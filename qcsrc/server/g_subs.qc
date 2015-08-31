#include "g_subs.qh"
#include "_all.qh"

#include "antilag.qh"
#include "command/common.qh"
#include "../warpzonelib/common.qh"

void spawnfunc_info_null (void)
{
	remove(self);
	// if anything breaks, tell the mapper to fix his map! info_null is meant to remove itself immediately.
}

void setanim(entity e, vector anim, float looping, float override, float restart)
{
	if (!anim)
		return; // no animation was given to us! We can't use this.

	if (anim.x == e.animstate_startframe)
	if (anim.y == e.animstate_numframes)
	if (anim.z == e.animstate_framerate)
	{
		if(restart)
		{
			if(restart > 0)
			if(anim.y == 1) // ZYM animation
				BITXOR_ASSIGN(e.effects, EF_RESTARTANIM_BIT);
		}
		else
			return;
	}
	e.animstate_startframe = anim.x;
	e.animstate_numframes = anim.y;
	e.animstate_framerate = anim.z;
	e.animstate_starttime = servertime - 0.1 * serverframetime; // shift it a little bit into the past to prevent float inaccuracy hiccups
	e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
	e.animstate_looping = looping;
	e.animstate_override = override;
	e.frame = e.animstate_startframe;
	e.frame1time = servertime;
}

void updateanim(entity e)
{
	if (time >= e.animstate_endtime)
	{
		if (e.animstate_looping)
		{
			e.animstate_starttime = e.animstate_endtime;
			e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
		}
		e.animstate_override = false;
	}
	e.frame = e.animstate_startframe + bound(0, (time - e.animstate_starttime) * e.animstate_framerate, e.animstate_numframes - 1);
	//print(ftos(time), " -> ", ftos(e.frame), "\n");
}

/*
==================
main

unused but required by the engine
==================
*/
void main (void)
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
	entity player;
	float oldsolid;

	// check whether antilagged traces are enabled
	if (lag < 0.001)
		lag = 0;
	if (!IS_REAL_CLIENT(forent))
		lag = 0; // only antilag for clients

	// change shooter to SOLID_BBOX so the shot can hit corpses
	oldsolid = source.dphitcontentsmask;
	if(source)
		source.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	if (lag)
	{
		// take players back into the past
		FOR_EACH_PLAYER(player)
			if(player != forent)
				antilag_takeback(player, time - lag);
		FOR_EACH_MONSTER(player)
			antilag_takeback(player, time - lag);
	}

	// do the trace
	if(wz)
		WarpZone_TraceBox (v1, mi, ma, v2, nomonst, forent);
	else
		tracebox (v1, mi, ma, v2, nomonst, forent);

	// restore players to current positions
	if (lag)
	{
		FOR_EACH_PLAYER(player)
			if(player != forent)
				antilag_restore(player);
		FOR_EACH_MONSTER(player)
			antilag_restore(player);
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
			LOG_TRACE("HOLY SHIT! When tracing from ", vtos(v1), " to ", vtos(v2), "\n");
			LOG_TRACE("  Nudging gets us nowhere at ", vtos(pos), "\n");
			LOG_TRACE("  trace_endpos is ", vtos(trace_endpos), "\n");
			LOG_TRACE("  trace distance is ", ftos(vlen(pos - trace_endpos)), "\n");
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
		traceline (org, org + vec, true, world);
		vec = vec * -1;
		if (trace_fraction < 1)
		{
			loc = trace_endpos;
			traceline (loc, loc + vec, true, world);
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

float LOD_customize()
{
	float d;

	if(autocvar_loddebug)
	{
		d = autocvar_loddebug;
		if(d == 1)
			self.modelindex = self.lodmodelindex0;
		else if(d == 2 || !self.lodmodelindex2)
			self.modelindex = self.lodmodelindex1;
		else // if(d == 3)
			self.modelindex = self.lodmodelindex2;
		return true;
	}

	// TODO csqc network this so it only gets sent once
	d = vlen(NearestPointOnBox(self, other.origin) - other.origin);
	if(d < self.loddistance1)
		self.modelindex = self.lodmodelindex0;
	else if(!self.lodmodelindex2 || d < self.loddistance2)
		self.modelindex = self.lodmodelindex1;
	else
		self.modelindex = self.lodmodelindex2;

	return true;
}

void LOD_uncustomize()
{
	self.modelindex = self.lodmodelindex0;
}

void LODmodel_attach()
{
	entity e;

	if(!self.loddistance1)
		self.loddistance1 = 1000;
	if(!self.loddistance2)
		self.loddistance2 = 2000;
	self.lodmodelindex0 = self.modelindex;

	if(self.lodtarget1 != "")
	{
		e = find(world, targetname, self.lodtarget1);
		if(e)
		{
			self.lodmodel1 = e.model;
			remove(e);
		}
	}
	if(self.lodtarget2 != "")
	{
		e = find(world, targetname, self.lodtarget2);
		if(e)
		{
			self.lodmodel2 = e.model;
			remove(e);
		}
	}

	if(autocvar_loddebug < 0)
	{
		self.lodmodel1 = self.lodmodel2 = ""; // don't even initialize
	}

	if(self.lodmodel1 != "")
	{
		vector mi, ma;
		mi = self.mins;
		ma = self.maxs;

		precache_model(self.lodmodel1);
		setmodel(self, self.lodmodel1);
		self.lodmodelindex1 = self.modelindex;

		if(self.lodmodel2 != "")
		{
			precache_model(self.lodmodel2);
			setmodel(self, self.lodmodel2);
			self.lodmodelindex2 = self.modelindex;
		}

		self.modelindex = self.lodmodelindex0;
		setsize(self, mi, ma);
	}

	if(self.lodmodelindex1)
		if (!self.SendEntity)
			SetCustomizer(self, LOD_customize, LOD_uncustomize);
}

void ApplyMinMaxScaleAngles(entity e)
{
	if(e.angles.x != 0 || e.angles.z != 0 || self.avelocity.x != 0 || self.avelocity.z != 0) // "weird" rotation
	{
		e.maxs = '1 1 1' * vlen(
			'1 0 0' * max(-e.mins.x, e.maxs.x) +
			'0 1 0' * max(-e.mins.y, e.maxs.y) +
			'0 0 1' * max(-e.mins.z, e.maxs.z)
		);
		e.mins = -e.maxs;
	}
	else if(e.angles.y != 0 || self.avelocity.y != 0) // yaw only is a bit better
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

void SetBrushEntityModel()
{
 	if(self.model != "")
 	{
 		precache_model(self.model);
		if(self.mins != '0 0 0' || self.maxs != '0 0 0')
		{
			vector mi = self.mins;
			vector ma = self.maxs;
			setmodel(self, self.model); // no precision needed
			setsize(self, mi, ma);
		}
		else
			setmodel(self, self.model); // no precision needed
		InitializeEntity(self, LODmodel_attach, INITPRIO_FINDTARGET);
 	}
	setorigin(self, self.origin);
	ApplyMinMaxScaleAngles(self);
}

void SetBrushEntityModelNoLOD()
{
 	if(self.model != "")
 	{
 		precache_model(self.model);
		if(self.mins != '0 0 0' || self.maxs != '0 0 0')
		{
			vector mi = self.mins;
			vector ma = self.maxs;
			setmodel(self, self.model); // no precision needed
			setsize(self, mi, ma);
		}
		else
			setmodel(self, self.model); // no precision needed
 	}
	setorigin(self, self.origin);
	ApplyMinMaxScaleAngles(self);
}

/*
================
InitTrigger
================
*/

void SetMovedir()
{
	if (self.movedir != '0 0 0')
		self.movedir = normalize(self.movedir);
	else
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}

	self.angles = '0 0 0';
}

void InitTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	SetMovedir ();
	self.solid = SOLID_TRIGGER;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
}

void InitSolidBSPTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	SetMovedir ();
	self.solid = SOLID_BSP;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_NONE; // why was this PUSH? -div0
//	self.modelindex = 0;
	self.model = "";
}

float InitMovingBrushTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	self.solid = SOLID_BSP;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_PUSH;
	if(self.modelindex == 0)
	{
		objerror("InitMovingBrushTrigger: no brushes found!");
		return 0;
	}
	return 1;
}
