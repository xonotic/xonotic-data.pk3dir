#include "hk_weapon.qh"

#ifdef SVQC

float autocvar_g_turrets_unit_hk_shot_speed;
float autocvar_g_turrets_unit_hk_shot_speed_accel;
float autocvar_g_turrets_unit_hk_shot_speed_accel2;
float autocvar_g_turrets_unit_hk_shot_speed_decel;
float autocvar_g_turrets_unit_hk_shot_speed_max;
float autocvar_g_turrets_unit_hk_shot_speed_turnrate;

void turret_hk_missile_think(entity this);
SOUND(HunterKillerAttack_FIRE, W_Sound("rocket_fire"));
METHOD(HunterKillerAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	bool isPlayer = IS_PLAYER(actor);
	if (fire & 1)
	if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1)) {
		if (isPlayer) {
            turret_initparams(actor);
            W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_HunterKillerAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_HK.m_id);
            actor.tur_shotdir_updated = w_shotdir;
            actor.tur_shotorg = w_shotorg;
            actor.tur_head = actor;
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
        }
        entity missile = turret_projectile(actor, SND_HunterKillerAttack_FIRE, 6, 10, DEATH_TURRET_HK.m_id, PROJECTILE_ROCKET, false, false);
        te_explosion (missile.origin);

        setthink(missile, turret_hk_missile_think);
        missile.nextthink = time + 0.25;
        set_movetype(missile, MOVETYPE_BOUNCEMISSILE);
        missile.velocity = actor.tur_shotdir_updated * (actor.shot_speed * 0.75);
        missile.angles = vectoangles(missile.velocity);
        missile.cnt = time + 30;
        missile.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_GUIDED_AI;

        if (!isPlayer)
        if (actor.tur_head.frame == 0)
            actor.tur_head.frame = actor.tur_head.frame + 1;
	}
}

bool hk_is_valid_target(entity this, entity proj, entity targ);
void turret_hk_missile_think(entity this)
{
    vector vu, vd, vf, vl, vr, ve;  // Vector (direction)
    float  fu, fd, ff, fl, fr, fe;  // Fraction to solid
    vector olddir,wishdir,newdir;   // Final direction
    float lt_for;   // Length of Trace FORwrad
    float lt_seek;  // Length of Trace SEEK (left, right, up down)
    float pt_seek;  // Pitch of Trace SEEK (How mutch to angele left, right up, down trace towards v_forward)
    float myspeed;

    this.nextthink = time;

    //if (this.cnt < time)
    //	turret_hk_missile_explode();

    if (IS_DEAD(this.enemy) || IS_SPEC(this.enemy) || IS_OBSERVER(this.enemy))
        this.enemy = NULL;

    // Pick the closest valid target.
    if (!this.enemy)
    {
        // in this case, the lighter check is to validate it first, and check distance if it is valid
        IL_EACH(g_damagedbycontents, hk_is_valid_target(this.owner, this, it),
        {
            if(vdist(it.origin, >, 5000))
                continue;

            if(!this.enemy)
                this.enemy = it;
            else if(vlen2(this.origin - it.origin) < vlen2(this.origin - this.enemy.origin))
                this.enemy = it;
        });
    }

    this.angles = vectoangles(this.velocity);
    this.angles_x = this.angles_x * -1;
    makevectors(this.angles);
    this.angles_x = this.angles_x * -1;

    if (this.enemy)
    {
        // Close enougth to do decent damage?
        if(vdist(this.origin - this.enemy.origin, <=, (this.owner.shot_radius * 0.25)))
        {
            turret_projectile_explode(this);
            return;
        }

        // Get data on enemy position
        vector pre_pos = this.enemy.origin +
                  this.enemy.velocity *
                  min((vlen(this.enemy.origin - this.origin) / vlen(this.velocity)),0.5);

        traceline(this.origin, pre_pos,true,this.enemy);
        ve = normalize(pre_pos - this.origin);
        fe = trace_fraction;

    }
    else
    {
        ve = '0 0 0';
        fe = 0;
    }

    if ((fe != 1) || (this.enemy == NULL) || vdist(this.origin - this.enemy.origin, >, 1000))
    {
        myspeed = vlen(this.velocity);

        lt_for  = myspeed * 3;
        lt_seek = myspeed * 2.95;

        // Trace forward
        traceline(this.origin, this.origin + v_forward * lt_for,false,this);
        vf = trace_endpos;
        ff = trace_fraction;

        // Find angular offset
        float ad = vlen(vectoangles(normalize(this.enemy.origin - this.origin)) - this.angles);

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
        traceline(this.origin, this.origin + (-1 * (v_right * pt_seek) + (v_forward * ff)) * lt_seek,false,this);
        vl = trace_endpos;
        fl = trace_fraction;

        // Trace right
        traceline(this.origin,  this.origin + ((v_right * pt_seek) + (v_forward * ff)) * lt_seek ,false,this);
        vr = trace_endpos;
        fr = trace_fraction;

        // Trace up
        traceline(this.origin,  this.origin + ((v_up * pt_seek) + (v_forward * ff)) * lt_seek ,false,this);
        vu = trace_endpos;
        fu = trace_fraction;

        // Trace down
        traceline(this.origin,  this.origin + (-1 * (v_up * pt_seek) + (v_forward * ff)) * lt_seek ,false,this);
        vd = trace_endpos;
        fd = trace_fraction;

        vl = normalize(vl - this.origin);
        vr = normalize(vr - this.origin);
        vu = normalize(vu - this.origin);
        vd = normalize(vd - this.origin);

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

        if (this.enemy)
        {
            if (fe < 0.1) fe = 0.1; // Make sure we always try to move sligtly towards our target
            wishdir = (wishdir * (1 - fe)) + (ve * fe);
        }
    }
    else
    {
        // Got a clear path to target, speed up fast (if not at full speed) and go straight for it.
        myspeed = vlen(this.velocity);
        if (myspeed < (autocvar_g_turrets_unit_hk_shot_speed_max))
            myspeed = min(myspeed * (autocvar_g_turrets_unit_hk_shot_speed_accel2),(autocvar_g_turrets_unit_hk_shot_speed_max));

        wishdir = ve;
    }

    if ((myspeed > (autocvar_g_turrets_unit_hk_shot_speed)) && (this.cnt > time))
        myspeed = min(myspeed * (autocvar_g_turrets_unit_hk_shot_speed_accel2),(autocvar_g_turrets_unit_hk_shot_speed_max));

    // Ranoutagazfish?
    if (this.cnt < time)
    {
        this.cnt = time + 0.25;
        this.nextthink = 0;
        set_movetype(this, MOVETYPE_BOUNCE);
        return;
    }

    // Calculate new heading
    olddir = normalize(this.velocity);
    newdir = normalize(olddir + wishdir * (autocvar_g_turrets_unit_hk_shot_speed_turnrate));

    // Set heading & speed
    this.velocity = newdir * myspeed;

    // Align model with new heading
    this.angles = vectoangles(this.velocity);


#ifdef TURRET_DEBUG_HK
    //if(this.atime < time) {
    if ((fe <= 0.99)||vdist(this.origin - this.enemy.origin, >, 1000))
    {
        te_lightning2(NULL,this.origin, this.origin + vr * lt_seek);
        te_lightning2(NULL,this.origin, this.origin + vl * lt_seek);
        te_lightning2(NULL,this.origin, this.origin + vu * lt_seek);
        te_lightning2(NULL,this.origin, this.origin + vd * lt_seek);
        te_lightning2(NULL,this.origin, vf);
    }
    else
    {
        te_lightning2(NULL,this.origin, this.enemy.origin);
    }
    bprint("Speed: ", ftos(rint(myspeed)), "\n");
    bprint("Trace to solid: ", ftos(rint(ff * 100)), "%\n");
    bprint("Trace to target:", ftos(rint(fe * 100)), "%\n");
    this.atime = time + 0.2;
    //}
#endif

    UpdateCSQCProjectile(this);
}

bool hk_is_valid_target(entity this, entity proj, entity targ)
{
    if (!targ)
        return false;

    // we know for sure pure entities are bad targets
    if(is_pure(targ))
        return false;

    // If only this was used more..
    if (targ.flags & FL_NOTARGET)
        return false;

    // Cant touch this
    if ((targ.takedamage == DAMAGE_NO) || (GetResource(targ, RES_HEALTH) < 0))
        return false;

    // player
    if (IS_PLAYER(targ))
    {
        if (this.target_select_playerbias < 0)
            return false;

        if (IS_DEAD(targ))
            return false;
    }

    // Missile
    if ((targ.flags & FL_PROJECTILE) && (this.target_select_missilebias < 0))
        return false;

    // Team check
    if ((targ.team == this.team) || (this.team == targ.owner.team))
        return false;

    return true;
}

#endif
