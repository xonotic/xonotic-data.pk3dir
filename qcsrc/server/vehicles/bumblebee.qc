#ifdef SVQC
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

float autocvar_g_vehicle_bumblebee_cannon_turnspeed;
float autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down;
float autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up;
float autocvar_g_vehicle_bumblebee_cannon_turnlimit_in;
float autocvar_g_vehicle_bumblebee_cannon_turnlimit_out;

float autocvar_g_vehicle_bumblebee_raygun_turnspeed;
float autocvar_g_vehicle_bumblebee_raygun_pitchlimit_down;
float autocvar_g_vehicle_bumblebee_raygun_pitchlimit_up;
float autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides;

float autocvar_g_vehicle_bumblebee_respawntime;

float autocvar_g_vehicle_bumblebee_blowup_radius;
float autocvar_g_vehicle_bumblebee_blowup_coredamage;
float autocvar_g_vehicle_bumblebee_blowup_edgedamage;
float autocvar_g_vehicle_bumblebee_blowup_forceintensity;

float autocvar_g_vehicle_bumblebee;

#define BUMB_MIN '-120 -120 -120'
#define BUMB_MAX '120 120 120'

void bumb_fire_cannon(entity _gun, string _tagname, entity _owner)
{
    vector v;
    entity bolt;
    
    v = gettaginfo(_gun, gettagindex(_gun, _tagname));
    bolt = vehicles_projectile("bigplasma_muzzleflash", "weapons/flacexp3.wav",
                           v, normalize(v_forward + randomvec() * autocvar_g_vehicle_bumblebee_cannon_spread) * autocvar_g_vehicle_bumblebee_cannon_speed,
                           autocvar_g_vehicle_bumblebee_cannon_damage, autocvar_g_vehicle_bumblebee_cannon_radius, autocvar_g_vehicle_bumblebee_cannon_force,  0,
                           DEATH_BUMB_GUN, PROJECTILE_BUMBLE_GUN, 0, TRUE, TRUE, _owner);


    //bolt.velocity = v_forward * autocvar_g_vehicle_bumblebee_cannon_speed;
}

float bumb_gunner_frame()
{
    entity vehic, gun, gunner;

    vehic   = self.vehicle.owner;
    gun     = self.vehicle;
    gunner  = self;
    self    = vehic;

    vehic.solid = SOLID_NOT;
    setorigin(gunner, vehic.origin);
    gunner.velocity = vehic.velocity;
    crosshair_trace(gunner);
    vector _ct = trace_endpos;
    vector ad;
    
    if(gun.lock_time < time)
        gun.enemy = world;
    
    if(trace_ent)
    if(trace_ent.movetype)
    if(trace_ent.takedamage)
    if(!trace_ent.deadflag)
    {
        if(teamplay)
        {
            if(trace_ent.team != gunner.team)
            {
                gun.enemy = trace_ent;
                gun.lock_time = time + 5;
            }
        }
        else
        {            
            gun.enemy = trace_ent;
            gun.lock_time = time + 5;
        }
    }
        
    if(gun.enemy)
    {
        float i, distance, impact_time;

        vector vf = real_origin(gun.enemy);
        vector _vel = gun.enemy.velocity;
        if(gun.enemy.movetype == MOVETYPE_WALK)
            _vel_z *= 0.1;
        
            
        ad = vf;
        for(i = 0; i < 4; ++i)
        {
            distance = vlen(ad - gunner.origin);
            impact_time = distance / autocvar_g_vehicle_bumblebee_cannon_speed;
            ad = vf + _vel * impact_time;
        }
        trace_endpos = ad;
            

        UpdateAuxiliaryXhair(gunner, ad, '1 0 1', 1);
        vehicle_aimturret(vehic, trace_endpos, vehic.gun1, "fire", 
                          autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up, 
                          autocvar_g_vehicle_bumblebee_cannon_turnlimit_out * -1,  autocvar_g_vehicle_bumblebee_cannon_turnlimit_in,  autocvar_g_vehicle_bumblebee_cannon_turnspeed);

    }
    else
        vehicle_aimturret(vehic, _ct, vehic.gun1, "fire", 
                          autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up, 
                          autocvar_g_vehicle_bumblebee_cannon_turnlimit_out * -1,  autocvar_g_vehicle_bumblebee_cannon_turnlimit_in,  autocvar_g_vehicle_bumblebee_cannon_turnspeed);

    if(gunner.BUTTON_ATCK)
    if(time > gun.attack_finished_single)
    if(vehic.vehicle_energy >= autocvar_g_vehicle_bumblebee_cannon_cost)
    {
        vehic.vehicle_energy -= autocvar_g_vehicle_bumblebee_cannon_cost;
        vehic.wait = time;                        
        bumb_fire_cannon(gun, "fire", gunner);
        gun.attack_finished_single = time + autocvar_g_vehicle_bumblebee_cannon_refire;
    }
    
    VEHICLE_UPDATE_PLAYER(gunner, health, bumblebee);
    VEHICLE_UPDATE_PLAYER(gunner, energy, bumblebee);

    if(vehic.vehicle_flags & VHF_HASSHIELD)
        VEHICLE_UPDATE_PLAYER(gunner, shield, bumblebee);
        
    ad = gettaginfo(gun, gettagindex(gun, "fire"));
    traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, gun);
    UpdateAuxiliaryXhair(gunner, trace_endpos, ('1 0 0' * gunner.vehicle_reload1) + ('0 1 0' * (1 - gunner.vehicle_reload1)), 0);

    
    vehic.solid = SOLID_BBOX;
    gunner.BUTTON_ATCK = gunner.BUTTON_ATCK2 = gunner.BUTTON_CROUCH = 0;
    self = gunner;
    return 1;
}

.entity gunner1;
.entity gunner2;

void bumb_gunner_exit(float _exitflag)
{
    dprint("^2Gunner1 exits\n");
    
    if (clienttype(self) == CLIENTTYPE_REAL)
    {
        msg_entity = self;
        WriteByte (MSG_ONE, SVC_SETVIEWPORT);
        WriteEntity( MSG_ONE, self);

        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
        WriteAngle(MSG_ONE, 0);
        WriteAngle(MSG_ONE, self.vehicle.angles_y);
        WriteAngle(MSG_ONE, 0);
    }
    
    setsize(self, PL_MIN,PL_MAX);

    self.takedamage     = DAMAGE_AIM;
    self.solid          = SOLID_SLIDEBOX;
    self.movetype       = MOVETYPE_WALK;
    self.effects        &~= EF_NODRAW;
    self.alpha          = 1;
    self.PlayerPhysplug = SUB_Null;
    self.view_ofs       = PL_VIEW_OFS;
    self.event_damage   = PlayerDamage;
    self.hud            = HUD_NORMAL;
    self.switchweapon   = self.vehicle.switchweapon;

    if(self.flagcarried)
    {
        self.flagcarried.scale = 0.6;
        setattachment(self.flagcarried, self, "");
        setorigin(self.flagcarried, FLAG_CARRY_POS);
    }

    CSQCVehicleSetup(self, HUD_NORMAL);
    self.vehicle.vehicle_hudmodel.viewmodelforclient = self.vehicle;	    
    
    if(self == self.vehicle.owner.gunner1)
        self.vehicle.owner.gunner1 = world;
    else if(self == self.vehicle.owner.gunner2)
        self.vehicle.owner.gunner2 = world;
    else
        dprint("^1self != gunner1 or gunner2, this is a BIG PROBLEM, tell tZork this happend.\n");
    
    self.vehicle.phase = time + 1; 
    self.vehicle        = world;
}

float bumb_gunner_enter()
{    
    RemoveGrapplingHook(other);

    self.gun1.vehicle_pilot = other;
    self.gunner1            = other;
    //self.gun1.owner         = other;
    self.gunner1.vehicle    = self.gun1;
    self.gun1.switchweapon  = other.switchweapon;
    self.gun1.vehicle_exit  = bumb_gunner_exit;
    
        
    other.angles            = self.angles;
    other.takedamage        = DAMAGE_NO;
    other.solid             = SOLID_NOT;
    other.movetype          = MOVETYPE_NOCLIP;
    other.alpha             = -1;
    other.event_damage      = SUB_Null;
    other.view_ofs          = '0 0 0';
    other.hud               = self.gun1.hud;
    other.PlayerPhysplug    = self.gun1.PlayerPhysplug;
    other.vehicle_ammo1     = self.vehicle_ammo1;
    other.vehicle_ammo2     = self.vehicle_ammo2;
    other.vehicle_reload1   = self.vehicle_reload1;
    other.vehicle_reload2   = self.vehicle_reload2;
    other.vehicle_energy    = self.vehicle_energy;
    other.PlayerPhysplug    = bumb_gunner_frame;
    other.flags             &~= FL_ONGROUND;
        
    msg_entity = other;
    WriteByte (MSG_ONE, SVC_SETVIEWPORT);
    WriteEntity(MSG_ONE, self.gun1.vehicle_viewport);
    WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
    WriteAngle(MSG_ONE, self.gun1.angles_x + self.angles_x); // tilt
    WriteAngle(MSG_ONE, self.gun1.angles_y + self.angles_y); // yaw
    WriteAngle(MSG_ONE, 0);                                  // roll        
    self.gun1.vehicle_hudmodel.viewmodelforclient = other;
    
    return TRUE;
}

float vehicles_valid_pilot()
{
    if(other.classname != "player")
        return FALSE;

    if(other.deadflag != DEAD_NO)
        return FALSE;

    if(other.vehicle != world)
        return FALSE;

    // Remove this when bots know how to use vehicles.
    if (clienttype(other) != CLIENTTYPE_REAL)
        return FALSE;
    
    return TRUE;
}

void bumb_touch()
{
    
    if(self.gunner1 != world && self.gunner2 != world)
    {
        vehicles_touch();
        return;
    }
    
    if (vehicles_valid_pilot())
    {
        if(self.gun1.phase <= time)
            if (bumb_gunner_enter())        
                return;            
        
        if(self.gun2.phase <= time)
            if (bumb_gunner_enter())        
                return;    
    
    }
    
    vehicles_touch();
}

float bumb_pilot_frame()
{
    entity pilot, vehic;
    vector newvel;

    pilot = self;
    vehic = self.vehicle;
    self   = vehic;

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

    vehicle_aimturret(vehic, trace_endpos, self.gun3, "fire", 
                          autocvar_g_vehicle_bumblebee_raygun_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_raygun_pitchlimit_up, 
                          autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides * -1,  autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides,  autocvar_g_vehicle_bumblebee_raygun_turnspeed);

    /*
    if(!vehic.gunner1)
    vehicle_aimturret(vehic, trace_endpos, self.gun1, "fire", 
                          autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up, 
                          autocvar_g_vehicle_bumblebee_cannon_turnlimit_out * -1,  autocvar_g_vehicle_bumblebee_cannon_turnlimit_in,  autocvar_g_vehicle_bumblebee_cannon_turnspeed);
    //if(!vehic.gunner2)
    vehicle_aimturret(vehic, trace_endpos, self.gun2, "fire", 
                          autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up, 
                          autocvar_g_vehicle_bumblebee_cannon_turnlimit_in * -1,  autocvar_g_vehicle_bumblebee_cannon_turnlimit_out,  autocvar_g_vehicle_bumblebee_cannon_turnspeed);
    


    if(pilot.BUTTON_ATCK)
    if(time > vehic.attack_finished_single)
    if(vehic.vehicle_energy >= autocvar_g_vehicle_bumblebee_cannon_cost)
    {
        vehic.vehicle_energy -= autocvar_g_vehicle_bumblebee_cannon_cost;
        vehic.wait = time;

        if(vehic.cnt)
        {
            bumb_fire_cannon(vehic.gun1, "fire", pilot);
            vehic.cnt = 0;
        }
        else
        {
            bumb_fire_cannon(vehic.gun2, "fire", pilot);
            vehic.cnt = 1;
        }
        vehic.attack_finished_single = time + autocvar_g_vehicle_bumblebee_cannon_refire;
    }
    */
    
    if(vehic.vehicle_flags  & VHF_SHIELDREGEN)
        vehicles_regen(dmg_time, vehicle_shield, autocvar_g_vehicle_bumblebee_shield, autocvar_g_vehicle_bumblebee_shield_regen_pause, autocvar_g_vehicle_bumblebee_shield_regen, frametime, TRUE);

    if(vehic.vehicle_flags  & VHF_HEALTHREGEN)
        vehicles_regen(dmg_time, vehicle_health, autocvar_g_vehicle_bumblebee_health, autocvar_g_vehicle_bumblebee_health_regen_pause, autocvar_g_vehicle_bumblebee_health_regen, frametime, FALSE);

    if(vehic.vehicle_flags  & VHF_ENERGYREGEN)
        vehicles_regen(wait, vehicle_energy, autocvar_g_vehicle_bumblebee_energy, autocvar_g_vehicle_bumblebee_energy_regen_pause, autocvar_g_vehicle_bumblebee_energy_regen, frametime, FALSE);

    VEHICLE_UPDATE_PLAYER(pilot, health, bumblebee);
    VEHICLE_UPDATE_PLAYER(pilot, energy, bumblebee);

    if(vehic.vehicle_flags & VHF_HASSHIELD)
        VEHICLE_UPDATE_PLAYER(pilot, shield, bumblebee);


    pilot.BUTTON_ATCK = pilot.BUTTON_ATCK2 = pilot.BUTTON_CROUCH = 0;
    self = pilot;

    return 1;
}

void bumb_think()
{
    self.velocity = self.velocity * 0.99;
    self.nextthink = time + 0.1;
}

void bumb_enter()
{
    self.touch  = bumb_touch;
}

void bumb_exit(float eject)
{
    self.owner = world;
    self.touch = vehicles_touch;
}

void bumb_spawn(float _f)
{
    self.vehicle_health = autocvar_g_vehicle_bumblebee_health;
    self.vehicle_shield = autocvar_g_vehicle_bumblebee_shield;
    self.movetype       = MOVETYPE_TOSS;
    self.solid          = SOLID_BBOX;
    //self.vehicle_energy = 1;
    self.movetype = MOVETYPE_FLY;
    setorigin(self, self.origin + '0 0 25');
}

void bumb_die()
{
    self.deadflag    = DEAD_DEAD;
    self.vehicle_exit(VHEF_NORMAL);
    
    self.health       = 0;
    self.event_damage = SUB_Null;
    self.solid        = SOLID_CORPSE;
    self.takedamage   = DAMAGE_NO;
    self.deadflag     = DEAD_DYING;
    self.movetype     = MOVETYPE_BOUNCE;
    
    RadiusDamage (self, self.enemy, autocvar_g_vehicle_bumblebee_blowup_coredamage,
					autocvar_g_vehicle_bumblebee_blowup_edgedamage,
					autocvar_g_vehicle_bumblebee_blowup_radius, world,
					autocvar_g_vehicle_bumblebee_blowup_forceintensity,
					DEATH_WAKIBLOWUP, world);

    pointparticles(particleeffectnum("rocket_explode"), findbetterlocation (self.origin, 16), '0 0 0', 1);
}

void bumb_dinit()
{
    if not (vehicle_initialize(
             "Bumblebee", "models/vehicles/bumblebee_body.dpm",
             "", "models/vehicles/spiderbot_cockpit.dpm", "", "", "tag_viewport",
             HUD_BUMBLEBEE, BUMB_MIN, BUMB_MAX, FALSE,
             bumb_spawn, autocvar_g_vehicle_bumblebee_respawntime,
             bumb_pilot_frame, bumb_enter, bumb_exit,
             bumb_die, bumb_think, FALSE, autocvar_g_vehicle_bumblebee_health))
    {
        remove(self);
        return;
    }
    
    
    self.gun1 = spawn();
    self.gun2 = spawn();
    self.gun3 = spawn();

    self.vehicle_flags |= VHF_MULTISLOT;

    self.gun1.owner = self;
    self.gun2.owner = self;
    self.gun3.owner = self;
    
    setmodel(self.gun1, "models/vehicles/bumblebee_plasma_right.dpm");
    setmodel(self.gun2, "models/vehicles/bumblebee_plasma_left.dpm");
    setmodel(self.gun3, "models/vehicles/bumblebee_ray.dpm");

    setattachment(self.gun1, self, "cannon_right");
    setattachment(self.gun2, self, "cannon_left");
    setattachment(self.gun3, self, "raygun");

    vehicle_addplayerslot(self, self.gun1, HUD_RAPTOR, "models/vehicles/wakizashi_cockpit.dpm", bumb_gunner_frame, bumb_gunner_exit);
    vehicle_addplayerslot(self, self.gun2, HUD_RAPTOR, "models/vehicles/wakizashi_cockpit.dpm", bumb_gunner_frame, bumb_gunner_exit);
    
    //fixme-model
    setorigin(self.gun1.vehicle_hudmodel, '90 -27 -23');
    setorigin(self.gun1.vehicle_viewport, '-85 0 50');
    
    setorigin(self.gun2.vehicle_hudmodel, '90 -27 -23');
    setorigin(self.gun2.vehicle_viewport, '-85 0 50');
    self.scale = 1.5;

    /*
    float i;
    for(i=1; gettaginfo(self.gun1, i), gettaginfo_name; ++i)
    {
        
        dprint(" ------- ^1gettaginfo_name^2(",ftos(i),") ^3=", gettaginfo_name, "\n");
    }
    */    
}

void spawnfunc_vehicle_bumblebee()
{
    if(!autocvar_g_vehicle_bumblebee)
    {
        remove(self);
        return;
    }        
    
    precache_model ("models/vehicles/bumblebee_body.dpm");
    precache_model ("models/vehicles/bumblebee_plasma_left.dpm");
    precache_model ("models/vehicles/bumblebee_plasma_right.dpm");
    precache_model ("models/vehicles/bumblebee_ray.dpm");
    precache_model ("models/vehicles/wakizashi_cockpit.dpm");
    precache_model ("models/vehicles/spiderbot_cockpit.dpm");
    precache_model ("models/vehicles/raptor_cockpit.dpm");

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
#endif // SVQC

#ifdef CSQC
void bumblebee_draw()
{

}

void bumblebee_draw2d()
{

}

void bumblebee_read_extra()
{

}

void vehicle_bumblebee_assemble()
{

}
#endif //CSQC

/*
vector predict_target(entity _targ, vector _from, float _shot_speed)
{    
    float i;                // loop
    float _distance;        // How far to target
    float _impact_time;     // How long untill projectile impacts
    vector _predict_pos;    // Predicted enemy location
    vector _original_origin;// Where target is before predicted
    
     _original_origin = real_origin(_targ); // Typicaly center of target BBOX
        
    _predict_pos = _original_origin;
    for(i = 0; i < 4; ++i)  // Loop a few times to increase prediction accuracy (increase loop count if accuracy is to low)
    {
        _distance = vlen(_predict_pos - _from); // Get distance to previos predicted location
        _impact_time = _distance / _shot_speed; // Calculate impact time
        _predict_pos = _original_origin + _targ.velocity * _impact_time; // Calculate new predicted location
    }
    
    return _predict_pos;
}
*/