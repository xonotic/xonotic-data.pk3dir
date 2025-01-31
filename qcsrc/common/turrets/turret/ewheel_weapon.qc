#include "ewheel_weapon.qh"

#ifdef SVQC

void turret_initparams(entity);
SOUND(EWheelAttack_FIRE, W_Sound("lasergun_fire"));
METHOD(EWheelAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1)) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_EWheelAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_EWHEEL.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
        }

        turret_do_updates(actor);

        entity missile = turret_projectile(actor, SND_EWheelAttack_FIRE, 1, 0, DEATH_TURRET_EWHEEL.m_id, PROJECTILE_BLASTER, true, true);
        missile.missile_flags = MIF_SPLASH;

        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);

        if (!isPlayer) {
            actor.tur_head.frame += 2;

            if (actor.tur_head.frame > 3)
                actor.tur_head.frame = 0;
        }
    }
}

#endif
