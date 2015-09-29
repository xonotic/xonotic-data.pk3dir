#ifndef TUR_PLASMA_DUAL_H
#define TUR_PLASMA_DUAL_H

CLASS(DualPlasmaTurret, Turret)
/* spawnflags */ ATTRIB(DualPlasmaTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(DualPlasmaTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(DualPlasmaTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(DualPlasmaTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(DualPlasmaTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(DualPlasmaTurret, head_model, string, strzone(strcat("models/turrets/", "plasmad.md3")));
/* netname    */ ATTRIB(DualPlasmaTurret, netname, string, "plasma_dual");
/* fullname   */ ATTRIB(DualPlasmaTurret, turret_name, string, _("Dual Plasma Cannon"));
ENDCLASS(DualPlasmaTurret)

REGISTER_TURRET(PLASMA_DUAL, NEW(DualPlasmaTurret));

#endif

#ifdef IMPLEMENTATION

#include "../../weapons/all.qh"

CLASS(PlasmaDualAttack, PortoLaunch)
/* flags     */ ATTRIB(PlasmaDualAttack, spawnflags, int, WEP_TYPE_OTHER);
/* impulse   */ ATTRIB(PlasmaDualAttack, impulse, int, 5);
/* refname   */ ATTRIB(PlasmaDualAttack, netname, string, "plasmadual");
/* wepname   */ ATTRIB(PlasmaDualAttack, message, string, _("Dual plasma"));
ENDCLASS(PlasmaDualAttack)
REGISTER_WEAPON(PLASMA_DUAL, NEW(PlasmaDualAttack));

#ifdef SVQC

METHOD(PlasmaDualAttack, wr_think, bool(entity thiswep, bool fire1, bool fire2)) {
	SELFPARAM();
	if (fire1)
	if (weapon_prepareattack(false, WEP_CVAR_PRI(electro, refire))) {
		W_SetupShot_Dir(self, v_forward, false, 0, W_Sound("electro_fire"), CH_WEAPON_B, 0);
		self.tur_shotdir_updated = w_shotdir;
		self.tur_shotorg = w_shotorg;
		self.tur_head = self;
        self.shot_speed = max(1, ((!self.shot_speed) ? 2500 : self.shot_speed));
        self.shot_spread = bound(0.0001, ((!self.shot_spread) ? 0.0125 : self.shot_spread), 500);
        TUR_ACTION(TUR_PLASMA_DUAL.m_id, TR_ATTACK);
		weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
	}
	return true;
}

void spawnfunc_turret_plasma_dual() { SELFPARAM(); if(!turret_initialize(TUR_PLASMA_DUAL.m_id)) remove(self); }

        METHOD(DualPlasmaTurret, tr_attack, bool(DualPlasmaTurret thistur))
        {
            if(g_instagib)
            {
                float flying;
                flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

                FireRailgunBullet (self.tur_shotorg, self.tur_shotorg + self.tur_shotdir_updated * MAX_SHOT_DISTANCE, 10000000000,
                                   800, 0, 0, 0, 0, DEATH_TURRET_PLASMA);


                Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);

                // teamcolor / hit beam effect
                vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
                WarpZone_TrailParticles(world, particleeffectnum(EFFECT_VAPORIZER(self.team)), self.tur_shotorg, v);
                self.tur_head.frame += 1;
            }
            else
            {
                entity missile = turret_projectile(SND(HAGAR_FIRE), 1, 0, DEATH_TURRET_PLASMA, PROJECTILE_ELECTRO_BEAM, TRUE, TRUE);
                missile.missile_flags = MIF_SPLASH;
                Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);
                self.tur_head.frame += 1;
            }

            return true;
        }
        METHOD(DualPlasmaTurret, tr_think, bool(DualPlasmaTurret thistur))
        {
            if ((self.tur_head.frame != 0) && (self.tur_head.frame != 3))
                self.tur_head.frame = self.tur_head.frame + 1;

            if (self.tur_head.frame > 6)
                self.tur_head.frame = 0;

            return true;
        }
        METHOD(DualPlasmaTurret, tr_death, bool(DualPlasmaTurret thistur))
        {
            return true;
        }
        METHOD(DualPlasmaTurret, tr_setup, bool(DualPlasmaTurret thistur))
        {
            self.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE | TFL_AMMO_RECIEVE;
            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.firecheck_flags |= TFL_FIRECHECK_AFF;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE | TFL_AIM_SPLASH;

            turret_do_updates(self);

            return true;
        }
        METHOD(DualPlasmaTurret, tr_precache, bool(DualPlasmaTurret thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(DualPlasmaTurret, tr_setup, bool(DualPlasmaTurret thistur))
        {
            return true;
        }
        METHOD(DualPlasmaTurret, tr_precache, bool(DualPlasmaTurret thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
