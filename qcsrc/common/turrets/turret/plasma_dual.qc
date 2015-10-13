#ifndef TURRET_PLASMA_DUAL_H
#define TURRET_PLASMA_DUAL_H

CLASS(PlasmaDualAttack, PlasmaAttack)
/* refname   */ ATTRIB(PlasmaDualAttack, netname, string, "turret_plasma_dual");
/* wepname   */ ATTRIB(PlasmaDualAttack, message, string, _("Dual plasma"));
ENDCLASS(PlasmaDualAttack)
REGISTER_WEAPON(PLASMA_DUAL, NEW(PlasmaDualAttack));

CLASS(DualPlasmaTurret, PlasmaTurret)
/* spawnflags */ ATTRIB(DualPlasmaTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(DualPlasmaTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(DualPlasmaTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(DualPlasmaTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(DualPlasmaTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(DualPlasmaTurret, head_model, string, strzone(strcat("models/turrets/", "plasmad.md3")));
/* netname    */ ATTRIB(DualPlasmaTurret, netname, string, "plasma_dual");
/* fullname   */ ATTRIB(DualPlasmaTurret, turret_name, string, _("Dual Plasma Cannon"));
    ATTRIB(DualPlasmaTurret, m_weapon, Weapon, WEP_PLASMA_DUAL);
ENDCLASS(DualPlasmaTurret)
REGISTER_TURRET(PLASMA_DUAL, NEW(DualPlasmaTurret));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

spawnfunc(turret_plasma_dual) { if (!turret_initialize(TUR_PLASMA_DUAL)) remove(self); }

METHOD(DualPlasmaTurret, tr_attack, void(DualPlasmaTurret this))
{
    if (g_instagib) {
        FireRailgunBullet (self.tur_shotorg, self.tur_shotorg + self.tur_shotdir_updated * MAX_SHOT_DISTANCE, 10000000000,
                           800, 0, 0, 0, 0, DEATH_TURRET_PLASMA.m_id);


        Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

        // teamcolor / hit beam effect
        vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
        WarpZone_TrailParticles(world, particleeffectnum(EFFECT_VAPORIZER(self.team)), self.tur_shotorg, v);
    } else {
        super.vtblbase.tr_attack(this);
    }
    self.tur_head.frame += 1;
}
METHOD(DualPlasmaTurret, tr_think, void(DualPlasmaTurret thistur))
{
    if ((self.tur_head.frame != 0) && (self.tur_head.frame != 3))
        self.tur_head.frame = self.tur_head.frame + 1;

    if (self.tur_head.frame > 6)
        self.tur_head.frame = 0;
}

#endif
#endif
