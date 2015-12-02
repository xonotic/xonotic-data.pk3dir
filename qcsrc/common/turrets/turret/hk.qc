#ifndef TURRET_HK_H
#define TURRET_HK_H

//#define TURRET_DEBUG_HK

#include "hk_weapon.qc"

CLASS(HunterKiller, Turret)
/* spawnflags */ ATTRIB(HunterKiller, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER | TUR_FLAG_RECIEVETARGETS);
/* mins       */ ATTRIB(HunterKiller, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(HunterKiller, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(HunterKiller, mdl, string, "base.md3");
/* model      */ ATTRIB_STRZONE(HunterKiller, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(HunterKiller, head_model, string, strcat("models/turrets/", "hk.md3"));
/* netname    */ ATTRIB(HunterKiller, netname, string, "hk");
/* fullname   */ ATTRIB(HunterKiller, turret_name, string, _("Hunter-Killer Turret"));
    ATTRIB(HunterKiller, m_weapon, Weapon, WEP_HK);
ENDCLASS(HunterKiller)
REGISTER_TURRET(HK, NEW(HunterKiller));

#endif

#ifdef IMPLEMENTATION

#include "hk_weapon.qc"

#ifdef SVQC

#ifdef TURRET_DEBUG_HK
.float atime;
#endif

spawnfunc(turret_hk) { if(!turret_initialize(TUR_HK)) remove(self); }

METHOD(HunterKiller, tr_think, void(HunterKiller thistur))
{
    if (self.tur_head.frame != 0)
        self.tur_head.frame = self.tur_head.frame + 1;

    if (self.tur_head.frame > 5)
        self.tur_head.frame = 0;
}

float turret_hk_addtarget(entity e_target,entity e_sender);
METHOD(HunterKiller, tr_setup, void(HunterKiller this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_SIMPLE;
    it.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_TRIGGERTARGET | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;
    it.firecheck_flags = TFL_FIRECHECK_DEAD | TFL_FIRECHECK_TEAMCHECK  | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AFF;
    it.shoot_flags = TFL_SHOOT_CLEARTARGET;
    it.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_TEAMCHECK;

    it.turret_addtarget = turret_hk_addtarget;
}

float turret_hk_addtarget(entity e_target,entity e_sender)
{SELFPARAM();
    if (e_target)
    {
        if (turret_validate_target(self,e_target,self.target_validate_flags) > 0)
        {
            self.enemy = e_target;
            return 1;
        }
    }

    return 0;
}

#endif // SVQC
#endif
