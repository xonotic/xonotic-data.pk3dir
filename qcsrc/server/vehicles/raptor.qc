#define RAPTOR_MIN '-80 -80 0'
#define RAPTOR_MAX '80 80 70'

float autocvar_g_vehicle_raptor_respawntime;

float autocvar_g_vehicle_raptor_movestyle;
float autocvar_g_vehicle_raptor_turnspeed;
float autocvar_g_vehicle_raptor_pitchspeed;
float autocvar_g_vehicle_raptor_pitchlimit;

float autocvar_g_vehicle_raptor_speed_forward;
float autocvar_g_vehicle_raptor_speed_strafe;
float autocvar_g_vehicle_raptor_speed_up;
float autocvar_g_vehicle_raptor_speed_down;

float autocvar_g_vehicle_raptor_bomblets;
float autocvar_g_vehicle_raptor_bomblet_alt;
float autocvar_g_vehicle_raptor_bomblet_time;
float autocvar_g_vehicle_raptor_bomblet_damage;
float autocvar_g_vehicle_raptor_bomblet_spread;
float autocvar_g_vehicle_raptor_bomblet_edgedamage;
float autocvar_g_vehicle_raptor_bomblet_radius;
float autocvar_g_vehicle_raptor_bomblet_force;
float autocvar_g_vehicle_raptor_bombs_refire;

float autocvar_g_vehicle_raptor_guns_turnspeed;
float autocvar_g_vehicle_raptor_guns_turnlimit;
float autocvar_g_vehicle_raptor_guns_pitchlimit_up;
float autocvar_g_vehicle_raptor_guns_pitchlimit_down;

float autocvar_g_vehicle_raptor_cannon_locktarget;
float autocvar_g_vehicle_raptor_cannon_locking_time;
float autocvar_g_vehicle_raptor_cannon_locking_releasetime;
float autocvar_g_vehicle_raptor_cannon_locked_time;
float autocvar_g_vehicle_raptor_cannon_predicttarget;

float autocvar_g_vehicle_raptor_cannon_cost;
float autocvar_g_vehicle_raptor_cannon_damage;
float autocvar_g_vehicle_raptor_cannon_radius;
float autocvar_g_vehicle_raptor_cannon_refire;
float autocvar_g_vehicle_raptor_cannon_speed;
float autocvar_g_vehicle_raptor_cannon_spread;


float autocvar_g_vehicle_raptor_energy;
float autocvar_g_vehicle_raptor_energy_regen;
float autocvar_g_vehicle_raptor_energy_regen_pause;

float autocvar_g_vehicle_raptor_health;
float autocvar_g_vehicle_raptor_health_regen;
float autocvar_g_vehicle_raptor_health_regen_pause;

float autocvar_g_vehicle_raptor_shield;
float autocvar_g_vehicle_raptor_shield_regen;
float autocvar_g_vehicle_raptor_shield_regen_pause;

void raptor_spawn();
//void raptor_return();
float raptor_frame();
//float raptor_takeoff();

.entity bomb1;
.entity bomb2;
.entity camera;

float raptor_altitude(float amax)
{
	tracebox(self.origin, self.mins, self.maxs, self.origin - ('0 0 1' * amax), TRUE, self);
    return vlen(self.origin - trace_endpos);
}

void raptor_bomblet_boom()
{
    if(other == self.owner || other.owner == self.owner)
        return;

    pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
    RadiusDamage (self, self.enemy, autocvar_g_vehicle_raptor_bomblet_damage,
                                    autocvar_g_vehicle_raptor_bomblet_edgedamage,
                                    autocvar_g_vehicle_raptor_bomblet_radius, world,
                                    autocvar_g_vehicle_raptor_bomblet_force, DEATH_SBROCKET, world);
    remove(self);
}

void raptor_bomb_burst()
{
    if(autocvar_g_vehicle_raptor_bomblet_alt)
    {
        self.nextthink = time;
        // FIXME: this can make bombs stic forever if fierd at low altitude and land close to vehicle.
        traceline(self.origin, self.origin + (normalize(self.velocity) * autocvar_g_vehicle_raptor_bomblet_alt), MOVE_NORMAL, self);
        if(trace_fraction == 1.0)
            return;

        if(vlen(self.origin - self.owner.origin) < autocvar_g_vehicle_raptor_bomblet_radius)
            return;
    }

    entity bomblet;
    float i;

    pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);

    for(i = 0; i < autocvar_g_vehicle_raptor_bomblets; ++i)
    {
        bomblet = spawn();
        setorigin(bomblet, self.origin);

        bomblet.scale       = 0.5;
        bomblet.solid       = SOLID_TRIGGER;
        bomblet.movetype    = MOVETYPE_BOUNCE;
        bomblet.touch       = raptor_bomblet_boom;
        bomblet.think       = raptor_bomblet_boom;
        bomblet.nextthink   = time + 5;
        bomblet.owner       = self.owner;
        bomblet.velocity    = normalize(normalize(self.velocity) + (randomvec() * autocvar_g_vehicle_raptor_bomblet_spread)) * vlen(self.velocity);

        CSQCProjectile(bomblet, TRUE, PROJECTILE_RAPTORBOMB, TRUE);
    }

    remove(self);
}

void raptor_bomb_touch()
{
    raptor_bomb_burst();
}

void raptor_bombdrop()
{
    entity bomb_1, bomb_2;

    //self.bomb1.alpha = 0;
    //self.bomb2.alpha = 0;

    bomb_1 = spawn();
    bomb_2 = spawn();

    setorigin(bomb_1, gettaginfo(self, gettagindex(self, "bombmount_left")));
    setorigin(bomb_2, gettaginfo(self, gettagindex(self, "bombmount_right")));

    bomb_1.movetype  = bomb_2.movetype   = MOVETYPE_TOSS;
    bomb_1.velocity  = bomb_2.velocity   = self.velocity;
    bomb_1.touch     = bomb_2.touch      = raptor_bomb_touch;
    bomb_1.think     = bomb_2.think      = raptor_bomb_burst;

    if(autocvar_g_vehicle_raptor_bomblet_alt)
        bomb_1.nextthink = bomb_2.nextthink  = time;
    else
        bomb_1.nextthink = bomb_2.nextthink  = time + autocvar_g_vehicle_raptor_bomblet_time;

    bomb_1.owner     = bomb_2.owner      = self;
    bomb_1.enemy     = bomb_2.enemy      = self.owner;
    bomb_1.solid     = bomb_2.solid      = SOLID_BBOX;

    CSQCProjectile(bomb_1, TRUE, PROJECTILE_RAPTORBOMB, TRUE);
    CSQCProjectile(bomb_2, TRUE, PROJECTILE_RAPTORBOMB, TRUE);

}

void raptor_bolt_explode()
{
	PROJECTILE_TOUCH;
    pointparticles(particleeffectnum("raptor_cannon_impact"), findbetterlocation (self.origin, 8), trace_plane_normal * 1000, 1);
    RadiusDamage (self, self.realowner, autocvar_g_vehicle_raptor_cannon_damage, 0, autocvar_g_vehicle_raptor_cannon_radius, world, 25, DEATH_WAKIGUN, world);
    sound (self, CHAN_PROJECTILE, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
    remove (self);
}

void raptor_fire_cannon(entity gun, string tagname)
{
    entity bolt;

    bolt = spawn();

    PROJECTILE_MAKETRIGGER(bolt);
    sound (gun, CHAN_WEAPON, "weapons/lasergun_fire.wav", VOL_BASE, ATTN_NORM);
    setorigin(bolt, gettaginfo(gun, gettagindex(gun, tagname)));

    bolt.movetype        = MOVETYPE_FLYMISSILE;
    bolt.flags           = FL_PROJECTILE | FL_NOTARGET;
    bolt.owner           = self;
    bolt.realowner       = self.owner;
    bolt.touch           = raptor_bolt_explode;
    bolt.think           = raptor_bolt_explode;
    bolt.nextthink       = time + 9;
    bolt.bot_dodge       = TRUE;
    bolt.bot_dodgerating = autocvar_g_vehicle_raptor_cannon_damage;
    bolt.velocity        = normalize(v_forward + randomvec() * autocvar_g_vehicle_raptor_cannon_spread) * autocvar_g_vehicle_raptor_cannon_speed;

    pointparticles(particleeffectnum("raptor_cannon_muzzleflash"), bolt.origin, bolt.velocity, 1);
    //pointparticles(particleeffectnum("spiderbot_minigun_muzzleflash"), bolt.origin, bolt.velocity, 1);

    CSQCProjectile(bolt, TRUE, PROJECTILE_CRYLINK, TRUE);
}

void raptor_think()
{
}

void raptor_enter()
{
    self.movetype   = MOVETYPE_BOUNCEMISSILE;
    self.owner.vehicle_health = (self.vehicle_health / autocvar_g_vehicle_raptor_health);
    self.owner.vehicle_shield = (self.vehicle_shield / autocvar_g_vehicle_raptor_shield);
    self.velocity_z = 1;
    //setorigin(self.vehicle_viewport, self.origin);
}

void raptor_land()
{
    float hgt;

    hgt = raptor_altitude(512);
    self.velocity = (self.velocity * 0.9) + ('0 0 -1800' * (hgt / 256) * sys_frametime);
    self.angles_x *= 0.95;
    self.angles_z *= 0.95;

    if(hgt < 128)
        if(self.frame != 0)
            self.frame = max(self.frame - 0.25, 0);

    self.bomb1.gun1.avelocity_y = 90 + ((self.frame / 25) * 2000);
    self.bomb1.gun2.avelocity_y = -self.bomb1.gun1.avelocity_y;

    if(hgt < 16)
    {
        self.movetype   = MOVETYPE_BOUNCE;
        self.think      = raptor_think;
    }

    self.nextthink  = time;
}

void raptor_exit(float eject)
{

    if(self.deadflag == DEAD_NO)
    {
        vehicles_setreturn(autocvar_g_vehicle_raptor_respawntime, raptor_spawn);
        self.think      = raptor_land;
        self.nextthink  = time;
    }

    if not (self.owner)
        return;

	makevectors(self.angles);
	if(eject)
	{
	    setorigin(self.owner,self.origin + v_forward * 100 + '0 0 64');
	    self.owner.velocity = (v_up + v_forward * 0.25) * 750;
	}
	else
        setorigin(self.owner,self.origin - v_forward * 200 + '0 0 64');

    self.owner = world;
}

float raptor_frame()
{
    entity player, raptor;
    float ftmp, ftmp2;
    vector df;

    player = self;
    raptor   = self.vehicle;
    self    = raptor;

    if(player.BUTTON_USE)
    {
        self = raptor;
        vehicles_exit(VHEF_NORMAL);
        self = player;
        return 0;
    }

    if(raptor.deadflag != DEAD_NO)
    {
        self = player;
        player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
        return 1;
    }

    // Takeoff sequense
    if(raptor.frame < 25)
    {
        raptor.frame += 0.25;
        raptor.velocity_z = min(raptor.velocity_z * 1.5, 256);
        self.bomb1.gun1.avelocity_y = 90 + ((raptor.frame / 25) * 2000);
        self.bomb1.gun2.avelocity_y = -self.bomb1.gun1.avelocity_y;
        player.BUTTON_ATCK = player.BUTTON_ATCK2 = player.BUTTON_CROUCH = 0;
        self = player;
        return 1;
    }

    /*
    raptor.angles_x *= -1;
    // Rotate Body
    ftmp = autocvar_g_vehicle_raptor_turnspeed * sys_frametime;
    ftmp = bound(-ftmp, shortangle_f(player.v_angle_y - raptor.angles_y, raptor.angles_y), ftmp);

    // Turn
    raptor.angles_y = anglemods(raptor.angles_y + ftmp);

    // Pitch Body
    ftmp = autocvar_g_vehicle_raptor_pitchspeed  * sys_frametime;
    ftmp = bound(-ftmp, shortangle_f(player.v_angle_x - raptor.angles_x, raptor.angles_x), ftmp);

    raptor.angles_x = bound(-autocvar_g_vehicle_raptor_pitchlimit, anglemods(raptor.angles_x + ftmp), autocvar_g_vehicle_raptor_pitchlimit);
    raptor.angles_x *= -1;

    if(autocvar_g_vehicle_raptor_movestyle == 1)
    {
        ftmp = raptor.angles_z;
        raptor.angles_z = 0;
        ftmp2 = raptor.angles_x;
        raptor.angles_x = 0;
        fixedmakevectors(raptor.angles);
        raptor.angles_z = ftmp;
        raptor.angles_x = ftmp2;
    }
    else
        makevectors(player.v_angle);
    */

    crosshair_trace(player);
    //df = vectoangles(normalize(trace_endpos - gettaginfo(raptor ,gettagindex(raptor, "tag_hud"))) - raptor.angles);
    df = vectoangles(normalize(trace_endpos - self.origin + '0 0 32'));
    if(df_x > 180)  df_x -= 360;
    if(df_x < -180) df_x += 360;
    if(df_y > 180)  df_y -= 360;
    if(df_y < -180) df_y += 360;

    //raptor.angles_x *= -1;
    // Rotate Body
    ftmp = autocvar_g_vehicle_raptor_turnspeed * sys_frametime;
    ftmp = bound(-ftmp, shortangle_f(df_y - raptor.angles_y, raptor.angles_y), ftmp);

    // Turn
    raptor.angles_y = anglemods(raptor.angles_y + ftmp);

    // Pitch Body
    ftmp = autocvar_g_vehicle_raptor_pitchspeed  * sys_frametime;
    ftmp = bound(-ftmp, shortangle_f(df_x - raptor.angles_x, raptor.angles_x), ftmp);

    raptor.angles_x = bound(-autocvar_g_vehicle_raptor_pitchlimit, anglemods(raptor.angles_x + ftmp), autocvar_g_vehicle_raptor_pitchlimit);
    //raptor.angles_x *= -1;

    if(autocvar_g_vehicle_raptor_movestyle == 1)
    {
        ftmp = raptor.angles_z;
        raptor.angles_z = 0;
        ftmp2 = raptor.angles_x;
        raptor.angles_x = 0;
        fixedmakevectors(raptor.angles);
        raptor.angles_z = ftmp;
        raptor.angles_x = ftmp2;
    }
    else
        makevectors(player.v_angle);



    /*
    float dist, spd, back, up;
    //dist = normalize(self.vehicle_viewport.origin - self.origin);
    spd = vlen(self.velocity) + 0.01;
    back = spd / autocvar_g_vehicle_raptor_speed_forward;
    up = 1 - back;
    back = back;
    back = back * 1250;
    back += 150;
    up = up * 200;
    up = up + 100;

    setorigin(self.vehicle_viewport, self.origin + (v_up * up) + (v_forward * -back));
    */

    df = raptor.velocity * -1;

    if(player.movement_x != 0)
    {
        if(player.movement_x > 0)
            df += v_forward  * autocvar_g_vehicle_raptor_speed_forward;
        else if(player.movement_x < 0)
            df -= v_forward  * autocvar_g_vehicle_raptor_speed_forward;
    }

    if(player.movement_y != 0)
    {
        if(player.movement_y < 0)
            df -= v_right * autocvar_g_vehicle_raptor_speed_strafe;
        else if(player.movement_y > 0)
            df += v_right * autocvar_g_vehicle_raptor_speed_strafe;

        raptor.angles_z = bound(-30,raptor.angles_z + (player.movement_y / autocvar_g_vehicle_raptor_speed_strafe),30);
    }
    else
    {
        raptor.angles_z *= 0.95;
        if(raptor.angles_z >= -1 && raptor.angles_z <= -1)
            raptor.angles_z = 0;
    }

    if(player.BUTTON_CROUCH)
        df -=   v_up * autocvar_g_vehicle_raptor_speed_down;
    else if (player.BUTTON_JUMP)
        df +=  v_up * autocvar_g_vehicle_raptor_speed_up;

    raptor.velocity  += df * frametime;
    player.velocity = player.movement  = raptor.velocity;
    setorigin(player,raptor.origin + '0 0 32');

    vector vf, ad;
    // Target lock & predict
    if(autocvar_g_vehicle_raptor_cannon_locktarget)
    {

        vehicles_locktarget2((1 / autocvar_g_vehicle_raptor_cannon_locking_time) * frametime,
                             (1 / autocvar_g_vehicle_raptor_cannon_locking_releasetime) * frametime,
                             autocvar_g_vehicle_raptor_cannon_locked_time);

        if(autocvar_g_vehicle_raptor_cannon_predicttarget && self.lock_strength == 1)
        {
            vector o;
            if(self.lock_target != world)
            {
                float i, distance, impact_time;

                vf = real_origin(raptor.lock_target);
                ad = vf;
                o = raptor.origin;
                for(i = 0; i < 4; ++i)
                {

                    distance = vlen(ad - o);
                    impact_time = distance / autocvar_g_vehicle_raptor_cannon_speed;
                    ad = vf + raptor.lock_target.velocity * impact_time;
                    o = raptor.origin + raptor.velocity * impact_time;
                }
                trace_endpos = ad;
            }
        }

        if(self.lock_target != world)
        if(self.lock_strength == 1)
            UpdateAuxiliaryXhair(player, real_origin(self.lock_target), '0 0 1', 1);
        else
            UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * (1 - self.lock_strength)) + '0 1 0' * self.lock_strength, 1);
    }

    // Aim the gunz
    ftmp2 = autocvar_g_vehicle_raptor_guns_turnspeed * frametime;
    ftmp = -ftmp2;

    // Gun1
    df = gettaginfo(raptor.gun1, gettagindex(raptor.gun1, "fire1"));
    ad = df;
    vf = v_forward;
    df = vectoangles(normalize(trace_endpos - df)); // Find the direction & angle
    df = shortangle_vxy(df - (raptor.angles + raptor.gun1.angles), raptor.angles + raptor.gun1.angles);     // Find aim offset
    // Bind to aimspeed
    df_x = bound(ftmp, df_x, ftmp2);
    df_y = bound(ftmp, df_y, ftmp2);
    // Bind to limts
    raptor.gun1.angles_x = bound(-autocvar_g_vehicle_raptor_guns_pitchlimit_down, df_x + raptor.gun1.angles_x, autocvar_g_vehicle_raptor_guns_pitchlimit_up);
    raptor.gun1.angles_y = bound(-autocvar_g_vehicle_raptor_guns_turnlimit,  df_y + raptor.gun1.angles_y, autocvar_g_vehicle_raptor_guns_turnlimit);

    //Gun 2
    df = gettaginfo(raptor.gun2, gettagindex(raptor.gun2, "fire1"));
    ad += df;
    vf += v_forward;
    df = vectoangles(normalize(trace_endpos - df)); // Find the direction & angle
    df = shortangle_vxy(df - (raptor.angles + raptor.gun2.angles), raptor.angles + raptor.gun2.angles);     // Find aim offset
    // Bind to aimspeed
    df_x = bound(ftmp, df_x, ftmp2);
    df_y = bound(ftmp, df_y, ftmp2);
    // Bind to limts
    raptor.gun2.angles_x = bound(-autocvar_g_vehicle_raptor_guns_pitchlimit_down, df_x + raptor.gun2.angles_x, autocvar_g_vehicle_raptor_guns_pitchlimit_up);
    raptor.gun2.angles_y = bound(-autocvar_g_vehicle_raptor_guns_turnlimit,  df_y + raptor.gun2.angles_y, autocvar_g_vehicle_raptor_guns_turnlimit);


    /*
    ad = ad * 0.5;
    v_forward = vf * 0.5;
    traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, raptor);
    UpdateAuxiliaryXhair(player, trace_endpos, '0 1 0', 0);
    */

    if(player.BUTTON_ATCK)
    if(raptor.attack_finished_single <= time)
    if(raptor.vehicle_energy > autocvar_g_vehicle_raptor_cannon_cost)
    {
        raptor_fire_cannon(self.gun1, "fire1");
        raptor_fire_cannon(self.gun2, "fire1");

        raptor.vehicle_energy -= autocvar_g_vehicle_raptor_cannon_cost;
        raptor.attack_finished_single = time + autocvar_g_vehicle_raptor_cannon_refire;
        self.cnt = time;
    }

    if(self.vehicle_flags  & VHF_SHIELDREGEN)
        vehicles_regen(dmg_time, vehicle_shield, autocvar_g_vehicle_raptor_shield, autocvar_g_vehicle_raptor_shield_regen_pause, autocvar_g_vehicle_raptor_shield_regen, frametime);

    if(self.vehicle_flags  & VHF_HEALTHREGEN)
        vehicles_regen(dmg_time, vehicle_health, autocvar_g_vehicle_raptor_health, autocvar_g_vehicle_raptor_health_regen_pause, autocvar_g_vehicle_raptor_health_regen, frametime);

    if(self.vehicle_flags  & VHF_ENERGYREGEN)
        vehicles_regen(cnt, vehicle_energy, autocvar_g_vehicle_raptor_energy, autocvar_g_vehicle_raptor_energy_regen_pause, autocvar_g_vehicle_raptor_energy_regen, frametime);

    player.vehicle_energy = raptor.vehicle_energy / autocvar_g_vehicle_raptor_energy;


    if(time > raptor.delay)
    {
        if(player.BUTTON_ATCK2)
        {
            raptor_bombdrop();
            raptor.delay = time + autocvar_g_vehicle_raptor_bombs_refire;
        }
        player.vehicle_reload1 = 1;
    }
    else
    {
        player.vehicle_reload1 = min(time / raptor.delay, 1);
        raptor.bomb1.alpha = raptor.bomb2.alpha = player.vehicle_reload1; //(player.vehicle_reload1 == 1 ? 1 : player.vehicle_reload1 * 0.25);
    }



    VEHICLE_UPDATE_PLAYER(health, raptor);

    if(self.vehicle_flags & VHF_HASSHIELD)
        VEHICLE_UPDATE_PLAYER(shield, raptor);

    player.BUTTON_ATCK = player.BUTTON_ATCK2 = player.BUTTON_CROUCH = 0;
    return 1;
}

void raptor_touch()
{
    if(self.owner)
    {
        if(vlen(self.velocity) == 0)
            return;

        if(other.classname != "player")
            return;

        return;
    }

    if(other.classname != "player")
        return;

    if(other.deadflag != DEAD_NO)
        return;

    if(other.vehicle != world)
        return;

    vehicles_enter();
}

void raptor_blowup()
{
    sound (self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
    pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);

    self.deadflag    = DEAD_DEAD;
    self.vehicle_exit(VHEF_NORMAL);
    RadiusDamage (self, self, 250, 15, 250, world, 250, DEATH_WAKIBLOWUP, world);

    self.alpha          = -1;
    self.movetype       = MOVETYPE_NONE;
    self.effects        = EF_NODRAW;
    self.colormod       = '0 0 0';
    self.avelocity      = '0 0 0';
    self.velocity       = '0 0 0';

    setorigin(self, self.pos1);
    self.touch = SUB_Null;
}

void raptor_die()
{
    self.health       = 0;
    self.event_damage = SUB_Null;
    self.iscreature   = FALSE;
    self.solid        = SOLID_CORPSE;
    self.takedamage   = DAMAGE_NO;
    self.deadflag     = DEAD_DYING;
    self.movetype     = MOVETYPE_BOUNCE;
    //self.wait         = time;

    pointparticles(particleeffectnum("rocket_explode"), findbetterlocation (self.origin, 16), '0 0 0', 1);

    self.velocity_z += 128;

    if(random() < 0.5)
        self.avelocity_z  = 45 + random() * 270;
    else
        self.avelocity_z  = -45 + random() * -270;

    self.colormod = '-0.5 -0.5 -0.5';

	self.touch     = raptor_blowup;
	self.think     = raptor_spawn;
	self.nextthink = time + autocvar_g_vehicle_raptor_respawntime;
}

void raptor_spawn()
{
    self.flags     = FL_NOTARGET;
    self.effects   = 0;

    self.vehicle_health = autocvar_g_vehicle_raptor_health;
    self.vehicle_shield = autocvar_g_vehicle_raptor_shield;
    self.event_damage   = vehicles_damage;
    self.touch          = raptor_touch;
    self.iscreature     = TRUE;
    self.movetype       = MOVETYPE_FLY;
    self.solid          = SOLID_SLIDEBOX;
    self.takedamage     = DAMAGE_AIM;
	self.deadflag       = DEAD_NO;
    self.bot_attack     = TRUE;
    self.vehicle_energy = 1;
    self.vehicle_hudmodel.viewmodelforclient = self;

    self.bomb1.gun1.avelocity_y = 90;
    self.bomb1.gun2.avelocity_y = -90;
    self.frame = 0;

    setorigin(self, self.pos1);
    self.angles = self.pos2;

    setsize(self, RAPTOR_MIN, RAPTOR_MAX );
    pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);
    self.delay = time;

    vehicles_common_spawn();
}

void raptor_dinit()
{
    entity spinner;
    vector ofs;

    if not (vehicle_initialize(
             "Raptor",
             "models/vehicles/raptor.dpm",
             "",
             "models/vehicles/raptor_cockpit.dpm",
             "", "tag_hud", "tag_camera",
             HUD_RAPTOR,
             RAPTOR_MIN, RAPTOR_MAX,
             FALSE,
             raptor_spawn, raptor_frame,
             raptor_enter, raptor_exit,
             raptor_die,   raptor_think))
    {
        remove(self);
        return;
    }

    //FIXME: Camera is in a bad place in HUD model.
    setorigin(self.vehicle_viewport, '10 0 3');

    self.frame = 0;

    self.bomb1 = spawn();
    self.bomb2 = spawn();
    self.gun1  = spawn();
    self.gun2  = spawn();

    //setattachment(self.vehicle_viewport, world, "");

    setmodel(self.bomb1,"models/vehicles/raptor_bomb.dpm");
    setmodel(self.bomb2,"models/vehicles/raptor_bomb.dpm");
    setmodel(self.gun1, "models/vehicles/raptor_gun.dpm");
    setmodel(self.gun2, "models/vehicles/raptor_gun.dpm");

    setattachment(self.bomb1, self,"bombmount_left");
    setattachment(self.bomb2, self,"bombmount_right");


    // FIXME Guns mounts to angled bones
    self.bomb1.angles = self.angles;
    self.angles = '0 0 0';
    // This messes up gun-aim, so work arround it.
    //setattachment(self.gun1, self, "gunmount_left");
    ofs = gettaginfo(self, gettagindex(self, "gunmount_left"));
    ofs -= self.origin;
    setattachment(self.gun1, self, "");
    setorigin(self.gun1, ofs);

    //setattachment(self.gun2, self, "gunmount_right");
    ofs = gettaginfo(self, gettagindex(self, "gunmount_right"));
    ofs -= self.origin;
    setattachment(self.gun2, self, "");
    setorigin(self.gun2, ofs);

    self.angles = self.bomb1.angles;
    self.bomb1.angles = '0 0 0';


    spinner = spawn();
    spinner.owner = self;
    setmodel(spinner,"models/vehicles/spinner.dpm");
    setattachment(spinner, self, "engine_left");
    spinner.movetype = MOVETYPE_NOCLIP;
    spinner.avelocity = '0 90 0';
    self.bomb1.gun1 = spinner;

    spinner = spawn();
    spinner.owner = self;
    setmodel(spinner,"models/vehicles/spinner.dpm");
    setattachment(spinner, self, "engine_right");
    spinner.movetype = MOVETYPE_NOCLIP;
    spinner.avelocity = '0 -90 0';
    self.bomb1.gun2 = spinner;
}

void spawnfunc_vehicle_raptor()
{
    vehicles_configcheck("vehicle_raptor.cfg", autocvar_g_vehicle_raptor_health);

    if(autocvar_g_vehicle_raptor_shield)
        self.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_raptor_shield_regen)
        self.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_raptor_health_regen)
        self.vehicle_flags |= VHF_HEALTHREGEN;

    if(autocvar_g_vehicle_raptor_energy_regen)
        self.vehicle_flags |= VHF_ENERGYREGEN;

    precache_model ("models/vehicles/raptor.dpm");
    precache_model ("models/vehicles/raptor_gun.dpm");
    precache_model ("models/vehicles/spinner.dpm");
    precache_model ("models/vehicles/raptor_cockpit.dpm");
    precache_model ("models/vehicles/raptor_bomb.dpm");

    self.think = raptor_dinit;
    self.nextthink = time + 1;
}
