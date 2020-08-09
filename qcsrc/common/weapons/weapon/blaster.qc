#include "blaster.qh"

#ifdef SVQC

void W_Blaster_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	this.event_damage = func_null;

	RadiusDamageForSource(
		this,
		(this.origin + (this.mins + this.maxs) * 0.5),
		this.velocity,
		this.realowner,
		this.blaster_damage,
		this.blaster_edgedamage,
		this.blaster_radius,
		NULL,
		NULL,
		false,
		this.blaster_force,
		this.blaster_force_zscale,
		this.projectiledeathtype,
		this.weaponentity_fld,
		toucher
	);

	delete(this);
}

void W_Blaster_Think(entity this)
{
	set_movetype(this, MOVETYPE_FLY);
	setthink(this, SUB_Remove);
	this.nextthink = time + this.blaster_lifetime;
	CSQCProjectile(this, true, PROJECTILE_BLASTER, true);
}

void W_Blaster_Attack(
	entity actor,
	.entity weaponentity,
	float atk_deathtype,
	float atk_shotangle,
	float atk_damage,
	float atk_edgedamage,
	float atk_radius,
	float atk_force,
	float atk_force_zscale,
	float atk_speed,
	float atk_spread,
	float atk_delay,
	float atk_lifetime)
{
	vector s_forward = v_forward * cos(atk_shotangle * DEG2RAD) + v_up * sin(atk_shotangle * DEG2RAD);

	W_SetupShot_Dir(actor, weaponentity, s_forward, false, 3, SND_LASERGUN_FIRE, CH_WEAPON_B, atk_damage, atk_deathtype);
	W_MuzzleFlash(WEP_BLASTER, actor, weaponentity, w_shotorg, w_shotdir);

	entity missile = new(blasterbolt);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = atk_damage;
	PROJECTILE_MAKETRIGGER(missile);

	missile.blaster_damage = atk_damage;
	missile.blaster_edgedamage = atk_edgedamage;
	missile.blaster_radius = atk_radius;
	missile.blaster_force = atk_force;
	missile.blaster_force_zscale = atk_force_zscale;
	missile.blaster_lifetime = atk_lifetime;

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Explicit(
		missile,
		w_shotdir,
		v_up,
		atk_speed,
		0,
		0,
		atk_spread,
		false
	);

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
	missile.nextthink = time + atk_delay;

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);

	if (time >= missile.nextthink)
	{
		getthink(missile)(missile);
	}
}

METHOD(Blaster, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(WEP_CVAR(blaster, secondary))
    {
        if((random() * (WEP_CVAR_PRI(blaster, damage) + WEP_CVAR_SEC(blaster, damage))) > WEP_CVAR_PRI(blaster, damage))
            { PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, WEP_CVAR_SEC(blaster, speed), 0, WEP_CVAR_SEC(blaster, lifetime), false); }
        else
            { PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(blaster, speed), 0, WEP_CVAR_PRI(blaster, lifetime), false); }
    }
    else
        { PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(blaster, speed), 0, WEP_CVAR_PRI(blaster, lifetime), false); }
}

METHOD(Blaster, wr_think, void(Blaster thiswep, entity actor, .entity weaponentity, int fire))
{
    if(fire & 1)
    {
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(blaster, refire)))
        {
            W_Blaster_Attack(
                actor,
                weaponentity,
                WEP_BLASTER.m_id,
                WEP_CVAR_PRI(blaster, shotangle),
                WEP_CVAR_PRI(blaster, damage),
                WEP_CVAR_PRI(blaster, edgedamage),
                WEP_CVAR_PRI(blaster, radius),
                WEP_CVAR_PRI(blaster, force),
                WEP_CVAR_PRI(blaster, force_zscale),
                WEP_CVAR_PRI(blaster, speed),
                WEP_CVAR_PRI(blaster, spread),
                WEP_CVAR_PRI(blaster, delay),
                WEP_CVAR_PRI(blaster, lifetime)
            );
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(blaster, animtime), w_ready);
        }
    }
    else if(fire & 2)
    {
        switch(WEP_CVAR(blaster, secondary))
        {
            case 0: // switch to last used weapon
            {
                if(actor.(weaponentity).m_switchweapon == WEP_BLASTER) // don't do this if already switching
                    W_LastWeapon(actor, weaponentity);
                break;
            }

            case 1: // normal projectile secondary
            {
                if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(blaster, refire)))
                {
                    W_Blaster_Attack(
                        actor,
                        weaponentity,
                        WEP_BLASTER.m_id | HITTYPE_SECONDARY,
                        WEP_CVAR_SEC(blaster, shotangle),
                        WEP_CVAR_SEC(blaster, damage),
                        WEP_CVAR_SEC(blaster, edgedamage),
                        WEP_CVAR_SEC(blaster, radius),
                        WEP_CVAR_SEC(blaster, force),
                        WEP_CVAR_SEC(blaster, force_zscale),
                        WEP_CVAR_SEC(blaster, speed),
                        WEP_CVAR_SEC(blaster, spread),
                        WEP_CVAR_SEC(blaster, delay),
                        WEP_CVAR_SEC(blaster, lifetime)
                    );
                    weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(blaster, animtime), w_ready);
                }

                break;
            }
        }
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
	actor.jump_interval = time + WEP_CVAR_SEC(blaster, refire) * W_WeaponRateFactor(actor);
	.entity weaponentity = weaponentities[1];
	BLASTER_SECONDARY_ATTACK(blaster, actor, weaponentity);
}

#endif
#ifdef CSQC

METHOD(Blaster, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 6;
    pointparticles(EFFECT_BLASTER_IMPACT, org2, w_backoff * 1000, 1);
    if(!w_issilent) { sound(actor, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM); }
}

#endif
