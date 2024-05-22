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

bool Teleport_Active(entity this, entity player)
{
	if (this.active != ACTIVE_ACTIVE)
		return false;

#ifdef SVQC
	if (!player.teleportable)
		return false;

	if(player.vehicle)
	if(!player.vehicle.teleportable)
		return false;

	if(IS_TURRET(player))
		return false;
#elif defined(CSQC)
	if(!IS_PLAYER(player))
		return false;
#endif

	if(IS_DEAD(player))
		return false;

	if(this.team)
		if(((this.spawnflags & INVERT_TEAMS) == 0) == (DIFF_TEAM(this, player)))
			return false;

	// no need to call IS_OBSERVER(), observers never call use/touch functions which means this is never an observer
	if(this.classname == "trigger_teleport" && (this.spawnflags & TELEPORT_OBSERVERS_ONLY))
		return false;

	return true;
}

void Teleport_Touch(entity this, entity toucher)
{
	entity player = toucher;

	if(!Teleport_Active(this, player))
		return;

	EXACTTRIGGER_TOUCH(this, player);

#ifdef SVQC
	if(IS_PLAYER(player))
		RemoveGrapplingHooks(player);
#endif

	entity e;
	e = Simple_TeleportPlayer(this, player);

#ifdef SVQC
	string s = this.target; this.target = string_null;
	SUB_UseTargets(this, player, player); // TODO: should we be using toucher for trigger too?
	if (!this.target) this.target = s;

	SUB_UseTargets(e, player, player);
#endif
}

#ifdef SVQC
void target_teleport_use(entity this, entity actor, entity trigger)
{
	entity player = actor;

	if(!Teleport_Active(this, player))
		return;

	if(IS_PLAYER(player))
		RemoveGrapplingHooks(player);

	entity e = Simple_TeleportPlayer(this, player);

	string s = this.target; this.target = string_null;
	SUB_UseTargets(this, player, player); // TODO: should we be using toucher for trigger too?
	if (!this.target)
	{
		this.target = s;
	}

	if(e != this) // only activate the target teleporter if target is different
		SUB_UseTargets(e, player, player);
}
#endif

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
	EXACTTRIGGER_INIT;
	this.use = trigger_teleport_use;

	if(this.noise != "")
		FOREACH_WORD(this.noise, true, precache_sound(it));

	// this must be called to spawn the teleport waypoints for bots
	InitializeEntity(this, teleport_findtarget, INITPRIO_FINDTARGET);

	if (!this.target || this.target == "")
	{
		objerror (this, "Teleporter with no target");
		return;
	}

	IL_PUSH(g_teleporters, this);
}

void target_teleporter_checktarget(entity this)
{
	// target_teleporter is used in many strange ways
	// we must attempt to figure out which way it is being used for in this instance

	if(!this.target || this.target == "")
	{
		// this target_teleporter has no target
		// so it must be either a destination for a teleporter or a teleporter itself
		bool is_teleporter_target = false;
		// NOTE: target2, target3, target4 unsupported, this may not be necessary as DeFrag maps have no such targets
		FOREACH_ENTITY_STRING(target, this.targetname,
		{
			if(it.classname == "trigger_teleport" || it.classname == "target_teleporter")
			{
				is_teleporter_target = true;
				break; // no need to keep looping once a valid target is found
			}
		});

		if(is_teleporter_target)
		{
			// there were teleporters found targeting this, so it must be a destination!
			spawnfunc_info_teleport_destination(this);
			return;
		}

		// set this entity up to be a teleporter, since it can be activated as one
		this.enemy = this;
		this.mangle = this.angles;
		this.angles = '0 0 0';
	}

	// seeing as this entity isn't targeted by a teleporter, it must be a teleporter itself

	this.active = ACTIVE_ACTIVE;
	this.use = target_teleport_use;

	if(this.noise && this.noise != "")
		FOREACH_WORD(this.noise, true, precache_sound(it));

	if(this.target && this.target != "") // no need to find a target on this entity, as it does not have one and .enemy is already set as required
		teleport_findtarget(this);
}

spawnfunc(target_teleporter)
{
	InitializeEntity(this, target_teleporter_checktarget, INITPRIO_FINDTARGET);
}
#elif defined(CSQC)
NET_HANDLE(ENT_CLIENT_TRIGGER_TELEPORT, bool isnew)
{
	this.classname = "trigger_teleport";
	if(isnew)
		IL_PUSH(g_teleporters, this);
	int mytm = ReadByte();
	if(mytm)
	{
		this.team = mytm - 1;
	}
	this.spawnflags = ReadInt24_t();
	this.active = ReadByte();
	this.speed = ReadCoord();

	trigger_common_read(this, true);

	this.entremove = trigger_remove_generic;
	this.solid = SOLID_TRIGGER;
	//settouch(this, trigger_push_touch);
	this.move_time = time;
	defer(this, 0.25, teleport_findtarget);

	return true;
}

#endif
