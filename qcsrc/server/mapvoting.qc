#include "mapvoting.qh"

#include <common/constants.qh>
#include <common/mapinfo.qh>
#include <common/net_linked.qh>
#include <common/playerstats.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <server/client.qh>
#include <server/command/cmd.qh>
#include <server/command/getreplies.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/world.qh>

// definitions

float mapvote_nextthink;
float mapvote_keeptwotime;
float mapvote_timeout;
const int MAPVOTE_SCREENSHOT_DIRS_COUNT = 4;
string mapvote_screenshot_dirs[MAPVOTE_SCREENSHOT_DIRS_COUNT];
int mapvote_screenshot_dirs_count;

int mapvote_count;
int mapvote_count_real;
string mapvote_maps[MAPVOTE_COUNT];
int mapvote_maps_screenshot_dir[MAPVOTE_COUNT];
string mapvote_maps_pakfile[MAPVOTE_COUNT];
bool mapvote_maps_suggested[MAPVOTE_COUNT];
string mapvote_suggestions[MAPVOTE_COUNT];
int mapvote_suggestion_ptr;
int mapvote_voters;
int mapvote_selections[MAPVOTE_COUNT];
int mapvote_maps_flags[MAPVOTE_COUNT];
bool mapvote_run;
bool mapvote_detail;
bool mapvote_abstain;
.int mapvote;

entity mapvote_ent;

/**
 * Returns the gamtype ID from its name, if type_name isn't a real gametype it
 * checks for sv_vote_gametype_(type_name)_type
 */
Gametype GameTypeVote_Type_FromString(string type_name)
{
	Gametype type = MapInfo_Type_FromString(type_name, false);
	if (type == NULL)
		type = MapInfo_Type_FromString(cvar_string(
			strcat("sv_vote_gametype_",type_name,"_type")), false);
	return type;
}

int GameTypeVote_AvailabilityStatus(string type_name)
{
	int flag = GTV_FORBIDDEN;

	Gametype type = MapInfo_Type_FromString(type_name, false);
	if ( type == NULL )
	{
		type = MapInfo_Type_FromString(cvar_string(
			strcat("sv_vote_gametype_",type_name,"_type")), false);
		flag |= GTV_CUSTOM;
	}

	if( type == NULL )
		return flag;

	if ( autocvar_nextmap != "" )
	{
		if ( !MapInfo_Get_ByName(autocvar_nextmap, false, NULL) )
			return flag;
		if (!(MapInfo_Map_supportedGametypes & type.m_flags))
			return flag;
	}

	return flag | GTV_AVAILABLE;
}

int GameTypeVote_GetMask()
{
	int n, j, gametype_mask;
	n = tokenizebyseparator(autocvar_sv_vote_gametype_options, " ");
	n = min(MAPVOTE_COUNT, n);
	gametype_mask = 0;
	for(j = 0; j < n; ++j)
		gametype_mask |= GameTypeVote_Type_FromString(argv(j)).m_flags;
	return gametype_mask;
}

string GameTypeVote_MapInfo_FixName(string m)
{
	if ( autocvar_sv_vote_gametype )
	{
		MapInfo_Enumerate();
		_MapInfo_FilterGametype(GameTypeVote_GetMask(), 0, MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	}
	return MapInfo_FixName(m);
}

void MapVote_ClearAllVotes()
{
	FOREACH_CLIENT(true, { it.mapvote = 0; });
}

void MapVote_UnzoneStrings()
{
	for(int j = 0; j < mapvote_count; ++j)
	{
		strfree(mapvote_maps[j]);
		strfree(mapvote_maps_pakfile[j]);
	}
}

string MapVote_Suggest(entity this, string m)
{
	int i;
	if(m == "")
		return "That's not how to use this command.";
	if(!autocvar_g_maplist_votable_suggestions)
		return "Suggestions are not accepted on this server.";
	if(mapvote_initialized)
	if(!gametypevote)
		return "Can't suggest - voting is already in progress!";
	m = GameTypeVote_MapInfo_FixName(m);
	if (!m)
		return "The map you suggested is not available on this server.";
	if(!autocvar_g_maplist_votable_suggestions_override_mostrecent)
		if(Map_IsRecent(m))
			return "This server does not allow for recent maps to be played again. Please be patient for some rounds.";

	if (!autocvar_sv_vote_gametype)
	if(!MapInfo_CheckMap(m))
		return "The map you suggested does not support the current game mode.";
	for(i = 0; i < mapvote_suggestion_ptr; ++i)
		if(mapvote_suggestions[i] == m)
			return "This map was already suggested.";
	if(mapvote_suggestion_ptr >= MAPVOTE_COUNT)
	{
		i = floor(random() * mapvote_suggestion_ptr);
	}
	else
	{
		i = mapvote_suggestion_ptr;
		mapvote_suggestion_ptr += 1;
	}
	if(mapvote_suggestions[i] != "")
		strunzone(mapvote_suggestions[i]);
	mapvote_suggestions[i] = strzone(m);
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":vote:suggested:", m, ":", ftos(this.playerid)));
	return strcat("Suggestion of ", m, " accepted.");
}

void MapVote_AddVotable(string nextMap, bool isSuggestion)
{
	int j, i, o;
	string pakfile, mapfile;

	if(nextMap == "")
		return;
	for(j = 0; j < mapvote_count; ++j)
		if(mapvote_maps[j] == nextMap)
			return;
	// suggestions might be no longer valid/allowed after gametype switch!
	if(isSuggestion)
		if(!MapInfo_CheckMap(nextMap))
			return;
	mapvote_maps[mapvote_count] = strzone(nextMap);
	mapvote_maps_suggested[mapvote_count] = isSuggestion;

	pakfile = string_null;
	for(i = 0; i < mapvote_screenshot_dirs_count; ++i)
	{
		mapfile = strcat(mapvote_screenshot_dirs[i], "/", nextMap);
		pakfile = whichpack(strcat(mapfile, ".tga"));
		if(pakfile == "")
			pakfile = whichpack(strcat(mapfile, ".jpg"));
		if(pakfile == "")
			pakfile = whichpack(strcat(mapfile, ".png"));
		if(pakfile != "")
			break;
	}
	if(i >= mapvote_screenshot_dirs_count)
		i = 0; // FIXME maybe network this error case, as that means there is no mapshot on the server?
	for(o = strstrofs(pakfile, "/", 0)+1; o > 0; o = strstrofs(pakfile, "/", 0)+1)
		pakfile = substring(pakfile, o, -1);

	mapvote_maps_screenshot_dir[mapvote_count] = i;
	mapvote_maps_pakfile[mapvote_count] = strzone(pakfile);
	mapvote_maps_flags[mapvote_count] = GTV_AVAILABLE;

	mapvote_count += 1;
}

void MapVote_Init()
{
	int i;
	int nmax, smax;

	MapVote_ClearAllVotes();
	MapVote_UnzoneStrings();

	mapvote_count = 0;
	mapvote_detail = !autocvar_g_maplist_votable_nodetail;
	mapvote_abstain = boolean(autocvar_g_maplist_votable_abstain);

	if(mapvote_abstain)
		nmax = min(MAPVOTE_COUNT - 1, autocvar_g_maplist_votable);
	else
		nmax = min(MAPVOTE_COUNT, autocvar_g_maplist_votable);
	smax = min3(nmax, autocvar_g_maplist_votable_suggestions, mapvote_suggestion_ptr);

	// we need this for AddVotable, as that cycles through the screenshot dirs
	mapvote_screenshot_dirs_count = tokenize_console(autocvar_g_maplist_votable_screenshot_dir);
	if(mapvote_screenshot_dirs_count == 0)
		mapvote_screenshot_dirs_count = tokenize_console("maps levelshots");
	mapvote_screenshot_dirs_count = min(mapvote_screenshot_dirs_count, MAPVOTE_SCREENSHOT_DIRS_COUNT);
	for(i = 0; i < mapvote_screenshot_dirs_count; ++i)
		mapvote_screenshot_dirs[i] = strzone(argv(i));

	if(mapvote_suggestion_ptr)
		for(i = 0; i < 100 && mapvote_count < smax; ++i)
			MapVote_AddVotable(mapvote_suggestions[floor(random() * mapvote_suggestion_ptr)], true);

	for(i = 0; i < 100 && mapvote_count < nmax; ++i)
		MapVote_AddVotable(GetNextMap(), false);

	if(mapvote_count == 0)
	{
		bprint( "Maplist contains no single playable map!  Resetting it to default map list.\n" );
		cvar_set("g_maplist", MapInfo_ListAllowedMaps(MapInfo_CurrentGametype(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags()));
		if(autocvar_g_maplist_shuffle)
			ShuffleMaplist();
		localcmd("\nmenu_cmd sync\n");
		for(i = 0; i < 100 && mapvote_count < nmax; ++i)
			MapVote_AddVotable(GetNextMap(), false);
	}

	mapvote_count_real = mapvote_count;
	if(mapvote_abstain)
		MapVote_AddVotable("don't care", false);

	//dprint("mapvote count is ", ftos(mapvote_count), "\n");

	mapvote_keeptwotime = time + autocvar_g_maplist_votable_keeptwotime;
	mapvote_timeout = time + autocvar_g_maplist_votable_timeout;
	if(mapvote_count_real < 3 || mapvote_keeptwotime <= time)
		mapvote_keeptwotime = 0;

	MapVote_Spawn();
}

void MapVote_SendPicture(entity to, int id)
{
	msg_entity = to;
	WriteHeader(MSG_ONE, TE_CSQC_PICTURE);
	WriteByte(MSG_ONE, id);
	WritePicture(MSG_ONE, strcat(mapvote_screenshot_dirs[mapvote_maps_screenshot_dir[id]], "/", mapvote_maps[id]), 3072);
}


void MapVote_WriteMask()
{
	if ( mapvote_count < 24 )
	{
		int mask = 0;
		for(int j = 0; j < mapvote_count; ++j)
		{
			if(mapvote_maps_flags[j] & GTV_AVAILABLE)
				mask |= BIT(j);
		}

		if(mapvote_count < 8)
			WriteByte(MSG_ENTITY, mask);
		else if (mapvote_count < 16)
			WriteShort(MSG_ENTITY,mask);
		else
			WriteLong(MSG_ENTITY, mask);
	}
	else
	{
		for (int j = 0; j < mapvote_count; ++j)
			WriteByte(MSG_ENTITY, mapvote_maps_flags[j]);
	}
}

/*
 * Sends a single map vote option to the client
 */
void MapVote_SendOption(int i)
{
	// abstain
	if(mapvote_abstain && i == mapvote_count - 1)
	{
		WriteString(MSG_ENTITY, ""); // abstain needs no text
		WriteString(MSG_ENTITY, ""); // abstain needs no pack
		WriteByte(MSG_ENTITY, 0); // abstain needs no screenshot dir
	}
	else
	{
		WriteString(MSG_ENTITY, mapvote_maps[i]);
		WriteString(MSG_ENTITY, mapvote_maps_pakfile[i]);
		WriteByte(MSG_ENTITY, mapvote_maps_screenshot_dir[i]);
	}
}

/*
 * Sends a single gametype vote option to the client
 */
void GameTypeVote_SendOption(int i)
{
	// abstain
	if(mapvote_abstain && i == mapvote_count - 1)
	{
		WriteString(MSG_ENTITY, ""); // abstain needs no text
		WriteByte(MSG_ENTITY, GTV_AVAILABLE);
	}
	else
	{
		string type_name = mapvote_maps[i];
		WriteString(MSG_ENTITY, type_name);
		WriteByte(MSG_ENTITY, mapvote_maps_flags[i]);
		if ( mapvote_maps_flags[i] & GTV_CUSTOM )
		{
			WriteString(MSG_ENTITY, cvar_string(
				strcat("sv_vote_gametype_",type_name,"_name")));
			WriteString(MSG_ENTITY, cvar_string(
				strcat("sv_vote_gametype_",type_name,"_description")));
			WriteString(MSG_ENTITY, cvar_string(
				strcat("sv_vote_gametype_",type_name,"_type")));
		}
	}
}

bool MapVote_SendEntity(entity this, entity to, int sf)
{
	int i;

	if(sf & 1)
		sf &= ~2; // if we send 1, we don't need to also send 2

	WriteHeader(MSG_ENTITY, ENT_CLIENT_MAPVOTE);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		// flag 1 == initialization
		for(i = 0; i < mapvote_screenshot_dirs_count; ++i)
			WriteString(MSG_ENTITY, mapvote_screenshot_dirs[i]);
		WriteString(MSG_ENTITY, "");
		WriteByte(MSG_ENTITY, mapvote_count);
		WriteByte(MSG_ENTITY, mapvote_abstain);
		WriteByte(MSG_ENTITY, mapvote_detail);
		WriteCoord(MSG_ENTITY, mapvote_timeout);

		if ( gametypevote )
		{
			// gametype vote
			WriteByte(MSG_ENTITY, 1);
			WriteString(MSG_ENTITY, autocvar_nextmap);
		}
		else if ( autocvar_sv_vote_gametype )
		{
			// map vote but gametype has been chosen via voting screen
			WriteByte(MSG_ENTITY, 2);
			WriteString(MSG_ENTITY, MapInfo_Type_ToText(MapInfo_CurrentGametype()));
		}
		else
			WriteByte(MSG_ENTITY, 0); // map vote

		MapVote_WriteMask();

		// Send data for the vote options
		for(i = 0; i < mapvote_count; ++i)
		{
			if(gametypevote)
				GameTypeVote_SendOption(i);
			else
				MapVote_SendOption(i);
		}
	}

	if(sf & 2)
	{
		// flag 2 == update of mask
		MapVote_WriteMask();
	}

	if(sf & 4)
	{
		if(mapvote_detail)
			for(i = 0; i < mapvote_count; ++i)
				if ( mapvote_maps_flags[i] & GTV_AVAILABLE )
					WriteByte(MSG_ENTITY, mapvote_selections[i]);

		WriteByte(MSG_ENTITY, to.mapvote);
	}

	return true;
}

void MapVote_Spawn()
{
	Net_LinkEntity(mapvote_ent = new(mapvote_ent), false, 0, MapVote_SendEntity);
}

void MapVote_TouchMask()
{
	mapvote_ent.SendFlags |= 2;
}

void MapVote_TouchVotes(entity voter)
{
	mapvote_ent.SendFlags |= 4;
}

bool MapVote_Finished(int mappos)
{
	if(alreadychangedlevel)
		return false;

	string result;
	int i;
	int didntvote;

	if(autocvar_sv_eventlog)
	{
		result = strcat(":vote:finished:", mapvote_maps[mappos]);
		result = strcat(result, ":", ftos(mapvote_selections[mappos]), "::");
		didntvote = mapvote_voters;
		for(i = 0; i < mapvote_count; ++i)
			if(mapvote_maps_flags[i] & GTV_AVAILABLE )
			{
				didntvote -= mapvote_selections[i];
				if(i != mappos)
				{
					result = strcat(result, ":", mapvote_maps[i]);
					result = strcat(result, ":", ftos(mapvote_selections[i]));
				}
			}
		result = strcat(result, ":didn't vote:", ftos(didntvote));

		GameLogEcho(result);
		if(mapvote_maps_suggested[mappos])
			GameLogEcho(strcat(":vote:suggestion_accepted:", mapvote_maps[mappos]));
	}

	FOREACH_CLIENT(IS_REAL_CLIENT(it), { FixClientCvars(it); });

	if(gametypevote)
	{
		if ( GameTypeVote_Finished(mappos) )
		{
			gametypevote = false;
			if(autocvar_nextmap != "")
			{
				Map_Goto_SetStr(autocvar_nextmap);
				Map_Goto(0);
				alreadychangedlevel = true;
				return true;
			}
			else
				MapVote_Init();
		}
		return false;
	}

	Map_Goto_SetStr(mapvote_maps[mappos]);
	Map_Goto(0);
	alreadychangedlevel = true;

	return true;
}

void MapVote_CheckRules_1()
{
	for (int i = 0; i < mapvote_count; ++i)
		if (mapvote_maps_flags[i] & GTV_AVAILABLE)
		{
			//dprint("Map ", ftos(i), ": "); dprint(mapvote_maps[i], "\n");
			mapvote_selections[i] = 0;
		}

	mapvote_voters = 0;
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		++mapvote_voters;
		if (it.mapvote)
		{
			int idx = it.mapvote - 1;
			//dprint("Player ", it.netname, " vote = ", ftos(idx), "\n");
			++mapvote_selections[idx];
		}
	});
}

bool MapVote_CheckRules_2()
{
	int i;
	int firstPlace, secondPlace, currentPlace;
	int firstPlaceVotes, secondPlaceVotes, currentVotes;
	int mapvote_voters_real;
	string result;

	if(mapvote_count_real == 1)
		return MapVote_Finished(0);

	mapvote_voters_real = mapvote_voters;
	if(mapvote_abstain)
		mapvote_voters_real -= mapvote_selections[mapvote_count - 1];

	RandomSelection_Init();
	currentPlace = 0;
	currentVotes = -1;
	for(i = 0; i < mapvote_count_real; ++i)
		if ( mapvote_maps_flags[i] & GTV_AVAILABLE )
		{
			RandomSelection_AddFloat(i, 1, mapvote_selections[i]);
			if ( gametypevote &&  mapvote_maps[i] == MapInfo_Type_ToString(MapInfo_CurrentGametype()) )
			{
				currentVotes = mapvote_selections[i];
				currentPlace = i;
			}
		}
	firstPlaceVotes = RandomSelection_best_priority;
	if ( autocvar_sv_vote_gametype_default_current && firstPlaceVotes == 0 )
		firstPlace = currentPlace;
	else
		firstPlace = RandomSelection_chosen_float;

	//dprint("First place: ", ftos(firstPlace), "\n");
	//dprint("First place votes: ", ftos(firstPlaceVotes), "\n");

	RandomSelection_Init();
	for(i = 0; i < mapvote_count_real; ++i)
		if(i != firstPlace)
		if ( mapvote_maps_flags[i] & GTV_AVAILABLE )
			RandomSelection_AddFloat(i, 1, mapvote_selections[i]);
	secondPlace = RandomSelection_chosen_float;
	secondPlaceVotes = RandomSelection_best_priority;
	//dprint("Second place: ", ftos(secondPlace), "\n");
	//dprint("Second place votes: ", ftos(secondPlaceVotes), "\n");

	if(firstPlace == -1)
		error("No first place in map vote... WTF?");

	if(secondPlace == -1 || time > mapvote_timeout || (mapvote_voters_real - firstPlaceVotes) < firstPlaceVotes)
		return MapVote_Finished(firstPlace);

	if(mapvote_keeptwotime)
		if(time > mapvote_keeptwotime || (mapvote_voters_real - firstPlaceVotes - secondPlaceVotes) < secondPlaceVotes)
		{
			MapVote_TouchMask();
			mapvote_keeptwotime = 0;
			result = strcat(":vote:keeptwo:", mapvote_maps[firstPlace]);
			result = strcat(result, ":", ftos(firstPlaceVotes));
			result = strcat(result, ":", mapvote_maps[secondPlace]);
			result = strcat(result, ":", ftos(secondPlaceVotes), "::");
			int didntvote = mapvote_voters;
			for(i = 0; i < mapvote_count; ++i)
			{
				didntvote -= mapvote_selections[i];
				if(i != firstPlace)
					if(i != secondPlace)
					{
						result = strcat(result, ":", mapvote_maps[i]);
						result = strcat(result, ":", ftos(mapvote_selections[i]));
						if(i < mapvote_count_real)
						{
							mapvote_maps_flags[i] &= ~GTV_AVAILABLE;
						}
					}
			}
			result = strcat(result, ":didn't vote:", ftos(didntvote));
			if(autocvar_sv_eventlog)
				GameLogEcho(result);
		}

	return false;
}

void MapVote_Tick()
{

	MapVote_CheckRules_1(); // count
	if(MapVote_CheckRules_2()) // decide
		return;

	int totalvotes = 0;
	FOREACH_CLIENT(true, {
		if(!IS_REAL_CLIENT(it))
		{
			// apply the same special health value to bots too for consistency's sake
			if(GetResource(it, RES_HEALTH) != 2342)
				SetResourceExplicit(it, RES_HEALTH, 2342);
			continue;
		}
		// hide scoreboard again
		if(GetResource(it, RES_HEALTH) != 2342)
		{
			SetResourceExplicit(it, RES_HEALTH, 2342); // health in the voting phase
			CS(it).impulse = 0;

			msg_entity = it;
			WriteByte(MSG_ONE, SVC_FINALE);
			WriteString(MSG_ONE, "");
		}

		// clear possibly invalid votes
		if ( !(mapvote_maps_flags[it.mapvote-1] & GTV_AVAILABLE) )
			it.mapvote = 0;
		// use impulses as new vote
		if(CS(it).impulse >= 1 && CS(it).impulse <= mapvote_count)
			if( mapvote_maps_flags[CS(it).impulse - 1] & GTV_AVAILABLE )
			{
				it.mapvote = CS(it).impulse;
				MapVote_TouchVotes(it);
			}
		CS(it).impulse = 0;

		if(it.mapvote)
			++totalvotes;
	});

	MapVote_CheckRules_1(); // just count
}

void MapVote_Start()
{
	// if mapvote is already running, don't do this initialization again
	if(mapvote_run) { return; }

	// don't start mapvote until after playerstats gamereport is sent
	if(PlayerStats_GameReport_DelayMapVote) { return; }

	MapInfo_Enumerate();
	if(MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1))
		mapvote_run = true;
}

void MapVote_Think()
{
	if(!mapvote_run)
		return;

	if(alreadychangedlevel)
		return;

	if(time < mapvote_nextthink)
		return;
	//dprint("tick\n");

	mapvote_nextthink = time + 0.5;

	if(!mapvote_initialized)
	{
		if(autocvar_rescan_pending == 1)
		{
			cvar_set("rescan_pending", "2");
			localcmd("fs_rescan\nrescan_pending 3\n");
			return;
		}
		else if(autocvar_rescan_pending == 2)
		{
			return;
		}
		else if(autocvar_rescan_pending == 3)
		{
			// now build missing mapinfo files
			if(!MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1))
				return;

			// we're done, start the timer
			cvar_set("rescan_pending", "0");
		}

		mapvote_initialized = true;
		if(DoNextMapOverride(0))
			return;
		if(!autocvar_g_maplist_votable || player_count <= 0)
		{
			GotoNextMap(0);
			return;
		}

		if(autocvar_sv_vote_gametype) { GameTypeVote_Start(); }
		else if(autocvar_nextmap == "") { MapVote_Init(); }
	}

	MapVote_Tick();
}

bool GameTypeVote_SetGametype(Gametype type)
{
	if (MapInfo_CurrentGametype() == type)
		return true;

	Gametype tsave = MapInfo_CurrentGametype();

	MapInfo_SwitchGameType(type);

	MapInfo_Enumerate();
	MapInfo_FilterGametype(type, MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	if(MapInfo_count > 0)
	{
		// update lsmaps in case the gametype changed, this way people can easily list maps for it
		if(lsmaps_reply != "") { strunzone(lsmaps_reply); }
		lsmaps_reply = strzone(getlsmaps());
		bprint("Game type successfully switched to ", MapInfo_Type_ToString(type), "\n");
	}
	else
	{
		bprint("Cannot use this game type: no map for it found\n");
		MapInfo_SwitchGameType(tsave);
		MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		return false;
	}

	//localcmd("gametype ", MapInfo_Type_ToString(type), "\n");

	cvar_set("g_maplist", MapInfo_ListAllowedMaps(type, MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags()) );
	if(autocvar_g_maplist_shuffle)
		ShuffleMaplist();

	return true;
}

bool gametypevote_finished;
bool GameTypeVote_Finished(int pos)
{
	if(!gametypevote || gametypevote_finished)
		return false;

	localcmd("sv_vote_gametype_hook_all\n");
	localcmd("sv_vote_gametype_hook_", mapvote_maps[pos], "\n");

	if ( !GameTypeVote_SetGametype(GameTypeVote_Type_FromString(mapvote_maps[pos])) )
	{
		LOG_TRACE("Selected gametype is not supported by any map");
	}

	gametypevote_finished = true;

	return true;
}

bool GameTypeVote_AddVotable(string nextMode)
{
	if ( nextMode == "" || GameTypeVote_Type_FromString(nextMode) == NULL )
		return false;

	for(int j = 0; j < mapvote_count; ++j)
		if(mapvote_maps[j] == nextMode)
			return false;

	mapvote_maps[mapvote_count] = strzone(nextMode);
	mapvote_maps_suggested[mapvote_count] = false;

	mapvote_maps_screenshot_dir[mapvote_count] = 0;
	mapvote_maps_pakfile[mapvote_count] = strzone("");
	mapvote_maps_flags[mapvote_count] = GameTypeVote_AvailabilityStatus(nextMode);

	mapvote_count += 1;

	return true;

}

bool GameTypeVote_Start()
{
	MapVote_ClearAllVotes();
	MapVote_UnzoneStrings();

	mapvote_count = 0;
	mapvote_timeout = time + autocvar_sv_vote_gametype_timeout;
	mapvote_abstain = false;
	mapvote_detail = !autocvar_g_maplist_votable_nodetail;

	int n = tokenizebyseparator(autocvar_sv_vote_gametype_options, " ");
	n = min(MAPVOTE_COUNT, n);

	int really_available, which_available;
	really_available = 0;
	which_available = -1;
	for(int j = 0; j < n; ++j)
	{
		if ( GameTypeVote_AddVotable(argv(j)) )
		if ( mapvote_maps_flags[j] & GTV_AVAILABLE )
		{
			really_available++;
			which_available = j;
		}
	}

	mapvote_count_real = mapvote_count;

	gametypevote = 1;

	if ( really_available == 0 )
	{
		if ( mapvote_count > 0 )
			strunzone(mapvote_maps[0]);
		mapvote_maps[0] = strzone(MapInfo_Type_ToString(MapInfo_CurrentGametype()));
		//GameTypeVote_Finished(0);
		MapVote_Finished(0);
		return false;
	}
	if ( really_available == 1 )
	{
		//GameTypeVote_Finished(which_available);
		MapVote_Finished(which_available);
		return false;
	}

	mapvote_count_real = mapvote_count;

	mapvote_keeptwotime = time + autocvar_sv_vote_gametype_keeptwotime;
	if(mapvote_count_real < 3 || mapvote_keeptwotime <= time)
		mapvote_keeptwotime = 0;

	MapVote_Spawn();

	return true;
}
