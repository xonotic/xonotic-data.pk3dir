#include "g_subs.qh"

#include <server/defs.qh>
#include <server/miscfunctions.qh>
#include "antilag.qh"
#include "command/common.qh"
#include "../common/state.qh"
#include "../lib/warpzone/common.qh"
#include "../common/mapobjects/subs.qh"

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
		antilag_takeback_all(forent, lag);

	// do the trace
	if(wz)
		WarpZone_TraceBox (v1, mi, ma, v2, nomonst, forent);
	else
		tracebox (v1, mi, ma, v2, nomonst, forent);

	// restore players to current positions
	if (lag)
		antilag_restore_all(forent);

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
	bool noantilag = ((IS_CLIENT(source)) ? CS(source).cvar_cl_noantilag : false);
	if (autocvar_g_antilag != 2 || noantilag)
		lag = 0;
	traceline_antilag_force(source, v1, v2, nomonst, forent, lag);
}
void tracebox_antilag (entity source, vector v1, vector mi, vector ma, vector v2, float nomonst, entity forent, float lag)
{
	bool noantilag = ((IS_CLIENT(source)) ? CS(source).cvar_cl_noantilag : false);
	if (autocvar_g_antilag != 2 || noantilag)
		lag = 0;
	tracebox_antilag_force_wz(source, v1, mi, ma, v2, nomonst, forent, lag, false);
}
void WarpZone_traceline_antilag_force (entity source, vector v1, vector v2, float nomonst, entity forent, float lag)
{
	tracebox_antilag_force_wz(source, v1, '0 0 0', '0 0 0', v2, nomonst, forent, lag, true);
}
void WarpZone_traceline_antilag (entity source, vector v1, vector v2, float nomonst, entity forent, float lag)
{
	bool noantilag = ((IS_CLIENT(source)) ? CS(source).cvar_cl_noantilag : false);
	if (autocvar_g_antilag != 2 || noantilag)
		lag = 0;
	WarpZone_traceline_antilag_force(source, v1, v2, nomonst, forent, lag);
}
void WarpZone_tracebox_antilag (entity source, vector v1, vector mi, vector ma, vector v2, float nomonst, entity forent, float lag)
{
	bool noantilag = ((IS_CLIENT(source)) ? CS(source).cvar_cl_noantilag : false);
	if (autocvar_g_antilag != 2 || noantilag)
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
	vector vec = mindist * '1 0 0';
	int c = 0;
	while (c < 6)
	{
		traceline (org, org + vec, true, NULL);
		vec = vec * -1;
		if (trace_fraction < 1)
		{
			vector loc = trace_endpos;
			traceline (loc, loc + vec, true, NULL);
			if (trace_fraction >= 1)
				org = loc + vec;
		}
		if (c & 1)
		{
			float h = vec.y;
			vec.y = vec.x;
			vec.x = vec.z;
			vec.z = h;
		}
		c = c + 1;
	}

	return org;
}
