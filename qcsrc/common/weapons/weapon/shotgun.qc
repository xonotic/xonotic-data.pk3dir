#include "shotgun.qh"

#ifdef SVQC

// enable to debug melee range
//#define SHOTGUN_MELEEDEBUG

void W_Shotgun_Attack(Weapon thiswep, entity actor, .entity weaponentity,
                      float isprimary, float ammocount, float damage,
                      float falloff_halflife, float falloff_mindist, float falloff_maxdist,
                      float bullets, float spread,
                      float spread_pattern, float spread_pattern_scale, float spread_pattern_bias,
                      float solidpenetration,
                      float force, float falloff_forcehalflife,
                      entity bullet_trail_effect)
{
	W_DecreaseAmmo(thiswep, actor, ammocount, weaponentity);

	W_SetupShot(actor, weaponentity, true, 5, SND_SHOTGUN_FIRE,
		((isprimary) ? CH_WEAPON_A : CH_WEAPON_SINGLE), damage * bullets, thiswep.m_id);

	// TRICK: do the antilag outside the regular fireBullet function,
	// so it isn't performed unnecessarily on every single bullet!
	float lag = antilag_getlag(actor);
	if(lag && bullets > 0)
		antilag_takeback_all(actor, lag);

	if (spread_pattern && spread_pattern_scale > 0)
	{
		vector right, up;
		right = v_right;
		up = v_up;

		float fixed_spread_factor = (spread * autocvar_g_weaponspreadfactor) / spread_pattern_scale;
		spread_pattern_bias = bound(0, spread_pattern_bias, 1);
		for(int sc = 0; sc < bullets; ++sc)
		{
			vector s = W_CalculateSpreadPattern(spread_pattern, spread_pattern_bias, sc, bullets);
			s = s * fixed_spread_factor;
			fireBullet_falloff(actor, weaponentity,
			                   w_shotorg, w_shotdir + right * s.y + up * s.z,
			                   0, solidpenetration, damage,
			                   falloff_halflife, falloff_mindist, falloff_maxdist,
			                   0, force, falloff_forcehalflife,
			                   thiswep.m_id, bullet_trail_effect, false);
		}
	}
	else
		for(int sc = 0; sc < bullets; ++sc)
			fireBullet_falloff(actor, weaponentity,
				w_shotorg, w_shotdir,
				spread, solidpenetration, damage,
				falloff_halflife, falloff_mindist, falloff_maxdist,
				0, force, falloff_forcehalflife,
				thiswep.m_id, bullet_trail_effect, false);

	if(lag && bullets > 0)
		antilag_restore_all(actor);

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	// casing code
	if(autocvar_g_casings >= 1)
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		//for(int sc = 0; sc < WEP_CVAR_PRI(WEP_SHOTGUN, ammo); ++sc)
			SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 30) * v_up), vectoangles(v_forward), 1, actor, weaponentity);
	}
}

.float swing_prev;
.entity swing_alreadyhit;
void W_Shotgun_Melee_Think(entity this)
{
	// declarations
	float i, f, swing, swing_factor, swing_damage, meleetime, is_player;
	entity target_victim;
	vector targpos, melee_path;

	if(!this.cnt) // set start time of melee
	{
		this.cnt = time;
		W_PlayStrengthSound(this.realowner);
	}

	makevectors(this.realowner.v_angle); // update values for v_* vectors

	// calculate swing percentage based on time
	meleetime = WEP_CVAR_SEC(WEP_SHOTGUN, melee_time) * W_WeaponRateFactor(this.realowner);
	swing = bound(0, (this.cnt + meleetime - time) / meleetime, 10);
	f = ((1 - swing) * WEP_CVAR_SEC(WEP_SHOTGUN, melee_traces));

	// check to see if we can still continue, otherwise give up now
	if(IS_DEAD(this.realowner) && WEP_CVAR_SEC(WEP_SHOTGUN, melee_no_doubleslap))
	{
		delete(this);
		return;
	}

	melee_path = (v_up    * WEP_CVAR_SEC(WEP_SHOTGUN, melee_swing_up))
	           + (v_right * WEP_CVAR_SEC(WEP_SHOTGUN, melee_swing_side));
	// if okay, perform the traces needed for this frame
	for(i=this.swing_prev; i < f; ++i)
	{
		swing_factor = ((1 - (i / WEP_CVAR_SEC(WEP_SHOTGUN, melee_traces))) * 2 - 1);

		targpos = this.realowner.origin + this.realowner.view_ofs
			+ (melee_path * swing_factor)
			+ (v_forward * WEP_CVAR_SEC(WEP_SHOTGUN, melee_range));

		WarpZone_traceline_antilag(this.realowner, this.realowner.origin + this.realowner.view_ofs, targpos, false, this.realowner, ((IS_CLIENT(this.realowner)) ? ANTILAG_LATENCY(this.realowner) : 0));

		Send_Effect(EFFECT_SHOTGUN_WOOSH, trace_endpos, -melee_path, 1);

		// draw lightning beams for debugging
	#ifdef SHOTGUN_MELEEDEBUG
		te_lightning2(NULL, targpos, this.realowner.origin + this.realowner.view_ofs + v_forward * 5 - v_up * 5);
		te_customflash(targpos, 40,  2, '1 1 1');
	#endif

		is_player = (IS_PLAYER(trace_ent) || trace_ent.classname == "body" || IS_MONSTER(trace_ent));

		if((trace_fraction < 1) // if trace is good, apply the damage and remove this
			&& (trace_ent.takedamage != DAMAGE_NO)
			&& (trace_ent != this.swing_alreadyhit)
			&& (is_player || WEP_CVAR_SEC(WEP_SHOTGUN, melee_nonplayerdamage)))
		{
			target_victim = trace_ent; // so it persists through other calls

			if(is_player) // this allows us to be able to nerf the non-player damage done in e.g. assault or onslaught.
				swing_damage = (WEP_CVAR_SEC(WEP_SHOTGUN, damage) * min(1, swing_factor + 1));
			else
				swing_damage = (WEP_CVAR_SEC(WEP_SHOTGUN, melee_nonplayerdamage) * min(1, swing_factor + 1));

			//print(strcat(this.realowner.netname, " hitting ", target_victim.netname, " with ", strcat(ftos(swing_damage), " damage (factor: ", ftos(swing_factor), ") at "), ftos(time), " seconds.\n"));

			Damage(target_victim, this.realowner, this.realowner,
				swing_damage, WEP_SHOTGUN.m_id | HITTYPE_SECONDARY, this.weaponentity_fld,
				this.realowner.origin + this.realowner.view_ofs,
				v_forward * WEP_CVAR_SEC(WEP_SHOTGUN, force));

			if(accuracy_isgooddamage(this.realowner, target_victim))
				accuracy_add(this.realowner, WEP_SHOTGUN, 0, swing_damage, 0); // add to hit

			// draw large red flash for debugging
		#ifdef SHOTGUN_MELEEDEBUG
			te_customflash(targpos, 200, 2, '15 0 0');
		#endif

			if(WEP_CVAR_SEC(WEP_SHOTGUN, melee_multihit)) // allow multiple hits with one swing, but not against the same player twice.
			{
				this.swing_alreadyhit = target_victim;
				continue; // move along to next trace
			}
			else
			{
				delete(this);
				return;
			}
		}
	}

	if(time >= this.cnt + meleetime)
	{
		// melee is finished
		delete(this);
		return;
	}
	else
	{
		// set up next frame
		this.swing_prev = i;
		this.nextthink = time;
	}
}

void W_Shotgun_Attack2(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	sound(actor, CH_WEAPON_A, SND_SHOTGUN_MELEE, VOL_BASE, ATTEN_NORM);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_SHOTGUN, animtime), w_ready);

	entity meleetemp = new_pure(meleetemp);
	meleetemp.realowner = actor;
	setthink(meleetemp, W_Shotgun_Melee_Think);
	meleetemp.nextthink = time + WEP_CVAR_SEC(WEP_SHOTGUN, melee_delay) * W_WeaponRateFactor(actor);
	meleetemp.weaponentity_fld = weaponentity;
	W_SetupShot_Range(actor, weaponentity, true, 0, SND_Null, 0, WEP_CVAR_SEC(WEP_SHOTGUN, damage), WEP_CVAR_SEC(WEP_SHOTGUN, melee_range), WEP_SHOTGUN.m_id | HITTYPE_SECONDARY);
}

// alternate secondary weapon frames
void W_Shotgun_Attack3_Frame2(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if (!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
	if (!(actor.items & IT_UNLIMITED_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	sound(actor, CH_WEAPON_SINGLE, SND_Null, VOL_BASE, ATTN_NORM); // kill previous sound
	W_Shotgun_Attack(thiswep, actor, weaponentity, true,
		WEP_CVAR_PRI(WEP_SHOTGUN, ammo),
		WEP_CVAR_PRI(WEP_SHOTGUN, damage),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_halflife),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_mindist),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_maxdist),
		WEP_CVAR_PRI(WEP_SHOTGUN, bullets),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_scale),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_bias),
		WEP_CVAR_PRI(WEP_SHOTGUN, solidpenetration),
		WEP_CVAR_PRI(WEP_SHOTGUN, force),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_forcehalflife),
		EFFECT_BULLET_WEAK); // actually is secondary, but we trick the last shot into playing full reload sound
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(WEP_SHOTGUN, alt_animtime), w_ready);
}
void W_Shotgun_Attack3_Frame1(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if (!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
	if (!(actor.items & IT_UNLIMITED_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_Shotgun_Attack(thiswep, actor, weaponentity, false,
		WEP_CVAR_PRI(WEP_SHOTGUN, ammo),
		WEP_CVAR_PRI(WEP_SHOTGUN, damage),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_halflife),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_mindist),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_maxdist),
		WEP_CVAR_PRI(WEP_SHOTGUN, bullets),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_scale),
		WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_bias),
		WEP_CVAR_PRI(WEP_SHOTGUN, solidpenetration),
		WEP_CVAR_PRI(WEP_SHOTGUN, force),
		WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_forcehalflife),
		EFFECT_BULLET_WEAK);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(WEP_SHOTGUN, alt_animtime), W_Shotgun_Attack3_Frame2);
}

.float shotgun_primarytime;

METHOD(Shotgun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(vdist(actor.origin - actor.enemy.origin, <=, WEP_CVAR_SEC(WEP_SHOTGUN, melee_range)))
		PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, false);
	else
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, false);
}

METHOD(Shotgun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	// force reload weapon when clip is empty or insufficent
	if(WEP_CVAR(WEP_SHOTGUN, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(WEP_SHOTGUN, ammo))
	{
		if(actor.(weaponentity).clip_load >= 0 && (GetResource(actor, thiswep.ammo_type) > 0 || (actor.items & IT_UNLIMITED_AMMO)))
		{
			thiswep.wr_reload(thiswep, actor, weaponentity);
			return;
		}
	}

	if(actor.(weaponentity).clip_load >= 0) // we are not currently reloading
	{
		if(fire & 1)
		{
			if(time >= actor.(weaponentity).shotgun_primarytime) // handle refire separately so the secondary can be fired straight after a primary
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_SHOTGUN, animtime)))
				{
					W_Shotgun_Attack(thiswep, actor, weaponentity, true,
						WEP_CVAR_PRI(WEP_SHOTGUN, ammo),
						WEP_CVAR_PRI(WEP_SHOTGUN, damage),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_halflife),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_mindist),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_maxdist),
						WEP_CVAR_PRI(WEP_SHOTGUN, bullets),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_scale),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_bias),
						WEP_CVAR_PRI(WEP_SHOTGUN, solidpenetration),
						WEP_CVAR_PRI(WEP_SHOTGUN, force),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_forcehalflife),
						EFFECT_BULLET_WEAK);
					actor.(weaponentity).shotgun_primarytime = time + WEP_CVAR_PRI(WEP_SHOTGUN, refire) * W_WeaponRateFactor(actor);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_SHOTGUN, animtime), w_ready);
					return;
				}
			}
		}
		else if((fire & 2) && WEP_CVAR(WEP_SHOTGUN, secondary) == 2)
		{
			if(time >= actor.(weaponentity).shotgun_primarytime) // handle refire separately so the secondary can be fired straight after a primary
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(WEP_SHOTGUN, alt_animtime)))
				{
					W_Shotgun_Attack(thiswep, actor, weaponentity, false,
						WEP_CVAR_PRI(WEP_SHOTGUN, ammo),
						WEP_CVAR_PRI(WEP_SHOTGUN, damage),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_halflife),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_mindist),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_maxdist),
						WEP_CVAR_PRI(WEP_SHOTGUN, bullets),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_scale),
						WEP_CVAR_PRI(WEP_SHOTGUN, spread_pattern_bias),
						WEP_CVAR_PRI(WEP_SHOTGUN, solidpenetration),
						WEP_CVAR_PRI(WEP_SHOTGUN, force),
						WEP_CVAR_PRI(WEP_SHOTGUN, damagefalloff_forcehalflife),
						EFFECT_BULLET_WEAK);
					actor.(weaponentity).shotgun_primarytime = time + WEP_CVAR_SEC(WEP_SHOTGUN, alt_refire) * W_WeaponRateFactor(actor);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_SEC(WEP_SHOTGUN, alt_animtime), W_Shotgun_Attack3_Frame1);
					return;
				}
			}
		}
	}

	if(actor.(weaponentity).clip_load >= 0) // we are not currently reloading
	if(WEP_CVAR(WEP_SHOTGUN, secondary) == 1)
	if(((fire & 1) && !IS_BOT_CLIENT(actor) && GetResource(actor, thiswep.ammo_type) <= 0 && actor.(weaponentity).clip_load == 0 && !(actor.items & IT_UNLIMITED_AMMO)) || (fire & 2))
	if(!WEP_CVAR_SEC(WEP_SHOTGUN, melee_blockedbyfiring) || time >= actor.(weaponentity).shotgun_primarytime)
	if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_SHOTGUN, refire)))
	{
		// melee attack
		// attempt forcing playback of the anim by switching to another anim (that we never play) here...
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, W_Shotgun_Attack2);
	}
}

METHOD(Shotgun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_SHOTGUN, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_SHOTGUN, ammo);
	return ammo_amount;
}

METHOD(Shotgun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	switch(WEP_CVAR(WEP_SHOTGUN, secondary))
	{
		case 1: return true; // melee does not use ammo
		case 2: // secondary triple shot
		{
			float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_SHOTGUN, ammo);
			ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_SHOTGUN, ammo);
			return ammo_amount;
		}
		default: return false; // secondary unavailable
	}
}

METHOD(Shotgun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, WEP_CVAR_PRI(WEP_SHOTGUN, ammo), SND_RELOAD); // WEAPONTODO
}

METHOD(Shotgun, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(Shotgun, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_SHOTGUN_MURDER_SLAP;
	else
		return WEAPON_SHOTGUN_MURDER;
}

#endif
#ifdef CSQC
.float prevric;

METHOD(Shotgun, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_SHOTGUN_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent && time - actor.prevric > 0.25)
	{
		if(w_random < 0.05)
			sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
		actor.prevric = time;
	}
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>

METHOD(Shotgun, describe, string(Shotgun this))
{
	TC(Shotgun, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s is one of the two main default weapons, firing a single shotgun round which spreads into multiple pellets upon exiting the barrel."), COLORED_NAME(this));
	PAR(_("The secondary fire swings the %s, slapping players close enough with the head of the weapon. "
	      "Since the slap takes a moment to land, timing this well is difficult."), COLORED_NAME(this));
	PAR(_("The primary fire consumes %s ammo, although if you spawn in with the %s you will already have some."), COLORED_NAME(ITEM_Shells), COLORED_NAME(this));
	PAR(_("The %s damage drops off quickly as the range increases, so it is only useful for close combat or sometimes medium range combat."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_primaryMultishot(this.netname, "primary", "secondary", "primary_bullets", ""));
	return PAGE_TEXT;
}

#endif
