#ifndef TURRET_HELLION_WEAPON_H
#define TURRET_HELLION_WEAPON_H

CLASS(HellionAttack, PortoLaunch)
/* flags     */ ATTRIB(HellionAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(HellionAttack, impulse, int, 9);
/* refname   */ ATTRIB(HellionAttack, netname, string, "turret_hellion");
/* wepname   */ ATTRIB(HellionAttack, m_name, string, _("Hellion"));
ENDCLASS(HellionAttack)
REGISTER_WEAPON(HELLION, NEW(HellionAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

float autocvar_g_turrets_unit_hellion_shot_speed_gain;
float autocvar_g_turrets_unit_hellion_shot_speed_max;

void turret_hellion_missile_think();
SOUND(HellionAttack_FIRE, W_Sound("electro_fire"));
METHOD(HellionAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire)) {
    bool isPlayer = IS_PLAYER(actor);
    if (fire & 1)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
        if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, SND(HellionAttack_FIRE), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            actor.shot_radius = 500;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        if (!isPlayer) {
            if (actor.tur_head.frame != 0)
                actor.tur_shotorg = gettaginfo(actor.tur_head, gettagindex(actor.tur_head, "tag_fire"));
            else
                actor.tur_shotorg = gettaginfo(actor.tur_head, gettagindex(actor.tur_head, "tag_fire2"));
        }

        entity missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_HELLION.m_id, PROJECTILE_ROCKET, FALSE, FALSE);
        te_explosion (missile.origin);
        missile.think		= turret_hellion_missile_think;
        missile.nextthink	= time;
        missile.flags		= FL_PROJECTILE;
        missile.max_health   = time + 9;
        missile.tur_aimpos   = randomvec() * 128;
        missile.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_GUIDED_HEAT;
        if (!isPlayer) actor.tur_head.frame += 1;
    }
}

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

#endif

#endif
