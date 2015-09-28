#ifndef TUR_MLRS_H
#define TUR_MLRS_H

CLASS(MLRSTurret, Turret)
/* spawnflags */ ATTRIB(MLRSTurret, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER);
/* mins       */ ATTRIB(MLRSTurret, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(MLRSTurret, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(MLRSTurret, mdl, string, "base.md3");
/* model      */ ATTRIB(MLRSTurret, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(MLRSTurret, head_model, string, strzone(strcat("models/turrets/", "mlrs.md3")));
/* netname    */ ATTRIB(MLRSTurret, netname, string, "mlrs");
/* fullname   */ ATTRIB(MLRSTurret, turret_name, string, _("MLRS Turret"));
ENDCLASS(MLRSTurret)

REGISTER_TURRET(MLRS, NEW(MLRSTurret));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
void spawnfunc_turret_mlrs() { SELFPARAM(); if(!turret_initialize(TUR_MLRS.m_id)) remove(self); }

        METHOD(MLRSTurret, tr_attack, bool(MLRSTurret thistur))
        {
            entity missile;

            turret_tag_fire_update();
            missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_MLRS, PROJECTILE_ROCKET, TRUE, TRUE);
            missile.nextthink = time + max(self.tur_impacttime,(self.shot_radius * 2) / self.shot_speed);
            missile.missile_flags = MIF_SPLASH;
            te_explosion (missile.origin);

            return true;
        }
        METHOD(MLRSTurret, tr_think, bool(MLRSTurret thistur))
        {
            // 0 = full, 6 = empty
            self.tur_head.frame = bound(0, 6 - floor(0.1 + self.ammo / self.shot_dmg), 6);
            if(self.tur_head.frame < 0)
            {
                LOG_TRACE("ammo:",ftos(self.ammo),"\n");
                LOG_TRACE("shot_dmg:",ftos(self.shot_dmg),"\n");
            }

            return true;
        }
        METHOD(MLRSTurret, tr_death, bool(MLRSTurret thistur))
        {
            return true;
        }
        METHOD(MLRSTurret, tr_setup, bool(MLRSTurret thistur))
        {
            self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;

            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.shoot_flags  |= TFL_SHOOT_VOLLYALWAYS;
            self.volly_counter = self.shot_volly;

            return true;
        }
        METHOD(MLRSTurret, tr_precache, bool(MLRSTurret thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(MLRSTurret, tr_setup, bool(MLRSTurret thistur))
        {
            return true;
        }
        METHOD(MLRSTurret, tr_precache, bool(MLRSTurret thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
