#include "viewloc.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <lib/warpzone/util_server.qh>
    #include <server/defs.qh>
#endif

REGISTER_NET_LINKED(ENT_CLIENT_VIEWLOC)
REGISTER_NET_LINKED(ENT_CLIENT_VIEWLOC_TRIGGER)

#ifdef SVQC

void viewloc_think(entity this)
{
	entity e;

	// we abuse this method, rather than using normal .touch, because touch isn't reliable with multiple clients inside the same trigger, and can't "untouch" entities

	// set myself as current viewloc where possible
	for(e = NULL; (e = findentity(e, viewloc, this)); )
		e.viewloc = NULL;

		for(e = findradius((this.absmin + this.absmax) * 0.5, vlen(this.absmax - this.absmin) * 0.5 + 1); e; e = e.chain)
			if(!e.viewloc)
				if(IS_PLAYER(e)) // should we support non-player entities with this?
				//if(!IS_DEAD(e)) // death view is handled separately, we can't override this just yet
				{
					vector emin = e.absmin;
					vector emax = e.absmax;
					if(this.solid == SOLID_BSP)
					{
						emin -= '1 1 1';
						emax += '1 1 1';
					}
					if(boxesoverlap(emin, emax, this.absmin, this.absmax)) // quick
						if(WarpZoneLib_BoxTouchesBrush(emin, emax, this, e)) // accurate
							e.viewloc = this;
				}

	this.nextthink = time;
}

bool trigger_viewloc_send(entity this, entity to, int sf)
{
	// CSQC doesn't need to know our origin (yet), as we're only available for referencing
	WriteHeader(MSG_ENTITY, ENT_CLIENT_VIEWLOC_TRIGGER);

	WriteEntity(MSG_ENTITY, this.enemy);
	WriteEntity(MSG_ENTITY, this.goalentity);

	WriteCoord(MSG_ENTITY, this.origin_x);
	WriteCoord(MSG_ENTITY, this.origin_y);
	WriteCoord(MSG_ENTITY, this.origin_z);

	return true;
}

void viewloc_init(entity this)
{
	entity e;
	for(e = NULL; (e = find(e, targetname, this.target)); )
		if(e.classname == "target_viewlocation_start")
		{
			this.enemy = e;
			break;
		}
	for(e = NULL; (e = find(e, targetname, this.target2)); )
		if(e.classname == "target_viewlocation_end")
		{
			this.goalentity = e;
			break;
		}

	if(!this.enemy) { LOG_INFO("^1FAIL!\n"); delete(this); return; }

	if(!this.goalentity)
		this.goalentity = this.enemy; // make them match so CSQC knows what to do

	Net_LinkEntity(this, false, 0, trigger_viewloc_send);

	setthink(this, viewloc_think);
	this.nextthink = time;
}

spawnfunc(trigger_viewlocation)
{
	// we won't check target2 here yet, as it may not even need to exist
	if(this.target == "") { LOG_INFO("^1FAIL!\n"); delete(this); return; }

	EXACTTRIGGER_INIT;
	InitializeEntity(this, viewloc_init, INITPRIO_FINDTARGET);
}

bool viewloc_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_VIEWLOC);

	WriteByte(MSG_ENTITY, this.cnt);

	WriteCoord(MSG_ENTITY, this.origin_x);
	WriteCoord(MSG_ENTITY, this.origin_y);
	WriteCoord(MSG_ENTITY, this.origin_z);

	WriteAngle(MSG_ENTITY, this.angles_x);
	WriteAngle(MSG_ENTITY, this.angles_y);
	WriteAngle(MSG_ENTITY, this.angles_z);

	return true;
}

.float angle;
void viewloc_link(entity this)
{
	if(this.angle)
		this.angles_y = this.angle;
	Net_LinkEntity(this, false, 0, viewloc_send);
}

spawnfunc(target_viewlocation_start)
{
	this.classname = "target_viewlocation_start";
	this.cnt = 1;
	viewloc_link(this);
}
spawnfunc(target_viewlocation_end)
{
	this.classname = "target_viewlocation_end";
	this.cnt = 2;
	viewloc_link(this);
}

// compatibility
spawnfunc(target_viewlocation) { spawnfunc_target_viewlocation_start(this); }

#elif defined(CSQC)

void trigger_viewloc_updatelink(entity this)
{
	this.enemy = findfloat(NULL, entnum, this.cnt);
	this.goalentity = findfloat(NULL, entnum, this.count);
}

NET_HANDLE(ENT_CLIENT_VIEWLOC_TRIGGER, bool isnew)
{
	float point1 = ReadShort();
	float point2 = ReadShort();

	this.enemy = findfloat(NULL, entnum, point1);
	this.goalentity = findfloat(NULL, entnum, point2);

	this.origin_x = ReadCoord();
	this.origin_y = ReadCoord();
	this.origin_z = ReadCoord();

	return = true;

	setorigin(this, this.origin);

	this.cnt = point1;
	this.count = point2;

	setthink(this, trigger_viewloc_updatelink);
	this.nextthink = time + 1; // we need to delay this or else

	this.classname = "trigger_viewlocation";
	this.drawmask = MASK_NORMAL; // not so concerned, but better keep it alive
}

NET_HANDLE(ENT_CLIENT_VIEWLOC, bool isnew)
{
	this.cnt = ReadByte();

	this.origin_x = ReadCoord();
	this.origin_y = ReadCoord();
	this.origin_z = ReadCoord();
	setorigin(this, this.origin);

	this.movedir_x = ReadAngle();
	this.movedir_y = ReadAngle();
	this.movedir_z = ReadAngle();

	return = true;

	this.classname = ((this.cnt == 2) ? "target_viewlocation_end" : "target_viewlocation_start");
	this.drawmask = MASK_NORMAL; // don't cull it
}

#endif
