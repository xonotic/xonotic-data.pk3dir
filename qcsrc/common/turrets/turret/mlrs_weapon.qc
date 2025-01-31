#include "mlrs_weapon.qh"

#ifdef SVQC
SOUND(MLRSTurretAttack_FIRE, W_Sound("rocket_fire"));
METHOD(MLRSTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_MACHINEGUN, sustained_refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_MLRSTurretAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_MLRS.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.shot_radius = 500;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, w_ready);
        }
        turret_tag_fire_update(actor);
        entity missile = turret_projectile(actor, SND_MLRSTurretAttack_FIRE, 6, 10, DEATH_TURRET_MLRS.m_id, PROJECTILE_ROCKET, true, true);
        missile.nextthink = time + max(actor.tur_impacttime,(actor.shot_radius * 2) / actor.shot_speed);
        missile.missile_flags = MIF_SPLASH;
        te_explosion (missile.origin);
    }
}

#endif
