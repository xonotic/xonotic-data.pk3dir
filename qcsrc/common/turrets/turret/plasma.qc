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
#ifdef SVQC
void spawnfunc_turret_plasma() { SELFPARAM(); if(!turret_initialize(TUR_PLASMA.m_id)) remove(self); }

        METHOD(PlasmaTurret, tr_attack, bool(PlasmaTurret thistur))
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
                if (self.tur_head.frame == 0)
                    self.tur_head.frame = 1;
            }
            else
            {
                entity missile = turret_projectile(SND(HAGAR_FIRE), 1, 0, DEATH_TURRET_PLASMA, PROJECTILE_ELECTRO_BEAM, TRUE, TRUE);
                missile.missile_flags = MIF_SPLASH;

                Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);
                if (self.tur_head.frame == 0)
                    self.tur_head.frame = 1;
            }

            return true;
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
