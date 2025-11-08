#include "plasma.qh"

#ifdef SVQC

spawnfunc(turret_plasma) { if (!turret_initialize(this, TUR_PLASMA)) delete(this); }

METHOD(PlasmaTurret, tr_attack, void(PlasmaTurret this, entity it))
{
    if(MUTATOR_IS_ENABLED(mutator_instagib))
    {
        .entity weaponentity = weaponentities[0]; // TODO: unhardcode
        FireRailgunBullet (it, weaponentity, it.tur_shotorg, it.tur_shotorg + it.tur_shotdir_updated * max_shot_distance, 10000000000, false,
                           800, 0, 0, 0, 0, DEATH_TURRET_PLASMA.m_id);

        Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, it.tur_shotorg, it.tur_shotdir_updated * 1000, 1);

        // teamcolor / hit beam effect
        vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
        vector rgb = Team_ColorRGB(it.team);
        Send_Effect_Except(EFFECT_VAPORIZER_BEAM, it.tur_shotorg, v, 1, rgb, rgb, NULL);
    }
    else
    {
        SUPER(PlasmaTurret).tr_attack(this, it);
    }
    if (it.tur_head.frame == 0)
        it.tur_head.frame = 1;
}
METHOD(PlasmaTurret, tr_think, void(PlasmaTurret thistur, entity it))
{
    if (it.tur_head.frame != 0)
        it.tur_head.frame = it.tur_head.frame + 1;

    if (it.tur_head.frame > 5)
        it.tur_head.frame = 0;
}
METHOD(PlasmaTurret, tr_setup, void(PlasmaTurret this, entity it))
{
    it.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
    it.damage_flags |= TFL_DMG_HEADSHAKE;
    it.firecheck_flags |= TFL_FIRECHECK_AFF;
    it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE | TFL_AIM_SPLASH;

    turret_do_updates(it);
}

#endif // SVQC
#ifdef MENUQC
#include <common/weapons/weapon/electro.qh>
#include "plasma_dual.qh"

METHOD(PlasmaTurret, describe, string(PlasmaTurret this))
{
    TC(PlasmaTurret, this);
    PAGE_TEXT_INIT();
    PAR(_("The %s is a turret that fires electric balls forwards, similar to those of the %s."), COLORED_NAME(this), COLORED_NAME(WEP_ELECTRO));
    PAR(_("It is a weaker version of the %s, which has two electric ball cannons."), COLORED_NAME(TUR_PLASMA_DUAL));
    return PAGE_TEXT;
}

#endif // MENUQC
