#include "mortar.qh"

#ifdef SVQC

void W_Mortar_Grenade_Explode(entity this, entity directhitentity)
{
	if(directhitentity.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(directhitentity))
			if(DIFF_TEAM(this.realowner, directhitentity))
				if(!IS_DEAD(directhitentity))
					if(IsFlying(directhitentity))
						Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	if(this.move_movetype == MOVETYPE_NONE)
		this.velocity = this.movedir; // .velocity must be != '0 0 0' for particle fx and decal to work

	RadiusDamage(this, this.realowner, WEP_CVAR_PRI(WEP_MORTAR, damage), WEP_CVAR_PRI(WEP_MORTAR, edgedamage), WEP_CVAR_PRI(WEP_MORTAR, radius), NULL, NULL, WEP_CVAR_PRI(WEP_MORTAR, force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	delete(this);
}

void W_Mortar_Grenade_Explode_use(entity this, entity actor, entity trigger)
{
	W_Mortar_Grenade_Explode(this, trigger);
}

void W_Mortar_Grenade_Explode2(entity this, entity directhitentity)
{
	if(directhitentity.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(directhitentity))
			if(DIFF_TEAM(this.realowner, directhitentity))
				if(!IS_DEAD(directhitentity))
					if(IsFlying(directhitentity))
						Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	if(this.move_movetype == MOVETYPE_NONE)
		this.velocity = this.movedir; // .velocity must be != '0 0 0' for particle fx and decal to work

	RadiusDamage(this, this.realowner, WEP_CVAR_SEC(WEP_MORTAR, damage), WEP_CVAR_SEC(WEP_MORTAR, edgedamage), WEP_CVAR_SEC(WEP_MORTAR, radius), NULL, NULL, WEP_CVAR_SEC(WEP_MORTAR, force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	delete(this);
}

void W_Mortar_Grenade_Explode2_use(entity this, entity actor, entity trigger)
{
	W_Mortar_Grenade_Explode2(this, trigger);
}

void W_Mortar_Grenade_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, adaptor_think2use);
}

void W_Mortar_Grenade_Think1(entity this)
{
	this.nextthink = time;
	if(time > this.cnt)
	{
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Mortar_Grenade_Explode(this, NULL);
		return;
	}
	if(this.gl_detonate_later && this.gl_bouncecnt >= WEP_CVAR_PRI(WEP_MORTAR, remote_minbouncecnt))
		W_Mortar_Grenade_Explode(this, NULL);
}

void W_Mortar_Grenade_Touch1(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(toucher.takedamage == DAMAGE_AIM || WEP_CVAR_PRI(WEP_MORTAR, type) == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		this.use(this, NULL, toucher);
	}
	else if(WEP_CVAR_PRI(WEP_MORTAR, type) == 1) // bounce
	{
		spamsound(this, CH_SHOTS, SND_GRENADE_BOUNCE_RANDOM(), VOL_BASE, ATTN_NORM);
		Send_Effect(EFFECT_HAGAR_BOUNCE, this.origin, this.velocity, 1);
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		this.gl_bouncecnt += 1;
	}
	else if(WEP_CVAR_PRI(WEP_MORTAR, type) == 2 && (!toucher || (toucher.takedamage != DAMAGE_AIM && toucher.move_movetype == MOVETYPE_NONE))) // stick
	{
		spamsound(this, CH_SHOTS, SND_MORTAR_STICK, VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		this.movedir = this.velocity; // save to this temporary field, will be restored on explosion
		this.velocity = '0 0 0';
		set_movetype(this, MOVETYPE_NONE); // also disables gravity
		this.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(this);

		// do not respond to any more touches
		this.solid = SOLID_NOT;

		this.nextthink = min(this.nextthink, time + WEP_CVAR_PRI(WEP_MORTAR, lifetime_stick));
	}
}

void W_Mortar_Grenade_Touch2(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(toucher.takedamage == DAMAGE_AIM || WEP_CVAR_SEC(WEP_MORTAR, type) == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		this.use(this, NULL, toucher);
	}
	else if(WEP_CVAR_SEC(WEP_MORTAR, type) == 1) // bounce
	{
		spamsound(this, CH_SHOTS, SND_GRENADE_BOUNCE_RANDOM(), VOL_BASE, ATTN_NORM);
		Send_Effect(EFFECT_HAGAR_BOUNCE, this.origin, this.velocity, 1);
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		this.gl_bouncecnt += 1;

		if(WEP_CVAR_SEC(WEP_MORTAR, lifetime_bounce) && this.gl_bouncecnt == 1)
			this.nextthink = time + WEP_CVAR_SEC(WEP_MORTAR, lifetime_bounce);

	}
	else if(WEP_CVAR_SEC(WEP_MORTAR, type) == 2 && (!toucher || (toucher.takedamage != DAMAGE_AIM && toucher.move_movetype == MOVETYPE_NONE))) // stick
	{
		spamsound(this, CH_SHOTS, SND_MORTAR_STICK, VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		this.movedir = this.velocity; // save to this temporary field, will be restored on explosion
		this.velocity = '0 0 0';
		set_movetype(this, MOVETYPE_NONE); // also disables gravity
		this.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(this);

		// do not respond to any more touches
		this.solid = SOLID_NOT;

		this.nextthink = min(this.nextthink, time + WEP_CVAR_SEC(WEP_MORTAR, lifetime_stick));
	}
}

void W_Mortar_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(WEP_MORTAR, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 4, SND_MORTAR_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(WEP_MORTAR, damage), thiswep.m_id);
	w_shotdir = v_forward; // no TrueAim for grenades please

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	entity gren = new(grenade);
	gren.owner = gren.realowner = actor;
	gren.bot_dodge = true;
	gren.bot_dodgerating = WEP_CVAR_PRI(WEP_MORTAR, damage);
	set_movetype(gren, MOVETYPE_BOUNCE);
	gren.bouncefactor = WEP_CVAR(WEP_MORTAR, bouncefactor);
	gren.bouncestop = WEP_CVAR(WEP_MORTAR, bouncestop);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = thiswep.m_id;
	gren.weaponentity_fld = weaponentity;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.cnt = time + WEP_CVAR_PRI(WEP_MORTAR, lifetime);
	gren.nextthink = time;
	setthink(gren, W_Mortar_Grenade_Think1);
	gren.use = W_Mortar_Grenade_Explode_use;
	settouch(gren, W_Mortar_Grenade_Touch1);

	gren.takedamage = DAMAGE_YES;
	SetResourceExplicit(gren, RES_HEALTH, WEP_CVAR_PRI(WEP_MORTAR, health));
	gren.damageforcescale = WEP_CVAR_PRI(WEP_MORTAR, damageforcescale);
	gren.event_damage = W_Mortar_Grenade_Damage;
	gren.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, gren);
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_UP_PRI(gren, WEP_MORTAR);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	if(WEP_CVAR_PRI(WEP_MORTAR, type) == 0 || WEP_CVAR_PRI(WEP_MORTAR, type) == 2)
		CSQCProjectile(gren, true, PROJECTILE_GRENADE, true);
	else
		CSQCProjectile(gren, true, PROJECTILE_GRENADE_BOUNCING, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

void W_Mortar_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity gren;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(WEP_MORTAR, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 4, SND_MORTAR_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(WEP_MORTAR, damage), thiswep.m_id | HITTYPE_SECONDARY);
	w_shotdir = v_forward; // no TrueAim for grenades please

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	gren = new(grenade);
	gren.owner = gren.realowner = actor;
	gren.bot_dodge = true;
	gren.bot_dodgerating = WEP_CVAR_SEC(WEP_MORTAR, damage);
	set_movetype(gren, MOVETYPE_BOUNCE);
	gren.bouncefactor = WEP_CVAR(WEP_MORTAR, bouncefactor);
	gren.bouncestop = WEP_CVAR(WEP_MORTAR, bouncestop);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
	gren.weaponentity_fld = weaponentity;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.nextthink = time + WEP_CVAR_SEC(WEP_MORTAR, lifetime);
	setthink(gren, adaptor_think2use_hittype_splash);
	gren.use = W_Mortar_Grenade_Explode2_use;
	settouch(gren, W_Mortar_Grenade_Touch2);

	gren.takedamage = DAMAGE_YES;
	SetResourceExplicit(gren, RES_HEALTH, WEP_CVAR_SEC(WEP_MORTAR, health));
	gren.damageforcescale = WEP_CVAR_SEC(WEP_MORTAR, damageforcescale);
	gren.event_damage = W_Mortar_Grenade_Damage;
	gren.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, gren);
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_UP_SEC(gren, WEP_MORTAR);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	if(WEP_CVAR_SEC(WEP_MORTAR, type) == 0 || WEP_CVAR_SEC(WEP_MORTAR, type) == 2)
		CSQCProjectile(gren, true, PROJECTILE_GRENADE, true);
	else
		CSQCProjectile(gren, true, PROJECTILE_GRENADE_BOUNCING, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

.float bot_secondary_grenademooth;

METHOD(Mortar, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	PHYS_INPUT_BUTTON_ATCK(actor) = false;
	PHYS_INPUT_BUTTON_ATCK2(actor) = false;
	if(actor.bot_secondary_grenademooth == 0) // WEAPONTODO: merge this into using WEP_CVAR_BOTH
	{
		if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(WEP_MORTAR, speed), WEP_CVAR_PRI(WEP_MORTAR, speed_up), WEP_CVAR_PRI(WEP_MORTAR, lifetime), true, true))
		{
			PHYS_INPUT_BUTTON_ATCK(actor) = true;
			if(random() < 0.01) actor.bot_secondary_grenademooth = 1;
		}
	}
	else
	{
		if(bot_aim(actor, weaponentity, WEP_CVAR_SEC(WEP_MORTAR, speed), WEP_CVAR_SEC(WEP_MORTAR, speed_up), WEP_CVAR_SEC(WEP_MORTAR, lifetime), true, true))
		{
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
			if(random() < 0.02) actor.bot_secondary_grenademooth = 0;
		}
	}
}

/*case WR_CALCINFO:
{
	wepinfo_pri_refire = max3(sys_frametime, WEP_CVAR_PRI(WEP_MORTAR, refire), WEP_CVAR_PRI(WEP_MORTAR, animtime));
	wepinfo_pri_dps = (WEP_CVAR_PRI(WEP_MORTAR, damage) * (1 / wepinfo_pri_refire));
	wepinfo_pri_speed = (1 / max(1, (10000 / max(1, WEP_CVAR_PRI(WEP_MORTAR, speed)))));

	// for the range calculation, closer to 1 is better
	wepinfo_pri_range_max = 2000 * wepinfo_pri_speed;
	wepinfo_pri_range = wepinfo_pri_speed * WEP_CVAR_PRI(WEP_MORTAR,

	wepinfo_sec_refire = max3(sys_frametime, WEP_CVAR_SEC(WEP_MORTAR, refire), WEP_CVAR_SEC(WEP_MORTAR, animtime));
	wepinfo_sec_dps = (WEP_CVAR_SEC(WEP_MORTAR, damage) * (1 / wepinfo_sec_refire));

	wepinfo_sec_dps = (WEP_CVAR_SEC(WEP_MORTAR, damage) * (1 / max3(sys_frametime, WEP_CVAR_SEC(WEP_MORTAR, refire), WEP_CVAR_SEC(WEP_MORTAR, animtime))));
	wepinfo_ter_dps = 0;
	*/

METHOD(Mortar, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(autocvar_g_balance_mortar_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(WEP_MORTAR, ammo), WEP_CVAR_SEC(WEP_MORTAR, ammo))) { // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	} else if(fire & 1)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_MORTAR, refire)))
		{
			W_Mortar_Attack(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_MORTAR, animtime), w_ready);
		}
	}
	else if(fire & 2)
	{
		if(WEP_CVAR_SEC(WEP_MORTAR, remote_detonateprimary))
		{
			bool nadefound = false;
			IL_EACH(g_projectiles, it.realowner == actor && it.classname == "grenade",
			{
				if(!it.gl_detonate_later)
				{
					it.gl_detonate_later = true;
					nadefound = true;
				}
			});
			if(nadefound)
				sound(actor, CH_WEAPON_B, SND_MORTAR_DET, VOL_BASE, ATTN_NORM);
		}
		else if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_MORTAR, refire)))
		{
			W_Mortar_Attack2(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_MORTAR, animtime), w_ready);
		}
	}
}

METHOD(Mortar, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_MORTAR, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_MORTAR, ammo);
	return ammo_amount;
}

METHOD(Mortar, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(WEP_MORTAR, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(WEP_MORTAR, ammo);
	return ammo_amount;
}

METHOD(Mortar, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(WEP_MORTAR, ammo), WEP_CVAR_SEC(WEP_MORTAR, ammo)), SND_RELOAD); // WEAPONTODO
}

METHOD(Mortar, wr_suicidemessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_MORTAR_SUICIDE_BOUNCE;
	else
		return WEAPON_MORTAR_SUICIDE_EXPLODE;
}

METHOD(Mortar, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_MORTAR_MURDER_BOUNCE;
	else
		return WEAPON_MORTAR_MURDER_EXPLODE;
}

#endif
#ifdef CSQC

METHOD(Mortar, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_GRENADE_EXPLODE, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_MORTAR_IMPACT, VOL_BASE, ATTN_NORM);
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>

METHOD(Mortar, describe, string(Mortar this))
{
	TC(Mortar, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s launches a grenade that explodes immediately on impact, dealing a medium amount of splash damage."), COLORED_NAME(this));
	PAR(_("The secondary fire shoots a similar grenade that explodes shortly after bouncing."));
	PAR(_("It consumes %s ammo for every grenade launched."), COLORED_NAME(ITEM_Rockets));
	PAR(_("The %s works best at close to medium ranges, but it's quite tricky to hit an enemy if they're airborne. "
	      "Since the secondary fire grenade bounces before exploding, it can be bounced against walls to damage enemies lurking around a corner."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS(this.netname, "primary", "secondary"));
	return PAGE_TEXT;
}

#endif
