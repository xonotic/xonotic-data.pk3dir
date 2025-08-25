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
        vector rgb = Team_ColorRGB(it.team);
        Send_Effect_Except(EFFECT_VAPORIZER_BEAM, it.tur_shotorg, v, 1, rgb, rgb, NULL);
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

#endif // SVQC
#ifdef MENUQC
#include <common/weapons/weapon/electro.qh>
#include "plasma.qh"

METHOD(DualPlasmaTurret, describe, string(DualPlasmaTurret this))
{
    TC(DualPlasmaTurret, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is a turret that fires electric balls forwards from its two cannons, shooting balls similar to those of the %s."), COLORED_NAME(this), COLORED_NAME(WEP_ELECTRO));
    PAR(_("It is a stronger version of the %s, which only has one electric ball cannon."), COLORED_NAME(TUR_PLASMA));
    return PAGE_TEXT;
}

#endif // MENUQC
