#include "hlac.qh"

#ifdef SVQC

void W_HLAC_Touch(entity this, entity toucher)
{
	float isprimary;

	PROJECTILE_TOUCH(this, toucher);

	this.event_damage = func_null;

	isprimary = !(this.projectiledeathtype & HITTYPE_SECONDARY);

	RadiusDamage(this, this.realowner,
	             WEP_CVAR_BOTH(WEP_HLAC, isprimary, damage),
	             WEP_CVAR_BOTH(WEP_HLAC, isprimary, edgedamage),
	             WEP_CVAR_BOTH(WEP_HLAC, isprimary, radius),
	             NULL, NULL,
	             WEP_CVAR_BOTH(WEP_HLAC, isprimary, force),
	             this.projectiledeathtype, this.weaponentity_fld, toucher);

	delete(this);
}

void W_HLAC_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity missile;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(WEP_HLAC, ammo), weaponentity);

	float spread = WEP_CVAR_PRI(WEP_HLAC, spread_min) + (WEP_CVAR_PRI(WEP_HLAC, spread_add) * actor.(weaponentity).misc_bulletcounter);
	spread = min(spread,WEP_CVAR_PRI(WEP_HLAC, spread_max));
	if(IS_DUCKED(actor))
		spread = spread * WEP_CVAR_PRI(WEP_HLAC, spread_crouchmod);

	W_SetupShot(actor, weaponentity, false, 3, SND_HLAC_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(WEP_HLAC, damage), thiswep.m_id);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	missile = new(hlacbolt);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;

	missile.bot_dodgerating = WEP_CVAR_PRI(WEP_HLAC, damage);

	set_movetype(missile, MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Basic(missile, WEP_CVAR_PRI(WEP_HLAC, speed), spread);
	//missile.angles = vectoangles(missile.velocity); // csqc

	settouch(missile, W_HLAC_Touch);
	setthink(missile, SUB_Remove);

	missile.nextthink = time + WEP_CVAR_PRI(WEP_HLAC, lifetime);

	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.projectiledeathtype = thiswep.m_id;
	missile.weaponentity_fld = weaponentity;

	CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

void W_HLAC_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity missile;
	float spread = WEP_CVAR_SEC(WEP_HLAC, spread);

	if(IS_DUCKED(actor))
		spread = spread * WEP_CVAR_SEC(WEP_HLAC, spread_crouchmod);

	W_SetupShot(actor, weaponentity, false, 3, SND_HLAC_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(WEP_HLAC, damage) * WEP_CVAR_SEC(WEP_HLAC, shots), thiswep.m_id | HITTYPE_SECONDARY);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(WEP_HLAC, ammo), weaponentity);

	for(int j = WEP_CVAR_SEC(WEP_HLAC, shots); j > 0; --j)
	{
		missile = new(hlacbolt);
		missile.owner = missile.realowner = actor;
		missile.bot_dodge = true;

		missile.bot_dodgerating = WEP_CVAR_SEC(WEP_HLAC, damage);

		set_movetype(missile, MOVETYPE_FLY);
		PROJECTILE_MAKETRIGGER(missile);

		setorigin(missile, w_shotorg);
		setsize(missile, '0 0 0', '0 0 0');

		W_SetupProjVelocity_Basic(missile, WEP_CVAR_SEC(WEP_HLAC, speed), spread);
		//missile.angles = vectoangles(missile.velocity); // csqc

		settouch(missile, W_HLAC_Touch);
		setthink(missile, SUB_Remove);

		missile.nextthink = time + WEP_CVAR_SEC(WEP_HLAC, lifetime);

		missile.flags = FL_PROJECTILE;
		IL_PUSH(g_projectiles, missile);
		IL_PUSH(g_bot_dodge, missile);
		missile.missile_flags = MIF_SPLASH;
		missile.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
		missile.weaponentity_fld = weaponentity;

		CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

		MUTATOR_CALLHOOK(EditProjectile, actor, missile);
	}

	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}
}

// weapon frames
void W_HLAC_Attack_Frame(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(actor.(weaponentity).m_weapon != actor.(weaponentity).m_switchweapon) // abort immediately if switching
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if(PHYS_INPUT_BUTTON_ATCK(actor))
	{
		if(!thiswep.wr_checkammo1(thiswep, actor, weaponentity))
		if(!(actor.items & IT_UNLIMITED_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
			w_ready(thiswep, actor, weaponentity, fire);
			return;
		}

		ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR_PRI(WEP_HLAC, refire) * W_WeaponRateFactor(actor);
		W_HLAC_Attack(thiswep, actor, weaponentity);
		actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_HLAC, refire), W_HLAC_Attack_Frame);
	}
	else
	{
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_HLAC, animtime), w_ready);
	}
}

METHOD(HLAC, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(WEP_HLAC, speed), 0, WEP_CVAR_PRI(WEP_HLAC, lifetime), false, true);
}

METHOD(HLAC, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(autocvar_g_balance_hlac_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(WEP_HLAC, ammo), WEP_CVAR_SEC(WEP_HLAC, ammo))) { // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	} else if(fire & 1)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_HLAC, refire)))
		{
			actor.(weaponentity).misc_bulletcounter = 0;
			W_HLAC_Attack(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_HLAC, refire), W_HLAC_Attack_Frame);
		}
	}

	else if((fire & 2) && WEP_CVAR(WEP_HLAC, secondary))
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_HLAC, refire)))
		{
			W_HLAC_Attack2(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_HLAC, animtime), w_ready);
		}
	}
}

METHOD(HLAC, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_HLAC, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_HLAC, ammo);
	return ammo_amount;
}

METHOD(HLAC, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(WEP_HLAC, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(WEP_HLAC, ammo);
	return ammo_amount;
}

METHOD(HLAC, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(WEP_HLAC, ammo), WEP_CVAR_SEC(WEP_HLAC, ammo)), SND_RELOAD);
}

METHOD(HLAC, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_HLAC_SUICIDE;
}

METHOD(HLAC, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_HLAC_MURDER;
}

METHOD(HLAC, wr_init, void(entity thiswep))
{
	precache_model(MDL_HLAC_VIEW);
	precache_model(MDL_HLAC_WORLD);
	precache_model(MDL_HLAC_ITEM);

	precache_sound(SND_HLAC_FIRE);
}

#endif
#ifdef CSQC

METHOD(HLAC, wr_impacteffect, void(entity thiswep, entity actor))
{
	// TODO: remove this caching & fallback after next release (xonotic-v0.9.0)
	// do the same for the muzzleflash effect in hlac.qh. see also common/effects/all.inc
	entity eff = EFFECT_GREEN_HLAC_IMPACT;
	if (!thiswep.cnt) // cache effect num here
		thiswep.cnt = particleeffectnum(eff); // can't return 0
	if (thiswep.cnt < 0)
		eff = EFFECT_BLASTER_IMPACT; // compatible with Xonotic v0.8.6 or lower

	vector org2 = w_org + w_backoff * 2;
	pointparticles(eff, org2, w_backoff * 1000, 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM);
}

#endif
