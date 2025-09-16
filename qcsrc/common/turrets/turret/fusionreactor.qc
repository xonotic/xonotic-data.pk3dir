#include "fusionreactor.qh"

#ifdef SVQC
bool turret_fusionreactor_firecheck(entity this)
{
    entity targ = this.enemy;

    switch(MUTATOR_CALLHOOK(FusionReactor_ValidTarget, this, targ))
    {
        case MUT_FUSREAC_TARG_VALID: { return true; }
        case MUT_FUSREAC_TARG_INVALID: { return false; }
    }

    if((this.attack_finished_single[0] > time)
    || (!targ)
    || (IS_DEAD(targ))
    || (this.ammo < this.shot_dmg)
    || (targ.ammo >= targ.ammo_max)
    || (vdist(targ.origin - this.origin, >, this.target_range))
    || (this.team != targ.team)
    || (!(targ.ammo_flags & TFL_AMMO_ENERGY))
    ) { return false; }

    return true;
}

spawnfunc(turret_fusionreactor) { if (!turret_initialize(this, TUR_FUSIONREACTOR)) delete(this); }

METHOD(FusionReactor, tr_attack, void(FusionReactor this, entity it))
{
    it.enemy.ammo = min(it.enemy.ammo + it.shot_dmg,it.enemy.ammo_max);
    vector fl_org = 0.5 * (it.enemy.absmin + it.enemy.absmax);
    te_smallflash(fl_org);
}
METHOD(FusionReactor, tr_think, void(FusionReactor thistur, entity it))
{
    it.tur_head.avelocity = '0 250 0' * (it.ammo / it.ammo_max);
}
METHOD(FusionReactor, tr_setup, void(FusionReactor this, entity it))
{
    it.ammo_flags				= TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE;
    it.target_select_flags	= TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_OWNTEAM | TFL_TARGETSELECT_RANGELIMITS;
    it.firecheck_flags		= TFL_FIRECHECK_AMMO_OWN | TFL_FIRECHECK_AMMO_OTHER | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_DEAD;
    it.shoot_flags			= TFL_SHOOT_HITALLVALID;
    it.aim_flags				= TFL_AIM_NO;
    it.track_flags			= TFL_TRACK_NO;

    it.tur_head.scale = 0.75;
    it.tur_head.avelocity = '0 50 0';

    it.turret_firecheckfunc = turret_fusionreactor_firecheck;
}

#endif // SVQC
#ifdef MENUQC

METHOD(FusionReactor, describe, string(FusionReactor this))
{
    TC(FusionReactor, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is a bit of a unique turret, instead helping out other turrets rather than directly attacking its targets. "
          "It has no weapon of its own, and instead works by generating power for nearby turrets, so that they can attack their shared targets more often."), COLORED_NAME(this));
    PAR(_("This is the only turret that doesn't directly attack its targets."));
    return PAGE_TEXT;
}

#endif // MENUQC
