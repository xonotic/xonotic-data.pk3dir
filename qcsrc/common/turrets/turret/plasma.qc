#ifndef TURRET_PLASMA_H
#define TURRET_PLASMA_H

#include "plasma_weapon.qc"

CLASS(PlasmaTurret, Turret)
/* spawnflags */ ATTRIB(PlasmaTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(PlasmaTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(PlasmaTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(PlasmaTurret, mdl, string, "base.md3");
/* model      */ ATTRIB_STRZONE(PlasmaTurret, model, string, strcat("models/turrets/", this.mdl));
/* head_model */ ATTRIB_STRZONE(PlasmaTurret, head_model, string, strcat("models/turrets/", "plasma.md3"));
/* netname    */ ATTRIB(PlasmaTurret, netname, string, "plasma");
/* fullname   */ ATTRIB(PlasmaTurret, turret_name, string, _("Plasma Cannon"));
    ATTRIB(PlasmaTurret, m_weapon, Weapon, WEP_PLASMA);
ENDCLASS(PlasmaTurret)
REGISTER_TURRET(PLASMA, NEW(PlasmaTurret));

#endif

#ifdef IMPLEMENTATION

#include "plasma_weapon.qc"

#ifdef SVQC

spawnfunc(turret_plasma) { if (!turret_initialize(TUR_PLASMA)) remove(self); }

METHOD(PlasmaTurret, tr_attack, void(PlasmaTurret this))
{
    if(g_instagib)
    {
        FireRailgunBullet (self.tur_shotorg, self.tur_shotorg + self.tur_shotdir_updated * MAX_SHOT_DISTANCE, 10000000000,
                           800, 0, 0, 0, 0, DEATH_TURRET_PLASMA.m_id);

        Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

        // teamcolor / hit beam effect
        vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
        WarpZone_TrailParticles(world, particleeffectnum(EFFECT_VAPORIZER(self.team)), self.tur_shotorg, v);
    }
    else
    {
        SUPER(PlasmaTurret).tr_attack(this);
    }
    if (self.tur_head.frame == 0)
        self.tur_head.frame = 1;
}
METHOD(PlasmaTurret, tr_think, void(PlasmaTurret thistur))
{
    if (self.tur_head.frame != 0)
        self.tur_head.frame = self.tur_head.frame + 1;

    if (self.tur_head.frame > 5)
        self.tur_head.frame = 0;
}
METHOD(PlasmaTurret, tr_setup, void(PlasmaTurret this, entity it))
{
    it.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.firecheck_flags |= TFL_FIRECHECK_AFF;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE | TFL_AIM_SPLASH;

    turret_do_updates(it);
}

#endif
#endif
