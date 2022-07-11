#include "sv_mh.qh"

.bool tagteleport;
.vector taggedplayerlocation;
.vector taggedplayervelocity;
.vector taggedplayerviewangles;

void MH_FakeTimeLimit(entity e, float t)
{
	if(!IS_REAL_CLIENT(e))
		return;
#if 0
	msg_entity = e;
	WriteByte(MSG_ONE, 3); // svc_updatestat
	WriteByte(MSG_ONE, 236); // STAT_TIMELIMIT
	if(t < 0)
		WriteCoord(MSG_ONE, autocvar_timelimit);
	else
		WriteCoord(MSG_ONE, (t + 1) / 60);
#else
	STAT(MH_ROUNDTIMER, e) = t;
#endif
}

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

//damage dealing for tagging
MUTATOR_HOOKFUNCTION(mh, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(autocvar_g_mh_enable_tagging_on_touch && round_handler_IsRoundStarted() && player.team == Team_IndexToTeam(1) && !game_stopped && !IS_DEAD(player) && IS_PLAYER(player) && !IS_INDEPENDENT_PLAYER(player))
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != player && it.team == Team_IndexToTeam(2), {
			if(!IS_DEAD(it) && !IS_INDEPENDENT_PLAYER(it))
			if(boxesoverlap(player.absmin, player.absmax, it.absmin, it.absmax))
			{
				float health = GetResource(it, RES_HEALTH);
				float armor = GetResource(it, RES_ARMOR);
				float max_dmg;
				if(autocvar_g_balance_armor_blockpercent == 1){
					max_dmg = health + armor; //skip handling (1 - autocvar_g_balance_armor_blockpercent) in case of cvar value of 1 as it leads to divide by 0
				} else {
					max_dmg = health + bound(0, armor, ((health / (1 - autocvar_g_balance_armor_blockpercent))- health)); 
				}
				Damage(it, player, player, max_dmg, DEATH_CAMP.m_id, DMG_NOWEP, player.origin, '0 0 0');
				it.tagteleport = true;
				it.taggedplayerlocation = it.origin;
				it.taggedplayervelocity = it.velocity;
				it.taggedplayerviewangles = it.angles;
			}
		});
	}

	if(player.team == Team_IndexToTeam(1))
		player.mh_status = MH_STATUS_HUNTER;
	else if(player.team == Team_IndexToTeam(2))
		player.mh_status = MH_STATUS_RUNNER;
}

MUTATOR_HOOKFUNCTION(mh, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	vector frag_force = M_ARGV(6, vector);
	
	if(frag_deathtype == DEATH_FALL.m_id){
		M_ARGV(4, float) = 0; //no fall damage or splat damage
		return;
	}
	
	if(frag_deathtype==DEATH_CAMP.m_id || !IS_PLAYER(frag_attacker)) return;

	
	if(IS_PLAYER(frag_target) && !IS_DEAD(frag_target)){ //check that the target is a player and not dead, allows anyone to knock around corpses for funsies

		switch(autocvar_g_mh_weapons_damage)
		{
			// no damage
			default:
			case 0: {
				frag_damage = 0;
				break;
			}
			// only self-damage for runners
			case 1: {
				if(frag_target != frag_attacker)frag_damage = 0;
				break;
			}
			// only damage opposing team
			case 2: {
				if(SAME_TEAM(frag_target, frag_attacker))frag_damage = 0;
				break;
			}
			// only allow hunters to damage runners
			case 3: {
				//print(sprintf("%f", frag_attacker.team));
				//print("\n");
				//print(sprintf("%f", frag_target.team));
				//print("\n");
				if(!((frag_attacker.team==5) && (frag_target.team==14)))frag_damage = 0;
				break;
			}
			// self-damage and opposing team damage
			case 4: {
				if(frag_target != frag_attacker && SAME_TEAM(frag_target, frag_attacker))frag_damage = 0;
				break;
			}
		}
		switch(autocvar_g_mh_weapons_force){
			// no force
			case 0: {
				frag_force = '0 0 0';
				break;
			}
			// only self-force
			default:
			case 1: {
				if(frag_target != frag_attacker)frag_force = '0 0 0';
				break;
			}
			// self-force and opposing team force
			case 2: {
				if(frag_target != frag_attacker && SAME_TEAM(frag_target, frag_attacker))frag_force = '0 0 0';
				break;
			}
		}
	}

	M_ARGV(4, float) = frag_damage;
	M_ARGV(6, vector) = frag_force;
}

MUTATOR_HOOKFUNCTION(mh, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_mh_weaponarena;
}

//ammo is needed if weapons are given with above weaponarena unless players are given infinite ammo
MUTATOR_HOOKFUNCTION(mh, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	if(!cvar("g_use_ammunition") || autocvar_g_mh_limited_ammunition)
		start_items |= IT_UNLIMITED_AMMO;

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

// functions:						refactor			documented:
//                                  finished:			:)

// mh_LastPlayerForTeam				y					y
// mh_LastPlayerForTeam_Notify		y					y
// PlayerDies						y					y
// ClientDisconnect					y					y
// HideTeamNagger					y					y
// PlayerSpawn						y					y
// PutClientInServer				y					y
// MH_count_players					y					y
// MH_GetWinnerTeam					y					y
// nades_Clear						y					y
// MH_CheckWinner					y					y
// MH_RoundStart					y					y
// MH_CheckTeams					y					y



// general order which they are called in / when they are called:
// todo: update after cleanup is finished and when new functions are added

// Start by initiating round_handler, when there is >= 1 player alive on both teams MH_CheckTeams(which is done by calling MH_count_players and 
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

	if (IS_PLAYER(player)){
		mh_LastPlayerForTeam_Notify(player);
		if (player.waypointsprite_attachedforcarrier)
			WaypointSprite_Kill(player.waypointsprite_attachedforcarrier);

	}
	return true;
}

// when players want to spec, clear HUD
MUTATOR_HOOKFUNCTION(mh, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	if (IS_PLAYER(player) && !IS_DEAD(player))
		mh_LastPlayerForTeam_Notify(player);
		
	player.mh_status = 0;
	MH_FakeTimeLimit(player, -1); // restore original timelimit
	return false;  // allow team reset
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
// MH_count_players
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
void MH_count_players()
{
	total_players = 0;
	for (int i = 1; i <= 2; ++i){
		Team_SetNumberOfAlivePlayers(Team_GetTeamFromIndex(i), 0);
		// TOFIX: After merging master, this function has been removed
		//Team_SetNumberOfTotalPlayers(Team_GetTeamFromIndex(i), 0);
	}
	FOREACH_CLIENT(IS_PLAYER(it) && Entity_HasValidTeam(it),{
		entity team_ = Entity_GetTeam(it);
		// TOFIX: After merging master, this function (Team_GetNumberOfTotalPlayers()) has been removed
		//int num_total = Team_GetNumberOfTotalPlayers(team_);
		int num_total = 1;
		++num_total;
		// TOFIX: After merging master, this function has been removed
		//Team_SetNumberOfTotalPlayers(team_, num_total);
		++total_players;
		if (IS_DEAD(it)){
			continue;
		}
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
	//both teams have players
	// TOFIX: After merging master, this function (Team_GetNumberOfTotalPlayers()) has been removed
	//if ((Team_GetNumberOfTotalPlayers(Team_GetTeamFromIndex(1)) >= 1) && 
	if (Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2)) >= 1){
		return Team_IndexToTeam(2);
	}
	
	//only hunters were alive
	// TOFIX: After merging master, this function (Team_GetNumberOfTotalPlayers()) has been removed
	//if ((Team_GetNumberOfTotalPlayers(Team_GetTeamFromIndex(1)) >= 1) && 
	if (Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2)) == 0){
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
// round_handler_Init , MH_count_players , MH_GetWinnerTeam , nades_Clear
float MH_CheckWinner()
{
	int did_the_round_end = 0;
	MH_count_players();
	int winner_team = MH_GetWinnerTeam();
	if(winner_team == 14){
		//(total amount of players divided by total amount of runners) divided by 2[because of initial team split] amount of score per second divided over X ticks per second
		//(2 total players / 1 total runner) / 2 = 1 score per second
		//(9 total players / 3 total runners) / 2 = 1.5 score per second (5v4 in the beginning and only 1 person has been tagged making it 6v3)
		//(10 total players / 1 total runner) / 2 = 5 score per second (5v5 in which only 1 runner is alive, they gain 5 score per second as last alive)
		//(10 total players / 9 total runners) / 2 = 0.55556 score per second(1 hunter and 9 runners, doesn't really award runners for stacking for that team)
		// TOFIX: After merging master, this function (Team_GetNumberOfTotalPlayers()) has been removed
		float survivalscore = (((total_players)/2)/(1/cvar("sys_ticrate")));
		FOREACH_CLIENT(IS_PLAYER(it) && it.team == 14, 
			{ GameRules_scoring_add_team(it, SCORE, (survivalscore)); }); //add 1 score to each runner's score per second at 60 tickrate
	}
	if(round_handler_GetEndTime() - time > 0 && winner_team == Team_IndexToTeam(2)){
		did_the_round_end = 0;
	} else if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0 && winner_team == Team_IndexToTeam(2)){
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN)); //replace with runners win
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));     //replace with runners win
		TeamScore_AddToTeam(winner_team, ST_MH_ROUNDS, +1);
		did_the_round_end = 1;
		FOREACH_CLIENT(IS_PLAYER(it) && it.team == 14,
			{ GameRules_scoring_add_team(it, SCORE, (autocvar_g_mh_round_timelimit)); }); //add score to each runner's score, equal to the round timelimit
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
		print("Error: Ran out of appropriate team win situations\n");
	}
	
	if(did_the_round_end == 0)return 0;
	
	game_stopped = true;
	round_handler_Init(5, autocvar_g_mh_warmup, autocvar_g_mh_round_timelimit);
	if(pymod(round_counter_for_teamchanging, autocvar_g_mh_how_many_rounds_before_shuffle) || autocvar_g_mh_how_many_rounds_before_shuffle == 1)
		shuffleteams_on_reset_map = !allowed_to_spawn_untagged;
	++round_counter_for_teamchanging;
	//FOREACH_CLIENT(IS_PLAYER(it), { CS(it).killcount = 0; nades_Clear(it); }); //hopefully "{ CS(it).killcount = 0; nades_Clear(it); }" works and doesn't cut off nades_Clear, untested
	FOREACH_CLIENT(IS_PLAYER(it), { nades_Clear(it); MH_FakeTimeLimit(it, -1); }); //hopefully "{ CS(it).killcount = 0; nades_Clear(it); }" works and doesn't cut off nades_Clear, untested

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
// MH_count_players , Team_ functions which are imported
bool MH_CheckTeams()
{
	static int prev_missing_teams_mask;
	allowed_to_spawn_untagged = true;
	MH_count_players();
	// TOFIX: After merging master, this function has been removed
	if ((Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(1)) + 
		Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2))) == NumTeams(mh_teams)){
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
		if (mh_teams & Team_IndexToBit(i)) { // &&
			// TOFIX: After merging master, this function (Team_GetNumberOfTotalPlayers()) has been removed
			//(Team_GetNumberOfTotalPlayers(Team_GetTeamFromIndex(i)) == 0)){
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
	if(autocvar_g_mh_player_waypoints == 0){
		FOREACH_CLIENT(IS_PLAYER(it), 
		{
			if(it.team == Team_IndexToTeam(1))
				it.mh_status = MH_STATUS_HUNTER;
			else if(it.team == Team_IndexToTeam(2))
				it.mh_status = MH_STATUS_RUNNER;
			MH_FakeTimeLimit(it, round_handler_GetEndTime());
		});
		return;
	} else if(autocvar_g_mh_player_waypoints == 1 || autocvar_g_mh_player_waypoints == 2){
		FOREACH_CLIENT(IS_PLAYER(it), 
		{
			if(it.team == Team_IndexToTeam(1))
				it.mh_status = MH_STATUS_HUNTER;
			else if(it.team == Team_IndexToTeam(2))
			{
				it.mh_status = MH_STATUS_RUNNER;
				WaypointSprite_AttachCarrier(WP_Null, it, RADARICON_FLAGCARRIER);
				WaypointSprite_UpdateRule(it.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
				vector pl_color = colormapPaletteColor(it.clientcolors & 0x0F, false);
				WaypointSprite_UpdateTeamRadar(it.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, pl_color);
				WaypointSprite_Ping(it.waypointsprite_attachedforcarrier);
			}
			MH_FakeTimeLimit(it, round_handler_GetEndTime());
		});
	}
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
	
	if (!allowed_to_spawn_untagged && IS_PLAYER(player) && round_handler_IsRoundStarted()){ // this can be true even when player is trying to join
		if (CS(player).jointime != time){ // not when connecting
			MH_FakeTimeLimit(player, round_handler_GetEndTime() - CS(player).jointime); // set HUD with current round time
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

	if (frag_target.waypointsprite_attachedforcarrier)
		WaypointSprite_Kill(frag_target.waypointsprite_attachedforcarrier);

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

// runs on waypoints which are attached to players, updates once per frame
bool mh_waypointsprite_visible_for_player(entity this, entity player, entity view)
{
	//if(IS_PLAYER(view) || this == view || IS_SPEC(player)) //fix me
	//	return false; // we don't want spectators to see the attached waypoint on the top of their screen

	if(autocvar_g_mh_player_waypoints == 0)
		return false;

	return true;
}

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
	player.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
	MH_count_players();
	
	if(autocvar_g_mh_hunterblind)
	{
		if(player.team == Team_IndexToTeam(1))
			HunterEyesStart(player); // Hunters can't see anything until round starts
	}
	
	if(player.team == Team_IndexToTeam(2) && !allowed_to_spawn_untagged && Team_GetNumberOfAlivePlayers(Team_GetTeamFromIndex(2)) > 1 && round_handler_IsActive() && round_handler_IsRoundStarted()){
		player.mh_status = MH_STATUS_RUNNER;
		player.deadflag = 1; // avoid a crash when a spectator joins runners mid-round and gets sent to hunters
		MoveToTeam(player, 1, 6); //index of 1 static is wrong way but it's working somehow with bubblegum and prayers
		player.deadflag = 0; // with bubblegum and prayers, there probably is probably a better check to use here
	}
	if(player.team == Team_IndexToTeam(1) && !IS_DEAD(player) && player.tagteleport == true && !allowed_to_spawn_untagged){
		player.mh_status = MH_STATUS_HUNTER;
		player.tagteleport = false;
		player.origin = player.taggedplayerlocation;
		player.velocity = player.taggedplayervelocity;
		player.angles = player.taggedplayerviewangles;
	}
	//player.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = mh_waypointsprite_visible_for_player; 
	if(autocvar_g_mh_player_waypoints == 2){
		if(player.team == Team_IndexToTeam(1))
		{
			player.mh_status = MH_STATUS_HUNTER;
			WaypointSprite_AttachCarrier(WP_Null, player, RADARICON_FLAGCARRIER);
			//player.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = mh_waypointsprite_visible_for_player;
			WaypointSprite_UpdateRule(player.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
			vector pl_color = colormapPaletteColor(player.clientcolors & 0x0F, false);
			WaypointSprite_UpdateTeamRadar(player.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, pl_color);
			WaypointSprite_Ping(player.waypointsprite_attachedforcarrier);
		};
	}
}

//reset kill streaks and respawn players on round reset
MUTATOR_HOOKFUNCTION(mh, reset_map_players)
{
	FOREACH_CLIENT(true, {
		CS(it).killcount = 0;
		MH_FakeTimeLimit(it, -1);
		if(it.team == Team_IndexToTeam(1))
		{
			if(autocvar_g_mh_hunterblind)
				HunterEyesStart(it); // Hunters can't see anything until round starts
			it.mh_status = MH_STATUS_HUNTER;
		}
		else if(it.team == Team_IndexToTeam(2))
			it.mh_status = MH_STATUS_RUNNER;
		PutClientInServer(it);
		}
	);
	return true;
}

// ===========
//  to change
// ===========



//idk if this function is needed
MUTATOR_HOOKFUNCTION(mh, reset_map_global)
{
	return true;
}