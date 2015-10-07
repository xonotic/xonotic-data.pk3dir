#ifndef TURRET_MACHINEGUN_WEAPON_H
#define TURRET_MACHINEGUN_WEAPON_H

CLASS(MachineGunTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(MachineGunTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(MachineGunTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(MachineGunTurretAttack, netname, string, "turret_machinegun");
/* wepname   */ ATTRIB(MachineGunTurretAttack, message, string, _("Machinegun"));
ENDCLASS(MachineGunTurretAttack)
REGISTER_WEAPON(TUR_MACHINEGUN, NEW(MachineGunTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

void W_MachineGun_MuzzleFlash();

METHOD(MachineGunTurretAttack, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
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
            weapon_thinkf(actor, WFRAME_FIRE1, 0, w_ready);
        }
        fireBullet (actor.tur_shotorg, actor.tur_shotdir_updated, actor.shot_spread, 0, actor.shot_dmg, actor.shot_force, DEATH_TURRET_MACHINEGUN.m_id, 0);
        W_MachineGun_MuzzleFlash();
        setattachment(actor.muzzle_flash, actor.tur_head, "tag_fire");
    }
}

#endif

#endif
