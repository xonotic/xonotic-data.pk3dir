REGISTER_NET_LINKED(ENT_CLIENT_LADDER)

void func_ladder_touch()
{SELFPARAM();
#ifdef SVQC
	if (!other.iscreature)
		return;
	if(IS_VEHICLE(other))
		return;
#endif

	EXACTTRIGGER_TOUCH;

	other.ladder_time = time + 0.1;
	other.ladder_entity = self;
}

#ifdef SVQC
bool func_ladder_send(entity to, int sf)
{SELFPARAM();
	WriteHeader(MSG_ENTITY, ENT_CLIENT_LADDER);

	int f = 0;
	if(self.warpzone_isboxy)
		BITSET_ASSIGN(f, 1);
	if(self.origin != '0 0 0')
		BITSET_ASSIGN(f, 4);
	WriteByte(MSG_ENTITY, f);

	// we need THESE to render the warpzone (and cull properly)...
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, self.origin.x);
		WriteCoord(MSG_ENTITY, self.origin.y);
		WriteCoord(MSG_ENTITY, self.origin.z);
	}

	WriteShort(MSG_ENTITY, self.modelindex);
	WriteCoord(MSG_ENTITY, self.mins.x);
	WriteCoord(MSG_ENTITY, self.mins.y);
	WriteCoord(MSG_ENTITY, self.mins.z);
	WriteCoord(MSG_ENTITY, self.maxs.x);
	WriteCoord(MSG_ENTITY, self.maxs.y);
	WriteCoord(MSG_ENTITY, self.maxs.z);
	WriteByte(MSG_ENTITY, bound(1, self.scale * 16, 255));

	WriteString(MSG_ENTITY, self.classname);
	WriteByte(MSG_ENTITY, self.skin);
	WriteCoord(MSG_ENTITY, self.speed);

	trigger_common_write(false);

	return true;
}

void func_ladder_link()
{
	self.SendEntity = func_ladder_send;
	self.SendFlags = 0xFFFFFF;
	//self.model = "null";
}

void func_ladder_init()
{
	//self.mdl = self.model;
	string m = self.model;
	WarpZoneLib_ExactTrigger_Init();
 	if(m != "")
 	{
 		precache_model(m);
 		_setmodel(self, m); // no precision needed
	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
	self.touch = func_ladder_touch;
	BITSET_ASSIGN(self.effects, EF_NODEPTHTEST);

	func_ladder_link();
}

spawnfunc(func_ladder)
{
	func_ladder_init();
}

spawnfunc(func_water)
{
	func_ladder_init();
}

#elif defined(CSQC)
.float speed;

void func_ladder_remove()
{
	if(self.classname) { strunzone(self.classname); }
	self.classname = string_null;
}

NET_HANDLE(ENT_CLIENT_LADDER, bool isnew)
{
	int f = ReadByte();
	self.warpzone_isboxy = (f & 1);
	if(f & 4)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
	}
	else
		self.origin = '0 0 0';

	self.modelindex = ReadShort();
	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	self.scale = ReadByte() / 16;
	self.classname = strzone(ReadString());
	self.skin = ReadByte();
	self.speed = ReadCoord();

	trigger_common_read(false);

	self.solid = SOLID_TRIGGER;
	self.move_touch = func_ladder_touch;
	self.drawmask = MASK_NORMAL;
	self.move_time = time;
	self.entremove = func_ladder_remove;

	return true;
}
#endif
