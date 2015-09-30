#ifndef TUR_HELLION_H
#define TUR_HELLION_H

CLASS(Hellion, Turret)
/* spawnflags */ ATTRIB(Hellion, spawnflags, int, TUR_FLAG_SPLASH | TUR_FLAG_FASTPROJ | TUR_FLAG_PLAYER | TUR_FLAG_MISSILE);
/* mins       */ ATTRIB(Hellion, mins, vector, '-32 -32 0');
/* maxs       */ ATTRIB(Hellion, maxs, vector, '32 32 64');
/* modelname  */ ATTRIB(Hellion, mdl, string, "base.md3");
/* model      */ ATTRIB(Hellion, model, string, strzone(strcat("models/turrets/", this.mdl)));
/* head_model */ ATTRIB(Hellion, head_model, string, strzone(strcat("models/turrets/", "hellion.md3")));
/* netname    */ ATTRIB(Hellion, netname, string, "hellion");
/* fullname   */ ATTRIB(Hellion, turret_name, string, _("Hellion Missile Turret"));
ENDCLASS(Hellion)

REGISTER_TURRET(HELLION, NEW(Hellion));

#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
float autocvar_g_turrets_unit_hellion_shot_speed_gain;
float autocvar_g_turrets_unit_hellion_shot_speed_max;

void turret_hellion_missile_think()
{SELFPARAM();
    vector olddir,newdir;
    vector pre_pos;
    float itime;

    self.nextthink = time + 0.05;

    olddir = normalize(self.velocity);

    if(self.max_health < time)
        turret_projectile_explode();

    // Enemy dead? just keep on the current heading then.
    if ((self.enemy == world) || (self.enemy.deadflag != DEAD_NO))
    {

        // Make sure we dont return to tracking a respawned player
        self.enemy = world;

        // Turn model
        self.angles = vectoangles(self.velocity);

        if ( (vlen(self.origin - self.owner.origin)) > (self.owner.shot_radius * 5) )
            turret_projectile_explode();

        // Accelerate
        self.velocity = olddir * min(vlen(self.velocity) * (autocvar_g_turrets_unit_hellion_shot_speed_gain), (autocvar_g_turrets_unit_hellion_shot_speed_max));

        UpdateCSQCProjectile(self);

        return;
    }

    // Enemy in range?
    if (vlen(self.origin - self.enemy.origin) < self.owner.shot_radius * 0.2)
        turret_projectile_explode();

    // Predict enemy position
    itime = vlen(self.enemy.origin - self.origin) / vlen(self.velocity);
    pre_pos = self.enemy.origin + self.enemy.velocity * itime;

    pre_pos = (pre_pos + self.enemy.origin) * 0.5;

    // Find out the direction to that place
    newdir = normalize(pre_pos - self.origin);

    // Turn
    newdir = normalize(olddir + newdir * 0.35);

    // Turn model
    self.angles = vectoangles(self.velocity);

    // Accelerate
    self.velocity = newdir * min(vlen(self.velocity) * (autocvar_g_turrets_unit_hellion_shot_speed_gain), (autocvar_g_turrets_unit_hellion_shot_speed_max));

    if (itime < 0.05)
        self.think = turret_projectile_explode;

    UpdateCSQCProjectile(self);
}

void spawnfunc_turret_hellion() { SELFPARAM(); if(!turret_initialize(TUR_HELLION.m_id)) remove(self); }

        METHOD(Hellion, tr_attack, void(Hellion thistur))
        {
            entity missile;

            if(self.tur_head.frame != 0)
                self.tur_shotorg = gettaginfo(self.tur_head, gettagindex(self.tur_head, "tag_fire"));
            else
                self.tur_shotorg = gettaginfo(self.tur_head, gettagindex(self.tur_head, "tag_fire2"));

            missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_HELLION, PROJECTILE_ROCKET, FALSE, FALSE);
            te_explosion (missile.origin);
            missile.think		= turret_hellion_missile_think;
            missile.nextthink	= time;
            missile.flags		= FL_PROJECTILE;
            missile.max_health   = time + 9;
            missile.tur_aimpos   = randomvec() * 128;
            missile.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_GUIDED_HEAT;
            self.tur_head.frame += 1;
        }
        METHOD(Hellion, tr_think, bool(Hellion thistur))
        {
            if (self.tur_head.frame != 0)
                self.tur_head.frame += 1;

            if (self.tur_head.frame >= 7)
                self.tur_head.frame = 0;

            return true;
        }
        METHOD(Hellion, tr_death, bool(Hellion thistur))
        {
            return true;
        }
        METHOD(Hellion, tr_setup, bool(Hellion thistur))
        {
            self.aim_flags = TFL_AIM_SIMPLE;
            self.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK ;
            self.firecheck_flags = TFL_FIRECHECK_DEAD | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_TEAMCHECK | TFL_FIRECHECK_REFIRE | TFL_FIRECHECK_AFF | TFL_FIRECHECK_AMMO_OWN;
            self.ammo_flags = TFL_AMMO_ROCKETS | TFL_AMMO_RECHARGE;

            return true;
        }
        METHOD(Hellion, tr_precache, bool(Hellion thistur))
        {
            return true;
        }

#endif // SVQC
#ifdef CSQC
        METHOD(Hellion, tr_setup, bool(Hellion thistur))
        {
            return true;
        }
        METHOD(Hellion, tr_precache, bool(Hellion thistur))
        {
            return true;
        }

#endif // CSQC
#endif // REGISTER_TURRET
