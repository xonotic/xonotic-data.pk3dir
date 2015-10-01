#ifndef TURRET_WALKER_WEAPON_H
#define TURRET_WALKER_WEAPON_H

CLASS(WalkerTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(WalkerTurretAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN);
/* impulse   */ ATTRIB(WalkerTurretAttack, impulse, int, 5);
/* refname   */ ATTRIB(WalkerTurretAttack, netname, string, "turret_walker");
/* wepname   */ ATTRIB(WalkerTurretAttack, message, string, _("Walker"));
ENDCLASS(WalkerTurretAttack)
REGISTER_WEAPON(WALKER, NEW(WalkerTurretAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

METHOD(WalkerTurretAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2)) {
    SELFPARAM();
    bool isPlayer = IS_PLAYER(self);
    if (fire1)
    if (!isPlayer || weapon_prepareattack(false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(self);
            W_SetupShot_Dir(self, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
            self.tur_shotdir_updated = w_shotdir;
            self.tur_shotorg = w_shotorg;
            self.tur_head = self;
            weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        sound (self, CH_WEAPON_A, SND_UZI_FIRE, VOL_BASE, ATTEN_NORM);
        fireBullet (self.tur_shotorg, self.tur_shotdir_updated, self.shot_spread, 0, self.shot_dmg, self.shot_force, DEATH_TURRET_WALK_GUN, 0);
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);
    }
    return true;
}

#endif

#endif
