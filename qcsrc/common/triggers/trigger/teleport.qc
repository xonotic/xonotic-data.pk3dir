#ifdef SVQC
void trigger_teleport_use()
{SELFPARAM();
	if(teamplay)
		self.team = activator.team;
#ifdef SVQC
	self.SendFlags |= SF_TRIGGER_UPDATE;
#endif
}

void Teleport_Touch (void)
{SELFPARAM();
	string s;

	if (self.active != ACTIVE_ACTIVE)
		return;

	if (!other.teleportable)
		return;

	if(other.vehicle)
	if(!other.vehicle.teleportable)
		return;

	if(IS_TURRET(other))
		return;

	if(other.deadflag != DEAD_NO)
		return;

	if(self.team)
		if(((self.spawnflags & 4) == 0) == (self.team != other.team))
			return;

	EXACTTRIGGER_TOUCH;

	if(IS_PLAYER(other))
		RemoveGrapplingHook(other);

	entity e = Simple_TeleportPlayer(self, other);

	activator = other;
	s = self.target; self.target = string_null;
	SUB_UseTargets();
	if (!self.target) self.target = s;

	WITH(entity, self, e, SUB_UseTargets());
}

spawnfunc(trigger_teleport)
{
	self.angles = '0 0 0';

	EXACTTRIGGER_INIT;

	self.active = ACTIVE_ACTIVE;

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
#endif
