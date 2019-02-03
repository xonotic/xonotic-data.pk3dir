#include "miscfunctions.qh"

#include "antilag.qh"
#include "command/common.qh"
#include "constants.qh"
#include "g_hook.qh"
#include "ipban.qh"
#include <server/mutators/_mod.qh>
#include "../common/t_items.qh"
#include "resources.qh"
#include "items.qh"
#include "player.qh"
#include "weapons/accuracy.qh"
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
#include "../common/util.qh"
#include "../common/turrets/sv_turrets.qh"
#include <common/weapons/_all.qh>
#include "../common/vehicles/sv_vehicles.qh"
#include "../common/vehicles/vehicle.qh"
#include "../common/items/_mod.qh"
#include "../common/state.qh"
#include "../common/effects/qc/globalsound.qh"
#include "../common/wepent.qh"
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

void dedicated_print(string input)
{
	if (server_is_dedicated) print(input);
}

void GameLogEcho(string s)
{
    string fn;
    int matches;

    if (autocvar_sv_eventlog_files)
    {
        if (!logfile_open)
        {
            logfile_open = true;
            matches = autocvar_sv_eventlog_files_counter + 1;
            cvar_set("sv_eventlog_files_counter", itos(matches));
            fn = ftos(matches);
            if (strlen(fn) < 8)
                fn = strcat(substring("00000000", 0, 8 - strlen(fn)), fn);
            fn = strcat(autocvar_sv_eventlog_files_nameprefix, fn, autocvar_sv_eventlog_files_namesuffix);
            logfile = fopen(fn, FILE_APPEND);
            fputs(logfile, ":logversion:3\n");
        }
        if (logfile >= 0)
        {
            if (autocvar_sv_eventlog_files_timestamps)
                fputs(logfile, strcat(":time:", strftime(true, "%Y-%m-%d %H:%M:%S", "\n", s, "\n")));
            else
                fputs(logfile, strcat(s, "\n"));
        }
    }
    if (autocvar_sv_eventlog_console)
    {
        dedicated_print(strcat(s, "\n"));
    }
}

void GameLogInit()
{
    logfile_open = 0;
    // will be opened later
}

void GameLogClose()
{
    if (logfile_open && logfile >= 0)
    {
        fclose(logfile);
        logfile = -1;
    }
}

entity findnearest(vector point, bool checkitems, vector axismod)
{
    vector dist;
    int num_nearest = 0;

    IL_EACH(((checkitems) ? g_items : g_locations), ((checkitems) ? (it.target == "###item###") : (it.classname == "target_location")),
    {
    	if ((it.items == IT_KEY1 || it.items == IT_KEY2) && it.target == "###item###")
            dist = it.oldorigin;
        else
            dist = it.origin;
        dist = dist - point;
        dist = dist.x * axismod.x * '1 0 0' + dist.y * axismod.y * '0 1 0' + dist.z * axismod.z * '0 0 1';
        float len = vlen2(dist);

        int l;
        for (l = 0; l < num_nearest; ++l)
        {
            if (len < nearest_length[l])
                break;
        }

        // now i tells us where to insert at
        //   INSERTION SORT! YOU'VE SEEN IT! RUN!
        if (l < NUM_NEAREST_ENTITIES)
        {
            for (int j = NUM_NEAREST_ENTITIES - 1; j >= l; --j)
            {
                nearest_length[j + 1] = nearest_length[j];
                nearest_entity[j + 1] = nearest_entity[j];
            }
            nearest_length[l] = len;
            nearest_entity[l] = it;
            if (num_nearest < NUM_NEAREST_ENTITIES)
                num_nearest = num_nearest + 1;
        }
    });

    // now use the first one from our list that we can see
    for (int j = 0; j < num_nearest; ++j)
    {
        traceline(point, nearest_entity[j].origin, true, NULL);
        if (trace_fraction == 1)
        {
            if (j != 0)
                LOG_TRACEF("Nearest point (%s) is not visible, using a visible one.", nearest_entity[0].netname);
            return nearest_entity[j];
        }
    }

    if (num_nearest == 0)
        return NULL;

    LOG_TRACE("Not seeing any location point, using nearest as fallback.");
    /* DEBUGGING CODE:
    dprint("Candidates were: ");
    for(j = 0; j < num_nearest; ++j)
    {
    	if(j != 0)
    		dprint(", ");
    	dprint(nearest_entity[j].netname);
    }
    dprint("\n");
    */

    return nearest_entity[0];
}

string NearestLocation(vector p)
{
    string ret = "somewhere";
    entity loc = findnearest(p, false, '1 1 1');
    if (loc)
        ret = loc.message;
    else
    {
        loc = findnearest(p, true, '1 1 4');
        if (loc)
            ret = loc.netname;
    }
    return ret;
}

string AmmoNameFromWeaponentity(Weapon wep)
{
	string ammoitems = "batteries";
	switch (wep.ammo_type)
	{
		case RES_SHELLS:  ammoitems = ITEM_Shells.m_name;      break;
		case RES_BULLETS: ammoitems = ITEM_Bullets.m_name;     break;
		case RES_ROCKETS: ammoitems = ITEM_Rockets.m_name;     break;
		case RES_CELLS:   ammoitems = ITEM_Cells.m_name;       break;
		case RES_PLASMA:  ammoitems = ITEM_Plasma.m_name;      break;
		case RES_FUEL:    ammoitems = ITEM_JetpackFuel.m_name; break;
	}
	return ammoitems;
}

string formatmessage(entity this, string msg)
{
	float p, p1, p2;
	float n;
	vector cursor = '0 0 0';
	entity cursor_ent = NULL;
	string escape;
	string replacement;
	p = 0;
	n = 7;
	bool traced = false;

	MUTATOR_CALLHOOK(PreFormatMessage, this, msg);
	msg = M_ARGV(1, string);

	while (1) {
		if (n < 1)
			break; // too many replacements

		n = n - 1;
		p1 = strstrofs(msg, "%", p); // NOTE: this destroys msg as it's a tempstring!
		p2 = strstrofs(msg, "\\", p); // NOTE: this destroys msg as it's a tempstring!

		if (p1 < 0)
			p1 = p2;

		if (p2 < 0)
			p2 = p1;

		p = min(p1, p2);

		if (p < 0)
			break;

		if(!traced)
		{
			WarpZone_crosshair_trace_plusvisibletriggers(this);
			cursor = trace_endpos;
			cursor_ent = trace_ent;
			traced = true;
		}

		replacement = substring(msg, p, 2);
		escape = substring(msg, p + 1, 1);

		.entity weaponentity = weaponentities[0]; // TODO: unhardcode

		switch(escape)
		{
			case "%": replacement = "%"; break;
			case "\\":replacement = "\\"; break;
			case "n": replacement = "\n"; break;
			case "a": replacement = ftos(floor(GetResource(this, RES_ARMOR))); break;
			case "h": replacement = ftos(floor(GetResource(this, RES_HEALTH))); break;
			case "l": replacement = NearestLocation(this.origin); break;
			case "y": replacement = NearestLocation(cursor); break;
			case "d": replacement = NearestLocation(this.death_origin); break;
			case "w": replacement = ((this.(weaponentity).m_weapon == WEP_Null) ? ((this.(weaponentity).m_switchweapon == WEP_Null) ? Weapons_from(this.(weaponentity).cnt) : this.(weaponentity).m_switchweapon) : this.(weaponentity).m_weapon).m_name; break;
			case "W": replacement = AmmoNameFromWeaponentity(this.(weaponentity).m_weapon); break;
			case "x": replacement = ((cursor_ent.netname == "" || !cursor_ent) ? "nothing" : cursor_ent.netname); break;
			case "s": replacement = ftos(vlen(this.velocity - this.velocity_z * '0 0 1')); break;
			case "S": replacement = ftos(vlen(this.velocity)); break;
			case "t": replacement = seconds_tostring(ceil(max(0, autocvar_timelimit * 60 + game_starttime - time))); break;
			case "T": replacement = seconds_tostring(floor(time - game_starttime)); break;
			default:
			{
				MUTATOR_CALLHOOK(FormatMessage, this, escape, replacement, msg);
				replacement = M_ARGV(2, string);
				break;
			}
		}

		msg = strcat(substring(msg, 0, p), replacement, substring(msg, p+2, strlen(msg) - (p+2)));
		p = p + strlen(replacement);
	}
	return msg;
}

/*
=============
GetCvars
=============
Called with:
  0:  sends the request
  >0: receives a cvar from name=argv(f) value=argv(f+1)
*/
void GetCvars_handleString(entity this, entity store, string thisname, float f, .string field, string name)
{
	if (f < 0)
	{
		strfree(store.(field));
	}
	else if (f > 0)
	{
		if (thisname == name)
		{
			strcpy(store.(field), argv(f + 1));
		}
	}
	else
		stuffcmd(this, strcat("cl_cmd sendcvar ", name, "\n"));
}
void GetCvars_handleString_Fixup(entity this, entity store, string thisname, float f, .string field, string name, string(entity, string) func)
{
	GetCvars_handleString(this, store, thisname, f, field, name);
	if (f >= 0) // also initialize to the fitting value for "" when sending cvars out
		if (thisname == name)
		{
			string s = func(this, strcat1(store.(field)));
			if (s != store.(field))
			{
				strcpy(store.(field), s);
			}
		}
}
void GetCvars_handleFloat(entity this, entity store, string thisname, float f, .float field, string name)
{
	if (f < 0)
	{
	}
	else if (f > 0)
	{
		if (thisname == name)
			store.(field) = stof(argv(f + 1));
	}
	else
		stuffcmd(this, strcat("cl_cmd sendcvar ", name, "\n"));
}
void GetCvars_handleFloatOnce(entity this, entity store, string thisname, float f, .float field, string name)
{
	if (f < 0)
	{
	}
	else if (f > 0)
	{
		if (thisname == name)
		{
			if (!store.(field))
			{
				store.(field) = stof(argv(f + 1));
				if (!store.(field))
					store.(field) = -1;
			}
		}
	}
	else
	{
		if (!store.(field))
			stuffcmd(this, strcat("cl_cmd sendcvar ", name, "\n"));
	}
}
string W_FixWeaponOrder_ForceComplete_AndBuildImpulseList(entity this, string wo)
{
	string o = W_FixWeaponOrder_ForceComplete(wo);
	strcpy(CS(this).weaponorder_byimpulse, W_FixWeaponOrder_BuildImpulseList(o));
	return o;
}

REPLICATE(autoswitch, bool, "cl_autoswitch");

REPLICATE(cvar_cl_allow_uid2name, bool, "cl_allow_uid2name");

REPLICATE(cvar_cl_autoscreenshot, int, "cl_autoscreenshot");

REPLICATE(cvar_cl_autotaunt, float, "cl_autotaunt");

REPLICATE(cvar_cl_clippedspectating, bool, "cl_clippedspectating");

REPLICATE(cvar_cl_handicap, float, "cl_handicap");

REPLICATE(cvar_cl_jetpack_jump, bool, "cl_jetpack_jump");

REPLICATE(cvar_cl_movement_track_canjump, bool, "cl_movement_track_canjump");

REPLICATE(cvar_cl_newusekeysupported, bool, "cl_newusekeysupported");

REPLICATE(cvar_cl_noantilag, bool, "cl_noantilag");

REPLICATE(cvar_cl_physics, string, "cl_physics");

REPLICATE(cvar_cl_voice_directional, int, "cl_voice_directional");

REPLICATE(cvar_cl_voice_directional_taunt_attenuation, float, "cl_voice_directional_taunt_attenuation");

REPLICATE(cvar_cl_weaponimpulsemode, int, "cl_weaponimpulsemode");

REPLICATE(cvar_g_xonoticversion, string, "g_xonoticversion");

REPLICATE(cvar_cl_cts_noautoswitch, bool, "cl_cts_noautoswitch");

REPLICATE(cvar_cl_weapon_switch_reload, bool, "cl_weapon_switch_reload");

REPLICATE(cvar_cl_weapon_switch_fallback_to_impulse, bool, "cl_weapon_switch_fallback_to_impulse");

/**
 * @param f -1: cleanup, 0: request, 1: receive
 */
void GetCvars(entity this, entity store, int f)
{
	string s = string_null;

	if (f > 0)
		s = strcat1(argv(f));

	get_cvars_f = f;
	get_cvars_s = s;
	MUTATOR_CALLHOOK(GetCvars);

	Notification_GetCvars(this);

	ReplicateVars(this, store, s, f);

	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriority, "cl_weaponpriority", W_FixWeaponOrder_ForceComplete_AndBuildImpulseList);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[0], "cl_weaponpriority0", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[1], "cl_weaponpriority1", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[2], "cl_weaponpriority2", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[3], "cl_weaponpriority3", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[4], "cl_weaponpriority4", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[5], "cl_weaponpriority5", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[6], "cl_weaponpriority6", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[7], "cl_weaponpriority7", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[8], "cl_weaponpriority8", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(this, store, s, f, cvar_cl_weaponpriorities[9], "cl_weaponpriority9", W_FixWeaponOrder_AllowIncomplete);

	GetCvars_handleFloat(this, store, s, f, cvar_cl_allow_uidtracking, "cl_allow_uidtracking");

	// fixup of switchweapon (needed for LMS or when spectating is disabled, as PutClientInServer comes too early)
	if (f > 0)
	{
		if (s == "cl_weaponpriority")
		{
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				if (this.(weaponentity) && (this.(weaponentity).m_weapon != WEP_Null || slot == 0))
					this.(weaponentity).m_switchweapon = w_getbestweapon(this, weaponentity);
			}
		}
		if (s == "cl_allow_uidtracking")
			PlayerStats_GameReport_AddPlayer(this);
	}
}

// decolorizes and team colors the player name when needed
string playername(entity p, bool team_colorize)
{
    string t;
    if (team_colorize && teamplay && !intermission_running && IS_PLAYER(p))
    {
        t = Team_ColorCode(p.team);
        return strcat(t, strdecolorize(p.netname));
    }
    else
        return p.netname;
}

float want_weapon(entity weaponinfo, float allguns) // WEAPONTODO: what still needs done?
{
	int i = weaponinfo.m_id;
	int d = 0;
	bool allow_mutatorblocked = false;

	if(!i)
		return 0;

	bool mutator_returnvalue = MUTATOR_CALLHOOK(WantWeapon, weaponinfo, d, allguns, allow_mutatorblocked);
	d = M_ARGV(1, float);
	allguns = M_ARGV(2, bool);
	allow_mutatorblocked = M_ARGV(3, bool);

	if(allguns)
	{
		if(weaponinfo.spawnflags & WEP_FLAG_NORMAL)
			d = true;
		else
			d = false;
	}
	else if(!mutator_returnvalue)
		d = !(!weaponinfo.weaponstart);

	if(!allow_mutatorblocked && (weaponinfo.spawnflags & WEP_FLAG_MUTATORBLOCKED)) // never default mutator blocked guns
		d = 0;

	float t = weaponinfo.weaponstartoverride;

	//print(strcat("want_weapon: ", weaponinfo.netname, " - d: ", ftos(d), ", t: ", ftos(t), ". \n"));

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

void readplayerstartcvars()
{
	float i, t;
	string s;

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

	s = cvar_string("g_weaponarena");

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
		FOREACH(Weapons, it != WEP_Null, {
			if(!(it.spawnflags & WEP_FLAG_MUTATORBLOCKED))
				g_weaponarena_weapons |= (it.m_wepset);
		});
	}
	else if (s == "devall")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "All Weapons"; // TODO: report as more than just all weapons?
		FOREACH(Weapons, it != WEP_Null,
		{
			g_weaponarena_weapons |= (it.m_wepset);
		});
	}
	else if (s == "most")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Most Weapons";
		FOREACH(Weapons, it != WEP_Null, {
			if(!(it.spawnflags & WEP_FLAG_MUTATORBLOCKED))
				if(it.spawnflags & WEP_FLAG_NORMAL)
					g_weaponarena_weapons |= (it.m_wepset);
		});
	}
	else if (s == "none")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "No Weapons";
	}
	else
	{
		g_weaponarena = 1;
		t = tokenize_console(s);
		g_weaponarena_list = "";
		for (i = 0; i < t; ++i)
		{
			s = argv(i);
			Weapon wep = Weapons_fromstr(s);
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
		start_items |= IT_UNLIMITED_AMMO;
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

	if(start_items & IT_UNLIMITED_WEAPON_AMMO)
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
		SetResource(random_start_ammo, RES_SHELLS, cvar(
			"g_random_start_shells"));
		SetResource(random_start_ammo, RES_BULLETS, cvar(
			"g_random_start_bullets"));
		SetResource(random_start_ammo, RES_ROCKETS,
			cvar("g_random_start_rockets"));
		SetResource(random_start_ammo, RES_CELLS, cvar(
			"g_random_start_cells"));
		SetResource(random_start_ammo, RES_PLASMA, cvar(
			"g_random_start_plasma"));
	}

	if (warmup_stage)
	{
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

		if (!g_weaponarena && !g_ca && !g_freezetag)
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
				int w = want_weapon(it, g_warmup_allguns);
				WepSet s = (it.m_wepset);
				if(w & 1)
					warmup_start_weapons |= s;
				if(w & 2)
					warmup_start_weapons_default |= s;
				if(w & 4)
					warmup_start_weapons_defaultmask |= s;
			});
		}
	}

	if (g_jetpack)
		start_items |= ITEM_Jetpack.m_itemid;

	MUTATOR_CALLHOOK(SetStartItems);

	if (start_items & ITEM_Jetpack.m_itemid)
	{
		start_items |= ITEM_JetpackRegen.m_itemid;
		start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
		warmup_start_ammo_fuel = max(warmup_start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
	}

	WepSet precache_weapons = start_weapons;
	if (g_warmup_allguns != 1)
		precache_weapons |= warmup_start_weapons;
	FOREACH(Weapons, it != WEP_Null, {
		if(precache_weapons & (it.m_wepset))
			it.wr_init(it);
	});

	start_ammo_shells = max(0, start_ammo_shells);
	start_ammo_nails = max(0, start_ammo_nails);
	start_ammo_rockets = max(0, start_ammo_rockets);
	start_ammo_cells = max(0, start_ammo_cells);
	start_ammo_plasma = max(0, start_ammo_plasma);
	start_ammo_fuel = max(0, start_ammo_fuel);
	SetResource(random_start_ammo, RES_SHELLS, max(0,
		GetResource(random_start_ammo, RES_SHELLS)));
	SetResource(random_start_ammo, RES_BULLETS, max(0,
		GetResource(random_start_ammo, RES_BULLETS)));
	SetResource(random_start_ammo, RES_ROCKETS, max(0,
		GetResource(random_start_ammo, RES_ROCKETS)));
	SetResource(random_start_ammo, RES_CELLS, max(0,
		GetResource(random_start_ammo, RES_CELLS)));
	SetResource(random_start_ammo, RES_PLASMA, max(0,
		GetResource(random_start_ammo, RES_PLASMA)));

	warmup_start_ammo_shells = max(0, warmup_start_ammo_shells);
	warmup_start_ammo_nails = max(0, warmup_start_ammo_nails);
	warmup_start_ammo_rockets = max(0, warmup_start_ammo_rockets);
	warmup_start_ammo_cells = max(0, warmup_start_ammo_cells);
	warmup_start_ammo_plasma = max(0, warmup_start_ammo_plasma);
	warmup_start_ammo_fuel = max(0, warmup_start_ammo_fuel);
}

void precache_playermodel(string m)
{
	float globhandle, i, n;
	string f;

	if(substring(m, -9,5) == "_lod1")
		return;
	if(substring(m, -9,5) == "_lod2")
		return;
	precache_model(m);
	f = strcat(substring(m, 0, -5), "_lod1", substring(m, -4, -1));
	if(fexists(f))
		precache_model(f);
	f = strcat(substring(m, 0, -5), "_lod2", substring(m, -4, -1));
	if(fexists(f))
		precache_model(f);

	globhandle = search_begin(strcat(m, "_*.sounds"), true, false);
	if (globhandle < 0)
		return;
	n = search_getsize(globhandle);
	for (i = 0; i < n; ++i)
	{
		//print(search_getfilename(globhandle, i), "\n");
		f = search_getfilename(globhandle, i);
		PrecachePlayerSounds(f);
	}
	search_end(globhandle);
}
void precache_all_playermodels(string pattern)
{
	int globhandle = search_begin(pattern, true, false);
	if (globhandle < 0) return;
	int n = search_getsize(globhandle);
	for (int i = 0; i < n; ++i)
	{
		string s = search_getfilename(globhandle, i);
		precache_playermodel(s);
	}
	search_end(globhandle);
}

void precache_playermodels(string s)
{
	FOREACH_WORD(s, true, { precache_playermodel(it); });
}

void precache()
{
    // gamemode related things

    // Precache all player models if desired
    if (autocvar_sv_precacheplayermodels)
    {
        PrecachePlayerSounds("sound/player/default.sounds");
        precache_all_playermodels("models/player/*.zym");
        precache_all_playermodels("models/player/*.dpm");
        precache_all_playermodels("models/player/*.md3");
        precache_all_playermodels("models/player/*.psk");
        precache_all_playermodels("models/player/*.iqm");
    }

    if (autocvar_sv_defaultcharacter)
    {
		precache_playermodels(autocvar_sv_defaultplayermodel_red);
		precache_playermodels(autocvar_sv_defaultplayermodel_blue);
		precache_playermodels(autocvar_sv_defaultplayermodel_yellow);
		precache_playermodels(autocvar_sv_defaultplayermodel_pink);
		precache_playermodels(autocvar_sv_defaultplayermodel);
    }

#if 0
    // Disabled this code because it simply does not work (e.g. ignores bgmvolume, overlaps with "cd loop" controlled tracks).

    if (!this.noise && this.music) // quake 3 uses the music field
        this.noise = this.music;

    // plays music for the level if there is any
    if (this.noise)
    {
        precache_sound (this.noise);
        ambientsound ('0 0 0', this.noise, VOL_BASE, ATTEN_NONE);
    }
#endif
}


void make_safe_for_remove(entity e)
{
    if (e.initialize_entity)
    {
        entity ent, prev = NULL;
        for (ent = initialize_entity_first; ent; )
        {
            if ((ent == e) || ((ent.classname == "initialize_entity") && (ent.enemy == e)))
            {
                //print("make_safe_for_remove: getting rid of initializer ", etos(ent), "\n");
                // skip it in linked list
                if (prev)
                {
                    prev.initialize_entity_next = ent.initialize_entity_next;
                    ent = prev.initialize_entity_next;
                }
                else
                {
                    initialize_entity_first = ent.initialize_entity_next;
                    ent = initialize_entity_first;
                }
            }
            else
            {
                prev = ent;
                ent = ent.initialize_entity_next;
            }
        }
    }
}

.float remove_except_protected_forbidden;
void remove_except_protected(entity e)
{
	if(e.remove_except_protected_forbidden)
		error("not allowed to remove this at this point");
	builtin_remove(e);
}

void remove_unsafely(entity e)
{
    if(e.classname == "spike")
        error("Removing spikes is forbidden (crylink bug), please report");
    builtin_remove(e);
}

void remove_safely(entity e)
{
    make_safe_for_remove(e);
    builtin_remove(e);
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

.float(entity) isEliminated;
bool EliminatedPlayers_SendEntity(entity this, entity to, float sendflags)
{
	Stream out = MSG_ENTITY;
	WriteHeader(out, ENT_CLIENT_ELIMINATEDPLAYERS);
	serialize(byte, out, sendflags);
	if (sendflags & 1) {
		for (int i = 1; i <= maxclients; i += 8) {
			int f = 0;
			entity e = edict_num(i);
			for (int b = 0; b < 8; ++b, e = nextent(e)) {
				if (eliminatedPlayers.isEliminated(e)) {
					f |= BIT(b);
				}
			}
			serialize(byte, out, f);
		}
	}
	return true;
}

void EliminatedPlayers_Init(float(entity) isEliminated_func)
{
	if(eliminatedPlayers)
	{
		backtrace("Can't spawn eliminatedPlayers again!");
		return;
	}
	Net_LinkEntity(eliminatedPlayers = spawn(), false, 0, EliminatedPlayers_SendEntity);
	eliminatedPlayers.isEliminated = isEliminated_func;
}




void adaptor_think2use_hittype_splash(entity this) // for timed projectile detonation
{
	if(!(IS_ONGROUND(this))) // if onground, we ARE touching something, but HITTYPE_SPLASH is to be networked if the damage causing projectile is not touching ANYTHING
		this.projectiledeathtype |= HITTYPE_SPLASH;
	adaptor_think2use(this);
}

// deferred dropping
void DropToFloor_Handler(entity this)
{
    WITHSELF(this, builtin_droptofloor());
    this.dropped_origin = this.origin;
}

void droptofloor(entity this)
{
    InitializeEntity(this, DropToFloor_Handler, INITPRIO_DROPTOFLOOR);
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

bool SUB_NoImpactCheck(entity this, entity toucher)
{
	// zero hitcontents = this is not the real impact, but either the
	// mirror-impact of something hitting the projectile instead of the
	// projectile hitting the something, or a touchareagrid one. Neither of
	// these stop the projectile from moving, so...
	if(trace_dphitcontents == 0)
	{
		LOG_TRACEF("A hit from a projectile happened with no hit contents! DEBUG THIS, this should never happen for projectiles! Projectile will self-destruct. (edict: %i, classname: %s, origin: %v)", this, this.classname, this.origin);
		checkclient(this); // TODO: .health is checked in the engine with this, possibly replace with a QC function?
	}
    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
        return true;
    if (toucher == NULL && this.size != '0 0 0')
    {
        vector tic;
        tic = this.velocity * sys_frametime;
        tic = tic + normalize(tic) * vlen(this.maxs - this.mins);
        traceline(this.origin - tic, this.origin + tic, MOVE_NORMAL, this);
        if (trace_fraction >= 1)
        {
            LOG_TRACE("Odd... did not hit...?");
        }
        else if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
        {
            LOG_TRACE("Detected and prevented the sky-grapple bug.");
            return true;
        }
    }

    return false;
}

#define SUB_OwnerCheck(ent,oth) ((oth) && ((oth) == (ent).owner))

bool WarpZone_Projectile_Touch_ImpactFilter_Callback(entity this, entity toucher)
{
	if(SUB_OwnerCheck(this, toucher))
		return true;
	if(SUB_NoImpactCheck(this, toucher))
	{
		if(this.classname == "nade")
			return false; // no checks here
		else if(this.classname == "grapplinghook")
			RemoveHook(this);
		else if(this.classname == "spike")
		{
			W_Crylink_Dequeue(this);
			delete(this);
		}
		else
			delete(this);
		return true;
	}
	if(trace_ent && trace_ent.solid > SOLID_TRIGGER)
		UpdateCSQCProjectile(this);
	return false;
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

string uid2name(string myuid) {
	string s;
	s = db_get(ServerProgsDB, strcat("/uid2name/", myuid));

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

float MoveToRandomLocationWithinBounds(entity e, vector boundmin, vector boundmax, float goodcontents, float badcontents, float badsurfaceflags, float attempts, float maxaboveground, float minviewdistance)
{
    float m, i;
    vector start, org, delta, end, enddown, mstart;

    m = e.dphitcontentsmask;
    e.dphitcontentsmask = goodcontents | badcontents;

    org = boundmin;
    delta = boundmax - boundmin;

    start = end = org;

    for (i = 0; i < attempts; ++i)
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
        enddown = trace_endpos;

        // rule 3: make sure we aren't outside the map. This only works
        // for somewhat well formed maps. A good rule of thumb is that
        // the map should have a convex outside hull.
        // these can be traceLINES as we already verified the starting box
        mstart = start + 0.5 * (e.mins + e.maxs);
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
        if (trace_startsolid)
            continue;
        if (trace_fraction < minviewdistance / vlen(delta))
            continue;

        // rule 5: don't want to look at sky
        if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
            continue;

        // rule 6: we must not end up in trigger_hurt
        if (tracebox_hits_trigger_hurt(start, e.mins, e.maxs, enddown))
            continue;

        break;
    }

    e.dphitcontentsmask = m;

    if (i < attempts)
    {
        setorigin(e, start);
        e.angles = vectoangles(end - start);
        LOG_DEBUG("Needed ", ftos(i + 1), " attempts");
        return true;
    }
    else
        return false;
}

float MoveToRandomMapLocation(entity e, float goodcontents, float badcontents, float badsurfaceflags, float attempts, float maxaboveground, float minviewdistance)
{
	return MoveToRandomLocationWithinBounds(e, world.mins, world.maxs, goodcontents, badcontents, badsurfaceflags, attempts, maxaboveground, minviewdistance);
}

void write_recordmarker(entity pl, float tstart, float dt)
{
    GameLogEcho(strcat(":recordset:", ftos(pl.playerid), ":", ftos(dt)));

    // also write a marker into demo files for demotc-race-record-extractor to find
    stuffcmd(pl,
             strcat(
                 strcat("//", strconv(2, 0, 0, GetGametype()), " RECORD SET ", TIME_ENCODED_TOSTRING(TIME_ENCODE(dt))),
                 " ", ftos(tstart), " ", ftos(dt), "\n"));
}

void attach_sameorigin(entity e, entity to, string tag)
{
    vector org, t_forward, t_left, t_up, e_forward, e_up;
    float tagscale;

    org = e.origin - gettaginfo(to, gettagindex(to, tag));
    tagscale = (vlen(v_forward) ** -2); // undo a scale on the tag
    t_forward = v_forward * tagscale;
    t_left = v_right * -tagscale;
    t_up = v_up * tagscale;

    e.origin_x = org * t_forward;
    e.origin_y = org * t_left;
    e.origin_z = org * t_up;

    // current forward and up directions
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
		e.angles = AnglesTransform_FromVAngles(e.angles);
	else
		e.angles = AnglesTransform_FromAngles(e.angles);
    fixedmakevectors(e.angles);

    // untransform forward, up!
    e_forward.x = v_forward * t_forward;
    e_forward.y = v_forward * t_left;
    e_forward.z = v_forward * t_up;
    e_up.x = v_up * t_forward;
    e_up.y = v_up * t_left;
    e_up.z = v_up * t_up;

    e.angles = fixedvectoangles2(e_forward, e_up);
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
		e.angles = AnglesTransform_ToVAngles(e.angles);
	else
		e.angles = AnglesTransform_ToAngles(e.angles);

    setattachment(e, to, tag);
    setorigin(e, e.origin);
}

void detach_sameorigin(entity e)
{
    vector org;
    org = gettaginfo(e, 0);
    e.angles = fixedvectoangles2(v_forward, v_up);
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
		e.angles = AnglesTransform_ToVAngles(e.angles);
	else
		e.angles = AnglesTransform_ToAngles(e.angles);
    setorigin(e, org);
    setattachment(e, NULL, "");
    setorigin(e, e.origin);
}

void follow_sameorigin(entity e, entity to)
{
    set_movetype(e, MOVETYPE_FOLLOW); // make the hole follow
    e.aiment = to; // make the hole follow bmodel
    e.punchangle = to.angles; // the original angles of bmodel
    e.view_ofs = e.origin - to.origin; // relative origin
    e.v_angle = e.angles - to.angles; // relative angles
}

void unfollow_sameorigin(entity e)
{
    set_movetype(e, MOVETYPE_NONE);
}

entity gettaginfo_relative_ent;
vector gettaginfo_relative(entity e, float tag)
{
    if (!gettaginfo_relative_ent)
    {
        gettaginfo_relative_ent = spawn();
        gettaginfo_relative_ent.effects = EF_NODRAW;
    }
    gettaginfo_relative_ent.model = e.model;
    gettaginfo_relative_ent.modelindex = e.modelindex;
    gettaginfo_relative_ent.frame = e.frame;
    return gettaginfo(gettaginfo_relative_ent, tag);
}

.string aiment_classname;
.float aiment_deadflag;
void SetMovetypeFollow(entity ent, entity e)
{
	// FIXME this may not be warpzone aware
	set_movetype(ent, MOVETYPE_FOLLOW); // make the hole follow
	ent.solid = SOLID_NOT; // MOVETYPE_FOLLOW is always non-solid - this means this cannot be teleported by warpzones any more! Instead, we must notice when our owner gets teleported.
	ent.aiment = e; // make the hole follow bmodel
	ent.punchangle = e.angles; // the original angles of bmodel
	ent.view_ofs = ent.origin - e.origin; // relative origin
	ent.v_angle = ent.angles - e.angles; // relative angles
	ent.aiment_classname = strzone(e.classname);
	ent.aiment_deadflag = e.deadflag;
}
void UnsetMovetypeFollow(entity ent)
{
	set_movetype(ent, MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(ent);
	ent.aiment = NULL;
}
float LostMovetypeFollow(entity ent)
{
/*
	if(ent.move_movetype != MOVETYPE_FOLLOW)
		if(ent.aiment)
			error("???");
*/
	if(ent.aiment)
	{
		if(ent.aiment.classname != ent.aiment_classname)
			return 1;
		if(ent.aiment.deadflag != ent.aiment_deadflag)
			return 1;
	}
	return 0;
}

.bool pushable;
bool isPushable(entity e)
{
	if(e.pushable)
		return true;
	if(IS_VEHICLE(e))
		return false;
	if(e.iscreature)
		return true;
	if (Item_IsLoot(e))
	{
		return true;
	}
	switch(e.classname)
	{
		case "body":
			return true;
		case "bullet": // antilagged bullets can't hit this either
			return false;
	}
	if (e.projectiledeathtype)
		return true;
	return false;
}
