#include "hellion.qh"

#ifdef SVQC

spawnfunc(turret_hellion) { if (!turret_initialize(this, TUR_HELLION)) delete(this); }

METHOD(Hellion, tr_think, void(Hellion thistur, entity it))
{
    if (it.tur_head.frame != 0)
        it.tur_head.frame += 1;

    if (it.tur_head.frame >= 7)
        it.tur_head.frame = 0;
}
METHOD(Hellion, tr_setup, void(Hellion this, entity it))
{
    it.aim_flags = TFL_AIM_SIMPLE;
    it.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK ;
    it.firecheck_flags = TFL_FIRECHECK_DEAD | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_TEAMCHECK | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AFF | TFL_FIRECHECK_AMMO_OWN;
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
}

#endif
