#ifndef TURRET_EWHEEL_WEAPON_H
#define TURRET_EWHEEL_WEAPON_H

CLASS(EWheelAttack, PortoLaunch)
/* flags     */ ATTRIB(EWheelAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN);
/* impulse   */ ATTRIB(EWheelAttack, impulse, int, 5);
/* refname   */ ATTRIB(EWheelAttack, netname, string, "turret_ewheel");
/* wepname   */ ATTRIB(EWheelAttack, message, string, _("eWheel"));
ENDCLASS(EWheelAttack)
REGISTER_WEAPON(EWHEEL, NEW(EWheelAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

void turret_initparams(entity);
METHOD(EWheelAttack, wr_think, void(entity thiswep, bool fire1, bool fire2)) {
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

        turret_do_updates(self);

        entity missile = turret_projectile(SND(LASERGUN_FIRE), 1, 0, DEATH_TURRET_EWHEEL, PROJECTILE_BLASTER, true, true);
        missile.missile_flags = MIF_SPLASH;

        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

        if (!isPlayer) {
            self.tur_head.frame += 2;

            if (self.tur_head.frame > 3)
                self.tur_head.frame = 0;
        }
    }
}

#endif

#endif
