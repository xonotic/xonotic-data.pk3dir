#ifndef TURRET_EWHEEL_WEAPON_H
#define TURRET_EWHEEL_WEAPON_H

CLASS(EWheelAttack, PortoLaunch)
/* flags     */ ATTRIB(EWheelAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(EWheelAttack, impulse, int, 5);
/* refname   */ ATTRIB(EWheelAttack, netname, string, "turret_ewheel");
/* wepname   */ ATTRIB(EWheelAttack, m_name, string, _("eWheel"));
ENDCLASS(EWheelAttack)
REGISTER_WEAPON(EWHEEL, NEW(EWheelAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

void turret_initparams(entity);
SOUND(EWheelAttack_FIRE, W_Sound("electro_fire"));
METHOD(EWheelAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, SND(EWheelAttack_FIRE), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }

        turret_do_updates(actor);

        entity missile = turret_projectile(SND(LASERGUN_FIRE), 1, 0, DEATH_TURRET_EWHEEL.m_id, PROJECTILE_BLASTER, true, true);
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

#endif
