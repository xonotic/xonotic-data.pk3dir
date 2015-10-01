#ifndef TURRET_MACHINEGUN_WEAPON_H
#define TURRET_MACHINEGUN_WEAPON_H

CLASS(MachineGunTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(MachineGunTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN);
/* impulse   */ ATTRIB(MachineGunTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(MachineGunTurretAttack, netname, string, "turret_machinegun");
/* wepname   */ ATTRIB(MachineGunTurretAttack, message, string, _("Machinegun"));
ENDCLASS(MachineGunTurretAttack)
REGISTER_WEAPON(TUR_MACHINEGUN, NEW(MachineGunTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

void W_MachineGun_MuzzleFlash();

METHOD(MachineGunTurretAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2))
{
    SELFPARAM();
    bool isPlayer = IS_PLAYER(self);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(false, WEP_CVAR(machinegun, sustained_refire))) {
        if (isPlayer) {
            turret_initparams(self);
            W_SetupShot_Dir(self, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            self.tur_shotdir_updated = w_shotdir;
            self.tur_shotorg = w_shotorg;
            self.tur_head = self;
            weapon_thinkf(WFRAME_FIRE1, 0, w_ready);
        }
        fireBullet (self.tur_shotorg, self.tur_shotdir_updated, self.shot_spread, 0, self.shot_dmg, self.shot_force, DEATH_TURRET_MACHINEGUN, 0);
        W_MachineGun_MuzzleFlash();
        setattachment(self.muzzle_flash, self.tur_head, "tag_fire");
    }
    return true;
}

#endif

#endif
