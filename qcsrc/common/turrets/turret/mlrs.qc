#ifndef TURRET_MLRS_H
#define TURRET_MLRS_H

#include "mlrs_weapon.qc"

CLASS(MLRSTurret, Turret)
/* spawnflags */ ATTRIB(MLRSTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(MLRSTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(MLRSTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(MLRSTurret, mdl, string, "base.md3");
/* model      */ ATTRIB_STRZONE(MLRSTurret, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(MLRSTurret, head_model, string, strcat("models/turrets/", "mlrs.md3"));
/* netname    */ ATTRIB(MLRSTurret, netname, string, "mlrs");
/* fullname   */ ATTRIB(MLRSTurret, turret_name, string, _("MLRS Turret"));
    ATTRIB(MLRSTurret, m_weapon, Weapon, WEP_TUR_MLRS);
ENDCLASS(MLRSTurret)
REGISTER_TURRET(MLRS, NEW(MLRSTurret));

#endif

#ifdef IMPLEMENTATION

#include "mlrs_weapon.qc"

#ifdef SVQC

spawnfunc(turret_mlrs) { if (!turret_initialize(TUR_MLRS)) remove(self); }

METHOD(MLRSTurret, tr_think, void(MLRSTurret thistur))
{
    // 0 = full, 6 = empty
    self.tur_head.frame = bound(0, 6 - floor(0.1 + self.ammo / self.shot_dmg), 6);
    if(self.tur_head.frame < 0)
    {
        LOG_TRACE("ammo:",ftos(self.ammo),"\n");
        LOG_TRACE("shot_dmg:",ftos(self.shot_dmg),"\n");
    }
}
METHOD(MLRSTurret, tr_setup, void(MLRSTurret this, entity it))
{
    it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;

    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.shoot_flags  |= TFL_SHOOT_VOLLYALWAYS;
    it.volly_counter = it.shot_volly;
}

#endif // SVQC
#endif
