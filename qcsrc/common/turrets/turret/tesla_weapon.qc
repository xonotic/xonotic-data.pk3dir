#include "tesla_weapon.qh"

#ifdef IMPLEMENTATION

#ifdef SVQC

entity toast(entity actor, entity from, float range, float damage);
SOUND(TeslaCoilTurretAttack_FIRE, W_Sound("electro_fire"));
METHOD(TeslaCoilTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_TeslaCoilTurretAttack_FIRE, CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
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

        FOREACH_ENTITY_FLOAT(railgunhit, 1,
        {
            it.railgunhit = 0;
        });
    }
}

entity toast(entity actor, entity from, float range, float damage)
{
    entity e;
    entity etarget = NULL;
    float d,dd;
    float r;

    dd = range + 1;

    e = findradius(from.origin,range);
    while (e)
    {
        if ((e.railgunhit != 1) && (e != from))
        {
            r = turret_validate_target(actor,e,actor.target_validate_flags);
            if (r > 0)
            {
                traceline(from.origin,0.5 * (e.absmin + e.absmax),MOVE_WORLDONLY,from);
                if (trace_fraction == 1.0)
                {
                    d = vlen(e.origin - from.origin);
                    if (d < dd)
                    {
                        dd = d;
                        etarget = e;
                    }
                }
            }
        }
        e = e.chain;
    }

    if (etarget)
    {
        te_csqc_lightningarc(from.origin,etarget.origin);
        Damage(etarget, actor, actor, damage, DEATH_TURRET_TESLA.m_id, etarget.origin, '0 0 0');
        etarget.railgunhit = 1;
    }

    return etarget;
}

#endif

#endif
