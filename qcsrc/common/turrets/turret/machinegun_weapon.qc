#include "machinegun_weapon.qh"

#ifdef SVQC

void W_MuzzleFlash_Model(entity wepent, entity muzzlemodel);
SOUND(MachineGunTurretAttack_FIRE, W_Sound("electro_fire"));
METHOD(MachineGunTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_MACHINEGUN, sustained_refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_MachineGunTurretAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_MACHINEGUN.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, w_ready);
        }
        fireBullet(actor, weaponentity, actor.tur_shotorg, actor.tur_shotdir_updated, actor.shot_spread, 0, actor.shot_dmg, 0, actor.shot_force, DEATH_TURRET_MACHINEGUN.m_id, EFFECT_BULLET);
        W_MuzzleFlash_Model(actor.(weaponentity), MDL_MACHINEGUN_MUZZLEFLASH);
        setattachment(actor.(weaponentity).muzzle_flash, actor.tur_head, "tag_fire");
    }
}

#endif
