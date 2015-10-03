#ifdef SVQC
float rainsnow_SendEntity(entity to, float sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_RAINSNOW);
	WriteByte(MSG_ENTITY, self.state);
	WriteCoord(MSG_ENTITY, self.origin_x + self.mins_x);
	WriteCoord(MSG_ENTITY, self.origin_y + self.mins_y);
	WriteCoord(MSG_ENTITY, self.origin_z + self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x - self.mins_x);
	WriteCoord(MSG_ENTITY, self.maxs_y - self.mins_y);
	WriteCoord(MSG_ENTITY, self.maxs_z - self.mins_z);
	WriteShort(MSG_ENTITY, compressShortVector(self.dest));
	WriteShort(MSG_ENTITY, self.count);
	WriteByte(MSG_ENTITY, self.cnt);
	return 1;
}

/*QUAKED spawnfunc_func_rain (0 .5 .8) ?
This is an invisible area like a trigger, which rain falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -700', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts density, this many particles fall every second for a 1024x1024 area, default is 2000
*/
spawnfunc(func_rain)
{
	self.dest = self.velocity;
	self.velocity = '0 0 0';
	if (!self.dest)
		self.dest = '0 0 -700';
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	SetBrushEntityModel();
	if (!self.cnt)
		self.cnt = 12;
	if (!self.count)
		self.count = 2000;
	self.count = 0.01 * self.count * (self.size_x / 1024) * (self.size_y / 1024);
	if (self.count < 1)
		self.count = 1;
	if(self.count > 65535)
		self.count = 65535;

	self.state = 1; // 1 is rain, 0 is snow
	self.Version = 1;

	Net_LinkEntity(self, false, 0, rainsnow_SendEntity);
}


/*QUAKED spawnfunc_func_snow (0 .5 .8) ?
This is an invisible area like a trigger, which snow falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -300', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts density, this many particles fall every second for a 1024x1024 area, default is 2000
*/
spawnfunc(func_snow)
{
	self.dest = self.velocity;
	self.velocity = '0 0 0';
	if (!self.dest)
		self.dest = '0 0 -300';
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	SetBrushEntityModel();
	if (!self.cnt)
		self.cnt = 12;
	if (!self.count)
		self.count = 2000;
	self.count = 0.01 * self.count * (self.size_x / 1024) * (self.size_y / 1024);
	if (self.count < 1)
		self.count = 1;
	if(self.count > 65535)
		self.count = 65535;

	self.state = 0; // 1 is rain, 0 is snow
	self.Version = 1;

	Net_LinkEntity(self, false, 0, rainsnow_SendEntity);
}
#elif defined(CSQC)
void Draw_Rain()
{SELFPARAM();
    te_particlerain(self.origin + self.mins, self.origin + self.maxs, self.velocity, floor(self.count * drawframetime + random()), self.glow_color);
}

void Draw_Snow()
{SELFPARAM();
    te_particlesnow(self.origin + self.mins, self.origin + self.maxs, self.velocity, floor(self.count * drawframetime + random()), self.glow_color);
}

void Ent_RainOrSnow()
{SELFPARAM();
	self.impulse = ReadByte(); // Rain, Snow, or Whatever
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	self.velocity = decompressShortVector(ReadShort());
	self.count = ReadShort() * 10;
	self.glow_color = ReadByte(); // color

	self.mins    = -0.5 * self.maxs;
	self.maxs    =  0.5 * self.maxs;
	self.origin  = self.origin - self.mins;

	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.solid = SOLID_NOT;
	if(self.impulse)
		self.draw = Draw_Rain;
	else
		self.draw = Draw_Snow;
}
#endif
