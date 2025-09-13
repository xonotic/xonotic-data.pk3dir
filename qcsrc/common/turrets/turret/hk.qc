#include "hk.qh"

#ifdef SVQC

#ifdef TURRET_DEBUG_HK
.float atime;
#endif

spawnfunc(turret_hk) { if(!turret_initialize(this, TUR_HK)) delete(this); }

METHOD(HunterKiller, tr_think, void(HunterKiller thistur, entity it))
{
    if (it.tur_head.frame != 0)
        it.tur_head.frame = it.tur_head.frame + 1;

    if (it.tur_head.frame > 5)
        it.tur_head.frame = 0;
}

bool turret_hk_addtarget(entity this, entity e_target,entity e_sender);
METHOD(HunterKiller, tr_setup, void(HunterKiller this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_SIMPLE;
    it.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_VEHICLES | TFL_TARGETSELECT_TRIGGERTARGET | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;
    it.firecheck_flags = TFL_FIRECHECK_DEAD | TFL_FIRECHECK_TEAMCHECK  | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AFF;
    it.shoot_flags = TFL_SHOOT_CLEARTARGET;
    it.target_validate_flags = TFL_TARGETSELECT_VEHICLES | TFL_TARGETSELECT_TEAMCHECK;

    it.turret_addtarget = turret_hk_addtarget;
}

bool turret_hk_addtarget(entity this, entity e_target,entity e_sender)
{
    if (e_target)
    {
        if (turret_validate_target(this,e_target,this.target_validate_flags) > 0)
        {
            this.enemy = e_target;
            return true;
        }
    }

    return false;
}

#endif // SVQC
#ifdef MENUQC
#include <common/weapons/weapon/devastator.qh>

METHOD(HunterKiller, describe, string(HunterKiller this))
{
    TC(HunterKiller, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s fires a single powerful homing rocket with the ability to evade obstacles to find its target. "
          "The rocket it fires is similar to that of the %s."), COLORED_NAME(this), COLORED_NAME(WEP_DEVASTATOR));
    return PAGE_TEXT;
}

#endif // MENUQC
