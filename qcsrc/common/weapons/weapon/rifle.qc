#include "rifle.qh"

#ifdef SVQC

void W_Rifle_FireBullet(Weapon thiswep, .entity weaponentity, float pSpread, float pDamage, float pForce, float pSolidPenetration, float pAmmo, int deathtype, float pTracer, float pShots, Sound pSound, entity actor)
{
	float i;

	W_DecreaseAmmo(thiswep, actor, pAmmo, weaponentity);

	W_SetupShot(actor, weaponentity, true, 2, pSound, CH_WEAPON_A, pDamage * pShots, deathtype);

	Send_Effect(EFFECT_RIFLE_MUZZLEFLASH, w_shotorg, w_shotdir * 2000, 1);

	if(PHYS_INPUT_BUTTON_ZOOM(actor) | PHYS_INPUT_BUTTON_ZOOMSCRIPT(actor)) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = actor.origin + actor.view_ofs + ((w_shotorg - actor.origin - actor.view_ofs) * v_forward) * v_forward;
	}

	for(i = 0; i < pShots; ++i)
		fireBullet(actor, weaponentity, w_shotorg, w_shotdir, pSpread, pSolidPenetration, pDamage, pForce, deathtype, (pTracer ? EFFECT_RIFLE : EFFECT_RIFLE_WEAK));

	if(autocvar_g_casings >= 2)
    {
        makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
    }
}

void W_Rifle_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_Rifle_FireBullet(thiswep, weaponentity, WEP_CVAR_PRI(rifle, spread), WEP_CVAR_PRI(rifle, damage), WEP_CVAR_PRI(rifle, force), WEP_CVAR_PRI(rifle, solidpenetration), WEP_CVAR_PRI(rifle, ammo), thiswep.m_id, WEP_CVAR_PRI(rifle, tracer), WEP_CVAR_PRI(rifle, shots), SND_CAMPINGRIFLE_FIRE, actor);
}

void W_Rifle_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_Rifle_FireBullet(thiswep, weaponentity, WEP_CVAR_SEC(rifle, spread), WEP_CVAR_SEC(rifle, damage), WEP_CVAR_SEC(rifle, force), WEP_CVAR_SEC(rifle, solidpenetration), WEP_CVAR_SEC(rifle, ammo), thiswep.m_id | HITTYPE_SECONDARY, WEP_CVAR_SEC(rifle, tracer), WEP_CVAR_SEC(rifle, shots), SND_CAMPINGRIFLE_FIRE2, actor);
}

.void(Weapon thiswep, entity actor, .entity weaponentity) rifle_bullethail_attackfunc;
.WFRAME rifle_bullethail_frame;
.float rifle_bullethail_animtime;
.float rifle_bullethail_refire;
void W_Rifle_BulletHail_Continue(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	float r, af;

	Weapon sw = actor.(weaponentity).m_switchweapon; // make it not detect weapon changes as reason to abort firing
	af = ATTACK_FINISHED(actor, weaponentity);
	actor.(weaponentity).m_switchweapon = actor.(weaponentity).m_weapon;
	ATTACK_FINISHED(actor, weaponentity) = time;
	r = weapon_prepareattack(thiswep, actor, weaponentity, actor.rifle_bullethail_frame == WFRAME_FIRE2, actor.rifle_bullethail_refire);
	if(actor.(weaponentity).m_switchweapon == actor.(weaponentity).m_weapon)
		actor.(weaponentity).m_switchweapon = sw;
	if(r)
	{
		actor.rifle_bullethail_attackfunc(thiswep, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, actor.rifle_bullethail_frame, actor.rifle_bullethail_animtime, W_Rifle_BulletHail_Continue);
	}
	else
	{
		ATTACK_FINISHED(actor, weaponentity) = af; // reset attack_finished if we didn't fire, so the last shot enforces the refire time
	}
}

void W_Rifle_BulletHail(Weapon thiswep, entity actor, .entity weaponentity, float mode, void(Weapon thiswep, entity actor, .entity weaponentity) AttackFunc, WFRAME fr, float animtime, float refire)
{
	// if we get here, we have at least one bullet to fire
	AttackFunc(thiswep, actor, weaponentity);
	if(mode)
	{
		// continue hail
		actor.rifle_bullethail_attackfunc = AttackFunc;
		actor.rifle_bullethail_frame = fr;
		actor.rifle_bullethail_animtime = animtime;
		actor.rifle_bullethail_refire = refire;
		weapon_thinkf(actor, weaponentity, fr, animtime, W_Rifle_BulletHail_Continue);
	}
	else
	{
		// just one shot
		weapon_thinkf(actor, weaponentity, fr, animtime, w_ready);
	}
}

.float bot_secondary_riflemooth;

METHOD(Rifle, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    PHYS_INPUT_BUTTON_ATCK(actor) = false;
    PHYS_INPUT_BUTTON_ATCK2(actor) = false;
    if(vdist(actor.origin - actor.enemy.origin, >, 1000))
        actor.bot_secondary_riflemooth = 0;
    if(actor.bot_secondary_riflemooth == 0)
    {
        if(bot_aim(actor, weaponentity, 1000000, 0, 0.001, false))
        {
            PHYS_INPUT_BUTTON_ATCK(actor) = true;
            if(random() < 0.01) actor.bot_secondary_riflemooth = 1;
        }
    }
    else
    {
        if(bot_aim(actor, weaponentity, 1000000, 0, 0.001, false))
        {
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
            if(random() < 0.03) actor.bot_secondary_riflemooth = 0;
        }
    }
}
METHOD(Rifle, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(autocvar_g_balance_rifle_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR_PRI(rifle, ammo), WEP_CVAR_SEC(rifle, ammo))) { // forced reload
        thiswep.wr_reload(thiswep, actor, weaponentity);
    } else
    {
        actor.(weaponentity).rifle_accumulator = bound(time - WEP_CVAR(rifle, bursttime), actor.(weaponentity).rifle_accumulator, time);
        if(fire & 1)
        if(weapon_prepareattack_check(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(rifle, refire)))
        if(time >= actor.(weaponentity).rifle_accumulator + WEP_CVAR_PRI(rifle, burstcost))
        {
            weapon_prepareattack_do(actor, weaponentity, false, WEP_CVAR_PRI(rifle, refire));
            W_Rifle_BulletHail(thiswep, actor, weaponentity, WEP_CVAR_PRI(rifle, bullethail), W_Rifle_Attack, WFRAME_FIRE1, WEP_CVAR_PRI(rifle, animtime), WEP_CVAR_PRI(rifle, refire));
            actor.(weaponentity).rifle_accumulator += WEP_CVAR_PRI(rifle, burstcost);
        }
        if(fire & 2)
        {
            if(WEP_CVAR(rifle, secondary))
            {
                if(WEP_CVAR_SEC(rifle, reload)) {
                    thiswep.wr_reload(thiswep, actor, weaponentity);
                } else
                {
                    if(weapon_prepareattack_check(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(rifle, refire)))
                    if(time >= actor.(weaponentity).rifle_accumulator + WEP_CVAR_SEC(rifle, burstcost))
                    {
                        weapon_prepareattack_do(actor, weaponentity, true, WEP_CVAR_SEC(rifle, refire));
                        W_Rifle_BulletHail(thiswep, actor, weaponentity, WEP_CVAR_SEC(rifle, bullethail), W_Rifle_Attack2, WFRAME_FIRE2, WEP_CVAR_SEC(rifle, animtime), WEP_CVAR_PRI(rifle, refire));
                        actor.(weaponentity).rifle_accumulator += WEP_CVAR_SEC(rifle, burstcost);
                    }
                }
            }
        }
    }
}
METHOD(Rifle, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(rifle, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(rifle, ammo);
    return ammo_amount;
}
METHOD(Rifle, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(rifle, ammo);
    ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_SEC(rifle, ammo);
    return ammo_amount;
}
METHOD(Rifle, wr_resetplayer, void(entity thiswep, entity actor))
{
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
        .entity weaponentity = weaponentities[slot];
        actor.(weaponentity).rifle_accumulator = time - WEP_CVAR(rifle, bursttime);
    }
}
METHOD(Rifle, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, min(WEP_CVAR_PRI(rifle, ammo), WEP_CVAR_SEC(rifle, ammo)), SND_RELOAD);
}
METHOD(Rifle, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Rifle, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        if(w_deathtype & HITTYPE_BOUNCE)
            return WEAPON_RIFLE_MURDER_HAIL_PIERCING;
        else
            return WEAPON_RIFLE_MURDER_HAIL;
    }
    else
    {
        if(w_deathtype & HITTYPE_BOUNCE)
            return WEAPON_RIFLE_MURDER_PIERCING;
        else
            return WEAPON_RIFLE_MURDER;
    }
}
METHOD(Rifle, wr_zoom, bool(entity thiswep, entity actor))
{
    return PHYS_INPUT_BUTTON_ATCK2(actor) && WEP_CVAR(rifle, secondary) == 0;
}

#endif
#ifdef CSQC

METHOD(Rifle, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 2;
    pointparticles(EFFECT_RIFLE_IMPACT, org2, w_backoff * 1000, 1);
    if(!w_issilent)
    {
        sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
    }
}
METHOD(Rifle, wr_init, void(entity thiswep))
{
    if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
    {
        precache_pic("gfx/reticle_nex");
    }
}
METHOD(Rifle, wr_zoom, bool(entity thiswep, entity actor))
{
    if(button_zoom || zoomscript_caught)
    {
        return true;
    }
    else
    {
        // no weapon specific image for this weapon
        return false;
    }
}
METHOD(Rifle, wr_zoomdir, bool(entity thiswep))
{
    return button_attack2 && !WEP_CVAR(rifle, secondary);
}

#endif
