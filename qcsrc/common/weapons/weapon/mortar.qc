#include "mortar.qh"
#ifndef IMPLEMENTATION
CLASS(Mortar, Weapon)
/* ammotype  */ ATTRIB(Mortar, ammo_field, .int, ammo_rockets);
/* impulse   */ ATTRIB(Mortar, impulse, int, 4);
/* flags     */ ATTRIB(Mortar, spawnflags, int, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Mortar, bot_pickupbasevalue, float, 7000);
/* color     */ ATTRIB(Mortar, wpcolor, vector, '1 0 0');
/* modelname */ ATTRIB(Mortar, mdl, string, "gl");
#ifdef GAMEQC
/* model     */ ATTRIB(Mortar, m_model, Model, MDL_MORTAR_ITEM);
#endif
/* crosshair */ ATTRIB(Mortar, w_crosshair, string, "gfx/crosshairgrenadelauncher");
/* crosshair */ ATTRIB(Mortar, w_crosshair_size, float, 0.7);
/* wepimg    */ ATTRIB(Mortar, model2, string, "weapongrenadelauncher");
/* refname   */ ATTRIB(Mortar, netname, string, "mortar");
/* wepname   */ ATTRIB(Mortar, m_name, string, _("Mortar"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, BOTH) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, bouncefactor, float, NONE) \
		P(class, prefix, bouncestop, float, NONE) \
		P(class, prefix, damageforcescale, float, BOTH) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, edgedamage, float, BOTH) \
		P(class, prefix, force, float, BOTH) \
		P(class, prefix, health, float, BOTH) \
		P(class, prefix, lifetime, float, BOTH) \
		P(class, prefix, lifetime_bounce, float, SEC) \
		P(class, prefix, lifetime_stick, float, BOTH) \
		P(class, prefix, radius, float, BOTH) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, reload_ammo, float, NONE) \
		P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, remote_detonateprimary, float, SEC) \
		P(class, prefix, remote_minbouncecnt, float, PRI) \
		P(class, prefix, speed, float, BOTH) \
		P(class, prefix, speed_up, float, BOTH) \
		P(class, prefix, speed_z, float, BOTH) \
		P(class, prefix, spread, float, BOTH) \
		P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, type, float, BOTH) \
		P(class, prefix, weaponreplace, string, NONE) \
		P(class, prefix, weaponstartoverride, float, NONE) \
		P(class, prefix, weaponstart, float, NONE) \
		P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, Mortar, mortar)
#undef X
ENDCLASS(Mortar)
REGISTER_WEAPON(MORTAR, mortar, NEW(Mortar));


#ifdef SVQC
.float gl_detonate_later;
.float gl_bouncecnt;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC

spawnfunc(weapon_mortar) { weapon_defaultspawnfunc(this, WEP_MORTAR); }
spawnfunc(weapon_grenadelauncher) { spawnfunc_weapon_mortar(this); }

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
		this.velocity = this.oldvelocity;

	RadiusDamage(this, this.realowner, WEP_CVAR_PRI(mortar, damage), WEP_CVAR_PRI(mortar, edgedamage), WEP_CVAR_PRI(mortar, radius), NULL, NULL, WEP_CVAR_PRI(mortar, force), this.projectiledeathtype, directhitentity);

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
		this.velocity = this.oldvelocity;

	RadiusDamage(this, this.realowner, WEP_CVAR_SEC(mortar, damage), WEP_CVAR_SEC(mortar, edgedamage), WEP_CVAR_SEC(mortar, radius), NULL, NULL, WEP_CVAR_SEC(mortar, force), this.projectiledeathtype, directhitentity);

	delete(this);
}

void W_Mortar_Grenade_Explode2_use(entity this, entity actor, entity trigger)
{
	W_Mortar_Grenade_Explode2(this, trigger);
}

void W_Mortar_Grenade_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if(this.health <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	this.health = this.health - damage;

	if(this.health <= 0)
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
	if(this.gl_detonate_later && this.gl_bouncecnt >= WEP_CVAR_PRI(mortar, remote_minbouncecnt))
		W_Mortar_Grenade_Explode(this, NULL);
}

void W_Mortar_Grenade_Touch1(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(toucher.takedamage == DAMAGE_AIM || WEP_CVAR_PRI(mortar, type) == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		this.use(this, NULL, toucher);
	}
	else if(WEP_CVAR_PRI(mortar, type) == 1) // bounce
	{
		spamsound(this, CH_SHOTS, SND(GRENADE_BOUNCE_RANDOM()), VOL_BASE, ATTN_NORM);
		Send_Effect(EFFECT_HAGAR_BOUNCE, this.origin, this.velocity, 1);
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		this.gl_bouncecnt += 1;
	}
	else if(WEP_CVAR_PRI(mortar, type) == 2 && (!toucher || (toucher.takedamage != DAMAGE_AIM && toucher.move_movetype == MOVETYPE_NONE))) // stick
	{
		spamsound(this, CH_SHOTS, SND(GRENADE_STICK), VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		this.oldvelocity = this.velocity;
		this.velocity = '0 0 0';
		set_movetype(this, MOVETYPE_NONE); // also disables gravity
		this.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(this);

		// do not respond to any more touches
		this.solid = SOLID_NOT;

		this.nextthink = min(this.nextthink, time + WEP_CVAR_PRI(mortar, lifetime_stick));
	}
}

void W_Mortar_Grenade_Touch2(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(toucher.takedamage == DAMAGE_AIM || WEP_CVAR_SEC(mortar, type) == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		this.use(this, NULL, toucher);
	}
	else if(WEP_CVAR_SEC(mortar, type) == 1) // bounce
	{
		spamsound(this, CH_SHOTS, SND(GRENADE_BOUNCE_RANDOM()), VOL_BASE, ATTN_NORM);
		Send_Effect(EFFECT_HAGAR_BOUNCE, this.origin, this.velocity, 1);
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		this.gl_bouncecnt += 1;

		if(WEP_CVAR_SEC(mortar, lifetime_bounce) && this.gl_bouncecnt == 1)
			this.nextthink = time + WEP_CVAR_SEC(mortar, lifetime_bounce);

	}
	else if(WEP_CVAR_SEC(mortar, type) == 2 && (!toucher || (toucher.takedamage != DAMAGE_AIM && toucher.move_movetype == MOVETYPE_NONE))) // stick
	{
		spamsound(this, CH_SHOTS, SND(GRENADE_STICK), VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		this.oldvelocity = this.velocity;
		this.velocity = '0 0 0';
		set_movetype(this, MOVETYPE_NONE); // also disables gravity
		this.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(this);

		// do not respond to any more touches
		this.solid = SOLID_NOT;

		this.nextthink = min(this.nextthink, time + WEP_CVAR_SEC(mortar, lifetime_stick));
	}
}

void W_Mortar_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(mortar, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 4, SND_GRENADE_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(mortar, damage));
	w_shotdir = v_forward; // no TrueAim for grenades please

	Send_Effect(EFFECT_GRENADE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	entity gren = new(grenade);
	gren.owner = gren.realowner = actor;
	gren.bot_dodge = true;
	gren.bot_dodgerating = WEP_CVAR_PRI(mortar, damage);
	set_movetype(gren, MOVETYPE_BOUNCE);
	gren.bouncefactor = WEP_CVAR(mortar, bouncefactor);
	gren.bouncestop = WEP_CVAR(mortar, bouncestop);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_MORTAR.m_id;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.cnt = time + WEP_CVAR_PRI(mortar, lifetime);
	gren.nextthink = time;
	setthink(gren, W_Mortar_Grenade_Think1);
	gren.use = W_Mortar_Grenade_Explode_use;
	settouch(gren, W_Mortar_Grenade_Touch1);

	gren.takedamage = DAMAGE_YES;
	gren.health = WEP_CVAR_PRI(mortar, health);
	gren.damageforcescale = WEP_CVAR_PRI(mortar, damageforcescale);
	gren.event_damage = W_Mortar_Grenade_Damage;
	gren.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, gren);
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_UP_PRI(gren, mortar);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	if(WEP_CVAR_PRI(mortar, type) == 0 || WEP_CVAR_PRI(mortar, type) == 2)
		CSQCProjectile(gren, true, PROJECTILE_GRENADE, true);
	else
		CSQCProjectile(gren, true, PROJECTILE_GRENADE_BOUNCING, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

void W_Mortar_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity gren;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(mortar, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 4, SND_GRENADE_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(mortar, damage));
	w_shotdir = v_forward; // no TrueAim for grenades please

	Send_Effect(EFFECT_GRENADE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	gren = new(grenade);
	gren.owner = gren.realowner = actor;
	gren.bot_dodge = true;
	gren.bot_dodgerating = WEP_CVAR_SEC(mortar, damage);
	set_movetype(gren, MOVETYPE_BOUNCE);
	gren.bouncefactor = WEP_CVAR(mortar, bouncefactor);
	gren.bouncestop = WEP_CVAR(mortar, bouncestop);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_MORTAR.m_id | HITTYPE_SECONDARY;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.nextthink = time + WEP_CVAR_SEC(mortar, lifetime);
	setthink(gren, adaptor_think2use_hittype_splash);
	gren.use = W_Mortar_Grenade_Explode2_use;
	settouch(gren, W_Mortar_Grenade_Touch2);

	gren.takedamage = DAMAGE_YES;
	gren.health = WEP_CVAR_SEC(mortar, health);
	gren.damageforcescale = WEP_CVAR_SEC(mortar, damageforcescale);
	gren.event_damage = W_Mortar_Grenade_Damage;
	gren.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, gren);
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_UP_SEC(gren, mortar);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	if(WEP_CVAR_SEC(mortar, type) == 0 || WEP_CVAR_SEC(mortar, type) == 2)
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
        if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(mortar, speed), WEP_CVAR_PRI(mortar, speed_up), WEP_CVAR_PRI(mortar, lifetime), true))
        {
            PHYS_INPUT_BUTTON_ATCK(actor) = true;
            if(random() < 0.01) actor.bot_secondary_grenademooth = 1;
        }
    }
    else
    {
        if(bot_aim(actor, weaponentity, WEP_CVAR_SEC(mortar, speed), WEP_CVAR_SEC(mortar, speed_up), WEP_CVAR_SEC(mortar, lifetime), true))
        {
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
            if(random() < 0.02) actor.bot_secondary_grenademooth = 0;
        }
    }
}
/*case WR_CALCINFO:
{
    wepinfo_pri_refire = max3(sys_frametime, WEP_CVAR_PRI(mortar, refire), WEP_CVAR_PRI(mortar, animtime));
    wepinfo_pri_dps = (WEP_CVAR_PRI(mortar, damage) * (1 / wepinfo_pri_refire));
    wepinfo_pri_speed = (1 / max(1, (10000 / max(1, WEP_CVAR_PRI(mortar, speed)))));

    // for the range calculation, closer to 1 is better
    wepinfo_pri_range_max = 2000 * wepinfo_pri_speed;
    wepinfo_pri_range = wepinfo_pri_speed * WEP_CVAR_PRI(mortar,

    wepinfo_sec_refire = max3(sys_frametime, WEP_CVAR_SEC(mortar, refire), WEP_CVAR_SEC(mortar, animtime));
    wepinfo_sec_dps = (WEP_CVAR_SEC(mortar, damage) * (1 / wepinfo_sec_refire));

    wepinfo_sec_dps = (WEP_CVAR_SEC(mortar, damage) * (1 / max3(sys_frametime, WEP_CVAR_SEC(mortar, refire), WEP_CVAR_SEC(mortar, animtime))));
    wepinfo_ter_dps = 0;
    */
METHOD(Mortar, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(autocvar_g_balance_mortar_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(mortar, ammo), WEP_CVAR_SEC(mortar, ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    } else if(fire & 1)
    {
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(mortar, refire)))
        {
            W_Mortar_Attack(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(mortar, animtime), w_ready);
        }
    }
    else if(fire & 2)
    {
        if(WEP_CVAR_SEC(mortar, remote_detonateprimary))
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
                sound(actor, CH_WEAPON_B, SND_ROCKET_DET, VOL_BASE, ATTN_NORM);
        }
        else if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(mortar, refire)))
        {
            W_Mortar_Attack2(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(mortar, animtime), w_ready);
        }
    }
}
METHOD(Mortar, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_PRI(mortar, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[WEP_MORTAR.m_id]) >= WEP_CVAR_PRI(mortar, ammo);
    return ammo_amount;
}
METHOD(Mortar, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_SEC(mortar, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[WEP_MORTAR.m_id]) >= WEP_CVAR_SEC(mortar, ammo);
    return ammo_amount;
}
METHOD(Mortar, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(mortar, ammo), WEP_CVAR_SEC(mortar, ammo)), SND_RELOAD); // WEAPONTODO
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
    vector org2;
    org2 = w_org + w_backoff * 12;
    pointparticles(EFFECT_GRENADE_EXPLODE, org2, '0 0 0', 1);
    if(!w_issilent)
        sound(actor, CH_SHOTS, SND_GRENADE_IMPACT, VOL_BASE, ATTN_NORM);
}

#endif
#endif
