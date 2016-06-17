#ifndef TURRET_PLASMA_DUAL_H
#define TURRET_PLASMA_DUAL_H

#include "plasma_weapon.qh"

CLASS(PlasmaDualAttack, PlasmaAttack)
/* refname   */ ATTRIB(PlasmaDualAttack, netname, string, "turret_plasma_dual");
/* wepname   */ ATTRIB(PlasmaDualAttack, m_name, string, _("Dual plasma"));
ENDCLASS(PlasmaDualAttack)
REGISTER_WEAPON(PLASMA_DUAL, NEW(PlasmaDualAttack));

CLASS(DualPlasmaTurret, PlasmaTurret)
/* spawnflags */ ATTRIB(DualPlasmaTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(DualPlasmaTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(DualPlasmaTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(DualPlasmaTurret, mdl, string, "base.md3");
/* model      */ ATTRIB_STRZONE(DualPlasmaTurret, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(DualPlasmaTurret, head_model, string, strcat("models/turrets/", "plasmad.md3"));
/* netname    */ ATTRIB(DualPlasmaTurret, netname, string, "plasma_dual");
/* fullname   */ ATTRIB(DualPlasmaTurret, turret_name, string, _("Dual Plasma Cannon"));
    ATTRIB(DualPlasmaTurret, m_weapon, Weapon, WEP_PLASMA_DUAL);
ENDCLASS(DualPlasmaTurret)
REGISTER_TURRET(PLASMA_DUAL, NEW(DualPlasmaTurret));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

spawnfunc(turret_plasma_dual) { if (!turret_initialize(this, TUR_PLASMA_DUAL)) remove(this); }

METHOD(DualPlasmaTurret, tr_attack, void(DualPlasmaTurret thistur, entity it))
{
    if (g_instagib) {
        FireRailgunBullet (it, it.tur_shotorg, it.tur_shotorg + it.tur_shotdir_updated * MAX_SHOT_DISTANCE, 10000000000,
                           800, 0, 0, 0, 0, DEATH_TURRET_PLASMA.m_id);


        Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, it.tur_shotorg, it.tur_shotdir_updated * 1000, 1);

        // teamcolor / hit beam effect
        vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
        WarpZone_TrailParticles(NULL, particleeffectnum(EFFECT_VAPORIZER(it.team)), it.tur_shotorg, v);
    } else {
        SUPER(PlasmaTurret).tr_attack(thistur, it);
    }
    it.tur_head.frame += 1;
}
METHOD(DualPlasmaTurret, tr_think, void(DualPlasmaTurret thistur, entity it))
{
    if ((it.tur_head.frame != 0) && (it.tur_head.frame != 3))
        it.tur_head.frame = it.tur_head.frame + 1;

    if (it.tur_head.frame > 6)
        it.tur_head.frame = 0;
}

#endif
#endif
