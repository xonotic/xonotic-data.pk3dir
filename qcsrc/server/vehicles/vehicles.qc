void vehicles_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force);
void vehicles_return();
void vehicles_clearrturn();

.entity AuxiliaryXhair;
float AuxiliaryXhair_customizeentityforclient()
{
    if(other == self.owner)
        return TRUE;

    return FALSE;
}
float AuxiliaryXhair_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_AUXILIARYXHAIR);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

    WriteByte(MSG_ENTITY, rint(self.colormod_x * 255));
    WriteByte(MSG_ENTITY, rint(self.colormod_y * 255));
    WriteByte(MSG_ENTITY, rint(self.colormod_z * 255));

	return TRUE;
}

void SpawnOrUpdateAuxiliaryXhair(entity own, vector loc, vector clr)
{

    if(own.AuxiliaryXhair == world || wasfreed(own.AuxiliaryXhair))
    {
        own.AuxiliaryXhair = spawn();
        own.AuxiliaryXhair.owner = own;
        own.AuxiliaryXhair.drawonlytoclient = own;
        Net_LinkEntity(own.AuxiliaryXhair, FALSE, 0, AuxiliaryXhair_SendEntity);
    }

    own.AuxiliaryXhair.colormod = clr;
    setorigin(own.AuxiliaryXhair, loc);
	own.AuxiliaryXhair.SendFlags |= 0x01;
}

void Release_AuxiliaryXhair(entity from)
{
    // from.AuxiliaryXhair.drawonlytoclient = from.AuxiliaryXhair;
    if (from.AuxiliaryXhair != world && !wasfreed(from.AuxiliaryXhair))
        remove(from.AuxiliaryXhair);

    from.AuxiliaryXhair = world;
}

#define VEHICLE_UPDATE_PLAYER(fld,vhname) \
self.owner.vehicle_##fld = self.vehicle_##fld / autocvar_g_vehicle_##vhname##_##fld

#define vehicles_sweap_collision(orig,vel,dt,acm,mult) \
traceline(orig, orig + vel * dt, MOVE_NORMAL, self); \
if(trace_fraction != 1) \
    acm += normalize(self.origin - trace_endpos) * (vlen(vel) * mult)

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

vector vehicles_force_fromtag_maglev(string tag_name, float spring_length, float max_power)
{

    force_fromtag_origin = gettaginfo(self, gettagindex(self, tag_name));
    v_forward  = normalize(v_forward) * -1;
    traceline(force_fromtag_origin, force_fromtag_origin - (v_forward  * spring_length), MOVE_NORMAL, self);

    if(trace_fraction == 1.0)
    {
        force_fromtag_normpower = -0.25;
        return '0 0 -200';
    }

    force_fromtag_power = ((1 - trace_fraction) - trace_fraction) * max_power;
    force_fromtag_normpower = force_fromtag_power / max_power;

    return v_forward  * force_fromtag_power;
}


void vehicles_touch()
{
    if(other.classname != "player")
        return;

    if(other.deadflag != DEAD_NO)
        return;

    if(other.vehicle != world)
        return;

    // Remove this when bots know how to use vehicles.
    if (clienttype(other) != CLIENTTYPE_REAL)
        return;

    self.vehicle_enter();
}

void vehicles_enter()
{
   // Remove this when bots know how to use vehicles
    if (clienttype(other) != CLIENTTYPE_REAL)
        return;

    self.colormod = self.tur_head.colormod = '0 0 0';

    if(teams_matter)
    if(self.team)
    if(self.team != other.team)
        return;

    self.owner          = other;
    self.switchweapon   = other.switchweapon;

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

    other.flags &~= FL_ONGROUND;
    self.flags  &~= FL_ONGROUND;

    self.team                 = self.owner.team;
    self.flags               -= FL_NOTARGET;

    msg_entity = other;
    WriteByte (MSG_ONE, SVC_SETVIEWPORT);
    WriteEntity(MSG_ONE, self.vehicle_viewport);

    WriteByte (MSG_ONE, SVC_SETVIEWANGLES);  // 10 = SVC_SETVIEWANGLES
    if(self.tur_head)
    {
        WriteAngle(MSG_ONE, self.tur_head.angles_x + self.angles_x);    // tilt
        WriteAngle(MSG_ONE, self.tur_head.angles_y + self.angles_y);    // yaw
        WriteAngle(MSG_ONE, 0);    // roll
    }
    else
    {
        WriteByte (MSG_ONE, SVC_SETVIEWANGLES); // 10 = SVC_SETVIEWANGLES
        WriteAngle(MSG_ONE,  self.angles_x * -1);    // tilt
        WriteAngle(MSG_ONE,  self.angles_y);    // yaw
        WriteAngle(MSG_ONE,  0);                // roll
    }

    vehicles_clearrturn();

    if(self.vehicle_enter)
        self.vehicle_enter();
}

void vehicles_exit(float eject)
{
	self.colormap   = 1024;
	self.tur_head.colormap   = 1024;

    if (teams_matter)
    {
        if (self.team == COLOR_TEAM1)
            self.colormod = '1.4 0.8 0.8';

        if (self.team == COLOR_TEAM2)
            self.colormod = '0.8 0.8 1.4';

        self.tur_head.colormod = self.colormod;
    }


	self.flags |= FL_NOTARGET;

    if (self.owner)
    {
        msg_entity = self.owner;
        WriteByte (MSG_ONE, SVC_SETVIEWPORT);
        WriteEntity( MSG_ONE, self.owner);

        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);    // 10 = SVC_SETVIEWANGLES
        WriteAngle(MSG_ONE,  0);                   // tilt
        WriteAngle(MSG_ONE,  self.angles_y);        // yaw
        WriteAngle(MSG_ONE,  0);                   // roll

        setsize(self.owner,PL_MIN,PL_MAX);

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
    }

    self.vehicle_hudmodel.viewmodelforclient = self;
	self.tur_head.nodrawtoclient             = self;

    if(self.vehicle_exit)
        self.vehicle_exit(eject);

    self.owner = world;
}


void vehicles_regen(.float timer, .float regen_field, float field_max, float rpause, float regen, float delta_time)
{
    if(self.regen_field < field_max)
    if(self.timer + rpause < time)
    {
        self.regen_field = min(self.regen_field + regen * delta_time, field_max);

        if(self.owner)
            self.owner.regen_field = self.regen_field / field_max;
    }
}

void shieldhit_think()
{
    self.alpha -= 0.1;
    if (self.alpha <= 0)
    {
        setmodel(self, "");
        self.alpha = -1;
    }
    else
    {
        self.nextthink = time + 0.1;
    }
}

void vehicles_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
    float ddmg_take;

    self.dmg_time = time;

    if((self.vehicle_flags & VHF_HASSHIELD) && (self.vehicle_shield > 0))
    {
        if (wasfreed(self.tur_head.enemy) || self.tur_head.enemy == world)
        {
            self.tur_head.enemy = spawn();
            self.tur_head.enemy.effects = EF_LOWPRECISION;
        }

        setmodel(self.tur_head.enemy, "models/vhshield.md3");
        setattachment(self.tur_head.enemy, self, "");

        self.tur_head.enemy.colormod    = '1 1 1';
        self.tur_head.enemy.alpha       = 0.45;
        self.tur_head.enemy.scale       = (256 / vlen(self.maxs - self.mins));
        self.tur_head.enemy.angles      = vectoangles(normalize(hitloc - self.origin)) - self.angles;
        self.tur_head.enemy.think       = shieldhit_think;
        self.tur_head.enemy.nextthink   = time;

        self.vehicle_shield -= damage;
        if(self.vehicle_shield < 0)
        {
            self.tur_head.enemy.colormod = '10 0 -1';
            ddmg_take = fabs(self.vehicle_shield);
            self.vehicle_shield         = 0;
            self.tur_head.enemy.alpha   = 0.75;
            self.vehicle_health         -= ddmg_take;
        }
    }
    else
        self.vehicle_health -= damage;

    if(self.vehicle_health <= 0)
    {
        if(self.owner)
            if(self.vehicle_flags & VHF_DEATHEJECT)
                vehicles_exit(VHEF_EJECT);
            else
                vehicles_exit(VHEF_RELESE);

        self.vehicle_die();
    }
}

void vehicles_return()
{
    pointparticles(particleeffectnum("teleport"), self.enemy.origin + '0 0 64', '0 0 0', 1);
    self.enemy.think = self.use;
    self.enemy.nextthink = time;
    remove(self);
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
            ret.think = SUB_Remove;
            ret.nextthink = time + 0.1;
            return;
        }
        ret = ret.chain;
    }
}

void vehicles_setreturn(float retime, void() respawn_proc)
{
    vehicles_clearrturn();

    if (self.deadflag == DEAD_NO)
    {
        entity ret;

        ret = spawn();
        ret.classname = "vehicle_return";
        ret.enemy = self;
        ret.think = vehicles_return;
        ret.nextthink = time + retime;
        ret.use = respawn_proc;
    }
}

float vehicles_customizeentityforclient()
{
    if(self.deadflag == DEAD_DEAD)
        return FALSE;

    return TRUE;
}

void vehicles_configcheck(string  configname, float   check_cvar)
{
    if(check_cvar == 0)
        localcmd(strcat("exec ", configname, "\n"));
}

float vehicle_initialize(string  net_name,
                         string  bodymodel,
                         string  topmodel,
                         string  hudmodel,
                         string  toptag,
                         string  hudtag,
                         string  viewtag,
                         float   vhud,
                         vector min_s,
                         vector max_s,
                         float  nodrop,
                         void()  spawnproc,
                         float() physproc,
                         void()  enterproc,
                         void(float extflag) exitfunc,
                         void() dieproc,
                         void() thinkproc )
{
    addstat(STAT_HUD, AS_INT,  hud);
	addstat(STAT_VEHICLESTAT_HEALTH,  AS_FLOAT, vehicle_health);
	addstat(STAT_VEHICLESTAT_SHIELD,  AS_FLOAT, vehicle_shield);
	addstat(STAT_VEHICLESTAT_ENERGY,  AS_FLOAT, vehicle_energy);

	addstat(STAT_VEHICLESTAT_AMMO1,   AS_INT,   vehicle_ammo1);
	addstat(STAT_VEHICLESTAT_RELOAD1, AS_FLOAT, vehicle_reload1);

	addstat(STAT_VEHICLESTAT_AMMO2,   AS_INT,   vehicle_ammo2);
	addstat(STAT_VEHICLESTAT_RELOAD2, AS_FLOAT, vehicle_reload2);

    if(bodymodel == "")
        error("vehicles: missing bodymodel!");

    if(hudmodel == "")
        error("vehicles: missing hudmodel!");

    if(net_name == "")
        self.netname = self.classname;
    else
        self.netname = net_name;

    if(self.team && !teams_matter)
        self.team = 0;

    setmodel(self, bodymodel);

    self.vehicle_viewport   = spawn();
    self.vehicle_hudmodel   = spawn();
    self.tur_head           = spawn();
    self.tur_head.owner     = self;
    self.takedamage         = DAMAGE_AIM;
    self.bot_attack         = TRUE;
    self.iscreature         = TRUE;
    self.hud                = vhud;

    self.customizeentityforclient = vehicles_customizeentityforclient;
    self.vehicle_die        = dieproc;
    self.vehicle_exit       = exitfunc;
    self.vehicle_enter      = enterproc;
    self.PlayerPhysplug     = physproc;
    self.event_damage       = vehicles_damage;
    self.touch              = vehicles_touch;
    self.think              = spawnproc;
    self.nextthink          = time;

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
    //self.vehicle_message    = self.vehicle_exit;
}
