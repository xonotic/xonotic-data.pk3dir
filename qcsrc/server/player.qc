#include "player.qh"

#include <common/anim.qh>
#include <common/animdecide.qh>
#include <common/csqcmodel_settings.qh>
#include <common/deathtypes/all.qh>
#include <common/effects/all.qh>
#include <common/effects/qc/_mod.qh>
#include <common/gametypes/_mod.qh>
#include <common/gametypes/sv_rules.qh>
#include <common/mapobjects/_mod.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/minigames/sv_minigames.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/mutators/mutator/waypoints/waypointsprites.qh>
#include <common/physics/player.qh>
#include <common/playerstats.qh>
#include <common/state.qh>
#include <common/wepent.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <server/bot/api.qh>
#include <server/cheats.qh>
#include <server/client.qh>
#include <server/clientkill.qh>
#include <server/command/common.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/handicap.qh>
#include <server/hook.qh>
#include <server/main.qh>
#include <server/mutators/_mod.qh>
#include <server/portals.qh>
#include <server/teamplay.qh>
#include <server/weapons/accuracy.qh>
#include <server/weapons/common.qh>
#include <server/weapons/throwing.qh>
#include <server/weapons/weaponstats.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

void Drop_Special_Items(entity player)
{
	// called when the player has become stuck or frozen
	// so objective items aren't stuck with the player

	MUTATOR_CALLHOOK(DropSpecialItems, player);
}

void CopyBody_Think(entity this)
{
	if(this.CopyBody_nextthink && time > this.CopyBody_nextthink)
	{
		this.CopyBody_think(this);
		if(wasfreed(this))
			return;
		this.CopyBody_nextthink = this.nextthink;
		this.CopyBody_think = getthink(this);
		setthink(this, CopyBody_Think);
	}
	CSQCMODEL_AUTOUPDATE(this);
	this.nextthink = time;
}
void CopyBody(entity this, float keepvelocity)
{
	if (this.effects & EF_NODRAW)
		return;
	entity clone = new(body);
	clone.enemy = this;
	clone.lip = this.lip;
	clone.colormap = this.colormap;
	clone.iscreature = this.iscreature;
	clone.teleportable = this.teleportable;
	clone.damagedbycontents = this.damagedbycontents;
	if(clone.damagedbycontents)
		IL_PUSH(g_damagedbycontents, clone);
	clone.angles = this.angles;
	clone.v_angle = this.v_angle;
	clone.avelocity = this.avelocity;
	clone.damageforcescale = this.damageforcescale;
	clone.effects = this.effects;
	clone.glowmod = this.glowmod;
	clone.event_damage = this.event_damage;
	clone.event_heal = this.event_heal;
	clone.anim_state = this.anim_state;
	clone.anim_time = this.anim_time;
	clone.anim_lower_action = this.anim_lower_action;
	clone.anim_lower_time = this.anim_lower_time;
	clone.anim_upper_action = this.anim_upper_action;
	clone.anim_upper_time = this.anim_upper_time;
	clone.anim_implicit_state = this.anim_implicit_state;
	clone.anim_implicit_time = this.anim_implicit_time;
	clone.anim_lower_implicit_action = this.anim_lower_implicit_action;
	clone.anim_lower_implicit_time = this.anim_lower_implicit_time;
	clone.anim_upper_implicit_action = this.anim_upper_implicit_action;
	clone.anim_upper_implicit_time = this.anim_upper_implicit_time;
	clone.dphitcontentsmask = this.dphitcontentsmask;
	clone.death_time = this.death_time;
	clone.pain_finished = this.pain_finished;
	SetResourceExplicit(clone, RES_HEALTH, GetResource(this, RES_HEALTH));
	SetResourceExplicit(clone, RES_ARMOR, GetResource(this, RES_ARMOR));
	clone.armortype = this.armortype;
	clone.model = this.model;
	clone.modelindex = this.modelindex;
	clone.skin = this.skin;
	clone.species = this.species;
	clone.move_qcphysics = false; // don't run gamecode logic on clones, too many
	set_movetype(clone, this.move_movetype);
	clone.solid = this.solid;
	clone.takedamage = this.takedamage;
	setcefc(clone, getcefc(this));
	clone.uncustomizeentityforclient = this.uncustomizeentityforclient;
	clone.uncustomizeentityforclient_set = this.uncustomizeentityforclient_set;
	if (keepvelocity == 1)
		clone.velocity = this.velocity;
	clone.oldvelocity = clone.velocity;
	clone.alpha = this.alpha;
	clone.fade_time = this.fade_time;
	clone.fade_rate = this.fade_rate;
	//clone.weapon = this.weapon;
	setorigin(clone, this.origin);
	setsize(clone, this.mins, this.maxs);
	clone.reset = SUB_Remove;
	clone._ps = this._ps;

	Drag_MoveDrag(this, clone);

	if(clone.colormap <= maxclients && clone.colormap > 0)
		clone.colormap = 1024 + this.clientcolors;
	clone.sv_entnum = etof(this); // sent to CSQC for color mapping purposes

	CSQCMODEL_AUTOINIT(clone);
	clone.CopyBody_nextthink = this.nextthink;
	clone.CopyBody_think = getthink(this);
	clone.nextthink = time;
	setthink(clone, CopyBody_Think);
	// "bake" the current animation frame for clones (they don't get clientside animation)
	animdecide_load_if_needed(clone);
	animdecide_setframes(clone, false, frame, frame1time, frame2, frame2time);

	IL_PUSH(g_clones, clone);

	MUTATOR_CALLHOOK(CopyBody, this, clone, keepvelocity);
}

void player_setupanimsformodel(entity this)
{
	// load animation info
	animdecide_load_if_needed(this);
	animdecide_setstate(this, 0, false);
}

void player_anim(entity this)
{
	int deadbits = (this.anim_state & (ANIMSTATE_DEAD1 | ANIMSTATE_DEAD2));
	if(IS_DEAD(this)) {
		if (!deadbits) {
			// Decide on which death animation to use.
			if(random() < 0.5)
				deadbits = ANIMSTATE_DEAD1;
			else
				deadbits = ANIMSTATE_DEAD2;
		}
	} else {
		// Clear a previous death animation.
		deadbits = 0;
	}
	int animbits = deadbits;
	if(StatusEffects_active(STATUSEFFECT_Frozen, this))
		animbits |= ANIMSTATE_FROZEN;
	if(this.move_movetype == MOVETYPE_FOLLOW)
		animbits |= ANIMSTATE_FOLLOW;
	if(IS_DUCKED(this))
		animbits |= ANIMSTATE_DUCK;

	MUTATOR_CALLHOOK(PlayerAnim, this, animbits);
	animbits = M_ARGV(1, int);

	animdecide_setstate(this, animbits, false);
	animdecide_setimplicitstate(this, IS_ONGROUND(this));
}

void PlayerCorpseDamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	float take, save;
	vector v;
	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, this, attacker);

	v = healtharmor_applydamage(GetResource(this, RES_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, damage);
	take = v.x;
	save = v.y;

	if(sound_allowed(MSG_BROADCAST, attacker))
	{
		if (save > 10)
			sound (this, CH_SHOTS, SND_ARMORIMPACT, VOL_BASE, ATTEN_NORM);
		else if (take > 30)
			sound (this, CH_SHOTS, SND_BODYIMPACT2, VOL_BASE, ATTEN_NORM);
		else if (take > 10)
			sound (this, CH_SHOTS, SND_BODYIMPACT1, VOL_BASE, ATTEN_NORM);
	}

	if (take > 50)
		Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, this, attacker);
	if (take > 100)
		Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, this, attacker);

	TakeResource(this, RES_ARMOR, save);
	TakeResource(this, RES_HEALTH, take);
	// pause regeneration for 5 seconds
	this.pauseregen_finished = max(this.pauseregen_finished, time + autocvar_g_balance_pause_health_regen);

	this.dmg_save = this.dmg_save + save;//max(save - 10, 0);
	this.dmg_take = this.dmg_take + take;//max(take - 10, 0);
	this.dmg_inflictor = inflictor;

	if (GetResource(this, RES_HEALTH) <= -autocvar_sv_gibhealth && this.alpha >= 0)
	{
		// don't use any animations as a gib
		this.frame = 0;
		// view just above the floor
		this.view_ofs = '0 0 4';

		Violence_GibSplash(this, 1, 1, attacker);
		this.alpha = -1;
		this.solid = SOLID_NOT; // restore later
		this.takedamage = DAMAGE_NO; // restore later
		if(this.damagedbycontents)
			IL_REMOVE(g_damagedbycontents, this);
		this.damagedbycontents = false;
	}
}

void PlayerDamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	vector v;
	float initial_health = max(GetResource(this, RES_HEALTH), 0);
	float initial_armor = max(GetResource(this, RES_ARMOR), 0);
	float take = 0, save = 0;

	if (damage)
	{
		if(!DEATH_ISSPECIAL(deathtype))
		{
			damage *= Handicap_GetTotalHandicap(this, true);
			if (this != attacker && IS_PLAYER(attacker))
			{
				damage /= Handicap_GetTotalHandicap(attacker, false);
			}
		}

		if (StatusEffects_active(STATUSEFFECT_SpawnShield, this) && autocvar_g_spawnshield_blockdamage < 1)
			damage *= 1 - bound(0, autocvar_g_spawnshield_blockdamage, 1);

		if(deathtype & HITTYPE_SOUND) // sound based attacks cause bleeding from the ears
		{
			vector ear1, ear2;
			vector d;
			float f;
			ear1 = this.origin;
			ear1_z += 0.125 * this.view_ofs.z + 0.875 * this.maxs.z; // 7/8
			ear2 = ear1;
			makevectors(this.angles);
			ear1 += v_right * -10;
			ear2 += v_right * +10;
			d = inflictor.origin - this.origin;
			if (d)
				f = (d * v_right) / vlen(d); // this is cos of angle of d and v_right!
			else
				f = 0;  // Assum ecenter.
			force = v_right * vlen(force);
			Violence_GibSplash_At(ear1, force * -1, 2, bound(0, damage, 25) / 2 * (0.5 - 0.5 * f), this, attacker);
			Violence_GibSplash_At(ear2, force,      2, bound(0, damage, 25) / 2 * (0.5 + 0.5 * f), this, attacker);
			if(f > 0)
			{
				hitloc = ear1;
				force = force * -1;
			}
			else
			{
				hitloc = ear2;
				// force is already good
			}
		}
		else
			Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, this, attacker);

		v = healtharmor_applydamage(GetResource(this, RES_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, damage);
		take = v.x;
		save = v.y;
	}

	if(attacker == this)
	{
		// don't reset pushltime for self damage as it may be an attempt to
		// escape a lava pit or similar
		//this.pushltime = 0;
		this.istypefrag = 0;
	}
	else if(IS_PLAYER(attacker))
	{
		this.pusher = attacker;
		this.pushltime = time + autocvar_g_maxpushtime;
		this.istypefrag = PHYS_INPUT_BUTTON_CHAT(this);
	}
	else if(time < this.pushltime)
	{
		attacker = this.pusher;
		this.pushltime = max(this.pushltime, time + 0.6);
	}
	else if(IS_MONSTER(attacker) && IS_PLAYER(attacker.realowner))
	{
		attacker = attacker.realowner;
		this.istypefrag = 0;
	}
	else
	{
		this.pushltime = 0;
		this.istypefrag = 0;
	}

	MUTATOR_CALLHOOK(PlayerDamage_SplitHealthArmor, inflictor, attacker, this, force, take, save, deathtype, damage);
	take = bound(0, M_ARGV(4, float), GetResource(this, RES_HEALTH));
	save = bound(0, M_ARGV(5, float), GetResource(this, RES_ARMOR));
	float excess = max(0, damage - take - save);

	if(sound_allowed(MSG_BROADCAST, attacker))
	{
		if (save > 10 && (initial_health - take) > 0) // don't play armor sound if the attack is fatal
			sound (this, CH_SHOTS, SND_ARMORIMPACT, VOL_BASE, ATTEN_NORM);
		else if (take > 30)
			sound (this, CH_SHOTS, SND_BODYIMPACT2, VOL_BASE, ATTEN_NORM);
		else if (take > 10)
			sound (this, CH_SHOTS, SND_BODYIMPACT1, VOL_BASE, ATTEN_NORM); // FIXME possibly remove them?
	}

	if (take > 50)
		Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, this, attacker);
	if (take > 100)
		Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, this, attacker);

	if (!StatusEffects_active(STATUSEFFECT_SpawnShield, this) || autocvar_g_spawnshield_blockdamage < 1)
	{
		if (!(this.flags & FL_GODMODE))
		{
			TakeResource(this, RES_ARMOR, save);
			TakeResource(this, RES_HEALTH, take);
			// pause regeneration for 5 seconds
			if(take)
				this.pauseregen_finished = max(this.pauseregen_finished, time + autocvar_g_balance_pause_health_regen);

			if (time > this.pain_finished && !STAT(FROZEN, this) && !StatusEffects_active(STATUSEFFECT_Frozen, this)) // Don't switch pain sequences like crazy
			{
				this.pain_finished = time + 0.5;	//Supajoe

				if(autocvar_sv_gentle < 1) {
					if(this.classname != "body") // pain anim is BORKED on our ZYMs, FIXME remove this once we have good models
					{
						if (!this.animstate_override)
						{
							if (random() > 0.5)
								animdecide_setaction(this, ANIMACTION_PAIN1, true);
							else
								animdecide_setaction(this, ANIMACTION_PAIN2, true);
						}
					}
					float myhp = GetResource(this, RES_HEALTH);
					if(myhp > 1)
					if(myhp < 25 || !(DEATH_WEAPONOF(deathtype).spawnflags & WEP_FLAG_CANCLIMB) || take > 20 || attacker != this)
					if(sound_allowed(MSG_BROADCAST, attacker))
					// exclude pain sounds for laserjumps as long as you aren't REALLY low on health and would die of the next two
					{
						if(deathtype == DEATH_FALL.m_id)
							PlayerSound(this, playersound_fall, CH_PAIN, VOL_BASE, VOICETYPE_PLAYERSOUND);
						else if(myhp > 75)
							PlayerSound(this, playersound_pain100, CH_PAIN, VOL_BASE, VOICETYPE_PLAYERSOUND);
						else if(myhp > 50)
							PlayerSound(this, playersound_pain75, CH_PAIN, VOL_BASE, VOICETYPE_PLAYERSOUND);
						else if(myhp > 25)
							PlayerSound(this, playersound_pain50, CH_PAIN, VOL_BASE, VOICETYPE_PLAYERSOUND);
						else
							PlayerSound(this, playersound_pain25, CH_PAIN, VOL_BASE, VOICETYPE_PLAYERSOUND);
					}
				}
			}

			// throw off bot aim temporarily
			float shake;
			if(IS_BOT_CLIENT(this) && GetResource(this, RES_HEALTH) >= 1)
			{
				shake = damage * 5 / (bound(0,skill,100) + 1);
				this.v_angle_x = this.v_angle.x + (random() * 2 - 1) * shake;
				this.v_angle_y = this.v_angle.y + (random() * 2 - 1) * shake;
				this.v_angle_x = bound(-90, this.v_angle.x, 90);
			}
		}
		else
			this.max_armorvalue += (save + take);
	}
	this.dmg_save = this.dmg_save + save;//max(save - 10, 0);
	this.dmg_take = this.dmg_take + take;//max(take - 10, 0);
	this.dmg_inflictor = inflictor;

	bool abot = (IS_BOT_CLIENT(attacker));
	bool vbot = (IS_BOT_CLIENT(this));

	bool valid_damage_for_weaponstats = false;
	Weapon awep = WEP_Null;

	if (!(round_handler_IsActive() && !round_handler_IsRoundStarted()) && time >= game_starttime)
	if(vbot || IS_REAL_CLIENT(this))
	if(abot || IS_REAL_CLIENT(attacker))
	if(attacker && this != attacker)
	if (DIFF_TEAM(this, attacker) && (!STAT(FROZEN, this) || this.freeze_time > time))
	{
		if(DEATH_ISSPECIAL(deathtype))
			awep = attacker.(weaponentity).m_weapon;
		else
			awep = DEATH_WEAPONOF(deathtype);
		valid_damage_for_weaponstats = true;
	}

	float dh = initial_health - max(GetResource(this, RES_HEALTH), 0); // health difference
	float da = initial_armor - max(GetResource(this, RES_ARMOR), 0); // armor difference
	if(valid_damage_for_weaponstats)
	{
		WeaponStats_LogDamage(awep.m_id, abot, this.(weaponentity).m_weapon.m_id, vbot, dh + da);
	}

	bool forbid_logging_damage = MUTATOR_CALLHOOK(PlayerDamaged, attacker, this, dh, da, hitloc, deathtype, damage);

	if ((dh || da) && !forbid_logging_damage)
	{
		float realdmg = damage - excess;
		if ((this != attacker || deathtype == DEATH_KILL.m_id) && realdmg
			&& (!(round_handler_IsActive() && !round_handler_IsRoundStarted()) && time >= game_starttime))
		{
			// accumulate damage, it will be logged later in this frame
			if (IS_PLAYER(attacker) && DIFF_TEAM(attacker, this) && deathtype != DEATH_KILL.m_id)
			{
				if (accuracy_isgooddamage(attacker, this))
					accuracy_add(attacker, awep, 0, 0, realdmg); // add to real
				attacker.score_frame_dmg += realdmg;
			}
			if (IS_PLAYER(this))
				this.score_frame_dmgtaken += realdmg;
		}
	}

	if (GetResource(this, RES_HEALTH) < 1)
	{
		bool defer_ClientKill_Now_TeamChange = false;

		if(this.alivetime_start)
		{
			PlayerStats_GameReport_Event_Player(this, PLAYERSTATS_ALIVETIME, max(0, time - this.alivetime_start));
			this.alivetime_start = 0;
		}

		if(valid_damage_for_weaponstats)
			WeaponStats_LogKill(awep.m_id, abot, this.(weaponentity).m_weapon.m_id, vbot);

		if(autocvar_sv_gentle < 1)
		if(sound_allowed(MSG_BROADCAST, attacker))
		{
			if(deathtype == DEATH_DROWN.m_id)
				PlayerSound(this, playersound_drown, CH_PAIN, VOL_BASE, VOICETYPE_PLAYERSOUND);
			else
				PlayerSound(this, playersound_death, CH_PAIN, VOL_BASE, VOICETYPE_PLAYERSOUND);
		}

		// get rid of kill indicator
		if(this.killindicator)
		{
			delete(this.killindicator);
			this.killindicator = NULL;
			if(this.killindicator_teamchange)
				defer_ClientKill_Now_TeamChange = true;

			if(this.classname == "body")
			if(deathtype == DEATH_KILL.m_id)
			{
				// for the lemmings fans, a small harmless explosion
				Send_Effect(EFFECT_ROCKET_EXPLODE, this.origin, '0 0 0', 1);
			}
		}

		// print an obituary message
		if(this.classname != "body")
			Obituary(attacker, inflictor, this, deathtype, weaponentity);

		// increment frag counter for used weapon type
		Weapon w = DEATH_WEAPONOF(deathtype);
		if(w != WEP_Null && accuracy_isgooddamage(attacker, this))
			CS(attacker).accuracy.(accuracy_frags[w.m_id-1]) += 1;

		this.respawn_time = 0;
		MUTATOR_CALLHOOK(PlayerDies, inflictor, attacker, this, deathtype, damage);
		damage = M_ARGV(4, float);
		excess = max(0, damage - take - save);

		//Weapon wep = this.(weaponentity).m_weapon;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity went = weaponentities[slot];
			if(!this.(went))
				continue; // TODO: clones have no weapon, but we don't want to have to check this all the time
			Weapon wep = this.(went).m_weapon;
			wep.wr_playerdeath(wep, this, went);
		}

		RemoveGrapplingHooks(this);

		Portal_ClearAllLater(this);

		this.fixangle = true;

		if(defer_ClientKill_Now_TeamChange)
			ClientKill_Now_TeamChange(this); // can turn player into spectator

		// player could have been miraculously resuscitated ;)
		if(GetResource(this, RES_HEALTH) >= 1 || !(IS_PLAYER(this) || this.classname == "body"))
			return;

		if (!this.respawn_time) // can be set in the mutator hook PlayerDies
			calculate_player_respawn_time(this);

		// when we get here, player actually dies

		// clear waypoints
		WaypointSprite_PlayerDead(this);
		// throw a weapon
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity went = weaponentities[slot];
			SpawnThrownWeapon(this, this.origin + (this.mins + this.maxs) * 0.5, this.(went).m_weapon, went);
		}

		// become fully visible
		this.alpha = default_player_alpha;
		// make the corpse upright (not tilted)
		this.angles_x = 0;
		this.angles_z = 0;
		// don't spin
		this.avelocity = '0 0 0';
		// view from the floor
		this.view_ofs = '0 0 -8';
		if(this.move_movetype == MOVETYPE_NOCLIP)
		{
			// don't toss the corpse in this case, it can get stuck in solid (causing low fps)
			// or fall indefinitely into the void if out of the map
			this.velocity = '0 0 0';
		}
		else
		{
			// toss the corpse
			set_movetype(this, MOVETYPE_TOSS);
		}
		// shootable corpse
		this.solid = SOLID_CORPSE;
		PS(this).ballistics_density = autocvar_g_ballistics_density_corpse;
		// don't stick to the floor
		UNSET_ONGROUND(this);
		// dying animation
		this.deadflag = DEAD_DYING;
		// don't play teleportation sounds
		this.teleportable = TELEPORT_SIMPLE;

		STAT(AIR_FINISHED, this) = 0;

		this.death_time = time;
		if (random() < 0.5)
			animdecide_setstate(this, this.anim_state | ANIMSTATE_DEAD1, true);
		else
			animdecide_setstate(this, this.anim_state | ANIMSTATE_DEAD2, true);

		// set damage function to corpse damage
		this.event_damage = PlayerCorpseDamage;
		this.event_heal = func_null;
		// call the corpse damage function just in case it wants to gib
		this.event_damage(this, inflictor, attacker, excess, deathtype, weaponentity, hitloc, force);

		// set up to fade out later
		SUB_SetFade (this, time + 6 + random (), 1);
		// reset body think wrapper broken by SUB_SetFade
		if(this.classname == "body" && getthink(this) != CopyBody_Think) {
			this.CopyBody_think = getthink(this);
			this.CopyBody_nextthink = this.nextthink;
			setthink(this, CopyBody_Think);
			this.nextthink = time;
		}

		if(autocvar_sv_gentle > 0 || autocvar_ekg || this.classname == "body") {
			// remove corpse
			// clones don't run any animation code any more, so we must gib them when they die :(
			this.event_damage(this, inflictor, attacker, autocvar_sv_gibhealth + 1, deathtype, weaponentity, hitloc, force);
		}

		// reset fields the weapons may use just in case
		if(this.classname != "body")
		{
			FOREACH(Weapons, it != WEP_Null,
			{
				it.wr_resetplayer(it, this);
				for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
				{
					ATTACK_FINISHED_FOR(this, it.m_id, slot) = 0;
				}
			});
		}
		MUTATOR_CALLHOOK(PlayerDied, this);
	}
}

bool PlayerHeal(entity targ, entity inflictor, float amount, float limit)
{
	float hlth = GetResource(targ, RES_HEALTH);
	if (hlth <= 0 || hlth >= limit)
		return false;

	GiveResourceWithLimit(targ, RES_HEALTH, amount, limit);
	return true;
}

void precache_playermodel(string m)
{
	int globhandle, i, n;
	string f;

	// remove :<skinnumber> suffix
	int j = strstrofs(m, ":", 0);
	if(j >= 0)
		m = substring(m, 0, j);

	if(substring(m, -9, 5) == "_lod1")
		return;
	if(substring(m, -9, 5) == "_lod2")
		return;
	precache_model(m);
	f = strcat(substring(m, 0, -5), "_lod1", substring(m, -4, -1));
	if(fexists(f))
		precache_model(f);
	f = strcat(substring(m, 0, -5), "_lod2", substring(m, -4, -1));
	if(fexists(f))
		precache_model(f);

	globhandle = search_begin(strcat(m, "_*.sounds"), true, false);
	if (globhandle < 0)
		return;
	n = search_getsize(globhandle);
	for (i = 0; i < n; ++i)
	{
		//print(search_getfilename(globhandle, i), "\n");
		f = search_getfilename(globhandle, i);
		PrecachePlayerSounds(f);
	}
	search_end(globhandle);
}
void precache_all_playermodels(string pattern)
{
	int globhandle = search_begin(pattern, true, false);
	if (globhandle < 0) return;
	int n = search_getsize(globhandle);
	for (int i = 0; i < n; ++i)
	{
		string s = search_getfilename(globhandle, i);
		precache_playermodel(s);
	}
	search_end(globhandle);
}

void precache_playermodels(string s)
{
	FOREACH_WORD(s, true, { precache_playermodel(it); });
}

PRECACHE(PlayerModels)
{
    // Precache all player models if desired
    if (autocvar_sv_precacheplayermodels)
    {
        PrecachePlayerSounds("sound/player/default.sounds");
        precache_all_playermodels("models/player/*.zym");
        precache_all_playermodels("models/player/*.dpm");
        precache_all_playermodels("models/player/*.md3");
        precache_all_playermodels("models/player/*.psk");
        precache_all_playermodels("models/player/*.iqm");
    }

    if (autocvar_sv_defaultcharacter)
    {
		precache_playermodels(autocvar_sv_defaultplayermodel_red);
		precache_playermodels(autocvar_sv_defaultplayermodel_blue);
		precache_playermodels(autocvar_sv_defaultplayermodel_yellow);
		precache_playermodels(autocvar_sv_defaultplayermodel_pink);
		precache_playermodels(autocvar_sv_defaultplayermodel);
    }
}
