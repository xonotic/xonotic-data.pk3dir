#include "hook.qh"

#include <common/constants.qh>
#include <common/effects/all.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/net_linked.qh>
#include <common/physics/player.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/util.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/_all.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/server.qh>
#include <server/bot/api.qh>
#include <server/command/common.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/round_handler.qh>
#include <server/weapons/common.qh>
#include <server/weapons/csqcprojectile.qh>
#include <server/weapons/selection.qh>
#include <server/weapons/tracing.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

void RemoveGrapplingHooks(entity pl)
{
	if(pl.move_movetype == MOVETYPE_FLY)
		set_movetype(pl, MOVETYPE_WALK);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(!pl.(weaponentity))
			continue; // continue incase other slots exist?
		if(pl.(weaponentity).hook)
			delete(pl.(weaponentity).hook);
		pl.(weaponentity).hook = NULL;
	}

	//pl.disableclientprediction = false;
}

void RemoveHook(entity this)
{
	entity player = this.realowner;
	.entity weaponentity = this.weaponentity_fld;

	if(player.(weaponentity).hook == this)
		player.(weaponentity).hook = NULL;

	if(player.move_movetype == MOVETYPE_FLY)
		set_movetype(player, MOVETYPE_WALK);
	delete(this);
}

void GrapplingHookReset(entity this)
{
	RemoveHook(this);
}

void GrapplingHook_Stop(entity this)
{
	Send_Effect(EFFECT_HOOK_IMPACT, this.origin, '0 0 0', 1);
	sound(this, CH_SHOTS, SND_HOOK_IMPACT, VOL_BASE, ATTEN_NORM);

	this.state = 1;
	setthink(this, GrapplingHookThink);
	this.nextthink = time;
	settouch(this, func_null);
	this.velocity = '0 0 0';
	set_movetype(this, MOVETYPE_NONE);
	this.hook_length = -1;
}

.vector hook_start, hook_end;
bool GrapplingHookSend(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_HOOK);
	sf = sf & 0x7F;
	if(sound_allowed(MSG_BROADCAST, this.realowner))
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, etof(this.realowner));
		WriteByte(MSG_ENTITY, weaponslot(this.weaponentity_fld));
	}
	if(sf & 2)
	{
		WriteVector(MSG_ENTITY, this.hook_start);
	}
	if(sf & 4)
	{
		WriteVector(MSG_ENTITY, this.hook_end);
	}
	return true;
}

int autocvar_g_grappling_hook_tarzan;

void GrapplingHookThink(entity this)
{
	float spd, dist;

	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).hook != this)	// how did that happen?
	{
		error("Owner lost the hook!\n");
		return;
	}
	if((this.move_movetype == MOVETYPE_FOLLOW && LostMovetypeFollow(this))
		|| game_stopped || (round_handler_IsActive() && !round_handler_IsRoundStarted())
		|| ((this.aiment.flags & FL_PROJECTILE) && this.aiment.classname != "nade"))
	{
		RemoveHook(this);
		return;
	}
	if(this.aiment)
		WarpZone_RefSys_AddIncrementally(this, this.aiment);

	this.nextthink = time;

	int s = W_GunAlign(this.realowner.(weaponentity), STAT(GUNALIGN, this.realowner)) - 1;

	makevectors(this.realowner.v_angle);
	vector vs = hook_shotorigin[s];
	vs = v_forward * vs.x + v_right * -vs.y + v_up * vs.z;
	vector org = this.realowner.origin + this.realowner.view_ofs + vs;
	vector myorg = WarpZone_RefSys_TransformOrigin(this.realowner, this, org);

	if(this.hook_length < 0)
		this.hook_length = vlen(myorg - this.origin);

	int tarzan = autocvar_g_grappling_hook_tarzan;
	entity pull_entity = this.realowner;
	float velocity_multiplier = 1;
	MUTATOR_CALLHOOK(GrappleHookThink, this, tarzan, pull_entity, velocity_multiplier);
	tarzan = M_ARGV(1, int);
	pull_entity = M_ARGV(2, entity);
	velocity_multiplier = M_ARGV(3, float);

	if(this.state == 1)
	{
		float pullspeed = autocvar_g_balance_grapplehook_speed_pull;
		// speed the rope is pulled with

		float rubberforce = autocvar_g_balance_grapplehook_force_rubber;
		// force the rope will use if it is stretched

		float rubberforce_overstretch = autocvar_g_balance_grapplehook_force_rubber_overstretch;
		// force the rope will use if it is stretched

		float minlength = autocvar_g_balance_grapplehook_length_min;
		// minimal rope length
		// if the rope goes below this length, it isn't pulled any more

		float ropestretch = autocvar_g_balance_grapplehook_stretch;
		// if the rope is stretched by more than this amount, more rope is
		// given to you again

		float ropeairfriction = autocvar_g_balance_grapplehook_airfriction;
		// while hanging on the rope, this friction component will help you a
		// bit to control the rope

		bool frozen_pulling = (autocvar_g_grappling_hook_tarzan >= 2 && autocvar_g_balance_grapplehook_pull_frozen);
		bool target_isfrozen = (STAT(FROZEN, this.aiment) || StatusEffects_active(STATUSEFFECT_Frozen, this.aiment));

		vector dir = this.origin - myorg;
		dist = vlen(dir);

		// TODO: Consider changing this back to `dir / dist` after https://github.com/graphitemaster/gmqcc/issues/210.
		dir = (dist ? dir * (1 / dist) : '0 0 0'); // same as dir = normalize(dir); but cheaper

		if(tarzan)
		{
			vector v, v0;
			v = v0 = WarpZone_RefSys_TransformVelocity(pull_entity, this, pull_entity.velocity);

			// first pull the rope...
			if(this.realowner.(weaponentity).hook_state & HOOK_PULLING)
			{
				float newlength = max(this.hook_length - pullspeed * frametime, minlength);

				if(newlength < dist - ropestretch) // overstretched?
				{
					newlength = dist - ropestretch;
					if(v * dir < 0) // only if not already moving in hook direction
						v = v + frametime * dir * rubberforce_overstretch;
				}

				this.hook_length = newlength;
			}

			if(pull_entity.move_movetype == MOVETYPE_FLY)
				set_movetype(pull_entity, MOVETYPE_WALK);

			if(this.realowner.(weaponentity).hook_state & HOOK_RELEASING)
			{
				this.hook_length = dist;
			}
			else
			{
				// then pull the player
				spd = bound(0, (dist - this.hook_length) / ropestretch, 1);
				v = v * (1 - frametime * ropeairfriction);
				v = v + frametime * dir * spd * rubberforce;

				vector dv = ((v - v0) * dir) * dir;
				if(tarzan >= 2)
				{
					if(this.aiment.move_movetype == MOVETYPE_WALK || this.aiment.classname == "nade")
					{
						entity aim_ent = ((IS_VEHICLE(this.aiment) && this.aiment.owner) ? this.aiment.owner : this.aiment);
						v = v - dv * 0.5;
						if((frozen_pulling && target_isfrozen) || !frozen_pulling)
						{
							this.aiment.velocity = this.aiment.velocity - dv * 0.5;
							UNSET_ONGROUND(this.aiment);
							if(this.aiment.flags & FL_PROJECTILE)
								UpdateCSQCProjectile(this.aiment);
						}
						if(this.aiment.classname == "nade")
							this.aiment.nextthink = time + autocvar_g_balance_grapplehook_nade_time; // set time after letting go?
						aim_ent.pusher = this.realowner;
						aim_ent.pushltime = time + autocvar_g_maxpushtime;
						aim_ent.istypefrag = PHYS_INPUT_BUTTON_CHAT(aim_ent);
					}
				}

				UNSET_ONGROUND(pull_entity);
			}

			if(!frozen_pulling && !(this.aiment.flags & FL_PROJECTILE))
				pull_entity.velocity = WarpZone_RefSys_TransformVelocity(this, pull_entity, v * velocity_multiplier);

			if(frozen_pulling && autocvar_g_balance_grapplehook_pull_frozen == 2 && !target_isfrozen)
			{
				RemoveHook(this);
				return;
			}
		}
		else
		{
			vector end = this.origin - dir * 50;
			dist = vlen(end - myorg);
			if(dist < 200)
				spd = dist * (pullspeed / 200);
			else
				spd = pullspeed;
			if(spd < 50)
				spd = 0;
			this.realowner.velocity = dir * spd;
			set_movetype(this.realowner, MOVETYPE_FLY);

			UNSET_ONGROUND(this.realowner);
		}
	}

	makevectors(this.angles.x * '-1 0 0' + this.angles.y * '0 1 0');
	myorg = WarpZone_RefSys_TransformOrigin(this, this.realowner, this.origin); // + v_forward * (-9);

	if(myorg != this.hook_start)
	{
		this.SendFlags |= 2;
		this.hook_start = myorg;
	}
	if(org != this.hook_end)
	{
		this.SendFlags |= 4;
		this.hook_end = org;
	}
}

void GrapplingHookTouch(entity this, entity toucher)
{
	if(toucher.move_movetype == MOVETYPE_FOLLOW)
		return;
	PROJECTILE_TOUCH(this, toucher);

	GrapplingHook_Stop(this);

	if(toucher)
		//if(toucher.move_movetype != MOVETYPE_NONE)
		{
			SetMovetypeFollow(this, toucher);
			WarpZone_RefSys_BeginAddingIncrementally(this, this.aiment);
		}

	//this.realowner.disableclientprediction = true;
}

void GrapplingHook_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if (!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_balance_projectiledamage says to halt

	TakeResource(this, RES_HEALTH, damage);

	if (GetResource(this, RES_HEALTH) <= 0)
	{
		if(attacker != this.realowner)
		{
			this.realowner.pusher = attacker;
			this.realowner.pushltime = time + autocvar_g_maxpushtime;
			this.realowner.istypefrag = PHYS_INPUT_BUTTON_CHAT(this.realowner);
		}
		RemoveHook(this);
	}
}

void FireGrapplingHook(entity actor, .entity weaponentity)
{
	if(weaponLocked(actor)) return;
	if(actor.vehicle) return;

	int s = W_GunAlign(actor.(weaponentity), STAT(GUNALIGN, actor)) - 1;
	vector oldmovedir = actor.(weaponentity).movedir;
	actor.(weaponentity).movedir = hook_shotorigin[s];
	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', true, 0, SND_HOOK_FIRE, CH_WEAPON_B, 0, WEP_HOOK.m_id);
	W_MuzzleFlash(WEP_HOOK, actor, weaponentity, w_shotorg, '0 0 0');
	actor.(weaponentity).movedir = oldmovedir;

	entity missile = WarpZone_RefSys_SpawnSameRefSys(actor);
	missile.owner = missile.realowner = actor;
	actor.(weaponentity).hook = missile;
	missile.weaponentity_fld = weaponentity;
	missile.reset = GrapplingHookReset;
	missile.classname = "grapplinghook";
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);

	set_movetype(missile, ((autocvar_g_balance_grapplehook_gravity) ? MOVETYPE_TOSS : MOVETYPE_FLY));
	PROJECTILE_MAKETRIGGER(missile);

	//setmodel (missile, MDL_HOOK); // precision set below
	setsize (missile, '-3 -3 -3', '3 3 3');
	setorigin(missile, w_shotorg);

	missile.state = 0; // not latched onto anything

	W_SetupProjVelocity_Explicit(missile, w_shotdir, v_up, autocvar_g_balance_grapplehook_speed_fly, 0, 0, 0, false);

	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	settouch(missile, GrapplingHookTouch);
	setthink(missile, GrapplingHookThink);
	missile.nextthink = time;

	missile.effects = /*EF_FULLBRIGHT | EF_ADDITIVE |*/ EF_LOWPRECISION;

	SetResourceExplicit(missile, RES_HEALTH, autocvar_g_balance_grapplehook_health);
	missile.event_damage = GrapplingHook_Damage;
	missile.takedamage = DAMAGE_AIM;
	missile.damageforcescale = 0;
	missile.damagedbycontents = (autocvar_g_balance_grapplehook_damagedbycontents);
	if(missile.damagedbycontents)
		IL_PUSH(g_damagedbycontents, missile);

	missile.hook_start = missile.hook_end = missile.origin;

	Net_LinkEntity(missile, false, 0, GrapplingHookSend);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

// NOTE: using PRECACHE here to make sure it's called after everything else
PRECACHE(GrappleHookInit)
{
	if(g_grappling_hook)
	{
		hook_shotorigin[0] = '8 8 -12';
		hook_shotorigin[1] = '8 8 -12';
		hook_shotorigin[2] = '8 8 -12';
		hook_shotorigin[3] = '8 8 -12';
	}
	else
	{
		Weapon w = WEP_HOOK;
		w.wr_init(w);
		vector vecs = CL_Weapon_GetShotOrg(WEP_HOOK.m_id);
		hook_shotorigin[0] = shotorg_adjust(vecs, false, false, 1);
		hook_shotorigin[1] = shotorg_adjust(vecs, false, false, 2);
		hook_shotorigin[2] = shotorg_adjust(vecs, false, false, 3);
		hook_shotorigin[3] = shotorg_adjust(vecs, false, false, 4);
	}
}
