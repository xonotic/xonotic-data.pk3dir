#include "blaster.qh"

#ifdef SVQC

void W_Blaster_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	this.event_damage = func_null;

	vector force_xyzscale = '1 1 1';
	force_xyzscale.z = WEP_CVAR_PRI(WEP_BLASTER, force_zscale);

	// slightly hacky but probably not worth adding a parameter for this special case
	bool zero_damageforcescale = false;
	if (autocvar_g_projectiles_interact == 1 && (toucher.flags & FL_PROJECTILE) && !toucher.damageforcescale)
	{
		toucher.damageforcescale = 1;
		zero_damageforcescale = true;
	}

	RadiusDamageForSource(
		this,
		(this.origin + (this.mins + this.maxs) * 0.5),
		this.velocity,
		this.realowner,
		WEP_CVAR_PRI(WEP_BLASTER, damage),
		WEP_CVAR_PRI(WEP_BLASTER, edgedamage),
		WEP_CVAR_PRI(WEP_BLASTER, radius),
		NULL,
		NULL,
		false,
		WEP_CVAR_PRI(WEP_BLASTER, force),
		force_xyzscale,
		this.projectiledeathtype,
		this.weaponentity_fld,
		toucher
	);

	if (zero_damageforcescale)
		toucher.damageforcescale = 0;

	delete(this);
}

void W_Blaster_Think(entity this)
{
	set_movetype(this, MOVETYPE_FLY);
	setthink(this, SUB_Remove);
	this.nextthink = time + WEP_CVAR_PRI(WEP_BLASTER, lifetime);
	CSQCProjectile(this, true, PROJECTILE_BLASTER, true);
}

void W_Blaster_Attack(entity actor, .entity weaponentity)
{
	float atk_shotangle = WEP_CVAR_PRI(WEP_BLASTER, shotangle) * DEG2RAD;
	float atk_damage = WEP_CVAR_PRI(WEP_BLASTER, damage);
	vector s_forward = v_forward * cos(atk_shotangle) + v_up * sin(atk_shotangle);
	int atk_deathtype = WEP_BLASTER.m_id;

	W_SetupShot_Dir(actor, weaponentity, s_forward, false, 3, SND_BLASTER_FIRE, CH_WEAPON_B, atk_damage, atk_deathtype);
	W_MuzzleFlash(WEP_BLASTER, actor, weaponentity, w_shotorg, w_shotdir);

	entity missile = new(blasterbolt);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = atk_damage;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	float atk_speed = WEP_CVAR_PRI(WEP_BLASTER, speed);
	float atk_spread = WEP_CVAR_PRI(WEP_BLASTER, spread);
	W_SetupProjVelocity_Explicit(missile, w_shotdir, v_up, atk_speed, 0, 0, atk_spread, false);

	missile.angles = vectoangles(missile.velocity);

	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;

	settouch(missile, W_Blaster_Touch);
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.missile_flags = MIF_SPLASH;
	missile.projectiledeathtype = atk_deathtype;
	missile.weaponentity_fld = weaponentity;
	setthink(missile, W_Blaster_Think);
	missile.nextthink = time + WEP_CVAR_PRI(WEP_BLASTER, delay);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);

	if (time >= missile.nextthink)
	{
		getthink(missile)(missile);
	}
}

METHOD(Blaster, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	PHYS_INPUT_BUTTON_ATCK(actor) =
		bot_aim(actor, weaponentity, WEP_CVAR_PRI(WEP_BLASTER, speed), 0, WEP_CVAR_PRI(WEP_BLASTER, lifetime), false, true);
}

METHOD(Blaster, wr_think, void(Blaster thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_BLASTER, refire)))
		{
			W_Blaster_Attack(actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_BLASTER, animtime), w_ready);
		}
	}
	else if(fire & 2)
	{
		if(actor.(weaponentity).m_switchweapon == WEP_BLASTER) // don't do this if already switching
			W_LastWeapon(actor, weaponentity);
	}
}

METHOD(Blaster, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // infinite ammo
}

METHOD(Blaster, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // blaster has infinite ammo
}

METHOD(Blaster, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_BLASTER_SUICIDE;
}

METHOD(Blaster, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_BLASTER_MURDER;
}

METHOD(OffhandBlaster, offhand_think, void(OffhandBlaster this, entity actor, bool key_pressed))
{
	if (!key_pressed || (time < actor.jump_interval))
	{
		return;
	}
	actor.jump_interval = time + WEP_CVAR_PRI(WEP_BLASTER, refire) * W_WeaponRateFactor(actor);
	.entity weaponentity = weaponentities[1];
	makevectors(actor.v_angle);
	W_Blaster_Attack(actor, weaponentity);
}

#endif
#ifdef CSQC

METHOD(Blaster, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_BLASTER_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent) { sound(actor, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM); }
}

#endif
#ifdef MENUQC

METHOD(Blaster, describe, string(Blaster this))
{
	TC(Blaster, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s is one of the two main default weapons, firing a relatively weak but high speed laser, dealing some splash damage but importantly a lot of knockback."), COLORED_NAME(this));
	PAR(_("It has no secondary fire, instead switching to the previously selected weapon."));
	PAR(_("It doesn't require ammo, meaning it is a great choice if you are running low on ammo and need to preserve some."));
	PAR(_("The %s is always available so ends up being used a lot when players spawn in, but it's difficult to master when used over a medium to long range. "
	      "Unlike other weapons, the %s can hit other projectiles directly."), COLORED_NAME(this), COLORED_NAME(this));
	PAR(_("One of the most common uses of the %s is \"laser jumping,\" where you can gain height by aiming down, jumping, then firing to boost yourself up. "
	      "Because it does a lot of knockback, another common usage is alternating between a high damage weapon and the %s to throw the enemy's aim off."), COLORED_NAME(this), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne(this.netname, "primary"));
	return PAGE_TEXT;
}

#endif
