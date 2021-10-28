#include "sv_mh.qh"

MUTATOR_HOOKFUNCTION(mh, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "mh_team";
}

MUTATOR_HOOKFUNCTION(mh, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

// ===================
//  weaponarena hooks
// ===================

MUTATOR_HOOKFUNCTION(mh, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_mh_weaponarena;
}

//ammo is needed if weapons are given with above weaponarena unless players are given infinite ammo
MUTATOR_HOOKFUNCTION(mh, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	start_health       = warmup_start_health       = cvar("g_ca_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_ca_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_ca_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_ca_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_ca_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_ca_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_ca_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_ca_start_ammo_fuel");
}

MUTATOR_HOOKFUNCTION(mh, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(mh, FilterItem)
{
	return true;
}

MUTATOR_HOOKFUNCTION(mh, PlayerRegen)
{
	// no regeneration nor rot
	return true;
}

// =============
//  score hooks
// =============

// MH_CheckWinner gives runners score

MUTATOR_HOOKFUNCTION(mh, GiveFragsForKill, CBC_ORDER_FIRST)
{
	M_ARGV(2, float) = 30; //30 points for every tag a hunter gets, might include runners telefragging a hunter idk lol but they can keep it then
	return true;
}

// ============================
//  round-based gameplay hooks
//    including teamchanging
// ============================



// "wtf do these functions do" chart

// all functions:					refactor			documented:
//                                  finished:			:)

// mh_LastPlayerForTeam				y					y
// mh_LastPlayerForTeam_Notify		y					y
// PlayerDies						add tp				y
// ClientDisconnect					y					y
// HideTeamNagger					y					y
// PlayerSpawn						add tp				y
// PutClientInServer				y					y
// MH_count_alive_players			y					y
// MH_GetWinnerTeam					y					y
// nades_Clear						y					y
// MH_CheckWinner					y					y
// MH_RoundStart					y					y
// MH_CheckTeams					y					y
			


// general order which they are called in / when they are called:
// todo: update after cleanup is finished and when new functions are added

// Start by initiating round_handler, when there is >= 1 player alive on both teams MH_CheckTeams(which is done by calling MH_count_alive_players and 
// it also updates the count for alive players for Team_ functions) let's round handler start a new round

// Between rounds reset_map_ hooks get triggered and on new round start MH_RoundStart is called

// On every tick round handler calls MH_CheckWinner to see if the round should end, if a round should end the game is stopped, 
// nades_Clear is called and MH_CheckWinner calls forward adding score to teams

// When a player dies PlayerDies hook gets triggered and mh_LastPlayerForTeam gets called, it may chain to
// mh_LastPlayerForTeam_Notify if appropriate. These are also called when ClientDisconnect hook gets triggered



// Function: 
// mh_LastPlayerForTeam
// Purpose in CA:
// when there are more than 1 player alive for that team return null meaning there are many players alive for that team
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// Removed check for if player is not dead as players don't "die" die without being instantly respawned
// Called by:
// mh_LastPlayerForTeam_Notify , PlayerDies
// Calls:
// none
entity mh_LastPlayerForTeam(entity this)
{
	entity last_pl = NULL;
	FOREACH_CLIENT(IS_PLAYER(it) && it != this, {
		if (SAME_TEAM(this, it))
		{
			if (!last_pl)
				last_pl = it;
			else
				return NULL;
		}
	});
	return last_pl;
}

// Function: 
// mh_LastPlayerForTeam_Notify
// Purpose in CA:
// is called when a player dies, calls mh_LastPlayerForTeam to see if there are more than 1 players left for that team, if only one is left then send them a notification
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// none I think
// Called by:
// PlayerDies , mh_LastPlayerForTeam_Notify
// Calls:
// mh_LastPlayerForTeam
void mh_LastPlayerForTeam_Notify(entity this)
{
	if (!warmup_stage && round_handler_IsActive() && round_handler_IsRoundStarted())
	{
		entity pl = mh_LastPlayerForTeam(this);
		if (pl)
			Send_Notification(NOTIF_ONE, pl, MSG_CENTER, CENTER_ALONE);
	}
}

// Function: 
// ClientDisconnect
// Purpose in CA:
// if 2nd last player of a team dc's notify the last player that they are the last one
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// none
// Called by:
// a player disconnecting
// Calls:
// mh_LastPlayerForTeam_Notify
MUTATOR_HOOKFUNCTION(mh, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	if (IS_PLAYER(player))
		mh_LastPlayerForTeam_Notify(player);
	return true;
}

// Function: 
// HideTeamNagger
// Purpose:
// hides TeamNagger which nags about players stacking in one team
MUTATOR_HOOKFUNCTION(mh, HideTeamNagger)
{
	return true; // doesn't work well with the whole stack teams until no non-tagged players exist thing
}

// Function: 
// MH_count_alive_players
// Purpose in CA:
// refresh count of how many players are alive in each team to Team_ functions
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// Removed support for 3rd and 4th teams
// Called by:
// MH_CheckWinner , MH_CheckTeams
// Calls:
// multiple Team_ functions which are imported
void MH_count_alive_players()
{
	total_players = 0;
	for (int i = 1; i <= 2; ++i){
		Team_SetNumberOfAlivePlayers(Team_GetTeamFromIndex(i), 0);
	}
	FOREACH_CLIENT(IS_PLAYER(it) && Entity_HasValidTeam(it),{
		++total_players;
		if (IS_DEAD(it)){
			continue;
		}
		entity team_ = Entity_GetTeam(it);
		int num_alive = Team_GetNumberOfAlivePlayers(team_);
		++num_alive;
		Team_SetNumberOfAlivePlayers(team_, num_alive);
	});
	FOREACH_CLIENT(IS_REAL_CLIENT(it),{
		STAT(REDALIVE, it) = Team_GetNumberOfAlivePlayers(
			Team_GetTeamFromIndex(1));
		STAT(BLUEALIVE, it) = Team_GetNumberOfAlivePlayers(
			Team_GetTeamFromIndex(2));
	});
}

// Function: 
// MH_GetWinnerTeam
// Purpose in CA:
// checks the number of players alive on teams and returns a number appropriate to the situation
// team 1 has players alive = return 1
// team 2 has players alive = return 2
// multiple have players alive = return 0
// no one has players alive = return -1
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// changed running out of time being a stalemate into runners winning, removed support for 3rd and 4th teams, refactored
// Called by:
// MH_CheckWinner
// Calls:
// Team_
int MH_GetWinnerTeam()
{
	if ((Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1)) >= 1) && (Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2)) >= 1)){
		return Team_IndexToTeam(2);
	}
	
	//only hunters were alive
	if ((Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1)) >= 1) && (Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2)) == 0)){
		return Team_IndexToTeam(1);
	}
	
	return -1; // no player left
}

// Function: 
// MH_CheckWinner
// Purpose in CA:
// ran on every frame to handle checking if a team has won with CA_GetWinnerTeam and then do the appropriate actions depending on results including starting a new round or continueing current round
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// renamed allowed_to_spawn to allowed_to_spawn_untagged, refactored
// Called by:
// round_handler
// Calls:
// round_handler_Init , MH_count_alive_players , MH_GetWinnerTeam , nades_Clear
float MH_CheckWinner()
{
	int did_the_round_end = 0;
	MH_count_alive_players();
	int winner_team = MH_GetWinnerTeam();
	if(winner_team == 14)
		FOREACH_CLIENT(IS_PLAYER(it) && it.team == 14, 
			{ GameRules_scoring_add_team(it, SCORE, (0.016666667)); }); //add 1 score to each runner's score per second at 60 tickrate
	if(round_handler_GetEndTime() - time > 0 && winner_team == Team_IndexToTeam(2)){
		did_the_round_end = 0;
	} else if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0 && winner_team == Team_IndexToTeam(2)){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN)); //replace with runners win
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));     //replace with runners win
		TeamScore_AddToTeam(winner_team, ST_MH_ROUNDS, +1);
		did_the_round_end = 1;
		FOREACH_CLIENT(IS_PLAYER(it) && it.team == 14,
			{ GameRules_scoring_add_team(it, SCORE, (30)); }); //add 30 score to each runner's score
	} else if(winner_team == Team_IndexToTeam(1)){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN)); //replace with hunters win
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));     //replace with hunters win
		TeamScore_AddToTeam(winner_team, ST_MH_ROUNDS, +1);
		did_the_round_end = 1;
	} else if(winner_team == -1){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
		did_the_round_end = 1;
	} else {
		//print("Error: Ran out of appropriate team win situations\n");
	}
	
	if(did_the_round_end == 0)return 0;
	
	game_stopped = true;
	round_handler_Init(5, autocvar_g_mh_warmup, autocvar_g_mh_round_timelimit);
	if(pymod(round_counter_for_teamchanging, 2))
		shuffleteams_on_reset_map = !allowed_to_spawn_untagged; //only shuffle every other round
	++round_counter_for_teamchanging;
	FOREACH_CLIENT(IS_PLAYER(it), { CS(it).killcount = 0; nades_Clear(it); }); //hopefully "{ CS(it).killcount = 0; nades_Clear(it); }" works and doesn't cut off nades_Clear, untested

	return did_the_round_end;
}

// Function: 
// MH_CheckTeams
// Purpose in CA:
// check that there are no empty teams
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// removed support for 3rd and 4th teams, none more? I skimmed through this without fully diving in and understanding deeply every bit
// Called by:
// round_handler_Spawn
// Calls:
// MH_count_alive_players , Team_ functions which are imported
bool MH_CheckTeams()
{
	static int prev_missing_teams_mask;
	allowed_to_spawn_untagged = true;
	MH_count_alive_players();
	if (Team_GetNumberOfAliveTeams() == NumTeams(mh_teams)){
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return true;
	}
	if(total_players == 0){
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return false;
	}
	int missing_teams_mask = 0;
	for (int i = 1; i <= 2; ++i){
		if ((mh_teams & Team_IndexToBit(i)) &&
			(Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(i)) == 0)){
			missing_teams_mask |= Team_IndexToBit(i);
		}
	}
	if(prev_missing_teams_mask != missing_teams_mask){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MISSING_TEAMS, missing_teams_mask);
		prev_missing_teams_mask = missing_teams_mask;
	}
	return false;
}

// Function: 
// MH_RoundStart
// Purpose in CA:
// if the game is in warmup players can just respawn as players instead of be forced to spectate
// Needed in MH? Purpose?:
// yes, allow players to respawn in runners while in warmup. maybe other stuff which depend on the round starting?
// Needed modifications for MH:
// renamed allowed_to_spawn to allowed_to_spawn_untagged
// Called by:
// round_handler_Spawn
// Calls:
// none
void MH_RoundStart()
{
	allowed_to_spawn_untagged = boolean(warmup_stage);
}

// Function: 
// PutClientInServer
// Purpose in CA:
// place the client in the server with the appropriate flags and as an observer when a spectator joins the game in the middle of the round
// Needed in MH? Purpose?:
// only to send an edited join late message about not being able to join runners?
// Needed modifications for MH:
// Removed TRANSMUTE(Observer, player); , fixed unnecessary printing of the message(fixed by removing call from reset_map_players?) , replaced the message with a new mh one
// Called by:
// a connecting player , reset_map_players
// Calls:
// none
MUTATOR_HOOKFUNCTION(mh, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if (!allowed_to_spawn_untagged && IS_PLAYER(player)){ // this is true even when player is trying to join
		if (CS(player).jointime != time){ // not when connecting
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_MH_JOIN_LATE);
		}
	}
}

// Function: 
// nades_Clear
// Purpose in CA:
// clear nades of the entity given as argument
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// none
// Called by:
// MH_CheckWinner
// Calls:
// qcsrc/common/mutators/mutator/nades/nades.qc nades_Clear
void nades_Clear(entity player);



// ===========
//  to change
// ===========



// Maybe add player teleporting to where they died if they just got tagged?

// Function: 
// PlayerSpawn
// Purpose in CA:
// set flags on the player when they spawn as a player
// Needed in MH? Purpose?:
// yes, don't allow players to join runners mid-round
// Needed modifications for MH:
// 
// Called by:
// a player spawning
// Calls:
// none
MUTATOR_HOOKFUNCTION(mh, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);
	MH_count_alive_players();
	if(player.team == Team_IndexToTeam(2) && !allowed_to_spawn_untagged && Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2)) > 1 && round_handler_IsActive() && round_handler_IsRoundStarted()){
		player.deadflag = 1; // avoid a crash when a spectator joins runners mid-round and gets sent to hunters
		MoveToTeam(player, 1, 6); //index of 1 static is wrong way but it's working somehow with bubblegum and prayers
		player.deadflag = 0; // with bubblegum and prayers, there probably is probably a better check to use here
	}
	//if (!warmup_stage)
	//	eliminatedPlayers.SendFlags |= 1;
}

// Maybe add player teleporting to where they died if they just got tagged?

// Function: 
// PlayerDies
// Purpose in CA:
// handle players dying
// Needed in MH? Purpose?:
// yes, handle players getting tagged
// Needed modifications for MH:
// change respawning
// Called by:
// a player dying/dc'ing
// Calls:
// mh_LastPlayerForTeam_Notify
MUTATOR_HOOKFUNCTION(mh, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	mh_LastPlayerForTeam_Notify(frag_target);
	if (!allowed_to_spawn_untagged)
	{
		frag_target.respawn_flags = RESPAWN_SILENT; //idk what this exactly does yet, below comment was there for respawn time = time + 2 and this line inside the backets
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
	}
	frag_target.respawn_time = time;
	frag_target.respawn_flags |= RESPAWN_FORCE;

	return true;
}
