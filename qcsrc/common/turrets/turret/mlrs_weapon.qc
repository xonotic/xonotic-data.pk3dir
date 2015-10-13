#ifndef TURRET_MLRS_WEAPON_H
#define TURRET_MLRS_WEAPON_H

CLASS(MLRSTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(MLRSTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(MLRSTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(MLRSTurretAttack, netname, string, "turret_mlrs");
/* wepname   */ ATTRIB(MLRSTurretAttack, message, string, _("MLRS"));
ENDCLASS(MLRSTurretAttack)
REGISTER_WEAPON(TUR_MLRS, NEW(MLRSTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

METHOD(MLRSTurretAttack, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
{
    bool isPlayer = IS_PLAYER(actor);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, false, WEP_CVAR(machinegun, sustained_refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.shot_radius = 500;
            weapon_thinkf(actor, WFRAME_FIRE1, 0, w_ready);
        }
        turret_tag_fire_update();
        entity missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_MLRS.m_id, PROJECTILE_ROCKET, TRUE, TRUE);
        missile.nextthink = time + max(actor.tur_impacttime,(actor.shot_radius * 2) / actor.shot_speed);
        missile.missile_flags = MIF_SPLASH;
        te_explosion (missile.origin);
    }
}

#endif

#endif
