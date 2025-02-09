#include "tesla.qh"

#ifdef SVQC

entity toast(entity actor, entity from, float range, float damage)
{
    float dd = range + 1;
    entity etarget = NULL;
    FOREACH_ENTITY_RADIUS(from.origin, range, it != from && !it.railgunhit,
    {
        float r = turret_validate_target(actor, it, actor.target_validate_flags);
        if(r > 0)
        {
            traceline(from.origin, 0.5 * (it.absmin + it.absmax), MOVE_WORLDONLY, from);
            if(trace_fraction == 1.0)
            {
                float d = vlen(it.origin - from.origin);
                if(d < dd)
                {
                    dd = d;
                    etarget = it;
                }
            }
        }
    });

    if (etarget)
    {
        te_csqc_lightningarc(from.origin, etarget.origin);
        if (etarget != actor.realowner)
            Damage(etarget, actor, actor, damage, DEATH_TURRET_TESLA.m_id, DMG_NOWEP, etarget.origin, '0 0 0');
        etarget.railgunhit = true;
        IL_PUSH(g_railgunhit, etarget);
    }

    return etarget;
}

spawnfunc(turret_tesla) { if (!turret_initialize(this, TUR_TESLA)) delete(this); }

METHOD(TeslaCoil, tr_attack, void(TeslaCoil this, entity actor))
{
    float d = actor.shot_dmg;
    float r = actor.target_range;
    entity e = spawn();
    setorigin(e, actor.tur_shotorg);

    actor.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

    entity t = toast(actor, e,r,d);
    delete(e);

    if (!t)
        return;

    actor.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_TEAMCHECK;

    actor.attack_finished_single[0] = time + actor.shot_refire;
    for (int i = 0; i < 10; ++i) {
        d *= 0.75;
        r *= 0.85;
        t = toast(actor, t, r, d);
        if (!t)
            break;

    }

    IL_EACH(g_railgunhit, it.railgunhit,
    {
        it.railgunhit = false;
    });
    IL_CLEAR(g_railgunhit);
}

METHOD(TeslaCoil, tr_think, void(TeslaCoil thistur, entity it))
{
    if(!it.active)
    {
        it.tur_head.avelocity = '0 0 0';
        return;
    }

    if(it.ammo < it.shot_dmg)
    {
        it.tur_head.avelocity = '0 45 0' * (it.ammo / it.shot_dmg);
    }
    else
    {
        it.tur_head.avelocity = '0 180 0' * (it.ammo / it.shot_dmg);

        if(it.attack_finished_single[0] > time)
            return;

        float f;
        f = (it.ammo / it.ammo_max);
        f = f * f;
        if(f > random())
            if(random() < 0.1)
                te_csqc_lightningarc(it.tur_shotorg,it.tur_shotorg + (randomvec() * 350));
    }
}

bool turret_tesla_firecheck(entity this);
METHOD(TeslaCoil, tr_setup, void(TeslaCoil this, entity it))
{
    it.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
                         TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

    it.turret_firecheckfunc = turret_tesla_firecheck;
    it.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES |
                       TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

    it.firecheck_flags	= TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AMMO_OWN;
    it.shoot_flags		= TFL_SHOOT_CUSTOM;
    it.ammo_flags			= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags			= TFL_AIM_NO;
    it.track_flags		= TFL_TRACK_NO;
}

bool turret_tesla_firecheck(entity this)
{
    // g_turrets_targetscan_maxdelay forces a target re-scan at least this often
    float do_target_scan = 0;

    if((this.target_select_time + autocvar_g_turrets_targetscan_maxdelay) < time)
        do_target_scan = 1;

    // Old target (if any) invalid?
    if(this.target_validate_time < time)
    if (turret_validate_target(this, this.enemy, this.target_validate_flags) <= 0)
    {
        this.enemy = NULL;
        this.target_validate_time = time + 0.5;
        do_target_scan = 1;
    }

    // But never more often then g_turrets_targetscan_mindelay!
    if (this.target_select_time + autocvar_g_turrets_targetscan_mindelay > time)
        do_target_scan = 0;

    if(do_target_scan)
    {
        this.enemy = turret_select_target(this);
        this.target_select_time = time;
    }

    if(!turret_firecheck(this))
        return false;

    if(this.enemy)
        return true;

    return false;
}

#endif
