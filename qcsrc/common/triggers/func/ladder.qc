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
	Net_LinkEntity(self, FALSE, 0, func_ladder_send);
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
	self.draw = trigger_draw_generic;
	self.trigger_touch = func_ladder_touch;
	self.drawmask = MASK_NORMAL;
	self.move_time = time;
}
#endif
