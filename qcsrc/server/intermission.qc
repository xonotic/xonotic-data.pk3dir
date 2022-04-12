#include "mapvoting.qh"

#include <common/mapinfo.qh>
#include <common/util.qh>
#include <server/bot/api.qh>
#include <server/bot/default/cvars.qh>
#include <server/campaign.qh>
#include <server/client.qh>
#include <server/mapvoting.qh>
#include <server/scores_rules.qh>
#include <server/world.qh>

string GetGametype()
{
	return MapInfo_Type_ToString(MapInfo_LoadedGametype);
}

string GetMapname()
{
	return mapname;
}

float Map_Count, Map_Current;
string Map_Current_Name;

// NOTE: this now expects the map list to be already tokenized and the count in Map_Count
int GetMaplistPosition()
{
	string map = GetMapname();
	int idx = autocvar_g_maplist_index;

	if(idx >= 0)
	{
		if(idx < Map_Count)
		{
			if(map == argv(idx))
			{
				return idx;
			}
		}
	}

	for(int pos = 0; pos < Map_Count; ++pos)
	{
		if(map == argv(pos))
			return pos;
	}

	// resume normal maplist rotation if current map is not in g_maplist
	return idx;
}

bool MapHasRightSize(string map)
{
	int minplayers = max(0, floor(autocvar_minplayers));
	if (teamplay)
		minplayers = max(0, floor(autocvar_minplayers_per_team) * AvailableTeams());
	if (autocvar_g_maplist_check_waypoints
		&& (currentbots || autocvar_bot_number || player_count < minplayers))
	{
		string checkwp_msg = strcat("checkwp ", map);
		if(!fexists(strcat("maps/", map, ".waypoints")))
		{
			LOG_TRACE(checkwp_msg, ": no waypoints");
			return false;
		}
		LOG_TRACE(checkwp_msg, ": has waypoints");
	}

	if(autocvar_g_maplist_ignore_sizes)
		return true;

	// open map size restriction file
	string opensize_msg = strcat("opensize ", map);
	float fh = fopen(strcat("maps/", map, ".sizes"), FILE_READ);
	int player_limit = ((autocvar_g_maplist_sizes_count_maxplayers) ? GetPlayerLimit() : 0);
	int pcount = ((player_limit > 0) ? min(player_count, player_limit) : player_count); // bind it to the player limit so that forced spectators don't influence the limits
	if(!autocvar_g_maplist_sizes_count_bots)
		pcount -= currentbots;
	if(fh >= 0)
	{
		opensize_msg = strcat(opensize_msg, ": ok, ");
		int mapmin = stoi(fgets(fh));
		int mapmax = stoi(fgets(fh));
		fclose(fh);
		if(pcount < mapmin)
		{
			LOG_TRACE(opensize_msg, "not enough");
			return false;
		}
		if(mapmax && pcount > mapmax)
		{
			LOG_TRACE(opensize_msg, "too many");
			return false;
		}
		LOG_TRACE(opensize_msg, "right size");
		return true;
	}
	LOG_TRACE(opensize_msg, ": not found");
	return true;
}

string Map_Filename(int position)
{
	return strcat("maps/", argv(position), ".bsp");
}

void Map_MarkAsRecent(string m)
{
	cvar_set("g_maplist_mostrecent", strwords(cons(m, autocvar_g_maplist_mostrecent), max(0, autocvar_g_maplist_mostrecent_count)));
}

bool Map_IsRecent(string m)
{
	return strhasword(autocvar_g_maplist_mostrecent, m);
}

bool Map_Check(int position, float pass)
{
	string filename;
	string map_next;
	map_next = argv(position);
	if(pass <= 1)
	{
		if(Map_IsRecent(map_next))
			return false;
	}
	filename = Map_Filename(position);
	if(MapInfo_CheckMap(map_next))
	{
		if(pass == 2)
			return true;
		if(MapHasRightSize(map_next))
			return true;
		return false;
	}
	else
		LOG_DEBUG( "Couldn't select '", filename, "'..." );

	return false;
}

void Map_Goto_SetStr(string nextmapname)
{
	if(getmapname_stored != "")
		strunzone(getmapname_stored);
	if(nextmapname == "")
		getmapname_stored = "";
	else
		getmapname_stored = strzone(nextmapname);
}

void Map_Goto_SetFloat(float position)
{
	cvar_set("g_maplist_index", ftos(position));
	Map_Goto_SetStr(argv(position));
}

void Map_Goto(float reinit)
{
	MapInfo_LoadMap(getmapname_stored, reinit);
}

// return codes of map selectors:
//   -1 = temporary failure (that is, try some method that is guaranteed to succeed)
//   -2 = permanent failure
float MaplistMethod_Iterate() // usual method
{
	float pass, i;

	LOG_TRACE("Trying MaplistMethod_Iterate");

	for(pass = 1; pass <= 2; ++pass)
	{
		for(i = 1; i < Map_Count; ++i)
		{
			float mapindex;
			mapindex = (i + Map_Current) % Map_Count;
			if(Map_Check(mapindex, pass))
				return mapindex;
		}
	}
	return -1;
}

float MaplistMethod_Repeat() // fallback method
{
	LOG_TRACE("Trying MaplistMethod_Repeat");

	if(Map_Check(Map_Current, 2))
		return Map_Current;
	return -2;
}

float MaplistMethod_Random() // random map selection
{
	float i, imax;

	LOG_TRACE("Trying MaplistMethod_Random");

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		float mapindex;
		mapindex = (Map_Current + floor(random() * (Map_Count - 1) + 1)) % Map_Count; // any OTHER map
		if(Map_Check(mapindex, 1))
			return mapindex;
	}
	return -1;
}

float MaplistMethod_Shuffle(float exponent) // more clever shuffling
// the exponent sets a bias on the map selection:
// the higher the exponent, the less likely "shortly repeated" same maps are
{
	float i, j, imax, insertpos;

	LOG_TRACE("Trying MaplistMethod_Shuffle");

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		string newlist;

		// now reinsert this at another position
		insertpos = (random() ** (1 / exponent));       // ]0, 1]
		insertpos = insertpos * (Map_Count - 1);       // ]0, Map_Count - 1]
		insertpos = ceil(insertpos) + 1;               // {2, 3, 4, ..., Map_Count}
		LOG_TRACE("SHUFFLE: insert pos = ", ftos(insertpos));

		// insert the current map there
		newlist = "";
		for(j = 1; j < insertpos; ++j)                 // i == 1: no loop, will be inserted as first; however, i == 1 has been excluded above
			newlist = strcat(newlist, " ", argv(j));
		newlist = strcat(newlist, " ", argv(0));       // now insert the just selected map
		for(j = insertpos; j < Map_Count; ++j)         // i == Map_Count: no loop, has just been inserted as last
			newlist = strcat(newlist, " ", argv(j));
		newlist = substring(newlist, 1, strlen(newlist) - 1);
		cvar_set("g_maplist", newlist);
		Map_Count = tokenizebyseparator(autocvar_g_maplist, " ");

		// NOTE: the selected map has just been inserted at (insertpos-1)th position
		Map_Current = insertpos - 1; // this is not really valid, but this way the fallback has a chance of working
		if(Map_Check(Map_Current, 1))
			return Map_Current;
	}
	return -1;
}

void Maplist_Init()
{
	float i = Map_Count = 0;
	if(autocvar_g_maplist != "")
	{
		Map_Count = tokenizebyseparator(autocvar_g_maplist, " ");
		for (i = 0; i < Map_Count; ++i)
		{
			if (Map_Check(i, 2))
				break;
		}
	}

	if (i == Map_Count)
	{
		bprint( "Maplist contains no usable maps!  Resetting it to default map list.\n" );
		cvar_set("g_maplist", MapInfo_ListAllAllowedMaps(MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags() | MAPINFO_FLAG_NOAUTOMAPLIST));
		if(autocvar_g_maplist_shuffle)
			ShuffleMaplist();
		if(!server_is_dedicated)
			localcmd("\nmenu_cmd sync\n");
		Map_Count = tokenizebyseparator(autocvar_g_maplist, " ");
	}
	if(Map_Count == 0)
		error("empty maplist, cannot select a new map");
	Map_Current = bound(0, GetMaplistPosition(), Map_Count - 1);

	strcpy(Map_Current_Name, argv(Map_Current)); // will be automatically freed on exit thanks to DP
	// this may or may not be correct, but who cares, in the worst case a map
	// isn't chosen in the first pass that should have been
}

string GetNextMap()
{
	Maplist_Init();
	float nextMap = -1;

	if(nextMap == -1)
		if(autocvar_g_maplist_shuffle > 0)
			nextMap = MaplistMethod_Shuffle(autocvar_g_maplist_shuffle + 1);

	if(nextMap == -1)
		if(autocvar_g_maplist_selectrandom)
			nextMap = MaplistMethod_Random();

	if(nextMap == -1)
		nextMap = MaplistMethod_Iterate();

	if(nextMap == -1)
		nextMap = MaplistMethod_Repeat();

	if(nextMap >= 0)
	{
		Map_Goto_SetFloat(nextMap);
		return getmapname_stored;
	}

	return "";
}

float DoNextMapOverride(float reinit)
{
	if(autocvar_g_campaign)
	{
		CampaignPostIntermission();
		alreadychangedlevel = true;
		return true;
	}
	if(autocvar_quit_when_empty)
	{
		if(player_count <= currentbots)
		{
			localcmd("quit\n");
			alreadychangedlevel = true;
			return true;
		}
	}
	if(autocvar_quit_and_redirect != "")
	{
		redirection_target = strzone(autocvar_quit_and_redirect);
		alreadychangedlevel = true;
		return true;
	}
	if (!reinit && autocvar_samelevel) // if samelevel is set, stay on same level
	{
		localcmd("restart\n");
		alreadychangedlevel = true;
		return true;
	}
	if(autocvar_nextmap != "")
	{
		string m;
		m = GameTypeVote_MapInfo_FixName(autocvar_nextmap);
		cvar_set("nextmap",m);

		if(!m || gametypevote)
			return false;
		if(autocvar_sv_vote_gametype)
		{
			Map_Goto_SetStr(m);
			return false;
		}

		if(MapInfo_CheckMap(m))
		{
			Map_Goto_SetStr(m);
			Map_Goto(reinit);
			alreadychangedlevel = true;
			return true;
		}
	}
	if(!reinit && autocvar_lastlevel)
	{
		cvar_settemp_restore();
		localcmd("set lastlevel 0\ntogglemenu 1\n");
		alreadychangedlevel = true;
		return true;
	}
	return false;
}

void GotoNextMap(float reinit)
{
	//string nextmap;
	//float n, nummaps;
	//string s;
	if (alreadychangedlevel)
		return;
	alreadychangedlevel = true;

	string nextMap = GetNextMap();
	if(nextMap == "")
		error("Everything is broken - cannot find a next map. Please report this to the developers.");
	Map_Goto(reinit);
}

void ShuffleMaplist()
{
	cvar_set("g_maplist", shufflewords(autocvar_g_maplist));
}

string GotoMap(string m)
{
	m = GameTypeVote_MapInfo_FixName(m);
	if (!m)
		return "The map you suggested is not available on this server.";
	if (!autocvar_sv_vote_gametype)
	if(!MapInfo_CheckMap(m))
		return "The map you suggested does not support the current game mode.";
	cvar_set("nextmap", m);
	cvar_set("_endmatch", "1");
	if(mapvote_initialized || alreadychangedlevel)
	{
		if(DoNextMapOverride(0))
			return "Map switch initiated.";
		else
			return "Hm... no. For some reason I like THIS map more.";
	}
	else
		return "Map switch will happen after scoreboard.";
}


/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
.float autoscreenshot;
void IntermissionThink(entity this)
{
	FixIntermissionClient(this);

	float server_screenshot = (autocvar_sv_autoscreenshot && CS_CVAR(this).cvar_cl_autoscreenshot);
	float client_screenshot = (CS_CVAR(this).cvar_cl_autoscreenshot == 2);

	if( (server_screenshot || client_screenshot)
		&& ((this.autoscreenshot > 0) && (time > this.autoscreenshot)) )
	{
		this.autoscreenshot = -1;
		if(IS_REAL_CLIENT(this))
		{
			string num = strftime_s(); // strftime(false, "%s") isn't reliable, see strftime_s description
			stuffcmd(this, sprintf("\nscreenshot screenshots/autoscreenshot/%s-%s.jpg; "
				"echo \"^5A screenshot has been taken at request of the server.\"\n", GetMapname(), num));
		}
		return;
	}

	if (time < intermission_exittime)
		return;

	if(!mapvote_initialized)
		if (time < intermission_exittime + 10 && !(PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_JUMP(this) || PHYS_INPUT_BUTTON_ATCK2(this) || PHYS_INPUT_BUTTON_HOOK(this) || PHYS_INPUT_BUTTON_USE(this)))
			return;

	MapVote_Start();
}

void FixIntermissionClient(entity e)
{
	if(!e.autoscreenshot) // initial call
	{
		e.autoscreenshot = time + 0.8;	// used for autoscreenshot
		SetResourceExplicit(e, RES_HEALTH, -2342); // health in the first intermission phase
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(e.(weaponentity))
			{
				e.(weaponentity).effects = EF_NODRAW;
				if (e.(weaponentity).weaponchild)
					e.(weaponentity).weaponchild.effects = EF_NODRAW;
			}
		}
		if(IS_REAL_CLIENT(e))
		{
			stuffcmd(e, "\nscr_printspeed 1000000\n");
			RandomSelection_Init();
			FOREACH_WORD(autocvar_sv_intermission_cdtrack, true, {
				RandomSelection_AddString(it, 1, 1);
			});
			if (RandomSelection_chosen_string != "")
			{
				stuffcmd(e, sprintf("\ncd loop %s\n", RandomSelection_chosen_string));
			}
			msg_entity = e;
			WriteByte(MSG_ONE, SVC_INTERMISSION);
		}
	}
}
