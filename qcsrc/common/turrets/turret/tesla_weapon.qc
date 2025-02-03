#include "tesla_weapon.qh"

#ifdef SVQC

entity toast(entity actor, entity from, float range, float damage);
SOUND(TeslaCoilTurretAttack_FIRE, W_Sound("electro_fire"));
METHOD(TeslaCoilTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1)) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_TeslaCoilTurretAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_TESLA.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
        }

        float d = actor.shot_dmg;
        float r = actor.target_range;
        entity e = spawn();
        setorigin(e, actor.tur_shotorg);

        actor.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

        entity t = toast(actor, e,r,d);
        delete(e);

        if (t == NULL) return;

        actor.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_TEAMCHECK;

        actor.attack_finished_single[0] = time + actor.shot_refire;
        for (int i = 0; i < 10; ++i) {
            d *= 0.75;
            r *= 0.85;
            t = toast(actor, t, r, d);
            if (t == NULL) break;

        }

        IL_EACH(g_railgunhit, it.railgunhit,
        {
            it.railgunhit = false;
        });
        IL_CLEAR(g_railgunhit);
    }
}

entity toast(entity actor, entity from, float range, float damage)
{
    float dd = range + 1;
    entity etarget = NULL;
    FOREACH_ENTITY_RADIUS(from.origin, range, it != from && !it.railgunhit,
    {
        float r = turret_validate_target(actor, it, actor.target_validate_flags);
        if(r > 0)
        {
            traceline(from.origin, 0.5 * (it.absmin + it.absmax), MOVE_WORLDONLY, from);
            if(trace_fraction == 1.0)
            {
                float d = vlen(it.origin - from.origin);
                if(d < dd)
                {
                    dd = d;
                    etarget = it;
                }
            }
        }
    });

    if (etarget)
    {
        te_csqc_lightningarc(from.origin, etarget.origin);
        if (etarget != actor.realowner)
            Damage(etarget, actor, actor, damage, DEATH_TURRET_TESLA.m_id, DMG_NOWEP, etarget.origin, '0 0 0');
        etarget.railgunhit = true;
        IL_PUSH(g_railgunhit, etarget);
    }

    return etarget;
}

#endif
