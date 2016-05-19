REGISTER_NET_LINKED(ENT_CLIENT_TRIGGER_TELEPORT)

#ifdef SVQC
void trigger_teleport_use(entity this, entity actor, entity trigger)
{
	if(teamplay)
		this.team = actor.team;
#ifdef SVQC
	this.SendFlags |= SF_TRIGGER_UPDATE;
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
#elif defined(CSQC)
	if(!IS_PLAYER(other))
		return;
#endif

	if(IS_DEAD(other))
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
	string s = self.target; self.target = string_null;
	SUB_UseTargets(self, other, other); // TODO: should we be using other for trigger too?
	if (!self.target) self.target = s;

	SUB_UseTargets(e, other, other);
#endif
}

#ifdef SVQC
float trigger_teleport_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRIGGER_TELEPORT);

	WriteByte(MSG_ENTITY, this.team);
	WriteInt24_t(MSG_ENTITY, this.spawnflags);
	WriteByte(MSG_ENTITY, this.active);
	WriteCoord(MSG_ENTITY, this.speed);

	trigger_common_write(this, true);

	return true;
}

void trigger_teleport_link(entity this)
{
	//trigger_link(this, trigger_teleport_send);
}

spawnfunc(trigger_teleport)
{
	this.angles = '0 0 0';

	this.active = ACTIVE_ACTIVE;
	//trigger_init(this); // only for predicted triggers?
	EXACTTRIGGER_INIT;
	this.use = trigger_teleport_use;

	if(this.noise != "")
		FOREACH_WORD(this.noise, true, precache_sound(it));

	// this must be called to spawn the teleport waypoints for bots
	InitializeEntity(this, teleport_findtarget, INITPRIO_FINDTARGET);

	if (this.target == "")
	{
		objerror ("Teleporter with no target");
		return;
	}

	this.teleport_next = teleport_first;
	teleport_first = this;
}
#elif defined(CSQC)
NET_HANDLE(ENT_CLIENT_TRIGGER_TELEPORT, bool isnew)
{
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
