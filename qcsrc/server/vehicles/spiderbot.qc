const vector SPIDERBOT_MIN = '-75 -75 10';
const vector SPIDERBOT_MAX  = '75 75 125';

#ifdef SVQC
float autocvar_g_vehicle_spiderbot_respawntime;

float autocvar_g_vehicle_spiderbot_speed_stop;
float autocvar_g_vehicle_spiderbot_speed_strafe;
float autocvar_g_vehicle_spiderbot_speed_walk;
float autocvar_g_vehicle_spiderbot_turnspeed;
float autocvar_g_vehicle_spiderbot_movement_inertia;

float autocvar_g_vehicle_spiderbot_springlength;
float autocvar_g_vehicle_spiderbot_springup;
float autocvar_g_vehicle_spiderbot_springblend;

float autocvar_g_vehicle_spiderbot_head_pitchlimit_down;
float autocvar_g_vehicle_spiderbot_head_pitchlimit_up;
float autocvar_g_vehicle_spiderbot_head_pitchspeed;
float autocvar_g_vehicle_spiderbot_head_turnlimit;
float autocvar_g_vehicle_spiderbot_head_turnspeed;

//float autocvar_g_vehicle_spiderbot_energy;
//float autocvar_g_vehicle_spiderbot_energy_regen;
//float autocvar_g_vehicle_spiderbot_energy_regen_pause;

float autocvar_g_vehicle_spiderbot_health;
float autocvar_g_vehicle_spiderbot_health_regen;
float autocvar_g_vehicle_spiderbot_health_regen_pause;

float autocvar_g_vehicle_spiderbot_shield;
float autocvar_g_vehicle_spiderbot_shield_regen;
float autocvar_g_vehicle_spiderbot_shield_regen_pause;

float autocvar_g_vehicle_spiderbot_minigun_damage;
float autocvar_g_vehicle_spiderbot_minigun_refire;
float autocvar_g_vehicle_spiderbot_minigun_spread;
float autocvar_g_vehicle_spiderbot_minigun_ammo_cost;
float autocvar_g_vehicle_spiderbot_minigun_ammo_max;
float autocvar_g_vehicle_spiderbot_minigun_ammo_regen;
float autocvar_g_vehicle_spiderbot_minigun_ammo_regen_pause;

float autocvar_g_vehicle_spiderbot_rocket_damage;
float autocvar_g_vehicle_spiderbot_rocket_force;
float autocvar_g_vehicle_spiderbot_rocket_radius;
float autocvar_g_vehicle_spiderbot_rocket_speed;
float autocvar_g_vehicle_spiderbot_rocket_refire;
float autocvar_g_vehicle_spiderbot_rocket_reload;
float autocvar_g_vehicle_spiderbot_rocket_health;
float autocvar_g_vehicle_spiderbot_rocket_noise;
float autocvar_g_vehicle_spiderbot_rocket_turnrate;
float autocvar_g_vehicle_spiderbot_rocket_lifetime;

void spiderbot_exit(float eject);
void spiderbot_enter();
void spiderbot_spawn();

void spiderbot_rocket_unguided()
{
    vector newdir, olddir;

    self.nextthink  = time;

    olddir = normalize(self.velocity);
    newdir = normalize(self.pos1 - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(self);

    if (self.owner.deadflag != DEAD_NO || self.cnt < time || vlen(self.pos1 - self.origin) < 16)
        self.use();
}

void spiderbot_rocket_guided()
{
    vector newdir, olddir;

    self.nextthink  = time;

    if not (self.realowner.vehicle)
        self.think = spiderbot_rocket_unguided;

    crosshair_trace(self.realowner);
    olddir = normalize(self.velocity);
    newdir = normalize(trace_endpos - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(self);

    if (self.owner.deadflag != DEAD_NO || self.cnt < time)
        self.use();
}

void spiderbot_guide_release()
{
    entity rkt;
    rkt = findchainentity(realowner, self.owner);
    if not (rkt)
        return;

    crosshair_trace(self.owner);
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

void spiderbot_rocket_do()
{

    vector v;
    entity rocket;

    if (self.owner.BUTTON_ATCK2)
    {
        if (self.wait == 1)
        if (self.tur_head.frame == 9 || self.tur_head.frame == 1)
        {
            if(self.gun2.cnt < time && self.tur_head.frame == 9)
                self.tur_head.frame = 1;

            return;
        }
        self.wait = 1;
    }
    else
    {
        if(self.wait)
            spiderbot_guide_release();

        self.wait = 0;
    }

    if(self.gun2.cnt > time)
        return;

    if (self.tur_head.frame >= 9)
        self.tur_head.frame = 1;

    if not (self.owner.BUTTON_ATCK2)
        return;

    crosshair_trace(self.owner);

    v = gettaginfo(self.tur_head,gettagindex(self.tur_head,"tag_fire"));
    rocket = vehicles_projectile("spiderbot_rocket_launch", "weapons/rocket_fire.wav",
                           v, normalize(v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
                           autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
                           DEATH_SBROCKET, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, FALSE, FALSE);

    rocket.cnt        = time + 15;
    rocket.classname  = "spiderbot_rocket";
    rocket.pos1       = trace_endpos;
    rocket.think      = spiderbot_rocket_guided;
    rocket.nextthink  = time;
    rocket.cnt        = time + autocvar_g_vehicle_spiderbot_rocket_lifetime;

    self.tur_head.frame += 1;
    if (self.tur_head.frame == 9)
        self.attack_finished_single = autocvar_g_vehicle_spiderbot_rocket_reload;
    else
        self.attack_finished_single = autocvar_g_vehicle_spiderbot_rocket_refire;

    self.gun2.cnt = time + self.attack_finished_single;
}

float spiderbot_frame()
{
    vector ad;
    entity player, spider;
    float ftmp;

	if(intermission_running)
		return 1;
		
    player = self;
    spider = self.vehicle;
    self   = spider;

    vehicles_painframe();
    
    player.BUTTON_ZOOM      = 0;
    player.BUTTON_CROUCH    = 0;
    player.switchweapon     = 0;

    crosshair_trace(player);
    //UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload2) + ('0 1 0' * (1 - player.vehicle_reload2)), 2);

    //player.v_angle_x *= -1;
    //gettaginfo(spider.tur_head, 0);
    //ad = player.v_angle - vectoangles2(v_forward, v_up);
    //ad = player.v_angle - (spider.tur_head.angles + spider.angles);
    //player.v_angle_x *= -1;
    ad = AnglesTransform_ToAngles(AnglesTransform_LeftDivide(AnglesTransform_FromAngles(spider.angles), AnglesTransform_FromVAngles(player.v_angle))) - spider.tur_head.angles;

    if(ad_x > 180)  ad_x -= 360;
    if(ad_x < -180) ad_x += 360;
    if(ad_y > 180)  ad_y -= 360;
    if(ad_y < -180) ad_y += 360;
    
    // Rotate head
    ftmp = autocvar_g_vehicle_spiderbot_head_turnspeed * sys_frametime;
    ad_y = bound(-ftmp, ad_y, ftmp);
    spider.tur_head.angles_y = bound(autocvar_g_vehicle_spiderbot_head_turnlimit * -1, spider.tur_head.angles_y + ad_y, autocvar_g_vehicle_spiderbot_head_turnlimit);

    // Pitch head
#if 0 // Enable to pich by cross-trace (more precise in chase, but less predictable)
    ad = vectoangles(normalize(trace_endpos - gettaginfo(spider.tur_head,gettagindex(spider.tur_head,"tag_hud")))) - (spider.tur_head.angles + spider.angles);
    if(ad_x > 180) ad_x -= 360;
    if(ad_x < -180) ad_x += 360;
#endif
    ftmp = autocvar_g_vehicle_spiderbot_head_pitchspeed * sys_frametime;
    ad_x = bound(ftmp * -1, ad_x, ftmp);
    spider.tur_head.angles_x = bound(autocvar_g_vehicle_spiderbot_head_pitchlimit_down, spider.tur_head.angles_x + ad_x, autocvar_g_vehicle_spiderbot_head_pitchlimit_up);

    // Turn Body
    ftmp = autocvar_g_vehicle_spiderbot_turnspeed * sys_frametime;
    ftmp = bound(-ftmp, spider.tur_head.angles_y, ftmp);

    makevectors(spider.angles + '-2 0 0' * spider.angles_x);

/*
    vector ofs;
    ofs = self.origin + v_up * 128;
    te_lightning1(world, ofs, ofs + v_up * 32);
    te_lightning1(world, ofs, ofs + v_right * 128);
    te_lightning1(world, ofs, ofs + v_forward * 256);
*/

    movelib_groundalign4point(autocvar_g_vehicle_spiderbot_springlength, autocvar_g_vehicle_spiderbot_springup, autocvar_g_vehicle_spiderbot_springblend);

    if(spider.flags & FL_ONGROUND)
    {
        if(spider.frame == 4 && self.tur_head.wait != 0)
        {
            sound (self, CH_TRIGGER_SINGLE, "vehicles/spiderbot_land.wav", VOL_VEHICLEENGINE, ATTN_NORM);
            spider.frame = 5;            
        }
        
        if(player.BUTTON_JUMP && self.tur_head.wait < time)
        {        
            sound (self, CH_TRIGGER_SINGLE, "vehicles/spiderbot_jump.wav", VOL_VEHICLEENGINE, ATTN_NORM);
            //dprint("spiderbot_jump:", ftos(soundlength("vehicles/spiderbot_jump.wav")), "\n");
            self.delay = 0;

            self.tur_head.wait = time + 2;
            player.BUTTON_JUMP = 0;
            spider.velocity   = v_forward * 700 + v_up * 600;
            spider.frame = 4;
        }
        else
        {
            if(vlen(player.movement) == 0)
            {
                if(self.sound_nexttime < time || self.delay != 3)
                {                        
                    self.delay = 3;
                    self.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_idle.wav");
                    //dprint("spiderbot_idle:", ftos(soundlength("vehicles/spiderbot_idle.wav")), "\n");
                    sound (self, CH_TRIGGER_SINGLE, "vehicles/spiderbot_idle.wav", VOL_VEHICLEENGINE, ATTN_NORM);
                }                
                movelib_beak_simple(autocvar_g_vehicle_spiderbot_speed_stop);
                spider.frame = 5;
            }
            else
            {
                spider.angles_y = anglemods(spider.angles_y + ftmp);
                spider.tur_head.angles_y -= ftmp;

                if(player.movement_x != 0)
                {
                    if(player.movement_x > 0)
                    {
                        player.movement_x = 1;
                        spider.frame = 0;
                    }
                    else if(player.movement_x < 0)
                    {
                        player.movement_x = -1;
                        spider.frame = 1;
                    }
                    player.movement_y = 0;
                    movelib_move_simple(normalize(v_forward * player.movement_x),autocvar_g_vehicle_spiderbot_speed_walk,autocvar_g_vehicle_spiderbot_movement_inertia);

                    if(self.sound_nexttime < time || self.delay != 1)
                    {                        
                        self.delay = 1;
                        self.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_walk.wav");
                        sound (self, CH_TRIGGER_SINGLE, "vehicles/spiderbot_walk.wav", VOL_VEHICLEENGINE, ATTN_NORM);
                        //dprint("spiderbot_walk:", ftos(soundlength("vehicles/spiderbot_walk.wav")), "\n");
                    }
                }
                else if(player.movement_y != 0)
                {
                    if(player.movement_y < 0)
                    {
                        player.movement_y = -1;
                        spider.frame = 2;
                    }
                    else if(player.movement_y > 0)
                    {
                        player.movement_y = 1;
                        spider.frame = 3;
                    }
                    movelib_move_simple(normalize(v_right * player.movement_y),autocvar_g_vehicle_spiderbot_speed_strafe,autocvar_g_vehicle_spiderbot_movement_inertia);
                    if(self.sound_nexttime < time || self.delay != 2)
                    {                        
                        self.delay = 2;
                        self.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_strafe.wav");
                        sound (self, CH_TRIGGER_SINGLE, "vehicles/spiderbot_strafe.wav", VOL_VEHICLEENGINE, ATTN_NORM);
                        //dprint("spiderbot_strafe:", ftos(soundlength("vehicles/spiderbot_strafe.wav")), "\n");
                    }
                }
            }
        }
    }

    self.angles_x = bound(-45, self.angles_x, 45);
    self.angles_z = bound(-45, self.angles_z, 45);

    if(player.BUTTON_ATCK)
    {
        spider.cnt = time;
        if(spider.vehicle_ammo1 >= autocvar_g_vehicle_spiderbot_minigun_ammo_cost && spider.tur_head.attack_finished_single <= time)
        {
            entity gun;
            vector v;
            spider.misc_bulletcounter += 1;

            self = player;

            mod(spider.misc_bulletcounter, 2) ? gun = spider.gun1 : gun = spider.gun2;
            v = gettaginfo(gun, gettagindex(gun, "barrels"));
            v_forward = normalize(v_forward);
            v += v_forward * 50;

            fireBullet (v, v_forward, autocvar_g_vehicle_spiderbot_minigun_spread, autocvar_g_vehicle_spiderbot_minigun_damage,
                autocvar_g_vehicle_spiderbot_minigun_spread, DEATH_SBMINIGUN, 0);

            sound (gun, CH_WEAPON_A, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
            trailparticles(self, particleeffectnum("spiderbot_minigun_trail"), v, trace_endpos);
            pointparticles(particleeffectnum("spiderbot_minigun_muzzleflash"), v, v_forward * 2500, 1);

            self = spider;

            spider.vehicle_ammo1 -= autocvar_g_vehicle_spiderbot_minigun_ammo_cost;
            spider.tur_head.attack_finished_single = time + autocvar_g_vehicle_spiderbot_minigun_refire;
            player.vehicle_ammo1 = (spider.vehicle_ammo1 / autocvar_g_vehicle_spiderbot_minigun_ammo_max) * 100;
            spider.gun1.angles_z += 45;
            spider.gun2.angles_z -= 45;
            if(spider.gun1.angles_z >= 360)
            {
                spider.gun1.angles_z = 0;
                spider.gun2.angles_z = 0;
            }
        }
    }
    else
        vehicles_regen(cnt, vehicle_ammo1, autocvar_g_vehicle_spiderbot_minigun_ammo_max,
                                           autocvar_g_vehicle_spiderbot_minigun_ammo_regen_pause,
                                           autocvar_g_vehicle_spiderbot_minigun_ammo_regen, frametime);
        

    spiderbot_rocket_do();

    if(self.vehicle_flags  & VHF_SHIELDREGEN)
        vehicles_regen(dmg_time, vehicle_shield, autocvar_g_vehicle_spiderbot_shield, autocvar_g_vehicle_spiderbot_shield_regen_pause, autocvar_g_vehicle_spiderbot_shield_regen, frametime);

    if(self.vehicle_flags  & VHF_HEALTHREGEN)
        vehicles_regen(dmg_time, vehicle_health, autocvar_g_vehicle_spiderbot_health, autocvar_g_vehicle_spiderbot_health_regen_pause, autocvar_g_vehicle_spiderbot_health_regen, frametime);

    player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
    player.vehicle_ammo2 = spider.tur_head.frame;

    if(spider.gun2.cnt <= time)
        player.vehicle_reload2 = 100;
    else
        player.vehicle_reload2 = 100 - ((spider.gun2.cnt - time) / spider.attack_finished_single) * 100;

    setorigin(player, spider.origin + '0 0 1' * SPIDERBOT_MAX_z);
    player.velocity = spider.velocity;

    VEHICLE_UPDATE_PLAYER(health, spiderbot);

    if(self.vehicle_flags & VHF_HASSHIELD)
        VEHICLE_UPDATE_PLAYER(shield, spiderbot);

#if 1 // 0 to enable per-gun impact aux crosshairs
    // Avarage gun impact point's -> aux cross
    vector vf;
    ad = gettaginfo(spider.gun1, gettagindex(spider.gun1, "barrels"));
    vf = v_forward;
    ad += gettaginfo(spider.gun2, gettagindex(spider.gun2, "barrels"));
    vf += v_forward;
    ad = ad * 0.5;
    v_forward = vf * 0.5;
    traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
    UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 0);

#else
    ad = gettaginfo(spider.gun1, gettagindex(spider.gun1, "barrels"));
    traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
    UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 0);

    ad = gettaginfo(spider.gun2, gettagindex(spider.gun2, "barrels"));
    traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
    UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 1);
#endif

    self = player;
    return 1;
}

void spiderbot_think()
{
    if(self.flags & FL_ONGROUND)
        movelib_beak_simple(autocvar_g_vehicle_spiderbot_speed_stop);

    self.nextthink = time;
}

void spiderbot_enter()
{
    self.movetype   = MOVETYPE_WALK;

    self.owner.vehicle_health = (self.vehicle_health / autocvar_g_vehicle_spiderbot_health);
    self.owner.vehicle_shield = (self.vehicle_shield / autocvar_g_vehicle_spiderbot_shield);

    if(self.owner.flagcarried)
    {
        setattachment(self.owner.flagcarried, self.tur_head, ""); 
        setorigin(self.owner.flagcarried, '-20 0 120'); 
    }
}

void spiderbot_exit(float eject)
{
    entity e;
    vector spot;
    
    e = findchain(classname,"spiderbot_rocket");
    while(e)
    {
        if(e.owner == self.owner)
        {
            e.realowner = self.owner;
            e.owner = world;
        }
        e = e.chain;
    }

    self.velocity   = '0 0 0';
    self.think      = spiderbot_think;
    self.nextthink  = time;
    self.frame      = 5;
    self.movetype   = MOVETYPE_WALK;
    
    if not (self.owner)
        return;

	makevectors(self.angles);
	if(eject)
	{
	    spot = self.origin + v_forward * 100 + '0 0 64';
	    spot = vehicles_findgoodexit(spot);
	    setorigin(self.owner , spot);
	    self.owner.velocity = (v_up + v_forward * 0.25) * 750;
	}
	else
	{
	    spot = self.origin - v_forward * 200 + '0 0 64';
	    spot = vehicles_findgoodexit(spot);
	    setorigin(self.owner , spot);
	}
        
    self.owner = world;
}

void spiderbot_spawn()
{
    self.frame              = 5;
    self.tur_head.frame     = 1;
    self.think              = spiderbot_think;
    self.nextthink          = time;
    self.vehicle_health     = autocvar_g_vehicle_spiderbot_health;
    self.vehicle_shield     = autocvar_g_vehicle_spiderbot_shield;
    self.movetype           = MOVETYPE_WALK;
    self.solid              = SOLID_SLIDEBOX;
    self.alpha              = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = 1;
    self.tur_head.angles    = '0 0 0';

    setorigin(self, self.pos1 + '0 0 128');
    self.angles = self.pos2;
}

void spiderbot_headfade()
{
	self.think = spiderbot_headfade;
	self.nextthink = self.fade_time;
	self.alpha = 1 - (time - self.fade_time) * self.fade_rate;

    if(self.cnt < time || self.alpha < 0.1)
    {
        if(self.alpha > 0.1)
        {
            sound (self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
            pointparticles(particleeffectnum("explosion_big"), self.origin + '0 0 100', '0 0 0', 1);
        }
        remove(self);
    }
}

void spiderbot_blowup()
{
    if(self.cnt > time)
    {
        if(random() < 0.1)
        {
            sound (self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
            pointparticles(particleeffectnum("explosion_small"), randomvec() * 80 + (self.origin + '0 0 100'), '0 0 0', 1);
        }
        self.nextthink = time + 0.1;
        return;
    }
    
    entity h, g1, g2, b;
    b = spawn();
    h = spawn();
    g1 = spawn();
    g2 = spawn();

    setmodel(b,  "models/vehicles/spiderbot.dpm");
    setmodel(h,  "models/vehicles/spiderbot_top.dpm");
    setmodel(g1, "models/vehicles/spiderbot_barrels.dpm");
    setmodel(g2, "models/vehicles/spiderbot_barrels.dpm");

    setorigin(b, self.origin);
    b.frame         = 11;
    b.angles        = self.angles;
    setsize(b, self.mins, self.maxs);

    setorigin(h, gettaginfo(self, gettagindex(self, "tag_head")));
    h.movetype      = MOVETYPE_BOUNCE;
    h.solid         = SOLID_BBOX;
    h.velocity      = v_up * (500 + random() * 500) + randomvec() * 128;
    h.modelflags    = MF_ROCKET;
    h.effects       = EF_FLAME | EF_LOWPRECISION;
    h.avelocity     = randomvec() * 360;

    h.alpha         = 1;
    h.cnt           = time + (3.5 * random());
    h.fade_rate     = 1 / min(autocvar_g_vehicle_spiderbot_respawntime, 10);
    h.fade_time     = time;
    h.think         = spiderbot_headfade;
    h.nextthink     = time;

    setorigin(g1, gettaginfo(self.tur_head, gettagindex(self.tur_head, "tag_hardpoint01")));
    g1.movetype     = MOVETYPE_TOSS;
    g1.solid        = SOLID_CORPSE;
    g1.velocity     = v_forward * 700 + (randomvec() * 32);
    g1.avelocity    = randomvec() * 180;

    setorigin(g2, gettaginfo(self.tur_head, gettagindex(self.tur_head, "tag_hardpoint02")));
    g2.movetype     = MOVETYPE_TOSS;
    g2.solid        = SOLID_CORPSE;
    g2.velocity     = v_forward * 700 + (randomvec() * 32);
    g2.avelocity    = randomvec() * 180;

    h.colormod = b.colormod = g1.colormod = g2.colormod = '-2 -2 -2';

    SUB_SetFade(b,  time + 5, min(autocvar_g_vehicle_spiderbot_respawntime, 1));
    //SUB_SetFade(h,  time, min(autocvar_g_vehicle_spiderbot_respawntime, 10));
    SUB_SetFade(g1, time, min(autocvar_g_vehicle_spiderbot_respawntime, 10));
    SUB_SetFade(g2, time, min(autocvar_g_vehicle_spiderbot_respawntime, 10));

    RadiusDamage (self, self, 250, 15, 250, world, 250, DEATH_SBBLOWUP, world);

    self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = -1;
    self.movetype   = MOVETYPE_NONE;
    self.deadflag   = DEAD_DEAD;
    self.solid      = SOLID_NOT;
    self.tur_head.effects  &~=  EF_FLAME;
	self.vehicle_hudmodel.viewmodelforclient = self;
}

void spiderbot_die()
{
    self.health             = 0;
    self.event_damage       = SUB_Null;
    self.takedamage         = DAMAGE_NO;
    self.touch              = SUB_Null;
    self.cnt                = 3.4 + time + random() * 2;
    self.think              = spiderbot_blowup;
    self.nextthink          = time;
    self.deadflag           = DEAD_DYING;
	self.frame              = 5;
	self.tur_head.effects  |= EF_FLAME;
	self.colormod           = self.tur_head.colormod = '-1 -1 -1';
	self.frame              = 10;
	self.movetype           = MOVETYPE_TOSS;
}

void vewhicle_spiderbot_dinit()
{
    if not (vehicle_initialize(
             "Spiderbot",
             "models/vehicles/spiderbot.dpm",
             "models/vehicles/spiderbot_top.dpm",
             "models/vehicles/spiderbot_cockpit.dpm",
             "tag_head", "tag_hud", "",
             HUD_SPIDERBOT,
             SPIDERBOT_MIN, SPIDERBOT_MAX,
             FALSE,
             spiderbot_spawn, autocvar_g_vehicle_spiderbot_respawntime,
             spiderbot_frame,
             spiderbot_enter, spiderbot_exit,
             spiderbot_die,   spiderbot_think,
             FALSE))
    {
        remove(self);
        return;
    }


    self.gun1               = spawn();
    self.gun2               = spawn();

    setmodel(self.gun1, "models/vehicles/spiderbot_barrels.dpm");
    setmodel(self.gun2, "models/vehicles/spiderbot_barrels.dpm");

    setattachment(self.gun1, self.tur_head, "tag_hardpoint01");
    setattachment(self.gun2, self.tur_head, "tag_hardpoint02");

    self.gravity            = 2;
    self.mass               = 5000;
}

void spawnfunc_vehicle_spiderbot()
{
    self.vehicle_flags |= VHF_DMGSHAKE;
    //self.vehicle_flags |= VHF_DMGROLL;
    //self.vehicle_flags |= VHF_DMGHEADROLL;
    
    precache_model ( "models/vhshield.md3");
    precache_model ( "models/vehicles/spiderbot.dpm");
    precache_model ( "models/vehicles/spiderbot_top.dpm");
    precache_model ( "models/vehicles/spiderbot_barrels.dpm");
    precache_model ( "models/vehicles/spiderbot_cockpit.dpm");
    precache_model ( "models/uziflash.md3");

    precache_sound ( "weapons/uzi_fire.wav" );
    precache_sound ( "weapons/rocket_impact.wav");
    
    precache_sound ( "vehicles/spiderbot_die.wav");
    precache_sound ( "vehicles/spiderbot_idle.wav");
    precache_sound ( "vehicles/spiderbot_jump.wav");
    precache_sound ( "vehicles/spiderbot_strafe.wav");
    precache_sound ( "vehicles/spiderbot_walk.wav");
    precache_sound ( "vehicles/spiderbot_land.wav");

    vehicles_configcheck("vehicle_spiderbot.cfg", autocvar_g_vehicle_spiderbot_health);
    if(autocvar_g_vehicle_spiderbot_shield)
        self.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_spiderbot_shield_regen)
        self.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_spiderbot_health_regen)
        self.vehicle_flags |= VHF_HEALTHREGEN;
    
    self.think = vewhicle_spiderbot_dinit;    
    self.nextthink = time + (autocvar_g_vehicles_delayspawn ? autocvar_g_vehicle_spiderbot_respawntime + (random() * autocvar_g_vehicles_delayspawn_jitter) : 0.5);
}
#endif // SVQC
