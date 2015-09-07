#ifdef SVQC
bool corner_send(entity to, int sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_CORNER);

	WriteString(MSG_ENTITY, self.platmovetype);

	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteString(MSG_ENTITY, self.target);
	WriteString(MSG_ENTITY, self.target2);
	WriteString(MSG_ENTITY, self.target3);
	WriteString(MSG_ENTITY, self.target4);
	WriteString(MSG_ENTITY, self.targetname);
	WriteByte(MSG_ENTITY, self.target_random);

	WriteByte(MSG_ENTITY, self.wait);

	return true;
}

void corner_link()
{
	//Net_LinkEntity(self, false, 0, corner_send);
}

void spawnfunc_path_corner()
{SELFPARAM();
	// setup values for overriding train movement
	// if a second value does not exist, both start and end speeds are the single value specified
	set_platmovetype(self, self.platmovetype);

	corner_link();
}
#elif defined(CSQC)

void corner_remove()
{SELFPARAM();
	if(self.target) { strunzone(self.target); }
	self.target = string_null;

	if(self.target2) { strunzone(self.target2); }
	self.target2 = string_null;

	if(self.target3) { strunzone(self.target3); }
	self.target3 = string_null;

	if(self.target4) { strunzone(self.target4); }
	self.target4 = string_null;

	if(self.targetname) { strunzone(self.targetname); }
	self.targetname = string_null;

	if(self.platmovetype) { strunzone(self.platmovetype); }
	self.platmovetype = string_null;
}

void ent_corner()
{SELFPARAM();
	self.platmovetype = strzone(ReadString());

	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	setorigin(self, self.origin);

	self.target = strzone(ReadString());
	self.target2 = strzone(ReadString());
	self.target3 = strzone(ReadString());
	self.target4 = strzone(ReadString());
	self.targetname = strzone(ReadString());
	self.target_random = ReadByte();

	self.wait = ReadByte();

	self.classname = "path_corner";
	self.drawmask = MASK_NORMAL;
	self.entremove = corner_remove;

	set_platmovetype(self, self.platmovetype);
}

#endif
