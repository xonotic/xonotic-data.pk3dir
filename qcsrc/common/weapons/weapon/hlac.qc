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
	if(IS_DUCKED(actor) && IS_ONGROUND(actor))
		spread *= WEP_CVAR_PRI(WEP_HLAC, spread_crouchmod);

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

	if(IS_DUCKED(actor) && IS_ONGROUND(actor))
		spread *= WEP_CVAR_SEC(WEP_HLAC, spread_crouchmod);

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
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include "blaster.qh"

METHOD(HLAC, describe, string(HLAC this))
{
	TC(HLAC, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s (or HLAC for short) fires lasers in quick succession. "
	      "The projectiles it fires are similar to those of the %s."), COLORED_NAME(this), COLORED_NAME(WEP_BLASTER));
	PAR(_("The secondary fire shoots a burst of multiple randomly-scattered lasers at once."));
	PAR(_("Unlike the %s, it consumes %s ammo for each laser shot, meaning that it cannot be used infinitely."), COLORED_NAME(WEP_BLASTER), COLORED_NAME(ITEM_Cells));
	PAR(_("The %s works best in close ranges, but the primary fire is also useful in medium ranges."), COLORED_NAME(this));
	PAR(_("A unique aspect of the %s is that the longer the primary fire is held, the more that the lasers will start to spread out. "
	      "This means releasing primary fire every now and then is important to restore accuracy. "
	      "Also, the %s has less spread when used while crouching."), COLORED_NAME(this), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_secondaryMultishot(this.netname, "primary", "secondary", "secondary_shots", "", false));
	return PAGE_TEXT;
}

#endif
