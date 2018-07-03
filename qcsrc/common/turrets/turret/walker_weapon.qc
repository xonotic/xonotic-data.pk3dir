#include "walker_weapon.qh"

#ifdef SVQC

SOUND(WalkerTurretAttack_FIRE, W_Sound("electro_fire"));
METHOD(WalkerTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_WalkerTurretAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_WALK_GUN.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        sound (actor, CH_WEAPON_A, SND_UZI_FIRE, VOL_BASE, ATTEN_NORM);
        fireBullet(actor, weaponentity, actor.tur_shotorg, actor.tur_shotdir_updated, actor.shot_spread, 0, actor.shot_dmg, actor.shot_force, DEATH_TURRET_WALK_GUN.m_id, EFFECT_BULLET);
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);
    }
}

#endif
