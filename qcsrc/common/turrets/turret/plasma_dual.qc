#include "plasma_dual.qh"

#ifdef SVQC

spawnfunc(turret_plasma_dual) { if (!turret_initialize(this, TUR_PLASMA_DUAL)) delete(this); }

METHOD(DualPlasmaTurret, tr_attack, void(DualPlasmaTurret thistur, entity it))
{
    if (MUTATOR_IS_ENABLED(mutator_instagib)) {
        .entity weaponentity = weaponentities[0]; // TODO: unhardcode
        FireRailgunBullet (it, weaponentity, it.tur_shotorg, it.tur_shotorg + it.tur_shotdir_updated * max_shot_distance, 10000000000, false,
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
