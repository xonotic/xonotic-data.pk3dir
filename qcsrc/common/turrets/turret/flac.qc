#ifndef TUR_FLAC_H
#define TUR_FLAC_H

CLASS(Flac, Turret)
/* spawnflags */ ATTRIB(Flac, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_FASTPROJ | TUR_FLAG_MISSILE);
/* mins       */ ATTRIB(Flac, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(Flac, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(Flac, mdl, string, "base.md3");
/* model      */ ATTRIB(Flac, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(Flac, head_model, string, strzone(strcat("models/turrets/", "flac.md3")));
/* netname    */ ATTRIB(Flac, netname, string, "flac");
/* fullname   */ ATTRIB(Flac, turret_name, string, _("FLAC Cannon"));
ENDCLASS(Flac)

REGISTER_TURRET(FLAC, NEW(Flac));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
void turret_flac_projectile_think_explode()
{SELFPARAM();
    if(self.enemy != world)
    if(vlen(self.origin - self.enemy.origin) < self.owner.shot_radius * 3)
        setorigin(self,self.enemy.origin + randomvec() * self.owner.shot_radius);

#ifdef TURRET_DEBUG
    float d;
    d = RadiusDamage (self, self.owner, self.owner.shot_dmg, self.owner.shot_dmg, self.owner.shot_radius, self, world, self.owner.shot_force, self.totalfrags, world);
    self.owner.tur_dbg_dmg_t_h = self.owner.tur_dbg_dmg_t_h + d;
    self.owner.tur_dbg_dmg_t_f = self.owner.tur_dbg_dmg_t_f + self.owner.shot_dmg;
#else
    RadiusDamage (self, self.realowner, self.owner.shot_dmg, self.owner.shot_dmg, self.owner.shot_radius, self, world, self.owner.shot_force, self.totalfrags, world);
#endif
    remove(self);
}

void spawnfunc_turret_flac() { SELFPARAM(); if(!turret_initialize(TUR_FLAC.m_id)) remove(self); }

        METHOD(Flac, tr_attack, void(Flac thistur))
        {
            entity proj;

            turret_tag_fire_update();

            proj = turret_projectile(SND(HAGAR_FIRE), 5, 0, DEATH_TURRET_FLAC, PROJECTILE_HAGAR, TRUE, TRUE);
            Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, self.tur_shotorg, self.tur_shotdir_updated * 1000, 1);
            proj.think	  = turret_flac_projectile_think_explode;
            proj.nextthink  = time + self.tur_impacttime + (random() * 0.01 - random() * 0.01);
            proj.missile_flags = MIF_SPLASH | MIF_PROXY;

            self.tur_head.frame = self.tur_head.frame + 1;
            if (self.tur_head.frame >= 4)
                self.tur_head.frame = 0;
        }
        METHOD(Flac, tr_think, bool(Flac thistur))
        {
            return true;
        }
        METHOD(Flac, tr_death, bool(Flac thistur))
        {
            return true;
        }
        METHOD(Flac, tr_setup, bool(Flac thistur))
        {
            self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;
            self.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE;
            self.damage_flags |= TFL_DMG_HEADSHAKE;
            self.target_select_flags |= TFL_TARGETSELECT_NOTURRETS | TFL_TARGETSELECT_MISSILESONLY;

            return true;
        }
        METHOD(Flac, tr_precache, bool(Flac thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(Flac, tr_setup, bool(Flac thistur))
        {
            return true;
        }
        METHOD(Flac, tr_precache, bool(Flac thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
