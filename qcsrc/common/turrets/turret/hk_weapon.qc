#ifndef TURRET_HK_WEAPON_H
#define TURRET_HK_WEAPON_H

CLASS(HunterKillerAttack, PortoLaunch)
/* flags     */ ATTRIB(HunterKillerAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(HunterKillerAttack, impulse, int, 9);
/* refname   */ ATTRIB(HunterKillerAttack, netname, string, "turret_hk");
/* wepname   */ ATTRIB(HunterKillerAttack, m_name, string, _("Hunter-Killer"));
ENDCLASS(HunterKillerAttack)
REGISTER_WEAPON(HK, NEW(HunterKillerAttack));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

float autocvar_g_turrets_unit_hk_shot_speed;
float autocvar_g_turrets_unit_hk_shot_speed_accel;
float autocvar_g_turrets_unit_hk_shot_speed_accel2;
float autocvar_g_turrets_unit_hk_shot_speed_decel;
float autocvar_g_turrets_unit_hk_shot_speed_max;
float autocvar_g_turrets_unit_hk_shot_speed_turnrate;

void turret_hk_missile_think();
SOUND(HunterKillerAttack_FIRE, W_Sound("electro_fire"));
METHOD(HunterKillerAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	bool isPlayer = IS_PLAYER(actor);
	if (fire & 1)
	if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(electro, refire))) {
		if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, v_forward, false, 0, SND(HunterKillerAttack_FIRE), CH_WEAPON_B, 0);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(electro, animtime), w_ready);
        }
        entity missile = turret_projectile(SND(ROCKET_FIRE), 6, 10, DEATH_TURRET_HK.m_id, PROJECTILE_ROCKET, FALSE, FALSE);
        te_explosion (missile.origin);

        missile.think = turret_hk_missile_think;
        missile.nextthink = time + 0.25;
        missile.movetype = MOVETYPE_BOUNCEMISSILE;
        missile.velocity = actor.tur_shotdir_updated * (actor.shot_speed * 0.75);
        missile.angles = vectoangles(missile.velocity);
        missile.cnt = time + 30;
        missile.ticrate = max(autocvar_sys_ticrate, 0.05);
        missile.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_GUIDED_AI;

        if (!isPlayer)
        if (actor.tur_head.frame == 0)
            actor.tur_head.frame = actor.tur_head.frame + 1;
	}
}

bool hk_is_valid_target(entity e_target);
void turret_hk_missile_think()
{SELFPARAM();
    vector vu, vd, vf, vl, vr, ve;  // Vector (direction)
    float  fu, fd, ff, fl, fr, fe;  // Fraction to solid
    vector olddir,wishdir,newdir;   // Final direction
    float lt_for;   // Length of Trace FORwrad
    float lt_seek;  // Length of Trace SEEK (left, right, up down)
    float pt_seek;  // Pitch of Trace SEEK (How mutch to angele left, right up, down trace towards v_forward)
    vector pre_pos;
    float myspeed;
    entity e;
    float ad,edist;

    self.nextthink = time + self.ticrate;

    //if (self.cnt < time)
    //	turret_hk_missile_explode();

    if (self.enemy.deadflag != DEAD_NO)
        self.enemy = world;

    // Pick the closest valid target.
    if (!self.enemy)
    {
        e = findradius(self.origin, 5000);
        while (e)
        {
            if (hk_is_valid_target(e))
            {
                if (!self.enemy)
                    self.enemy = e;
                else
                    if (vlen(self.origin - e.origin) < vlen(self.origin - self.enemy.origin))
                        self.enemy = e;
            }
            e = e.chain;
        }
    }

    self.angles = vectoangles(self.velocity);
    self.angles_x = self.angles_x * -1;
    makevectors(self.angles);
    self.angles_x = self.angles_x * -1;

    if (self.enemy)
    {
        edist = vlen(self.origin - self.enemy.origin);
        // Close enougth to do decent damage?
        if ( edist <= (self.owner.shot_radius * 0.25) )
        {
            turret_projectile_explode();
            return;
        }

        // Get data on enemy position
        pre_pos = self.enemy.origin +
                  self.enemy.velocity *
                  min((vlen(self.enemy.origin - self.origin) / vlen(self.velocity)),0.5);

        traceline(self.origin, pre_pos,true,self.enemy);
        ve = normalize(pre_pos - self.origin);
        fe = trace_fraction;

    }
    else
    {
    edist = 0;
    ve = '0 0 0';
        fe = 0;
    }

    if ((fe != 1) || (self.enemy == world) || (edist > 1000))
    {
        myspeed = vlen(self.velocity);

        lt_for  = myspeed * 3;
        lt_seek = myspeed * 2.95;

        // Trace forward
        traceline(self.origin, self.origin + v_forward * lt_for,false,self);
        vf = trace_endpos;
        ff = trace_fraction;

        // Find angular offset
        ad = vlen(vectoangles(normalize(self.enemy.origin - self.origin)) - self.angles);

        // To close to something, Slow down!
        if ( ((ff < 0.7) || (ad > 4)) && (myspeed > (autocvar_g_turrets_unit_hk_shot_speed)) )
            myspeed = max(myspeed * (autocvar_g_turrets_unit_hk_shot_speed_decel), (autocvar_g_turrets_unit_hk_shot_speed));

        // Failry clear, accelerate.
        if ( (ff > 0.7) && (myspeed < (autocvar_g_turrets_unit_hk_shot_speed_max)) )
            myspeed = min(myspeed * (autocvar_g_turrets_unit_hk_shot_speed_accel), (autocvar_g_turrets_unit_hk_shot_speed_max));

        // Setup trace pitch
        pt_seek = 1 - ff;
        pt_seek = bound(0.15,pt_seek,0.8);
        if (ff < 0.5) pt_seek = 1;

        // Trace left
        traceline(self.origin, self.origin + (-1 * (v_right * pt_seek) + (v_forward * ff)) * lt_seek,false,self);
        vl = trace_endpos;
        fl = trace_fraction;

        // Trace right
        traceline(self.origin,  self.origin + ((v_right * pt_seek) + (v_forward * ff)) * lt_seek ,false,self);
        vr = trace_endpos;
        fr = trace_fraction;

        // Trace up
        traceline(self.origin,  self.origin + ((v_up * pt_seek) + (v_forward * ff)) * lt_seek ,false,self);
        vu = trace_endpos;
        fu = trace_fraction;

        // Trace down
        traceline(self.origin,  self.origin + (-1 * (v_up * pt_seek) + (v_forward * ff)) * lt_seek ,false,self);
        vd = trace_endpos;
        fd = trace_fraction;

        vl = normalize(vl - self.origin);
        vr = normalize(vr - self.origin);
        vu = normalize(vu - self.origin);
        vd = normalize(vd - self.origin);

        // Panic tresh passed, find a single direction and turn as hard as we can
        if (pt_seek == 1)
        {
            wishdir = v_right;
            if (fl > fr) wishdir = -1 * v_right;
            if (fu > fl) wishdir = v_up;
            if (fd > fu) wishdir = -1 * v_up;
        }
        else
        {
            // Normalize our trace vectors to make a smooth path
            wishdir = normalize( (vl * fl) + (vr * fr) +  (vu * fu) +  (vd * fd) );
        }

        if (self.enemy)
        {
            if (fe < 0.1) fe = 0.1; // Make sure we always try to move sligtly towards our target
            wishdir = (wishdir * (1 - fe)) + (ve * fe);
        }
    }
    else
    {
        // Got a clear path to target, speed up fast (if not at full speed) and go straight for it.
        myspeed = vlen(self.velocity);
        if (myspeed < (autocvar_g_turrets_unit_hk_shot_speed_max))
            myspeed = min(myspeed * (autocvar_g_turrets_unit_hk_shot_speed_accel2),(autocvar_g_turrets_unit_hk_shot_speed_max));

        wishdir = ve;
    }

    if ((myspeed > (autocvar_g_turrets_unit_hk_shot_speed)) && (self.cnt > time))
        myspeed = min(myspeed * (autocvar_g_turrets_unit_hk_shot_speed_accel2),(autocvar_g_turrets_unit_hk_shot_speed_max));

    // Ranoutagazfish?
    if (self.cnt < time)
    {
        self.cnt = time + 0.25;
        self.nextthink = 0;
        self.movetype		 = MOVETYPE_BOUNCE;
        return;
    }

    // Calculate new heading
    olddir = normalize(self.velocity);
    newdir = normalize(olddir + wishdir * (autocvar_g_turrets_unit_hk_shot_speed_turnrate));

    // Set heading & speed
    self.velocity = newdir * myspeed;

    // Align model with new heading
    self.angles = vectoangles(self.velocity);


#ifdef TURRET_DEBUG_HK
    //if(self.atime < time) {
    if ((fe <= 0.99)||(edist > 1000))
    {
        te_lightning2(world,self.origin, self.origin + vr * lt_seek);
        te_lightning2(world,self.origin, self.origin + vl * lt_seek);
        te_lightning2(world,self.origin, self.origin + vu * lt_seek);
        te_lightning2(world,self.origin, self.origin + vd * lt_seek);
        te_lightning2(world,self.origin, vf);
    }
    else
    {
        te_lightning2(world,self.origin, self.enemy.origin);
    }
    bprint("Speed: ", ftos(rint(myspeed)), "\n");
    bprint("Trace to solid: ", ftos(rint(ff * 100)), "%\n");
    bprint("Trace to target:", ftos(rint(fe * 100)), "%\n");
    self.atime = time + 0.2;
    //}
#endif

    UpdateCSQCProjectile(self);
}

bool hk_is_valid_target(entity e_target)
{SELFPARAM();
    if (e_target == world)
        return 0;

    // If only this was used more..
    if (e_target.flags & FL_NOTARGET)
        return 0;

    // Cant touch this
    if ((e_target.takedamage == DAMAGE_NO) || (e_target.health < 0))
        return 0;

    // player
    if (IS_CLIENT(e_target))
    {
        if (self.owner.target_select_playerbias < 0)
            return 0;

        if (e_target.deadflag != DEAD_NO)
            return 0;
    }

    // Missile
    if ((e_target.flags & FL_PROJECTILE) && (self.owner.target_select_missilebias < 0))
        return 0;

    // Team check
    if ((e_target.team == self.owner.team) || (self.owner.team == e_target.owner.team))
        return 0;

    return 1;
}

#endif

#endif
