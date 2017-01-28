#include "blaster.qh"
#ifndef IMPLEMENTATION
CLASS(Blaster, Weapon)
/* ammotype  */ //ATTRIB(Blaster, ammo_field, .int, ammo_none);
/* impulse   */ ATTRIB(Blaster, impulse, int, 1);
/* flags     */ ATTRIB(Blaster, spawnflags, int, WEP_FLAG_NORMAL | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Blaster, bot_pickupbasevalue, float, 0);
/* color     */ ATTRIB(Blaster, wpcolor, vector, '1 0.5 0.5');
/* modelname */ ATTRIB(Blaster, mdl, string, "laser");
#ifdef GAMEQC
/* model     */ ATTRIB(Blaster, m_model, Model, MDL_BLASTER_ITEM);
#endif
/* crosshair */ ATTRIB(Blaster, w_crosshair, string, "gfx/crosshairlaser");
/* crosshair */ ATTRIB(Blaster, w_crosshair_size, float, 0.5);
/* wepimg    */ ATTRIB(Blaster, model2, string, "weaponlaser");
/* refname   */ ATTRIB(Blaster, netname, string, "blaster");
/* wepname   */ ATTRIB(Blaster, m_name, string, _("Blaster"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, delay, float, BOTH) \
		P(class, prefix, edgedamage, float, BOTH) \
		P(class, prefix, force, float, BOTH) \
		P(class, prefix, force_zscale, float, BOTH) \
		P(class, prefix, lifetime, float, BOTH) \
		P(class, prefix, radius, float, BOTH) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, secondary, float, NONE) \
		P(class, prefix, shotangle, float, BOTH) \
		P(class, prefix, speed, float, BOTH) \
		P(class, prefix, spread, float, BOTH) \
        P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, weaponreplace, string, NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
	W_PROPS(X, Blaster, blaster)
#undef X

ENDCLASS(Blaster)
REGISTER_WEAPON(BLASTER, blaster, NEW(Blaster));

#ifdef SVQC
.float blaster_damage;
.float blaster_edgedamage;
.float blaster_radius;
.float blaster_force;
.float blaster_lifetime;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_blaster) { weapon_defaultspawnfunc(this, WEP_BLASTER); }
spawnfunc(weapon_laser) { spawnfunc_weapon_blaster(this); }

void W_Blaster_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	this.event_damage = func_null;

	RadiusDamage(
		this,
		this.realowner,
		this.blaster_damage,
		this.blaster_edgedamage,
		this.blaster_radius,
		NULL,
		NULL,
		this.blaster_force,
		this.projectiledeathtype,
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
	float atk_speed,
	float atk_spread,
	float atk_delay,
	float atk_lifetime)
{
	vector s_forward = v_forward * cos(atk_shotangle * DEG2RAD) + v_up * sin(atk_shotangle * DEG2RAD);

	W_SetupShot_Dir(actor, weaponentity, s_forward, false, 3, SND_LASERGUN_FIRE, CH_WEAPON_B, atk_damage);
	Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	entity missile = new(blasterbolt);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = atk_damage;
	PROJECTILE_MAKETRIGGER(missile);

	missile.blaster_damage = atk_damage;
	missile.blaster_edgedamage = atk_edgedamage;
	missile.blaster_radius = atk_radius;
	missile.blaster_force = atk_force;
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
#endif
