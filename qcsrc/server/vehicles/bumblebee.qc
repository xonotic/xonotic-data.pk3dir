// Auto cvars
float autocvar_g_vehicle_bumblebee_speed_forward;
float autocvar_g_vehicle_bumblebee_speed_strafe;
float autocvar_g_vehicle_bumblebee_turnspeed;
float autocvar_g_vehicle_bumblebee_pitchspeed;
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

float bumb_frame()
{
    entity pilot, gunner, vehic;


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
}

void bumb_spawn()
{    
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
             HUD_WAKIZASHI,
             BUMB_MIN, BUMB_MAX,
             FALSE,
             bumb_spawn, autocvar_g_vehicle_bumblebee_respawntime,
             bumb_frame,
             bumb_enter, bumb_exit,
             bumb_die,   bumb_think))
    {
        remove(self);
        return;
    }
    self.gun1 = spawn();
    self.gun2 = spawn();
    setmodel(self.gun1, "models/vehicles/bumblebee_plasma_left.dpm");
    setmodel(self.gun2, "models/vehicles/bumblebee_plasma_right.dpm");
    setattachment(self.gun1, self, "tag_hardpoint02");
    setattachment(self.gun2, self, "tag_hardpoint01");
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