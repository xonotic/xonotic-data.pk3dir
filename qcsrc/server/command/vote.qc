#include "vote.qh"

#include <common/command/_mod.qh>
#include <common/constants.qh>
#include <common/gametypes/_mod.qh>
#include <common/items/inventory.qh>
#include <common/mapinfo.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/playerstats.qh>
#include <common/stats.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <server/campaign.qh>
#include <server/client.qh>
#include <server/command/banning.qh>
#include <server/command/common.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/mutators/_mod.qh>
#include <server/race.qh>
#include <server/round_handler.qh>
#include <server/scores.qh>
#include <server/teamplay.qh>
#include <server/weapons/accuracy.qh>
#include <server/weapons/selection.qh>
#include <server/world.qh>

// =============================================
//  Server side voting code, reworked by Samual
//  Last updated: December 27th, 2011
// =============================================

//  Nagger for players to know status of voting
bool Nagger_SendEntity(entity this, entity to, float sendflags)
{
	int nags = 0;
	WriteHeader(MSG_ENTITY, ENT_CLIENT_NAGGER);

	// bits:
	//   1 = ready
	//   2 = player needs to ready up
	//   4 = vote
	//   8 = player needs to vote
	//  16 = warmup
	// sendflags:
	//  64 = vote counts
	// 128 = vote string

	if (warmup_stage)
	{
		if (readycount)
		{
			nags |= BIT(0);
			if (!to.ready) nags |= BIT(1);
		}
		nags |= BIT(4);
	}

	if (vote_called)
	{
		nags |= BIT(2);
		if (to.vote_selection == 0) nags |= BIT(3);
		nags |= sendflags & BIT(6);
		nags |= sendflags & BIT(7);
	}

	WriteByte(MSG_ENTITY, nags);

	if (nags & BIT(6))
	{
		WriteByte(MSG_ENTITY, vote_accept_count);
		WriteByte(MSG_ENTITY, vote_reject_count);
		WriteByte(MSG_ENTITY, vote_needed_overall);
		WriteChar(MSG_ENTITY, to.vote_selection);
	}

	if (nags & BIT(7)) WriteString(MSG_ENTITY, vote_called_display);

	if (nags & BIT(0))
	{
		for (int i = 1; i <= maxclients;)
		{
			int f = 0;
			for (int b = 0; b < 8 && i <= maxclients; ++b, ++i)
				if (edict_num(i).ready)
					f |= BIT(b);
			WriteByte(MSG_ENTITY, f);
		}
	}

	return true;
}

void Nagger_Init()
{
	Net_LinkEntity(nagger = new_pure(nagger), false, 0, Nagger_SendEntity);
}

void Nagger_VoteChanged()
{
	if (nagger) nagger.SendFlags |= BIT(7);
}

void Nagger_VoteCountChanged()
{
	if (nagger) nagger.SendFlags |= BIT(6);
}

void Nagger_ReadyCounted()
{
	if (nagger) nagger.SendFlags |= BIT(0);
}

// If the vote_caller is still here, return their name, otherwise vote_caller_name
string OriginalCallerName()
{
	if (IS_REAL_CLIENT(vote_caller)) return playername(vote_caller.netname, vote_caller.team, false);
	return vote_caller_name;
}

// =======================
//  Game logic for voting
// =======================

void VoteStop(entity stopper, bool show_name);
void VoteReset(bool verbose)
{
	if (verbose && vote_called)
	{
		VoteStop(NULL, true);
		return;
	}

	FOREACH_CLIENT(true, { it.vote_selection = 0; });

	if (vote_called)
	{
		strfree(vote_called_command);
		strfree(vote_called_display);
		strfree(vote_caller_name);
	}

	vote_called = VOTE_NULL;
	vote_caller = NULL;
	vote_endtime = 0;

	vote_parsed_command = string_null;
	vote_parsed_display = string_null;

	Nagger_VoteChanged();
}

void VoteStop(entity stopper, bool canceled)
{
	if (canceled) // Code such as NextLevel() stopped it, not a direct action by a human.
		bprint("\{1}^2* ^3", OriginalCallerName(), "^2's vote was canceled\n");
	else if (stopper == vote_caller)
		bprint("\{1}^2* ^3", OriginalCallerName(), "^2 stopped their vote\n");
	else
		bprint("\{1}^2* ^3", GetCallerName(stopper), "^2 stopped ^3", OriginalCallerName(), "^2's vote\n");

	if (autocvar_sv_eventlog)   GameLogEcho(strcat(":vote:vstop:", ftos(stopper.playerid)));
	// Don't force them to wait for next vote, this way they can e.g. correct their vote.
	if ((vote_caller) && (stopper == vote_caller))   vote_caller.vote_waittime = time + autocvar_sv_vote_stop;
	VoteReset(false);
}

void VoteAccept()
{
	bprint("\{1}^2* ^3", OriginalCallerName(), "^2's vote for ^1", vote_called_display, "^2 was accepted\n");

	if ((vote_called == VOTE_MASTER) && vote_caller) vote_caller.vote_master = true;
	else localcmd(strcat(vote_called_command, "\n"));

	if (vote_caller)   vote_caller.vote_waittime = 0;  // people like your votes, you don't need to wait to vote again

	VoteReset(false);
	Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_VOTE_ACCEPT);
}

void VoteReject()
{
	bprint("\{1}^2* ^3", OriginalCallerName(), "^2's vote for ", vote_called_display, "^2 was rejected\n");
	VoteReset(false);
	Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_VOTE_FAIL);
}

void VoteTimeout()
{
	bprint("\{1}^2* ^3", OriginalCallerName(), "^2's vote for ", vote_called_display, "^2 timed out\n");
	VoteReset(false);
	Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_VOTE_FAIL);
}

void VoteSpam(float notvoters, float mincount, string result)
{
	bprint(strcat(
		strcat("\{1}^2* vote results: ^1", ftos(vote_accept_count)),
		strcat("^2:^1", ftos(vote_reject_count)),
		((mincount >= 0) ? strcat("^2 (^1", ftos(mincount), "^2 needed)") : "^2"),
		strcat(", ^1", ftos(vote_abstain_count), "^2 didn't care"),
		strcat(", ^1", ftos(notvoters), strcat("^2 didn't ", ((mincount >= 0) ? "" : "have to "), "vote\n"))));

	if (autocvar_sv_eventlog)
	{
		GameLogEcho(strcat(
			strcat(":vote:v", result, ":", ftos(vote_accept_count)),
			strcat(":", ftos(vote_reject_count)),
			strcat(":", ftos(vote_abstain_count)),
			strcat(":", ftos(notvoters)),
			strcat(":", ftos(mincount))));
	}
}

#define spectators_allowed (!autocvar_sv_vote_nospectators || (autocvar_sv_vote_nospectators == 1 && (warmup_stage || intermission_running)))

void VoteCount(float first_count)
{
	vote_accept_count = vote_reject_count = vote_abstain_count = 0;

	float vote_player_count = 0, notvoters = 0;
	float vote_real_player_count = 0, vote_real_accept_count = 0;
	float vote_real_reject_count = 0, vote_real_abstain_count = 0;
	float vote_needed_of_voted, final_needed_votes;
	float vote_factor_overall, vote_factor_of_voted;

	Nagger_VoteCountChanged();

	// add up all the votes from each connected client
	FOREACH_CLIENT(IS_REAL_CLIENT(it) || autocvar_sv_vote_debug, {
		++vote_player_count;
		if (IS_PLAYER(it) || INGAME(it)) ++vote_real_player_count;
		switch (it.vote_selection)
		{
			case VOTE_SELECT_REJECT:
				++vote_reject_count;
				if (IS_PLAYER(it) || INGAME(it)) ++vote_real_reject_count;
				break;
			case VOTE_SELECT_ACCEPT:
				++vote_accept_count;
				if (IS_PLAYER(it) || INGAME(it)) ++vote_real_accept_count;
				break;
			case VOTE_SELECT_ABSTAIN:
				++vote_abstain_count;
				if (IS_PLAYER(it) || INGAME(it)) ++vote_real_abstain_count;
				break;
			default: break;
		}
	});

	// Check to see if there are enough players on the server to allow master voting... otherwise, vote master could be used for evil.
	if ((vote_called == VOTE_MASTER) && autocvar_sv_vote_master_playerlimit > vote_player_count)
	{
		if (vote_caller)   vote_caller.vote_waittime = 0;
		print_to(vote_caller, "^1There are not enough players on this server to allow you to become vote master.");
		VoteReset(false);
		return;
	}

	// if spectators aren't allowed to vote and there are players in a match, then only count the players in the vote and ignore spectators.
	if (!spectators_allowed && (vote_real_player_count > 0))
	{
		vote_accept_count = vote_real_accept_count;
		vote_reject_count = vote_real_reject_count;
		vote_abstain_count = vote_real_abstain_count;
		vote_player_count = vote_real_player_count;
	}

	// people who have no opinion in any way :D
	notvoters = (vote_player_count - vote_accept_count - vote_reject_count - vote_abstain_count);

	// determine the goal for the vote to be passed or rejected normally
	vote_factor_overall = bound(0.5, autocvar_sv_vote_majority_factor, 0.999);
	vote_needed_overall = floor((vote_player_count - vote_abstain_count) * vote_factor_overall) + 1;

	// if the vote times out, determine the amount of votes needed of the people who actually already voted
	vote_factor_of_voted = bound(0.5, autocvar_sv_vote_majority_factor_of_voted, 0.999);
	vote_needed_of_voted = floor((vote_accept_count + vote_reject_count) * vote_factor_of_voted) + 1;

	// are there any players at all on the server? it could be an admin vote
	if (vote_player_count == 0 && first_count)
	{
		VoteSpam(0, -1, "yes");  // no players at all, just accept it
		VoteAccept();
		return;
	}

	// since there ARE players, finally calculate the result of the vote
	if (vote_accept_count >= vote_needed_overall)
	{
		VoteSpam(notvoters, -1, "yes");  // there is enough acceptions to pass the vote
		VoteAccept();
		return;
	}

	if (vote_reject_count > vote_player_count - vote_abstain_count - vote_needed_overall)
	{
		VoteSpam(notvoters, -1, "no");  // there is enough rejections to deny the vote
		VoteReject();
		return;
	}

	// there is not enough votes in either direction, now lets just calculate what the voters have said
	if (time > vote_endtime)
	{
		final_needed_votes = vote_needed_overall;

		if (autocvar_sv_vote_majority_factor_of_voted)
		{
			if (vote_accept_count >= vote_needed_of_voted)
			{
				VoteSpam(notvoters, min(vote_needed_overall, vote_needed_of_voted), "yes");
				VoteAccept();
				return;
			}

			if (vote_accept_count + vote_reject_count > 0)
			{
				VoteSpam(notvoters, min(vote_needed_overall, vote_needed_of_voted), "no");
				VoteReject();
				return;
			}

			final_needed_votes = min(vote_needed_overall, vote_needed_of_voted);
		}

		// it didn't pass or fail, so not enough votes to even make a decision.
		VoteSpam(notvoters, final_needed_votes, "timeout");
		VoteTimeout();
	}
}

void VoteThink()
{
	if (vote_endtime > 0)        // a vote was called
	{
		if (time > vote_endtime) // time is up
			VoteCount(false);
	}
}


// =======================
//  Game logic for warmup
// =======================

// Resets the state of all clients, items, weapons, waypoints, ... of the map.
void reset_map(bool is_fake_round_start)
{
	if (time <= game_starttime)
	{
		if (game_stopped)
			return;

		if (!is_fake_round_start)
		{
			Score_ClearAll();
			PlayerStats_GameReport_Reset_All();
		}

		if (round_handler_IsActive())
			round_handler_Reset(game_starttime);
	}

	if (shuffleteams_on_reset_map)
	{
		shuffleteams();
		shuffleteams_on_reset_map = false;
	}

	FOREACH_CLIENT(true, {
		if (time <= game_starttime)
			accuracy_reset(it); // for spectators too because weapon accuracy is persistent
		if (!IS_PLAYER(it))
			continue;
		player_powerups_remove_all(it, true);
		entity store = PS(it);
		if (store)
		{
			Inventory_clear(store.inventory);
			Inventory_update(store);
		}
	});

	MUTATOR_CALLHOOK(reset_map_global);

	FOREACH_ENTITY_FLOAT_ORDERED(pure_data, false,
	{
		if(IS_CLIENT(it))
			continue;
		if (it.reset)
		{
			it.reset(it);
			continue;
		}
		if (it.team_saved) it.team = it.team_saved;
		if (it.flags & FL_PROJECTILE) delete(it);  // remove any projectiles left
	});

	// Waypoints and assault start come LAST
	FOREACH_ENTITY_ORDERED(IS_NOT_A_CLIENT(it), {
		if (it.reset2) it.reset2(it);
	});

	// Moving the player reset code here since the player-reset depends
	// on spawnpoint entities which have to be reset first --blub
	if (!MUTATOR_CALLHOOK(reset_map_players))
	{
		FOREACH_CLIENT(IS_PLAYER(it),
		{
			// PlayerScore_Clear(it);
			CS(it).killcount = 0;
			// stop the player from moving so that they stand still once they get respawned
			it.velocity = '0 0 0';
			it.avelocity = '0 0 0';
			CS(it).movement = '0 0 0';
			PutClientInServer(it);

			if(IS_BOT_CLIENT(it))
			{
				.entity weaponentity = weaponentities[0];
				if(it.(weaponentity).m_weapon == WEP_Null)
					W_NextWeapon(it, 0, weaponentity);
			}
		});
	}
}

// Restarts the map after the countdown is over (and cvar sv_ready_restart_after_countdown is set)
void ReadyRestart_think(entity this)
{
	if (!warmup_stage) // if the countdown was not aborted
		reset_map(false);
	delete(this);
}

// Forces a restart of the game without actually reloading the map // this is a mess...
void ReadyRestart_force(bool is_fake_round_start)
{
	if (time <= game_starttime && game_stopped)
		return;
	if (!is_fake_round_start && !autocvar_g_campaign)
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_COUNTDOWN_RESTART);

	VoteReset(true);

	// clear overtime, we have to decrease timelimit to its original value again.
	if (checkrules_overtimesadded > 0 && g_race_qualifying != 2)
		cvar_set("timelimit", ftos(autocvar_timelimit - (checkrules_overtimesadded * autocvar_timelimit_overtime)));
	checkrules_suddendeathend = checkrules_overtimesadded = checkrules_suddendeathwarning = overtimes = 0;

	if(warmup_stage)
		game_starttime = time; // Warmup: No countdown in warmup
	else if (autocvar_g_campaign)
		game_starttime = time + 3;
	else
		game_starttime = time + RESTART_COUNTDOWN; // Go into match mode

	// clear player attributes
	FOREACH_CLIENT(IS_PLAYER(it), {
		it.alivetime_start = 0;
		CS(it).killcount = 0;
	});

	// if we're ending the warmup stage call the corresponding hook
	if(!is_fake_round_start && !warmup_stage)
		localcmd("\nsv_hook_warmupend\n");

	// reset the .ready status of all clients (including spectators and bots)
	FOREACH_CLIENT(true, { it.ready = false; });
	readycount = 0;
	Nagger_ReadyCounted();  // NOTE: this causes a resend of that entity, and will also turn off warmup state on the client

	// lock teams with lockonrestart
	if (autocvar_teamplay_lockonrestart && teamplay)
		lockteams = !warmup_stage;

	// initiate the restart-countdown-announcer entity
	if (!is_fake_round_start && sv_ready_restart_after_countdown && !warmup_stage)
	{
		entity restart_timer = new_pure(restart_timer);
		setthink(restart_timer, ReadyRestart_think);
		restart_timer.nextthink = game_starttime;
	}

	// If we're returning to warmup join/switch all queued players for consistency:
	// there's no queueing in warmup and imbalances are handled by sv_teamnagger blocking end of warmup.
	if (warmup_stage)
	{
		// First pass: join player(s) queued for specific team(s)
		FOREACH_CLIENT(it.wants_join > 0, Join(it, false));
		// Second pass: join player(s) queued for team autoselection
		FOREACH_CLIENT(it.wants_join < 0, Join(it, false));
	}

	// after a restart every players number of allowed timeouts gets reset, too
	if (autocvar_sv_timeout)
	{
		FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), { CS(it).allowed_timeouts = autocvar_sv_timeout_number; });
	}

	if (autocvar_sv_spectate == 2 && !warmup_stage)
	{
		FOREACH_CLIENT(IS_SPEC(it),
		{
			if (it.vote_master)
				ClientData_Touch(it.enemy);
			else
			{
				Send_Notification(NOTIF_ONE_ONLY, it, MSG_MULTI, SPECTATE_SPEC_NOTALLOWED);
				TRANSMUTE(Observer, it);
				PutClientInServer(it);
			}
		});
	}

	if (!sv_ready_restart_after_countdown || warmup_stage)
		reset_map(is_fake_round_start);

	if (autocvar_sv_eventlog) GameLogEcho(":restart");
}

void ReadyRestart(bool forceWarmupEnd)
{
	if (MUTATOR_CALLHOOK(ReadyRestart_Deny))
	{
		// NOTE: ReadyRestart support is mandatory in campaign
		if (autocvar_g_campaign)
			error("ReadyRestart must be supported in campaign mode!");
		localcmd("restart\n"); // if ReadyRestart is denied, restart the server
	}
	else if (intermission_running || race_completing) // game is over, ReadyRestart no longer available
		localcmd("restart\n");
	else
		localcmd("\nsv_hook_readyrestart\n");

	if(forceWarmupEnd || autocvar_g_campaign)
		warmup_stage = 0; // forcefully end warmup and go to match stage
	else
		warmup_stage = autocvar_g_warmup; // go into warmup if it's enabled, otherwise restart into match stage

	ReadyRestart_force(false);
}

/* Count the players who are ready and determine whether or not to restart the match when:
 * a player presses F4                      server/command/cmd.qc  ClientCommand_ready()
 * a player switches from players to specs  server/client.qc       PutObserverInServer()
 * a player joins (from specs or directly)  server/client.qc       PutPlayerInServer()
 * a player disconnects                     server/client.qc       ClientDisconnect()	*/
void ReadyCount()
{
	// cannot reset the game while a timeout is active or pending
	if (timeout_status) return;

	int total_players = 0, human_players = 0, humans_ready = 0;
	readycount = 0;

	FOREACH_CLIENT(IS_PLAYER(it) || INGAME_JOINED(it), {
		++total_players;
		if (it.ready) ++readycount;
		if (IS_REAL_CLIENT(it))
		{
			++human_players;
			if (it.ready) ++humans_ready;
		}
	});

	Nagger_ReadyCounted();

	// can't read warmup_stage here as it could have been set to 0 by ReadyRestart()
	// and we need to use this when checking if we should abort the countdown
	// map_minplayers can only be > 0 if g_warmup was -1 at worldspawn
	int minplayers = autocvar_g_warmup > 1 ? autocvar_g_warmup : map_minplayers;

	// This allows warmup to end with zero players to prevent complaints
	// of server never changing map with legacy config (sv_autopause 0).
	bool badteams = (teamplay && total_players && autocvar_sv_teamnagger)
		? TeamBalance_SizeDifference(NULL) >= autocvar_sv_teamnagger
		: false;

	if (total_players < minplayers || badteams)
	{
		if (game_starttime > time) // someone bailed during countdown, back to warmup
		{
			warmup_stage = autocvar_g_warmup; // CAN change it AFTER calling Nagger_ReadyCounted() this frame
			game_starttime = time;
			if (total_players < minplayers)
				Send_Notification(NOTIF_ALL, NULL, MSG_MULTI, COUNTDOWN_STOP_MINPLAYERS, minplayers);
			else
				Send_Notification(NOTIF_ALL, NULL, MSG_MULTI, COUNTDOWN_STOP_BADTEAMS);
			if (!sv_ready_restart_after_countdown) // if we ran reset_map() at start of countdown
				FOREACH_CLIENT(IS_PLAYER(it), { GiveWarmupResources(it); });
		}
		warmup_limit = -1;
		return; // don't ReadyRestart if players are ready but too few or teams are bad
	}
	else if (warmup_limit <= 0
	&& game_starttime <= time) // No countdown in progress, check prevents early countdown end if only player leaves
	{
		// there's enough players now and teams are ok
		// but we're still in infinite warmup and may need to switch to timed warmup
		warmup_limit = cvar("g_warmup_limit");
		if (warmup_limit == 0)
			warmup_limit = autocvar_timelimit * 60;
		if (warmup_limit > 0)
			game_starttime = time;
		// implicit else: g_warmup -1 && g_warmup_limit -1 means
		// warmup continues until enough players AND enough RUPs (no time limit)
	}

	if (humans_ready && humans_ready >= rint(human_players * bound(0.5, cvar("g_warmup_majority_factor"), 1)))
		ReadyRestart(true);
}


// ======================================
//  Supporting functions for VoteCommand
// ======================================

bool Votecommand_check_assignment(entity caller, float assignment)
{
	bool from_server = (!caller);

	if ((assignment == VC_ASGNMNT_BOTH)
	    || ((!from_server && assignment == VC_ASGNMNT_CLIENTONLY)
	    || (from_server && assignment == VC_ASGNMNT_SERVERONLY))) return true;

	return false;
}

string VoteCommand_extractcommand(string input, float startpos, int argc)
{
	string output;

	if ((argc - 1) < startpos) output = "";
	else output = substring(input, argv_start_index(startpos), argv_end_index(-1) - argv_start_index(startpos));

	return output;
}

bool VoteCommand_checknasty(string vote_command)
{
	return !((strstrofs(vote_command, ";", 0) >= 0)
	    || (strstrofs(vote_command, "\n", 0) >= 0)
	    || (strstrofs(vote_command, "\r", 0) >= 0)
	    || (strstrofs(vote_command, "$", 0) >= 0));
}

// NOTE: requires input to be surrounded by spaces
string VoteCommand_checkreplacements(string input)
{
	// add a space around the input so the start and end of the list is captured
	string output = strcat(" ", input, " ");
	// allow gotomap replacements
	output = strreplace(" map ", " gotomap ", output);
	output = strreplace(" chmap ", " gotomap ", output);
	return output;
}

bool VoteCommand_checkinlist(string vote_command, string list)
{
	if (vote_command == "" || list == "")
		return false;

	string l = VoteCommand_checkreplacements(list);
	return (strstrofs(l, VoteCommand_checkreplacements(vote_command), 0) >= 0);
}

string ValidateMap(string validated_map, entity caller)
{
	validated_map = MapInfo_FixName(validated_map);

	if (!validated_map)
	{
		print_to(caller, "This map is not available on this server.");
		return string_null;
	}

	if (!autocvar_sv_vote_override_mostrecent && caller)
	{
		if (Map_IsRecent(validated_map))
		{
			print_to(caller, "This server does not allow for recent maps to be played again. Please be patient for some rounds.");
			return string_null;
		}
	}

	if (!MapInfo_CheckMap(validated_map))
	{
		print_to(caller, strcat("^1Invalid mapname, \"^3", validated_map, "^1\" does not support the current gametype."));
		return string_null;
	}

	return validated_map;
}

float VoteCommand_checkargs(float startpos, int argc)
{
	float p, q, check, minargs;
	string cvarname = strcat("sv_vote_command_restriction_", argv(startpos));
	string cmdrestriction = "";  // No we don't.
	string charlist, arg;
	float checkmate;

	if(cvar_type(cvarname) & CVAR_TYPEFLAG_EXISTS)
		cmdrestriction = cvar_string(cvarname);
	else
		LOG_INFO("NOTE: ", cvarname, " does not exist, no restrictions will be applied.");

	if (cmdrestriction == "") return true;

	++startpos;  // skip command name

	// check minimum arg count

	// 0 args: argc == startpos
	// 1 args: argc == startpos + 1
	// ...

	minargs = stof(cmdrestriction);
	if (argc - startpos < minargs) return false;

	p = strstrofs(cmdrestriction, ";", 0);  // find first semicolon

	for ( ; ; )
	{
		// we know that at any time, startpos <= argc - minargs
		// so this means: argc-minargs >= startpos >= argc, thus
		// argc-minargs >= argc, thus minargs <= 0, thus all minargs
		// have been seen already

		if (startpos >= argc) // all args checked? GOOD
			break;

		if (p < 0)            // no more args? FAIL
		{
			// exception: exactly minargs left, this one included
			if (argc - startpos == minargs) break;

			// otherwise fail
			return false;
		}

		// cut to next semicolon
		q = strstrofs(cmdrestriction, ";", p + 1);  // find next semicolon
		if (q < 0) charlist = substring(cmdrestriction, p + 1, -1);
		else charlist = substring(cmdrestriction, p + 1, q - (p + 1));

		// in case we ever want to allow semicolons in VoteCommand_checknasty
		// charlist = strreplace("^^", ";", charlist);

		if (charlist != "")
		{
			// verify the arg only contains allowed chars
			arg = argv(startpos);
			checkmate = strlen(arg);
			for (check = 0; check < checkmate; ++check)
				if (strstrofs(charlist, substring(arg, check, 1), 0) < 0) return false;
			// not allowed character
			// all characters are allowed. FINE.
		}

		++startpos;
		--minargs;
		p = q;
	}

	return true;
}

int VoteCommand_parse(entity caller, string vote_command, string vote_list, float startpos, int argc)
{
	string first_command = argv(startpos);
	int missing_chars = argv_start_index(startpos);

	if (autocvar_sv_vote_limit > 0 && strlen(vote_command) > autocvar_sv_vote_limit)
		return 0;

	if (caller && !VoteCommand_checkinlist(first_command, vote_list)) return 0;

	if (!VoteCommand_checkargs(startpos, argc)) return 0;

	switch (MUTATOR_CALLHOOK(VoteCommand_Parse, caller, first_command, vote_command, startpos, argc))
	{
		case MUT_VOTEPARSE_CONTINUE: { break; }
		case MUT_VOTEPARSE_SUCCESS: { return 1; }
		case MUT_VOTEPARSE_INVALID: { return -1; }
		case MUT_VOTEPARSE_UNACCEPTABLE: { return 0; }
	}

	switch (first_command) // now go through and parse the proper commands to adjust as needed.
	{
		case "movetoauto":
		case "movetored":
		case "movetoblue":
		case "movetoyellow":
		case "movetopink":
		case "movetospec":
		{
			entity victim = GetIndexedEntity(argc, (startpos + 1));
			float accepted = VerifyClientEntity(victim, true, false);
			if (accepted > 0)
			{
				vote_parsed_command = vote_command;
				vote_parsed_display = sprintf("^1%s #%d ^7%s", first_command, etof(victim), victim.netname);
			}
			else
			{
				print_to(caller, strcat("vcall: ", GetClientErrorString(accepted, argv(startpos + 1)), ".\n"));
				return 0;
			}

			break;
		}

		case "kick":
		case "kickban":    // catch all kick/kickban commands
		{
			entity victim = GetIndexedEntity(argc, (startpos + 1));
			float accepted = VerifyClientEntity(victim, true, false);

			if (accepted > 0)
			{
				string reason = "No reason provided";
				if(argc > next_token)
					reason = substring(vote_command, argv_start_index(next_token) - missing_chars, -1);

				string command_arguments = reason;
				if (first_command == "kickban")
					command_arguments = strcat(ftos(autocvar_g_ban_default_bantime), " ", ftos(autocvar_g_ban_default_masksize), " ~");

				vote_parsed_command = strcat(first_command, " # ", ftos(etof(victim)), " ", command_arguments);
				vote_parsed_display = sprintf("^1%s #%d ^7%s^1 %s", first_command, etof(victim), victim.netname, reason);
			}
			else
			{
				print_to(caller, strcat("vcall: ", GetClientErrorString(accepted, argv(startpos + 1)), ".\n"));
				return 0;
			}

			break;
		}

		case "map":
		case "chmap":
		case "gotomap":  // re-direct all map selection commands to gotomap
		{
			vote_command = ValidateMap(argv(startpos + 1), caller);
			if (!vote_command)  return -1;
			vote_parsed_command = strcat("gotomap ", vote_command);
			vote_parsed_display = strzone(strcat("^1", vote_parsed_command));

			break;
		}

		// TODO: replicate the old behaviour of being able to vote for maps from different modes on multimode servers (possibly support it in gotomap too)
		// maybe fallback instead of aborting if map name is invalid?
		case "nextmap":
		{
			vote_command = ValidateMap(argv(startpos + 1), caller);
			if (!vote_command)  return -1;
			vote_parsed_command = strcat("nextmap ", vote_command);
			vote_parsed_display = strzone(strcat("^1", vote_parsed_command));

			break;
		}

		case "fraglimit": // include restrictions on the maximum votable frag limit
		{
			float fraglimit_vote = stof(argv(startpos + 1));
			float fraglimit_min = 0;
			float fraglimit_max = 999999;
			if(fraglimit_vote > fraglimit_max || fraglimit_vote < fraglimit_min)
			{
				print_to(caller, strcat("Invalid fraglimit vote, accepted values are between ", ftos(fraglimit_min), " and ", ftos(fraglimit_max), "."));
				return -1;
			}
			vote_parsed_command = strcat("fraglimit ", ftos(fraglimit_vote));
			vote_parsed_display = strzone(strcat("^1", vote_parsed_command));

			break;
		}

		case "timelimit": // include restrictions on the maximum votable time limit
		{
			float timelimit_vote = stof(argv(startpos + 1));
			if(timelimit_vote > autocvar_timelimit_max || timelimit_vote < autocvar_timelimit_min)
			{
				print_to(caller, strcat("Invalid timelimit vote, accepted values are between ", ftos(autocvar_timelimit_min), " and ", ftos(autocvar_timelimit_max), "."));
				return -1;
			}
			vote_parsed_command = strcat("timelimit ", ftos(timelimit_vote));
			vote_parsed_display = strzone(strcat("^1", vote_parsed_command));

			break;
		}

		case "restart":
		{
			// add a delay so that vote result can be seen and announcer can be heard
			// if the vote is accepted
			vote_parsed_command = strcat("defer 1 ", vote_command);
			vote_parsed_display = strzone(strcat("^1", vote_command));

			break;
		}

		case "allready":
		{
			if(!warmup_stage) {
				print_to(caller, "Game already started. Use the resetmatch command to restart the match.");
				return -1;
			}

			vote_parsed_command = vote_command;
			vote_parsed_display = strzone(strcat("^1", vote_command));
			break;
		}

		default:
		{
			vote_parsed_command = vote_command;
			vote_parsed_display = strzone(strcat("^1", vote_command));

			break;
		}
	}

	return 1;
}


// =======================
//  Command Sub-Functions
// =======================

void VoteCommand_abstain(int request, entity caller)  // CLIENT ONLY
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (PlayerInList(caller, autocvar_g_voteban_list)) // voteban
			{
				print_to(caller, "^1You are banned from voting.");
				Send_Notification(NOTIF_ONE, caller, MSG_CENTER, CENTER_VOTEBANYN);
				return;
			}

			if (!vote_called) { print_to(caller, "^1No vote called."); }
			else if (caller.vote_selection != VOTE_SELECT_NULL && !autocvar_sv_vote_change)
			{
				print_to(caller, "^1You have already voted.");
			}

			else  // everything went okay, continue changing vote
			{
				print_to(caller, "^1You abstained from your vote.");
				caller.vote_selection = VOTE_SELECT_ABSTAIN;
				msg_entity = caller;
				if (!autocvar_sv_vote_singlecount)
					VoteCount(false);
			}

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote abstain"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void print_available_commands_to(entity caller)
{
	print_to(caller, strcat("You can call a vote for or execute these commands: ^3", autocvar_sv_vote_commands, "^7 and maybe further ^3arguments^7"));
}

void VoteCommand_call(int request, entity caller, int argc, string vote_command)  // BOTH
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float tmp_playercount = 0;
			int parse_error;

			if (PlayerInList(caller, autocvar_g_voteban_list)) // voteban
			{
				print_to(caller, "^1You are banned from calling a vote.");
				Send_Notification(NOTIF_ONE, caller, MSG_CENTER, CENTER_VOTEBAN);
				return;
			}

			vote_command = VoteCommand_extractcommand(vote_command, 2, argc);

			if (!autocvar_sv_vote_call && caller)
			{
				print_to(caller, "^1Vote calling is not allowed.");
			}
			else if (!autocvar_sv_vote_gamestart && time < game_starttime)
			{
				print_to(caller, "^1Vote calling is not allowed before the match has started.");
			}
			else if (vote_called)
			{
				print_to(caller, "^1There is already a vote called.");
			}
			else if (!spectators_allowed && (caller && !IS_PLAYER(caller)))
			{
				print_to(caller, "^1Only players can call a vote.");
			}
			else if (caller && !IS_CLIENT(caller))
			{
				print_to(caller, "^1Only connected clients can vote.");
			}
			else if (timeout_status && vote_command != "timein")
			{
				print_to(caller, "^1You can not call a vote while a timeout is active.");
			}
			else if (caller && (time < caller.vote_waittime))
			{
				print_to(caller, strcat("^1You have to wait ^2", ftos(ceil(caller.vote_waittime - time)), "^1 seconds before you can again call a vote."));
			}
			else if (!VoteCommand_checknasty(vote_command))
			{
				print_to(caller, "^1Syntax error in command.");
			}
			else if ((parse_error = VoteCommand_parse(caller, vote_command, autocvar_sv_vote_commands, 2, argc)) <= 0)
			{
				if(parse_error == 0)
				{
					if (vote_called_command == "")
						VoteCommand_call(CMD_REQUEST_USAGE, caller, argc, vote_command);
					else
						print_to(caller, "^1This command is not acceptable or not available.");
				}
			}
			else  // everything went okay, continue with calling the vote
			{
				vote_caller = caller;  // remember who called the vote
				vote_caller_name = strzone(GetCallerName(vote_caller));
				vote_called = VOTE_NORMAL;
				vote_called_command = strzone(vote_parsed_command);
				vote_called_display = strzone(vote_parsed_display);
				vote_endtime = time + autocvar_sv_vote_timeout;

				if (caller)
				{
					caller.vote_selection = VOTE_SELECT_ACCEPT;
					caller.vote_waittime = time + autocvar_sv_vote_wait;
					msg_entity = caller;
				}

				FOREACH_CLIENT(IS_REAL_CLIENT(it), { ++tmp_playercount; });

				bprint("\{1}^2* ^3", OriginalCallerName(), "^2 calls a vote for ", vote_called_display, "\n");
				if (autocvar_sv_vote_debug)
					bprint("\{1}^2* ^3", "^6DEBUG MODE ACTIVE: bots can vote too\n"); // so servers don't forget it on
				if (autocvar_sv_eventlog)
					GameLogEcho(strcat(":vote:vcall:", ftos(vote_caller.playerid), ":", vote_called_display));
				Nagger_VoteChanged();
				VoteCount(true);  // needed if you are the only one

				if (tmp_playercount > 1 && vote_called != VOTE_NULL)
					Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_VOTE_CALL);
			}

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote call <command>"));
			print_to(caller, "  Where <command> is the command to request a vote upon.");
			print_to(caller, strcat("Examples: ", GetCommandPrefix(caller), " vote call gotomap dance"));
			print_to(caller, strcat("          ", GetCommandPrefix(caller), " vote call endmatch"));
			print_available_commands_to(caller);
			print_to(caller, "Shortcuts: ^2vcall <command>, vend, vmap, vkick, ...");
			return;
		}
	}
}

void VoteCommand_master(int request, entity caller, int argc, string vote_command)  // CLIENT ONLY
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (autocvar_sv_vote_master)
			{
				switch (strtolower(argv(2)))
				{
					case "do":
					{
						int parse_error;
						vote_command = VoteCommand_extractcommand(vote_command, 3, argc);

						if (!caller.vote_master)
							print_to(caller, "^1You do not have vote master privileges.");
						else if (!VoteCommand_checknasty(vote_command))
						{
							print_to(caller, "^1Syntax error in command.");
						}
						else if ((parse_error = VoteCommand_parse(caller, vote_command, strcat(autocvar_sv_vote_commands, " ", autocvar_sv_vote_master_commands), 3, argc)) <= 0)
						{
							if(parse_error == 0)
							{
								if (vote_called_command == "")
									VoteCommand_master(CMD_REQUEST_USAGE, caller, argc, vote_command);
								else
									print_to(caller, "^1This command is not acceptable or not available.");
							}
						}
						else  // everything went okay, proceed with command
						{
							localcmd(strcat(vote_parsed_command, "\n"));
							print_to(caller, strcat("Executing command '", vote_parsed_display, "' on server."));
							bprint("\{1}^2* ^3", GetCallerName(caller), "^2 used their ^3master^2 status to do \"^2", vote_parsed_display, "^2\".\n");
							if (autocvar_sv_eventlog)
								GameLogEcho(strcat(":vote:vdo:", ftos(caller.playerid), ":", vote_parsed_display));
						}

						return;
					}

					case "login":
					{
						if (autocvar_sv_vote_master_password == "") { print_to(caller, "^1Login to vote master is not allowed."); }
						else if (caller.vote_master)
						{
							print_to(caller, "^1You are already logged in as vote master.");
						}
						else if (autocvar_sv_vote_master_password != argv(3))
						{
							print_to(caller, strcat("Rejected vote master login from ", GetCallerName(caller)));
						}
						else  // everything went okay, proceed with giving this player master privilages
						{
							caller.vote_master = true;
							print_to(caller, strcat("Accepted vote master login from ", GetCallerName(caller)));
							bprint("\{1}^2* ^3", GetCallerName(caller), "^2 logged in as ^3master^2\n");
							if (autocvar_sv_eventlog)
								GameLogEcho(strcat(":vote:vlogin:", ftos(caller.playerid)));
						}

						return;
					}

					default:  // calling a vote for master
					{
						if (!autocvar_sv_vote_master_callable) { print_to(caller, "^1Vote to become vote master is not allowed."); }
						else if (vote_called)
						{
							print_to(caller, "^1There is already a vote called.");
						}
						else if (!spectators_allowed && (caller && !IS_PLAYER(caller)))
						{
							print_to(caller, "^1Only players can call a vote.");
						}
						else if (timeout_status)
						{
							print_to(caller, "^1You can not call a vote while a timeout is active.");
						}
						else  // everything went okay, continue with creating vote
						{
							vote_caller = caller;
							vote_caller_name = strzone(GetCallerName(vote_caller));
							vote_called = VOTE_MASTER;
							vote_called_command = strzone("XXX");
							vote_called_display = strzone("^3master");
							vote_endtime = time + autocvar_sv_vote_timeout;

							caller.vote_selection = VOTE_SELECT_ACCEPT;
							caller.vote_waittime = time + autocvar_sv_vote_wait;

							bprint("\{1}^2* ^3", OriginalCallerName(), "^2 calls a vote to become ^3master^2.\n");
							if (autocvar_sv_eventlog)
								GameLogEcho(strcat(":vote:vcall:", ftos(vote_caller.playerid), ":", vote_called_display));
							Nagger_VoteChanged();
							VoteCount(true);  // needed if you are the only one
						}

						return;
					}
				}
			}
			else { print_to(caller, "^1Master control of voting is not allowed."); }

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote master [<action> [<command> | <password>]]"));
			print_to(caller, "  If <action> is left blank, it calls a vote for you to become master.");
			print_to(caller, "  Otherwise it can be either 'do' (to run <command>) or 'login' as master.");
			return;
		}
	}
}

void VoteCommand_no(int request, entity caller)  // CLIENT ONLY
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (PlayerInList(caller, autocvar_g_voteban_list)) // voteban
			{
				print_to(caller, "^1You are banned from voting.");
				Send_Notification(NOTIF_ONE, caller, MSG_CENTER, CENTER_VOTEBANYN);
				return;
			}

			if (!vote_called) { print_to(caller, "^1No vote called."); }
			else if (caller.vote_selection != VOTE_SELECT_NULL && !autocvar_sv_vote_change)
			{
				print_to(caller, "^1You have already voted.");
			}
			else if (caller == vote_caller && autocvar_sv_vote_no_stops_vote)
			{
				VoteStop(caller, false);
			}

			else  // everything went okay, continue changing vote
			{
				print_to(caller, "^1You rejected the vote.");
				caller.vote_selection = VOTE_SELECT_REJECT;
				msg_entity = caller;
				if (!autocvar_sv_vote_singlecount)
					VoteCount(false);
			}

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote no"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void VoteCommand_status(int request, entity caller)  // BOTH
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (vote_called) print_to(caller, strcat("^7Vote for ", vote_called_display, "^7 called by ^7", OriginalCallerName(), "^7."));
			else print_to(caller, "^1No vote called.");

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote status"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void VoteCommand_stop(int request, entity caller)  // BOTH
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!vote_called)   print_to(caller, "^1No vote called.");
			else if ((caller == vote_caller) || !caller || caller.vote_master)   VoteStop(caller, false);
			else   print_to(caller, "^1You are not allowed to stop that vote.");
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote stop"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void VoteCommand_yes(int request, entity caller)  // CLIENT ONLY
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (PlayerInList(caller, autocvar_g_voteban_list)) // voteban
			{
				print_to(caller, "^1You are banned from voting.");
				Send_Notification(NOTIF_ONE, caller, MSG_CENTER, CENTER_VOTEBANYN);
				return;
			}

			if (!vote_called) { print_to(caller, "^1No vote called."); }
			else if (caller.vote_selection != VOTE_SELECT_NULL && !autocvar_sv_vote_change)
			{
				print_to(caller, "^1You have already voted.");
			}
			else  // everything went okay, continue changing vote
			{
				print_to(caller, "^1You accepted the vote.");
				caller.vote_selection = VOTE_SELECT_ACCEPT;
				msg_entity = caller;
				if (!autocvar_sv_vote_singlecount)
					VoteCount(false);
			}

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote yes"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void VoteCommand_(int request)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {

            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " vote ");
            print_to(caller, "  No arguments required.");
            return;
        }
    }
}
*/


// ================================
//  Macro system for vote commands
// ================================

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
#define VOTE_COMMANDS(request, caller, arguments, command) \
	VOTE_COMMAND("abstain", VoteCommand_abstain(request, caller), "Abstain your vote in current vote", VC_ASGNMNT_CLIENTONLY) \
	VOTE_COMMAND("call", VoteCommand_call(request, caller, arguments, command), "Create a new vote for players to decide on", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("help", VoteCommand_macro_help(caller, arguments), "Shows this information", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("master", VoteCommand_master(request, caller, arguments, command), "Full control over all voting and vote commands", VC_ASGNMNT_CLIENTONLY) \
	VOTE_COMMAND("no", VoteCommand_no(request, caller), "Select no in current vote", VC_ASGNMNT_CLIENTONLY) \
	VOTE_COMMAND("status", VoteCommand_status(request, caller), "Prints information about current vote", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("stop", VoteCommand_stop(request, caller), "Immediately end a vote", VC_ASGNMNT_BOTH) \
	VOTE_COMMAND("yes", VoteCommand_yes(request, caller), "Select yes in current vote", VC_ASGNMNT_CLIENTONLY) \
	/* nothing */

void VoteCommand_macro_help(entity caller, int argc)
{
	string command_origin = GetCommandPrefix(caller);

	if (argc == 2 || argv(2) == "help")  // help display listing all commands
	{
		print_to(caller, "\nVoting commands:\n");
		#define VOTE_COMMAND(name, function, description, assignment) \
			{ if (Votecommand_check_assignment(caller, assignment)) { print_to(caller, strcat("  ^2", name, "^7: ", description)); } }

		VOTE_COMMANDS(0, caller, 0, "");
		#undef VOTE_COMMAND

		print_to(caller, strcat("\nUsage:^3 ", command_origin, " vote <command>^7, where possible commands are listed above.\n"));
		print_to(caller, strcat("For help about a specific command, type ", command_origin, " vote help <command>"));
		print_available_commands_to(caller);
	}
	else  // usage for individual command
	{
		#define VOTE_COMMAND(name, function, description, assignment) \
			{ if (Votecommand_check_assignment(caller, assignment)) { if (name == strtolower(argv(2))) { function; return; } } }

		VOTE_COMMANDS(CMD_REQUEST_USAGE, caller, argc, "");
		#undef VOTE_COMMAND

		string cvarname = strcat("sv_vote_command_help_", argv(2));
		if(cvar_type(cvarname) & CVAR_TYPEFLAG_EXISTS)
			wordwrap_sprint(caller, cvar_string(cvarname), 1000);
		else if (argv(2) != "")
			print_to(caller, "No documentation exists for this vote");
	}
}

float VoteCommand_macro_command(entity caller, int argc, string vote_command)
{
	#define VOTE_COMMAND(name, function, description, assignment) \
		{ if (Votecommand_check_assignment(caller, assignment)) { if (name == strtolower(argv(1))) { function; return true; } } }

	VOTE_COMMANDS(CMD_REQUEST_COMMAND, caller, argc, vote_command);
	#undef VOTE_COMMAND

	return false;
}


// ======================================
//  Main function handling vote commands
// ======================================

void VoteCommand(int request, entity caller, int argc, string vote_command)
{
	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3
	// cmd     vote - master - login - password

	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (VoteCommand_macro_command(caller, argc, vote_command)) return;
		}

		default:
			print_to(caller, strcat(((argv(1) != "") ? strcat("Unknown vote command \"", argv(1), "\"") : "No command provided"), ". For a list of supported commands, try ", GetCommandPrefix(caller), " vote help.\n"));
		case CMD_REQUEST_USAGE:
		{
			VoteCommand_macro_help(caller, argc);
			return;
		}
	}
}
