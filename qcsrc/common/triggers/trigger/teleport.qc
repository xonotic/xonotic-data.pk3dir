#include "teleport.qh"
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

void Teleport_Touch(entity this, entity toucher)
{
	if (this.active != ACTIVE_ACTIVE)
		return;

#ifdef SVQC
	if (!toucher.teleportable)
		return;

	if(toucher.vehicle)
	if(!toucher.vehicle.teleportable)
		return;

	if(IS_TURRET(toucher))
		return;
#elif defined(CSQC)
	if(!IS_PLAYER(toucher))
		return;
#endif

	if(IS_DEAD(toucher))
		return;

	if(this.team)
		if(((this.spawnflags & 4) == 0) == (DIFF_TEAM(this, toucher)))
			return;

	EXACTTRIGGER_TOUCH(this, toucher);

#ifdef SVQC
	if(IS_PLAYER(toucher))
		RemoveGrapplingHooks(toucher);
#endif

	entity e;
	e = Simple_TeleportPlayer(this, toucher);

#ifdef SVQC
	string s = this.target; this.target = string_null;
	SUB_UseTargets(this, toucher, toucher); // TODO: should we be using toucher for trigger too?
	if (!this.target) this.target = s;

	SUB_UseTargets(e, toucher, toucher);
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
		objerror (this, "Teleporter with no target");
		return;
	}

	IL_PUSH(g_teleporters, this);

	this.teleport_next = teleport_first;
	teleport_first = this;
}
#elif defined(CSQC)
NET_HANDLE(ENT_CLIENT_TRIGGER_TELEPORT, bool isnew)
{
	this.classname = "trigger_teleport";
	if(isnew)
		IL_PUSH(g_teleporters, this);
	int mytm = ReadByte(); if(mytm) { this.team = mytm - 1; }
	this.spawnflags = ReadInt24_t();
	this.active = ReadByte();
	this.speed = ReadCoord();

	trigger_common_read(this, true);

	this.entremove = trigger_remove_generic;
	this.solid = SOLID_TRIGGER;
	//settouch(this, trigger_push_touch);
	this.move_time = time;
	defer(this, 0.25, teleport_findtarget);

	this.teleport_next = teleport_first;
	teleport_first = this;

	return true;
}

#endif
