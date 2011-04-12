// Auto cvars
float autocvar_g_vehicle_bumblebee_speed_forward;
float autocvar_g_vehicle_bumblebee_speed_strafe;
float autocvar_g_vehicle_bumblebee_speed_up;
float autocvar_g_vehicle_bumblebee_speed_down;
float autocvar_g_vehicle_bumblebee_turnspeed;
float autocvar_g_vehicle_bumblebee_pitchspeed;
float autocvar_g_vehicle_bumblebee_pitchlimit;
float autocvar_g_vehicle_bumblebee_friction;

float autocvar_g_vehicle_bumblebee_energy;
float autocvar_g_vehicle_bumblebee_energy_regen;
float autocvar_g_vehicle_bumblebee_energy_regen_pause;

float autocvar_g_vehicle_bumblebee_health;
float autocvar_g_vehicle_bumblebee_health_regen;
float autocvar_g_vehicle_bumblebee_health_regen_pause;

float autocvar_g_vehicle_bumblebee_shield;
float autocvar_g_vehicle_bumblebee_shield_regen;
float autocvar_g_vehicle_bumblebee_shield_regen_pause;

float autocvar_g_vehicle_bumblebee_cannon_cost;
float autocvar_g_vehicle_bumblebee_cannon_damage;
float autocvar_g_vehicle_bumblebee_cannon_radius;
float autocvar_g_vehicle_bumblebee_cannon_refire;
float autocvar_g_vehicle_bumblebee_cannon_speed;
float autocvar_g_vehicle_bumblebee_cannon_spread;
float autocvar_g_vehicle_bumblebee_cannon_force;

float autocvar_g_vehicle_bumblebee_respawntime;

float autocvar_g_vehicle_bumblebee_blowup_radius;
float autocvar_g_vehicle_bumblebee_blowup_coredamage;
float autocvar_g_vehicle_bumblebee_blowup_edgedamage;
float autocvar_g_vehicle_bumblebee_blowup_forceintensity;


#define BUMB_MIN '-120 -120 -40'
#define BUMB_MAX '120 120 40'

.entity gunner1;
.entity gunner2;

float bumb_pilot_frame()
{
    entity pilot, gunner, vehic;
    vector newvel;
    
    pilot = self;
    vehic = self.vehicle;
    self   = vehic;

    if(pilot.BUTTON_USE && vehic.deadflag == DEAD_NO)
    {
        self = vehic;
        vehicles_exit(VHEF_NORMAL);
        self = pilot;
        return 0;
    }

    if(vehic.deadflag != DEAD_NO)
    {
        self = pilot;
        pilot.BUTTON_ATCK = pilot.BUTTON_ATCK2 = 0;
        return 1;
    }

    crosshair_trace(pilot);    
    

    vector vang;
    float ftmp;
    
    vang = vehic.angles;
    newvel = vectoangles(normalize(trace_endpos - self.origin + '0 0 32'));
    vang_x *= -1;
    newvel_x *= -1;
    if(newvel_x > 180)  newvel_x -= 360;
    if(newvel_x < -180) newvel_x += 360;
    if(newvel_y > 180)  newvel_y -= 360;
    if(newvel_y < -180) newvel_y += 360;

    ftmp = shortangle_f(pilot.v_angle_y - vang_y, vang_y);
    if(ftmp > 180)  ftmp -= 360; if(ftmp < -180) ftmp += 360;
    vehic.avelocity_y = bound(-autocvar_g_vehicle_bumblebee_turnspeed, ftmp + vehic.avelocity_y * 0.9, autocvar_g_vehicle_bumblebee_turnspeed);

    // Pitch
    ftmp = 0;
    if(pilot.movement_x > 0 && vang_x < autocvar_g_vehicle_bumblebee_pitchlimit) ftmp = 5;
    else if(pilot.movement_x < 0 && vang_x > -autocvar_g_vehicle_bumblebee_pitchlimit) ftmp = -20;

    newvel_x = bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel_x , autocvar_g_vehicle_bumblebee_pitchlimit);
    ftmp = vang_x - bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel_x + ftmp, autocvar_g_vehicle_bumblebee_pitchlimit);
    vehic.avelocity_x = bound(-autocvar_g_vehicle_bumblebee_pitchspeed, ftmp + vehic.avelocity_x * 0.9, autocvar_g_vehicle_bumblebee_pitchspeed);

    vehic.angles_x = anglemods(vehic.angles_x);
    vehic.angles_y = anglemods(vehic.angles_y);
    vehic.angles_z = anglemods(vehic.angles_z);

    
    makevectors('0 1 0' * vehic.angles_y);
    newvel = vehic.velocity * -autocvar_g_vehicle_bumblebee_friction;

    if(pilot.movement_x != 0)
    {
        if(pilot.movement_x > 0)
            newvel += v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
        else if(pilot.movement_x < 0)
            newvel -= v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
    }

    if(pilot.movement_y != 0)
    {
        if(pilot.movement_y < 0)
            newvel -= v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
        else if(pilot.movement_y > 0)
            newvel += v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
        ftmp = newvel * v_right;
        ftmp / autocvar_g_vehicle_bumblebee_speed_strafe;
        ftmp *= frametime * 0.1;
        vehic.angles_z = bound(-15, vehic.angles_z + ftmp, 15);
    }
    else
    {
        vehic.angles_z *= 0.95;
        if(vehic.angles_z >= -1 && vehic.angles_z <= -1)
            vehic.angles_z = 0;
    }

    if(pilot.BUTTON_CROUCH)
        newvel -=   v_up * autocvar_g_vehicle_bumblebee_speed_down;
    else if (pilot.BUTTON_JUMP)
        newvel +=  v_up * autocvar_g_vehicle_bumblebee_speed_up;

    vehic.velocity  += newvel * frametime;
    pilot.velocity = pilot.movement  = vehic.velocity;
    setorigin(pilot,vehic.origin + '0 0 32');


    if(vehic.vehicle_flags  & VHF_SHIELDREGEN)
        vehicles_regen(dmg_time, vehicle_shield, autocvar_g_vehicle_bumblebee_shield, autocvar_g_vehicle_bumblebee_shield_regen_pause, autocvar_g_vehicle_bumblebee_shield_regen, frametime);

    if(vehic.vehicle_flags  & VHF_HEALTHREGEN)
        vehicles_regen(dmg_time, vehicle_health, autocvar_g_vehicle_bumblebee_health, autocvar_g_vehicle_bumblebee_health_regen_pause, autocvar_g_vehicle_bumblebee_health_regen, frametime);

    if(vehic.vehicle_flags  & VHF_ENERGYREGEN)
        vehicles_regen(cnt, vehicle_energy, autocvar_g_vehicle_bumblebee_energy, autocvar_g_vehicle_bumblebee_energy_regen_pause, autocvar_g_vehicle_bumblebee_energy_regen, frametime);

    VEHICLE_UPDATE_PLAYER(health, bumblebee);
    VEHICLE_UPDATE_PLAYER(energy, bumblebee);
    if(vehic.vehicle_flags & VHF_HASSHIELD)
        VEHICLE_UPDATE_PLAYER(shield, bumblebee);

    pilot.BUTTON_ATCK = pilot.BUTTON_ATCK2 = pilot.BUTTON_CROUCH = 0;
    self = pilot;
    
    return 1;
}

void bumb_think()
{
}

void bumb_enter()
{
}

void bumb_exit(float eject)
{
    self.owner = world;
}

void bumb_spawn()
{    
    self.vehicle_health = autocvar_g_vehicle_bumblebee_health;
    self.vehicle_shield = autocvar_g_vehicle_bumblebee_shield;
    self.movetype       = MOVETYPE_TOSS;
    self.solid          = SOLID_BBOX;
    //self.vehicle_energy = 1;
    self.movetype = MOVETYPE_FLY;
    setorigin(self, self.origin + '0 0 150');
}

void bumb_die()
{
    self.health       = 0;
    self.event_damage = SUB_Null;
    self.iscreature   = FALSE;
    self.solid        = SOLID_CORPSE;
    self.takedamage   = DAMAGE_NO;
    self.deadflag     = DEAD_DYING;
    self.movetype     = MOVETYPE_BOUNCE;

    pointparticles(particleeffectnum("rocket_explode"), findbetterlocation (self.origin, 16), '0 0 0', 1);
}

void bumb_dinit()
{
    if not (vehicle_initialize(
             "Bumblebee",
             "models/vehicles/bumblebee_body.dpm",
             "",
             "models/vehicles/wakizashi_cockpit.dpm",
             "", "", "tag_viewport",
             HUD_BUMBLEBEE,
             BUMB_MIN, BUMB_MAX,
             FALSE,
             bumb_spawn, autocvar_g_vehicle_bumblebee_respawntime,
             bumb_pilot_frame,
             bumb_enter, bumb_exit,
             bumb_die,   bumb_think))
    {
        remove(self);
        return;
    }
    self.gun1 = spawn();
    setmodel(self.gun1, "models/vehicles/bumblebee_ray.dpm");
    setattachment(self.gun1, self, "tag_hardpoint03");
    
    self.gun1 = spawn();
    self.gun2 = spawn();
    
    setmodel(self.gun1, "models/vehicles/bumblebee_plasma_left.dpm");
    setmodel(self.gun2, "models/vehicles/bumblebee_plasma_right.dpm");
    setattachment(self.gun1, self, "tag_hardpoint01");
    setattachment(self.gun2, self, "tag_hardpoint02");
    // H@XZ!
    self.gun1.angles = '90 90 0';
    self.gun2.angles = '-90 -90 0';
}

void spawnfunc_vehicle_bumblebee()
{

    precache_model ("models/vehicles/bumblebee_body.dpm");
    precache_model ("models/vehicles/bumblebee_plasma_left.dpm");
    precache_model ("models/vehicles/bumblebee_plasma_right.dpm");
    precache_model ("models/vehicles/bumblebee_ray.dpm");

    //vehicles_configcheck("vehicle_bumblebee.cfg", autocvar_g_vehicle_bumblebee_health);
    
    if(autocvar_g_vehicle_bumblebee_energy)
        if(autocvar_g_vehicle_bumblebee_energy_regen)
            self.vehicle_flags |= VHF_ENERGYREGEN;

    if(autocvar_g_vehicle_bumblebee_shield)
        self.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_bumblebee_shield_regen)
        self.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_bumblebee_health_regen)
        self.vehicle_flags |= VHF_HEALTHREGEN;

    self.think = bumb_dinit;
    self.nextthink = time + 1;    
}