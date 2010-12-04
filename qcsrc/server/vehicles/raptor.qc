#define RAPTOR_MIN '-40 -40 0'
#define RAPTOR_MAX '40 40 40'

float raptor_movestyle;
float raptor_turnspeed;
float raptor_turnroll;
float raptor_pitchspeed;
float raptor_speed_forward;
float raptor_speed_strafe;
float raptor_speed_up;
float raptor_speed_down;

float raptor_bomblet_waves;
float raptor_bomblet_wavefirst;
float raptor_bomblet_wavenext;
float raptor_bomblet_wawespread;
float raptor_bomblets;
float raptor_bomblet_damage;
float raptor_bomblet_edgedamage;
float raptor_bomblet_radius;
float raptor_bomblet_force;
float raptor_bombs_refire;

float raptor_beam_dps;
float raptor_beam_fops;
float raptor_beam_aps;
float raptor_beam_size;
float raptor_beam_leangth;
float raptor_beam_refire;

float raptor_shield_max;
float raptor_shield_regen;

float raptor_health_max;
float raptor_health_regen;

float raptor_energy_max;
float raptor_energy_regen;

void raptor_spawn();
void raptor_return();
float raptor_pplug();
float raptor_takeoff();
float raptor_land();

.entity bomb1;
.entity bomb2;

float raptor_altitude(float amax)
{
	tracebox(self.origin, self.mins, self.maxs, '0 0 -1' * amax, TRUE, self);
	if(trace_fraction == 1)
        return amax+1;
    else
        return vlen(self.origin - trace_endpos);
}

void raptor_loadsettings()
{
    raptor_movestyle     = CCVAR("_movestyle");
    raptor_turnspeed     = CCVAR("_turnspeed");
    raptor_turnroll      = CCVAR("_turnroll");
    raptor_pitchspeed    = CCVAR("_pitchspeed");
    raptor_speed_forward = CCVAR("_speed_forward");
    raptor_speed_strafe  = CCVAR("_speed_strafe");
    raptor_speed_up      = CCVAR("_speed_up");
    raptor_speed_down    = CCVAR("_speed_down");

    raptor_bomblet_waves      = CCVAR("_bomblet_waves ");
    raptor_bomblet_wavefirst  = CCVAR("_bomblet_wavefirst");
    raptor_bomblet_wavenext   = CCVAR("_bomblet_wavenext");
    raptor_bomblet_wawespread = CCVAR("_bomblet_wawespread");
    raptor_bomblets           = CCVAR("_bomblets");
    raptor_bomblet_damage     = CCVAR("_bomblet_damage");
    raptor_bomblet_edgedamage = CCVAR("_bomblet_edgedamage");
    raptor_bomblet_radius     = CCVAR("_bomblet_radius");
    raptor_bomblet_force      = CCVAR("_bomblet_force ");
    raptor_bombs_refire       = CCVAR("_bombs_refire");

    raptor_beam_dps     = CCVAR("_beam_dps");
    raptor_beam_fops    = CCVAR("_beam_fops");
    raptor_beam_aps     = CCVAR("_beam_aps");
    raptor_beam_size    = CCVAR("_beam_size");
    raptor_beam_leangth = CCVAR("_beam_length");
    raptor_beam_refire  = CCVAR("_beam_refire");

    raptor_shield_max    = CCVAR("_shield");
    raptor_shield_regen  = CCVAR("_shield_regen");

    raptor_health_max    = CCVAR("_health");
    raptor_health_regen  = CCVAR("_health_regen");

    raptor_energy_max    = CCVAR("_energy");
    raptor_energy_regen  = CCVAR("_energy_regen");
}

void raptor_bombs_return()
{
    self.owner.bomb1.alpha = 1;
    self.owner.bomb2.alpha = 1;
    remove(self);
}

void raptor_bomblet_boom()
{
    if(other.enemy == self.enemy)
        return;

    pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);
    RadiusDamage (self, self.enemy, raptor_bomblet_damage, raptor_bomblet_edgedamage, raptor_bomblet_radius, world, raptor_bomblet_force, DEATH_SBROCKET, world);
    remove(self);
}

void raptor_bomb_burst()
{
    self.angles = vectoangles(self.velocity);

    if(self.cnt < time)
    {
        entity bomblet;
        float i,v;
        vector d;

        makevectors(self.angles);
        v = vlen(self.velocity) + random();
        d = normalize(self.velocity);
        pointparticles(particleeffectnum("rocket_explode"), self.origin, '0 0 0', 1);

        for(i = 0; i < raptor_bomblets; ++i)
        {

            bomblet = spawn();
            setorigin(bomblet,self.origin);

            setmodel(bomblet,"models/vehicles/raptor_bomb.dpm");
            bomblet.scale = 0.5;

            bomblet.owner = self.owner;
            bomblet.enemy = self.enemy;

            bomblet.solid = SOLID_TRIGGER;
            bomblet.movetype    = MOVETYPE_BOUNCE;
            bomblet.touch = raptor_bomblet_boom;

            bomblet.think = raptor_bomblet_boom;
            bomblet.nextthink = time + 5;

            //bomblet.modelflags = MF_ROCKET;
            bomblet.modelflags = MF_GRENADE;

            bomblet.velocity =  normalize(d + randomvec() * raptor_bomblet_wawespread) * v;

            bomblet.angles = vectoangles(bomblet.velocity);
        }

        self.wait -= 1;
        if(self.wait <= 0)
        {
            remove(self);
            return;
        }

        self.cnt = time + raptor_bomblet_wavenext;
    }

    self.nextthink = time;
}

void raptor_bomb_touch()
{
    raptor_bomb_burst();
}

void raptor_bombdrop()
{
    entity bomb_1, bomb_2;

    self.bomb1.alpha = 0.25;
    self.bomb2.alpha = 0.25;

    bomb_1 = spawn();
    bomb_2 = spawn();

    setmodel(bomb_1,"models/vehicles/raptor_bomb.dpm");
    setmodel(bomb_2,"models/vehicles/raptor_bomb.dpm");

    setorigin(bomb_1, gettaginfo(self, gettagindex(self, "bombmount_left")));
    setorigin(bomb_2, gettaginfo(self, gettagindex(self, "bombmount_right")));

    bomb_1.movetype  = bomb_2.movetype    = MOVETYPE_TOSS;
    bomb_1.velocity  = bomb_2.velocity    = self.velocity;
    bomb_1.touch     = bomb_2.touch       = raptor_bomb_touch;
    bomb_1.think     = bomb_2.think       = raptor_bomb_burst;
    bomb_1.nextthink = bomb_2.nextthink   = time;
    bomb_1.cnt       = bomb_2.cnt         = time + raptor_bomblet_wavefirst;
    bomb_1.wait       = bomb_2.wait       = raptor_bomblet_waves;

    bomb_1.avelocity = bomb_2.avelocity   = '0 0 180';
    bomb_1.owner     = bomb_2.owner       = self;
    bomb_1.enemy     = bomb_2.enemy       = self.owner;
    bomb_1.angles    = bomb_2.angles      = self.angles;
    bomb_1.solid     = bomb_2.solid      = SOLID_BBOX;

    bomb_1 = spawn();
    bomb_1.owner = self;
    bomb_1.think = raptor_bombs_return;
    bomb_1.nextthink = time + raptor_bombs_refire;
}

void raptor_animator_think()
{
    self.owner.frame += 1;
    if(self.owner.frame == self.cnt)
        remove(self);
    else
        self.nextthink = time + self.wait;
}

void raptor_setanim(float start, float end, float length)
{
    entity ani;
    if(self.tur_head.enemy)
        ani = self.tur_head.enemy;
    else
        ani = spawn();

    self.tur_head.enemy = ani;
    ani.owner = self;
    self.frame = start;
    ani.cnt = end;
    ani.wait = sys_frametime / length;
    ani.think = raptor_animator_think;
    ani.nextthink = time + ani.wait;
}

void raptor_beam (vector start, vector end, vector smin, vector smax, float bforce, float f_dmg, float deathtype)
{
    vector hitloc, force, endpoint, dir;
    entity ent;

    dir = normalize(end - start);
    force = dir * bforce;

    // go a little bit into the wall because we need to hit this wall later
    end = end + dir;

    // trace multiple times until we hit a wall, each obstacle will be made unsolid.
    // note down which entities were hit so we can damage them later
    while (1)
    {
        tracebox(start, smin, smax, end, FALSE, world);

        // if it is world we can't hurt it so stop now
        if (trace_ent == world || trace_fraction == 1)
            break;

        if (trace_ent.solid == SOLID_BSP)
            break;

        // make the entity non-solid so we can hit the next one
        trace_ent.railgunhit = TRUE;
        trace_ent.railgunhitloc = end;
        trace_ent.railgunhitsolidbackup = trace_ent.solid;

        // make the entity non-solid
        trace_ent.solid = SOLID_NOT;
    }

    endpoint = trace_endpos;

    // find all the entities the railgun hit and hurt them
    ent = findchainfloat(railgunhit, TRUE);
    while (ent)
    {
        // get the details we need to call the damage function
        ent.solid = ent.railgunhitsolidbackup;
        hitloc = ent.railgunhitloc;
        ent.railgunhitloc = '0 0 0';
        ent.railgunhitsolidbackup = SOLID_NOT;
        ent.railgunhit = FALSE;

        // apply the damage
        if (ent.takedamage)
            Damage (ent, self, self, f_dmg, deathtype, hitloc, force);

        ent = ent.chain;
    }
    trace_endpos = endpoint;
}


void raptor_enter()
{
    // Remove this when bots know how to use vehicles
    if (clienttype(other) != CLIENTTYPE_REAL)
        return;

    if(teams_matter)
        if(self.team)
            if(self.team != other.team)
                return;

    self.owner = other;
    self.switchweapon = other.switchweapon;

    self.event_damage          = vehicle_stdproc_damage;
    self.colormap              = self.owner.colormap;
    self.vehicle_hudmodel.viewmodelforclient = self.owner;
    self.nextthink             = 0;
    self.owner.angles          = self.angles;
    self.owner.takedamage      = DAMAGE_NO;
    self.owner.solid           = SOLID_NOT;
    self.owner.movetype        = MOVETYPE_NOCLIP;
    self.owner.alpha           = -1;
    self.owner.PlayerPhysplug  = raptor_takeoff;
    self.owner.vehicle         = self;
    self.owner.event_damage    = SUB_Null;
    self.owner.hud             = HUD_RAPTOR;
    self.owner.vehicle_health  = self.vehicle_health / raptor_health_max;
    self.owner.vehicle_shield  = self.vehicle_shield / raptor_shield_max;
    self.owner.view_ofs        = '0 0 1';
    self.owner.vehicle_ammo1   = self.vehicle_ammo1;
    self.owner.vehicle_ammo2   = self.vehicle_ammo2;
    self.owner.vehicle_reload1 = self.vehicle_reload1;
    self.owner.vehicle_reload2 = self.vehicle_reload2;

    other.flags &~= FL_ONGROUND;
    self.flags &~= FL_ONGROUND;

    self.frame = 0;
    raptor_setanim(0, 25, 1);

    self.team                 = self.owner.team;
    self.flags               -= FL_NOTARGET;

    self.velocity = '0 0 1';

    setorigin(other,self.origin + '0 0 32');
    other.velocity = self.velocity;

    other.flags &~= FL_ONGROUND;
    msg_entity = other;
    WriteByte (MSG_ONE, SVC_SETVIEWPORT);
    WriteEntity( MSG_ONE, self.vehicle_viewport);

    WriteByte (MSG_ONE, SVC_SETVIEWANGLES);     // 10 = SVC_SETVIEWANGLES
    WriteAngle(MSG_ONE,  self.angles_x * -1);   // tilt
    WriteAngle(MSG_ONE,  self.angles_y);        // yaw
    WriteAngle(MSG_ONE,  0);                    // roll
}

void raptor_exit(float eject)
{
	self.colormap   = 1024;
	self.flags      = FL_NOTARGET;

    if not (self.owner)
        return;

    msg_entity = self.owner;
    WriteByte (MSG_ONE, SVC_SETVIEWPORT);
    WriteEntity( MSG_ONE, self.owner);

    WriteByte (MSG_ONE, SVC_SETVIEWANGLES);    // 10 = SVC_SETVIEWANGLES
    WriteAngle(MSG_ONE,  0);                   // tilt
    WriteAngle(MSG_ONE,  self.angles_y); // yaw
    WriteAngle(MSG_ONE,  0);                   // roll

    if (self.deadflag == DEAD_NO)
    {
        //self.think = racer_exitthink;
        self.nextthink = time;
    }

    self.owner.takedamage     = DAMAGE_AIM;
    self.owner.solid          = SOLID_SLIDEBOX;
    self.owner.movetype       = MOVETYPE_WALK;

    setsize(self.owner,PL_MIN,PL_MAX);

    self.owner.effects        &~= EF_NODRAW;
    self.owner.alpha          = 1;
    self.owner.PlayerPhysplug = SUB_Null;
    self.owner.vehicle        = world;
	self.owner.view_ofs       = PL_VIEW_OFS;
	self.owner.event_damage   = PlayerDamage;
	self.owner.hud            = HUD_NORMAL;
	//self.exteriormodeltoclient = self;

    self.vehicle_hudmodel.viewmodelforclient = self;

	if(eject)
	{
	    makevectors(self.angles);
	    setorigin(self.owner,self.origin + v_forward * 100);
	    self.owner.velocity = (v_up + v_forward * 0.25) * 750;
	}
	else
	{
	    self.owner.velocity = (v_forward) * -150;
        setorigin(self.owner,self.origin - v_forward * 128);
	}

    self.owner = world;

    if (self.deadflag != DEAD_NO)
    {
        entity ret;
        ret = spawn();
        ret.enemy = self;
        ret.think = raptor_return;
        ret.nextthink = time + autocvar_g_vehicle_racer_respawntime;
    }
}


float raptor_pplug()
{
    entity player, vhic;
    float ftmp, ftmp2, energy_used;
    vector df;


    if(autocvar_g_vehicle_raptor_reload)
    {
        raptor_loadsettings();
        cvar_set("g_vehicle_raptor_reload","0");
    }

    player = self;
    vhic   = self.vehicle;
    self    = vhic;

    if(player.BUTTON_USE)
    {
        self = vhic;
        raptor_exit(0);
        self = player;
        return 0;
    }

    if(vhic.deadflag != DEAD_NO)
    {
        self = player;
        player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
        return 1;
    }

    vhic.angles_x *= -1;
    // Rotate Body
    ftmp = raptor_turnspeed * sys_frametime;

    ftmp = bound(-ftmp, shortangle_f(player.v_angle_y - vhic.angles_y, vhic.angles_y), ftmp);

    // Roll
    //ftmp = bound(-90,shortangle_f(player.v_angle_z + ((vhic.angles_y - ftmp2) * raptor_turnroll), vhic.angles_z),90);
    //ftmp = safeangle(vhic.angles_z + ftmp);
    //vhic.angles_z = ftmp;

    // Turn
    vhic.angles_y = anglemods(vhic.angles_y + ftmp);

    // Pitch Body
    ftmp = raptor_pitchspeed  * sys_frametime;

    ftmp = bound(-ftmp, shortangle_f(player.v_angle_x - vhic.angles_x,vhic.angles_x), ftmp);

    vhic.angles_x = bound(-60,anglemods(vhic.angles_x + ftmp),60);
    vhic.angles_x *= -1;

    if(raptor_movestyle == 1)
    {
        ftmp = vhic.angles_z;
        vhic.angles_z = 0;
        ftmp2 = vhic.angles_x;
        vhic.angles_x = 0;
        fixedmakevectors(vhic.angles);
        vhic.angles_z = ftmp;
        vhic.angles_x = ftmp2;
    }
    else
        fixedmakevectors(vhic.angles);

    df = vhic.velocity * -1;

    if(player.movement_x != 0)
    {
        if(player.movement_x > 0)
            df += v_forward  * raptor_speed_forward;
        else if(player.movement_x < 0)
            df -= v_forward  * raptor_speed_forward;
    }

    if(player.movement_y != 0)
    {
        if(player.movement_y < 0)
            df -= v_right * raptor_speed_strafe;
        else if(player.movement_y > 0)
            df += v_right * raptor_speed_strafe;

        vhic.angles_z = bound(-30,vhic.angles_z + (player.movement_y / raptor_speed_strafe),30);
    }
    else
    {
        vhic.angles_z *= 0.95;
        if(vhic.angles_z >= -1 && vhic.angles_z <= -1)
            vhic.angles_z = 0;
    }

    if(player.BUTTON_CROUCH)
        df -=   v_up * raptor_speed_down;
    else if (player.BUTTON_JUMP)
        df +=  v_up * raptor_speed_up;
    //else
        //df_z = vhic.velocity_z * -1;

    vhic.velocity  += df * frametime;
    player.velocity = player.movement  = vhic.velocity;
    setorigin(player,vhic.origin + '0 0 32');

    // Aim the gunz
    /*
    vector target_angle, move_angle, org1, org2, targ;

    makevectors(player.v_angle);

    //targ = (vhic.origin + player.view_ofs) + v_forward * MAX_SHOT_DISTANCE;
    targ = player.cursor_trace_endpos;

    org1 = gettaginfo(vhic.gun1,gettagindex(vhic.gun1, "fire1"));
    org2 = gettaginfo(vhic.gun2,gettagindex(vhic.gun2, "fire1"));

    traceline(vhic.origin + player.view_ofs, targ, FALSE, vhic);
    targ = trace_endpos;

    // Find the direction
    target_angle = vectoangles(normalize(targ - org1)); // And make a angle

    // Find the diffrence between where we currently aim and where we want to aim
    move_angle = target_angle - (vhic.angles + vhic.gun1.angles);
    move_angle = shortangle_vxy(move_angle,(vhic.angles + vhic.gun1.angles));
    vhic.gun1.angles_x = bound(-10, move_angle_x + vhic.gun1.angles_x, 10);
    vhic.gun1.angles_y = bound(-15, move_angle_y + vhic.gun1.angles_y, 15);

    // Find the direction
    target_angle = vectoangles(normalize(targ - org2)); // And make a angle

    move_angle = target_angle - (vhic.angles + vhic.gun2.angles);
    move_angle = shortangle_vxy(move_angle,(vhic.angles + vhic.gun2.angles));
    vhic.gun2.angles_x = bound(-15,move_angle_x + vhic.gun2.angles_x,15);
    vhic.gun2.angles_y = bound(-20,move_angle_y + vhic.gun2.angles_y,20);
	*/
    if(player.BUTTON_ATCK)
    if(vhic.vehicle_energy > (raptor_beam_aps * sys_frametime))
    {
        vector start;
        self = player;

        start = gettaginfo(vhic.gun1, gettagindex(vhic.gun1, "fire1"));
        traceline(start, start + v_forward * MAX_SHOT_DISTANCE, TRUE, player);
        te_lightning1(vhic.gun1, start, trace_endpos);
        raptor_beam(start, trace_endpos, '-1 -1 -1' * raptor_beam_size, '1 1 1' * raptor_beam_size, raptor_beam_fops * sys_frametime, raptor_beam_dps * sys_frametime, DEATH_SBROCKET);


        start = gettaginfo(vhic.gun2, gettagindex(vhic.gun2, "fire1"));
        traceline(start, start + v_forward * MAX_SHOT_DISTANCE, TRUE, player);
        te_lightning1(vhic.gun2, start, trace_endpos);
        raptor_beam(start, trace_endpos, '-1 -1 -1' * raptor_beam_size, '1 1 1' * raptor_beam_size, raptor_beam_fops * sys_frametime, raptor_beam_dps * sys_frametime, DEATH_SBROCKET);

        self = vhic;

        vhic.vehicle_energy -= raptor_beam_aps * sys_frametime;
        vhic.cnt = time + 1;
    }

    if(vhic.cnt < time)
        vhic.vehicle_energy = min(vhic.vehicle_energy += raptor_energy_regen * frametime, raptor_energy_max);

    player.vehicle_energy = vhic.vehicle_energy / raptor_energy_max;


    if(player.BUTTON_ATCK2)
    if(time > vhic.delay)
    {
        raptor_bombdrop();
        vhic.delay = time + raptor_bombs_refire;
    }

    player.BUTTON_ATCK = player.BUTTON_ATCK2 = player.BUTTON_CROUCH = 0;
    vehicle_stdproc_shiledregen(raptor_shield_max, frametime);
    vehicle_stdproc_healthregen(raptor_health_max, frametime);

    self = player;

    return 1;
}

float raptor_takeoff()
{
    entity player, vhic;

    if(self.vehicle.frame < 25)
        return 1;

    player = self;
    vhic   = self.vehicle;
    self    = vhic;

    if(raptor_altitude(512) <= 256)
    {
        vhic.velocity_z = min(vhic.velocity_z * 1.5, 256);
    }
    else
    {
        player.PlayerPhysplug = raptor_pplug;
    }

    player.BUTTON_CROUCH = player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
    self = player;

    return 1;
}

float raptor_land()
{
    return 0;
}

void raptor_return()
{
    pointparticles(particleeffectnum("teleport"), self.enemy.origin + '0 0 64', '0 0 0', 1);
    self.enemy.think = raptor_spawn;
    self.enemy.nextthink = time;
    remove(self);
}

void raptor_think()
{
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

    raptor_enter();
}

void raptor_die()
{
    self.health       = 0;
    self.event_damage = SUB_Null;
    self.iscreature   = FALSE;
    self.solid        = SOLID_NOT;
    self.takedamage   = DAMAGE_NO;
    //self.touch        = racer_dietouch;
    self.deadflag     = DEAD_DYING;
    self.movetype     = MOVETYPE_BOUNCE;
    self.wait = time;

    pointparticles(particleeffectnum("rocket_explode"), findbetterlocation (self.origin, 16), '0 0 0', 1);

    self.velocity     += '0 0 128';

    if(random() < 0.5)
        self.avelocity_z  = 45;
    else
        self.avelocity_z  = -45;

    self.colormod = '-0.5 -0.5 -0.5';

	self.think     = raptor_spawn;
	self.nextthink = time + 5;
}

void raptor_spawn()
{
    self.flags     = FL_NOTARGET;
    self.effects   = 0;

    self.vehicle_health = raptor_health_max;
    self.vehicle_shield = raptor_shield_max;

    self.event_damage = vehicle_stdproc_damage;
    self.touch      = raptor_touch;

    self.iscreature = TRUE;
    self.movetype   = MOVETYPE_FLY;
    self.solid      = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;

    self.alpha = 1;
	self.colormap = 1024;
	self.deadflag    = DEAD_NO;
    self.bot_attack = TRUE;

    self.colormod = '1 1 1';
    self.avelocity = '0 0 0';
    self.velocity = '0 0 0';

    self.vehicle_energy = 1;
    self.vehicle_hudmodel.viewmodelforclient = self;

    setorigin(self, self.pos1);
    self.angles = self.pos2;

    setsize(self,RAPTOR_MIN ,RAPTOR_MAX );
    pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);
    self.delay = time;
}

float raptor_customizeentityforclient()
{
    if(self.deadflag == DEAD_DEAD)
        return FALSE;

    /*
    if(other == self.owner)
        self.alpha = -1;
    else
        self.alpha = 1;
    */

    return TRUE;
}

void raptor_dinit()
{

    if (self.netname == "")
        self.netname     = "Raptor";

    setorigin(self, self.origin);

    self.frame = 0;

    setmodel(self,"models/vehicles/raptor.dpm");

    self.bomb1 = spawn();
    self.bomb2 = spawn();

    setmodel(self.bomb1,"models/vehicles/raptor_bomb.dpm");
    setmodel(self.bomb2,"models/vehicles/raptor_bomb.dpm");

    setattachment(self.bomb1, self,"bombmount_left");
    setattachment(self.bomb2, self,"bombmount_right");


    if not (self.vehicle_hudmodel)
    {
        self.vehicle_hudmodel   = spawn();
        setmodel(self.vehicle_hudmodel, "models/vehicles/raptor_cockpit.dpm");
        //setattachment(self.vehicle_hudmodel, self, "tag_viewport");
        setattachment(self.vehicle_hudmodel, self, "tag_hud");
    }

    if not (self.vehicle_viewport)
    {
        self.vehicle_viewport   = spawn();
        setmodel (self.vehicle_viewport, "null");
        setattachment(self.vehicle_viewport, self.vehicle_hudmodel, "tag_camera");
    }

    if not (self.gun1)
    {
        self.gun1   = spawn();
        setmodel(self.gun1, "models/vehicles/raptor_gun.dpm");
        setattachment(self.gun1, self, "gunmount_left");
    }

    if not (self.gun2)
    {
        self.gun2   = spawn();
        setmodel(self.gun2, "models/vehicles/raptor_gun.dpm");
        setattachment(self.gun2, self, "gunmount_right");
    }

    self.tur_head     = spawn();
    self.pos1         = self.origin;
    self.pos2         = self.angles;

    self.vehicle_hudmodel.viewmodelforclient = self;
    self.customizeentityforclient            = raptor_customizeentityforclient;

    self.vehicle_die  = raptor_die;
    self.vehicle_exit = raptor_exit;


    entity spinner;
    spinner = spawn();
    spinner.owner = self;
    setmodel(spinner,"models/vehicles/spinner.dpm");
    setattachment(spinner, self, "engine_left");
    spinner.movetype = MOVETYPE_NOCLIP;
    spinner.avelocity = '0 90 0';

    spinner = spawn();
    spinner.owner = self;
    setmodel(spinner,"models/vehicles/spinner.dpm");
    setattachment(spinner, self, "engine_right");
    spinner.movetype = MOVETYPE_NOCLIP;
    spinner.avelocity = '0 -90 0';

    addstat(STAT_HUD, AS_INT,  hud);
	addstat(STAT_VEHICLESTAT_HEALTH,  AS_FLOAT, vehicle_health);
	addstat(STAT_VEHICLESTAT_SHIELD,  AS_FLOAT, vehicle_shield);
	addstat(STAT_VEHICLESTAT_ENERGY,  AS_FLOAT, vehicle_energy);

	addstat(STAT_VEHICLESTAT_AMMO1,   AS_INT,   vehicle_ammo1);
	addstat(STAT_VEHICLESTAT_RELOAD1, AS_FLOAT, vehicle_reload1);

	addstat(STAT_VEHICLESTAT_AMMO2,   AS_INT,   vehicle_ammo2);
	addstat(STAT_VEHICLESTAT_RELOAD2, AS_FLOAT, vehicle_reload2);

    raptor_spawn();
}

void spawnfunc_vehicle_raptor()
{
    self.cvar_basename      = "g_vehicle_raptor";
    raptor_loadsettings();

    self.vehicle_flags      = VHF_HASSHIELD | VHF_SHIELDREGEN;

    traceline(self.origin, self.origin - '0 0 2048', MOVE_WORLDONLY, self);
    if(trace_startsolid)
    {
        dprint("WARNING: vehicle_raptor placed in solid\n");
        traceline(self.origin + '0 0 512' ,self.origin - '0 0 2048',MOVE_WORLDONLY,self);
        if(trace_startsolid || trace_fraction == 1.0)
        {
            dprint("ERROR: vehicle_raptor placed in more then 512 units into solid\n");
            remove(self);
            return;
        }
    }

    if(trace_fraction != 1.0)
        setorigin(self,trace_endpos + '0 0 8');
    else
        dprint("WARNING: vehicle_racer placed more then 2048 units above ground.\n");

    precache_model ("models/vehicles/raptor.dpm");
    precache_model ("models/vehicles/raptor_gun.dpm");
    precache_model ("models/vehicles/spinner.dpm");
    precache_model ("models/vehicles/raptor_cockpit.dpm");
    precache_model ("models/vehicles/raptor_bomb.dpm");


    self.think = raptor_dinit;
    self.nextthink = time + 1;
}


void spawnfunc_vehicle_raptor2()
{
    entity iqm,dpm,md3;

    precache_model ("models/vehicles/test.iqm");
    precache_model ("models/vehicles/test.dpm");
    precache_model ("models/vehicles/test.md3");

    iqm = spawn();
    dpm = spawn();
    md3 = spawn();
    iqm.scale = md3.scale = dpm.scale = 10;

    //setmodel(iqm,"models/vehicles/test.iqm");
    //setmodel(dpm,"models/vehicles/test.dpm");
    setmodel(md3,"models/vehicles/test.md3");

    setorigin(iqm, self.origin + '0 0 16');
    setorigin(dpm, self.origin + '0 20 32');
    setorigin(iqm, self.origin + '0 40 48');
}
