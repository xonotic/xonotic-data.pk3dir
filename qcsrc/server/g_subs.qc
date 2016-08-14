#include "g_subs.qh"

#include "antilag.qh"
#include "command/common.qh"
#include "../common/state.qh"
#include "../lib/warpzone/common.qh"
#include "../common/triggers/subs.qh"

spawnfunc(info_null)
{
	delete(this);
	// if anything breaks, tell the mapper to fix his map! info_null is meant to remove itself immediately.
}

/*
==================
main

unused but required by the engine
==================
*/
void main ()
{

}

// Misc

/*
==================
traceline_antilag

A version of traceline that must be used by SOLID_SLIDEBOX things that want to hit SOLID_CORPSE things with a trace attack
Additionally it moves players back into the past before the trace and restores them afterward.
==================
*/
void tracebox_antilag_force_wz (entity source, vector v1, vector mi, vector ma, vector v2, float nomonst, entity forent, float lag, float wz)
{
	// check whether antilagged traces are enabled
	if (lag < 0.001)
		lag = 0;
	if (!IS_REAL_CLIENT(forent))
		lag = 0; // only antilag for clients

	// change shooter to SOLID_BBOX so the shot can hit corpses
	int oldsolid = source.dphitcontentsmask;
	if(source)
		source.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	if (lag)
	{
		// take players back into the past
		FOREACH_CLIENT(IS_PLAYER(it) && it != forent, antilag_takeback(it, CS(it), time - lag));
		IL_EACH(g_monsters, it != forent,
		{
			antilag_takeback(it, it, time - lag);
		});
	}

	// do the trace
	if(wz)
		WarpZone_TraceBox (v1, mi, ma, v2, nomonst, forent);
	else
		tracebox (v1, mi, ma, v2, nomonst, forent);

	// restore players to current positions
	if (lag)
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != forent, antilag_restore(it, CS(it)));
		IL_EACH(g_monsters, it != forent,
		{
			antilag_restore(it, it);
		});
	}

	// restore shooter solid type
	if(source)
		source.dphitcontentsmask = oldsolid;
}
void traceline_antilag_force (entity source, vector v1, vector v2, float nomonst, entity forent, float lag)
{
	tracebox_antilag_force_wz(source, v1, '0 0 0', '0 0 0', v2, nomonst, forent, lag, false);
}
void traceline_antilag (entity source, vector v1, vector v2, float nomonst, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || source.cvar_cl_noantilag)
		lag = 0;
	traceline_antilag_force(source, v1, v2, nomonst, forent, lag);
}
void tracebox_antilag (entity source, vector v1, vector mi, vector ma, vector v2, float nomonst, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || source.cvar_cl_noantilag)
		lag = 0;
	tracebox_antilag_force_wz(source, v1, mi, ma, v2, nomonst, forent, lag, false);
}
void WarpZone_traceline_antilag_force (entity source, vector v1, vector v2, float nomonst, entity forent, float lag)
{
	tracebox_antilag_force_wz(source, v1, '0 0 0', '0 0 0', v2, nomonst, forent, lag, true);
}
void WarpZone_traceline_antilag (entity source, vector v1, vector v2, float nomonst, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || source.cvar_cl_noantilag)
		lag = 0;
	WarpZone_traceline_antilag_force(source, v1, v2, nomonst, forent, lag);
}
void WarpZone_tracebox_antilag (entity source, vector v1, vector mi, vector ma, vector v2, float nomonst, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || source.cvar_cl_noantilag)
		lag = 0;
	tracebox_antilag_force_wz(source, v1, mi, ma, v2, nomonst, forent, lag, true);
}

float tracebox_inverted (vector v1, vector mi, vector ma, vector v2, float nomonsters, entity forent, float stopatentity, entity ignorestopatentity) // returns the number of traces done, for benchmarking
{
	vector pos, dir, t;
	float nudge;
	entity stopentity;

	//nudge = 2 * cvar("collision_impactnudge"); // why not?
	nudge = 0.5;

	dir = normalize(v2 - v1);

	pos = v1 + dir * nudge;

	float c;
	c = 0;

	for (;;)
	{
		if(pos * dir >= v2 * dir)
		{
			// went too far
			trace_fraction = 1;
			trace_endpos = v2;
			return c;
		}

		tracebox(pos, mi, ma, v2, nomonsters, forent);
		++c;

		if(c == 50)
		{
			LOG_TRACE("HOLY SHIT! When tracing from ", vtos(v1), " to ", vtos(v2));
			LOG_TRACE("  Nudging gets us nowhere at ", vtos(pos));
			LOG_TRACE("  trace_endpos is ", vtos(trace_endpos));
			LOG_TRACE("  trace distance is ", ftos(vlen(pos - trace_endpos)));
		}

		stopentity = trace_ent;

		if(trace_startsolid)
		{
			// we started inside solid.
			// then trace from endpos to pos
			t = trace_endpos;
			tracebox(t, mi, ma, pos, nomonsters, forent);
			++c;
			if(trace_startsolid)
			{
				// t is still inside solid? bad
				// force advance, then, and retry
				pos = t + dir * nudge;

				// but if we hit an entity, stop RIGHT before it
				if(stopatentity && stopentity && stopentity != ignorestopatentity)
				{
					trace_ent = stopentity;
					trace_endpos = t;
					trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
					return c;
				}
			}
			else
			{
				// we actually LEFT solid!
				trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
				return c;
			}
		}
		else
		{
			// pos is outside solid?!? but why?!? never mind, just return it.
			trace_endpos = pos;
			trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
			return c;
		}
	}
}

void traceline_inverted (vector v1, vector v2, float nomonsters, entity forent, float stopatentity, entity ignorestopatentity)
{
	tracebox_inverted(v1, '0 0 0', '0 0 0', v2, nomonsters, forent, stopatentity, ignorestopatentity);
}

/*
==================
findbetterlocation

Returns a point at least 12 units away from walls
(useful for explosion animations, although the blast is performed where it really happened)
Ripped from DPMod
==================
*/
vector findbetterlocation (vector org, float mindist)
{
	vector	loc;
	vector vec;
	float c, h;

	vec = mindist * '1 0 0';
	c = 0;
	while (c < 6)
	{
		traceline (org, org + vec, true, NULL);
		vec = vec * -1;
		if (trace_fraction < 1)
		{
			loc = trace_endpos;
			traceline (loc, loc + vec, true, NULL);
			if (trace_fraction >= 1)
				org = loc + vec;
		}
		if (c & 1)
		{
			h = vec.y;
			vec.y = vec.x;
			vec.x = vec.z;
			vec.z = h;
		}
		c = c + 1;
	}

	return org;
}

bool LOD_customize(entity this, entity client)
{
	if(autocvar_loddebug)
	{
		int d = autocvar_loddebug;
		if(d == 1)
			this.modelindex = this.lodmodelindex0;
		else if(d == 2 || !this.lodmodelindex2)
			this.modelindex = this.lodmodelindex1;
		else // if(d == 3)
			this.modelindex = this.lodmodelindex2;
		return true;
	}

	// TODO csqc network this so it only gets sent once
	vector near_point = NearestPointOnBox(this, client.origin);
	if(vdist(near_point - client.origin, <, this.loddistance1))
		this.modelindex = this.lodmodelindex0;
	else if(!this.lodmodelindex2 || vdist(near_point - client.origin, <, this.loddistance2))
		this.modelindex = this.lodmodelindex1;
	else
		this.modelindex = this.lodmodelindex2;

	return true;
}

void LOD_uncustomize(entity this)
{
	this.modelindex = this.lodmodelindex0;
}

void LODmodel_attach(entity this)
{
	entity e;

	if(!this.loddistance1)
		this.loddistance1 = 1000;
	if(!this.loddistance2)
		this.loddistance2 = 2000;
	this.lodmodelindex0 = this.modelindex;

	if(this.lodtarget1 != "")
	{
		e = find(NULL, targetname, this.lodtarget1);
		if(e)
		{
			this.lodmodel1 = e.model;
			delete(e);
		}
	}
	if(this.lodtarget2 != "")
	{
		e = find(NULL, targetname, this.lodtarget2);
		if(e)
		{
			this.lodmodel2 = e.model;
			delete(e);
		}
	}

	if(autocvar_loddebug < 0)
	{
		this.lodmodel1 = this.lodmodel2 = ""; // don't even initialize
	}

	if(this.lodmodel1 != "")
	{
		vector mi, ma;
		mi = this.mins;
		ma = this.maxs;

		precache_model(this.lodmodel1);
		_setmodel(this, this.lodmodel1);
		this.lodmodelindex1 = this.modelindex;

		if(this.lodmodel2 != "")
		{
			precache_model(this.lodmodel2);
			_setmodel(this, this.lodmodel2);
			this.lodmodelindex2 = this.modelindex;
		}

		this.modelindex = this.lodmodelindex0;
		setsize(this, mi, ma);
	}

	if(this.lodmodelindex1)
		if (!getSendEntity(this))
			SetCustomizer(this, LOD_customize, LOD_uncustomize);
}

void ApplyMinMaxScaleAngles(entity e)
{
	if(e.angles.x != 0 || e.angles.z != 0 || e.avelocity.x != 0 || e.avelocity.z != 0) // "weird" rotation
	{
		e.maxs = '1 1 1' * vlen(
			'1 0 0' * max(-e.mins.x, e.maxs.x) +
			'0 1 0' * max(-e.mins.y, e.maxs.y) +
			'0 0 1' * max(-e.mins.z, e.maxs.z)
		);
		e.mins = -e.maxs;
	}
	else if(e.angles.y != 0 || e.avelocity.y != 0) // yaw only is a bit better
	{
		e.maxs_x = vlen(
			'1 0 0' * max(-e.mins.x, e.maxs.x) +
			'0 1 0' * max(-e.mins.y, e.maxs.y)
		);
		e.maxs_y = e.maxs.x;
		e.mins_x = -e.maxs.x;
		e.mins_y = -e.maxs.x;
	}
	if(e.scale)
		setsize(e, e.mins * e.scale, e.maxs * e.scale);
	else
		setsize(e, e.mins, e.maxs);
}

void SetBrushEntityModel(entity this)
{
 	if(this.model != "")
 	{
 		precache_model(this.model);
		if(this.mins != '0 0 0' || this.maxs != '0 0 0')
		{
			vector mi = this.mins;
			vector ma = this.maxs;
			_setmodel(this, this.model); // no precision needed
			setsize(this, mi, ma);
		}
		else
			_setmodel(this, this.model); // no precision needed
		InitializeEntity(this, LODmodel_attach, INITPRIO_FINDTARGET);
 	}
	setorigin(this, this.origin);
	ApplyMinMaxScaleAngles(this);
}

void SetBrushEntityModelNoLOD(entity this)
{
 	if(this.model != "")
 	{
 		precache_model(this.model);
		if(this.mins != '0 0 0' || this.maxs != '0 0 0')
		{
			vector mi = this.mins;
			vector ma = this.maxs;
			_setmodel(this, this.model); // no precision needed
			setsize(this, mi, ma);
		}
		else
			_setmodel(this, this.model); // no precision needed
 	}
	setorigin(this, this.origin);
	ApplyMinMaxScaleAngles(this);
}

/*
================
InitTrigger
================
*/

void SetMovedir(entity this)
{
	if(this.movedir != '0 0 0')
		this.movedir = normalize(this.movedir);
	else
	{
		makevectors(this.angles);
		this.movedir = v_forward;
	}

	this.angles = '0 0 0';
}

void InitTrigger(entity this)
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	SetMovedir(this);
	this.solid = SOLID_TRIGGER;
	SetBrushEntityModel(this);
	set_movetype(this, MOVETYPE_NONE);
	this.modelindex = 0;
	this.model = "";
}

void InitSolidBSPTrigger(entity this)
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	SetMovedir(this);
	this.solid = SOLID_BSP;
	SetBrushEntityModel(this);
	set_movetype(this, MOVETYPE_NONE); // why was this PUSH? -div0
//	this.modelindex = 0;
	this.model = "";
}

bool InitMovingBrushTrigger(entity this)
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	this.solid = SOLID_BSP;
	SetBrushEntityModel(this);
	set_movetype(this, MOVETYPE_PUSH);
	if(this.modelindex == 0)
	{
		objerror(this, "InitMovingBrushTrigger: no brushes found!");
		return false;
	}
	return true;
}
