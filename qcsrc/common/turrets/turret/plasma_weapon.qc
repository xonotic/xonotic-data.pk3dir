#ifndef TURRET_PLASMA_WEAPON_H
#define TURRET_PLASMA_WEAPON_H

CLASS(PlasmaAttack, PortoLaunch)
/* flags     */ ATTRIB(PlasmaAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(PlasmaAttack, impulse, int, 5);
/* refname   */ ATTRIB(PlasmaAttack, netname, string, "turret_plasma");
/* wepname   */ ATTRIB(PlasmaAttack, message, string, _("Plasma"));
ENDCLASS(PlasmaAttack)
REGISTER_WEAPON(PLASMA, NEW(PlasmaAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

METHOD(PlasmaAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2)) {
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
        entity missile = turret_projectile(SND(HAGAR_FIRE), 1, 0, DEATH_TURRET_PLASMA, PROJECTILE_ELECTRO_BEAM, true, true);
        missile.missile_flags = MIF_SPLASH;
        Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);
	}
	return true;
}

#endif

#endif
