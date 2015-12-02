#ifndef TURRET_WALKER_WEAPON_H
#define TURRET_WALKER_WEAPON_H

CLASS(WalkerTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(WalkerTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(WalkerTurretAttack, impulse, int, 5);
/* refname   */ ATTRIB(WalkerTurretAttack, netname, string, "turret_walker");
/* wepname   */ ATTRIB(WalkerTurretAttack, m_name, string, _("Walker"));
ENDCLASS(WalkerTurretAttack)
REGISTER_WEAPON(WALKER, NEW(WalkerTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

SOUND(WalkerTurretAttack_FIRE, W_Sound("electro_fire"));
METHOD(WalkerTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, SND(WalkerTurretAttack_FIRE), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        sound (actor, CH_WEAPON_A, SND_UZI_FIRE, VOL_BASE, ATTEN_NORM);
        fireBullet (actor.tur_shotorg, actor.tur_shotdir_updated, actor.shot_spread, 0, actor.shot_dmg, actor.shot_force, DEATH_TURRET_WALK_GUN.m_id, 0);
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, actor.tur_shotorg, actor.tur_shotdir_updated * 1000, 1);
    }
}

#endif

#endif
