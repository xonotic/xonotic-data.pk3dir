#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "../../../lib/warpzone/util_server.qh"
    #include "../../../server/defs.qh"
#endif

REGISTER_NET_LINKED(ENT_CLIENT_VIEWLOC)
REGISTER_NET_LINKED(ENT_CLIENT_VIEWLOC_TRIGGER)

#ifdef SVQC

void viewloc_think()
{SELFPARAM();
	entity e;

	// we abuse this method, rather than using normal .touch, because touch isn't reliable with multiple clients inside the same trigger, and can't "untouch" entities

	// set myself as current viewloc where possible
	for(e = world; (e = findentity(e, viewloc, self)); )
		e.viewloc = world;

		for(e = findradius((self.absmin + self.absmax) * 0.5, vlen(self.absmax - self.absmin) * 0.5 + 1); e; e = e.chain)
			if(!e.viewloc)
				if(IS_PLAYER(e)) // should we support non-player entities with this?
				//if(e.deadflag == DEAD_NO) // death view is handled separately, we can't override this just yet
				{
					vector emin = e.absmin;
					vector emax = e.absmax;
					if(self.solid == SOLID_BSP)
					{
						emin -= '1 1 1';
						emax += '1 1 1';
					}
					if(boxesoverlap(emin, emax, self.absmin, self.absmax)) // quick
						if(WarpZoneLib_BoxTouchesBrush(emin, emax, self, e)) // accurate
							e.viewloc = self;
				}

	self.nextthink = time;
}

bool trigger_viewloc_send(entity this, entity to, int sf)
{
	// CSQC doesn't need to know our origin (yet), as we're only available for referencing
	WriteHeader(MSG_ENTITY, ENT_CLIENT_VIEWLOC_TRIGGER);

	WriteEntity(MSG_ENTITY, self.enemy);
	WriteEntity(MSG_ENTITY, self.goalentity);

	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	return true;
}

void viewloc_init()
{SELFPARAM();
	entity e;
	for(e = world; (e = find(e, targetname, self.target)); )
		if(e.classname == "target_viewlocation_start")
		{
			self.enemy = e;
			break;
		}
	for(e = world; (e = find(e, targetname, self.target2)); )
		if(e.classname == "target_viewlocation_end")
		{
			self.goalentity = e;
			break;
		}

	if(!self.enemy) { LOG_INFO("^1FAIL!\n"); remove(self); return; }

	if(!self.goalentity)
		self.goalentity = self.enemy; // make them match so CSQC knows what to do

	Net_LinkEntity(self, false, 0, trigger_viewloc_send);

	self.think = viewloc_think;
	self.nextthink = time;
}

spawnfunc(trigger_viewlocation)
{
	// we won't check target2 here yet, as it may not even need to exist
	if(self.target == "") { LOG_INFO("^1FAIL!\n"); remove(self); return; }

	EXACTTRIGGER_INIT;
	InitializeEntity(self, viewloc_init, INITPRIO_FINDTARGET);
}

bool viewloc_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_VIEWLOC);

	WriteByte(MSG_ENTITY, self.cnt);

	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteCoord(MSG_ENTITY, self.angles_x);
	WriteCoord(MSG_ENTITY, self.angles_y);
	WriteCoord(MSG_ENTITY, self.angles_z);

	return true;
}

.float angle;
void viewloc_link()
{SELFPARAM();
	if(self.angle)
		self.angles_y = self.angle;
	Net_LinkEntity(self, false, 0, viewloc_send);
}

spawnfunc(target_viewlocation_start)
{
	self.classname = "target_viewlocation_start";
	self.cnt = 1;
	viewloc_link();
}
spawnfunc(target_viewlocation_end)
{
	self.classname = "target_viewlocation_end";
	self.cnt = 2;
	viewloc_link();
}

// compatibility
spawnfunc(target_viewlocation) { spawnfunc_target_viewlocation_start(this); }

#elif defined(CSQC)

void trigger_viewloc_updatelink()
{SELFPARAM();
	self.enemy = findfloat(world, entnum, self.cnt);
	self.goalentity = findfloat(world, entnum, self.count);
}

NET_HANDLE(ENT_CLIENT_VIEWLOC_TRIGGER, bool isnew)
{
	float point1 = ReadShort();
	float point2 = ReadShort();

	self.enemy = findfloat(world, entnum, point1);
	self.goalentity = findfloat(world, entnum, point2);

	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();

	return = true;

	setorigin(self, self.origin);

	self.cnt = point1;
	self.count = point2;

	self.think = trigger_viewloc_updatelink;
	self.nextthink = time + 1; // we need to delay this or else

	self.classname = "trigger_viewlocation";
	self.drawmask = MASK_NORMAL; // not so concerned, but better keep it alive
}

NET_HANDLE(ENT_CLIENT_VIEWLOC, bool isnew)
{
	self.cnt = ReadByte();

	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	setorigin(self, self.origin);

	self.movedir_x = ReadCoord();
	self.movedir_y = ReadCoord();
	self.movedir_z = ReadCoord();

	return = true;

	self.classname = ((self.cnt == 2) ? "target_viewlocation_end" : "target_viewlocation_start");
	self.drawmask = MASK_NORMAL; // don't cull it
}

#endif
