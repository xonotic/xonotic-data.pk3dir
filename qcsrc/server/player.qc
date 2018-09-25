#include "player.qh"

#include <common/effects/all.qh>
#include "bot/api.qh"
#include "cheats.qh"
#include "clientkill.qh"
#include "g_damage.qh"
#include "handicap.qh"
#include "miscfunctions.qh"
#include "portals.qh"
#include "teamplay.qh"
#include "weapons/throwing.qh"
#include "command/common.qh"
#include "../common/state.qh"
#include "../common/anim.qh"
#include "../common/animdecide.qh"
#include "../common/csqcmodel_settings.qh"
#include "../common/gamemodes/sv_rules.qh"
#include "../common/deathtypes/all.qh"
#include "../common/mapobjects/subs.qh"
#include "../common/playerstats.qh"
#include "../lib/csqcmodel/sv_model.qh"

#include "../common/minigames/sv_minigames.qh"

#include <common/gamemodes/_mod.qh>

#include "../common/physics/player.qh"
#include "../common/effects/qc/_mod.qh"
#include "../common/mutators/mutator/waypoints/waypointsprites.qh"
#include "../common/mapobjects/_mod.qh"
#include "../common/wepent.qh"

#include "weapons/weaponstats.qh"

#include "../common/animdecide.qh"

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
	SetResourceAmountExplicit(clone, RESOURCE_HEALTH, GetResourceAmount(this, RESOURCE_HEALTH));
	SetResourceAmountExplicit(clone, RESOURCE_ARMOR, GetResourceAmount(this, RESOURCE_ARMOR));
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
	if(STAT(FROZEN, this))
		animbits |= ANIMSTATE_FROZEN;
	if(this.move_movetype == MOVETYPE_FOLLOW)
		animbits |= ANIMSTATE_FOLLOW;
	if(this.crouch)
		animbits |= ANIMSTATE_DUCK;
	animdecide_setstate(this, animbits, false);
	animdecide_setimplicitstate(this, IS_ONGROUND(this));
}

void PlayerCorpseDamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	float take, save;
	vector v;
	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, this, attacker);

	v = healtharmor_applydamage(GetResourceAmount(this, RESOURCE_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, damage);
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

	TakeResource(this, RESOURCE_ARMOR, save);
	TakeResource(this, RESOURCE_HEALTH, take);
	// pause regeneration for 5 seconds
	this.pauseregen_finished = max(this.pauseregen_finished, time + autocvar_g_balance_pause_health_regen);

	this.dmg_save = this.dmg_save + save;//max(save - 10, 0);
	this.dmg_take = this.dmg_take + take;//max(take - 10, 0);
	this.dmg_inflictor = inflictor;

	if (GetResourceAmount(this, RESOURCE_HEALTH) <= -autocvar_sv_gibhealth && this.alpha >= 0)
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

void calculate_player_respawn_time(entity this)
{
	if(MUTATOR_CALLHOOK(CalculateRespawnTime, this))
		return;

	float gametype_setting_tmp;
	float sdelay_max = GAMETYPE_DEFAULTED_SETTING(respawn_delay_max);
	float sdelay_small = GAMETYPE_DEFAULTED_SETTING(respawn_delay_small);
	float sdelay_large = GAMETYPE_DEFAULTED_SETTING(respawn_delay_large);
	float sdelay_small_count = GAMETYPE_DEFAULTED_SETTING(respawn_delay_small_count);
	float sdelay_large_count = GAMETYPE_DEFAULTED_SETTING(respawn_delay_large_count);
	float waves = GAMETYPE_DEFAULTED_SETTING(respawn_waves);

	float pcount = 1;  // Include myself whether or not team is already set right and I'm a "player".
	if (teamplay)
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != this, {
			if(it.team == this.team)
				++pcount;
		});
		if (sdelay_small_count == 0)
			sdelay_small_count = 1;
		if (sdelay_large_count == 0)
			sdelay_large_count = 1;
	}
	else
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != this, {
			++pcount;
		});
		if (sdelay_small_count == 0)
		{
			if (IS_INDEPENDENT_PLAYER(this))
			{
				// Players play independently. No point in requiring enemies.
				sdelay_small_count = 1;
			}
			else
			{
				// Players play AGAINST each other. Enemies required.
				sdelay_small_count = 2;
			}
		}
		if (sdelay_large_count == 0)
		{
			if (IS_INDEPENDENT_PLAYER(this))
			{
				// Players play independently. No point in requiring enemies.
				sdelay_large_count = 1;
			}
			else
			{
				// Players play AGAINST each other. Enemies required.
				sdelay_large_count = 2;
			}
		}
	}

	float sdelay;

	if (pcount <= sdelay_small_count)
		sdelay = sdelay_small;
	else if (pcount >= sdelay_large_count)
		sdelay = sdelay_large;
	else  // NOTE: this case implies sdelay_large_count > sdelay_small_count.
		sdelay = sdelay_small + (sdelay_large - sdelay_small) * (pcount - sdelay_small_count) / (sdelay_large_count - sdelay_small_count);

	if(waves)
		this.respawn_time = ceil((time + sdelay) / waves) * waves;
	else
		this.respawn_time = time + sdelay;

	if(sdelay < sdelay_max)
		this.respawn_time_max = time + sdelay_max;
	else
		this.respawn_time_max = this.respawn_time;

	if((sdelay + waves >= 5.0) && (this.respawn_time - time > 1.75))
		this.respawn_countdown = 10; // first number to count down from is 10
	else
		this.respawn_countdown = -1; // do not count down

	if(autocvar_g_forced_respawn)
		this.respawn_flags = this.respawn_flags | RESPAWN_FORCE;
}

void PlayerDamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	float take, save, dh, da;
	vector v;
	float excess;

	dh = max(GetResourceAmount(this, RESOURCE_HEALTH), 0);
	da = max(GetResourceAmount(this, RESOURCE_ARMOR), 0);

	if(!DEATH_ISSPECIAL(deathtype))
	{
		damage *= Handicap_GetTotalHandicap(this);
		if (this != attacker && IS_PLAYER(attacker))
		{
			damage /= Handicap_GetTotalHandicap(attacker);
		}
	}

	if (time < this.spawnshieldtime && autocvar_g_spawnshield_blockdamage < 1)
		damage *= 1 - max(0, autocvar_g_spawnshield_blockdamage);

	if(DEATH_ISWEAPON(deathtype, WEP_TUBA))
	{
		// tuba causes blood to come out of the ears
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

	v = healtharmor_applydamage(GetResourceAmount(this, RESOURCE_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, damage);
	take = v.x;
	save = v.y;

	if(attacker == this)
	{
		// don't reset pushltime for this damage as it may be an attempt to
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
	else
	{
		this.pushltime = 0;
		this.istypefrag = 0;
	}

	MUTATOR_CALLHOOK(PlayerDamage_SplitHealthArmor, inflictor, attacker, this, force, take, save, deathtype, damage);
	take = bound(0, M_ARGV(4, float), GetResourceAmount(this, RESOURCE_HEALTH));
	save = bound(0, M_ARGV(5, float), GetResourceAmount(this, RESOURCE_ARMOR));
	excess = max(0, damage - take - save);

	if(sound_allowed(MSG_BROADCAST, attacker))
	{
		if (save > 10)
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

	if (time >= this.spawnshieldtime || autocvar_g_spawnshield_blockdamage < 1)
	{
		if (!(this.flags & FL_GODMODE))
		{
			TakeResource(this, RESOURCE_ARMOR, save);
			TakeResource(this, RESOURCE_HEALTH, take);
			// pause regeneration for 5 seconds
			if(take)
				this.pauseregen_finished = max(this.pauseregen_finished, time + autocvar_g_balance_pause_health_regen);

			if (time > this.pain_finished)		//Don't switch pain sequences like crazy
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
					float myhp = GetResourceAmount(this, RESOURCE_HEALTH);
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
			if(IS_BOT_CLIENT(this) && GetResourceAmount(this, RESOURCE_HEALTH) >= 1)
			{
				shake = damage * 5 / (bound(0,skill,100) + 1);
				this.v_angle_x = this.v_angle.x + (random() * 2 - 1) * shake;
				this.v_angle_y = this.v_angle.y + (random() * 2 - 1) * shake;
				this.v_angle_x = bound(-90, this.v_angle.x, 90);
			}

			if (this != attacker) {
				float realdmg = damage - excess;
				if (IS_PLAYER(attacker) && DIFF_TEAM(attacker, this)) {
					GameRules_scoring_add(attacker, DMG, realdmg);
				}
				if (IS_PLAYER(this)) {
					GameRules_scoring_add(this, DMGTAKEN, realdmg);
				}
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

	if(vbot || IS_REAL_CLIENT(this))
	if(abot || IS_REAL_CLIENT(attacker))
	if(attacker && this != attacker)
	if(DIFF_TEAM(this, attacker))
	{
		if(DEATH_ISSPECIAL(deathtype))
			awep = attacker.(weaponentity).m_weapon;
		else
			awep = DEATH_WEAPONOF(deathtype);
		valid_damage_for_weaponstats = true;
	}

	dh = dh - max(GetResourceAmount(this, RESOURCE_HEALTH), 0);
	da = da - max(GetResourceAmount(this, RESOURCE_ARMOR), 0);
	if(valid_damage_for_weaponstats)
	{
		WeaponStats_LogDamage(awep.m_id, abot, this.(weaponentity).m_weapon.m_id, vbot, dh + da);
	}

	MUTATOR_CALLHOOK(PlayerDamaged, attacker, this, dh, da, hitloc, deathtype, damage);

	if (GetResourceAmount(this, RESOURCE_HEALTH) < 1)
	{
		float defer_ClientKill_Now_TeamChange;
		defer_ClientKill_Now_TeamChange = false;

		if(this.alivetime)
		{
			PlayerStats_GameReport_Event_Player(this, PLAYERSTATS_ALIVETIME, time - this.alivetime);
			this.alivetime = 0;
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
			Obituary (attacker, inflictor, this, deathtype, weaponentity);

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
		// e.g. players in freezetag get frozen, they don't really die
		if(GetResourceAmount(this, RESOURCE_HEALTH) >= 1 || !(IS_PLAYER(this) || this.classname == "body"))
			return;

		if (!this.respawn_time) // can be set in the mutator hook PlayerDies
			calculate_player_respawn_time(this);

		// when we get here, player actually dies

		Unfreeze(this); // remove any icy remains
		SetResourceAmountExplicit(this, RESOURCE_HEALTH, 0); // Unfreeze resets health, so we need to set it back

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
		// toss the corpse
		set_movetype(this, MOVETYPE_TOSS);
		// shootable corpse
		this.solid = SOLID_CORPSE;
		PS(this).ballistics_density = autocvar_g_ballistics_density_corpse;
		// don't stick to the floor
		UNSET_ONGROUND(this);
		// dying animation
		this.deadflag = DEAD_DYING;

		STAT(MOVEVARS_SPECIALCOMMAND, this) = false; // sweet release

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
	if(GetResourceAmount(targ, RESOURCE_HEALTH) <= 0 || GetResourceAmount(targ, RESOURCE_HEALTH) >= limit)
		return false;

	GiveResourceWithLimit(targ, RESOURCE_HEALTH, amount, limit);
	return true;
}

/**
 * message "": do not say, just test flood control
 * return value:
 *   1 = accept
 *   0 = reject
 *  -1 = fake accept
 */
int Say(entity source, int teamsay, entity privatesay, string msgin, bool floodcontrol)
{
	if (!teamsay && !privatesay && substring(msgin, 0, 1) == " ")
		msgin = substring(msgin, 1, -1); // work around DP say bug (say_team does not have this!)

	if (source)
		msgin = formatmessage(source, msgin);

	string colorstr;
	if (!(IS_PLAYER(source) || source.caplayer))
		colorstr = "^0"; // black for spectators
	else if(teamplay)
		colorstr = Team_ColorCode(source.team);
	else
	{
		colorstr = "";
		teamsay = false;
	}

	if(game_stopped)
		teamsay = false;

	if (!source) {
		colorstr = "";
		teamsay = false;
	}

	if(msgin != "")
		msgin = trigger_magicear_processmessage_forallears(source, teamsay, privatesay, msgin);

	/*
	 * using bprint solves this... me stupid
	// how can we prevent the message from appearing in a listen server?
	// for now, just give "say" back and only handle say_team
	if(!teamsay)
	{
		clientcommand(source, strcat("say ", msgin));
		return;
	}
	*/

	string namestr = "";
	if (source)
		namestr = playername(source, autocvar_g_chat_teamcolors);

	string colorprefix = (strdecolorize(namestr) == namestr) ? "^3" : "^7";

	string msgstr = "", cmsgstr = "";
	string privatemsgprefix = string_null;
	int privatemsgprefixlen = 0;
	if (msgin != "")
	{
		if(privatesay)
		{
			msgstr = strcat("\{1}\{13}* ", colorprefix, namestr, "^3 tells you: ^7");
			privatemsgprefixlen = strlen(msgstr);
			msgstr = strcat(msgstr, msgin);
			cmsgstr = strcat(colorstr, colorprefix, namestr, "^3 tells you:\n^7", msgin);
			privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", playername(privatesay, autocvar_g_chat_teamcolors), ": ^7");
		}
		else if(teamsay)
		{
			if(strstrofs(msgin, "/me", 0) >= 0)
			{
				//msgin = strreplace("/me", "", msgin);
				//msgin = substring(msgin, 3, strlen(msgin));
				msgin = strreplace("/me", strcat(colorstr, "(", colorprefix, namestr, colorstr, ")^7"), msgin);
				msgstr = strcat("\{1}\{13}^4* ", "^7", msgin);
			}
			else
				msgstr = strcat("\{1}\{13}", colorstr, "(", colorprefix, namestr, colorstr, ") ^7", msgin);
			cmsgstr = strcat(colorstr, "(", colorprefix, namestr, colorstr, ")\n^7", msgin);
		}
		else
		{
			if(strstrofs(msgin, "/me", 0) >= 0)
			{
				//msgin = strreplace("/me", "", msgin);
				//msgin = substring(msgin, 3, strlen(msgin));
				msgin = strreplace("/me", strcat(colorprefix, namestr), msgin);
				msgstr = strcat("\{1}^4* ", "^7", msgin);
			}
			else {
				msgstr = "\{1}";
				msgstr = strcat(msgstr, (namestr != "") ? strcat(colorprefix, namestr, "^7: ") : "^7");
				msgstr = strcat(msgstr, msgin);
			}
			cmsgstr = "";
		}
		msgstr = strcat(strreplace("\n", " ", msgstr), "\n"); // newlines only are good for centerprint
	}

	string fullmsgstr = msgstr;
	string fullcmsgstr = cmsgstr;

	// FLOOD CONTROL
	int flood = 0;
	var .float flood_field = floodcontrol_chat;
	if(floodcontrol && source)
	{
		float flood_spl;
		float flood_burst;
		float flood_lmax;
		float lines;
		if(privatesay)
		{
			flood_spl = autocvar_g_chat_flood_spl_tell;
			flood_burst = autocvar_g_chat_flood_burst_tell;
			flood_lmax = autocvar_g_chat_flood_lmax_tell;
			flood_field = floodcontrol_chattell;
		}
		else if(teamsay)
		{
			flood_spl = autocvar_g_chat_flood_spl_team;
			flood_burst = autocvar_g_chat_flood_burst_team;
			flood_lmax = autocvar_g_chat_flood_lmax_team;
			flood_field = floodcontrol_chatteam;
		}
		else
		{
			flood_spl = autocvar_g_chat_flood_spl;
			flood_burst = autocvar_g_chat_flood_burst;
			flood_lmax = autocvar_g_chat_flood_lmax;
			flood_field = floodcontrol_chat;
		}
		flood_burst = max(0, flood_burst - 1);
		// to match explanation in default.cfg, a value of 3 must allow three-line bursts and not four!

		// do flood control for the default line size
		if(msgstr != "")
		{
			getWrappedLine_remaining = msgstr;
			msgstr = "";
			lines = 0;
			while(getWrappedLine_remaining && (!flood_lmax || lines <= flood_lmax))
			{
				msgstr = strcat(msgstr, " ", getWrappedLineLen(82.4289758859709, strlennocol)); // perl averagewidth.pl < gfx/vera-sans.width
				++lines;
			}
			msgstr = substring(msgstr, 1, strlen(msgstr) - 1);

			if(getWrappedLine_remaining != "")
			{
				msgstr = strcat(msgstr, "\n");
				flood = 2;
			}

			if (time >= source.(flood_field))
			{
				source.(flood_field) = max(time - flood_burst * flood_spl, source.(flood_field)) + lines * flood_spl;
			}
			else
			{
				flood = 1;
				msgstr = fullmsgstr;
			}
		}
		else
		{
			if (time >= source.(flood_field))
				source.(flood_field) = max(time - flood_burst * flood_spl, source.(flood_field)) + flood_spl;
			else
				flood = 1;
		}

		if (timeout_status == TIMEOUT_ACTIVE) // when game is paused, no flood protection
			source.(flood_field) = flood = 0;
	}

	string sourcemsgstr, sourcecmsgstr;
	if(flood == 2) // cannot happen for empty msgstr
	{
		if(autocvar_g_chat_flood_notify_flooder)
		{
			sourcemsgstr = strcat(msgstr, "\n^3FLOOD CONTROL: ^7message too long, trimmed\n");
			sourcecmsgstr = "";
		}
		else
		{
			sourcemsgstr = fullmsgstr;
			sourcecmsgstr = fullcmsgstr;
		}
		cmsgstr = "";
	}
	else
	{
		sourcemsgstr = msgstr;
		sourcecmsgstr = cmsgstr;
	}

	if (!privatesay && source && !(IS_PLAYER(source) || source.caplayer))
	{
		if (!game_stopped)
		if (teamsay || (autocvar_g_chat_nospectators == 1) || (autocvar_g_chat_nospectators == 2 && !warmup_stage))
			teamsay = -1; // spectators
	}

	if(flood)
		LOG_INFO("NOTE: ", playername(source, true), "^7 is flooding.");

	// build sourcemsgstr by cutting off a prefix and replacing it by the other one
	if(privatesay)
		sourcemsgstr = strcat(privatemsgprefix, substring(sourcemsgstr, privatemsgprefixlen, -1));

	int ret;
	if(source && CS(source).muted)
	{
		// always fake the message
		ret = -1;
	}
	else if(flood == 1)
	{
		if (autocvar_g_chat_flood_notify_flooder)
		{
			sprint(source, strcat("^3FLOOD CONTROL: ^7wait ^1", ftos(source.(flood_field) - time), "^3 seconds\n"));
			ret = 0;
		}
		else
			ret = -1;
	}
	else
	{
		ret = 1;
	}

	if (privatesay && source && !(IS_PLAYER(source) || source.caplayer))
	{
		if (!game_stopped)
		if ((privatesay && (IS_PLAYER(privatesay) || privatesay.caplayer)) && ((autocvar_g_chat_nospectators == 1) || (autocvar_g_chat_nospectators == 2 && !warmup_stage)))
			ret = -1; // just hide the message completely
	}

	MUTATOR_CALLHOOK(ChatMessage, source, ret);
	ret = M_ARGV(1, int);

	if(sourcemsgstr != "" && ret != 0)
	{
		if(ret < 0) // faked message, because the player is muted
		{
			sprint(source, sourcemsgstr);
			if(sourcecmsgstr != "" && !privatesay)
				centerprint(source, sourcecmsgstr);
		}
		else if(privatesay) // private message, between 2 people only
		{
			sprint(source, sourcemsgstr);
			if (!autocvar_g_chat_tellprivacy) { dedicated_print(msgstr); } // send to server console too if "tellprivacy" is disabled
			if(!MUTATOR_CALLHOOK(ChatMessageTo, privatesay, source))
			{
				sprint(privatesay, msgstr);
				if(cmsgstr != "")
					centerprint(privatesay, cmsgstr);
			}
		}
		else if ( teamsay && CS(source).active_minigame )
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != source && CS(it).active_minigame == CS(source).active_minigame && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				sprint(it, msgstr);
			});
		}
		else if(teamsay > 0) // team message, only sent to team mates
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			if(sourcecmsgstr != "")
				centerprint(source, sourcecmsgstr);
			FOREACH_CLIENT((IS_PLAYER(it) || it.caplayer) && IS_REAL_CLIENT(it) && it != source && it.team == source.team && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				sprint(it, msgstr);
				if(cmsgstr != "")
					centerprint(it, cmsgstr);
			});
		}
		else if(teamsay < 0) // spectator message, only sent to spectators
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			FOREACH_CLIENT(!(IS_PLAYER(it) || it.caplayer) && IS_REAL_CLIENT(it) && it != source && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				sprint(it, msgstr);
			});
		}
		else
		{
			if (source) {
				sprint(source, sourcemsgstr);
				dedicated_print(msgstr); // send to server console too
				MX_Say(strcat(playername(source, true), "^7: ", msgin));
			}
			FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != source && !MUTATOR_CALLHOOK(ChatMessageTo, it, source), {
				sprint(it, msgstr);
			});
		}
	}

	return ret;
}
