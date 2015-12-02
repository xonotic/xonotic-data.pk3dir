#ifndef TURRET_MACHINEGUN_H
#define TURRET_MACHINEGUN_H

#include "machinegun_weapon.qc"

CLASS(MachineGunTurret, Turret)
/* spawnflags */ ATTRIB(MachineGunTurret, spawnflags, int, TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(MachineGunTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(MachineGunTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(MachineGunTurret, mdl, string, "base.md3");
/* model      */ ATTRIB_STRZONE(MachineGunTurret, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(MachineGunTurret, head_model, string, strcat("models/turrets/", "machinegun.md3"));
/* netname    */ ATTRIB(MachineGunTurret, netname, string, "machinegun");
/* fullname   */ ATTRIB(MachineGunTurret, turret_name, string, _("Machinegun Turret"));
    ATTRIB(MachineGunTurret, m_weapon, Weapon, WEP_TUR_MACHINEGUN);
ENDCLASS(MachineGunTurret)
REGISTER_TURRET(MACHINEGUN, NEW(MachineGunTurret));

#endif

#ifdef IMPLEMENTATION

#include "machinegun_weapon.qc"

#ifdef SVQC

spawnfunc(turret_machinegun) { if (!turret_initialize(TUR_MACHINEGUN)) remove(self); }

METHOD(MachineGunTurret, tr_setup, void(MachineGunTurret this, entity it))
{
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;
    it.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
    it.turret_flags |= TUR_FLAG_HITSCAN;
}

#endif // SVQC
#endif
