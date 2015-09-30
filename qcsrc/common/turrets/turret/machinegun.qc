#ifndef TUR_MACHINEGUN_H
#define TUR_MACHINEGUN_H

CLASS(MachineGunTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(MachineGunTurretAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(MachineGunTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(MachineGunTurretAttack, netname, string, "turret_machinegun");
/* wepname   */ ATTRIB(MachineGunTurretAttack, message, string, _("Machinegun"));
ENDCLASS(MachineGunTurretAttack)
REGISTER_WEAPON(TUR_MACHINEGUN, NEW(MachineGunTurretAttack));

CLASS(MachineGunTurret, Turret)
/* spawnflags */ ATTRIB(MachineGunTurret, spawnflags, int, TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(MachineGunTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(MachineGunTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(MachineGunTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(MachineGunTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(MachineGunTurret, head_model, string, strzone(strcat("models/turrets/", "machinegun.md3")));
/* netname    */ ATTRIB(MachineGunTurret, netname, string, "machinegun");
/* fullname   */ ATTRIB(MachineGunTurret, turret_name, string, _("Machinegun Turret"));
    ATTRIB(MachineGunTurret, m_weapon, Weapon, WEP_TUR_MACHINEGUN);
ENDCLASS(MachineGunTurret)
REGISTER_TURRET(MACHINEGUN, NEW(MachineGunTurret));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
void W_MachineGun_MuzzleFlash();

METHOD(MachineGunTurretAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2)) {
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

void spawnfunc_turret_machinegun() { SELFPARAM(); if(!turret_initialize(TUR_MACHINEGUN)) remove(self); }

        METHOD(MachineGunTurret, tr_setup, void(MachineGunTurret this, entity it))
        {
            it.damage_flags |= TFL_DMG_HEADSHAKE;
            it.target_select_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;
            it.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
            it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
            it.turret_flags |= TUR_FLAG_HITSCAN;
        }

#endif // SVQC
#endif
