#include "racer_weapon.qh"

#ifdef SVQC

void racer_fire_rocket(entity this, entity player, vector org, vector dir, entity trg);
SOUND(RacerAttack_LASER_FIRE, W_Sound("lasergun_fire"));
SOUND(RacerAttack_ROCKET_FIRE, W_Sound("rocket_fire"));
METHOD(RacerAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    bool isPlayer = IS_PLAYER(actor);
    entity player = isPlayer ? actor : actor.owner;
    entity veh = player.vehicle;
    if (fire & 1)
    if (weapon_prepareattack(thiswep, player, weaponentity, false, autocvar_g_vehicle_racer_cannon_refire)) {
        if (veh) {
            veh.vehicle_energy -= autocvar_g_vehicle_racer_cannon_cost;
            veh.wait = time;
        }
        if(!isPlayer)
        {
            string tagname = (veh.cnt)
                ? (veh.cnt = 0, "tag_fire1")
                : (veh.cnt = 1, "tag_fire2");
            vector vshotorg = gettaginfo(veh, gettagindex(veh, tagname));
            w_shotorg = vshotorg;
            w_shotdir = v_forward;

            // Fix z-aim (for chase mode)
            crosshair_trace(player);
            w_shotdir.z = normalize(trace_endpos - vshotorg).z * 0.5;
        }
        if (isPlayer) W_SetupShot_Dir(player, weaponentity, v_forward, false, 0, SND_Null, CH_WEAPON_B, 0, DEATH_VH_WAKI_GUN.m_id);
        vector org = w_shotorg;
        vector dir = w_shotdir;
        entity bolt = vehicles_projectile(((veh) ? veh : player), EFFECT_RACER_MUZZLEFLASH, SND_RacerAttack_LASER_FIRE,
                               org, normalize(v_forward + randomvec() * autocvar_g_vehicle_racer_cannon_spread) * autocvar_g_vehicle_racer_cannon_speed,
                               autocvar_g_vehicle_racer_cannon_damage, autocvar_g_vehicle_racer_cannon_radius, autocvar_g_vehicle_racer_cannon_force,  0,
                               DEATH_VH_WAKI_GUN.m_id, PROJECTILE_WAKICANNON, 0, true, true, player);
        bolt.velocity = normalize(dir) * autocvar_g_vehicle_racer_cannon_speed;
        weapon_thinkf(player, weaponentity, WFRAME_FIRE1, 0, w_ready);
    }
    if (fire & 2)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 0.2)) {
        if (isPlayer) W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_Null, CH_WEAPON_B, 0, DEATH_VH_WAKI_ROCKET.m_id);
        racer_fire_rocket(((veh) ? veh : player), player, w_shotorg, w_shotdir, NULL);
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, 0, w_ready);
    }
}

METHOD(RacerAttack, wr_checkammo1, bool(RacerAttack thiswep, entity actor, .entity weaponentity))
{
    bool isPlayer = IS_PLAYER(actor);
    entity player = isPlayer ? actor : actor.owner;
    entity veh = player.vehicle;
    return isPlayer || veh.vehicle_energy >= autocvar_g_vehicle_racer_cannon_cost;
}

void racer_rocket_tracker(entity this);
void racer_rocket_groundhugger(entity this);

void racer_fire_rocket(entity this, entity player, vector org, vector dir, entity trg)
{
    entity rocket = vehicles_projectile(this, EFFECT_RACER_ROCKETLAUNCH, SND_RacerAttack_ROCKET_FIRE,
                           org, dir * autocvar_g_vehicle_racer_rocket_speed,
                           autocvar_g_vehicle_racer_rocket_damage, autocvar_g_vehicle_racer_rocket_radius, autocvar_g_vehicle_racer_rocket_force, 3,
                           DEATH_VH_WAKI_ROCKET.m_id, PROJECTILE_WAKIROCKET, 20, false, false, player);

    rocket.lip			  = autocvar_g_vehicle_racer_rocket_accel * sys_frametime;
    rocket.wait			 = autocvar_g_vehicle_racer_rocket_turnrate;
    rocket.nextthink		= time;
    rocket.enemy			= trg;
    rocket.cnt			  = time + 15;

    if(trg)
        setthink(rocket, racer_rocket_tracker);
    else
        setthink(rocket, racer_rocket_groundhugger);
}

void racer_rocket_tracker(entity this)
{
    vector olddir, newdir;
    float oldvel, newvel;

    this.nextthink  = time;

    if (IS_DEAD(this.owner) || this.cnt < time)
    {
        this.use(this, NULL, NULL);
        return;
    }

    if(!this.realowner.vehicle)
    {
        UpdateCSQCProjectile(this);
        return;
    }

    olddir = normalize(this.velocity);
    oldvel = vlen(this.velocity);
    newvel = oldvel + this.lip;
    makevectors(vectoangles(olddir));

    float time_to_impact = min(vlen(this.enemy.origin - this.origin) / vlen(this.velocity), 1);
    vector predicted_origin = this.enemy.origin + this.enemy.velocity * time_to_impact;

    traceline(this.origin, this.origin + v_forward * 64 - '0 0 32', MOVE_NORMAL, this);
    newdir = normalize(predicted_origin - this.origin);

    //vector
    float height_diff = predicted_origin_z - this.origin_z;

    if(vdist(newdir - v_forward, >, autocvar_g_vehicle_racer_rocket_locked_maxangle))
    {
        //bprint("Target lost!\n");
        //dprint("OF:", ftos(vlen(newdir - v_forward)), "\n");
        setthink(this, racer_rocket_groundhugger);
        return;
    }

    if(trace_fraction != 1.0 && trace_ent != this.enemy)
        newdir_z += 16 * sys_frametime;

    this.velocity = normalize(olddir + newdir * autocvar_g_vehicle_racer_rocket_turnrate) * newvel;
    this.velocity_z -= 800 * sys_frametime;
    this.velocity_z += max(height_diff, autocvar_g_vehicle_racer_rocket_climbspeed) * sys_frametime ;

    UpdateCSQCProjectile(this);
    return;
}

void racer_rocket_groundhugger(entity this)
{
    vector olddir, newdir;
    float oldvel, newvel;

    this.nextthink  = time;

    if(IS_DEAD(this.owner) || this.cnt < time)
    {
        this.use(this, NULL, NULL);
        return;
    }

    if(!this.realowner.vehicle)
    {
        UpdateCSQCProjectile(this);
        return;
    }

    olddir = normalize(this.velocity);
    oldvel = vlen(this.velocity);
    newvel = oldvel + this.lip;

    tracebox(this.origin, this.mins, this.maxs, this.origin + olddir * 64, MOVE_WORLDONLY,this);
    if(trace_fraction <= 0.5)
    {
        // Hitting somethign soon, just speed ahead
        this.velocity = olddir * newvel;
        UpdateCSQCProjectile(this);
        return;
    }

    traceline(trace_endpos, trace_endpos - '0 0 64', MOVE_NORMAL, this);
    if(trace_fraction != 1.0)
    {
        newdir = normalize(trace_endpos + '0 0 64' - this.origin) * autocvar_g_vehicle_racer_rocket_turnrate;
        this.velocity = normalize(olddir + newdir) * newvel;
    }
    else
    {
        this.velocity = olddir * newvel;
        this.velocity_z -= 1600 * sys_frametime; // 2x grav looks better for this one
    }

    int cont = pointcontents(this.origin - '0 0 32');
    if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
        this.velocity_z += 200;

    UpdateCSQCProjectile(this);
    return;
}

#endif
