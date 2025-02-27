#include "plasma.qh"

#ifdef SVQC

spawnfunc(turret_plasma) { if (!turret_initialize(this, TUR_PLASMA)) delete(this); }

METHOD(PlasmaTurret, tr_attack, void(PlasmaTurret this, entity actor))
{
    if(MUTATOR_IS_ENABLED(mutator_instagib))
    {
        .entity weaponentity = weaponentities[0]; // TODO: unhardcode
        FireRailgunBullet (actor, weaponentity, actor.tur_shotorg, actor.tur_shotorg + actor.tur_shotdir_updated * max_shot_distance, 10000000000, false,
                           800, 0, 0, 0, 0, DEATH_TURRET_PLASMA.m_id);

        Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);

        // teamcolor / hit beam effect
        vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
        vector rgb = Team_ColorRGB(actor.team);
        Send_Effect_Except(EFFECT_VAPORIZER_BEAM, actor.tur_shotorg, v, 1, rgb, rgb, NULL);
    }
    else
    {
        entity missile = turret_projectile(actor, SND_PlasmaAttack_FIRE, 1, 0, DEATH_TURRET_PLASMA.m_id, PROJECTILE_ELECTRO_BEAM, true, true);
        missile.missile_flags = MIF_SPLASH;
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);
    }
    if (actor.tur_head.frame == 0)
        actor.tur_head.frame = 1;
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

#endif
