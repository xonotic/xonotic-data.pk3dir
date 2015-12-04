REGISTER_NET_LINKED(ENT_CLIENT_TRIGGER_TELEPORT)

#ifdef SVQC
void trigger_teleport_use()
{SELFPARAM();
	if(teamplay)
		self.team = activator.team;
#ifdef SVQC
	self.SendFlags |= SF_TRIGGER_UPDATE;
#endif
}
#endif

void Teleport_Touch ()
{SELFPARAM();
	if (self.active != ACTIVE_ACTIVE)
		return;

#ifdef SVQC
	if (!other.teleportable)
		return;

	if(other.vehicle)
	if(!other.vehicle.teleportable)
		return;

	if(IS_TURRET(other))
		return;
#endif

	if(PHYS_DEAD(other))
		return;

	if(self.team)
		if(((self.spawnflags & 4) == 0) == (DIFF_TEAM(this, other)))
			return;

	EXACTTRIGGER_TOUCH;

#ifdef SVQC
	if(IS_PLAYER(other))
		RemoveGrapplingHook(other);
#endif

	entity e;
	e = Simple_TeleportPlayer(self, other);

#ifdef SVQC
	activator = other;
	string s = self.target; self.target = string_null;
	SUB_UseTargets();
	if (!self.target) self.target = s;

	WITH(entity, self, e, SUB_UseTargets());
#endif
}

#ifdef SVQC
float trigger_teleport_send(entity to, float sf)
{SELFPARAM();
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRIGGER_TELEPORT);

	int f = 0;
	if(self.warpzone_isboxy)
		BITSET_ASSIGN(f, 1);
	if(self.origin != '0 0 0')
		BITSET_ASSIGN(f, 4);
	WriteByte(MSG_ENTITY, f);

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
	WriteByte(MSG_ENTITY, self.team);
	WriteInt24_t(MSG_ENTITY, self.spawnflags);
	WriteByte(MSG_ENTITY, self.active);
	WriteCoord(MSG_ENTITY, self.speed);

	trigger_common_write(true);

	return true;
}

void trigger_teleport_link(entity this)
{
	this.SendEntity = trigger_teleport_send;
	this.SendFlags = 0xFFFFFF;
}

spawnfunc(trigger_teleport)
{
	self.angles = '0 0 0';

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

	self.active = ACTIVE_ACTIVE;
	BITSET_ASSIGN(self.effects, EF_NODEPTHTEST);
	self.use = trigger_teleport_use;

	// this must be called to spawn the teleport waypoints for bots
	InitializeEntity(self, teleport_findtarget, INITPRIO_FINDTARGET);

	if (self.target == "")
	{
		objerror ("Teleporter with no target");
		return;
	}

	self.teleport_next = teleport_first;
	teleport_first = self;
}
#elif defined(CSQC)
NET_HANDLE(ENT_CLIENT_TRIGGER_TELEPORT, bool isnew)
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
	self.classname = "trigger_teleport";
	int mytm = ReadByte(); if(mytm) { self.team = mytm - 1; }
	self.spawnflags = ReadInt24_t();
	self.active = ReadByte();
	self.speed = ReadCoord();

	trigger_common_read(true);

	self.entremove = trigger_remove_generic;
	self.solid = SOLID_TRIGGER;
	//self.draw = trigger_draw_generic;
	//self.move_touch = trigger_push_touch;
	self.drawmask = MASK_NORMAL;
	self.move_time = time;
	defer(self, 0.25, teleport_findtarget);

	self.teleport_next = teleport_first;
	teleport_first = self;

	return true;
}

#endif
