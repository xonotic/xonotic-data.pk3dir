#include "ladder.qh"
REGISTER_NET_LINKED(ENT_CLIENT_LADDER)

void func_ladder_touch(entity this, entity toucher)
{
#ifdef SVQC
	if (!toucher.iscreature)
		return;
	if(IS_VEHICLE(toucher))
		return;
#elif defined(CSQC)
	if(!IS_PLAYER(toucher)) // don't allow non-player predicted entities!
		return;
#endif

	EXACTTRIGGER_TOUCH(this, toucher);

	toucher.ladder_time = time + 0.1;
	toucher.ladder_entity = this;
}

#ifdef SVQC
bool func_ladder_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_LADDER);

	WriteString(MSG_ENTITY, this.classname);
	WriteByte(MSG_ENTITY, this.skin);
	WriteCoord(MSG_ENTITY, this.speed);

	trigger_common_write(this, false);

	return true;
}

void func_ladder_link(entity this)
{
	trigger_link(this, func_ladder_send);
	//this.model = "null";
}

void func_ladder_init(entity this)
{
	settouch(this, func_ladder_touch);
	trigger_init(this);
	func_ladder_link(this);

	if(min(this.absmax.x - this.absmin.x, this.absmax.y - this.absmin.y) > 100)
		return;

	entity tracetest_ent = spawn();
	setsize(tracetest_ent, PL_MIN_CONST, PL_MAX_CONST);
	tracetest_ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;

	vector top_min = (this.absmin + this.absmax) / 2;
	top_min.z = this.absmax.z;
	vector top_max = top_min;
	top_max.z += PL_MAX_CONST.z - PL_MIN_CONST.z;
	tracebox(top_max + jumpstepheightvec, PL_MIN_CONST, PL_MAX_CONST, top_min, MOVE_NOMONSTERS, tracetest_ent);
	if(trace_startsolid)
	{
		tracebox(top_max + stepheightvec, PL_MIN_CONST, PL_MAX_CONST, top_min, MOVE_NOMONSTERS, tracetest_ent);
		if(trace_startsolid)
		{
			tracebox(top_max, PL_MIN_CONST, PL_MAX_CONST, top_min, MOVE_NOMONSTERS, tracetest_ent);
			if(trace_startsolid)
			{
				if(this.absmax.x - this.absmin.x > PL_MAX_CONST.x - PL_MIN_CONST.x
					&& this.absmax.y - this.absmin.y < this.absmax.x - this.absmin.x)
				{
					// move top on one side
					top_max.y = top_min.y = this.absmin.y + (PL_MAX_CONST.y - PL_MIN_CONST.y) * 0.75;
				}
				else if(this.absmax.y - this.absmin.y > PL_MAX_CONST.y - PL_MIN_CONST.y
					&& this.absmax.x - this.absmin.x < this.absmax.y - this.absmin.y)
				{
					// move top on one side
					top_max.x = top_min.x = this.absmin.x + (PL_MAX_CONST.x - PL_MIN_CONST.x) * 0.75;
				}
				tracebox(top_max, PL_MIN_CONST, PL_MAX_CONST, top_min, MOVE_NOMONSTERS, tracetest_ent);
				if(trace_startsolid)
				{
					if(this.absmax.x - this.absmin.x > PL_MAX_CONST.x - PL_MIN_CONST.x
						&& this.absmax.y - this.absmin.y < this.absmax.x - this.absmin.x)
					{
						// alternatively on the other side
						top_max.y = top_min.y = this.absmax.y - (PL_MAX_CONST.y - PL_MIN_CONST.y) * 0.75;
					}
					else if(this.absmax.y - this.absmin.y > PL_MAX_CONST.y - PL_MIN_CONST.y
						&& this.absmax.x - this.absmin.x < this.absmax.y - this.absmin.y)
					{
						// alternatively on the other side
						top_max.x = top_min.x = this.absmax.x - (PL_MAX_CONST.x - PL_MIN_CONST.x) * 0.75;
					}
					tracebox(top_max, PL_MIN_CONST, PL_MAX_CONST, top_min, MOVE_NOMONSTERS, tracetest_ent);
				}
			}
		}
	}
	if(trace_startsolid || trace_endpos.z < this.absmax.z)
	{
		delete(tracetest_ent);
		return;
	}

	this.bot_pickup = true; // allow bots to make use of this ladder
	float cost = waypoint_getlinearcost(trace_endpos.z - this.absmin.z);
	top_min = trace_endpos;
	waypoint_spawnforteleporter_boxes(this, WAYPOINTFLAG_LADDER, this.absmin, this.absmax, top_min, top_min, cost);
}

spawnfunc(func_ladder)
{
	IL_PUSH(g_ladders, this); // TODO: also func_water? bots currently loop through func_ladder only

	func_ladder_init(this);
}

spawnfunc(func_water)
{
	func_ladder_init(this);
}

#elif defined(CSQC)
.float speed;

void func_ladder_remove(entity this)
{
	strfree(this.classname);
}

NET_HANDLE(ENT_CLIENT_LADDER, bool isnew)
{
	this.classname = strzone(ReadString());
	this.skin = ReadByte();
	this.speed = ReadCoord();

	trigger_common_read(this, false);

	this.solid = SOLID_TRIGGER;
	settouch(this, func_ladder_touch);
	this.drawmask = MASK_NORMAL;
	this.move_time = time;
	this.entremove = func_ladder_remove;

	return true;
}
#endif
