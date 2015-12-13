#include "cl_player.qh"

#include "bot/bot.qh"
#include "cheats.qh"
#include "g_damage.qh"
#include "g_subs.qh"
#include "miscfunctions.qh"
#include "portals.qh"
#include "teamplay.qh"
#include "weapons/throwing.qh"
#include "command/common.qh"
#include "../common/anim.qh"
#include "../common/animdecide.qh"
#include "../common/csqcmodel_settings.qh"
#include "../common/deathtypes/all.qh"
#include "../common/triggers/subs.qh"
#include "../common/playerstats.qh"
#include "../lib/csqcmodel/sv_model.qh"

#include "../common/minigames/sv_minigames.qh"

#include "../common/mutators/mutator/waypoints/waypointsprites.qh"
#include "../common/triggers/include.qh"

#include "weapons/weaponstats.qh"

#include "../common/animdecide.qh"

void Drop_Special_Items(entity player)
{
	// called when the player has become stuck or frozen
	// so objective items aren't stuck with the player

	MUTATOR_CALLHOOK(DropSpecialItems, player);
}

void CopyBody_Think()
{SELFPARAM();
	if(self.CopyBody_nextthink && time > self.CopyBody_nextthink)
	{
		self.CopyBody_think();
		if(wasfreed(self))
			return;
		self.CopyBody_nextthink = self.nextthink;
		self.CopyBody_think = self.think;
		self.think = CopyBody_Think;
	}
	CSQCMODEL_AUTOUPDATE(self);
	self.nextthink = time;
}
void CopyBody(float keepvelocity)
{SELFPARAM();
	if (self.effects & EF_NODRAW)
		return;
	setself(new(body));
	self.enemy = this;
	self.lip = this.lip;
	self.colormap = this.colormap;
	self.iscreature = this.iscreature;
	self.teleportable = this.teleportable;
	self.damagedbycontents = this.damagedbycontents;
	self.angles = this.angles;
	self.v_angle = this.v_angle;
	self.avelocity = this.avelocity;
	self.damageforcescale = this.damageforcescale;
	self.effects = this.effects;
	self.glowmod = this.glowmod;
	self.event_damage = this.event_damage;
	self.anim_state = this.anim_state;
	self.anim_time = this.anim_time;
	self.anim_lower_action = this.anim_lower_action;
	self.anim_lower_time = this.anim_lower_time;
	self.anim_upper_action = this.anim_upper_action;
	self.anim_upper_time = this.anim_upper_time;
	self.anim_implicit_state = this.anim_implicit_state;
	self.anim_implicit_time = this.anim_implicit_time;
	self.anim_lower_implicit_action = this.anim_lower_implicit_action;
	self.anim_lower_implicit_time = this.anim_lower_implicit_time;
	self.anim_upper_implicit_action = this.anim_upper_implicit_action;
	self.anim_upper_implicit_time = this.anim_upper_implicit_time;
	self.dphitcontentsmask = this.dphitcontentsmask;
	self.death_time = this.death_time;
	self.pain_finished = this.pain_finished;
	self.health = this.health;
	self.armorvalue = this.armorvalue;
	self.armortype = this.armortype;
	self.model = this.model;
	self.modelindex = this.modelindex;
	self.skin = this.skin;
	self.species = this.species;
	self.movetype = this.movetype;
	self.solid = this.solid;
	self.ballistics_density = this.ballistics_density;
	self.takedamage = this.takedamage;
	self.customizeentityforclient = this.customizeentityforclient;
	self.uncustomizeentityforclient = this.uncustomizeentityforclient;
	self.uncustomizeentityforclient_set = this.uncustomizeentityforclient_set;
	if (keepvelocity == 1)
		self.velocity = this.velocity;
	self.oldvelocity = self.velocity;
	self.alpha = this.alpha;
	self.fade_time = this.fade_time;
	self.fade_rate = this.fade_rate;
	//self.weapon = this.weapon;
	setorigin(self, this.origin);
	setsize(self, this.mins, this.maxs);
	self.prevorigin = this.origin;
	self.reset = SUB_Remove;

	Drag_MoveDrag(this, self);

	if(self.colormap <= maxclients && self.colormap > 0)
		self.colormap = 1024 + this.clientcolors;

	CSQCMODEL_AUTOINIT(self);
	self.CopyBody_nextthink = this.nextthink;
	self.CopyBody_think = this.think;
	self.nextthink = time;
	self.think = CopyBody_Think;
	// "bake" the current animation frame for clones (they don't get clientside animation)
	animdecide_load_if_needed(self);
	animdecide_setframes(self, false, frame, frame1time, frame2, frame2time);

	setself(this);
}

void player_setupanimsformodel()
{SELFPARAM();
	// load animation info
	animdecide_load_if_needed(self);
	animdecide_setstate(self, 0, false);
}

void player_anim ()
{SELFPARAM();
	int deadbits = (self.anim_state & (ANIMSTATE_DEAD1 | ANIMSTATE_DEAD2));
	if(self.deadflag) {
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
	if(self.frozen)
		animbits |= ANIMSTATE_FROZEN;
	if(self.movetype == MOVETYPE_FOLLOW)
		animbits |= ANIMSTATE_FOLLOW;
	if(self.crouch)
		animbits |= ANIMSTATE_DUCK;
	animdecide_setstate(self, animbits, false);
	animdecide_setimplicitstate(self, (self.flags & FL_ONGROUND));
}

void PlayerCorpseDamage (entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	float take, save;
	vector v;
	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);

	// damage resistance (ignore most of the damage from a bullet or similar)
	damage = max(damage - 5, 1);

	v = healtharmor_applydamage(self.armorvalue, autocvar_g_balance_armor_blockpercent, deathtype, damage);
	take = v.x;
	save = v.y;

	if(sound_allowed(MSG_BROADCAST, attacker))
	{
		if (save > 10)
			sound (self, CH_SHOTS, SND_ARMORIMPACT, VOL_BASE, ATTEN_NORM);
		else if (take > 30)
			sound (self, CH_SHOTS, SND_BODYIMPACT2, VOL_BASE, ATTEN_NORM);
		else if (take > 10)
			sound (self, CH_SHOTS, SND_BODYIMPACT1, VOL_BASE, ATTEN_NORM);
	}

	if (take > 50)
		Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, self, attacker);
	if (take > 100)
		Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, self, attacker);

	self.armorvalue = self.armorvalue - save;
	self.health = self.health - take;
	// pause regeneration for 5 seconds
	self.pauseregen_finished = max(self.pauseregen_finished, time + autocvar_g_balance_pause_health_regen);

	self.dmg_save = self.dmg_save + save;//max(save - 10, 0);
	self.dmg_take = self.dmg_take + take;//max(take - 10, 0);
	self.dmg_inflictor = inflictor;

	if (self.health <= -autocvar_sv_gibhealth && self.alpha >= 0)
	{
		// don't use any animations as a gib
		self.frame = 0;
		// view just above the floor
		self.view_ofs = '0 0 4';

		Violence_GibSplash(self, 1, 1, attacker);
		self.alpha = -1;
		self.solid = SOLID_NOT; // restore later
		self.takedamage = DAMAGE_NO; // restore later
		self.damagedbycontents = false;
	}
}

void calculate_player_respawn_time()
{SELFPARAM();
	if(g_ca)
		return;

	float gametype_setting_tmp;
	float sdelay_max = GAMETYPE_DEFAULTED_SETTING(respawn_delay_max);
	float sdelay_small = GAMETYPE_DEFAULTED_SETTING(respawn_delay_small);
	float sdelay_large = GAMETYPE_DEFAULTED_SETTING(respawn_delay_large);
	float sdelay_small_count = GAMETYPE_DEFAULTED_SETTING(respawn_delay_small_count);
	float sdelay_large_count = GAMETYPE_DEFAULTED_SETTING(respawn_delay_large_count);
	float waves = GAMETYPE_DEFAULTED_SETTING(respawn_waves);

	float pcount = 1;  // Include myself whether or not team is already set right and I'm a "player".
	entity pl;
	if (teamplay)
	{
		FOR_EACH_PLAYER(pl)
			if (pl != self)
				if (pl.team == self.team)
					++pcount;
		if (sdelay_small_count == 0)
			sdelay_small_count = 1;
		if (sdelay_large_count == 0)
			sdelay_large_count = 1;
	}
	else
	{
		FOR_EACH_PLAYER(pl)
			if (pl != self)
				++pcount;
		if (sdelay_small_count == 0)
		{
			if (g_cts)
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
			if (g_cts)
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
		self.respawn_time = ceil((time + sdelay) / waves) * waves;
	else
		self.respawn_time = time + sdelay;

	if(sdelay < sdelay_max)
		self.respawn_time_max = time + sdelay_max;
	else
		self.respawn_time_max = self.respawn_time;

	if((sdelay + waves >= 5.0) && (self.respawn_time - time > 1.75))
		self.respawn_countdown = 10; // first number to count down from is 10
	else
		self.respawn_countdown = -1; // do not count down

	if(autocvar_g_forced_respawn)
		self.respawn_flags = self.respawn_flags | RESPAWN_FORCE;
}

void PlayerDamage (entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	float take, save, dh, da;
	int j;
	vector v;
	float valid_damage_for_weaponstats;
	float excess;

	dh = max(self.health, 0);
	da = max(self.armorvalue, 0);

	if(!DEATH_ISSPECIAL(deathtype))
	{
		damage *= sqrt(bound(1.0, self.cvar_cl_handicap, 100.0));
		if(self != attacker)
			damage /= sqrt(bound(1.0, attacker.cvar_cl_handicap, 100.0));
	}

	if(DEATH_ISWEAPON(deathtype, WEP_TUBA))
	{
		// tuba causes blood to come out of the ears
		vector ear1, ear2;
		vector d;
		float f;
		ear1 = self.origin;
		ear1_z += 0.125 * self.view_ofs.z + 0.875 * self.maxs.z; // 7/8
		ear2 = ear1;
		makevectors(self.angles);
		ear1 += v_right * -10;
		ear2 += v_right * +10;
		d = inflictor.origin - self.origin;
		if (d)
			f = (d * v_right) / vlen(d); // this is cos of angle of d and v_right!
		else
			f = 0;  // Assum ecenter.
		force = v_right * vlen(force);
		Violence_GibSplash_At(ear1, force * -1, 2, bound(0, damage, 25) / 2 * (0.5 - 0.5 * f), self, attacker);
		Violence_GibSplash_At(ear2, force,      2, bound(0, damage, 25) / 2 * (0.5 + 0.5 * f), self, attacker);
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
		Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);


	v = healtharmor_applydamage(self.armorvalue, autocvar_g_balance_armor_blockpercent, deathtype, damage);
	take = v.x;
	save = v.y;

	if(attacker == self)
	{
		// don't reset pushltime for self damage as it may be an attempt to
		// escape a lava pit or similar
		//self.pushltime = 0;
		self.istypefrag = 0;
	}
	else if(IS_PLAYER(attacker))
	{
		self.pusher = attacker;
		self.pushltime = time + autocvar_g_maxpushtime;
		self.istypefrag = self.BUTTON_CHAT;
	}
	else if(time < self.pushltime)
	{
		attacker = self.pusher;
		self.pushltime = max(self.pushltime, time + 0.6);
	}
	else
	{
		self.pushltime = 0;
		self.istypefrag = 0;
	}

	frag_damage = damage;
	MUTATOR_CALLHOOK(PlayerDamage_SplitHealthArmor, inflictor, attacker, self, force, take, save);
	take = bound(0, damage_take, self.health);
	save = bound(0, damage_save, self.armorvalue);
	excess = max(0, damage - take - save);

	if(sound_allowed(MSG_BROADCAST, attacker))
	{
		if (save > 10)
			sound (self, CH_SHOTS, SND_ARMORIMPACT, VOL_BASE, ATTEN_NORM);
		else if (take > 30)
			sound (self, CH_SHOTS, SND_BODYIMPACT2, VOL_BASE, ATTEN_NORM);
		else if (take > 10)
			sound (self, CH_SHOTS, SND_BODYIMPACT1, VOL_BASE, ATTEN_NORM); // FIXME possibly remove them?
	}

	if (take > 50)
		Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, self, attacker);
	if (take > 100)
		Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, self, attacker);

	if (time >= self.spawnshieldtime)
	{
		if (!(self.flags & FL_GODMODE))
		{
			self.armorvalue = self.armorvalue - save;
			self.health = self.health - take;
			// pause regeneration for 5 seconds
			if(take)
				self.pauseregen_finished = max(self.pauseregen_finished, time + autocvar_g_balance_pause_health_regen);

			if (time > self.pain_finished)		//Don't switch pain sequences like crazy
			{
				self.pain_finished = time + 0.5;	//Supajoe

				if(autocvar_sv_gentle < 1) {
					if(self.classname != "body") // pain anim is BORKED on our ZYMs, FIXME remove this once we have good models
					{
						if (!self.animstate_override)
						{
							if (random() > 0.5)
								animdecide_setaction(self, ANIMACTION_PAIN1, true);
							else
								animdecide_setaction(self, ANIMACTION_PAIN2, true);
						}
					}

					if(sound_allowed(MSG_BROADCAST, attacker))
					if((self.health < 2 * WEP_CVAR_PRI(blaster, damage) * autocvar_g_balance_selfdamagepercent + 1) || !(DEATH_WEAPONOF(deathtype).spawnflags & WEP_FLAG_CANCLIMB) || attacker != self) // WEAPONTODO: create separate limit for pain notification with laser
					if(self.health > 1)
					// exclude pain sounds for laserjumps as long as you aren't REALLY low on health and would die of the next two
					{
						if(deathtype == DEATH_FALL.m_id)
							PlayerSound(self, playersound_fall, CH_PAIN, VOICETYPE_PLAYERSOUND);
						else if(self.health > 75) // TODO make a "gentle" version?
							PlayerSound(self, playersound_pain100, CH_PAIN, VOICETYPE_PLAYERSOUND);
						else if(self.health > 50)
							PlayerSound(self, playersound_pain75, CH_PAIN, VOICETYPE_PLAYERSOUND);
						else if(self.health > 25)
							PlayerSound(self, playersound_pain50, CH_PAIN, VOICETYPE_PLAYERSOUND);
						else
							PlayerSound(self, playersound_pain25, CH_PAIN, VOICETYPE_PLAYERSOUND);
					}
				}
			}

			// throw off bot aim temporarily
			float shake;
			if(IS_BOT_CLIENT(self) && self.health >= 1)
			{
				shake = damage * 5 / (bound(0,skill,100) + 1);
				self.v_angle_x = self.v_angle.x + (random() * 2 - 1) * shake;
				self.v_angle_y = self.v_angle.y + (random() * 2 - 1) * shake;
				self.v_angle_x = bound(-90, self.v_angle.x, 90);
			}
		}
		else
			self.max_armorvalue += (save + take);
	}
	self.dmg_save = self.dmg_save + save;//max(save - 10, 0);
	self.dmg_take = self.dmg_take + take;//max(take - 10, 0);
	self.dmg_inflictor = inflictor;

	if (self != attacker) {
		float realdmg = damage - excess;
		if (IS_PLAYER(attacker)) {
			PlayerScore_Add(attacker, SP_DMG, realdmg);
		}
		if (IS_PLAYER(self)) {
			PlayerScore_Add(self, SP_DMGTAKEN, realdmg);
		}
	}

	bool abot = (IS_BOT_CLIENT(attacker));
	bool vbot = (IS_BOT_CLIENT(self));

	valid_damage_for_weaponstats = 0;
	Weapon awep = WEP_Null;

	if(vbot || IS_REAL_CLIENT(self))
	if(abot || IS_REAL_CLIENT(attacker))
	if(attacker && self != attacker)
	if(DIFF_TEAM(self, attacker))
	{
		if(DEATH_ISSPECIAL(deathtype))
			awep = PS(attacker).m_weapon;
		else
			awep = DEATH_WEAPONOF(deathtype);
		valid_damage_for_weaponstats = 1;
	}

	if(valid_damage_for_weaponstats)
	{
		dh = dh - max(self.health, 0);
		da = da - max(self.armorvalue, 0);
		WeaponStats_LogDamage(awep.m_id, abot, PS(self).m_weapon.m_id, vbot, dh + da);
		MUTATOR_CALLHOOK(PlayerDamaged, attacker, self, dh, da, hitloc, deathtype);
	}

	if (self.health < 1)
	{
		float defer_ClientKill_Now_TeamChange;
		defer_ClientKill_Now_TeamChange = false;

		if(self.alivetime)
		{
			PS_GR_P_ADDVAL(self, PLAYERSTATS_ALIVETIME, time - self.alivetime);
			self.alivetime = 0;
		}

		if(valid_damage_for_weaponstats)
			WeaponStats_LogKill(awep.m_id, abot, PS(self).m_weapon.m_id, vbot);

		if(autocvar_sv_gentle < 1) // TODO make a "gentle" version?
		if(sound_allowed(MSG_BROADCAST, attacker))
		{
			if(deathtype == DEATH_DROWN.m_id)
				PlayerSound(self, playersound_drown, CH_PAIN, VOICETYPE_PLAYERSOUND);
			else
				PlayerSound(self, playersound_death, CH_PAIN, VOICETYPE_PLAYERSOUND);
		}

		// get rid of kill indicator
		if(self.killindicator)
		{
			remove(self.killindicator);
			self.killindicator = world;
			if(self.killindicator_teamchange)
				defer_ClientKill_Now_TeamChange = true;

			if(self.classname == "body")
			if(deathtype == DEATH_KILL.m_id)
			{
				// for the lemmings fans, a small harmless explosion
				Send_Effect(EFFECT_ROCKET_EXPLODE, self.origin, '0 0 0', 1);
			}
		}

		// print an obituary message
		if(self.classname != "body")
			Obituary (attacker, inflictor, self, deathtype);

        // increment frag counter for used weapon type
        Weapon w = DEATH_WEAPONOF(deathtype);
        if(w != WEP_Null)
	if(accuracy_isgooddamage(attacker, self))
        attacker.accuracy.(accuracy_frags[w.m_id-1]) += 1;

		MUTATOR_CALLHOOK(PlayerDies, inflictor, attacker, self, deathtype);
		excess = frag_damage;

		Weapon wep = PS(self).m_weapon;
		wep.wr_playerdeath(wep);

		RemoveGrapplingHook(self);

		Portal_ClearAllLater(self);

		self.fixangle = true;

		if(defer_ClientKill_Now_TeamChange)
			ClientKill_Now_TeamChange(); // can turn player into spectator

		// player could have been miraculously resuscitated ;)
		// e.g. players in freezetag get frozen, they don't really die
		if(self.health >= 1 || !(IS_PLAYER(self) || self.classname == "body"))
			return;

		// when we get here, player actually dies

		Unfreeze(self); // remove any icy remains
		self.health = 0; // Unfreeze resets health, so we need to set it back

		// clear waypoints
		WaypointSprite_PlayerDead();
		// throw a weapon
		SpawnThrownWeapon (self.origin + (self.mins + self.maxs) * 0.5, PS(self).m_switchweapon.m_id);

		// become fully visible
		self.alpha = default_player_alpha;
		// make the corpse upright (not tilted)
		self.angles_x = 0;
		self.angles_z = 0;
		// don't spin
		self.avelocity = '0 0 0';
		// view from the floor
		self.view_ofs = '0 0 -8';
		// toss the corpse
		self.movetype = MOVETYPE_TOSS;
		// shootable corpse
		self.solid = SOLID_CORPSE;
		self.ballistics_density = autocvar_g_ballistics_density_corpse;
		// don't stick to the floor
		self.flags &= ~FL_ONGROUND;
		// dying animation
		self.deadflag = DEAD_DYING;

		// when to allow respawn
		calculate_player_respawn_time();

		self.death_time = time;
		if (random() < 0.5)
			animdecide_setstate(self, self.anim_state | ANIMSTATE_DEAD1, true);
		else
			animdecide_setstate(self, self.anim_state | ANIMSTATE_DEAD2, true);
		if (self.maxs.z > 5)
		{
			self.maxs_z = 5;
			setsize(self, self.mins, self.maxs);
		}
		// set damage function to corpse damage
		self.event_damage = PlayerCorpseDamage;
		// call the corpse damage function just in case it wants to gib
		self.event_damage(inflictor, attacker, excess, deathtype, hitloc, force);

		// set up to fade out later
		SUB_SetFade (self, time + 6 + random (), 1);
		// reset body think wrapper broken by SUB_SetFade
		if(self.classname == "body" && self.think != CopyBody_Think) {
			self.CopyBody_think = self.think;
			self.CopyBody_nextthink = self.nextthink;
			self.think = CopyBody_Think;
			self.nextthink = time;
		}

		if(autocvar_sv_gentle > 0 || autocvar_ekg || self.classname == "body") {
			// remove corpse
			// clones don't run any animation code any more, so we must gib them when they die :(
			PlayerCorpseDamage (inflictor, attacker, autocvar_sv_gibhealth+1.0, deathtype, hitloc, force);
		}

		// reset fields the weapons may use just in case
		for (j = WEP_FIRST; j <= WEP_LAST; ++j)
		{
			Weapon w = Weapons_from(j);
			w.wr_resetplayer(w);
			for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				ATTACK_FINISHED_FOR(self, j, slot) = 0;
			}
		}
	}
}

void MoveToTeam(entity client, int team_colour, int type)
{
	int lockteams_backup = lockteams;  // backup any team lock
	lockteams = 0;  // disable locked teams
	TeamchangeFrags(client);  // move the players frags
	SetPlayerColors(client, team_colour - 1);  // set the players colour
	Damage(client, client, client, 100000, DEATH_AUTOTEAMCHANGE.m_id, client.origin, '0 0 0');  // kill the player
	lockteams = lockteams_backup;  // restore the team lock
	LogTeamchange(client.playerid, client.team, type);
}

/**
 * message "": do not say, just test flood control
 * return value:
 *   1 = accept
 *   0 = reject
 *  -1 = fake accept
 */
int Say(entity source, float teamsay, entity privatesay, string msgin, bool floodcontrol)
{
	string msgstr, colorstr, cmsgstr, namestr, fullmsgstr, sourcemsgstr, fullcmsgstr, sourcecmsgstr, colorprefix;
	float flood;
	var .float flood_field;
	entity head;
	float ret;
	string privatemsgprefix = string_null; float privatemsgprefixlen = 0;

	if(!teamsay && !privatesay)
		if(substring(msgin, 0, 1) == " ")
			msgin = substring(msgin, 1, strlen(msgin) - 1); // work around DP say bug (say_team does not have this!)

	msgin = formatmessage(msgin);

	if (!IS_PLAYER(source))
		colorstr = "^0"; // black for spectators
	else if(teamplay)
		colorstr = Team_ColorCode(source.team);
	else
	{
		colorstr = "";
		teamsay = false;
	}

	if(intermission_running)
		teamsay = false;

	if(msgin != "")
		msgin = trigger_magicear_processmessage_forallears(source, teamsay, privatesay, msgin);

	/*
	 * using bprint solves this... me stupid
	// how can we prevent the message from appearing in a listen server?
	// for now, just give "say" back and only handle say_team
	if(!teamsay)
	{
		clientcommand(self, strcat("say ", msgin));
		return;
	}
	*/

	if(autocvar_g_chat_teamcolors)
		namestr = playername(source);
	else
		namestr = source.netname;

	if(strdecolorize(namestr) == namestr)
		colorprefix = "^3";
	else
		colorprefix = "^7";

	if(msgin != "")
	{
		if(privatesay)
		{
			msgstr = strcat("\{1}\{13}* ", colorprefix, namestr, "^3 tells you: ^7");
			privatemsgprefixlen = strlen(msgstr);
			msgstr = strcat(msgstr, msgin);
			cmsgstr = strcat(colorstr, colorprefix, namestr, "^3 tells you:\n^7", msgin);
			if(autocvar_g_chat_teamcolors)
				privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", playername(privatesay), ": ^7");
			else
				privatemsgprefix = strcat("\{1}\{13}* ^3You tell ", privatesay.netname, ": ^7");
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
			else
				msgstr = strcat("\{1}", colorprefix, namestr, "^7: ", msgin);
			cmsgstr = "";
		}
		msgstr = strcat(strreplace("\n", " ", msgstr), "\n"); // newlines only are good for centerprint
	}
	else
	{
		msgstr = cmsgstr = "";
	}

	fullmsgstr = msgstr;
	fullcmsgstr = cmsgstr;

	// FLOOD CONTROL
	flood = 0;
	flood_field = floodcontrol_chat;
	if(floodcontrol)
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

	if(!privatesay)
	if (!IS_PLAYER(source))
	{
		if (!intermission_running)
			if(teamsay || (autocvar_g_chat_nospectators == 1) || (autocvar_g_chat_nospectators == 2 && !(warmup_stage || gameover)))
				teamsay = -1; // spectators
	}

	if(flood)
		LOG_INFO("NOTE: ", playername(source), "^7 is flooding.\n");

	// build sourcemsgstr by cutting off a prefix and replacing it by the other one
	if(privatesay)
		sourcemsgstr = strcat(privatemsgprefix, substring(sourcemsgstr, privatemsgprefixlen, -1));

	if(source.muted)
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
			sprint(privatesay, msgstr);
			if (!autocvar_g_chat_tellprivacy) { dedicated_print(msgstr); } // send to server console too if "tellprivacy" is disabled
			if(cmsgstr != "")
				centerprint(privatesay, cmsgstr);
		}
		else if ( teamsay && source.active_minigame )
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			FOR_EACH_REALCLIENT(head)
				if(head != source)
				if(head.active_minigame == source.active_minigame)
					sprint(head, msgstr);
		}
		else if(teamsay > 0) // team message, only sent to team mates
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			if(sourcecmsgstr != "")
				centerprint(source, sourcecmsgstr);
			FOR_EACH_REALPLAYER(head) if(head.team == source.team)
				if(head != source)
				{
					sprint(head, msgstr);
					if(cmsgstr != "")
						centerprint(head, cmsgstr);
				}
		}
		else if(teamsay < 0) // spectator message, only sent to spectators
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			FOR_EACH_REALCLIENT(head) if (!IS_PLAYER(head))
				if(head != source)
					sprint(head, msgstr);
		}
		else if(sourcemsgstr != msgstr) // trimmed/server fixed message, sent to all players
		{
			sprint(source, sourcemsgstr);
			dedicated_print(msgstr); // send to server console too
			FOR_EACH_REALCLIENT(head)
				if(head != source)
					sprint(head, msgstr);
		}
		else
			bprint(msgstr); // entirely normal message, sent to all players -- bprint sends to server console too.
	}

	return ret;
}
