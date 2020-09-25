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

float want_weapon(entity weaponinfo, float allguns)
{
	int d = 0;
	bool allow_mutatorblocked = false;

	if(!weaponinfo.m_id)
		return 0;

	bool mutator_returnvalue = MUTATOR_CALLHOOK(WantWeapon, weaponinfo, d, allguns, allow_mutatorblocked);
	d = M_ARGV(1, float);
	allguns = M_ARGV(2, bool);
	allow_mutatorblocked = M_ARGV(3, bool);

	if(allguns)
		d = boolean((weaponinfo.spawnflags & WEP_FLAG_NORMAL) && !(weaponinfo.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_SPECIALATTACK)));
	else if(!mutator_returnvalue)
		d = !(!weaponinfo.weaponstart);

	if(!allow_mutatorblocked && (weaponinfo.spawnflags & WEP_FLAG_MUTATORBLOCKED)) // never default mutator blocked guns
		d = 0;

	float t = weaponinfo.weaponstartoverride;

	//LOG_INFOF("want_weapon: %s - d: %d t: %d\n", weaponinfo.netname, d, t);

	// bit order in t:
	// 1: want or not
	// 2: is default?
	// 4: is set by default?
	if(t < 0)
		t = 4 | (3 * d);
	else
		t |= (2 * d);

	return t;
}

/// Weapons the player normally starts with outside weapon arena.
WepSet weapons_start()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null, {
		int w = want_weapon(it, false);
		if (w & 1)
			ret |= it.m_wepset;
	});
	return ret;
}

WepSet weapons_all()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null, {
		if (!(it.spawnflags & (WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_SPECIALATTACK)))
			ret |= it.m_wepset;
	});
	return ret;
}

WepSet weapons_devall()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null,
	{
		ret |= it.m_wepset;
	});
	return ret;
}

WepSet weapons_most()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null, {
		if ((it.spawnflags & WEP_FLAG_NORMAL) && !(it.spawnflags & (WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_HIDDEN | WEP_FLAG_SPECIALATTACK)))
			ret |= it.m_wepset;
	});
	return ret;
}

void weaponarena_available_all_update(entity this)
{
	if (weaponsInMapAll)
	{
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_start() | (weaponsInMapAll & weapons_all());
	}
	else
	{
		// if no weapons are available on the map, just fall back to all weapons arena
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_all();
	}
}

void weaponarena_available_devall_update(entity this)
{
	if (weaponsInMapAll)
	{
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_start() | weaponsInMapAll;
	}
	else
	{
		// if no weapons are available on the map, just fall back to devall weapons arena
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_devall();
	}
}

void weaponarena_available_most_update(entity this)
{
	if (weaponsInMapAll)
	{
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_start() | (weaponsInMapAll & weapons_most());
	}
	else
	{
		// if no weapons are available on the map, just fall back to most weapons arena
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_most();
	}
}

void readplayerstartcvars()
{
	// initialize starting values for players
	start_weapons = '0 0 0';
	start_weapons_default = '0 0 0';
	start_weapons_defaultmask = '0 0 0';
	start_items = 0;
	start_ammo_shells = 0;
	start_ammo_nails = 0;
	start_ammo_rockets = 0;
	start_ammo_cells = 0;
	start_ammo_plasma = 0;
	if (random_start_ammo == NULL)
	{
		random_start_ammo = spawn();
	}
	start_health = cvar("g_balance_health_start");
	start_armorvalue = cvar("g_balance_armor_start");

	g_weaponarena = 0;
	g_weaponarena_weapons = '0 0 0';

	string s = cvar_string("g_weaponarena");

	MUTATOR_CALLHOOK(SetWeaponArena, s);
	s = M_ARGV(0, string);

	if (s == "0" || s == "")
	{
		// no arena
	}
	else if (s == "off")
	{
		// forcibly turn off weaponarena
	}
	else if (s == "all" || s == "1")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "All Weapons";
		g_weaponarena_weapons = weapons_all();
	}
	else if (s == "devall")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Dev All Weapons";
		g_weaponarena_weapons = weapons_devall();
	}
	else if (s == "most")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Most Weapons";
		g_weaponarena_weapons = weapons_most();
	}
	else if (s == "all_available")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "All Available Weapons";

		// this needs to run after weaponsInMapAll is initialized
		InitializeEntity(NULL, weaponarena_available_all_update, INITPRIO_FINDTARGET);
	}
	else if (s == "devall_available")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Dev All Available Weapons";

		// this needs to run after weaponsInMapAll is initialized
		InitializeEntity(NULL, weaponarena_available_devall_update, INITPRIO_FINDTARGET);
	}
	else if (s == "most_available")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Most Available Weapons";

		// this needs to run after weaponsInMapAll is initialized
		InitializeEntity(NULL, weaponarena_available_most_update, INITPRIO_FINDTARGET);
	}
	else if (s == "none")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "No Weapons";
	}
	else
	{
		g_weaponarena = 1;
		float t = tokenize_console(s);
		g_weaponarena_list = "";
		for (int j = 0; j < t; ++j)
		{
			s = argv(j);
			Weapon wep = Weapon_from_name(s);
			if(wep != WEP_Null)
			{
				g_weaponarena_weapons |= (wep.m_wepset);
				g_weaponarena_list = strcat(g_weaponarena_list, wep.m_name, " & ");
			}
		}
		g_weaponarena_list = strzone(substring(g_weaponarena_list, 0, strlen(g_weaponarena_list) - 3));
	}

	if (g_weaponarena)
	{
		g_weapon_stay = 0; // incompatible
		start_weapons = g_weaponarena_weapons;
		start_items |= IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS;
	}
	else
	{
		FOREACH(Weapons, it != WEP_Null, {
			int w = want_weapon(it, false);
			WepSet s = it.m_wepset;
			if(w & 1)
				start_weapons |= s;
			if(w & 2)
				start_weapons_default |= s;
			if(w & 4)
				start_weapons_defaultmask |= s;
		});
	}

	if(cvar("g_balance_superweapons_time") < 0)
		start_items |= IT_UNLIMITED_SUPERWEAPONS;

	if(!cvar("g_use_ammunition"))
		start_items |= IT_UNLIMITED_AMMO;

	if(start_items & IT_UNLIMITED_AMMO)
	{
		start_ammo_shells = 999;
		start_ammo_nails = 999;
		start_ammo_rockets = 999;
		start_ammo_cells = 999;
		start_ammo_plasma = 999;
		start_ammo_fuel = 999;
	}
	else
	{
		start_ammo_shells = cvar("g_start_ammo_shells");
		start_ammo_nails = cvar("g_start_ammo_nails");
		start_ammo_rockets = cvar("g_start_ammo_rockets");
		start_ammo_cells = cvar("g_start_ammo_cells");
		start_ammo_plasma = cvar("g_start_ammo_plasma");
		start_ammo_fuel = cvar("g_start_ammo_fuel");
		random_start_weapons_count = cvar("g_random_start_weapons_count");
		SetResource(random_start_ammo, RES_SHELLS, cvar("g_random_start_shells"));
		SetResource(random_start_ammo, RES_BULLETS, cvar("g_random_start_bullets"));
		SetResource(random_start_ammo, RES_ROCKETS,cvar("g_random_start_rockets"));
		SetResource(random_start_ammo, RES_CELLS, cvar("g_random_start_cells"));
		SetResource(random_start_ammo, RES_PLASMA, cvar("g_random_start_plasma"));
	}

	warmup_start_ammo_shells = start_ammo_shells;
	warmup_start_ammo_nails = start_ammo_nails;
	warmup_start_ammo_rockets = start_ammo_rockets;
	warmup_start_ammo_cells = start_ammo_cells;
	warmup_start_ammo_plasma = start_ammo_plasma;
	warmup_start_ammo_fuel = start_ammo_fuel;
	warmup_start_health = start_health;
	warmup_start_armorvalue = start_armorvalue;
	warmup_start_weapons = start_weapons;
	warmup_start_weapons_default = start_weapons_default;
	warmup_start_weapons_defaultmask = start_weapons_defaultmask;

	if (!g_weaponarena)
	{
		warmup_start_ammo_shells = cvar("g_warmup_start_ammo_shells");
		warmup_start_ammo_nails = cvar("g_warmup_start_ammo_nails");
		warmup_start_ammo_rockets = cvar("g_warmup_start_ammo_rockets");
		warmup_start_ammo_cells = cvar("g_warmup_start_ammo_cells");
		warmup_start_ammo_plasma = cvar("g_warmup_start_ammo_plasma");
		warmup_start_ammo_fuel = cvar("g_warmup_start_ammo_fuel");
		warmup_start_health = cvar("g_warmup_start_health");
		warmup_start_armorvalue = cvar("g_warmup_start_armor");
		warmup_start_weapons = '0 0 0';
		warmup_start_weapons_default = '0 0 0';
		warmup_start_weapons_defaultmask = '0 0 0';
		FOREACH(Weapons, it != WEP_Null, {
			int w = want_weapon(it, autocvar_g_warmup_allguns);
			WepSet s = it.m_wepset;
			if(w & 1)
				warmup_start_weapons |= s;
			if(w & 2)
				warmup_start_weapons_default |= s;
			if(w & 4)
				warmup_start_weapons_defaultmask |= s;
		});
	}

	if (autocvar_g_jetpack)
		start_items |= ITEM_Jetpack.m_itemid;

	MUTATOR_CALLHOOK(SetStartItems);

	if (start_items & ITEM_Jetpack.m_itemid)
	{
		start_items |= ITEM_JetpackRegen.m_itemid;
		start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
		warmup_start_ammo_fuel = max(warmup_start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
	}

	start_ammo_shells = max(0, start_ammo_shells);
	start_ammo_nails = max(0, start_ammo_nails);
	start_ammo_rockets = max(0, start_ammo_rockets);
	start_ammo_cells = max(0, start_ammo_cells);
	start_ammo_plasma = max(0, start_ammo_plasma);
	start_ammo_fuel = max(0, start_ammo_fuel);
	SetResource(random_start_ammo, RES_SHELLS,
		max(0, GetResource(random_start_ammo, RES_SHELLS)));
	SetResource(random_start_ammo, RES_BULLETS,
		max(0, GetResource(random_start_ammo, RES_BULLETS)));
	SetResource(random_start_ammo, RES_ROCKETS,
		max(0, GetResource(random_start_ammo, RES_ROCKETS)));
	SetResource(random_start_ammo, RES_CELLS,
		max(0, GetResource(random_start_ammo, RES_CELLS)));
	SetResource(random_start_ammo, RES_PLASMA,
		max(0, GetResource(random_start_ammo, RES_PLASMA)));

	warmup_start_ammo_shells = max(0, warmup_start_ammo_shells);
	warmup_start_ammo_nails = max(0, warmup_start_ammo_nails);
	warmup_start_ammo_rockets = max(0, warmup_start_ammo_rockets);
	warmup_start_ammo_cells = max(0, warmup_start_ammo_cells);
	warmup_start_ammo_plasma = max(0, warmup_start_ammo_plasma);
	warmup_start_ammo_fuel = max(0, warmup_start_ammo_fuel);
}

void InitializeEntity(entity e, void(entity this) func, int order)
{
    entity prev, cur;

    if (!e || e.initialize_entity)
    {
        // make a proxy initializer entity
        entity e_old = e;
        e = new(initialize_entity);
        e.enemy = e_old;
    }

    e.initialize_entity = func;
    e.initialize_entity_order = order;

    cur = initialize_entity_first;
    prev = NULL;
    for (;;)
    {
        if (!cur || cur.initialize_entity_order > order)
        {
            // insert between prev and cur
            if (prev)
                prev.initialize_entity_next = e;
            else
                initialize_entity_first = e;
            e.initialize_entity_next = cur;
            return;
        }
        prev = cur;
        cur = cur.initialize_entity_next;
    }
}
void InitializeEntitiesRun()
{
    entity startoflist = initialize_entity_first;
    initialize_entity_first = NULL;
    delete_fn = remove_except_protected;
    for (entity e = startoflist; e; e = e.initialize_entity_next)
    {
		e.remove_except_protected_forbidden = 1;
    }
    for (entity e = startoflist; e; )
    {
		e.remove_except_protected_forbidden = 0;
        e.initialize_entity_order = 0;
    	entity next = e.initialize_entity_next;
        e.initialize_entity_next = NULL;
        var void(entity this) func = e.initialize_entity;
        e.initialize_entity = func_null;
        if (e.classname == "initialize_entity")
        {
            entity wrappee = e.enemy;
            builtin_remove(e);
            e = wrappee;
        }
        //dprint("Delayed initialization: ", e.classname, "\n");
        if (func)
        {
        	func(e);
        }
        else
        {
            eprint(e);
            backtrace(strcat("Null function in: ", e.classname, "\n"));
        }
        e = next;
    }
    delete_fn = remove_unsafely;
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
