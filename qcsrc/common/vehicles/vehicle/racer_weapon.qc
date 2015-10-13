#ifndef VEHICLE_RACER_WEAPON_H
#define VEHICLE_RACER_WEAPON_H

#include "../../weapons/all.qh"

CLASS(RacerAttack, PortoLaunch)
/* flags     */ ATTRIB(RacerAttack, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED);
/* impulse   */ ATTRIB(RacerAttack, impulse, int, 3);
/* refname   */ ATTRIB(RacerAttack, netname, string, "racercannon");
/* wepname   */ ATTRIB(RacerAttack, message, string, _("Racer cannon"));
ENDCLASS(RacerAttack)
REGISTER_WEAPON(RACER, NEW(RacerAttack));

// TODO: move into implementation
#ifdef SVQC
float autocvar_g_vehicle_racer_rocket_refire;
void racer_fire_rocket(vector org, vector dir, entity trg);
#endif

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

float autocvar_g_vehicle_racer_cannon_cost;
float autocvar_g_vehicle_racer_cannon_damage;
float autocvar_g_vehicle_racer_cannon_radius;
float autocvar_g_vehicle_racer_cannon_refire;
float autocvar_g_vehicle_racer_cannon_speed;
float autocvar_g_vehicle_racer_cannon_spread;
float autocvar_g_vehicle_racer_cannon_force;

float autocvar_g_vehicle_racer_rocket_accel;
float autocvar_g_vehicle_racer_rocket_damage;
float autocvar_g_vehicle_racer_rocket_radius;
float autocvar_g_vehicle_racer_rocket_force;
float autocvar_g_vehicle_racer_rocket_speed;
float autocvar_g_vehicle_racer_rocket_turnrate;

float autocvar_g_vehicle_racer_rocket_climbspeed;
float autocvar_g_vehicle_racer_rocket_locked_maxangle;

void racer_fire_rocket(vector org, vector dir, entity trg);
METHOD(RacerAttack, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
{
    bool isPlayer = IS_PLAYER(actor);
    entity player = isPlayer ? actor : actor.owner;
    entity veh = player.vehicle;
    if (fire1)
    if (weapon_prepareattack(thiswep, player, false, autocvar_g_vehicle_racer_cannon_refire)) {
        if (veh) {
            veh.vehicle_energy -= autocvar_g_vehicle_racer_cannon_cost;
            veh.wait = time;
        }
        if (isPlayer) W_SetupShot_Dir(player, v_forward, false, 0, SND(Null), CH_WEAPON_B, 0);
        vector org = w_shotorg;
        vector dir = w_shotdir;
        entity bolt = vehicles_projectile(EFFECT_RACER_MUZZLEFLASH.eent_eff_name, SND(LASERGUN_FIRE),
                               org, normalize(v_forward + randomvec() * autocvar_g_vehicle_racer_cannon_spread) * autocvar_g_vehicle_racer_cannon_speed,
                               autocvar_g_vehicle_racer_cannon_damage, autocvar_g_vehicle_racer_cannon_radius, autocvar_g_vehicle_racer_cannon_force,  0,
                               DEATH_VH_WAKI_GUN.m_id, PROJECTILE_WAKICANNON, 0, true, true, player);
        bolt.velocity = normalize(dir) * autocvar_g_vehicle_racer_cannon_speed;
        weapon_thinkf(player, WFRAME_FIRE1, 0, w_ready);
    }
    if (fire2)
    if (!isPlayer || weapon_prepareattack(thiswep, actor, false, 0.2)) {
        if (isPlayer) W_SetupShot_Dir(actor, v_forward, false, 0, SND(Null), CH_WEAPON_B, 0);
        racer_fire_rocket(w_shotorg, w_shotdir, NULL);
        weapon_thinkf(actor, WFRAME_FIRE2, 0, w_ready);
    }
}

METHOD(RacerAttack, wr_checkammo1, bool(RacerAttack thiswep))
{
    SELFPARAM();
    bool isPlayer = IS_PLAYER(self);
    entity player = isPlayer ? self : self.owner;
    entity veh = player.vehicle;
    return isPlayer || veh.vehicle_energy >= autocvar_g_vehicle_racer_cannon_cost;
}

void racer_rocket_tracker();
void racer_rocket_groundhugger();

void racer_fire_rocket(vector org, vector dir, entity trg)
{SELFPARAM();
    entity rocket = vehicles_projectile(EFFECT_RACER_ROCKETLAUNCH.eent_eff_name, SND(ROCKET_FIRE),
                           org, dir * autocvar_g_vehicle_racer_rocket_speed,
                           autocvar_g_vehicle_racer_rocket_damage, autocvar_g_vehicle_racer_rocket_radius, autocvar_g_vehicle_racer_rocket_force, 3,
                           DEATH_VH_WAKI_ROCKET.m_id, PROJECTILE_WAKIROCKET, 20, false, false, self.owner);

    rocket.lip			  = autocvar_g_vehicle_racer_rocket_accel * sys_frametime;
    rocket.wait			 = autocvar_g_vehicle_racer_rocket_turnrate;
    rocket.nextthink		= time;
    rocket.enemy			= trg;
    rocket.cnt			  = time + 15;

    if(trg)
        rocket.think			= racer_rocket_tracker;
    else
        rocket.think			= racer_rocket_groundhugger;
}

void racer_rocket_tracker()
{SELFPARAM();
    vector olddir, newdir;
    float oldvel, newvel;

    self.nextthink  = time;

    if (self.owner.deadflag != DEAD_NO || self.cnt < time)
    {
        self.use();
        return;
    }

    if(!self.realowner.vehicle)
    {
        UpdateCSQCProjectile(self);
        return;
    }

    olddir = normalize(self.velocity);
    oldvel = vlen(self.velocity);
    newvel = oldvel + self.lip;
    makevectors(vectoangles(olddir));

    float time_to_impact = min(vlen(self.enemy.origin - self.origin) / vlen(self.velocity), 1);
    vector predicted_origin = self.enemy.origin + self.enemy.velocity * time_to_impact;

    traceline(self.origin, self.origin + v_forward * 64 - '0 0 32', MOVE_NORMAL, self);
    newdir = normalize(predicted_origin - self.origin);

    //vector
    float height_diff = predicted_origin_z - self.origin_z;

    if(vlen(newdir - v_forward) > autocvar_g_vehicle_racer_rocket_locked_maxangle)
    {
        //bprint("Target lost!\n");
        //dprint("OF:", ftos(vlen(newdir - v_forward)), "\n");
        self.think = racer_rocket_groundhugger;
        return;
    }

    if(trace_fraction != 1.0 && trace_ent != self.enemy)
        newdir_z += 16 * sys_frametime;

    self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_racer_rocket_turnrate) * newvel;
    self.velocity_z -= 800 * sys_frametime;
    self.velocity_z += max(height_diff, autocvar_g_vehicle_racer_rocket_climbspeed) * sys_frametime ;

    UpdateCSQCProjectile(self);
    return;
}

void racer_rocket_groundhugger()
{SELFPARAM();
    vector olddir, newdir;
    float oldvel, newvel;

    self.nextthink  = time;

    if(self.owner.deadflag != DEAD_NO || self.cnt < time)
    {
        self.use();
        return;
    }

    if(!self.realowner.vehicle)
    {
        UpdateCSQCProjectile(self);
        return;
    }

    olddir = normalize(self.velocity);
    oldvel = vlen(self.velocity);
    newvel = oldvel + self.lip;

    tracebox(self.origin, self.mins, self.maxs, self.origin + olddir * 64, MOVE_WORLDONLY,self);
    if(trace_fraction <= 0.5)
    {
        // Hitting somethign soon, just speed ahead
        self.velocity = olddir * newvel;
        UpdateCSQCProjectile(self);
        return;
    }

    traceline(trace_endpos, trace_endpos - '0 0 64', MOVE_NORMAL, self);
    if(trace_fraction != 1.0)
    {
        newdir = normalize(trace_endpos + '0 0 64' - self.origin) * autocvar_g_vehicle_racer_rocket_turnrate;
        self.velocity = normalize(olddir + newdir) * newvel;
    }
    else
    {
        self.velocity = olddir * newvel;
        self.velocity_z -= 1600 * sys_frametime; // 2x grav looks better for this one
    }

    int cont = pointcontents(self.origin - '0 0 32');
    if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
        self.velocity_z += 200;

    UpdateCSQCProjectile(self);
    return;
}

#endif

#endif
