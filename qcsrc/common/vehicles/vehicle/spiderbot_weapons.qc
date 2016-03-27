#include "spiderbot_weapons.qh"

#ifdef IMPLEMENTATION

#ifdef SVQC

void spiderbot_rocket_artillery()
{SELFPARAM();
    self.nextthink = time;
    UpdateCSQCProjectile(self);
}

void spiderbot_rocket_unguided()
{SELFPARAM();
    vector newdir, olddir;

    self.nextthink  = time;

    olddir = normalize(self.velocity);
    newdir = normalize(self.pos1 - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(self);

    if (IS_DEAD(self.owner) || self.cnt < time || vdist(self.pos1 - self.origin, <, 16))
        self.use1(self, NULL, NULL);
}

void spiderbot_rocket_guided()
{SELFPARAM();
    vector newdir, olddir;

    self.nextthink  = time;

    if(!self.realowner.vehicle)
        self.think = spiderbot_rocket_unguided;

    crosshair_trace(self.realowner);
    olddir = normalize(self.velocity);
    newdir = normalize(trace_endpos - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(self);

    if (IS_DEAD(self.owner) || self.cnt < time)
        self.use1(self, NULL, NULL);
}

void spiderbot_guide_release(entity this)
{
    entity rkt;
    rkt = findchainentity(realowner, this.owner);
    if(!rkt)
        return;

    crosshair_trace(this.owner);
    while(rkt)
    {
        if(rkt.think == spiderbot_rocket_guided)
        {
            rkt.pos1 = trace_endpos;
            rkt.think = spiderbot_rocket_unguided;
        }
        rkt = rkt.chain;
    }
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
{;
    vector v;
    entity rocket = world;

    if (this.wait != -10)
    {
        if (PHYS_INPUT_BUTTON_ATCK2(this.owner) && this.vehicle_weapon2mode == SBRM_GUIDE)
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

    if(forbidWeaponUse(this.owner))
        return;

    v = gettaginfo(this.tur_head,gettagindex(this.tur_head,"tag_fire"));

    switch(this.vehicle_weapon2mode)
    {
        case SBRM_VOLLY:
            rocket = vehicles_projectile(this, EFFECT_SPIDERBOT_ROCKETLAUNCH.eent_eff_name, SND_ROCKET_FIRE,
                                   v, normalize(randomvec() * autocvar_g_vehicle_spiderbot_rocket_spread + v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
                                   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
                                   DEATH_VH_SPID_ROCKET.m_id, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, true, this.owner);
            crosshair_trace(this.owner);
            float _dist = (random() * autocvar_g_vehicle_spiderbot_rocket_radius) + vlen(v - trace_endpos);
            _dist -= (random() * autocvar_g_vehicle_spiderbot_rocket_radius) ;
            rocket.nextthink  = time + (_dist / autocvar_g_vehicle_spiderbot_rocket_speed);
            rocket.think	 = vehicles_projectile_explode;

            if(PHYS_INPUT_BUTTON_ATCK2(this.owner) && this.tur_head.frame == 1)
                this.wait = -10;
            break;
        case SBRM_GUIDE:
            rocket = vehicles_projectile(this, EFFECT_SPIDERBOT_ROCKETLAUNCH.eent_eff_name, SND_ROCKET_FIRE,
                                   v, normalize(v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
                                   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
                                   DEATH_VH_SPID_ROCKET.m_id, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, false, this.owner);
            crosshair_trace(this.owner);
            rocket.pos1	   = trace_endpos;
            rocket.nextthink  = time;
            rocket.think	  = spiderbot_rocket_guided;


        break;
        case SBRM_ARTILLERY:
            rocket = vehicles_projectile(this, EFFECT_SPIDERBOT_ROCKETLAUNCH.eent_eff_name, SND_ROCKET_FIRE,
                                   v, normalize(v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
                                   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
                                   DEATH_VH_SPID_ROCKET.m_id, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, true, this.owner);

            crosshair_trace(this.owner);

            rocket.pos1	   = trace_endpos + randomvec() * (0.75 * autocvar_g_vehicle_spiderbot_rocket_radius);
            rocket.pos1_z	   = trace_endpos_z;

            traceline(v, v + '0 0 1' * MAX_SHOT_DISTANCE, MOVE_WORLDONLY, this);
            float h1 = 0.75 * vlen(v - trace_endpos);

            //v = trace_endpos;
            traceline(v , rocket.pos1 + '0 0 1' * MAX_SHOT_DISTANCE, MOVE_WORLDONLY, this);
            float h2 = 0.75 * vlen(rocket.pos1 - v);

            rocket.velocity  = spiberbot_calcartillery(v, rocket.pos1, ((h1 < h2) ? h1 : h2));
            rocket.movetype  = MOVETYPE_TOSS;
            rocket.gravity   = 1;
            //rocket.think	 = spiderbot_rocket_artillery;
        break;
    }
    rocket.classname  = "spiderbot_rocket";

    rocket.cnt = time + autocvar_g_vehicle_spiderbot_rocket_lifetime;

    this.tur_head.frame += 1;
    if (this.tur_head.frame == 9)
        this.attack_finished_single[0] = autocvar_g_vehicle_spiderbot_rocket_reload;
    else
        this.attack_finished_single[0] = ((this.vehicle_weapon2mode ==  SBRM_VOLLY) ? autocvar_g_vehicle_spiderbot_rocket_refire2 : autocvar_g_vehicle_spiderbot_rocket_refire);

    this.gun2.cnt = time + this.attack_finished_single[0];
}

#endif

#endif
