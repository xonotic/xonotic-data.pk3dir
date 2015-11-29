REGISTER_NET_LINKED(ENT_CLIENT_TELEPORT_DEST)

#ifdef SVQC

bool teleport_dest_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TELEPORT_DEST);

	WriteByte(MSG_ENTITY, self.cnt);
	WriteCoord(MSG_ENTITY, self.speed);
	WriteString(MSG_ENTITY, self.targetname);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteAngle(MSG_ENTITY, self.mangle_x);
	WriteAngle(MSG_ENTITY, self.mangle_y);
	WriteAngle(MSG_ENTITY, self.mangle_z);

	return true;
}

void teleport_dest_link()
{SELFPARAM();
	Net_LinkEntity(self, false, 0, teleport_dest_send);
	//self.SendFlags |= 1; // update
}

spawnfunc(info_teleport_destination)
{
	self.classname = "info_teleport_destination";

	self.mangle = self.angles;
	self.angles = '0 0 0';

	//setorigin (self, self.origin + '0 0 27');	// To fix a mappers' habit as old as Quake
	setorigin (self, self.origin);

	IFTARGETED
	{
	}
	else
		objerror ("^3Teleport destination without a targetname");

	teleport_dest_link();
}

spawnfunc(misc_teleporter_dest)
{
	spawnfunc_info_teleport_destination(this);
}

spawnfunc(target_teleporter)
{
	spawnfunc_info_teleport_destination(this);
}

#elif defined(CSQC)

void teleport_dest_remove()
{SELFPARAM();
	//if(self.classname)
		//strunzone(self.classname);
	//self.classname = string_null;

	if(self.targetname)
		strunzone(self.targetname);
	self.targetname = string_null;
}

NET_HANDLE(ENT_CLIENT_TELEPORT_DEST, bool isnew)
{
	self.classname = "info_teleport_destination";
	self.cnt = ReadByte();
	self.speed = ReadCoord();
	self.targetname = strzone(ReadString());
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();

	self.mangle_x = ReadAngle();
	self.mangle_y = ReadAngle();
	self.mangle_z = ReadAngle();

	return = true;

	setorigin(self, self.origin);

	self.drawmask = MASK_NORMAL;
	self.entremove = teleport_dest_remove;
}

#endif
