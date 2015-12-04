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

	WriteString(MSG_ENTITY, self.classname);
	WriteByte(MSG_ENTITY, self.skin);
	WriteCoord(MSG_ENTITY, self.speed);

	trigger_common_write(self, false);

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
	self.touch = func_ladder_touch;

	trigger_init(self);
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
