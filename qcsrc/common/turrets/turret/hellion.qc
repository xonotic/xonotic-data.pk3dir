#ifndef TURRET_HELLION_H
#define TURRET_HELLION_H

#include "hellion_weapon.qc"

CLASS(Hellion, Turret)
/* spawnflags */ ATTRIB(Hellion, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_FASTPROJ | TUR_FLAG_PLAYER | TUR_FLAG_MISSILE);
/* mins       */ ATTRIB(Hellion, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(Hellion, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(Hellion, mdl, string, "base.md3");
/* model      */ ATTRIB(Hellion, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(Hellion, head_model, string, strzone(strcat("models/turrets/", "hellion.md3")));
/* netname    */ ATTRIB(Hellion, netname, string, "hellion");
/* fullname   */ ATTRIB(Hellion, turret_name, string, _("Hellion Missile Turret"));
    ATTRIB(Hellion, m_weapon, Weapon, WEP_HELLION);
ENDCLASS(Hellion)
REGISTER_TURRET(HELLION, NEW(Hellion));

#endif

#ifdef IMPLEMENTATION

#include "hellion_weapon.qc"

#ifdef SVQC

spawnfunc(turret_hellion) { if (!turret_initialize(TUR_HELLION)) remove(self); }

METHOD(Hellion, tr_think, void(Hellion thistur))
{
    if (self.tur_head.frame != 0)
        self.tur_head.frame += 1;

    if (self.tur_head.frame >= 7)
        self.tur_head.frame = 0;
}
METHOD(Hellion, tr_setup, void(Hellion this, entity it))
{
    it.aim_flags = TFL_AIM_SIMPLE;
    it.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK ;
    it.firecheck_flags = TFL_FIRECHECK_DEAD | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_TEAMCHECK | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AFF | TFL_FIRECHECK_AMMO_OWN;
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
}

#endif
#endif
