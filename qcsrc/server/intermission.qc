#include "intermission.qh"

#include <common/mapinfo.qh>
#include <common/maplist.qh>
#include <common/mapvoting/_mod.qh>
#include <common/util.qh>
#include <server/bot/api.qh>
#include <server/bot/default/cvars.qh>
#include <server/campaign.qh>
#include <server/client.qh>
#include <server/scores_rules.qh>
#include <server/world.qh>

void Send_NextMap_To_Player(entity pl)
{
	stuffcmd(pl, sprintf("\nsettemp _nextmap %s\n", get_nextmap()));
}

void Set_NextMap(string mapname)
{
	if (mapname != "")
		strcpy(_nextmap, mapname);
	else
		strfree(_nextmap);

	FOREACH_CLIENT(IS_REAL_CLIENT(it), { Send_NextMap_To_Player(it); });
}

string GetGametype()
{
	return MapInfo_Type_ToString(MapInfo_LoadedGametype);
}

string GetMapname()
{
	return mapname;
}

int Map_Count, Map_Current;

// NOTE: this now expects the map list to be already tokenized and the count in Map_Count
int GetMaplistPosition()
{
	string map = GetMapname();
	int idx = autocvar_g_maplist_index;

	if(idx >= 0)
	{
		if(idx < Map_Count)
		{
			if(map == bufstr_get(maplist_buffer, idx))
			{
				return idx;
			}
		}
	}

	for(int pos = 0; pos < Map_Count; ++pos)
	{
		if(map == bufstr_get(maplist_buffer, pos))
			return pos;
	}

	// resume normal maplist rotation if current map is not in g_maplist
	return idx;
}

bool MapHasRightSize(string map)
{
	int minplayers = max(0, floor(autocvar_minplayers));
	if (teamplay)
		minplayers = max(0, floor(autocvar_minplayers_per_team) * AVAILABLE_TEAMS);
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

	// open map size restriction file (sets map_minplayers and map_maxplayers)
	if(!MapReadSizes(map))
		return true; // map has no size restrictions

	string checksize_msg = strcat("MapHasRightSize ", map);
	int pcount = player_count;

	if(!autocvar_g_maplist_sizes_count_bots)
		pcount -= currentbots;
	pcount -= rint(cvar("g_maplist_sizes_specparty") * pcount);
	if (autocvar_g_maplist_sizes_count_maxplayers)
		pcount = min(pcount, GetPlayerLimit()); // bind it to the player limit so that forced spectators don't influence the limits

	// ensure small maps can be selected when pcount is low
	if(map_minplayers <= (_MapInfo_GetTeamPlayBool(MapInfo_CurrentGametype()) ? 4 : 2))
		map_minplayers = 0;

	if(pcount < map_minplayers)
	{
		LOG_TRACE(checksize_msg, ": not enough");
		return false;
	}
	if(map_maxplayers && pcount > map_maxplayers)
	{
		LOG_TRACE(checksize_msg, ": too many");
		return false;
	}
	LOG_TRACE(checksize_msg, ": right size");
	return true;
}

string Map_Filename(string m)
{
	return strcat("maps/", m, ".bsp");
}

void Map_MarkAsRecent(string m)
{
	cvar_set("g_maplist_mostrecent", strwords(cons(m, autocvar_g_maplist_mostrecent), max(0, autocvar_g_maplist_mostrecent_count)));
}

bool Map_IsRecent(string m)
{
	if(autocvar_g_maplist_mostrecent == "")
		return false;
	return strhasword(autocvar_g_maplist_mostrecent, m);
}

bool Map_Check(string m, int pass)
{
	if(pass <= 1)
	{
		if(Map_IsRecent(m))
			return false;
	}
	if(MapInfo_CheckMap(m))
	{
		if(pass == 2)
			return true;
		// MapInfo_Map_flags was set by MapInfo_CheckMap()
		if (MapInfo_Map_flags & MAPINFO_FLAG_DONOTWANT)
			return false;
		if(MapHasRightSize(m))
			return true;
		return false;
	}
	else
	{
		string filename = Map_Filename(m);
		LOG_DEBUG( "Couldn't select '", filename, "'..." );
	}

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

void Map_Goto_SetIndex(int position)
{
	Map_Current = position;
	cvar_set("g_maplist_index", ftos(position));
	Map_Goto_SetStr(bufstr_get(maplist_buffer, position));
}

void Map_Goto(float reinit)
{
	MapInfo_LoadMap(getmapname_stored, reinit);
}

// return codes of map selectors:
//   -1 = temporary failure (that is, try some method that is guaranteed to succeed)
//   -2 = permanent failure
int MaplistMethod_Iterate(void) // usual method
{
	int attempts = 42; // skip advanced checks if this many maps fail

	LOG_TRACE("Trying MaplistMethod_Iterate");

	for(int i = 1; i < Map_Count; ++i)
	{
		int mapindex = (i + Map_Current) % Map_Count;
		if(Map_Check(bufstr_get(maplist_buffer, mapindex), 1))
			return mapindex;

		--attempts;
		if(attempts <= 0)
		{
			LOG_DEBUG("MaplistMethod_Iterate: Couldn't find a suitable map, falling back to next valid");
			break;
		}
	}

	// failing that, just accept the next map in the list
	int mapindex = (1 + Map_Current) % Map_Count;
	return mapindex;
}

int MaplistMethod_Repeat(void) // fallback method
{
	LOG_TRACE("Trying MaplistMethod_Repeat");

	if(Map_Check(bufstr_get(maplist_buffer, Map_Current), 2))
		return Map_Current;
	return -2;
}

int MaplistMethod_Random(void) // random map selection
{
	int i, imax;

	LOG_TRACE("Trying MaplistMethod_Random");

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		int mapindex = (Map_Current + floor(random() * (Map_Count - 1) + 1)) % Map_Count; // any OTHER map
		if(Map_Check(bufstr_get(maplist_buffer, mapindex), 1))
			return mapindex;
	}
	return -1;
}

// The configured map list (g_maplist, else the map list file, else every installed map), unfiltered.
// Held for the level because resolving it can mean a directory scan and a .mapinfo read per map, and
// Maplist_Init() runs more than once per intermission. Cleared with the rest of the SVQC globals on
// level change; MapList_Forget() handles the map set changing under a running server.
int maplist_configured_buffer = -1;

// returns a buffer holding the configured map list, one map per entry, and sets
// maplist_configured_count to how many. Owned by the cache, don't buf_del() it.
int Maplist_Configured()
{
	if(maplist_configured_buffer >= 0)
		return maplist_configured_buffer;

	maplist_configured_buffer = buf_create();
	maplist_configured_count = MapList_ToBuffer(maplist_configured_buffer);
	return maplist_configured_buffer;
}

// appends a map to maplist_buffer at position pos, or at a random position if g_maplist_shuffle is set
// NOTE: inlined maplist_shuffle function to avoid a second buffer, keep both in sync
void Maplist_Append(string map, int pos)
{
	if(autocvar_g_maplist_shuffle)
	{
		int j = floor(random() * (pos + 1));
		if(j != pos)
			bufstr_set(maplist_buffer, pos, bufstr_get(maplist_buffer, j));
		bufstr_set(maplist_buffer, j, map);
	}
	else
		bufstr_set(maplist_buffer, pos, map);
}

// Fills maplist_buffer with the playable maps of the configured list and returns how many. Sets
// maplist_missing to how many entries named a map whose .bsp is gone, so the caller can trim them.
int maplist_missing;
int Maplist_Fill()
{
	int cfg = Maplist_Configured();
	int cnt = 0;
	maplist_missing = 0;

	for(int i = 0; i < maplist_configured_count; ++i)
	{
		string map = bufstr_get(cfg, i);
		if(!fexists(Map_Filename(map)))
		{
			++maplist_missing;
			continue;
		}
		if(!Map_Check(map, 2))
			continue; // playable file, but not in this gametype: keep it in the list, just not in the rotation
		Maplist_Append(map, cnt);
		++cnt;
	}
	return cnt;
}

// Rewrites the configured list without the maps whose .bsp is gone, wherever it's stored.
void Maplist_TrimMissing()
{
	int cfg = Maplist_Configured();
	int keep = buf_create();
	int n = 0;
	for(int i = 0; i < maplist_configured_count; ++i)
	{
		string map = bufstr_get(cfg, i);
		if(fexists(Map_Filename(map)))
			bufstr_set(keep, n++, map);
	}
	if(n > 0)
		MapList_FromBuffer(keep, n);
	buf_del(keep);
	LOG_DEBUGF("Maplist_Init: trimmed %d missing maps from the list", maplist_missing);

	// the store changed underneath the cache
	buf_del(maplist_configured_buffer);
	maplist_configured_buffer = -1;
}

// NOTE: call Maplist_Close when you're done!
int Maplist_Init(void)
{
	maplist_buffer = buf_create();
	int _cnt = Maplist_Fill();

	// Only trim a list that is actually stored somewhere. An unconfigured list comes from the live
	// map glob so nothing in it can be missing, and writing it back would freeze it.
	if(maplist_missing && MapList_Source != MAPLIST_SOURCE_ALL)
	{
		Maplist_TrimMissing();
		if(_cnt == 0)
		{
			// everything the list named is gone; the trimmed store may still resolve to something
			buf_del(maplist_buffer);
			maplist_buffer = buf_create();
			_cnt = Maplist_Fill();
		}
	}

	if(_cnt == 0 && MapList_Source != MAPLIST_SOURCE_ALL)
	{
		// A curated list with nothing playable in it. Drop it and take every installed map, which is
		// what an empty g_maplist and no list file mean.
		bprint("Maplist contains no usable maps!  Falling back to the full map list.\n");
		cvar_set("g_maplist", "");
		MapList_Forget();
		buf_del(maplist_configured_buffer);
		maplist_configured_buffer = -1;

		buf_del(maplist_buffer);
		maplist_buffer = buf_create();
		_cnt = Maplist_Fill();

		if(!autocvar_sv_dedicated)
			localcmd("\nmenu_cmd sync\n");
	}

	Map_Count = buf_getsize(maplist_buffer);

	if(Map_Count == 0)
		error("empty maplist, cannot select a new map");

	Map_Current = bound(0, GetMaplistPosition(), Map_Count - 1);

	return Map_Count;
}

void Maplist_Close()
{
	buf_del(maplist_buffer);
}

// NOTE: call Maplist_Init() before making GetNextMap() call(s)
string GetNextMap(void)
{
	int nextMap = -1;

	if(nextMap == -1 && autocvar_g_maplist_selectrandom)
		nextMap = MaplistMethod_Random();

	if(nextMap == -1)
		nextMap = MaplistMethod_Iterate();

	if(nextMap == -1)
		nextMap = MaplistMethod_Repeat();

	if(nextMap >= 0)
	{
		Map_Goto_SetIndex(nextMap);
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
	if(get_nextmap() != "")
	{
		string m = GameTypeVote_MapInfo_FixName(get_nextmap());
		if (m != get_nextmap())
			Set_NextMap(m);

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

	Maplist_Init();
	string nextMap = GetNextMap();
	Maplist_Close();
	if(nextMap == "")
		error("Everything is broken - cannot find a next map. Please report this to the developers.");
	Map_Goto(reinit);
}

string GotoMap(string m)
{
	m = GameTypeVote_MapInfo_FixName(m);
	if (!m)
		return "The map you suggested is not available on this server.";
	if (!autocvar_sv_vote_gametype)
	if (!MapInfo_CheckMap(m))
		return "The map you suggested does not support the current gametype.";
	if (m != get_nextmap())
		Set_NextMap(m);
	if (!intermission_running)
		cvar_set("_endmatch", "1");
	if (mapvote_initialized || alreadychangedlevel)
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
			// in old clients "cl_autoscreenshot_screenshot_s %s %s;" takes the screenshot
			// "cl_autoscreenshot_screenshot %s %s;" does nothing because the cl_autoscreenshot_screenshot alias
			// doesn't exist; the cl_autoscreenshot_screenshot dummy cvar is created
			// so that "cl_autoscreenshot_screenshot %s %s" doesn't print any warning in console

			// in new clients "cl_autoscreenshot_screenshot %s %s;" takes the screenshot
			// even if the cl_autoscreenshot_screenshot cvar is created, only the cl_autoscreenshot_screenshot alias
			// is executed since only the alias is executed if a cvar with the same name exists
			// cl_autoscreenshot_screenshot_s is not run as cl_autoscreenshot_screenshot alias clears it
			// (it doesn't delete it so that "unalias cl_autoscreenshot_screenshot_s;" doesn't print any warning)

			// this stuffcmd is needed only for Xonotic 0.8.6 or lower
			// the s in cl_autoscreenshot_screenshot_s stands for server alias (alias name can't be longer than 32)
			stuffcmd(this, sprintf("\n"
				"alias cl_autoscreenshot_screenshot_s \"screenshot screenshots/autoscreenshot/%s-%s.jpg\";"
				"set cl_autoscreenshot_screenshot 0;", GetMapname(), matchid));

			// keep only this stuffcmd after the next release
			stuffcmd(this, sprintf("\ncl_autoscreenshot_screenshot %s %s;"
				"echo \"^5A screenshot has been taken at request of the server.\"\n", GetMapname(), matchid));

			// this stuffcmd is needed only for Xonotic 0.8.6 or lower
			stuffcmd(this, "\n"
				"cl_autoscreenshot_screenshot_s %s %s;"
				"unset cl_autoscreenshot_screenshot;"
				"unalias cl_autoscreenshot_screenshot_s;");
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
		e.autoscreenshot = time + 0.1;
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
