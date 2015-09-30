#ifndef TUR_MLRS_H
#define TUR_MLRS_H

CLASS(MLRSTurretAttack, PortoLaunch)
/* flags     */ ATTRIB(MLRSTurretAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(MLRSTurretAttack, impulse, int, 9);
/* refname   */ ATTRIB(MLRSTurretAttack, netname, string, "turret_mlrs");
/* wepname   */ ATTRIB(MLRSTurretAttack, message, string, _("MLRS"));
ENDCLASS(MLRSTurretAttack)
REGISTER_WEAPON(TUR_MLRS, NEW(MLRSTurretAttack));

CLASS(MLRSTurret, Turret)
/* spawnflags */ ATTRIB(MLRSTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(MLRSTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(MLRSTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(MLRSTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(MLRSTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(MLRSTurret, head_model, string, strzone(strcat("models/turrets/", "mlrs.md3")));
/* netname    */ ATTRIB(MLRSTurret, netname, string, "mlrs");
/* fullname   */ ATTRIB(MLRSTurret, turret_name, string, _("MLRS Turret"));
    ATTRIB(MLRSTurret, m_weapon, Weapon, WEP_TUR_MLRS);
ENDCLASS(MLRSTurret)
REGISTER_TURRET(MLRS, NEW(MLRSTurret));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
METHOD(MLRSTurretAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2)) {
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
            self.shot_radius = 500;
            weapon_thinkf(WFRAME_FIRE1, 0, w_ready);
        }
        turret_tag_fire_update();
        entity missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_MLRS, PROJECTILE_ROCKET, TRUE, TRUE);
        missile.nextthink = time + max(self.tur_impacttime,(self.shot_radius * 2) / self.shot_speed);
        missile.missile_flags = MIF_SPLASH;
        te_explosion (missile.origin);
	}
	return true;
}

void spawnfunc_turret_mlrs() { SELFPARAM(); if(!turret_initialize(TUR_MLRS)) remove(self); }

        METHOD(MLRSTurret, tr_think, void(MLRSTurret thistur))
        {
            // 0 = full, 6 = empty
            self.tur_head.frame = bound(0, 6 - floor(0.1 + self.ammo / self.shot_dmg), 6);
            if(self.tur_head.frame < 0)
            {
                LOG_TRACE("ammo:",ftos(self.ammo),"\n");
                LOG_TRACE("shot_dmg:",ftos(self.shot_dmg),"\n");
            }
        }
        METHOD(MLRSTurret, tr_setup, void(MLRSTurret this, entity it))
        {
            it.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
            it.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;

            it.damage_flags |= TFL_DMG_HEADSHAKE;
            it.shoot_flags  |= TFL_SHOOT_VOLLYALWAYS;
            it.volly_counter = it.shot_volly;
        }

#endif // SVQC
#endif
