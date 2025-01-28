#include "spiderbot_weapons.qh"

#ifdef SVQC

void spiderbot_rocket_artillery(entity this)
{
    this.nextthink = time;
    UpdateCSQCProjectile(this);
}

void spiderbot_rocket_unguided(entity this)
{
    vector newdir, olddir;

    this.nextthink  = time;

    olddir = normalize(this.velocity);
    newdir = normalize(this.pos1 - this.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    this.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(this);

    if (IS_DEAD(this.owner) || this.cnt < time || vdist(this.pos1 - this.origin, <, 16))
        this.use(this, NULL, NULL);
}

void spiderbot_rocket_guided(entity this)
{
    vector newdir, olddir;

    this.nextthink  = time;

    if(!this.realowner.vehicle)
        setthink(this, spiderbot_rocket_unguided);

    crosshair_trace(this.realowner);
    olddir = normalize(this.velocity);
    newdir = normalize(trace_endpos - this.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    this.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(this);

    if (IS_DEAD(this.owner) || this.cnt < time)
        this.use(this, NULL, NULL);
}

void spiderbot_guide_release(entity this)
{
    bool donetrace = false;
    IL_EACH(g_projectiles, it.realowner == this.owner && getthink(it) == spiderbot_rocket_guided,
    {
        if(!donetrace) // something exists, let's trace!
        {
            donetrace = true;
            crosshair_trace(this.owner);
        }

        it.pos1 = trace_endpos;
        setthink(it, spiderbot_rocket_unguided);
    });
}

float spiberbot_calcartillery_flighttime;
vector spiberbot_calcartillery(vector org, vector tgt, float ht)
{
    float grav, sdist, zdist, vs, vz, jumpheight;
    vector sdir;

    grav  = autocvar_sv_gravity;
    zdist = tgt_z - org_z;
    sdist = vlen(tgt - org - zdist * '0 0 1');
    sdir  = normalize(tgt - org - zdist * '0 0 1');

    // how high do we need to go?
    jumpheight = fabs(ht);
    if(zdist > 0)
        jumpheight = jumpheight + zdist;

    // push so high...
    vz = sqrt(2 * grav * jumpheight); // NOTE: sqrt(positive)!

    // we start with downwards velocity only if it's a downjump and the jump apex should be outside the jump!
    if(ht < 0)
        if(zdist < 0)
            vz = -vz;

    vector solution;
    solution = solve_quadratic(0.5 * grav, -vz, zdist); // equation "z(ti) = zdist"
    // ALWAYS solvable because jumpheight >= zdist
    if(!solution_z)
        solution_y = solution_x; // just in case it is not solvable due to roundoff errors, assume two equal solutions at their center (this is mainly for the usual case with ht == 0)
    if(zdist == 0)
        solution_x = solution_y; // solution_x is 0 in this case, so don't use it, but rather use solution_y (which will be sqrt(0.5 * jumpheight / grav), actually)

    if(zdist < 0)
    {
        // down-jump
        if(ht < 0)
        {
            // almost straight line type
            // jump apex is before the jump
            // we must take the larger one
            spiberbot_calcartillery_flighttime = solution_y;
        }
        else
        {
            // regular jump
            // jump apex is during the jump
            // we must take the larger one too
            spiberbot_calcartillery_flighttime = solution_y;
        }
    }
    else
    {
        // up-jump
        if(ht < 0)
        {
            // almost straight line type
            // jump apex is after the jump
            // we must take the smaller one
            spiberbot_calcartillery_flighttime = solution_x;
        }
        else
        {
            // regular jump
            // jump apex is during the jump
            // we must take the larger one
            spiberbot_calcartillery_flighttime = solution_y;
        }
    }
    vs = sdist / spiberbot_calcartillery_flighttime;

    // finally calculate the velocity
    return sdir * vs + '0 0 1' * vz;
}

void spiderbot_rocket_do(entity this)
{
    vector v;
    entity rocket = NULL;

    if (this.wait != -10)
    {
        if (PHYS_INPUT_BUTTON_ATCK2(this.owner) && STAT(VEHICLESTAT_W2MODE, this) == SBRM_GUIDE)
        {
            if (this.wait == 1)
            if (this.tur_head.frame == 9 || this.tur_head.frame == 1)
            {
                if(this.gun2.cnt < time && this.tur_head.frame == 9)
                    this.tur_head.frame = 1;

                return;
            }
            this.wait = 1;
        }
        else
        {
            if(this.wait)
                spiderbot_guide_release(this);

            this.wait = 0;
        }
    }

    if(this.gun2.cnt > time)
        return;

    if (this.tur_head.frame >= 9)
    {
        this.tur_head.frame = 1;
        this.wait = 0;
    }

    if(this.wait != -10)
    if(!PHYS_INPUT_BUTTON_ATCK2(this.owner))
        return;

    if(weaponLocked(this.owner) || weaponUseForbidden(this.owner))
        return;

    v = gettaginfo(this.tur_head,gettagindex(this.tur_head,"tag_fire"));

    switch(STAT(VEHICLESTAT_W2MODE, this))
    {
        case SBRM_VOLLY:
            rocket = vehicles_projectile(this, EFFECT_SPIDERBOT_ROCKETLAUNCH, SND_VEH_SPIDERBOT_ROCKET_FIRE,
                                   v, normalize(randomvec() * autocvar_g_vehicle_spiderbot_rocket_spread + v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
                                   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
                                   DEATH_VH_SPID_ROCKET.m_id, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, true, this.owner);
            crosshair_trace(this.owner);
            float _dist = (random() * autocvar_g_vehicle_spiderbot_rocket_radius) + vlen(v - trace_endpos);
            _dist -= (random() * autocvar_g_vehicle_spiderbot_rocket_radius) ;
            rocket.nextthink  = time + (_dist / autocvar_g_vehicle_spiderbot_rocket_speed);
            setthink(rocket, vehicles_projectile_explode_think);

            if(PHYS_INPUT_BUTTON_ATCK2(this.owner) && this.tur_head.frame == 1)
                this.wait = -10;
            break;
        case SBRM_GUIDE:
            rocket = vehicles_projectile(this, EFFECT_SPIDERBOT_ROCKETLAUNCH, SND_VEH_SPIDERBOT_ROCKET_FIRE,
                                   v, normalize(v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
                                   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
                                   DEATH_VH_SPID_ROCKET.m_id, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, false, this.owner);
            crosshair_trace(this.owner);
            rocket.pos1	   = trace_endpos;
            rocket.nextthink  = time;
            setthink(rocket, spiderbot_rocket_guided);


        break;
        case SBRM_ARTILLERY:
            rocket = vehicles_projectile(this, EFFECT_SPIDERBOT_ROCKETLAUNCH, SND_VEH_SPIDERBOT_ROCKET_FIRE,
                                   v, normalize(v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
                                   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
                                   DEATH_VH_SPID_ROCKET.m_id, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, true, this.owner);

            crosshair_trace(this.owner);

            rocket.pos1	   = trace_endpos + randomvec() * (0.75 * autocvar_g_vehicle_spiderbot_rocket_radius);
            rocket.pos1_z	   = trace_endpos_z;

            traceline(v, v + '0 0 1' * max_shot_distance, MOVE_WORLDONLY, this);
            float h1 = 0.75 * vlen(v - trace_endpos);

            //v = trace_endpos;
            traceline(v , rocket.pos1 + '0 0 1' * max_shot_distance, MOVE_WORLDONLY, this);
            float h2 = 0.75 * vlen(rocket.pos1 - v);

            rocket.velocity  = spiberbot_calcartillery(v, rocket.pos1, ((h1 < h2) ? h1 : h2));
            set_movetype(rocket, MOVETYPE_TOSS);
            rocket.gravity   = 1;
            //setthink(rocket, spiderbot_rocket_artillery);
        break;
    }
    rocket.classname  = "spiderbot_rocket";

    rocket.cnt = time + autocvar_g_vehicle_spiderbot_rocket_lifetime;

    this.tur_head.frame += 1;
    if (this.tur_head.frame == 9)
        this.attack_finished_single[0] = autocvar_g_vehicle_spiderbot_rocket_reload;
    else
        this.attack_finished_single[0] = ((STAT(VEHICLESTAT_W2MODE, this) ==  SBRM_VOLLY) ? autocvar_g_vehicle_spiderbot_rocket_refire2 : autocvar_g_vehicle_spiderbot_rocket_refire);

    this.gun2.cnt = time + this.attack_finished_single[0];
}

#endif
