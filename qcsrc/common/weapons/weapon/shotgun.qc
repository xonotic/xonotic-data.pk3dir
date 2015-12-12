#ifndef IMPLEMENTATION
CLASS(Shotgun, Weapon)
/* ammotype  */ ATTRIB(Shotgun, ammo_field, .int, ammo_shells)
/* impulse   */ ATTRIB(Shotgun, impulse, int, 2)
/* flags     */ ATTRIB(Shotgun, spawnflags, int, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN);
/* rating    */ ATTRIB(Shotgun, bot_pickupbasevalue, float, BOT_PICKUP_RATING_LOW);
/* color     */ ATTRIB(Shotgun, wpcolor, vector, '0.5 0.25 0');
/* modelname */ ATTRIB(Shotgun, mdl, string, "shotgun");
#ifndef MENUQC
/* model     */ ATTRIB(Shotgun, m_model, Model, MDL_SHOTGUN_ITEM);
#endif
/* crosshair */ ATTRIB(Shotgun, w_crosshair, string, "gfx/crosshairshotgun");
/* crosshair */ ATTRIB(Shotgun, w_crosshair_size, float, 0.65);
/* wepimg    */ ATTRIB(Shotgun, model2, string, "weaponshotgun");
/* refname   */ ATTRIB(Shotgun, netname, string, "shotgun");
/* wepname   */ ATTRIB(Shotgun, m_name, string, _("Shotgun"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, alt_animtime, float, SEC) \
		P(class, prefix, alt_refire, float, SEC) \
		P(class, prefix, ammo, float, PRI) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, bullets, float, PRI) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, force, float, BOTH) \
		P(class, prefix, melee_delay, float, SEC) \
		P(class, prefix, melee_multihit, float, SEC) \
		P(class, prefix, melee_nonplayerdamage, float, SEC) \
		P(class, prefix, melee_no_doubleslap, float, SEC) \
		P(class, prefix, melee_range, float, SEC) \
		P(class, prefix, melee_swing_side, float, SEC) \
		P(class, prefix, melee_swing_up, float, SEC) \
		P(class, prefix, melee_time, float, SEC) \
		P(class, prefix, melee_traces, float, SEC) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, reload_ammo, float, NONE) \
        P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, secondary, float, NONE) \
		P(class, prefix, solidpenetration, float, PRI) \
		P(class, prefix, spread, float, PRI) \
        P(class, prefix, switchdelay_drop, float, NONE) \
        P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, weaponreplace, string,NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, Shotgun, shotgun)
#undef X

ENDCLASS(Shotgun)
REGISTER_WEAPON(SHOTGUN, shotgun, NEW(Shotgun));


#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_shotgun) { weapon_defaultspawnfunc(this, WEP_SHOTGUN); }

void W_Shotgun_Attack(Weapon thiswep, float isprimary)
{SELFPARAM();
	float	sc;
	entity flash;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR_PRI(shotgun, ammo));

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
	flash.think = SUB_Remove_self;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(self, flash, '5 0 0');
}

.float swing_prev;
.entity swing_alreadyhit;
void W_Shotgun_Melee_Think()
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

void W_Shotgun_Attack2(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	sound(actor, CH_WEAPON_A, SND_SHOTGUN_MELEE, VOL_BASE, ATTEN_NORM);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(shotgun, animtime), w_ready);

	entity meleetemp = new(meleetemp);
	make_pure(meleetemp);
	meleetemp.realowner = actor;
	meleetemp.think = W_Shotgun_Melee_Think;
	meleetemp.nextthink = time + WEP_CVAR_SEC(shotgun, melee_delay) * W_WeaponRateFactor();
	W_SetupShot_Range(actor, true, 0, "", 0, WEP_CVAR_SEC(shotgun, damage), WEP_CVAR_SEC(shotgun, melee_range));
}

// alternate secondary weapon frames
void W_Shotgun_Attack3_Frame2(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if (!thiswep.wr_checkammo2(thiswep))
	if (!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	sound(actor, CH_WEAPON_SINGLE, SND_Null, VOL_BASE, ATTN_NORM); // kill previous sound
	W_Shotgun_Attack(WEP_SHOTGUN, true); // actually is secondary, but we trick the last shot into playing full reload sound
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(shotgun, alt_animtime), w_ready);
}
void W_Shotgun_Attack3_Frame1(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if (!thiswep.wr_checkammo2(thiswep))
	if (!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_Shotgun_Attack(WEP_SHOTGUN, false);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(shotgun, alt_animtime), W_Shotgun_Attack3_Frame2);
}

.float shotgun_primarytime;

		METHOD(Shotgun, wr_aim, void(entity thiswep))
		{
			if(vlen(self.origin-self.enemy.origin) <= WEP_CVAR_SEC(shotgun, melee_range))
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, false);
			else
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, false);
		}
		METHOD(Shotgun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(WEP_CVAR(shotgun, reload_ammo) && actor.clip_load < WEP_CVAR_PRI(shotgun, ammo)) // forced reload
			{
				// don't force reload an empty shotgun if its melee attack is active
				if(WEP_CVAR(shotgun, secondary) < 2) {
					thiswep.wr_reload(thiswep);
				}
			}
			else
			{
				if(fire & 1)
				{
					if(time >= actor.shotgun_primarytime) // handle refire separately so the secondary can be fired straight after a primary
					{
						if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(shotgun, animtime)))
						{
							W_Shotgun_Attack(thiswep, true);
							actor.shotgun_primarytime = time + WEP_CVAR_PRI(shotgun, refire) * W_WeaponRateFactor();
							weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(shotgun, animtime), w_ready);
						}
					}
				}
				else if((fire & 2) && WEP_CVAR(shotgun, secondary) == 2)
				{
					if(time >= actor.shotgun_primarytime) // handle refire separately so the secondary can be fired straight after a primary
					{
						if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(shotgun, alt_animtime)))
						{
							W_Shotgun_Attack(thiswep, false);
							actor.shotgun_primarytime = time + WEP_CVAR_SEC(shotgun, alt_refire) * W_WeaponRateFactor();
							weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(shotgun, alt_animtime), W_Shotgun_Attack3_Frame1);
						}
					}
				}
			}
			if(actor.clip_load >= 0) // we are not currently reloading
			if(!actor.crouch) // no crouchmelee please
			if(WEP_CVAR(shotgun, secondary) == 1)
			if(((fire & 1) && actor.(thiswep.ammo_field) <= 0 && !(actor.items & IT_UNLIMITED_WEAPON_AMMO)) || (fire & 2))
			if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(shotgun, refire)))
			{
				// attempt forcing playback of the anim by switching to another anim (that we never play) here...
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, W_Shotgun_Attack2);
			}
		}
		METHOD(Shotgun, wr_setup, void(entity thiswep))
		{
			self.ammo_field = ammo_none;
		}
		METHOD(Shotgun, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_PRI(shotgun, ammo);
			ammo_amount += self.(weapon_load[WEP_SHOTGUN.m_id]) >= WEP_CVAR_PRI(shotgun, ammo);
			return ammo_amount;
		}
		METHOD(Shotgun, wr_checkammo2, bool(entity thiswep))
		{
			if(IS_BOT_CLIENT(self))
			if(vlen(self.origin-self.enemy.origin) > WEP_CVAR_SEC(shotgun, melee_range))
				return false; // bots cannot use secondary out of range (fixes constant melee when out of ammo)
			switch(WEP_CVAR(shotgun, secondary))
			{
				case 1: return true; // melee does not use ammo
				case 2: // secondary triple shot
				{
					float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_PRI(shotgun, ammo);
					ammo_amount += self.(weapon_load[WEP_SHOTGUN.m_id]) >= WEP_CVAR_PRI(shotgun, ammo);
					return ammo_amount;
				}
				default: return false; // secondary unavailable
			}
		}
		METHOD(Shotgun, wr_reload, void(entity thiswep))
		{
			W_Reload(self, WEP_CVAR_PRI(shotgun, ammo), SND(RELOAD)); // WEAPONTODO
		}
		METHOD(Shotgun, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		METHOD(Shotgun, wr_killmessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_SHOTGUN_MURDER_SLAP;
			else
				return WEAPON_SHOTGUN_MURDER;
		}

#endif
#ifdef CSQC
.float prevric;

		METHOD(Shotgun, wr_impacteffect, void(entity thiswep))
		{
			vector org2 = w_org + w_backoff * 2;
			pointparticles(EFFECT_SHOTGUN_IMPACT, org2, w_backoff * 1000, 1);
			if(!w_issilent && time - self.prevric > 0.25)
			{
				if(w_random < 0.05)
					sound(self, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
				self.prevric = time;
			}
		}

#endif
#endif
