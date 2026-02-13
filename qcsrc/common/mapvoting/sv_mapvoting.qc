#include "sv_mapvoting.qh"

#include "net.qh"

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
#include <server/world.qh>

// Declarations
float mv_nextthink;
int mv_reduce_count;

/// Returns the gamtype ID from its name, if type_name isn't a real gametype it checks for sv_vote_gametype_(type_name)_type
Gametype GameTypeVote_Type_FromString(string type_name)
{
	Gametype type = MapInfo_Type_FromString(type_name, false, false);
	if (type == NULL)
		type = MapInfo_Type_FromString(cvar_string(
			strcat("sv_vote_gametype_", type_name, "_type")), false, false);
	return type;
}

int GameTypeVote_AvailabilityStatus(string type_name)
{
	int flag = GTV_FORBIDDEN;

	Gametype type = MapInfo_Type_FromString(type_name, false, false);
	if (type == NULL)
	{
		type = MapInfo_Type_FromString(cvar_string(
			strcat("sv_vote_gametype_", type_name, "_type")), false, false);
		flag |= GTV_CUSTOM;
	}
	if (type == NULL)
		return flag;

	if (get_nextmap() != "")
	{
		if (!MapInfo_Get_ByName(get_nextmap(), false, NULL))
			return flag;
		if (!(MapInfo_Map_supportedGametypes & type.gametype_flags))
			return flag;
	}

	return flag | GTV_AVAILABLE;
}

vector GameTypeVote_GetMask()
{
	vector gametype_mask = '0 0 0';
	int n = tokenizebyseparator(autocvar_sv_vote_gametype_options, " ");
	n = min(MAPVOTE_COUNT, n);
	for (int i = 0; i < n; ++i)
		gametype_mask |= GameTypeVote_Type_FromString(argv(i)).gametype_flags;

	if (gametype_mask == '0 0 0')
		gametype_mask = MapInfo_CurrentGametype().gametype_flags;

	return gametype_mask;
}

string GameTypeVote_MapInfo_FixName(string m)
{
	if (autocvar_sv_vote_gametype)
	{
		MapInfo_Enumerate();
		_MapInfo_FilterGametype(GameTypeVote_GetMask(), 0, MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	}
	return MapInfo_FixName(m);
}

void MapVote_ClearAllVotes()
{
	FOREACH_CLIENT(true, it.mapvote = 0);
}

void MapVote_UnzoneStrings()
{
	for (int i = 0; i < mv_count; ++i)
	{
		strfree(mv_entries[i]);
		strfree(mv_pakfile[i]);
		// mv_suggester is set to the netname of the suggester, so can't & doesn't need to be unzoned
	}
}

string MapVote_Suggest(entity this, string m)
{
	if (m == "")
		return "That's not how to use this command.";
	if (!autocvar_g_maplist_votable_suggestions)
		return "Suggestions are not accepted on this server.";
	if (mapvote_initialized && !gametypevote)
		return "Can't suggest, voting is already in progress.";
	m = GameTypeVote_MapInfo_FixName(m);
	if (!m)
		return "The map you suggested is not available on this server.";
	if (!autocvar_g_maplist_votable_suggestions_override_mostrecent && Map_IsRecent(m))
		return "This server does not allow for recent maps to be played again. Please be patient for some rounds.";

	if (!autocvar_sv_vote_gametype && !MapInfo_CheckMap(m))
		return "The map you suggested does not support the current gametype.";
	int i;
	for (i = 0; i < mv_suggestion_ptr; ++i)
		if (mv_suggestions[i] == m)
			return "This map was already suggested.";
	if (mv_suggestion_ptr >= MAPVOTE_COUNT)
		i = floor(random() * mv_suggestion_ptr);
	else
	{
		i = mv_suggestion_ptr;
		++mv_suggestion_ptr;
	}

	if (mv_suggestions[i] != "")
		strunzone(mv_suggestions[i]);
	mv_suggestions[i] = strzone(m);
	mv_suggester[i] = this.netname;

	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":vote:suggested:", m, ":", itos(this.playerid)));
	return strcat("Suggestion of ", m, " accepted.");
}

bool MapVote_AddVotable(int from_i)
{
	string next_map = "";
	if (from_i == -1) // GetNextMap
		next_map = GetNextMap();
	else if (from_i == -2) // abstain
		next_map = "don't care";
	else
		next_map = mv_suggestions[from_i];
	if (next_map == "")
		return false;

	string suggester = (from_i >= 0 ? mv_suggester[from_i] : "");
	int i;
	if (suggester == "")
	{
		for (i = 0; i < mv_count; ++i)
			if (mv_entries[i] == next_map)
				return false;
	}
	else if (!MapInfo_CheckMap(next_map))
		// suggestions might be no longer valid/allowed after gametype switch!
		return false;

	string pakfile = string_null;
	for (i = 0; i < mv_ssdirs_count; ++i)
	{
		string mapfile = strcat(mv_ssdirs[i], "/", next_map);
		pakfile = whichpack(strcat(mapfile, ".tga"));
		if (pakfile == "")
			pakfile = whichpack(strcat(mapfile, ".jpg"));
		if (pakfile == "")
			pakfile = whichpack(strcat(mapfile, ".png"));
		if (pakfile != "")
			break;
	}
	if (i >= mv_ssdirs_count)
		i = 0; // FIXME maybe network this error case, as that means there is no mapshot on th=e server?
	for (int o = strstrofs(pakfile, "/", 0); o >= 0; o = strstrofs(pakfile, "/", 0))
		pakfile = substring(pakfile, o + 1, -1);

	mv_entries[mv_count] = strzone(next_map);
	mv_rng[mv_count] = random();
	mv_ssdir_i[mv_count] = i;
	mv_pakfile[mv_count] = strzone(pakfile);
	mv_flags[mv_count] = GTV_AVAILABLE;
	if (suggester != "" && from_i != mv_count)
	{
		// swap accepted suggestion with wherever it came from
		mv_suggestions[from_i] = mv_suggestions[mv_count];
		mv_suggester[from_i] = mv_suggester[mv_count];
		mv_suggestions[mv_count] = next_map;
		mv_suggester[mv_count] = suggester;
	}

	++mv_count;
	return true;
}

void MapVote_AddVotableMaps(int nmax, int smax)
{
	int available_maps = Maplist_Init();
	int max_attempts = (available_maps < 2)
		? available_maps
		: min(available_maps * 5, 100);

	/**
	 * Before mapvoting begins, players can trigger MapVote_Suggest (suggestmap),
	 * which sets mv_suggestions and mv_suggester from index 0 onwards.
	 * When mapvoting begins, we store the other info (pakfile, flags, ssdir, rng)
	 * with MapVote_AddVotable, for the suggested maps first to filter out the invalid ones,
	 * then run MapVote_AddVotable with GetNextMap to fill in the rest of the maps.
	 */
	if (smax && mv_suggestion_ptr)
	{
		int i, last_i = mv_suggestion_ptr - 1;
		while (mv_count < smax && last_i >= mv_count)
		{
			// mv_suggestion_ptr <= smax, so mv_count + fails < mv_suggestion_ptr
			i = floor(random() * (last_i - mv_count + 1)) + mv_count;
			if (!MapVote_AddVotable(i))
			{
				// replace failed suggestion with the one at the end of the list, and shorten the list
				mv_suggestions[i] = mv_suggestions[last_i];
				mv_suggester[i] = mv_suggester[last_i];
				mv_suggestions[last_i] = "";
				mv_suggester[last_i] = "";
				--last_i;
			}
		}
		for (i = mv_count; i <= last_i; ++i) // may need to clear unused suggestions,
		{                                         // if g_maplist_votable_suggestions < mv_suggestion_ptr
			mv_suggestions[i] = "";
			mv_suggester[i] = "";
		}
	}
	for (int att = 0; att < max_attempts && mv_count < nmax; ++att)
		MapVote_AddVotable(-1); // GetNextMap

	mv_ranked[0] = 0;

	Maplist_Close();
}

int current_gametype_index;
void MapVote_Init()
{
	MapVote_ClearAllVotes();
	MapVote_UnzoneStrings();

	mv_count = 0;
	mv_detail = autocvar_g_maplist_votable_detail;
	mv_abstain = autocvar_g_maplist_votable_abstain;
	mv_show_suggester = autocvar_g_maplist_votable_show_suggester;
	current_gametype_index = -1;

	int nmax = (mv_abstain)
		? min(MAPVOTE_COUNT - 1, autocvar_g_maplist_votable)
		: min(MAPVOTE_COUNT, autocvar_g_maplist_votable);
	int smax = min3(nmax, autocvar_g_maplist_votable_suggestions, mv_suggestion_ptr);

	// we need this for AddVotable, as that cycles through the screenshot dirs
	mv_ssdirs_count = tokenize_console(autocvar_g_maplist_votable_screenshot_dir);
	if (mv_ssdirs_count == 0)
		mv_ssdirs_count = tokenize_console("maps levelshots");
	mv_ssdirs_count = min(mv_ssdirs_count, MAPVOTE_SSDIRS_COUNT);
	for (int i = 0; i < mv_ssdirs_count; ++i)
		mv_ssdirs[i] = strzone(argv(i));

	MapVote_AddVotableMaps(nmax, smax);

	mv_count_real = mv_count;
	if (mv_abstain)
		MapVote_AddVotable(-2); // abstain

	//dprint("mapvote count is ", itos(mv_count), "\n");

	mv_reduce_time = time + autocvar_g_maplist_votable_reduce_time;
	mv_reduce_count = autocvar_g_maplist_votable_reduce_count;
	mv_timeout = time + autocvar_g_maplist_votable_timeout;
	if (mv_count_real < 3 || mv_reduce_time <= time)
		mv_reduce_time = 0;

	MapVote_Spawn();

	/* If match_gametype is set it means voted_gametype has just been applied (on gametype vote end).
	 * In this case apply back match_gametype here so that the "restart" command, if called,
	 * properly restarts the map applying the current gametype.
	 * Applying voted_gametype before map vote start is needed to properly initialize map vote.
	 */
	if (match_gametype)
	{
		string gametype_custom_string = (gametype_custom_enabled)
			? loaded_gametype_custom_string
			: "";
		GameTypeVote_SetGametype(match_gametype, gametype_custom_string, true);
	}
}

bool MapVote_Finished(int mappos)
{
	if (alreadychangedlevel)
		return false;

	if (autocvar_sv_eventlog)
	{
		string result = strcat(":vote:finished:", mv_entries[mappos],
			":", itos(mv_votes[mappos]), "::");
		int didnt_vote = mv_voters;
		for (int i = 0; i < mv_count; ++i)
			if (mv_flags[i] & GTV_AVAILABLE)
			{
				didnt_vote -= mv_votes[i];
				if (i != mappos)
					result = strcat(result, ":", mv_entries[i],
						":", itos(mv_votes[i]));
			}
		result = strcat(result, ":didn't vote:", itos(didnt_vote));

		GameLogEcho(result);
		if (!gametypevote && mv_suggester[mappos] != "")
			GameLogEcho(strcat(":vote:suggestion_accepted:", mv_entries[mappos]));
	}

	FOREACH_CLIENT(IS_REAL_CLIENT(it), FixClientCvars(it));

	if (gametypevote)
	{
		if (GameTypeVote_Finished(mappos))
		{
			gametypevote = false;
			if (get_nextmap() != "")
			{
				Map_Goto_SetStr(get_nextmap());
				Map_Goto(0);
				alreadychangedlevel = true;
				strfree(voted_gametype_string);
				return true;
			}
			else
				MapVote_Init();
		}
		return false;
	}

	mv_winner = mappos;
	mv_winner_time = time;
	mapvote_ent.SendFlags |= SF_MV_WINNER;
	alreadychangedlevel = true;

	return true;
}

void MapVote_ranked_swap(int i, int j, entity pass)
{
	TC(int, i); TC(int, j);
	int tmp = mv_ranked[i];
	mv_ranked[i] = mv_ranked[j];
	mv_ranked[j] = tmp;
}
int MapVote_ranked_cmp(int i, int j, entity pass)
{
	TC(int, i); TC(int, j);
	int ri = mv_ranked[i];
	int rj = mv_ranked[j];
	bool avail_i = (mv_flags[ri] & GTV_AVAILABLE);
	bool avail_j = (mv_flags[rj] & GTV_AVAILABLE);
	if (avail_j && !avail_i) // i isn't votable, just move it to the end
		return 1;
	if (avail_i && !avail_j) // j isn't votable, just move it to the end
		return -1;
	if (!avail_i && !avail_j)
		return 0;

	int votes_i = mv_votes[ri];
	int votes_j = mv_votes[rj];
	if (votes_i <= 0 && rj == current_gametype_index) // j is the current and should be used
		return 1;
	if (votes_j <= 0 && ri == current_gametype_index) // i is the current and should be used
		return -1;
	if (votes_i == votes_j) // randomly choose which goes first
		return (mv_rng[rj] > mv_rng[ri]) ? 1 : -1;
	return votes_j - votes_i; // descending order
}

void MapVote_CheckRules_count()
{
	int idx, i;
	for (i = 0; i < mv_count; ++i) // reset all votes
		if (mv_flags[i] & GTV_AVAILABLE)
		{
			//dprint("Map ", itos(i), ": "); dprint(mv_entries[i], "\n");
			mv_votes[i] = 0;
		}

	mv_voters = 0;
	FOREACH_CLIENT(IS_REAL_CLIENT(it), // add votes
	{
		++mv_voters;
		if (it.mapvote)
		{
			idx = it.mapvote - 1;
			//dprint("Player ", it.netname, " vote = ", itos(idx), "\n");
			++mv_votes[idx];
		}
	});

	for (i = 0; i < mv_count; ++i) // sort by most votes, for any ties choose randomly
		mv_ranked[i] = i; // populate up to mv_count, only bother sorting up to mv_count_real
	heapsort(mv_count_real, MapVote_ranked_swap, MapVote_ranked_cmp, NULL);
}

bool MapVote_CheckRules_decide()
{
	if (mv_count_real == 1)
		return MapVote_Finished(0);

	int mv_voters_real = mv_voters;
	if (mv_abstain)
		mv_voters_real -= mv_votes[mv_count - 1]; // excluding abstainers

	//dprint("1st place index: ", itos(mv_ranked[0]), "\n");
	//dprint("1st place votes: ", itos(mv_votes[mv_ranked[0]]), "\n");
	//dprint("2nd place index: ", itos(mv_ranked[1]), "\n");
	//dprint("2nd place votes: ", itos(mv_votes[mv_ranked[1]]), "\n");

	// these are used to check whether even if everyone else all voted for one map,
	// ... it wouldn't be enough to push it into the top `reduce_count` maps
	// i.e. reducing can start early
	int votes_recent = mv_votes[mv_ranked[0]];
	int votes_running_total = votes_recent;

	if (time > mv_timeout
	|| (mv_voters_real - votes_running_total) < votes_recent
	||  mv_voters_real == 0) // all abstained
		return MapVote_Finished(mv_ranked[0]); // choose best

	// if mv_reduce_count is >= 2, we reduce to the top `reduce_count`, keeping exactly that many
	// if it's < 2, we keep all maps that received at least 1 vote, as long as there's at least 2
	int ri, i;
	bool keep_exactly = (mv_reduce_count >= 2);
#define REDUCE_REMOVE_THIS(idx) (keep_exactly \
	? (idx >= mv_reduce_count) \
	: (mv_votes[mv_ranked[idx]] <= 0))
	for (ri = 1; ri < mv_count; ++ri)
	{
		i = mv_ranked[ri];
		if (REDUCE_REMOVE_THIS(ri))
			break;
		votes_recent = mv_votes[i];
		votes_running_total += votes_recent;
	}

	if (mv_reduce_time)
	if ((time > mv_reduce_time && (keep_exactly || ri >= 2))
	|| (mv_voters_real - votes_running_total) < votes_recent)
	{
		mapvote_ent.SendFlags |= SF_MV_MASK;
		mv_reduce_time = 0;
		string result = ":vote:reduce";
		int didnt_vote = mv_voters;
		bool remove = false;
		for (ri = 0; ri < mv_count; ++ri)
		{
			i = mv_ranked[ri];
			didnt_vote -= mv_votes[i];
			result = strcat(result, ":", mv_entries[i],
				":", itos(mv_votes[i]));
			if (!remove && REDUCE_REMOVE_THIS(ri))
			{
				result = strcat(result, "::"); // separator between maps kept and maps removed
				remove = true;
			}
			if (remove && i < mv_count_real)
				mv_flags[i] &= ~GTV_AVAILABLE; // make it not votable
		}
		result = strcat(result, ":didn't vote:", itos(didnt_vote));
		if (autocvar_sv_eventlog)
			GameLogEcho(result);
	}
#undef REDUCE_REMOVE_THIS

	return false;
}

void MapVote_Tick()
{
	MapVote_CheckRules_count();
	if (MapVote_CheckRules_decide())
		return;

	FOREACH_CLIENT(true,
	{
		if (!IS_REAL_CLIENT(it))
		{
			// apply the same special health value to bots too for consistency's sake
			if (GetResource(it, RES_HEALTH) != 2342)
				SetResourceExplicit(it, RES_HEALTH, 2342);
			continue;
		}
		// hide scoreboard again
		if (GetResource(it, RES_HEALTH) != 2342)
		{
			SetResourceExplicit(it, RES_HEALTH, 2342); // health in the voting phase
			CS(it).impulse = 0;

			msg_entity = it;
			WriteByte(MSG_ONE, SVC_FINALE);
			WriteString(MSG_ONE, "");
		}

		// clear possibly invalid votes
		if (!(mv_flags[it.mapvote - 1] & GTV_AVAILABLE))
			it.mapvote = 0;
		// use impulses as new vote
		if (CS(it).impulse >= 1 && CS(it).impulse <= mv_count
		&& (mv_flags[CS(it).impulse - 1] & GTV_AVAILABLE))
		{
			it.mapvote = CS(it).impulse;
			mapvote_ent.SendFlags |= SF_MV_VOTES;
		}
		CS(it).impulse = 0;
	});

	MapVote_CheckRules_count(); // just count
}

void MapVote_Start()
{
	// if mapvote is already running, don't do this initialization again
	if (mapvote_run)
		return;

	// don't start mapvote until after playerstats gamereport is sent
	if (PlayerStats_GameReport_DelayMapVote)
		return;

	MapInfo_Enumerate();
	if (MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1))
		mapvote_run = true;
}

void MapVote_Think()
{
	if (!mapvote_run)
		return;

	if (mv_winner_time)
	{
		if (time > mv_winner_time + 1)
		{
			if (voted_gametype)
			{
				// clear match_gametype so that GameTypeVote_SetGametype
				// prints the gametype switch message
				match_gametype = NULL;
				GameTypeVote_SetGametype(voted_gametype, voted_gametype_string, true);
			}

			Map_Goto_SetStr(mv_entries[mv_winner]);
			Map_Goto(0);
			strfree(voted_gametype_string);
		}
		return;
	}

	if (alreadychangedlevel)
		return;

	if (time < mv_nextthink)
		return;
	//dprint("tick\n");

	mv_nextthink = time + 0.5;
	if (mv_nextthink > mv_timeout - 0.1) // make sure there's no delay when map vote times out
		mv_nextthink = mv_timeout + 0.001;

	if (!mapvote_initialized)
	{
		if (autocvar_rescan_pending == 1)
		{
			cvar_set("rescan_pending", "2");
			localcmd("\nfs_rescan\nrescan_pending 3\n");
			return;
		}
		else if (autocvar_rescan_pending == 2)
			return;
		else if (autocvar_rescan_pending == 3)
		{
			// now build missing mapinfo files
			if (!MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1))
				return;

			// we're done, start the timer
			cvar_set("rescan_pending", "0");
		}

		mapvote_initialized = true;
		if (DoNextMapOverride(0))
			return;
		if (!autocvar_g_maplist_votable || player_count <= 0)
		{
			GotoNextMap(0);
			return;
		}

		if (autocvar_sv_vote_gametype)
			GameTypeVote_Start();
		else if (get_nextmap() == "")
			MapVote_Init();
	}

	MapVote_Tick();
}

// if gametype_string is "" then gametype_string is inferred from Gametype type
// otherwise gametype_string is the string (short name) of a custom gametype
bool GameTypeVote_SetGametype(Gametype type, string gametype_string, bool call_hooks)
{
	if (gametype_string == "")
		gametype_string = MapInfo_Type_ToString(type);
	if (!call_hooks)
		// custom gametype is disabled because gametype hooks can't be executed
		gametype_custom_enabled = false;
	else
	{
		gametype_custom_enabled = (gametype_string != MapInfo_Type_ToString(type));

		localcmd("\nsv_vote_gametype_hook_all\n");
		localcmd("\nsv_vote_gametype_hook_", gametype_string, "\n");
	}

	if (MapInfo_CurrentGametype() == type)
		return true;

	Gametype tsave = MapInfo_CurrentGametype();

	MapInfo_SwitchGameType(type);

	MapInfo_Enumerate();
	MapInfo_FilterGametype(type, MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	if (MapInfo_count > 0)
	{
		// update lsmaps in case the gametype changed, this way people can easily list maps for it
		if (lsmaps_reply != "")
			strunzone(lsmaps_reply);
		lsmaps_reply = strzone(getlsmaps());

		if (!match_gametype) // don't show this msg if we are temporarily switching gametype
			bprint("Gametype successfully switched to ", MapInfo_Type_ToString(type), "\n");
	}
	else
	{
		bprint("Cannot use this gametype: no map for it found\n");
		MapInfo_SwitchGameType(tsave);
		MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		return false;
	}

	bool do_reset = autocvar_sv_vote_gametype_maplist_reset;
	string gvmaplist = strcat("sv_vote_gametype_", gametype_string, "_maplist");
	if (cvar_type(gvmaplist) & CVAR_TYPEFLAG_EXISTS)
	{
		// force a reset if the provided list is empty
		if (cvar_string(gvmaplist) == "")
			do_reset = true;
		else
			cvar_set("g_maplist", cvar_string(gvmaplist));
	}
	if (do_reset)
		cvar_set("g_maplist", MapInfo_ListAllowedMaps(type, MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags()));

	return true;
}

bool gametypevote_finished;
bool GameTypeVote_Finished(int pos)
{
	if (!gametypevote || gametypevote_finished)
		return false;

	match_gametype = MapInfo_CurrentGametype();
	voted_gametype = GameTypeVote_Type_FromString(mv_entries[pos]);
	strcpy(voted_gametype_string, mv_entries[pos]);

	GameTypeVote_SetGametype(voted_gametype, voted_gametype_string, true);

	// save to a cvar so it can be applied back when gametype is temporary
	// changed on gametype vote end of the next game
	if (mv_flags[pos] & GTV_CUSTOM)
		cvar_set("_sv_vote_gametype_custom", voted_gametype_string);

	gametypevote_finished = true;
	return true;
}

bool GameTypeVote_AddVotable(string nextMode)
{
	if (nextMode == "" || GameTypeVote_Type_FromString(nextMode) == NULL)
		return false;

	for (int i = 0; i < mv_count; ++i)
		if (mv_entries[i] == nextMode)
			return false;

	mv_entries[mv_count] = strzone(nextMode);
	mv_ssdir_i[mv_count] = 0;
	// suggester will be uninitialized, but it's never read until map voting, before which it has been set
	mv_flags[mv_count] = GameTypeVote_AvailabilityStatus(nextMode);

	++mv_count;
	return true;
}

bool GameTypeVote_Start()
{
	MapVote_ClearAllVotes();
	MapVote_UnzoneStrings();

	mv_count = 0;
	mv_timeout = time + autocvar_sv_vote_gametype_timeout;
	mv_abstain = false;
	mv_detail = autocvar_sv_vote_gametype_detail;

	int n = tokenizebyseparator(autocvar_sv_vote_gametype_options, " ");
	n = min(MAPVOTE_COUNT, n);

	int really_available = 0;
	int which_available = -1;
	int i;
	for (i = 0; i < n; ++i)
		if (GameTypeVote_AddVotable(argv(i))
		&& (mv_flags[i] & GTV_AVAILABLE))
		{
			++really_available;
			which_available = i;
		}

	mv_count_real = mv_count;

	gametypevote = true;

	const string current_gametype_string = (gametype_custom_enabled)
		? loaded_gametype_custom_string
		: MapInfo_Type_ToString(MapInfo_CurrentGametype());

	if (really_available == 0)
	{
		if (mv_count > 0)
			strunzone(mv_entries[0]);
		mv_entries[0] = strzone(current_gametype_string);
		current_gametype_index = 0;
		//GameTypeVote_Finished(0);
		MapVote_Finished(current_gametype_index);
		return false;
	}
	if (really_available == 1)
	{
		current_gametype_index = which_available;
		//GameTypeVote_Finished(which_available);
		MapVote_Finished(current_gametype_index);
		return false;
	}
	current_gametype_index = -1;
	if (autocvar_sv_vote_gametype_default_current) // find current gametype index
		for (i = 0; i < mv_count_real; ++i)
			if (mv_entries[i] == current_gametype_string)
			{
				current_gametype_index = i;
				break;
			}

	mv_count_real = mv_count;

	mv_reduce_time = time + autocvar_sv_vote_gametype_reduce_time;
	mv_reduce_count = autocvar_sv_vote_gametype_reduce_count;
	if (mv_count_real < 3 || mv_reduce_time <= time)
		mv_reduce_time = 0;

	MapVote_Spawn();
	return true;
}
