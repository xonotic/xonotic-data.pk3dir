void func_ladder_touch()
{SELFPARAM();
#ifdef SVQC
	if (!other.iscreature)
		return;
	if(IS_VEHICLE(other))
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
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_LADDER);

	WriteString(MSG_ENTITY, self.classname);
	WriteByte(MSG_ENTITY, self.skin);
	WriteByte(MSG_ENTITY, self.speed);
	WriteString(MSG_ENTITY, self.mdl);

	trigger_common_write(false);

	return true;
}

void func_ladder_link()
{
	//self.SendEntity = func_ladder_send;
	//self.SendFlags = 0xFFFFFF;
	//self.model = "null";
}

void spawnfunc_func_ladder()
{SELFPARAM();
	self.mdl = self.model;
	EXACTTRIGGER_INIT;
	self.touch = func_ladder_touch;

	func_ladder_link();
}

void spawnfunc_func_water()
{SELFPARAM();
	self.mdl = self.model;
	EXACTTRIGGER_INIT;
	self.touch = func_ladder_touch;

	func_ladder_link();
}

#elif defined(CSQC)
.float speed;

void ent_func_ladder()
{SELFPARAM();
	self.classname = strzone(ReadString());
	self.skin = ReadByte();
	self.speed = ReadByte();
	self.model = strzone(ReadString());

	trigger_common_read(false);
	self.mins = self.maxs = '0 0 0';

	self.solid = SOLID_TRIGGER;
	self.draw = trigger_draw_generic;
	self.trigger_touch = func_ladder_touch;
	self.drawmask = MASK_NORMAL;
	self.move_time = time;
	self.entremove = trigger_remove_generic;

	//precache_model(self.mdl);
	EXACTTRIGGER_INIT;
}
#endif
