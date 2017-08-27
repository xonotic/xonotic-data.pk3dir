#include "machinegun.qh"

#ifdef SVQC

spawnfunc(turret_machinegun) { if (!turret_initialize(this, TUR_MACHINEGUN)) delete(this); }

METHOD(MachineGunTurret, tr_setup, void(MachineGunTurret this, entity it))
{
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;
    it.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
    it.turret_flags |= TUR_FLAG_HITSCAN;
}

#endif // SVQC
