// NOTE: Please do NOT add new functions to this file! It is a dumping ground that is in the process of being cleaned up, please find a proper home for your code!

#include "miscfunctions.qh"

#include "antilag.qh"
#include "command/common.qh"
#include "client.qh"
#include "damage.qh"
#include "hook.qh"
#include "world.qh"
#include <server/gamelog.qh>
#include "ipban.qh"
#include <server/intermission.qh>
#include <server/items/items.qh>
#include <server/mutators/_mod.qh>
#include <server/spawnpoints.qh>
#include <server/main.qh>
#include "mapvoting.qh"
#include "resources.qh"
#include <server/items/spawning.qh>
#include "player.qh"
#include "weapons/accuracy.qh"
#include "weapons/common.qh"
#include "weapons/csqcprojectile.qh"
#include "weapons/selection.qh"
#include "../common/command/_mod.qh"
#include "../common/constants.qh"
#include <common/net_linked.qh>
#include <common/weapons/weapon/crylink.qh>
#include "../common/deathtypes/all.qh"
#include "../common/mapinfo.qh"
#include "../common/notifications/all.qh"
#include "../common/playerstats.qh"
#include "../common/teams.qh"
#include "../common/mapobjects/subs.qh"
#include <common/mapobjects/trigger/hurt.qh>
#include <common/mapobjects/target/location.qh>
#include "../common/util.qh"
#include "../common/turrets/sv_turrets.qh"
#include <common/weapons/_all.qh>
#include "../common/vehicles/sv_vehicles.qh"
#include "../common/vehicles/vehicle.qh"
#include "../common/items/_mod.qh"
#include "../common/state.qh"
#include "../common/effects/qc/globalsound.qh"
#include "../common/wepent.qh"
#include <common/weapons/weapon.qh>
#include "../lib/csqcmodel/sv_model.qh"
#include "../lib/warpzone/anglestransform.qh"
#include "../lib/warpzone/server.qh"

void crosshair_trace(entity pl)
{
	traceline_antilag(pl, CS(pl).cursor_trace_start, CS(pl).cursor_trace_start + normalize(CS(pl).cursor_trace_endpos - CS(pl).cursor_trace_start) * max_shot_distance, MOVE_NORMAL, pl, ANTILAG_LATENCY(pl));
}

void crosshair_trace_plusvisibletriggers(entity pl)
{
	crosshair_trace_plusvisibletriggers__is_wz(pl, false);
}

void WarpZone_crosshair_trace_plusvisibletriggers(entity pl)
{
	crosshair_trace_plusvisibletriggers__is_wz(pl, true);
}

void crosshair_trace_plusvisibletriggers__is_wz(entity pl, bool is_wz)
{
	FOREACH_ENTITY_FLOAT(solid, SOLID_TRIGGER,
	{
		if(it.model != "")
		{
			it.solid = SOLID_BSP;
			IL_PUSH(g_ctrace_changed, it);
		}
	});

	if (is_wz)
		WarpZone_crosshair_trace(pl);
	else
		crosshair_trace(pl);

	IL_EACH(g_ctrace_changed, true, { it.solid = SOLID_TRIGGER; });

	IL_CLEAR(g_ctrace_changed);
}

void WarpZone_crosshair_trace(entity pl)
{
	WarpZone_traceline_antilag(pl, CS(pl).cursor_trace_start, CS(pl).cursor_trace_start + normalize(CS(pl).cursor_trace_endpos - CS(pl).cursor_trace_start) * max_shot_distance, MOVE_NORMAL, pl, ANTILAG_LATENCY(pl));
}

float trace_hits_box_a0, trace_hits_box_a1;

float trace_hits_box_1d(float end, float thmi, float thma)
{
    if (end == 0)
    {
        // just check if x is in range
        if (0 < thmi)
            return false;
        if (0 > thma)
            return false;
    }
    else
    {
        // do the trace with respect to x
        // 0 -> end has to stay in thmi -> thma
        trace_hits_box_a0 = max(trace_hits_box_a0, min(thmi / end, thma / end));
        trace_hits_box_a1 = min(trace_hits_box_a1, max(thmi / end, thma / end));
        if (trace_hits_box_a0 > trace_hits_box_a1)
            return false;
    }
    return true;
}

float trace_hits_box(vector start, vector end, vector thmi, vector thma)
{
    end -= start;
    thmi -= start;
    thma -= start;
    // now it is a trace from 0 to end

    trace_hits_box_a0 = 0;
    trace_hits_box_a1 = 1;

    if (!trace_hits_box_1d(end.x, thmi.x, thma.x))
        return false;
    if (!trace_hits_box_1d(end.y, thmi.y, thma.y))
        return false;
    if (!trace_hits_box_1d(end.z, thmi.z, thma.z))
        return false;

    return true;
}

float tracebox_hits_box(vector start, vector mi, vector ma, vector end, vector thmi, vector thma)
{
    return trace_hits_box(start, end, thmi - ma, thma - mi);
}

/** engine callback */
void URI_Get_Callback(float id, float status, string data)
{
	if(url_URI_Get_Callback(id, status, data))
	{
		// handled
	}
	else if (id == URI_GET_DISCARD)
	{
		// discard
	}
	else if (id >= URI_GET_CURL && id <= URI_GET_CURL_END)
	{
		// sv_cmd curl
		Curl_URI_Get_Callback(id, status, data);
	}
	else if (id >= URI_GET_IPBAN && id <= URI_GET_IPBAN_END)
	{
		// online ban list
		OnlineBanList_URI_Get_Callback(id, status, data);
	}
	else if (MUTATOR_CALLHOOK(URI_GetCallback, id, status, data))
	{
		// handled by a mutator
	}
	else
	{
		LOG_INFO("Received HTTP request data for an invalid id ", ftos(id), ".");
	}
}

string uid2name(string myuid)
{
	string s = db_get(ServerProgsDB, strcat("/uid2name/", myuid));

	// FIXME remove this later after 0.6 release
	// convert old style broken records to correct style
	if(s == "")
	{
		s = db_get(ServerProgsDB, strcat("uid2name", myuid));
		if(s != "")
		{
			db_put(ServerProgsDB, strcat("/uid2name/", myuid), s);
			db_remove(ServerProgsDB, strcat("uid2name", myuid));
		}
	}

	if(s == "")
		s = "^1Unregistered Player";
	return s;
}

bool MoveToRandomLocationWithinBounds(entity e, vector boundmin, vector boundmax, float goodcontents, float badcontents, float badsurfaceflags, int attempts, float maxaboveground, float minviewdistance)
{
    float m = e.dphitcontentsmask;
    e.dphitcontentsmask = goodcontents | badcontents;

    vector org = boundmin;
    vector delta = boundmax - boundmin;

    vector start, end;
    start = end = org;
    int j; // used after the loop
    for(j = 0; j < attempts; ++j)
    {
        start.x = org.x + random() * delta.x;
        start.y = org.y + random() * delta.y;
        start.z = org.z + random() * delta.z;

        // rule 1: start inside world bounds, and outside
        // solid, and don't start from somewhere where you can
        // fall down to evil
        tracebox(start, e.mins, e.maxs, start - '0 0 1' * delta.z, MOVE_NORMAL, e);
        if (trace_fraction >= 1)
            continue;
        if (trace_startsolid)
            continue;
        if (trace_dphitcontents & badcontents)
            continue;
        if (trace_dphitq3surfaceflags & badsurfaceflags)
            continue;

        // rule 2: if we are too high, lower the point
        if (trace_fraction * delta.z > maxaboveground)
            start = trace_endpos + '0 0 1' * maxaboveground;
        vector enddown = trace_endpos;

        // rule 3: make sure we aren't outside the map. This only works
        // for somewhat well formed maps. A good rule of thumb is that
        // the map should have a convex outside hull.
        // these can be traceLINES as we already verified the starting box
        vector mstart = start + 0.5 * (e.mins + e.maxs);
        traceline(mstart, mstart + '1 0 0' * delta.x, MOVE_NORMAL, e);
        if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
            continue;
        traceline(mstart, mstart - '1 0 0' * delta.x, MOVE_NORMAL, e);
        if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
            continue;
        traceline(mstart, mstart + '0 1 0' * delta.y, MOVE_NORMAL, e);
        if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
            continue;
        traceline(mstart, mstart - '0 1 0' * delta.y, MOVE_NORMAL, e);
        if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
            continue;
        traceline(mstart, mstart + '0 0 1' * delta.z, MOVE_NORMAL, e);
        if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
            continue;

		// rule 4: we must "see" some spawnpoint or item
	    entity sp = NULL;
	    IL_EACH(g_spawnpoints, checkpvs(mstart, it),
	    {
	    	if((traceline(mstart, it.origin, MOVE_NORMAL, e), trace_fraction) >= 1)
	    	{
	    		sp = it;
	    		break;
	    	}
	    });
		if(!sp)
		{
			int items_checked = 0;
			IL_EACH(g_items, checkpvs(mstart, it),
			{
				if((traceline(mstart, it.origin + (it.mins + it.maxs) * 0.5, MOVE_NORMAL, e), trace_fraction) >= 1)
				{
					sp = it;
					break;
				}

				++items_checked;
				if(items_checked >= attempts)
					break; // sanity
			});

			if(!sp)
				continue;
		}

        // find a random vector to "look at"
        end.x = org.x + random() * delta.x;
        end.y = org.y + random() * delta.y;
        end.z = org.z + random() * delta.z;
        end = start + normalize(end - start) * vlen(delta);

        // rule 4: start TO end must not be too short
        tracebox(start, e.mins, e.maxs, end, MOVE_NORMAL, e);
        if(trace_startsolid)
            continue;
        if(trace_fraction < minviewdistance / vlen(delta))
            continue;

        // rule 5: don't want to look at sky
        if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
            continue;

        // rule 6: we must not end up in trigger_hurt
        if(tracebox_hits_trigger_hurt(start, e.mins, e.maxs, enddown))
            continue;

        break;
    }

    e.dphitcontentsmask = m;

    if(j < attempts)
    {
        setorigin(e, start);
        e.angles = vectoangles(end - start);
        LOG_DEBUG("Needed ", ftos(j + 1), " attempts");
        return true;
    }
    return false;
}

float MoveToRandomMapLocation(entity e, float goodcontents, float badcontents, float badsurfaceflags, float attempts, float maxaboveground, float minviewdistance)
{
	return MoveToRandomLocationWithinBounds(e, world.mins, world.maxs, goodcontents, badcontents, badsurfaceflags, attempts, maxaboveground, minviewdistance);
}
