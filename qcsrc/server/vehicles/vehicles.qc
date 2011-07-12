float autocvar_g_vehicles_crush_dmg;
float autocvar_g_vehicles_crush_force;
float autocvar_g_vehicles_delayspawn;
float autocvar_g_vehicles_delayspawn_jitter;
float autocvar_g_vehicles_allow_flagcarry;

void vehicles_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force);
void vehicles_return();
void vehicles_enter();
void vehicles_touch();
void vehicles_reset_colors();
void vehicles_clearrturn();
void vehicles_setreturn();


/** AuxiliaryXhair*
    Send additional points of interest to be drawn, to vehicle owner
**/
float MAX_AXH = 4;
.entity AuxiliaryXhair[MAX_AXH];

float SendAuxiliaryXhair(entity to, float sf)
{

	WriteByte(MSG_ENTITY, ENT_CLIENT_AUXILIARYXHAIR);

	WriteByte(MSG_ENTITY, self.cnt);

	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

    WriteByte(MSG_ENTITY, rint(self.colormod_x * 255));
    WriteByte(MSG_ENTITY, rint(self.colormod_y * 255));
    WriteByte(MSG_ENTITY, rint(self.colormod_z * 255));

    return TRUE;
}

void UpdateAuxiliaryXhair(entity own, vector loc, vector clr, float axh_id)
{
    entity axh;

    axh_id = bound(0, axh_id, MAX_AXH);
    axh = own.AuxiliaryXhair[axh_id];

    if(axh == world || wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
    {
        axh                     = spawn();
        axh.cnt                 = axh_id;
        axh.drawonlytoclient    = own;
        axh.owner               = own;
        Net_LinkEntity(axh, FALSE, 0, SendAuxiliaryXhair);
    }

    setorigin(axh, loc);
    axh.colormod            = clr;
    axh.SendFlags           = 0x01;
    own.AuxiliaryXhair[axh_id] = axh;
}

/*
// SVC_TEMPENTITY based, horrible with even 50 ping. hm.
// WriteByte(MSG_ONE, SVC_TEMPENTITY) uses reliable messagess, never use for thinsg that need continous updates.
void SendAuxiliaryXhair2(entity own, vector loc, vector clr, float axh_id)
{
	msg_entity = own;

	WriteByte(MSG_ONE, SVC_TEMPENTITY);
	WriteByte(MSG_ONE, TE_CSQC_AUXILIARYXHAIR);

	WriteByte(MSG_ONE, axh_id);

	WriteCoord(MSG_ONE, loc_x);
	WriteCoord(MSG_ONE, loc_y);
	WriteCoord(MSG_ONE, loc_z);

    WriteByte(MSG_ONE, rint(clr_x * 255));
    WriteByte(MSG_ONE, rint(clr_y * 255));
    WriteByte(MSG_ONE, rint(clr_z * 255));

}
*/
// End AuxiliaryXhair

/**
    Notifies the client that he enterd a vehicle, and sends 
    realavent data.
    
    only sends vehicle_id atm (wich is a HUD_* constant, ex. HUD_SPIDERBOT)
**/
void CSQCVehicleSetup(entity own, float vehicle_id)
{
	msg_entity = own;

	WriteByte(MSG_ONE, SVC_TEMPENTITY);
	WriteByte(MSG_ONE, TE_CSQC_VEHICLESETUP);
	WriteByte(MSG_ONE, vehicle_id);
}

/** vehicles_locktarget

    Generic target locking.

    Figure out if what target is "locked" (if any), for missile tracking as such.

    after calling, "if(self.lock_target != world && self.lock_strength == 1)" mean
    you have a locked in target.

    Exspects a crosshair_trace() or equivalent to be
    dont before calling.

**/
.entity lock_target;
.float  lock_strength;
.float  lock_time;
.float  lock_soundtime;
void vehicles_locktarget(float incr, float decr, float _lock_time)
{
    if(self.lock_target && self.lock_target.deadflag != DEAD_NO)
    {
        self.lock_target    = world;
        self.lock_strength  = 0;
        self.lock_time      = 0;
    }

    if(self.lock_time > time)
    {
        if(self.lock_target)
        if(self.lock_soundtime < time)
        {
            self.lock_soundtime = time + 0.5;
            play2(self.owner, "vehicles/locked.wav");
        }
        
        return;
    }

    if(trace_ent != world)
    {
        if(teamplay && trace_ent.team == self.team)
            trace_ent = world;

        if(trace_ent.deadflag != DEAD_NO)
            trace_ent = world;

        if not (trace_ent.vehicle_flags & VHF_ISVEHICLE || trace_ent.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
            trace_ent = world;
    }

    if(self.lock_target == world && trace_ent != world)
        self.lock_target = trace_ent;
    
    if(self.lock_target && trace_ent == self.lock_target) 
    {            
        if(self.lock_strength != 1 && self.lock_strength + incr >= 1)
        {
            play2(self.owner, "vehicles/lock.wav");
            self.lock_soundtime = time + 0.8;
        }        
        else if (self.lock_strength != 1 && self.lock_soundtime < time)
        {            
            play2(self.owner, "vehicles/locking.wav");
            self.lock_soundtime = time + 0.3;
        }
        
    }    
        
    // Have a locking target
    // Trace hit current target
    if(trace_ent == self.lock_target && trace_ent != world)
    {
        self.lock_strength = min(self.lock_strength + incr, 1);
        if(self.lock_strength == 1)
            self.lock_time = time + _lock_time;
    }
    else
    {
        if(trace_ent)
            self.lock_strength = max(self.lock_strength - decr * 2, 0);
        else
            self.lock_strength = max(self.lock_strength - decr, 0);

        if(self.lock_strength == 0)
            self.lock_target = world;
    }
}

#define VEHICLE_UPDATE_PLAYER(fld,vhname) \
self.owner.vehicle_##fld = (self.vehicle_##fld / autocvar_g_vehicle_##vhname##_##fld) * 100

#define vehicles_sweap_collision(orig,vel,dt,acm,mult) \
traceline(orig, orig + vel * dt, MOVE_NORMAL, self); \
if(trace_fraction != 1) \
    acm += normalize(self.origin - trace_endpos) * (vlen(vel) * mult)

// Hover movement support
float  force_fromtag_power;
float  force_fromtag_normpower;
vector force_fromtag_origin;
vector vehicles_force_fromtag_hover(string tag_name, float spring_length, float max_power)
{
    force_fromtag_origin = gettaginfo(self, gettagindex(self, tag_name));
    v_forward  = normalize(v_forward) * -1;
    traceline(force_fromtag_origin, force_fromtag_origin - (v_forward  * spring_length), MOVE_NORMAL, self);

    force_fromtag_power = (1 - trace_fraction) * max_power;
    force_fromtag_normpower = force_fromtag_power / max_power;

    return v_forward  * force_fromtag_power;
}

// Experimental hovermode wich uses attraction/repulstion from surface insted of gravity/repulsion
// Can possibly be use to move abt any surface (inclusing walls/celings)
vector vehicles_force_fromtag_maglev(string tag_name, float spring_length, float max_power)
{

    force_fromtag_origin = gettaginfo(self, gettagindex(self, tag_name));
    v_forward  = normalize(v_forward) * -1;
    traceline(force_fromtag_origin, force_fromtag_origin - (v_forward  * spring_length), MOVE_NORMAL, self);

    // TODO - this may NOT be compatible with wall/celing movement, unhardcode 0.25 (engine count multiplier)
    if(trace_fraction == 1.0)
    {
        force_fromtag_normpower = -0.25;
        return '0 0 -200';
    }

    force_fromtag_power = ((1 - trace_fraction) - trace_fraction) * max_power;
    force_fromtag_normpower = force_fromtag_power / max_power;

    return v_forward  * force_fromtag_power;
}

// Generic vehile projectile system
void vehicles_projectile_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
    // Ignore damage from oterh projectiles from my owner (dont mess up volly's)
    if(inflictor.owner == self.owner)
        return; 
    
    self.health -= damage;
    self.velocity += force;
    if(self.health < 1)
    {
        self.takedamage = DAMAGE_NO;
        self.event_damage = SUB_Null;
        self.think = self.use;
        self.nextthink = time;
    }

}

void vehicles_projectile_explode()
{
    if(self.owner && other != world)
    {
        if(other == self.owner.vehicle)
            return;

        if(other == self.owner.vehicle.tur_head)
            return;
    }

	PROJECTILE_TOUCH;

	self.event_damage = SUB_Null;
    RadiusDamage (self, self.realowner, self.shot_dmg, 0, self.shot_radius, self, self.shot_force, self.totalfrags, other);

    remove (self);
}

entity vehicles_projectile(string _mzlfx, string _mzlsound,
                           vector _org, vector _vel,
                           float _dmg, float _radi, float _force,  float _size,
                           float _deahtype, float _projtype, float _health,
                           float _cull, float _clianim)
{
    entity proj;

    proj = spawn();

    PROJECTILE_MAKETRIGGER(proj);
    setorigin(proj, _org);

    proj.shot_dmg         = _dmg;
    proj.shot_radius      = _radi;
    proj.shot_force       = _force;
    proj.totalfrags       = _deahtype;
    proj.solid            = SOLID_BBOX;
    proj.movetype         = MOVETYPE_FLYMISSILE;
    proj.flags            = FL_PROJECTILE;
    proj.bot_dodge        = TRUE;
    proj.bot_dodgerating  = _dmg;
    proj.velocity         = _vel;
    proj.touch            = vehicles_projectile_explode;
    proj.use              = vehicles_projectile_explode;
    proj.owner            = self;
    proj.realowner        = self.owner;
    proj.think            = SUB_Remove;
    proj.nextthink        = time + 30;

    if(_health)
    {
        proj.takedamage       = DAMAGE_AIM;
        proj.event_damage     = vehicles_projectile_damage;
        proj.health           = _health;
    }
    else
        proj.flags           = FL_PROJECTILE | FL_NOTARGET;

    if(_mzlsound)
        sound (self, CH_WEAPON_A, _mzlsound, VOL_BASE, ATTN_NORM);

    if(_mzlfx)
        pointparticles(particleeffectnum(_mzlfx), proj.origin, proj.velocity, 1);


    setsize (proj, '-1 -1 -1' * _size, '1 1 1' * _size);

    CSQCProjectile(proj, _clianim, _projtype, _cull);

    return proj;
}
// End generic vehile projectile system

/** vehicles_spawn
    Exetuted for all vehicles on (re)spawn.
    Sets defaults for newly spawned units.
**/
void vehicles_spawn()
{
    dprint("Spawning vehicle: ", self.netname, "\n");

    // De-own & reset
    self.vehicle_hudmodel.viewmodelforclient = self;

    self.owner              = world;
    self.touch              = vehicles_touch;
    self.event_damage       = vehicles_damage;
    self.iscreature         = TRUE;
    self.movetype           = MOVETYPE_WALK;
    self.solid              = SOLID_SLIDEBOX;
    self.takedamage         = DAMAGE_AIM;
	self.deadflag           = DEAD_NO;
    self.bot_attack         = TRUE;
    self.flags              = FL_NOTARGET;
    self.avelocity          = '0 0 0';
    self.velocity           = '0 0 0';

    // Reset locking
    self.lock_strength      = 0;
    self.lock_target        = world;
    self.misc_bulletcounter = 0;

    // Return to spawn
    self.angles             = self.pos2;
    setorigin(self, self.pos1 + '0 0 128');
    // Show it
    pointparticles(particleeffectnum("teleport"), self.origin + '0 0 64', '0 0 0', 1);

    vehicles_reset_colors();
    self.vehicle_spawn();
}

// Better way of determening whats crushable needed! (fl_crushable?)
float vehicles_crushable(entity e)
{
    if(e.classname == "player")
        return TRUE;

    if(e.classname == "monster_zombie")
        return TRUE;

    return FALSE;
}

void vehicles_touch()
{
    // Vehicle currently in use
    if(self.owner)
    {
        // Colided with world?
        if(other == world)
        {
        }
        else
        {
            if(other.vehicle_flags & VHF_ISVEHICLE)
            {
                //other.velocity += self.velocity * (self.mass / other.mass);
            }
            else if(vehicles_crushable(other))
            {
                if(vlen(self.velocity) != 0)
                    Damage(other, self, self.owner, autocvar_g_vehicles_crush_dmg, DEATH_VHCRUSH, '0 0 0', normalize(other.origin - self.origin) * autocvar_g_vehicles_crush_force);
            }
        }
        return;
    }

    if(other.classname != "player")
        return;

    if(other.deadflag != DEAD_NO)
        return;

    if(other.vehicle != world)
        return;

    // Remove this when bots know how to use vehicles.
    if (clienttype(other) != CLIENTTYPE_REAL)
        return;

    vehicles_enter();
}

void vehicles_enter()
{
   // Remove this when bots know how to use vehicles
    if (clienttype(other) != CLIENTTYPE_REAL)
        return;

    if(self.phase > time)
        return;

    if(teamplay)
    if(self.team)
    if(self.team != other.team)
        return;

    self.vehicle_ammo1   = 0;
    self.vehicle_ammo2   = 0;
    self.vehicle_reload1 = 0;
    self.vehicle_reload2 = 0;
    self.vehicle_energy  = 0;

    self.owner          = other;
    self.switchweapon   = other.switchweapon;

    // .viewmodelforclient works better.
    //self.vehicle_hudmodel.drawonlytoclient = self.owner;

    self.vehicle_hudmodel.viewmodelforclient = self.owner;

    self.event_damage         = vehicles_damage;
    self.nextthink            = 0;
    self.owner.angles         = self.angles;
    self.owner.takedamage     = DAMAGE_NO;
    self.owner.solid          = SOLID_NOT;
    self.owner.movetype       = MOVETYPE_NOCLIP;
    self.owner.alpha          = -1;
    self.owner.vehicle        = self;
    self.owner.event_damage   = SUB_Null;
    self.owner.view_ofs       = '0 0 0';
    self.colormap             = self.owner.colormap;
    if(self.tur_head)
        self.tur_head.colormap    = self.owner.colormap;

    self.owner.hud            = self.hud;
    self.owner.PlayerPhysplug = self.PlayerPhysplug;

    self.owner.vehicle_ammo1    = self.vehicle_ammo1;
    self.owner.vehicle_ammo2    = self.vehicle_ammo2;
    self.owner.vehicle_reload1  = self.vehicle_reload1;
    self.owner.vehicle_reload2  = self.vehicle_reload2;

    // Cant do this, hides attached objects too.
    //self.exteriormodeltoclient = self.owner;
    //self.tur_head.exteriormodeltoclient = self.owner;

    other.flags &~= FL_ONGROUND;
    self.flags  &~= FL_ONGROUND;

    self.team                 = self.owner.team;
    self.flags               -= FL_NOTARGET;

    msg_entity = other;
    WriteByte (MSG_ONE, SVC_SETVIEWPORT);
    WriteEntity(MSG_ONE, self.vehicle_viewport);

    WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
    if(self.tur_head)
    {
        WriteAngle(MSG_ONE, self.tur_head.angles_x + self.angles_x); // tilt
        WriteAngle(MSG_ONE, self.tur_head.angles_y + self.angles_y); // yaw
        WriteAngle(MSG_ONE, 0);                                      // roll
    }
    else
    {
        WriteAngle(MSG_ONE,  self.angles_x * -1); // tilt
        WriteAngle(MSG_ONE,  self.angles_y);      // yaw
        WriteAngle(MSG_ONE,  0);                  // roll
    }

    vehicles_clearrturn();

    CSQCVehicleSetup(self.owner, self.hud);
    
    if(other.flagcarried)
    {
        if(!autocvar_g_vehicles_allow_flagcarry)
            DropFlag(other.flagcarried, world, world);
        else
        {            
            other.flagcarried.scale = 1;
            setattachment(other.flagcarried, self, ""); 
            setorigin(other, '0 0 96');
        }
    }
    
    self.vehicle_enter();
}

/** vehicles_findgoodexit
    Locates a valid location for the player to exit the vehicle.
    Will first try prefer_spot, then up 100 random spots arround the vehicle
    wich are in direct line of sight and empty enougth to hold a players bbox
**/
vector vehicles_findgoodexit(vector prefer_spot)
{
    //vector exitspot;
    float mysize;
    
    tracebox(self.origin + '0 0 32', PL_MIN, PL_MAX, prefer_spot, MOVE_NORMAL, self.owner);
    if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
        return prefer_spot;
    
    mysize = vlen(self.maxs - self.mins);
    float i;
    vector v, v2;
    v2 = 0.5 * (self.absmin + self.absmax);
    for(i = 0; i < 100; ++i)
    {        
        v = randomvec();
        v_z = 0;
        v = v2 + normalize(v) * mysize;
        tracebox(v2, PL_MIN, PL_MAX, v, MOVE_NORMAL, self.owner);
        if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
            return v;
    }
    
    /*
    exitspot = (self.origin + '0 0 48') + v_forward * mysize;
    tracebox(self.origin + '0 0 32', PL_MIN, PL_MAX, exitspot, MOVE_NORMAL, self.owner);
    if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
        return exitspot;
    
    exitspot = (self.origin + '0 0 48') - v_forward * mysize;
    tracebox(self.origin + '0 0 32', PL_MIN, PL_MAX, exitspot, MOVE_NORMAL, self.owner);
    if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
        return exitspot;

    exitspot = (self.origin + '0 0 48') + v_right * mysize;
    tracebox(self.origin + '0 0 32', PL_MIN, PL_MAX, exitspot, MOVE_NORMAL, self.owner);
    if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
        return exitspot;
    
    exitspot = (self.origin + '0 0 48') - v_right * mysize;
    tracebox(self.origin + '0 0 32', PL_MIN, PL_MAX, exitspot, MOVE_NORMAL, self.owner);
    if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
        return exitspot;
    */
    
    return self.origin;
}

/** vehicles_exit
    Standarrd vehicle release fucntion.
    custom code goes in self.vehicle_exit
**/
void vehicles_exit(float eject)
{	
    entity oldself;
    if(self.flags & FL_CLIENT)
    {
        oldself = self;
        self = self.vehicle;
    }
    
	self.flags |= FL_NOTARGET;

    if (self.owner)
    {
        msg_entity = self.owner;
        WriteByte (MSG_ONE, SVC_SETVIEWPORT);
        WriteEntity( MSG_ONE, self.owner);

        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
        WriteAngle(MSG_ONE, 0);                 // pich
        WriteAngle(MSG_ONE, self.angles_y);     // yaw
        WriteAngle(MSG_ONE, 0);                 // roll

        setsize(self.owner, PL_MIN,PL_MAX);

        self.owner.takedamage     = DAMAGE_AIM;
        self.owner.solid          = SOLID_SLIDEBOX;
        self.owner.movetype       = MOVETYPE_WALK;
        self.owner.effects        &~= EF_NODRAW;
        self.owner.alpha          = 1;
        self.owner.PlayerPhysplug = SUB_Null;
        self.owner.vehicle        = world;
        self.owner.view_ofs       = PL_VIEW_OFS;
        self.owner.event_damage   = PlayerDamage;
        self.owner.hud            = HUD_NORMAL;
        self.owner.switchweapon   = self.switchweapon;
        //self.owner.BUTTON_USE     = 0;
    }

    if(self.deadflag == DEAD_NO)
        self.avelocity          = '0 0 0';

    self.vehicle_hudmodel.viewmodelforclient = self;
	self.tur_head.nodrawtoclient             = world;
    vehicles_setreturn();

    self.phase = time + 1;

    if(!teamplay)
        self.team = 0;

    if(self.owner.flagcarried)
    {
        self.owner.flagcarried.scale = 0.6;
        setattachment(self.owner.flagcarried, self.owner, ""); 
        setorigin(self.owner.flagcarried, FLAG_CARRY_POS);
    }
    
    sound (self, CH_TRIGGER_SINGLE, "misc/null.wav", 1, ATTN_NORM);
    self.vehicle_exit(eject);
    self.owner = world;
    
    if(oldself)
        self = oldself;
}


void vehicles_regen(.float timer, .float regen_field, float field_max, float rpause, float regen, float delta_time)
{
    if(self.regen_field < field_max)
    if(self.timer + rpause < time)
    {
        self.regen_field = min(self.regen_field + regen * delta_time, field_max);

        if(self.owner)
            self.owner.regen_field = (self.regen_field / field_max) * 100;
    }
}

void shieldhit_think()
{
    self.alpha -= 0.1;
    if (self.alpha <= 0)
    {
        //setmodel(self, "");
        self.alpha = -1;
    }
    else
    {
        self.nextthink = time + 0.1;
    }
}

void vehicles_painframe()
{
//.float	pain_finished;			//Added by Supajoe
    
    if(self.owner.vehicle_health <= 50)
    if(self.pain_frame < time)
    {  
        float _ftmp;  
        _ftmp = self.owner.vehicle_health / 50;
        self.pain_frame = time + 0.1 + (random() * 0.5 * _ftmp);
        pointparticles(particleeffectnum("smoke_small"), (self.origin + (randomvec() * 80)), '0 0 0', 1);
        
        if(self.vehicle_flags & VHF_DMGSHAKE)
            self.velocity += randomvec() * 30;
        
        if(self.vehicle_flags & VHF_DMGROLL)
            if(self.vehicle_flags & VHF_DMGHEADROLL)
                self.tur_head.angles += randomvec();
            else
                self.angles += randomvec();
        
    }    
}

void vehicles_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
    self.dmg_time = time;

    if((self.vehicle_flags & VHF_HASSHIELD) && (self.vehicle_shield > 0))
    {
        if (wasfreed(self.vehicle_shieldent) || self.vehicle_shieldent == world)
        {
            self.vehicle_shieldent = spawn();
            self.vehicle_shieldent.effects = EF_LOWPRECISION;

            setmodel(self.vehicle_shieldent, "models/vhshield.md3");
            setattachment(self.vehicle_shieldent, self, "");
            setorigin(self.vehicle_shieldent, real_origin(self) - self.origin);
            self.vehicle_shieldent.scale       = 256 / vlen(self.maxs - self.mins);
            self.vehicle_shieldent.think       = shieldhit_think;
        }

        self.vehicle_shieldent.colormod    = '1 1 1';
        self.vehicle_shieldent.alpha       = 0.45;
        self.vehicle_shieldent.angles      = vectoangles(normalize(hitloc - (self.origin + self.vehicle_shieldent.origin))) - self.angles;
        self.vehicle_shieldent.nextthink   = time;

        self.vehicle_shield -= damage;

        if(self.vehicle_shield < 0)
        {
            self.vehicle_health            -= fabs(self.vehicle_shield);
            self.vehicle_shieldent.colormod = '2 0 0';
            self.vehicle_shield             = 0;
            self.vehicle_shieldent.alpha    = 0.75;
            
        	if(sound_allowed(MSG_BROADCAST, attacker))
                spamsound (self, CH_PAIN, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);   // FIXME: PLACEHOLDER
        }
        else
        	if(sound_allowed(MSG_BROADCAST, attacker))
                spamsound (self, CH_PAIN, "onslaught/electricity_explode.wav", VOL_BASE, ATTN_NORM);  // FIXME: PLACEHOLDER

    }
    else
    {
        self.vehicle_health -= damage;

        if(sound_allowed(MSG_BROADCAST, attacker))
            spamsound (self, CH_PAIN, "onslaught/ons_hit2.wav", VOL_BASE, ATTN_NORM);  // FIXME: PLACEHOLDER
    }

    self.velocity += force; // * (vlen(force) / self.mass);

    if(self.vehicle_health <= 0)
    {
        if(self.owner)
            if(self.vehicle_flags & VHF_DEATHEJECT)
                vehicles_exit(VHEF_EJECT);
            else
                vehicles_exit(VHEF_RELESE);

        self.vehicle_die();
        vehicles_setreturn();
    }
}

void vehicles_clearrturn()
{
    entity ret;
    // Remove "return helper", if any.
    ret = findchain(classname, "vehicle_return");
    while(ret)
    {
        if(ret.enemy == self)
        {
            ret.classname   = "";
            ret.think       = SUB_Remove;
            ret.nextthink   = time + 0.1;            
            
            if(ret.waypointsprite_attached)
                WaypointSprite_Kill(ret.waypointsprite_attached);
            
            return;
        }
        ret = ret.chain;
    }
}

void vehicles_return()
{
    pointparticles(particleeffectnum("teleport"), self.enemy.origin + '0 0 64', '0 0 0', 1);

    self.enemy.think     = vehicles_spawn;
    self.enemy.nextthink = time;

    if(self.waypointsprite_attached)
        WaypointSprite_Kill(self.waypointsprite_attached);
            
    remove(self);
}

void vehicles_showwp_goaway()
{
    if(self.waypointsprite_attached)
        WaypointSprite_Kill(self.waypointsprite_attached);
            
    remove(self);
    
}

void vehicles_showwp()
{
    entity oldself;
    vector rgb;
    
    if(self.cnt)
    {        
        self.think      = vehicles_return;
        self.nextthink  = self.cnt;
    }    
    else
    {
        self.think      = vehicles_return;
        self.nextthink  = time +1;
        
        oldself = self;
        self = spawn();
        setmodel(self, "null");
        self.team = oldself.enemy.team;
        self.enemy = oldself.enemy;
        setorigin(self, oldself.enemy.pos1);
        
        self.nextthink = time + 5;
        self.think = vehicles_showwp_goaway;
    }
    
    if(teamplay && self.team)
	    rgb = TeamColor(self.team);
    else
	    rgb = '1 1 1';
    WaypointSprite_Spawn("vehicle", 0, 0, self, '0 0 64', world, 0, self, waypointsprite_attached, TRUE, RADARICON_POWERUP, rgb);
    if(self.waypointsprite_attached)
    {        
        WaypointSprite_UpdateRule(self.waypointsprite_attached, self.enemy.team, SPRITERULE_DEFAULT);        
        if(oldself == world)
            WaypointSprite_UpdateBuildFinished(self.waypointsprite_attached, self.nextthink);        
        WaypointSprite_Ping(self.waypointsprite_attached);
    }    
    
    if(oldself != world)
        self = oldself;
}

void vehicles_setreturn()
{
    entity ret;
    
    vehicles_clearrturn();

    ret = spawn();
    ret.classname   = "vehicle_return";
    ret.enemy       = self;    
    ret.team        = self.team;
    ret.think       = vehicles_showwp;        
    
    if(self.deadflag != DEAD_NO)
    {
        ret.cnt         = time + self.vehicle_respawntime;
        ret.nextthink   = min(time + self.vehicle_respawntime, time + self.vehicle_respawntime - 5);        
    }        
    else
    {
        ret.nextthink   = min(time + self.vehicle_respawntime, time + self.vehicle_respawntime - 1);        
    }
        
    
    
    setmodel(ret, "null");
    setorigin(ret, self.pos1 + '0 0 96');
    	
}

void vehicles_configcheck(string  configname, float check_cvar)
{
    if(check_cvar == 0)
        localcmd(strcat("exec ", configname, "\n"));
}

void vehicles_reset_colors()
{
    entity e;
    float _effects, _colormap;
    vector _glowmod, _colormod;

    if(autocvar_g_nodepthtestplayers)
        _effects = EF_NODEPTHTEST;

    if(autocvar_g_fullbrightplayers)
        _effects |= EF_FULLBRIGHT;

    if(self.team)
        _colormap = 1024 + (self.team - 1) * 17;
    else
        _colormap = 1024;

    _glowmod  = '0 0 0';
    _colormod = '0 0 0';

    // Find all ents attacked to main model and setup effects, colormod etc.
    e = findchainentity(tag_entity, self);
    while(e)
    {
        if(e != self.vehicle_shieldent)
        {
            e.effects   = _effects; //  | EF_LOWPRECISION;
            e.colormod  = _colormod;
            e.colormap  = _colormap;
            e.alpha     = 1;
        }
        e = e.chain;
    }

    self.vehicle_hudmodel.effects  = self.effects  = _effects; // | EF_LOWPRECISION;
    self.vehicle_hudmodel.colormod = self.colormod = _colormod;
    self.vehicle_hudmodel.colormap = self.colormap = _colormap;
    self.vehicle_viewport.effects = (EF_ADDITIVE | EF_DOUBLESIDED | EF_FULLBRIGHT | EF_NODEPTHTEST | EF_NOGUNBOB | EF_NOSHADOW | EF_LOWPRECISION | EF_SELECTABLE | EF_TELEPORT_BIT);

    self.alpha     = 1;
    self.avelocity = '0 0 0';
    self.velocity  = '0 0 0';
    self.effects   = _effects;
}

float vehicle_initialize(string  net_name,
                         string  bodymodel,
                         string  topmodel,
                         string  hudmodel,
                         string  toptag,
                         string  hudtag,
                         string  viewtag,
                         float   vhud,
                         vector  min_s,
                         vector  max_s,
                         float   nodrop,
                         void()  spawnproc,
                         float   _respawntime,
                         float() physproc,
                         void()  enterproc,
                         void(float extflag) exitfunc,
                         void() dieproc,
                         void() thinkproc,
                         float  use_csqc)
{
    addstat(STAT_HUD, AS_INT,  hud);
	addstat(STAT_VEHICLESTAT_HEALTH,  AS_INT, vehicle_health);
	addstat(STAT_VEHICLESTAT_SHIELD,  AS_INT, vehicle_shield);
	addstat(STAT_VEHICLESTAT_ENERGY,  AS_INT, vehicle_energy);

	addstat(STAT_VEHICLESTAT_AMMO1,   AS_INT,   vehicle_ammo1);
	addstat(STAT_VEHICLESTAT_RELOAD1, AS_INT, vehicle_reload1);

	addstat(STAT_VEHICLESTAT_AMMO2,   AS_INT,   vehicle_ammo2);
	addstat(STAT_VEHICLESTAT_RELOAD2, AS_INT, vehicle_reload2);

    if(bodymodel == "")
        error("vehicles: missing bodymodel!");

    if(hudmodel == "")
        error("vehicles: missing hudmodel!");

    if(net_name == "")
        self.netname = self.classname;
    else
        self.netname = net_name;

    if(self.team && !teamplay)
        self.team = 0;

    self.vehicle_flags |= VHF_ISVEHICLE;
    
    setmodel(self, bodymodel);

    self.vehicle_viewport   = spawn();
    self.vehicle_hudmodel   = spawn();
    self.tur_head           = spawn();
    self.tur_head.owner     = self;
    self.takedamage         = DAMAGE_AIM;
    self.bot_attack         = TRUE;
    self.iscreature         = TRUE;
    self.hud                = vhud;

    self.vehicle_die         = dieproc;
    self.vehicle_exit        = exitfunc;
    self.vehicle_enter       = enterproc;
    self.PlayerPhysplug      = physproc;
    self.event_damage        = vehicles_damage;
    self.touch               = vehicles_touch;
    self.think               = vehicles_spawn;    
    self.nextthink           = time;        
    self.vehicle_respawntime = _respawntime;
    self.vehicle_spawn       = spawnproc;

    if(autocvar_g_nodepthtestplayers)
        self.effects = self.effects | EF_NODEPTHTEST;

    if(autocvar_g_fullbrightplayers)
        self.effects = self.effects | EF_FULLBRIGHT;

    setmodel(self.vehicle_hudmodel, hudmodel);
    setmodel(self.vehicle_viewport, "null");


    if(topmodel != "")
    {
        setmodel(self.tur_head, topmodel);
        setattachment(self.tur_head, self, toptag);
        setattachment(self.vehicle_hudmodel, self.tur_head, hudtag);
        setattachment(self.vehicle_viewport, self.vehicle_hudmodel, viewtag);
    }
    else
    {
        setattachment(self.tur_head, self, "");
        setattachment(self.vehicle_hudmodel, self, hudtag);
        setattachment(self.vehicle_viewport, self.vehicle_hudmodel, viewtag);
    }

    setsize(self, min_s, max_s);
    if not (nodrop)
    {
        setorigin(self, self.origin);
        tracebox(self.origin + '0 0 100', min_s, max_s, self.origin - '0 0 10000', MOVE_WORLDONLY, self);
        setorigin(self, trace_endpos);
    }

    self.pos1 = self.origin;
    self.pos2 = self.angles;

    return TRUE;
}

void bugmenot()
{
    self.vehicle_exit       = self.vehicle_exit;
    self.vehicle_enter      = self.vehicle_exit;
    self.vehicle_die        = self.vehicle_exit;
    self.vehicle_spawn      = self.vehicle_exit;
    self.AuxiliaryXhair     = self.AuxiliaryXhair;
}
