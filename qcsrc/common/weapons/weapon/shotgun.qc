#ifndef IMPLEMENTATION
REGISTER_WEAPON(
/* WEP_##id  */ SHOTGUN,
/* function  */ W_Shotgun,
/* ammotype  */ ammo_shells,
/* impulse   */ 2,
/* flags     */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN,
/* rating    */ BOT_PICKUP_RATING_LOW,
/* color     */ '0.5 0.25 0',
/* modelname */ "shotgun",
/* simplemdl */ "foobar",
/* crosshair */ "gfx/crosshairshotgun 0.65",
/* wepimg    */ "weaponshotgun",
/* refname   */ "shotgun",
/* wepname   */ _("Shotgun")
);

#define SHOTGUN_SETTINGS(w_cvar,w_prop) SHOTGUN_SETTINGS_LIST(w_cvar, w_prop, SHOTGUN, shotgun)
#define SHOTGUN_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, PRI,  ammo) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, PRI,  bullets) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, PRI,  solidpenetration) \
	w_cvar(id, sn, PRI,  spread) \
	w_cvar(id, sn, NONE, secondary) \
	w_cvar(id, sn, SEC,  melee_time) \
	w_cvar(id, sn, SEC,  melee_no_doubleslap) \
	w_cvar(id, sn, SEC,  melee_traces) \
	w_cvar(id, sn, SEC,  melee_swing_up) \
	w_cvar(id, sn, SEC,  melee_swing_side) \
	w_cvar(id, sn, SEC,  melee_nonplayerdamage) \
	w_cvar(id, sn, SEC,  melee_multihit) \
	w_cvar(id, sn, SEC,  melee_delay) \
	w_cvar(id, sn, SEC,  melee_range) \
	w_cvar(id, sn, SEC,  alt_animtime) \
	w_cvar(id, sn, SEC,  alt_refire) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
SHOTGUN_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_shotgun) { weapon_defaultspawnfunc(WEP_SHOTGUN.m_id); }

void W_Shotgun_Attack(float isprimary)
{SELFPARAM();
	float	sc;
	entity flash;

	W_DecreaseAmmo(WEP_CVAR_PRI(shotgun, ammo));

	W_SetupShot(self, true, 5, SND(SHOTGUN_FIRE), ((isprimary) ? CH_WEAPON_A : CH_WEAPON_SINGLE), WEP_CVAR_PRI(shotgun, damage) * WEP_CVAR_PRI(shotgun, bullets));
	for(sc = 0;sc < WEP_CVAR_PRI(shotgun, bullets);sc = sc + 1)
		fireBullet(w_shotorg, w_shotdir, WEP_CVAR_PRI(shotgun, spread), WEP_CVAR_PRI(shotgun, solidpenetration), WEP_CVAR_PRI(shotgun, damage), WEP_CVAR_PRI(shotgun, force), WEP_SHOTGUN.m_id, 0);

	Send_Effect(EFFECT_SHOTGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, WEP_CVAR_PRI(shotgun, ammo));

	// casing code
	if(autocvar_g_casings >= 1)
		for(sc = 0;sc < WEP_CVAR_PRI(shotgun, ammo);sc = sc + 1)
			SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, MDL_SHOTGUN_MUZZLEFLASH); // precision set below
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');
}

.float swing_prev;
.entity swing_alreadyhit;
void W_Shotgun_Melee_Think(void)
{SELFPARAM();
	// declarations
	float i, f, swing, swing_factor, swing_damage, meleetime, is_player;
	entity target_victim;
	vector targpos;

	if(!self.cnt) // set start time of melee
	{
		self.cnt = time;
		W_PlayStrengthSound(self.realowner);
	}

	makevectors(self.realowner.v_angle); // update values for v_* vectors

	// calculate swing percentage based on time
	meleetime = WEP_CVAR_SEC(shotgun, melee_time) * W_WeaponRateFactor();
	swing = bound(0, (self.cnt + meleetime - time) / meleetime, 10);
	f = ((1 - swing) * WEP_CVAR_SEC(shotgun, melee_traces));

	// check to see if we can still continue, otherwise give up now
	if((self.realowner.deadflag != DEAD_NO) && WEP_CVAR_SEC(shotgun, melee_no_doubleslap))
	{
		remove(self);
		return;
	}

	// if okay, perform the traces needed for this frame
	for(i=self.swing_prev; i < f; ++i)
	{
		swing_factor = ((1 - (i / WEP_CVAR_SEC(shotgun, melee_traces))) * 2 - 1);

		targpos = (self.realowner.origin + self.realowner.view_ofs
			+ (v_forward * WEP_CVAR_SEC(shotgun, melee_range))
			+ (v_up * swing_factor * WEP_CVAR_SEC(shotgun, melee_swing_up))
			+ (v_right * swing_factor * WEP_CVAR_SEC(shotgun, melee_swing_side)));

		WarpZone_traceline_antilag(self, self.realowner.origin + self.realowner.view_ofs, targpos, false, self, ANTILAG_LATENCY(self.realowner));

		// draw lightning beams for debugging
		//te_lightning2(world, targpos, self.realowner.origin + self.realowner.view_ofs + v_forward * 5 - v_up * 5);
		//te_customflash(targpos, 40,  2, '1 1 1');

		is_player = (IS_PLAYER(trace_ent) || trace_ent.classname == "body" || IS_MONSTER(trace_ent));

		if((trace_fraction < 1) // if trace is good, apply the damage and remove self
			&& (trace_ent.takedamage == DAMAGE_AIM)
			&& (trace_ent != self.swing_alreadyhit)
			&& (is_player || WEP_CVAR_SEC(shotgun, melee_nonplayerdamage)))
		{
			target_victim = trace_ent; // so it persists through other calls

			if(is_player) // this allows us to be able to nerf the non-player damage done in e.g. assault or onslaught.
				swing_damage = (WEP_CVAR_SEC(shotgun, damage) * min(1, swing_factor + 1));
			else
				swing_damage = (WEP_CVAR_SEC(shotgun, melee_nonplayerdamage) * min(1, swing_factor + 1));

			//print(strcat(self.realowner.netname, " hitting ", target_victim.netname, " with ", strcat(ftos(swing_damage), " damage (factor: ", ftos(swing_factor), ") at "), ftos(time), " seconds.\n"));

			Damage(target_victim, self.realowner, self.realowner,
				swing_damage, WEP_SHOTGUN.m_id | HITTYPE_SECONDARY,
				self.realowner.origin + self.realowner.view_ofs,
				v_forward * WEP_CVAR_SEC(shotgun, force));

			if(accuracy_isgooddamage(self.realowner, target_victim)) { accuracy_add(self.realowner, WEP_SHOTGUN.m_id, 0, swing_damage); }

			// draw large red flash for debugging
			//te_customflash(targpos, 200, 2, '15 0 0');

			if(WEP_CVAR_SEC(shotgun, melee_multihit)) // allow multiple hits with one swing, but not against the same player twice.
			{
				self.swing_alreadyhit = target_victim;
				continue; // move along to next trace
			}
			else
			{
				remove(self);
				return;
			}
		}
	}

	if(time >= self.cnt + meleetime)
	{
		// melee is finished
		remove(self);
		return;
	}
	else
	{
		// set up next frame
		self.swing_prev = i;
		self.nextthink = time;
	}
}

void W_Shotgun_Attack2(void)
{SELFPARAM();
	sound(self, CH_WEAPON_A, SND_SHOTGUN_MELEE, VOL_BASE, ATTEN_NORM);
	weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(shotgun, animtime), w_ready);

	entity meleetemp;
	meleetemp = spawn();
	meleetemp.realowner = self;
	meleetemp.think = W_Shotgun_Melee_Think;
	meleetemp.nextthink = time + WEP_CVAR_SEC(shotgun, melee_delay) * W_WeaponRateFactor();
	W_SetupShot_Range(self, true, 0, "", 0, WEP_CVAR_SEC(shotgun, damage), WEP_CVAR_SEC(shotgun, melee_range));
}

// alternate secondary weapon frames
void W_Shotgun_Attack3_Frame2()
{SELFPARAM();
	if (!WEP_ACTION(self.weapon, WR_CHECKAMMO2))
	if (!(self.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(self, w_getbestweapon(self));
		w_ready();
		return;
	}

	sound(self, CH_WEAPON_SINGLE, SND_Null, VOL_BASE, ATTN_NORM); // kill previous sound
	W_Shotgun_Attack(true); // actually is secondary, but we trick the last shot into playing full reload sound
	weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_SEC(shotgun, alt_animtime), w_ready);
}
void W_Shotgun_Attack3_Frame1()
{SELFPARAM();
	if (!WEP_ACTION(self.weapon, WR_CHECKAMMO2))
	if (!(self.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(self, w_getbestweapon(self));
		w_ready();
		return;
	}

	W_Shotgun_Attack(false);
	weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_SEC(shotgun, alt_animtime), W_Shotgun_Attack3_Frame2);
}

.float shotgun_primarytime;

float W_Shotgun(float req)
{SELFPARAM();
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			if(vlen(self.origin-self.enemy.origin) <= WEP_CVAR_SEC(shotgun, melee_range))
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, false);
			else
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, false);

			return true;
		}
		case WR_THINK:
		{
			if(WEP_CVAR(shotgun, reload_ammo) && self.clip_load < WEP_CVAR_PRI(shotgun, ammo)) // forced reload
			{
				// don't force reload an empty shotgun if its melee attack is active
				if(WEP_CVAR(shotgun, secondary) < 2)
					WEP_ACTION(self.weapon, WR_RELOAD);
			}
			else
			{
				if(self.BUTTON_ATCK)
				{
					if(time >= self.shotgun_primarytime) // handle refire separately so the secondary can be fired straight after a primary
					{
						if(weapon_prepareattack(0, WEP_CVAR_PRI(shotgun, animtime)))
						{
							W_Shotgun_Attack(true);
							self.shotgun_primarytime = time + WEP_CVAR_PRI(shotgun, refire) * W_WeaponRateFactor();
							weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(shotgun, animtime), w_ready);
						}
					}
				}
				else if(self.BUTTON_ATCK2 && WEP_CVAR(shotgun, secondary) == 2)
				{
					if(time >= self.shotgun_primarytime) // handle refire separately so the secondary can be fired straight after a primary
					{
						if(weapon_prepareattack(0, WEP_CVAR_SEC(shotgun, alt_animtime)))
						{
							W_Shotgun_Attack(false);
							self.shotgun_primarytime = time + WEP_CVAR_SEC(shotgun, alt_refire) * W_WeaponRateFactor();
							weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_SEC(shotgun, alt_animtime), W_Shotgun_Attack3_Frame1);
						}
					}
				}
			}
			if(self.clip_load >= 0) // we are not currently reloading
			if(!self.crouch) // no crouchmelee please
			if(WEP_CVAR(shotgun, secondary) == 1)
			if((self.BUTTON_ATCK && self.WEP_AMMO(SHOTGUN) <= 0 && !(self.items & IT_UNLIMITED_WEAPON_AMMO)) || self.BUTTON_ATCK2)
			if(weapon_prepareattack(1, WEP_CVAR_SEC(shotgun, refire)))
			{
				// attempt forcing playback of the anim by switching to another anim (that we never play) here...
				weapon_thinkf(WFRAME_FIRE1, 0, W_Shotgun_Attack2);
			}

			return true;
		}
		case WR_INIT:
		{
			SHOTGUN_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
			return true;
		}
		case WR_SETUP:
		{
			self.ammo_field = ammo_none;
			return true;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.WEP_AMMO(SHOTGUN) >= WEP_CVAR_PRI(shotgun, ammo);
			ammo_amount += self.(weapon_load[WEP_SHOTGUN.m_id]) >= WEP_CVAR_PRI(shotgun, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			if(IS_BOT_CLIENT(self))
			if(vlen(self.origin-self.enemy.origin) > WEP_CVAR_SEC(shotgun, melee_range))
				return false; // bots cannot use secondary out of range (fixes constant melee when out of ammo)
			switch(WEP_CVAR(shotgun, secondary))
			{
				case 1: return true; // melee does not use ammo
				case 2: // secondary triple shot
				{
					ammo_amount = self.WEP_AMMO(SHOTGUN) >= WEP_CVAR_PRI(shotgun, ammo);
					ammo_amount += self.(weapon_load[WEP_SHOTGUN.m_id]) >= WEP_CVAR_PRI(shotgun, ammo);
					return ammo_amount;
				}
				default: return false; // secondary unavailable
			}
		}
		case WR_CONFIG:
		{
			SHOTGUN_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
			return true;
		}
		case WR_RELOAD:
		{
			W_Reload(WEP_CVAR_PRI(shotgun, ammo), SND(RELOAD)); // WEAPONTODO
			return true;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		case WR_KILLMESSAGE:
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_SHOTGUN_MURDER_SLAP;
			else
				return WEAPON_SHOTGUN_MURDER;
		}
	}
	return false;
}
#endif
#ifdef CSQC
.float prevric;
float W_Shotgun(float req)
{SELFPARAM();
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 2;
			pointparticles(particleeffectnum(EFFECT_SHOTGUN_IMPACT), org2, w_backoff * 1000, 1);
			if(!w_issilent && time - self.prevric > 0.25)
			{
				if(w_random < 0.0165)
					sound(self, CH_SHOTS, SND_RIC1, VOL_BASE, ATTEN_NORM);
				else if(w_random < 0.033)
					sound(self, CH_SHOTS, SND_RIC2, VOL_BASE, ATTEN_NORM);
				else if(w_random < 0.05)
					sound(self, CH_SHOTS, SND_RIC3, VOL_BASE, ATTEN_NORM);
				self.prevric = time;
			}

			return true;
		}
		case WR_INIT:
		{
			return true;
		}
		case WR_ZOOMRETICLE:
		{
			// no weapon specific image for this weapon
			return false;
		}
	}
	return false;
}
#endif
#endif
