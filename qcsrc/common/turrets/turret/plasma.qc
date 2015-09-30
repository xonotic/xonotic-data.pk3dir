#ifndef TUR_PLASMA_H
#define TUR_PLASMA_H

CLASS(PlasmaTurret, Turret)
/* spawnflags */ ATTRIB(PlasmaTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(PlasmaTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(PlasmaTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(PlasmaTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(PlasmaTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(PlasmaTurret, head_model, string, strzone(strcat("models/turrets/", "plasma.md3")));
/* netname    */ ATTRIB(PlasmaTurret, netname, string, "plasma");
/* fullname   */ ATTRIB(PlasmaTurret, turret_name, string, _("Plasma Cannon"));
ENDCLASS(PlasmaTurret)

REGISTER_TURRET(PLASMA, NEW(PlasmaTurret));

#endif

#ifdef IMPLEMENTATION

CLASS(PlasmaAttack, PortoLaunch)
/* flags     */ ATTRIB(PlasmaAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(PlasmaAttack, impulse, int, 5);
/* refname   */ ATTRIB(PlasmaAttack, netname, string, "plasma");
/* wepname   */ ATTRIB(PlasmaAttack, message, string, _("Plasma"));
ENDCLASS(PlasmaAttack)
REGISTER_WEAPON(PLASMA, NEW(PlasmaAttack));

#ifdef SVQC

void turret_initparams(entity tur);
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

void spawnfunc_turret_plasma() { SELFPARAM(); if(!turret_initialize(TUR_PLASMA.m_id)) remove(self); }

        METHOD(PlasmaTurret, tr_attack, void(PlasmaTurret thistur))
        {
            if(g_instagib)
            {
                FireRailgunBullet (self.tur_shotorg, self.tur_shotorg + self.tur_shotdir_updated * MAX_SHOT_DISTANCE, 10000000000,
                                   800, 0, 0, 0, 0, DEATH_TURRET_PLASMA);

                Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

                // teamcolor / hit beam effect
                vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
                WarpZone_TrailParticles(world, particleeffectnum(EFFECT_VAPORIZER(self.team)), self.tur_shotorg, v);
            }
            else
            {
                Weapon wep = WEP_PLASMA;
                wep.wr_think(wep, true, false);
            }
            if (self.tur_head.frame == 0)
                self.tur_head.frame = 1;
        }
        METHOD(PlasmaTurret, tr_think, bool(PlasmaTurret thistur))
        {
            if (self.tur_head.frame != 0)
                self.tur_head.frame = self.tur_head.frame + 1;

            if (self.tur_head.frame > 5)
                self.tur_head.frame = 0;

            return true;
        }
        METHOD(PlasmaTurret, tr_death, bool(PlasmaTurret thistur))
        {
            return true;
        }
        METHOD(PlasmaTurret, tr_setup, bool(PlasmaTurret thistur))
        {
            self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.firecheck_flags |= TFL_FIRECHECK_AFF;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE | TFL_AIM_SPLASH;

            turret_do_updates(self);

            return true;
        }
        METHOD(PlasmaTurret, tr_precache, bool(PlasmaTurret thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(PlasmaTurret, tr_setup, bool(PlasmaTurret thistur))
        {
            return true;
        }
        METHOD(PlasmaTurret, tr_precache, bool(PlasmaTurret thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
