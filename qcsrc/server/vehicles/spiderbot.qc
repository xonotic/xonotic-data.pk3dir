const vector spiderbot_MIN = '-75 -75 10';
const vector spiderbot_MAX  = '75 75 110';

float autocvar_g_vehicle_spiderbot_respawntime;

float autocvar_g_vehicle_spiderbot_crush_dmg;
float autocvar_g_vehicle_spiderbot_crush_force;

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

float autocvar_g_vehicle_spiderbot_minigun_cooldown;
float autocvar_g_vehicle_spiderbot_minigun_damage;
float autocvar_g_vehicle_spiderbot_minigun_heat;
float autocvar_g_vehicle_spiderbot_minigun_refire;
float autocvar_g_vehicle_spiderbot_minigun_spread;
float autocvar_g_vehicle_spiderbot_movement_inertia;

float autocvar_g_vehicle_spiderbot_rocket_damage;
float autocvar_g_vehicle_spiderbot_rocket_edgedamage;
float autocvar_g_vehicle_spiderbot_rocket_force;
float autocvar_g_vehicle_spiderbot_rocket_health;
float autocvar_g_vehicle_spiderbot_rocket_lifetime;
float autocvar_g_vehicle_spiderbot_rocket_noise;
float autocvar_g_vehicle_spiderbot_rocket_radius;
float autocvar_g_vehicle_spiderbot_rocket_refire;
float autocvar_g_vehicle_spiderbot_rocket_reload;
float autocvar_g_vehicle_spiderbot_rocket_speed;
float autocvar_g_vehicle_spiderbot_rocket_turnrate;

float autocvar_g_vehicle_spiderbot_shield;
float autocvar_g_vehicle_spiderbot_speed_stop;
float autocvar_g_vehicle_spiderbot_speed_strafe;
float autocvar_g_vehicle_spiderbot_speed_walk;
float autocvar_g_vehicle_spiderbot_turnspeed;


float autocvar_g_vehicle_spiderbot_springlength;
float autocvar_g_vehicle_spiderbot_springup;
float autocvar_g_vehicle_spiderbot_springblend;

void spiderbot_exit(float eject);
void spiderbot_enter();
void spiderbot_spawn();

void spiderbot_rocket_explode()
{
    vector org2;

    if(self.event_damage != SUB_Null)
    {
        self.event_damage = SUB_Null;
        self.think = spiderbot_rocket_explode;
        self.nextthink = time;
        return;
    }

    sound (self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
    org2 = findbetterlocation (self.origin, 16);
    pointparticles(particleeffectnum("rocket_explode"), org2, '0 0 0', 1);
    w_deathtypestring = "dident escape the rocket barrage";

    if(!self.owner)
        self.owner = self.realowner;

    RadiusDamage (self, self.owner,
        autocvar_g_vehicle_spiderbot_rocket_damage,
        autocvar_g_vehicle_spiderbot_rocket_edgedamage,
        autocvar_g_vehicle_spiderbot_rocket_radius, world,
        autocvar_g_vehicle_spiderbot_rocket_force, DEATH_SBROCKET, world);

    remove (self);
}

void spiderbot_rocket_touch()
{
    if(self.owner)
    {
        if(other == self.owner.vehicle)
            return;

        if(other == self.owner.vehicle.tur_head)
            return;
    }

    PROJECTILE_TOUCH;
    spiderbot_rocket_explode();
}

void spiderbot_rocket_unguided()
{
    vector newdir,olddir;

    self.nextthink  = time;


    olddir = normalize(self.velocity);
    newdir = normalize(self.pos1 - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(self);

    if (self.owner.deadflag != DEAD_NO || self.cnt < time)
        spiderbot_rocket_explode();

}

void spiderbot_rocket_guided()
{
    vector newdir, olddir;

    self.nextthink  = time;

    if not (self.owner.vehicle)
        self.think = spiderbot_rocket_unguided;

    crosshair_trace(self.owner);
    olddir = normalize(self.velocity);
    newdir = normalize(trace_endpos - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
    self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

    UpdateCSQCProjectile(self);

    if (self.owner.deadflag != DEAD_NO || self.cnt < time)
        spiderbot_rocket_explode();
}

void spiderbot_rocket_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
    self.health -= damage;
    self.velocity += force;
    if(self.health < 1)
        spiderbot_rocket_explode();
}

void spiderbot_guide_release()
{
    entity rkt;
    rkt = findchainentity(owner,self.owner);
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

    sound (self, CHAN_WEAPON, "weapons/rocket_fire.wav", VOL_BASE, ATTN_NORM);
    rocket                    = spawn ();
    setsize (rocket, '-1 -1 -1', '1 1 1'); // give it some size so it can be shot
    setorigin(rocket,gettaginfo(self.tur_head,gettagindex(self.tur_head,"tag_fire")));
    te_explosion (rocket.origin);

    crosshair_trace(self.owner);

    rocket.classname       = "spiderbot_rocket";
    rocket.bot_dodge       = TRUE;
    rocket.bot_dodgerating = autocvar_g_vehicle_spiderbot_rocket_damage;
    rocket.cnt             = time + autocvar_g_vehicle_spiderbot_rocket_lifetime;
    rocket.health          = autocvar_g_vehicle_spiderbot_rocket_health;
    rocket.takedamage      = DAMAGE_AIM;
    rocket.event_damage    = spiderbot_rocket_damage;
    rocket.owner           = self.owner;
    rocket.nextthink       = time;
    rocket.movetype        = MOVETYPE_FLYMISSILE;
    rocket.velocity        = normalize(v_forward + (v_up * 0.5) + randomvec() * 0.25) * autocvar_g_vehicle_spiderbot_rocket_speed;
    rocket.angles          = vectoangles(rocket.velocity);
    rocket.think           = spiderbot_rocket_guided;
    rocket.touch           = spiderbot_rocket_touch;
    rocket.flags           = FL_PROJECTILE;
    rocket.solid           = SOLID_TRIGGER;
    rocket.pos1            = trace_endpos;

	CSQCProjectile(rocket, FALSE, PROJECTILE_ROCKET, FALSE); // no culling, has fly sound

    self.tur_head.frame += 1;
    if (self.tur_head.frame == 9)
        self.attack_finished_single = autocvar_g_vehicle_spiderbot_rocket_reload;
    else
        self.attack_finished_single = autocvar_g_vehicle_spiderbot_rocket_refire;

    self.gun2.cnt = time + self.attack_finished_single;
}

void spiderbot_minigun_fire(entity gun, float trail)
{
    vector v;
    entity oldself;

    v = gettaginfo(gun, gettagindex(gun,"barrels"));
    v_forward = normalize(v_forward);
    v += v_forward * 50;

    oldself = self;
    self = self.owner;
    fireBullet (v, v_forward, autocvar_g_vehicle_spiderbot_minigun_spread, autocvar_g_vehicle_spiderbot_minigun_damage,
        autocvar_g_vehicle_spiderbot_minigun_spread, DEATH_SBMINIGUN, 0);
    self = oldself;

    if(trail)
    {
        sound (gun, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
        trailparticles(self, particleeffectnum("spiderbot_minigun_trail"), v, trace_endpos);
        pointparticles(particleeffectnum("spiderbot_minigun_muzzleflash"), v, v_forward * 2500, 1);
        pointparticles(particleeffectnum("spiderbot_minigun_impact"), trace_endpos, trace_plane_normal * 2500,1);
    }
}

void spiderbot_miniguns_do()
{
    float ftmp;

    if((self.vehicle_reload1 == 1) || (!self.owner.BUTTON_ATCK))
    {
        ftmp = 1 / autocvar_g_vehicle_spiderbot_minigun_cooldown * sys_frametime;
        self.owner.vehicle_reload1 = max(self.owner.vehicle_reload1 - ftmp, 0);
        if(self.owner.vehicle_reload1 <= 0)
            self.vehicle_reload1 = 0;

        return;
    }

    if (self.owner.BUTTON_ATCK)
    {

        // Animate miniguns
        self.gun1.angles_z += (1440 * sys_frametime);
        self.gun2.angles_z -= (1440 * sys_frametime);
        if(self.gun1.angles_z >= 360)
        {
            self.gun1.angles_z = 0;
            self.gun2.angles_z = 360;
        }

        if (self.tur_head.attack_finished_single < time)
        {
            // Fire bullets, alternating trails left<->right
            self = self.owner;
            if(self.misc_bulletcounter == 1)
            {
                spiderbot_minigun_fire(self.vehicle.gun1, 0);
                spiderbot_minigun_fire(self.vehicle.gun2, 1);
                self.misc_bulletcounter = 0;
            }
            else
            {
                spiderbot_minigun_fire(self.vehicle.gun1, 1);
                spiderbot_minigun_fire(self.vehicle.gun2, 0);
                self.misc_bulletcounter += 1;
            }
            self = self.vehicle;

            ftmp = autocvar_g_vehicle_spiderbot_minigun_refire / autocvar_g_vehicle_spiderbot_minigun_heat;
            self.owner.vehicle_reload1 +=  ftmp;

            if(self.owner.vehicle_reload1 >= 1)
            {
                self.vehicle_reload1 = 1;
                self.owner.vehicle_reload1 = 1;
                self.tur_head.attack_finished_single = autocvar_g_vehicle_spiderbot_minigun_cooldown + time;
            }
            else
                self.tur_head.attack_finished_single = autocvar_g_vehicle_spiderbot_minigun_refire + time;
        }
        return;
    }
}

float spiderbot_frame()
{
    vector ad;
    entity player, spider;
    float ftmp;

    player = self;
    spider = self.vehicle;

    player.BUTTON_ZOOM      = 0;
    player.BUTTON_CROUCH    = 0;
    player.switchweapon     = 0;

    if(player.BUTTON_USE)
    {
        self = spider;
        vehicles_exit(VHEF_NORMAL);
        self = player;
        return 0;
    }

    self = spider;

    crosshair_trace(player);
    UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload2) + ('0 1 0' * (1 - player.vehicle_reload2)), 2);
    ad = vectoangles(normalize(trace_endpos - gettaginfo(spider.tur_head,gettagindex(spider.tur_head,"tag_hud")))) - (spider.tur_head.angles + spider.angles);
    if(ad_x > 180) ad_x -= 360;
    if(ad_x < -180) ad_x += 360;
    if(ad_y > 180) ad_y -= 360;
    if(ad_y < -180) ad_y += 360;

    // Rotate head
    ftmp = autocvar_g_vehicle_spiderbot_head_turnspeed * sys_frametime;
    ad_y = bound(-ftmp, ad_y, ftmp);
    spider.tur_head.angles_y = bound(autocvar_g_vehicle_spiderbot_head_turnlimit * -1, spider.tur_head.angles_y + ad_y, autocvar_g_vehicle_spiderbot_head_turnlimit);

    // Pitch head
    ftmp = autocvar_g_vehicle_spiderbot_head_pitchspeed * sys_frametime;
    ad_x = bound(-ftmp, ad_x, ftmp);
    spider.tur_head.angles_x = bound(autocvar_g_vehicle_spiderbot_head_pitchlimit_down, spider.tur_head.angles_x + ad_x, autocvar_g_vehicle_spiderbot_head_pitchlimit_up);

    // Turn Body
    ftmp = autocvar_g_vehicle_spiderbot_turnspeed * sys_frametime;
    ftmp = bound(-ftmp, spider.tur_head.angles_y, ftmp);

    //fixedmakevectors(self.angles);
    // Not sure why this works better, but it does.
    spider.tur_head.angles_x *= -1;
    spider.angles_x *= -1;
    makevectors(spider.angles);
    spider.tur_head.angles_x *= -1;
    spider.angles_x *= -1;

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
        if(player.BUTTON_JUMP && self.tur_head.wait < time)
        {
            self.tur_head.wait = time + 2;
            player.BUTTON_JUMP = 0;
            spider.velocity   = v_forward * 700 + v_up * 600;
            spider.frame = 4;
        }
        else
        {
            if(vlen(player.movement) == 0)
            {
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
                }
            }
        }
    }

    self.angles_x = bound(-60, self.angles_x, 60);
    self.angles_z = bound(-60, self.angles_z, 60);

    spiderbot_miniguns_do();
    spiderbot_rocket_do();

    if(self.vehicle_flags  & VHF_SHIELDREGEN)
        vehicles_regen(dmg_time, vehicle_shield, autocvar_g_vehicle_spiderbot_shield, autocvar_g_vehicle_spiderbot_shield_regen_pause, autocvar_g_vehicle_spiderbot_shield_regen, frametime);

    if(self.vehicle_flags  & VHF_HEALTHREGEN)
        vehicles_regen(dmg_time, vehicle_health, autocvar_g_vehicle_spiderbot_health, autocvar_g_vehicle_spiderbot_health_regen_pause, autocvar_g_vehicle_spiderbot_health_regen, frametime);

    player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
    player.vehicle_ammo2 = spider.tur_head.frame;

    if(spider.gun2.cnt <= time)
        player.vehicle_reload2 = 1;
    else
        player.vehicle_reload2 = 1 - ((spider.gun2.cnt - time) / spider.attack_finished_single);

    setorigin(player, spider.origin + '0 0 64');
    player.velocity = spider.velocity;

    VEHICLE_UPDATE_PLAYER(health, spiderbot);

    if(self.vehicle_flags & VHF_HASSHIELD)
        VEHICLE_UPDATE_PLAYER(shield, spiderbot);

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


    /*
    ad = gettaginfo(spider.gun1, gettagindex(spider.gun1, "barrels"));
    traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
    UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 0);

    ad = gettaginfo(spider.gun2, gettagindex(spider.gun2, "barrels"));
    traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
    UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 1);
    */

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
    self.owner.vehicle_health = (self.vehicle_health / autocvar_g_vehicle_spiderbot_health);
    self.owner.vehicle_shield = (self.vehicle_shield / autocvar_g_vehicle_spiderbot_shield);
}

void spiderbot_exit(float eject)
{
    entity e;

    vehicles_setreturn(autocvar_g_vehicle_spiderbot_respawntime, spiderbot_spawn);

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

    if not (self.owner)
        return;

	makevectors(self.angles);
	if(eject)
	{
	    setorigin(self.owner ,self.origin + v_forward * 100 + '0 0 64');
	    self.owner.velocity = (v_up + v_forward * 0.25) * 750;
	}
	else
        setorigin(self.owner, self.origin - v_forward * 200 + '0 0 64');

    self.owner = world;
}

// Better way of determening whats crushable needed! (fl_crushable?)
float spiderbot_crushable(entity e)
{
    if(e.classname == "corpse")
        return 1;

    if(e.classname == "player")
        return 1;

    if(e.classname == "monster_zombie")
        return 1;

    return 0;
}

void spiderbot_touch()
{
    if(self.owner)
    {
        if(vlen(self.velocity) == 0)
            return;

        if not (spiderbot_crushable(other))
            return;

        //todo: add check for velocity/angle here (so we dont cush players runing into us from behind)

        Damage(other, self, self.owner,autocvar_g_vehicle_spiderbot_crush_dmg,DEATH_SBCRUSH, '0 0 0', normalize(other.origin - self.origin) * autocvar_g_vehicle_spiderbot_crush_force);
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


void spiderbot_spawn()
{

    setsize(self, spiderbot_MIN, spiderbot_MAX);

    self.frame              = 5;
    self.think              = spiderbot_think;
    self.nextthink          = time;
    self.owner              = world;
    self.velocity           = '0 0 0';
    self.vehicle_health     = autocvar_g_vehicle_spiderbot_health;
    self.vehicle_shield     = autocvar_g_vehicle_spiderbot_shield;
    self.event_damage       = vehicles_damage;
    self.iscreature         = TRUE;
    self.movetype           = MOVETYPE_WALK;
    self.solid              = SOLID_SLIDEBOX;
    self.takedamage         = DAMAGE_AIM;
    self.touch              = spiderbot_touch;
    self.alpha              = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = 1;
    self.tur_head.angles    = '0 0 0';
	self.colormap           = 1024;
	self.tur_head.colormap  = 1024;
	self.deadflag           = DEAD_NO;
    self.bot_attack         = TRUE;
    self.flags              |= FL_NOTARGET;
    self.tur_head.frame     = 1;
    self.vehicle_hudmodel.viewmodelforclient = self;

    setorigin(self, self.pos1 + '0 0 128');
    self.angles = self.pos2;

    if (self.team == COLOR_TEAM1)
        self.colormod = '1.4 0.8 0.8';
    else if (self.team == COLOR_TEAM2)
        self.colormod = '0.8 0.8 1.4';
    else
        self.colormod = '0 0 0';

    self.tur_head.colormod = self.colormod;

    vehicles_common_spawn();

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
            sound (self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
            pointparticles(particleeffectnum("rocket_explode"), self.origin + '0 0 100', '0 0 0', 1);
        }
        remove(self);
    }
}

void spiderbot_blowup()
{
    float i;
    sound (self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);

    for(i = 0; i < 5; ++i)
    {
        pointparticles(particleeffectnum("rocket_explode"), self.origin + (randomvec() * 100) + '0 0 100', '0 0 0', 1);
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
    b.frame         = 5;

    h.colormod = b.colormod = g1.colormod = g2.colormod = '-2 -2 -2';

    SUB_SetFade(b,  time, min(autocvar_g_vehicle_spiderbot_respawntime, 10));
    //SUB_SetFade(h,  time, min(autocvar_g_vehicle_spiderbot_respawntime, 10));
    SUB_SetFade(g1, time, min(autocvar_g_vehicle_spiderbot_respawntime, 10));
    SUB_SetFade(g2, time, min(autocvar_g_vehicle_spiderbot_respawntime, 10));

    RadiusDamage (self, self, 250, 15, 250, world, 250, DEATH_SBBLOWUP, world);

    self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = -1;
    self.nextthink  = time + autocvar_g_vehicle_spiderbot_respawntime;
    self.think      = spiderbot_spawn;
    self.movetype   = MOVETYPE_NONE;
    self.deadflag   = DEAD_DEAD;
    self.solid      = SOLID_NOT;
    self.tur_head.effects  &~=  EF_FLAME;
	self.vehicle_hudmodel.viewmodelforclient = self;

    //setorigin(self, self.tur_aimpos);
}

void spiderbot_die()
{
    sound (self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
    pointparticles(particleeffectnum("rocket_explode"), self.origin + '0 0 100', '0 0 0', 1);

    self.health         = 0;
    self.event_damage   = SUB_Null;
    self.takedamage     = DAMAGE_NO;
    self.touch          = SUB_Null;
    self.nextthink      = 1 + time + random() * 2;
    self.think          = spiderbot_blowup;
    self.deadflag       = DEAD_DYING;
	self.frame          = 5;
	self.tur_head.effects        |= EF_FLAME;
	self.colormod = self.tur_head.colormod = '-1 -1 -1';

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
             spiderbot_MIN, spiderbot_MAX,
             FALSE,
             spiderbot_spawn, spiderbot_frame,
             spiderbot_enter, spiderbot_exit,
             spiderbot_die,   spiderbot_think))
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
}

void spawnfunc_vehicle_spiderbot()
{
    precache_model ( "models/vhshield.md3");
    precache_model ( "models/vehicles/spiderbot.dpm");
    precache_model ( "models/vehicles/spiderbot_top.dpm");
    precache_model ( "models/vehicles/spiderbot_barrels.dpm");
    precache_model ( "models/vehicles/spiderbot_cockpit.dpm");
    precache_model ( "models/uziflash.md3");

    precache_sound ( "weapons/rocket_impact.wav" );
    precache_sound ( "weapons/uzi_fire.wav" );
    precache_sound ( "weapons/rocket_impact.wav" );

    vehicles_configcheck("vehicle_spiderbot.cfg", autocvar_g_vehicle_spiderbot_health);
    if(autocvar_g_vehicle_spiderbot_shield)
        self.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_spiderbot_shield_regen)
        self.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_spiderbot_health_regen)
        self.vehicle_flags |= VHF_HEALTHREGEN;

    self.think = vewhicle_spiderbot_dinit;
    self.nextthink = time + 0.5;
}
