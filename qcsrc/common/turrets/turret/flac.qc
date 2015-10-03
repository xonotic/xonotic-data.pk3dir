#ifndef TURRET_FLAC_H
#define TURRET_FLAC_H

#include "flac_weapon.qc"

CLASS(Flac, Turret)
/* spawnflags */ ATTRIB(Flac, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_FASTPROJ | TUR_FLAG_MISSILE);
/* mins       */ ATTRIB(Flac, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(Flac, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(Flac, mdl, string, "base.md3");
/* model      */ ATTRIB(Flac, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(Flac, head_model, string, strzone(strcat("models/turrets/", "flac.md3")));
/* netname    */ ATTRIB(Flac, netname, string, "flac");
/* fullname   */ ATTRIB(Flac, turret_name, string, _("FLAC Cannon"));
    ATTRIB(Flac, m_weapon, Weapon, WEP_FLAC);
ENDCLASS(Flac)
REGISTER_TURRET(FLAC, NEW(Flac));

#endif

#ifdef IMPLEMENTATION

#include "flac_weapon.qc"

#ifdef SVQC

spawnfunc(turret_flac) { if (!turret_initialize(TUR_FLAC)) remove(self); }

METHOD(Flac, tr_setup, void(Flac this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.target_select_flags |= TFL_TARGETSELECT_NOTURRETS | TFL_TARGETSELECT_MISSILESONLY;
}

#endif

#endif
