#include "flac.qh"

#ifdef SVQC

spawnfunc(turret_flac) { if (!turret_initialize(this, TUR_FLAC)) delete(this); }

METHOD(Flac, tr_setup, void(Flac this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.target_select_flags |= TFL_TARGETSELECT_NOTURRETS | TFL_TARGETSELECT_MISSILESONLY;
}

#endif
