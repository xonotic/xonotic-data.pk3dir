#include "classic.qh"

#ifdef SVQC

void W_Classic_Rocket_Explode(entity this, entity directhitentity)
{
        if(directhitentity.takedamage == DAMAGE_AIM)
                if(IS_PLAYER(directhitentity))
                        if(DIFF_TEAM(this.realowner, directhitentity))
                                if(!IS_DEAD(directhitentity))
                                        if(IsFlying(directhitentity))
                                                Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

        this.event_damage = func_null;
        this.takedamage = DAMAGE_NO;

        RadiusDamage(
                this,
                this.realowner,
                WEP_CVAR_PRI(classic, damage),
                WEP_CVAR_PRI(classic, edgedamage),
                WEP_CVAR_PRI(classic, radius),
                NULL,
                NULL,
                WEP_CVAR_PRI(classic, force),
                this.projectiledeathtype,
                this.weaponentity_fld,
                directhitentity
        );

        delete(this);
}


void W_Classic_Rocket_Explode_use(entity this, entity actor, entity trigger)
{
	W_Classic_Rocket_Explode(this, NULL);
}

void W_Classic_Rocket_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	this.use(this, NULL, toucher);
}

void W_Classic_Rocket_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
        if(GetResource(this, RES_HEALTH) <= 0)
                return;

        if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
                return; // g_projectiles_damage says to halt

        TakeResource(this, RES_HEALTH, damage);
        this.angles = vectoangles(this.velocity);

        if(GetResource(this, RES_HEALTH) <= 0)
                W_PrepareExplosionByDamage(this, attacker, adaptor_think2use_hittype_splash);
                //W_PrepareExplosionByDamage(this, attacker, W_Classic_Rocket_Explode_use);
}

void W_Classic_Rocket_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
        W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(classic, ammo), weaponentity);

        W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 5, SND_ROCKET_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(classic, damage), thiswep.m_id);
        W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

        entity missile = WarpZone_RefSys_SpawnSameRefSys(actor);
        missile.weaponentity_fld = weaponentity;
        missile.owner = missile.realowner = actor;
        missile.bot_dodge = true;
        missile.bot_dodgerating = WEP_CVAR_PRI(classic, damage);

        missile.takedamage = DAMAGE_YES;
        missile.damageforcescale = WEP_CVAR_PRI(classic, damageforcescale);
        SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR_PRI(classic, health));
        missile.event_damage = W_Classic_Rocket_Damage;
        missile.damagedbycontents = true;
        IL_PUSH(g_damagedbycontents, missile);
	
        set_movetype(missile, MOVETYPE_FLY);
        PROJECTILE_MAKETRIGGER(missile);
        missile.projectiledeathtype = thiswep.m_id;
        setsize(missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

        setorigin(missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
        W_SetupProjVelocity_Basic(missile, WEP_CVAR_PRI(classic, speed), 0);
        missile.angles = vectoangles(missile.velocity);

        settouch(missile, W_Classic_Rocket_Touch);
        //setthink(missile, W_Classic_Rocket_Explode_use);
	setthink(missile, adaptor_think2use_hittype_splash);
	missile.use = W_Classic_Rocket_Explode_use;
        missile.nextthink = time + WEP_CVAR_PRI(classic, lifetime);
        missile.cnt = time + WEP_CVAR_PRI(classic, lifetime);
        missile.flags = FL_PROJECTILE;
        IL_PUSH(g_projectiles, missile);
        IL_PUSH(g_bot_dodge, missile);
        missile.missile_flags = MIF_SPLASH;

        CSQCProjectile(missile, true, PROJECTILE_ROCKET, false); // because of fly sound

        // common properties
        MUTATOR_CALLHOOK(EditProjectile, actor, missile);

        if (time >= missile.nextthink)
        {
                getthink(missile)(missile);
        }
}

void W_Classic_Grenade_Explode(entity this, entity directhitentity)
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

	RadiusDamage(
		this,
		this.realowner,
		WEP_CVAR_SEC(classic, damage),
		WEP_CVAR_SEC(classic, edgedamage),
		WEP_CVAR_SEC(classic, radius),
		NULL,
		NULL,
		WEP_CVAR_SEC(classic, force),
		this.projectiledeathtype,
		this.weaponentity_fld,
		directhitentity
	);

	delete(this);
}

void W_Classic_Grenade_Explode_use(entity this, entity actor, entity trigger)
{
	W_Classic_Grenade_Explode(this, trigger);
}

void W_Classic_Grenade_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, adaptor_think2use);
}

void W_Classic_Grenade_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	// always explode when hitting a player, or if normal classic projectile
	if(toucher.takedamage == DAMAGE_AIM)
	{
		this.use(this, NULL, toucher);
	}
	else // bounce
	{
		spamsound(this, CH_SHOTS, SND_GRENADE_BOUNCE_RANDOM(), VOL_BASE, ATTN_NORM);
		Send_Effect(EFFECT_HAGAR_BOUNCE, this.origin, this.velocity, 1);
		this.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Classic_Grenade_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity gren;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(classic, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-3 -3 -3', '3 3 3', false, 4, SND_GRENADE_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(classic, damage), thiswep.m_id | HITTYPE_SECONDARY);
	w_shotdir = v_forward; // no TrueAim for grenades please

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	gren = new(grenade);
	gren.owner = gren.realowner = actor;
	gren.bot_dodge = true;
	gren.bot_dodgerating = WEP_CVAR_SEC(classic, damage);
	set_movetype(gren, MOVETYPE_BOUNCE);
	gren.bouncefactor = WEP_CVAR_SEC(classic, bouncefactor);
	gren.bouncestop = WEP_CVAR_SEC(classic, bouncestop);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
	gren.weaponentity_fld = weaponentity;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.nextthink = time + WEP_CVAR_SEC(classic, lifetime);
	setthink(gren, adaptor_think2use_hittype_splash);
	gren.use = W_Classic_Grenade_Explode_use;
	settouch(gren, W_Classic_Grenade_Touch);

	gren.takedamage = DAMAGE_YES;
	SetResourceExplicit(gren, RES_HEALTH, WEP_CVAR_SEC(classic, health));
	gren.damageforcescale = WEP_CVAR_SEC(classic, damageforcescale);
	gren.event_damage = W_Classic_Grenade_Damage;
	gren.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, gren);
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_UP_SEC(gren, classic);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	CSQCProjectile(gren, true, PROJECTILE_CLASSIC_GRENADE_BOUNCING, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

.float bot_secondary_grenademooth;

METHOD(Classic, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	PHYS_INPUT_BUTTON_ATCK(actor) = false;
	PHYS_INPUT_BUTTON_ATCK2(actor) = false;
	if(actor.bot_secondary_grenademooth == 0) // WEAPONTODO: merge this into using WEP_CVAR_BOTH
	{
		if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(classic, speed), 0, WEP_CVAR_PRI(classic, lifetime), false, true))
		{
			PHYS_INPUT_BUTTON_ATCK(actor) = true;
			if(random() < 0.5) actor.bot_secondary_grenademooth = 1;
		}
	}
	else
	{
		if(bot_aim(actor, weaponentity, WEP_CVAR_SEC(classic, speed), WEP_CVAR_SEC(classic, speed_up), WEP_CVAR_SEC(classic, lifetime), true, true))
		{
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
			if(random() < 0.5) actor.bot_secondary_grenademooth = 0;
		}
		else
		{
			if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(classic, speed), 0, WEP_CVAR_PRI(classic, lifetime), false, true))
			{
				PHYS_INPUT_BUTTON_ATCK(actor) = true;
				if(random() < 0.5) actor.bot_secondary_grenademooth = 1;
			}
		}
	}
}

METHOD(Classic, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(autocvar_g_balance_classic_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(classic, ammo), WEP_CVAR_SEC(classic, ammo)))
	{
		// forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	}
	else if(fire & 1)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(classic, refire)))
		{
			W_Classic_Rocket_Attack(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(classic, animtime), w_ready);
		}
	}
	else if(fire & 2)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(classic, refire)))
		{
			W_Classic_Grenade_Attack(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(classic, animtime), w_ready);
		}
	}
}

METHOD(Classic, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(classic, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(classic, ammo);
	return ammo_amount;
}

METHOD(Classic, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(classic, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(classic, ammo);
	return ammo_amount;
}

METHOD(Classic, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(classic, ammo), WEP_CVAR_SEC(classic, ammo)), SND_RELOAD); // WEAPONTODO? imported from mortar.qc which had "WEAPONTODO"
}
/*
METHOD(Classic, wr_suicidemessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_CLASSIC_SEC_SUICIDE;
	else
		return WEAPON_CLASSIC_PRI_SUICIDE;
}

METHOD(Classic, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
	{
		if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
			return WEAPON_CLASSIC_SEC_MURDER_SPLASH;
		else
			return WEAPON_CLASSIC_SEC_MURDER_DIRECT;
	}
	else
	{
		if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
			return WEAPON_CLASSIC_PRI_MURDER_SPLASH;
		else
			return WEAPON_CLASSIC_PRI_MURDER_DIRECT;
	}

}
*/
#endif
#ifdef CSQC

METHOD(Classic, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2;
	org2 = w_org + w_backoff * 12;
	pointparticles(EFFECT_GRENADE_EXPLODE, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_GRENADE_IMPACT, VOL_BASE, ATTN_NORM);
}

#endif
