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

// =============
//  score hooks
// =============

//refactor this when setting up score for tagging
MUTATOR_HOOKFUNCTION(mh, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	float frag_mirrordamage = M_ARGV(5, float);

	if (IS_PLAYER(frag_target))
	if (!IS_DEAD(frag_target))
	if (frag_target == frag_attacker || SAME_TEAM(frag_target, frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	frag_mirrordamage = 0;

	M_ARGV(4, float) = frag_damage;
	M_ARGV(5, float) = frag_mirrordamage;
}

//refactor this when setting up score for tagging
MUTATOR_HOOKFUNCTION(mh, PlayerDamage_SplitHealthArmor)
{
	if (time < game_starttime || (round_handler_IsActive() && !round_handler_IsRoundStarted()))
		return;

	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	if(frag_attacker.team == -1 || frag_target.team == -1)return;
	//print("\n", "frag_attacker.team: ", sprintf("%f ", frag_attacker.team), "\n"); //
	//print("\n", "frag_target.team: ", sprintf("%f ", frag_target.team), "\n");     //
	float frag_deathtype = M_ARGV(6, float);
	float frag_damage = M_ARGV(7, float);
	float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
	float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));

	float excess = max(0, frag_damage - damage_take - damage_save);

	//non-friendly fire
	if (frag_target != frag_attacker && IS_PLAYER(frag_attacker) && DIFF_TEAM(frag_target, frag_attacker))
		GameRules_scoring_add_team(frag_attacker, SCORE, (frag_damage - excess) * 1);

	//friendly fire
	if (SAME_TEAM(frag_target, frag_attacker))
		GameRules_scoring_add_team(frag_attacker, SCORE, (-1 * (frag_damage - excess)) * 1);

	//handle (environmental hazard) suiciding, check first if player has a registered attacker who most likely pushed them there to avoid punishing pushed players as pushers are already rewarded
	//deathtypes:
	//kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
	//camp = campcheck, lava = lava, slime = slime
	//team change / rebalance suicides are currently not included
	if (!IS_PLAYER(frag_attacker) && (
		frag_deathtype == DEATH_KILL.m_id ||
		frag_deathtype == DEATH_DROWN.m_id ||
		frag_deathtype == DEATH_HURTTRIGGER.m_id ||
		frag_deathtype == DEATH_CAMP.m_id ||
		frag_deathtype == DEATH_LAVA.m_id ||
		frag_deathtype == DEATH_SLIME.m_id ||
		frag_deathtype == DEATH_SWAMP.m_id))
			GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * 1);
}

MUTATOR_HOOKFUNCTION(mh, GiveFragsForKill, CBC_ORDER_FIRST)
{
	M_ARGV(2, float) = 0; // score will be given to the players differently
	return true;
}

// ============================
//  round-based gameplay hooks
//    including teamchanging
// ============================



// "wtf do these functions do" chart

// all functions:					read and			modified
//                                  understood:			to fit mh:

// mh_LastPlayerForTeam				y					y
// mh_LastPlayerForTeam_Notify		y					y
// PlayerDies						y					
// ClientDisconnect					y					y
// HideTeamNagger					y					y
// PlayerSpawn											
// ForbidSpawn											
// PutClientInServer									
// reset_map_players									
// reset_map_global					y					y until something needs to be added there
// MH_count_alive_players			y					y
// MH_GetWinnerTeam					y					y
// nades_Clear						??					??
// MH_CheckWinner					y					y
// MH_RoundStart					y					y
// MH_CheckTeams					y					y
// mh_isEliminated					y					y

// general order which they are called in:

























// Function: 
// mh_LastPlayerForTeam
// Purpose in CA:
// when there are more than 1 player alive for that team return null meaning there are many players alive for that team
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// Removed check for if player is not dead as players don't "die" die
// Called by:
// mh_LastPlayerForTeam_Notify
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
// PlayerDies
// Purpose in CA:
// handle players dying
// Needed in MH? Purpose?:
// yes, handle players getting tagged
// Needed modifications for MH:
// change respawning
// Called by:
// a player dying
// Calls:
// mh_LastPlayerForTeam_Notify
MUTATOR_HOOKFUNCTION(mh, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	mh_LastPlayerForTeam_Notify(frag_target);
	//if (!allowed_to_spawn_untagged)
	//{
		frag_target.respawn_flags = RESPAWN_SILENT;
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
		frag_target.respawn_time = time;
	//}
	frag_target.respawn_flags |= RESPAWN_FORCE;
	//print("\n", "frag_target.team: ", sprintf("%f ", frag_target.team), "\n");     //5 or 14
	//print("\n", "Team_IndexToTeam(1): ", sprintf("%f ", Team_IndexToTeam(1)), "\n");     //5
	//print("\n", "Team_IndexToTeam(2): ", sprintf("%f ", Team_IndexToTeam(2)), "\n");     //14
	//print("\n", "Team_IndexToTeam(3): ", sprintf("%f ", Team_IndexToTeam(3)), "\n");     //13
	//print("\n", "Team_IndexToTeam(4): ", sprintf("%f ", Team_IndexToTeam(4)), "\n");     //10
	if(frag_target.team == Team_IndexToTeam(2) && !allowed_to_spawn_untagged && (frag_target != mh_LastPlayerForTeam(frag_target)))
		MoveToTeam(frag_target, 1, 6); //index of 1 static is wrong way but it's working somehow with bubblegum and prayers

	//if (!warmup_stage)
	//	eliminatedPlayers.SendFlags |= 1;
	return true;
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
// PlayerSpawn
// Purpose in CA:
// 
// Needed in MH? Purpose?:
// 
// Needed modifications for MH:
// 
// Called by:
// a player spawning
// Calls:
// none
//MUTATOR_HOOKFUNCTION(mh, PlayerSpawn)
//{
//	entity player = M_ARGV(0, entity);

	//if(!allowed_to_spawn_untagged)
	//	MoveToTeam(player, Team_IndexToTeam(2), 6);

	//player.caplayer = 1;
	//if (!warmup_stage)
	//	eliminatedPlayers.SendFlags |= 1;
//}

// Function: 
// ForbidSpawn
// Purpose in CA:
// 
// Needed in MH? Purpose?:
// 
// Needed modifications for MH:
// remove?
// Called by:
// 
// Calls:
// 
//MUTATOR_HOOKFUNCTION(mh, ForbidSpawn)
//{
//	entity player = M_ARGV(0, entity);
//
//	// spectators / observers that weren't playing can join; they are
//	// immediately forced to observe in the PutClientInServer hook
//	// this way they are put in a team and can play in the next round
//	if (!allowed_to_spawn_untagged && player.caplayer)
//		return true;
//	return false;
//}

// Function: 
// PutClientInServer
// Purpose in CA:
// 
// Needed in MH? Purpose?:
// 
// Needed modifications for MH:
// Removed TRANSMUTE(Observer, player);
// Called by:
// 
// Calls:
// 
MUTATOR_HOOKFUNCTION(mh, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if (!allowed_to_spawn_untagged && IS_PLAYER(player)) // this is true even when player is trying to join
	{
		if (CS(player).jointime != time) // not when connecting
		{
			Send_Notification(NOTIF_ONE_ONLY, player, MSG_INFO, INFO_CA_JOIN_LATE);
		}
	}
}

// Function: 
// reset_map_players
// Purpose in CA:
// reset's each player's killstreak
//
// Needed in MH? Purpose?:
// yes, 
// Needed modifications for MH:
// 
// Called by:
// map being reset after round end
// Calls:
// PutClientInServer
MUTATOR_HOOKFUNCTION(mh, reset_map_players)
{
	FOREACH_CLIENT(true, {
		CS(it).killcount = 0;
		if(IS_BOT_CLIENT(it)){
			it.team = -1;
			
		}
		if(1){
			//TRANSMUTE(Player, it);
			PutClientInServer(it);
		}
	});
	
	return true;
}

// Function: 
// reset_map_global
// Purpose in CA:
// allow players to spawn after a new round is started
// Needed in MH? Purpose?:
// yes, same but as untagged
// Needed modifications for MH:
// renamed allowed_to_spawn to allowed_to_spawn_untagged
// Called by:
// map being reset after round end
// Calls:
// none
MUTATOR_HOOKFUNCTION(mh, reset_map_global)
{
	allowed_to_spawn_untagged = true;
	return true;
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
// MH_CheckWinner
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
// cleanup
// Called by:
// MH_CheckWinner
// Calls:
// none
int MH_GetWinnerTeam()
{
	//print("\n", "Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1): ", sprintf("%f ", Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1)), "\n"));     //5
	//print("\n", "Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2): ", sprintf("%f ", Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2)), "\n"));     //14
	//there were runners and hunters alive, runners win
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
// nades_Clear
// Purpose in CA:
// ??? maybe clear nades of the entity given as argument? how?
// Needed in MH? Purpose?:
// if it's needed in CA, yes
// Needed modifications for MH:
// none?
// Called by:
// MH_CheckWinner
// Calls:
// ??? maybe qcsrc/common/mutators/mutator/nades/nades.qc nades_Clear, idfk this magic / bubblegum fix and only given documentation is "// Remove nades that are being thrown"
void nades_Clear(entity player);

// Function: 
// MH_CheckWinner
// Purpose in CA:
// 
// Needed in MH? Purpose?:
// 
// Needed modifications for MH:
// renamed allowed_to_spawn to allowed_to_spawn_untagged
// Called by:
// 
// Calls:
// round_handler_Init , MH_count_alive_players
float MH_CheckWinner(){
	
	int did_the_round_end = 0;
	MH_count_alive_players();
	int winner_team = MH_GetWinnerTeam();
	if(winner_team != 14)print("\n", "winner_team: ", sprintf("%f ", winner_team), "\n");
	if(round_handler_GetEndTime() - time > 0 && winner_team == Team_IndexToTeam(2)){
		did_the_round_end = 0;
	} else if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0 && winner_team == Team_IndexToTeam(2)){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		print("runners \n");
		TeamScore_AddToTeam(winner_team, ST_MH_ROUNDS, +1);
		did_the_round_end = 1;
	} else if(winner_team == Team_IndexToTeam(1)){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		print("hunters \n");
		TeamScore_AddToTeam(winner_team, ST_MH_ROUNDS, +1);
		did_the_round_end = 1;
	} else if(winner_team == -1){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
		did_the_round_end = 1;
	} else {
		print("How did we get here? \n");
	}
	
	if(did_the_round_end == 0)return 0;
	
	allowed_to_spawn_untagged = false;
	game_stopped = true;
	round_handler_Init(5, autocvar_g_mh_warmup, autocvar_g_mh_round_timelimit);
	shuffleteams_on_reset_map = !allowed_to_spawn_untagged;

	FOREACH_CLIENT(IS_PLAYER(it), { nades_Clear(it); });

	return did_the_round_end;
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
	//shuffleteams_on_reset_map = 0;
	allowed_to_spawn_untagged = boolean(warmup_stage);
}

// Function: 
// MH_CheckTeams
// Purpose in CA:
// check that there are no empty teams
// Needed in MH? Purpose?:
// yes, same
// Needed modifications for MH:
// 
// Called by:
// round_handler_Spawn
// Calls:
// MH_count_alive_players , Team_ functions which are imported
bool MH_CheckTeams()
{
	static int prev_missing_teams_mask;
	allowed_to_spawn_untagged = true;
	MH_count_alive_players();
	if (Team_GetNumberOfAliveTeams() == NumTeams(mh_teams))
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return true;
	}
	if(total_players == 0)
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return false;
	}
	int missing_teams_mask = 0;
	for (int i = 1; i <= 2; ++i)
	{
		if ((mh_teams & Team_IndexToBit(i)) &&
			(Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(i)) == 0))
		{
			missing_teams_mask |= Team_IndexToBit(i);
		}
	}
	if(prev_missing_teams_mask != missing_teams_mask)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MISSING_TEAMS, missing_teams_mask);
		prev_missing_teams_mask = missing_teams_mask;
	}
	return false;
}

// Function: 
// mh_isEliminated
// Purpose in CA:
// find if player has been eliminated and is not alive anymore
// Needed in MH? Purpose?:
// no?
// Needed modifications for MH:
// remove?
// Called by:
// EliminatedPlayers_Init
// Calls:
// none
//bool mh_isEliminated(entity e)
//{
//	if(e.caplayer == 1 && (IS_DEAD(e) || e.frags == FRAGS_PLAYER_OUT_OF_GAME))
//		return true;
//	if(e.caplayer == 0.5)
//		return true;
//	return false;
//}