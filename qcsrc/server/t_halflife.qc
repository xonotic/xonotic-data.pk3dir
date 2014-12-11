.float ladder_time;
.entity ladder_entity;

#ifdef SVQC
.float  roomtype;
.float  radius;
.float  pitch;
.float  renderamt;
.float  rendermode;
.vector rendercolor;

void spawnfunc_weapon_crossbow() {}
void spawnfunc_weapon_handgrenade() {}
void spawnfunc_ammo_crossbow() {}
void spawnfunc_ammo_9mmclip() {}
void spawnfunc_ammo_gaussclip() {}
void spawnfunc_weapon_rpg() {}
void spawnfunc_weapon_357() {}
void ammo_ARgrenades() {}
void spawnfunc_item_battery() {}
void spawnfunc_ammo_rpgclip() {}
void weapon_9mmAR() {}
void spawnfunc_weapon_tripmine() {}
void spawnfunc_weapon_snark() {}
void spawnfunc_ammo_buckshot() {}
void ammo_9mmAR() {}
void spawnfunc_ammo_357() {}
void spawnfunc_weapon_gauss() {}
void spawnfunc_weapon_hornetgun() {}
//void spawnfunc_weapon_shotgun() {}
void spawnfunc_item_healthkit() {}
void spawnfunc_item_longjump() {}
void spawnfunc_item_antidote() {}
void spawnfunc_func_recharge() {}
void spawnfunc_info_node() {}
void spawnfunc_env_sound() {}
void spawnfunc_light_spot() {}
void spawnfunc_func_healthcharger() {}
#endif

void func_ladder_touch()
{
#ifdef SVQC
	if (!other.iscreature)
		return;
	if (other.vehicle_flags & VHF_ISVEHICLE)
		return;
#endif
#ifdef CSQC
	if(other.classname != "csqcmodel")
		return;
#endif

	EXACTTRIGGER_TOUCH;

#ifdef CSQC
	print("Setting ladder time on ", other.classname, "\n");
#endif

	other.ladder_time = time + 0.1;
	other.ladder_entity = self;
}

#ifdef SVQC
float func_ladder_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_LADDER);

	WriteString(MSG_ENTITY, self.classname);
	WriteByte(MSG_ENTITY, self.warpzone_isboxy);
	WriteByte(MSG_ENTITY, self.skin);
	WriteByte(MSG_ENTITY, self.speed);
	WriteByte(MSG_ENTITY, self.scale);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteCoord(MSG_ENTITY, self.mins_x);
	WriteCoord(MSG_ENTITY, self.mins_y);
	WriteCoord(MSG_ENTITY, self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x);
	WriteCoord(MSG_ENTITY, self.maxs_y);
	WriteCoord(MSG_ENTITY, self.maxs_z);

	WriteCoord(MSG_ENTITY, self.movedir_x);
	WriteCoord(MSG_ENTITY, self.movedir_y);
	WriteCoord(MSG_ENTITY, self.movedir_z);

	WriteCoord(MSG_ENTITY, self.angles_x);
	WriteCoord(MSG_ENTITY, self.angles_y);
	WriteCoord(MSG_ENTITY, self.angles_z);

	return TRUE;
}

void func_ladder_link()
{
	self.nextthink = time;
	Net_LinkEntity(self, FALSE, 0, func_ladder_send);
	self.nextthink = 0;
}

void spawnfunc_func_ladder()
{
	EXACTTRIGGER_INIT;
	self.touch = func_ladder_touch;

	func_ladder_link();
}

void spawnfunc_func_water()
{
	EXACTTRIGGER_INIT;
	self.touch = func_ladder_touch;

	func_ladder_link();
}

#elif defined(CSQC)
.float speed;

void func_ladder_draw()
{
	tracebox(self.origin, self.mins, self.maxs, self.origin, MOVE_NORMAL, self);

	if(trace_fraction < 1)
	if(trace_ent)
	{
		other = trace_ent;
		func_ladder_touch();
	}
}

void ent_func_ladder()
{
	self.classname = strzone(ReadString());
	self.warpzone_isboxy = ReadByte();
	self.skin = ReadByte();
	self.speed = ReadByte();
	self.scale = ReadByte();
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	setorigin(self, self.origin);
	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	setsize(self, self.mins, self.maxs);
	self.movedir_x = ReadCoord();
	self.movedir_y = ReadCoord();
	self.movedir_z = ReadCoord();
	self.angles_x = ReadCoord();
	self.angles_y = ReadCoord();
	self.angles_z = ReadCoord();

	self.solid = SOLID_TRIGGER;
	self.draw = func_ladder_draw;
	self.drawmask = MASK_NORMAL;
}
#endif
