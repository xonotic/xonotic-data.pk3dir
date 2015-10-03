#include "miscfunctions.qh"
#include "_all.qh"
#include "antilag.qh"
#include "command/common.qh"
#include "constants.qh"
#include "g_hook.qh"
#include "ipban.qh"
#include "mutators/mutators_include.qh"
#include "t_items.qh"
#include "weapons/accuracy.qh"
#include "weapons/csqcprojectile.qh"
#include "weapons/selection.qh"
#include "../common/command/generic.qh"
#include "../common/constants.qh"
#include "../common/deathtypes.qh"
#include "../common/mapinfo.qh"
#include "../common/notifications.qh"
#include "../common/playerstats.qh"
#include "../common/teams.qh"
#include "../common/triggers/subs.qh"
#include "../common/util.qh"
#include "../common/turrets/sv_turrets.qh"
#include "../common/weapons/all.qh"
#include "../csqcmodellib/sv_model.qh"
#include "../warpzonelib/anglestransform.qh"
#include "../warpzonelib/server.qh"

void crosshair_trace(entity pl)
{
	traceline_antilag(pl, pl.cursor_trace_start, pl.cursor_trace_start + normalize(pl.cursor_trace_endpos - pl.cursor_trace_start) * MAX_SHOT_DISTANCE, MOVE_NORMAL, pl, ANTILAG_LATENCY(pl));
}
void crosshair_trace_plusvisibletriggers(entity pl)
{
	entity first;
	entity e;
	first = findchainfloat(solid, SOLID_TRIGGER);

	for (e = first; e; e = e.chain)
		if (e.model != "")
			e.solid = SOLID_BSP;

	crosshair_trace(pl);

	for (e = first; e; e = e.chain)
		e.solid = SOLID_TRIGGER;
}
void WarpZone_crosshair_trace(entity pl)
{
	WarpZone_traceline_antilag(pl, pl.cursor_trace_start, pl.cursor_trace_start + normalize(pl.cursor_trace_endpos - pl.cursor_trace_start) * MAX_SHOT_DISTANCE, MOVE_NORMAL, pl, ANTILAG_LATENCY(pl));
}


string admin_name(void)
{
	if(autocvar_sv_adminnick != "")
		return autocvar_sv_adminnick;
	else
		return "SERVER ADMIN";
}

void DistributeEvenly_Init(float amount, float totalweight)
{
    if (DistributeEvenly_amount)
    {
        LOG_TRACE("DistributeEvenly_Init: UNFINISHED DISTRIBUTION (", ftos(DistributeEvenly_amount), " for ");
        LOG_TRACE(ftos(DistributeEvenly_totalweight), " left!)\n");
    }
    if (totalweight == 0)
        DistributeEvenly_amount = 0;
    else
        DistributeEvenly_amount = amount;
    DistributeEvenly_totalweight = totalweight;
}
float DistributeEvenly_Get(float weight)
{
    float f;
    if (weight <= 0)
        return 0;
    f = floor(0.5 + DistributeEvenly_amount * weight / DistributeEvenly_totalweight);
    DistributeEvenly_totalweight -= weight;
    DistributeEvenly_amount -= f;
    return f;
}
float DistributeEvenly_GetRandomized(float weight)
{
    float f;
    if (weight <= 0)
        return 0;
    f = floor(random() + DistributeEvenly_amount * weight / DistributeEvenly_totalweight);
    DistributeEvenly_totalweight -= weight;
    DistributeEvenly_amount -= f;
    return f;
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
        LOG_INFO(s, "\n");
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

entity findnearest(vector point, .string field, string value, vector axismod)
{
    entity localhead;
    float i;
    float j;
    float len;
    vector dist;

    float num_nearest;
    num_nearest = 0;

    localhead = find(world, field, value);
    while (localhead)
    {
        if ((localhead.items == IT_KEY1 || localhead.items == IT_KEY2) && localhead.target == "###item###")
            dist = localhead.oldorigin;
        else
            dist = localhead.origin;
        dist = dist - point;
        dist = dist.x * axismod.x * '1 0 0' + dist.y * axismod.y * '0 1 0' + dist.z * axismod.z * '0 0 1';
        len = vlen(dist);

        for (i = 0; i < num_nearest; ++i)
        {
            if (len < nearest_length[i])
                break;
        }

        // now i tells us where to insert at
        //   INSERTION SORT! YOU'VE SEEN IT! RUN!
        if (i < NUM_NEAREST_ENTITIES)
        {
            for (j = NUM_NEAREST_ENTITIES - 1; j >= i; --j)
            {
                nearest_length[j + 1] = nearest_length[j];
                nearest_entity[j + 1] = nearest_entity[j];
            }
            nearest_length[i] = len;
            nearest_entity[i] = localhead;
            if (num_nearest < NUM_NEAREST_ENTITIES)
                num_nearest = num_nearest + 1;
        }

        localhead = find(localhead, field, value);
    }

    // now use the first one from our list that we can see
    for (i = 0; i < num_nearest; ++i)
    {
        traceline(point, nearest_entity[i].origin, true, world);
        if (trace_fraction == 1)
        {
            if (i != 0)
            {
                LOG_TRACE("Nearest point (");
                LOG_TRACE(nearest_entity[0].netname);
                LOG_TRACE(") is not visible, using a visible one.\n");
            }
            return nearest_entity[i];
        }
    }

    if (num_nearest == 0)
        return world;

    LOG_TRACE("Not seeing any location point, using nearest as fallback.\n");
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
    entity loc;
    string ret;
    ret = "somewhere";
    loc = findnearest(p, classname, "target_location", '1 1 1');
    if (loc)
    {
        ret = loc.message;
    }
    else
    {
        loc = findnearest(p, target, "###item###", '1 1 4');
        if (loc)
            ret = loc.netname;
    }
    return ret;
}

string formatmessage(string msg)
{SELFPARAM();
	float p, p1, p2;
	float n;
	vector cursor;
	entity cursor_ent;
	string escape;
	string replacement;
	string ammoitems;
	p = 0;
	n = 7;

	ammoitems = "batteries";
	if(self.items & ITEM_Plasma.m_itemid) ammoitems = ITEM_Plasma.m_name;
	if(self.items & ITEM_Cells.m_itemid) ammoitems = ITEM_Cells.m_name;
	if(self.items & ITEM_Rockets.m_itemid) ammoitems = ITEM_Rockets.m_name;
	if(self.items & ITEM_Shells.m_itemid) ammoitems = ITEM_Shells.m_name;

	WarpZone_crosshair_trace(self);
	cursor = trace_endpos;
	cursor_ent = trace_ent;

	while (1) {
		if (n < 1)
			break; // too many replacements

		n = n - 1;
		p1 = strstr(msg, "%", p); // NOTE: this destroys msg as it's a tempstring!
		p2 = strstr(msg, "\\", p); // NOTE: this destroys msg as it's a tempstring!

		if (p1 < 0)
			p1 = p2;

		if (p2 < 0)
			p2 = p1;

		p = min(p1, p2);

		if (p < 0)
			break;

		replacement = substring(msg, p, 2);
		escape = substring(msg, p + 1, 1);

		switch(escape)
		{
			case "%": replacement = "%"; break;
			case "\\":replacement = "\\"; break;
			case "n": replacement = "\n"; break;
			case "a": replacement = ftos(floor(self.armorvalue)); break;
			case "h": replacement = ftos(floor(self.health)); break;
			case "l": replacement = NearestLocation(self.origin); break;
			case "y": replacement = NearestLocation(cursor); break;
			case "d": replacement = NearestLocation(self.death_origin); break;
			case "w": replacement = WEP_NAME((!self.weapon) ? (!self.switchweapon ? self.cnt : self.switchweapon) : self.weapon); break;
			case "W": replacement = ammoitems; break;
			case "x": replacement = ((cursor_ent.netname == "" || !cursor_ent) ? "nothing" : cursor_ent.netname); break;
			case "s": replacement = ftos(vlen(self.velocity - self.velocity_z * '0 0 1')); break;
			case "S": replacement = ftos(vlen(self.velocity)); break;
			case "t": replacement = seconds_tostring(ceil(max(0, autocvar_timelimit * 60 + game_starttime - time))); break;
			case "T": replacement = seconds_tostring(floor(time - game_starttime)); break;
			default:
			{
				MUTATOR_CALLHOOK(FormatMessage, escape, replacement, msg);
				escape = format_escape;
				replacement = format_replacement;
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
void GetCvars_handleString(string thisname, float f, .string field, string name)
{SELFPARAM();
	if (f < 0)
	{
		if (self.(field))
			strunzone(self.(field));
		self.(field) = string_null;
	}
	else if (f > 0)
	{
		if (thisname == name)
		{
			if (self.(field))
				strunzone(self.(field));
			self.(field) = strzone(argv(f + 1));
		}
	}
	else
		stuffcmd(self, strcat("cl_cmd sendcvar ", name, "\n"));
}
void GetCvars_handleString_Fixup(string thisname, float f, .string field, string name, string(string) func)
{SELFPARAM();
	GetCvars_handleString(thisname, f, field, name);
	if (f >= 0) // also initialize to the fitting value for "" when sending cvars out
		if (thisname == name)
		{
			string s = func(strcat1(self.(field)));
			if (s != self.(field))
			{
				strunzone(self.(field));
				self.(field) = strzone(s);
			}
		}
}
void GetCvars_handleFloat(string thisname, float f, .float field, string name)
{SELFPARAM();
	if (f < 0)
	{
	}
	else if (f > 0)
	{
		if (thisname == name)
			self.(field) = stof(argv(f + 1));
	}
	else
		stuffcmd(self, strcat("cl_cmd sendcvar ", name, "\n"));
}
void GetCvars_handleFloatOnce(string thisname, float f, .float field, string name)
{SELFPARAM();
	if (f < 0)
	{
	}
	else if (f > 0)
	{
		if (thisname == name)
		{
			if (!self.(field))
			{
				self.(field) = stof(argv(f + 1));
				if (!self.(field))
					self.(field) = -1;
			}
		}
	}
	else
	{
		if (!self.(field))
			stuffcmd(self, strcat("cl_cmd sendcvar ", name, "\n"));
	}
}
string W_FixWeaponOrder_ForceComplete_AndBuildImpulseList(string wo)
{SELFPARAM();
	string o;
	o = W_FixWeaponOrder_ForceComplete(wo);
	if(self.weaponorder_byimpulse)
	{
		strunzone(self.weaponorder_byimpulse);
		self.weaponorder_byimpulse = string_null;
	}
	self.weaponorder_byimpulse = strzone(W_FixWeaponOrder_BuildImpulseList(o));
	return o;
}
void GetCvars(float f)
{SELFPARAM();
	string s = string_null;

	if (f > 0)
		s = strcat1(argv(f));

	get_cvars_f = f;
	get_cvars_s = s;
	MUTATOR_CALLHOOK(GetCvars);

	Notification_GetCvars();

	ReplicateVars(this, s, f);

	GetCvars_handleFloat(s, f, autoswitch, "cl_autoswitch");
	GetCvars_handleFloat(s, f, cvar_cl_autoscreenshot, "cl_autoscreenshot");
	GetCvars_handleFloat(s, f, cvar_cl_jetpack_jump, "cl_jetpack_jump");
	GetCvars_handleString(s, f, cvar_g_xonoticversion, "g_xonoticversion");
	GetCvars_handleString(s, f, cvar_cl_physics, "cl_physics");
	GetCvars_handleFloat(s, f, cvar_cl_handicap, "cl_handicap");
	GetCvars_handleFloat(s, f, cvar_cl_clippedspectating, "cl_clippedspectating");
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriority, "cl_weaponpriority", W_FixWeaponOrder_ForceComplete_AndBuildImpulseList);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[0], "cl_weaponpriority0", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[1], "cl_weaponpriority1", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[2], "cl_weaponpriority2", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[3], "cl_weaponpriority3", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[4], "cl_weaponpriority4", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[5], "cl_weaponpriority5", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[6], "cl_weaponpriority6", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[7], "cl_weaponpriority7", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[8], "cl_weaponpriority8", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleString_Fixup(s, f, cvar_cl_weaponpriorities[9], "cl_weaponpriority9", W_FixWeaponOrder_AllowIncomplete);
	GetCvars_handleFloat(s, f, cvar_cl_weaponimpulsemode, "cl_weaponimpulsemode");
	GetCvars_handleFloat(s, f, cvar_cl_autotaunt, "cl_autotaunt");
	GetCvars_handleFloat(s, f, cvar_cl_noantilag, "cl_noantilag");
	GetCvars_handleFloat(s, f, cvar_cl_voice_directional, "cl_voice_directional");
	GetCvars_handleFloat(s, f, cvar_cl_voice_directional_taunt_attenuation, "cl_voice_directional_taunt_attenuation");
	GetCvars_handleFloat(s, f, cvar_cl_accuracy_data_share, "cl_accuracy_data_share");
	GetCvars_handleFloat(s, f, cvar_cl_accuracy_data_receive, "cl_accuracy_data_receive");

	self.cvar_cl_accuracy_data_share = boolean(self.cvar_cl_accuracy_data_share);
	self.cvar_cl_accuracy_data_receive = boolean(self.cvar_cl_accuracy_data_receive);

	GetCvars_handleFloatOnce(s, f, cvar_cl_gunalign, "cl_gunalign");
	GetCvars_handleFloat(s, f, cvar_cl_allow_uid2name, "cl_allow_uid2name");
	GetCvars_handleFloat(s, f, cvar_cl_allow_uidtracking, "cl_allow_uidtracking");
	GetCvars_handleFloat(s, f, cvar_cl_movement_track_canjump, "cl_movement_track_canjump");
	GetCvars_handleFloat(s, f, cvar_cl_newusekeysupported, "cl_newusekeysupported");

	// fixup of switchweapon (needed for LMS or when spectating is disabled, as PutClientInServer comes too early)
	if (f > 0)
	{
		if (s == "cl_weaponpriority")
			self.switchweapon = w_getbestweapon(self);
		if (s == "cl_allow_uidtracking")
			PlayerStats_GameReport_AddPlayer(self);
	}
}

// decolorizes and team colors the player name when needed
string playername(entity p)
{
    string t;
    if (teamplay && !intermission_running && IS_PLAYER(p))
    {
        t = Team_ColorCode(p.team);
        return strcat(t, strdecolorize(p.netname));
    }
    else
        return p.netname;
}

float want_weapon(entity weaponinfo, float allguns) // WEAPONTODO: what still needs done?
{
	int i = weaponinfo.weapon;
	int d = 0;

	if (!i)
		return 0;

	if (g_lms || g_ca || allguns)
	{
		if(weaponinfo.spawnflags & WEP_FLAG_NORMAL)
			d = true;
		else
			d = false;
	}
	else if (g_cts)
		d = (i == WEP_SHOTGUN.m_id);
	else if (g_nexball)
		d = 0; // weapon is set a few lines later
	else
		d = !(!weaponinfo.weaponstart);

	if(g_grappling_hook) // if possible, redirect off-hand hook to on-hand hook
		d |= (i == WEP_HOOK.m_id);
	if(!g_cts && (weaponinfo.spawnflags & WEP_FLAG_MUTATORBLOCKED)) // never default mutator blocked guns
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
	entity e;
	float i, j, t;
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
	start_health = cvar("g_balance_health_start");
	start_armorvalue = cvar("g_balance_armor_start");

	g_weaponarena = 0;
	g_weaponarena_weapons = '0 0 0';

	s = cvar_string("g_weaponarena");
	if (s == "0" || s == "")
	{
		if(g_ca || g_freezetag)
			s = "most";
	}

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
		for (j = WEP_FIRST; j <= WEP_LAST; ++j)
		{
			e = get_weaponinfo(j);
			if (!(e.spawnflags & WEP_FLAG_MUTATORBLOCKED))
				g_weaponarena_weapons |= WepSet_FromWeapon(j);
		}
	}
	else if (s == "most")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Most Weapons";
		for (j = WEP_FIRST; j <= WEP_LAST; ++j)
		{
			e = get_weaponinfo(j);
			if (!(e.spawnflags & WEP_FLAG_MUTATORBLOCKED))
				if (e.spawnflags & WEP_FLAG_NORMAL)
					g_weaponarena_weapons |= WepSet_FromWeapon(j);
		}
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
			for (j = WEP_FIRST; j <= WEP_LAST; ++j)
			{
				e = get_weaponinfo(j);
				if (e.netname == s)
				{
					g_weaponarena_weapons |= WepSet_FromWeapon(j);
					g_weaponarena_list = strcat(g_weaponarena_list, e.message, " & ");
					break;
				}
			}
			if (j > WEP_LAST)
			{
				LOG_INFO("The weapon mutator list contains an unknown weapon ", s, ". Skipped.\n");
			}
		}
		g_weaponarena_list = strzone(substring(g_weaponarena_list, 0, strlen(g_weaponarena_list) - 3));
	}

	if(g_weaponarena)
		g_weaponarena_random = cvar("g_weaponarena_random");
	else
		g_weaponarena_random = 0;
	g_weaponarena_random_with_blaster = cvar("g_weaponarena_random_with_blaster");

	if (g_weaponarena)
	{
		g_weapon_stay = 0; // incompatible
		start_weapons = g_weaponarena_weapons;
		start_items |= IT_UNLIMITED_AMMO;
	}
	else
	{
		for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		{
			e = get_weaponinfo(i);
			int w = want_weapon(e, false);
			if(w & 1)
				start_weapons |= WepSet_FromWeapon(i);
			if(w & 2)
				start_weapons_default |= WepSet_FromWeapon(i);
			if(w & 4)
				start_weapons_defaultmask |= WepSet_FromWeapon(i);
		}
	}

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
			for (i = WEP_FIRST; i <= WEP_LAST; ++i)
			{
				e = get_weaponinfo(i);
				int w = want_weapon(e, g_warmup_allguns);
				if(w & 1)
					warmup_start_weapons |= WepSet_FromWeapon(i);
				if(w & 2)
					warmup_start_weapons_default |= WepSet_FromWeapon(i);
				if(w & 4)
					warmup_start_weapons_defaultmask |= WepSet_FromWeapon(i);
			}
		}
	}

	if (g_jetpack)
		start_items |= ITEM_Jetpack.m_itemid;

	MUTATOR_CALLHOOK(SetStartItems);

	if ((start_items & ITEM_Jetpack.m_itemid) || (g_grappling_hook && (start_weapons & WEPSET_HOOK)))
	{
		start_items |= ITEM_JetpackRegen.m_itemid;
		start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
		warmup_start_ammo_fuel = max(warmup_start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
	}

	WepSet precache_weapons = start_weapons;
	if (g_warmup_allguns != 1)
		precache_weapons |= warmup_start_weapons;
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		e = get_weaponinfo(i);
		if(precache_weapons & WepSet_FromWeapon(i))
			WEP_ACTION(i, WR_INIT);
	}

	start_ammo_shells = max(0, start_ammo_shells);
	start_ammo_nails = max(0, start_ammo_nails);
	start_ammo_rockets = max(0, start_ammo_rockets);
	start_ammo_cells = max(0, start_ammo_cells);
	start_ammo_plasma = max(0, start_ammo_plasma);
	start_ammo_fuel = max(0, start_ammo_fuel);

	warmup_start_ammo_shells = max(0, warmup_start_ammo_shells);
	warmup_start_ammo_nails = max(0, warmup_start_ammo_nails);
	warmup_start_ammo_rockets = max(0, warmup_start_ammo_rockets);
	warmup_start_ammo_cells = max(0, warmup_start_ammo_cells);
	warmup_start_ammo_plasma = max(0, warmup_start_ammo_plasma);
	warmup_start_ammo_fuel = max(0, warmup_start_ammo_fuel);
}

float sound_allowed(float destin, entity e)
{
    // sounds from world may always pass
    for (;;)
    {
        if (e.classname == "body")
            e = e.enemy;
	else if (e.realowner && e.realowner != e)
            e = e.realowner;
	else if (e.owner && e.owner != e)
            e = e.owner;
        else
            break;
    }
    // sounds to self may always pass
    if (destin == MSG_ONE)
        if (e == msg_entity)
            return true;
    // sounds by players can be removed
    if (autocvar_bot_sound_monopoly)
        if (IS_REAL_CLIENT(e))
            return false;
    // anything else may pass
    return true;
}

void soundtoat(float _dest, entity e, vector o, float chan, string samp, float vol, float attenu)
{
    float entno, idx;

    if (!sound_allowed(_dest, e))
        return;

    entno = num_for_edict(e);
    idx = precache_sound_index(samp);

    int sflags;
    sflags = 0;

    attenu = floor(attenu * 64);
    vol = floor(vol * 255);

    if (vol != 255)
        sflags |= SND_VOLUME;
    if (attenu != 64)
        sflags |= SND_ATTENUATION;
    if (entno >= 8192 || chan < 0 || chan > 7)
        sflags |= SND_LARGEENTITY;
    if (idx >= 256)
        sflags |= SND_LARGESOUND;

    WriteByte(_dest, SVC_SOUND);
    WriteByte(_dest, sflags);
    if (sflags & SND_VOLUME)
        WriteByte(_dest, vol);
    if (sflags & SND_ATTENUATION)
        WriteByte(_dest, attenu);
    if (sflags & SND_LARGEENTITY)
    {
        WriteShort(_dest, entno);
        WriteByte(_dest, chan);
    }
    else
    {
        WriteShort(_dest, entno * 8 + chan);
    }
    if (sflags & SND_LARGESOUND)
        WriteShort(_dest, idx);
    else
        WriteByte(_dest, idx);

    WriteCoord(_dest, o.x);
    WriteCoord(_dest, o.y);
    WriteCoord(_dest, o.z);
}
void soundto(float _dest, entity e, float chan, string samp, float vol, float _atten)
{
    vector o;

    if (!sound_allowed(_dest, e))
        return;

    o = e.origin + 0.5 * (e.mins + e.maxs);
    soundtoat(_dest, e, o, chan, samp, vol, _atten);
}
void soundat(entity e, vector o, float chan, string samp, float vol, float _atten)
{
    soundtoat(((chan & 8) ? MSG_ALL : MSG_BROADCAST), e, o, chan, samp, vol, _atten);
}
void stopsoundto(float _dest, entity e, float chan)
{
    float entno;

    if (!sound_allowed(_dest, e))
        return;

    entno = num_for_edict(e);

    if (entno >= 8192 || chan < 0 || chan > 7)
    {
        float idx, sflags;
        idx = precache_sound_index(SND(Null));
        sflags = SND_LARGEENTITY;
        if (idx >= 256)
            sflags |= SND_LARGESOUND;
        WriteByte(_dest, SVC_SOUND);
        WriteByte(_dest, sflags);
        WriteShort(_dest, entno);
        WriteByte(_dest, chan);
        if (sflags & SND_LARGESOUND)
            WriteShort(_dest, idx);
        else
            WriteByte(_dest, idx);
        WriteCoord(_dest, e.origin.x);
        WriteCoord(_dest, e.origin.y);
        WriteCoord(_dest, e.origin.z);
    }
    else
    {
        WriteByte(_dest, SVC_STOPSOUND);
        WriteShort(_dest, entno * 8 + chan);
    }
}
void stopsound(entity e, float chan)
{
    if (!sound_allowed(MSG_BROADCAST, e))
        return;

    stopsoundto(MSG_BROADCAST, e, chan); // unreliable, gets there fast
    stopsoundto(MSG_ALL, e, chan); // in case of packet loss
}

void play2(entity e, string filename)
{
    //stuffcmd(e, strcat("play2 ", filename, "\n"));
    msg_entity = e;
    soundtoat(MSG_ONE, world, '0 0 0', CH_INFO, filename, VOL_BASE, ATTEN_NONE);
}

// use this one if you might be causing spam (e.g. from touch functions that might get called more than once per frame)
.float spamtime;
float spamsound(entity e, float chan, string samp, float vol, float _atten)
{
    if (!sound_allowed(MSG_BROADCAST, e))
        return false;

    if (time > e.spamtime)
    {
        e.spamtime = time;
        _sound(e, chan, samp, vol, _atten);
        return true;
    }
    return false;
}

void play2team(float t, string filename)
{
    entity head;

    if (autocvar_bot_sound_monopoly)
        return;

    FOR_EACH_REALPLAYER(head)
    {
        if (head.team == t)
            play2(head, filename);
    }
}

void play2all(string samp)
{
    if (autocvar_bot_sound_monopoly)
        return;

    _sound(world, CH_INFO, samp, VOL_BASE, ATTEN_NONE);
}

void PrecachePlayerSounds(string f);
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
	float globhandle, i, n;
	string f;

	globhandle = search_begin(pattern, true, false);
	if (globhandle < 0)
		return;
	n = search_getsize(globhandle);
	for (i = 0; i < n; ++i)
	{
		//print(search_getfilename(globhandle, i), "\n");
		f = search_getfilename(globhandle, i);
		precache_playermodel(f);
	}
	search_end(globhandle);
}

void precache()
{SELFPARAM();
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
        string s;
        s = autocvar_sv_defaultplayermodel_red;
        if (s != "")
            precache_playermodel(s);
        s = autocvar_sv_defaultplayermodel_blue;
        if (s != "")
            precache_playermodel(s);
        s = autocvar_sv_defaultplayermodel_yellow;
        if (s != "")
            precache_playermodel(s);
        s = autocvar_sv_defaultplayermodel_pink;
        if (s != "")
            precache_playermodel(s);
        s = autocvar_sv_defaultplayermodel;
        if (s != "")
            precache_playermodel(s);
    }

    if (g_footsteps)
    {
        PrecacheGlobalSound((globalsound_step = "misc/footstep0 6"));
        PrecacheGlobalSound((globalsound_metalstep = "misc/metalfootstep0 6"));
    }

    // gore and miscellaneous sounds
    PrecacheGlobalSound((globalsound_fall = "misc/hitground 4"));
    PrecacheGlobalSound((globalsound_metalfall = "misc/metalhitground 4"));

#if 0
    // Disabled this code because it simply does not work (e.g. ignores bgmvolume, overlaps with "cd loop" controlled tracks).

    if (!self.noise && self.music) // quake 3 uses the music field
        self.noise = self.music;

    // plays music for the level if there is any
    if (self.noise)
    {
        precache_sound (self.noise);
        ambientsound ('0 0 0', self.noise, VOL_BASE, ATTEN_NONE);
    }
#endif
}


void make_safe_for_remove(entity e)
{
    if (e.initialize_entity)
    {
        entity ent, prev = world;
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

void objerror(string s)
{SELFPARAM();
    make_safe_for_remove(self);
    builtin_objerror(s);
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

void InitializeEntity(entity e, void(void) func, float order)
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
    prev = world;
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
{SELFPARAM();
    entity startoflist = initialize_entity_first;
    initialize_entity_first = NULL;
    remove = remove_except_protected;
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
        var void() func = e.initialize_entity;
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
        	WITH(entity, self, e, func());
        }
        else
        {
            eprint(e);
            backtrace(strcat("Null function in: ", e.classname, "\n"));
        }
        e = next;
    }
    remove = remove_unsafely;
}

void UncustomizeEntitiesRun()
{SELFPARAM();
    for (entity e = NULL; (e = findfloat(e, uncustomizeentityforclient_set, 1)); )
    {
        WITH(entity, self, e, e.uncustomizeentityforclient());
    }
}
void SetCustomizer(entity e, float(void) customizer, void(void) uncustomizer)
{
    e.customizeentityforclient = customizer;
    e.uncustomizeentityforclient = uncustomizer;
    e.uncustomizeentityforclient_set = !!uncustomizer;
}

void Net_LinkEntity(entity e, bool docull, float dt, bool(entity, int) sendfunc)
{SELFPARAM();
    vector mi, ma;

    if (e.classname == "")
        e.classname = "net_linked";

    if (e.model == "" || self.modelindex == 0)
    {
        mi = e.mins;
        ma = e.maxs;
        setmodel(e, MDL_Null);
        setsize(e, mi, ma);
    }

    e.SendEntity = sendfunc;
    e.SendFlags = 0xFFFFFF;

    if (!docull)
        e.effects |= EF_NODEPTHTEST;

    if (dt)
    {
        e.nextthink = time + dt;
        e.think = SUB_Remove;
    }
}


.float(entity) isEliminated;
float EliminatedPlayers_SendEntity(entity to, float sendflags)
{
	float i, f, b;
	entity e;
	WriteByte(MSG_ENTITY, ENT_CLIENT_ELIMINATEDPLAYERS);
	WriteByte(MSG_ENTITY, sendflags);

	if(sendflags & 1)
	{
		for(i = 1; i <= maxclients; i += 8)
		{
			for(f = 0, e = edict_num(i), b = 1; b < 256; b *= 2, e = nextent(e))
			{
				if(eliminatedPlayers.isEliminated(e))
					f |= b;
			}
			WriteByte(MSG_ENTITY, f);
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


void adaptor_think2touch()
{SELFPARAM();
    entity o;
    o = other;
    other = world;
    self.touch();
    other = o;
}

void adaptor_think2use()
{SELFPARAM();
    entity o, a;
    o = other;
    a = activator;
    activator = world;
    other = world;
    self.use();
    other = o;
    activator = a;
}

void adaptor_think2use_hittype_splash() // for timed projectile detonation
{SELFPARAM();
	if(!(self.flags & FL_ONGROUND)) // if onground, we ARE touching something, but HITTYPE_SPLASH is to be networked if the damage causing projectile is not touching ANYTHING
		self.projectiledeathtype |= HITTYPE_SPLASH;
	adaptor_think2use();
}

// deferred dropping
void DropToFloor_Handler()
{SELFPARAM();
    builtin_droptofloor();
    self.dropped_origin = self.origin;
}

void droptofloor()
{SELFPARAM();
    InitializeEntity(self, DropToFloor_Handler, INITPRIO_DROPTOFLOOR);
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

float SUB_NoImpactCheck()
{SELFPARAM();
	// zero hitcontents = this is not the real impact, but either the
	// mirror-impact of something hitting the projectile instead of the
	// projectile hitting the something, or a touchareagrid one. Neither of
	// these stop the projectile from moving, so...
	if(trace_dphitcontents == 0)
	{
		//dprint("A hit happened with zero hit contents... DEBUG THIS, this should never happen for projectiles! Projectile will self-destruct.\n");
		LOG_TRACEF("A hit from a projectile happened with no hit contents! DEBUG THIS, this should never happen for projectiles! Profectile will self-destruct. (edict: %d, classname: %s, origin: %s)\n", num_for_edict(self), self.classname, vtos(self.origin));
		checkclient();
	}
    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
        return 1;
    if (other == world && self.size != '0 0 0')
    {
        vector tic;
        tic = self.velocity * sys_frametime;
        tic = tic + normalize(tic) * vlen(self.maxs - self.mins);
        traceline(self.origin - tic, self.origin + tic, MOVE_NORMAL, self);
        if (trace_fraction >= 1)
        {
            LOG_TRACE("Odd... did not hit...?\n");
        }
        else if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
        {
            LOG_TRACE("Detected and prevented the sky-grapple bug.\n");
            return 1;
        }
    }

    return 0;
}

#define SUB_OwnerCheck() (other && (other == self.owner))

void W_Crylink_Dequeue(entity e);
float WarpZone_Projectile_Touch_ImpactFilter_Callback()
{SELFPARAM();
	if(SUB_OwnerCheck())
		return true;
	if(SUB_NoImpactCheck())
	{
		if(self.classname == "nade")
			return false; // no checks here
		else if(self.classname == "grapplinghook")
			RemoveGrapplingHook(self.realowner);
		else if(self.classname == "spike")
		{
			W_Crylink_Dequeue(self);
			remove(self);
		}
		else
			remove(self);
		return true;
	}
	if(trace_ent && trace_ent.solid > SOLID_TRIGGER)
		UpdateCSQCProjectile(self);
	return false;
}


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
	else
	{
		LOG_INFO("Received HTTP request data for an invalid id ", ftos(id), ".\n");
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
			db_put(ServerProgsDB, strcat("uid2name", myuid), "");
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
    entity sp;

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
	for(sp = world; (sp = find(sp, classname, "info_player_deathmatch")); )
		if(checkpvs(mstart, sp))
			if((traceline(mstart, sp.origin, MOVE_NORMAL, e), trace_fraction) >= 1)
				break;
	if(!sp)
	{
		for(sp = world; (sp = findflags(sp, flags, FL_ITEM)); )
			if(checkpvs(mstart, sp))
				if((traceline(mstart, sp.origin + (sp.mins + sp.maxs) * 0.5, MOVE_NORMAL, e), trace_fraction) >= 1)
					break;
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
        LOG_TRACE("Needed ", ftos(i + 1), " attempts\n");
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

vector shotorg_adjustfromclient(vector vecs, float y_is_right, float allowcenter, float algn)
{
	switch(algn)
	{
		default:
		case 3: // right
			break;

		case 4: // left
			vecs.y = -vecs.y;
			break;

		case 1:
			if(allowcenter) // 2: allow center handedness
			{
				// center
				vecs.y = 0;
				vecs.z -= 2;
			}
			else
			{
				// right
			}
			break;

		case 2:
			if(allowcenter) // 2: allow center handedness
			{
				// center
				vecs.y = 0;
				vecs.z -= 2;
			}
			else
			{
				// left
				vecs.y = -vecs.y;
			}
			break;
	}
	return vecs;
}

vector shotorg_adjust_values(vector vecs, float y_is_right, float visual, float algn)
{
	string s;
	vector v;

	if (autocvar_g_shootfromeye)
	{
		if (visual)
		{
			if (autocvar_g_shootfromclient) { vecs = shotorg_adjustfromclient(vecs, y_is_right, (autocvar_g_shootfromclient >= 2), algn); }
			else { vecs.y = 0; vecs.z -= 2; }
		}
		else
		{
			vecs.y = 0;
			vecs.z = 0;
		}
	}
	else if (autocvar_g_shootfromcenter)
	{
		vecs.y = 0;
		vecs.z -= 2;
	}
	else if ((s = autocvar_g_shootfromfixedorigin) != "")
	{
		v = stov(s);
		if (y_is_right)
			v.y = -v.y;
		if (v.x != 0)
			vecs.x = v.x;
		vecs.y = v.y;
		vecs.z = v.z;
	}
	else if (autocvar_g_shootfromclient)
	{
		vecs = shotorg_adjustfromclient(vecs, y_is_right, (autocvar_g_shootfromclient >= 2), algn);
	}
	return vecs;
}

vector shotorg_adjust(vector vecs, float y_is_right, float visual)
{SELFPARAM();
	return shotorg_adjust_values(vecs, y_is_right, visual, self.owner.cvar_cl_gunalign);
}


void attach_sameorigin(entity e, entity to, string tag)
{
    vector org, t_forward, t_left, t_up, e_forward, e_up;
    float tagscale;

    org = e.origin - gettaginfo(to, gettagindex(to, tag));
    tagscale = pow(vlen(v_forward), -2); // undo a scale on the tag
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
    setattachment(e, world, "");
    setorigin(e, e.origin);
}

void follow_sameorigin(entity e, entity to)
{
    e.movetype = MOVETYPE_FOLLOW; // make the hole follow
    e.aiment = to; // make the hole follow bmodel
    e.punchangle = to.angles; // the original angles of bmodel
    e.view_ofs = e.origin - to.origin; // relative origin
    e.v_angle = e.angles - to.angles; // relative angles
}

void unfollow_sameorigin(entity e)
{
    e.movetype = MOVETYPE_NONE;
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

.float scale2;

float modeleffect_SendEntity(entity to, int sf)
{SELFPARAM();
	float f;
	WriteByte(MSG_ENTITY, ENT_CLIENT_MODELEFFECT);

	f = 0;
	if(self.velocity != '0 0 0')
		f |= 1;
	if(self.angles != '0 0 0')
		f |= 2;
	if(self.avelocity != '0 0 0')
		f |= 4;

	WriteByte(MSG_ENTITY, f);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteByte(MSG_ENTITY, self.skin);
	WriteByte(MSG_ENTITY, self.frame);
	WriteCoord(MSG_ENTITY, self.origin.x);
	WriteCoord(MSG_ENTITY, self.origin.y);
	WriteCoord(MSG_ENTITY, self.origin.z);
	if(f & 1)
	{
		WriteCoord(MSG_ENTITY, self.velocity.x);
		WriteCoord(MSG_ENTITY, self.velocity.y);
		WriteCoord(MSG_ENTITY, self.velocity.z);
	}
	if(f & 2)
	{
		WriteCoord(MSG_ENTITY, self.angles.x);
		WriteCoord(MSG_ENTITY, self.angles.y);
		WriteCoord(MSG_ENTITY, self.angles.z);
	}
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, self.avelocity.x);
		WriteCoord(MSG_ENTITY, self.avelocity.y);
		WriteCoord(MSG_ENTITY, self.avelocity.z);
	}
	WriteShort(MSG_ENTITY, self.scale * 256.0);
	WriteShort(MSG_ENTITY, self.scale2 * 256.0);
	WriteByte(MSG_ENTITY, self.teleport_time * 100.0);
	WriteByte(MSG_ENTITY, self.fade_time * 100.0);
	WriteByte(MSG_ENTITY, self.alpha * 255.0);

	return true;
}

void modeleffect_spawn(string m, float s, float f, vector o, vector v, vector ang, vector angv, float s0, float s2, float a, float t1, float t2)
{
	entity e;
	float sz;
	e = spawn();
	e.classname = "modeleffect";
	_setmodel(e, m);
	e.frame = f;
	setorigin(e, o);
	e.velocity = v;
	e.angles = ang;
	e.avelocity = angv;
	e.alpha = a;
	e.teleport_time = t1;
	e.fade_time = t2;
	e.skin = s;
	if(s0 >= 0)
		e.scale = s0 / max6(-e.mins.x, -e.mins.y, -e.mins.z, e.maxs.x, e.maxs.y, e.maxs.z);
	else
		e.scale = -s0;
	if(s2 >= 0)
		e.scale2 = s2 / max6(-e.mins.x, -e.mins.y, -e.mins.z, e.maxs.x, e.maxs.y, e.maxs.z);
	else
		e.scale2 = -s2;
	sz = max(e.scale, e.scale2);
	setsize(e, e.mins * sz, e.maxs * sz);
	Net_LinkEntity(e, false, 0.1, modeleffect_SendEntity);
}

void shockwave_spawn(string m, vector org, float sz, float t1, float t2)
{
	return modeleffect_spawn(m, 0, 0, org, '0 0 0', '0 0 0', '0 0 0', 0, sz, 1, t1, t2);
}

float randombit(float bits)
{
	if(!(bits & (bits-1))) // this ONLY holds for powers of two!
		return bits;

	float n, f, b, r;

	r = random();
	b = 0;
	n = 0;

	for(f = 1; f <= bits; f *= 2)
	{
		if(bits & f)
		{
			++n;
			r *= n;
			if(r <= 1)
				b = f;
			else
				r = (r - 1) / (n - 1);
		}
	}

	return b;
}

float randombits(float bits, float k, float error_return)
{
	float r;
	r = 0;
	while(k > 0 && bits != r)
	{
		r += randombit(bits - r);
		--k;
	}
	if(error_return)
		if(k > 0)
			return -1; // all
	return r;
}

void randombit_test(float bits, float iter)
{
	while(iter > 0)
	{
		LOG_INFO(ftos(randombit(bits)), "\n");
		--iter;
	}
}

float ExponentialFalloff(float mindist, float maxdist, float halflifedist, float d)
{
	if(halflifedist > 0)
		return pow(0.5, (bound(mindist, d, maxdist) - mindist) / halflifedist);
	else if(halflifedist < 0)
		return pow(0.5, (bound(mindist, d, maxdist) - maxdist) / halflifedist);
	else
		return 1;
}


.string aiment_classname;
.float aiment_deadflag;
void SetMovetypeFollow(entity ent, entity e)
{
	// FIXME this may not be warpzone aware
	ent.movetype = MOVETYPE_FOLLOW; // make the hole follow
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
	ent.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(ent);
	ent.aiment = world;
}
float LostMovetypeFollow(entity ent)
{
/*
	if(ent.movetype != MOVETYPE_FOLLOW)
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

float isPushable(entity e)
{
	if(e.pushable)
		return true;
	if(IS_VEHICLE(e))
		return false;
	if(e.iscreature)
		return true;
	switch(e.classname)
	{
		case "body":
		case "droppedweapon":
		case "keepawayball":
		case "nexball_basketball":
		case "nexball_football":
			return true;
		case "bullet": // antilagged bullets can't hit this either
			return false;
	}
	if (e.projectiledeathtype)
		return true;
	return false;
}
