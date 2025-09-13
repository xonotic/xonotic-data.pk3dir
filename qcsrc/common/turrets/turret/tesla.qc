#include "tesla.qh"

#ifdef SVQC

spawnfunc(turret_tesla) { if (!turret_initialize(this, TUR_TESLA)) delete(this); }

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

#endif // SVQC
#ifdef MENUQC

METHOD(TeslaCoil, describe, string(TeslaCoil this))
{
    TC(TeslaCoil, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is a turret that electrocutes all who dare come near it, sending powerful high-voltage arcs of lightning to strike its targets."), COLORED_NAME(this));
    PAR(_("Since the arcs of lightning can jump between nearby targets, it is best to just stay away from the %s."), COLORED_NAME(this));
    return PAGE_TEXT;
}

#endif // MENUQC
