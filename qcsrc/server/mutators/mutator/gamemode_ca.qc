#ifndef GAMEMODE_CA_H
#define GAMEMODE_CA_H

int autocvar_g_ca_point_limit;
int autocvar_g_ca_point_leadlimit;
bool autocvar_g_ca_team_spawns;

void ca_Initialize();

REGISTER_MUTATOR(ca, false)
{
	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		ca_Initialize();

		ActivateTeamplay();
		SetLimits(autocvar_g_ca_point_limit, autocvar_g_ca_point_leadlimit, -1, -1);

		if (autocvar_g_ca_team_spawns)
			have_team_spawns = -1; // request team spawns
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}

// should be removed in the future, as other code should not have to care
.float caplayer; // 0.5 if scheduled to join the next round
#endif

#ifdef IMPLEMENTATION
float autocvar_g_ca_damage2score_multiplier;
float autocvar_g_ca_round_timelimit;
bool autocvar_g_ca_spectate_enemies;
int autocvar_g_ca_teams;
int autocvar_g_ca_teams_override;
float autocvar_g_ca_warmup;

float ca_teams;
float allowed_to_spawn;

const float ST_CA_ROUNDS = 1;
void ca_ScoreRules(float teams)
{
	ScoreRules_basics(teams, SFL_SORT_PRIO_PRIMARY, 0, true);
	ScoreInfo_SetLabel_TeamScore(ST_CA_ROUNDS, "rounds", SFL_SORT_PRIO_PRIMARY);
	ScoreRules_basics_end();
}

void CA_count_alive_players()
{
	entity e;
	total_players = redalive = bluealive = yellowalive = pinkalive = 0;
	FOR_EACH_PLAYER(e) {
		if(e.team == NUM_TEAM_1)
		{
			++total_players;
			if (e.health >= 1) ++redalive;
		}
		else if(e.team == NUM_TEAM_2)
		{
			++total_players;
			if (e.health >= 1) ++bluealive;
		}
		else if(e.team == NUM_TEAM_3)
		{
			++total_players;
			if (e.health >= 1) ++yellowalive;
		}
		else if(e.team == NUM_TEAM_4)
		{
			++total_players;
			if (e.health >= 1) ++pinkalive;
		}
	}
	FOR_EACH_REALCLIENT(e) {
		e.redalive_stat = redalive;
		e.bluealive_stat = bluealive;
		e.yellowalive_stat = yellowalive;
		e.pinkalive_stat = pinkalive;
	}
}

float CA_GetWinnerTeam()
{
	float winner_team = 0;
	if(redalive >= 1)
		winner_team = NUM_TEAM_1;
	if(bluealive >= 1)
	{
		if(winner_team) return 0;
		winner_team = NUM_TEAM_2;
	}
	if(yellowalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = NUM_TEAM_3;
	}
	if(pinkalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = NUM_TEAM_4;
	}
	if(winner_team)
		return winner_team;
	return -1; // no player left
}

#define CA_ALIVE_TEAMS() ((redalive > 0) + (bluealive > 0) + (yellowalive > 0) + (pinkalive > 0))
#define CA_ALIVE_TEAMS_OK() (CA_ALIVE_TEAMS() == ca_teams)
float CA_CheckWinner()
{
	entity e;
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_OVER);
		allowed_to_spawn = false;
		round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);
		FOR_EACH_PLAYER(e)
			nades_Clear(e);
		return 1;
	}

	CA_count_alive_players();
	if(CA_ALIVE_TEAMS() > 1)
		return 0;

	float winner_team = CA_GetWinnerTeam();
	if(winner_team > 0)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, APP_TEAM_NUM_4(winner_team, CENTER_ROUND_TEAM_WIN_));
		Send_Notification(NOTIF_ALL, world, MSG_INFO, APP_TEAM_NUM_4(winner_team, INFO_ROUND_TEAM_WIN_));
		TeamScore_AddToTeam(winner_team, ST_CA_ROUNDS, +1);
	}
	else if(winner_team == -1)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_TIED);
	}

	allowed_to_spawn = false;
	round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);

	FOR_EACH_PLAYER(e)
		nades_Clear(e);

	return 1;
}

void CA_RoundStart()
{
	if(warmup_stage)
		allowed_to_spawn = true;
	else
		allowed_to_spawn = false;
}

float CA_CheckTeams()
{
	static float prev_missing_teams_mask;
	allowed_to_spawn = true;
	CA_count_alive_players();
	if(CA_ALIVE_TEAMS_OK())
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, world, MSG_CENTER_CPID, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return 1;
	}
	if(total_players == 0)
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, world, MSG_CENTER_CPID, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		return 0;
	}
	float missing_teams_mask = (!redalive) + (!bluealive) * 2;
	if(ca_teams >= 3) missing_teams_mask += (!yellowalive) * 4;
	if(ca_teams >= 4) missing_teams_mask += (!pinkalive) * 8;
	if(prev_missing_teams_mask != missing_teams_mask)
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_MISSING_TEAMS, missing_teams_mask);
		prev_missing_teams_mask = missing_teams_mask;
	}
	return 0;
}

float ca_isEliminated(entity e)
{
	if(e.caplayer == 1 && (e.deadflag != DEAD_NO || e.frags == FRAGS_LMS_LOSER))
		return true;
	if(e.caplayer == 0.5)
		return true;
	return false;
}

/** Returns next available player to spectate if g_ca_spectate_enemies == 0 */
entity CA_SpectateNext(entity player, entity start)
{
    if (SAME_TEAM(start, player)) return start;
	// continue from current player
	for (entity e = start; (e = find(e, classname, "player")); )
	{
		if (SAME_TEAM(player, e)) return e;
	}
	// restart from begining
	for (entity e = NULL; (e = find(e, classname, "player")); )
	{
		if (SAME_TEAM(player, e)) return e;
	}
	return start;
}


MUTATOR_HOOKFUNCTION(ca, PlayerSpawn)
{SELFPARAM();
	self.caplayer = 1;
	if(!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, PutClientInServer)
{SELFPARAM();
	if(!allowed_to_spawn)
	if(IS_PLAYER(self)) // this is true even when player is trying to join
	{
		self.classname = STR_OBSERVER;
		if(self.jointime != time) //not when connecting
		if(!self.caplayer)
		{
			self.caplayer = 0.5;
			if(IS_REAL_CLIENT(self))
				Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_CA_JOIN_LATE);
		}
	}
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, reset_map_players)
{SELFPARAM();
	entity e;
	FOR_EACH_CLIENT(e)
	{
		setself(e);
		self.killcount = 0;
		if(!self.caplayer && IS_BOT_CLIENT(self))
		{
			self.team = -1;
			self.caplayer = 1;
		}
		if(self.caplayer)
		{
			self.classname = STR_PLAYER;
			self.caplayer = 1;
			PutClientInServer();
		}
	}
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, ClientConnect)
{SELFPARAM();
	self.classname = STR_OBSERVER;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, reset_map_global)
{
	allowed_to_spawn = true;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, GetTeamCount, CBC_ORDER_EXCLUSIVE)
{
	ret_float = ca_teams;
	return false;
}

entity ca_LastPlayerForTeam()
{SELFPARAM();
	entity pl, last_pl = world;
	FOR_EACH_PLAYER(pl)
	{
		if(pl.health >= 1)
		if(pl != self)
		if(pl.team == self.team)
		if(!last_pl)
			last_pl = pl;
		else
			return world;
	}
	return last_pl;
}

void ca_LastPlayerForTeam_Notify()
{
	if(round_handler_IsActive())
	if(round_handler_IsRoundStarted())
	{
		entity pl = ca_LastPlayerForTeam();
		if(pl)
			Send_Notification(NOTIF_ONE, pl, MSG_CENTER, CENTER_ALONE);
	}
}

MUTATOR_HOOKFUNCTION(ca, PlayerDies)
{SELFPARAM();
	ca_LastPlayerForTeam_Notify();
	if(!allowed_to_spawn)
		self.respawn_flags =  RESPAWN_SILENT;
	if(!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, ClientDisconnect)
{SELFPARAM();
	if(self.caplayer == 1)
		ca_LastPlayerForTeam_Notify();
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, ForbidPlayerScore_Clear)
{
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, MakePlayerObserver)
{SELFPARAM();
	if(self.caplayer == 1)
		ca_LastPlayerForTeam_Notify();
	if(self.killindicator_teamchange == -2)
		self.caplayer = 0;
	if(self.caplayer)
		self.frags = FRAGS_LMS_LOSER;
	if(!warmup_stage)
		eliminatedPlayers.SendFlags |= 1;
	return true;
}

MUTATOR_HOOKFUNCTION(ca, ForbidThrowCurrentWeapon)
{
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, GiveFragsForKill, CBC_ORDER_FIRST)
{
	frag_score = 0; // score will be given to the winner team when the round ends
	return 1;
}

MUTATOR_HOOKFUNCTION(ca, SetStartItems)
{
	start_items &= ~IT_UNLIMITED_AMMO;
	start_health       = warmup_start_health       = cvar("g_lms_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_lms_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_lms_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_lms_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_lms_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_lms_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_lms_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_lms_start_ammo_fuel");

	return 0;
}

MUTATOR_HOOKFUNCTION(ca, PlayerDamage_Calculate)
{
	if(IS_PLAYER(frag_target))
	if(frag_target.deadflag == DEAD_NO)
	if(frag_target == frag_attacker || SAME_TEAM(frag_target, frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	frag_mirrordamage = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(ca, FilterItem)
{SELFPARAM();
	if(autocvar_g_powerups <= 0)
	if(self.flags & FL_POWERUP)
		return true;

	if(autocvar_g_pickup_items <= 0)
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(ca, PlayerDamage_SplitHealthArmor)
{
	float excess = max(0, frag_damage - damage_take - damage_save);

	if(frag_target != frag_attacker && IS_PLAYER(frag_attacker))
		PlayerTeamScore_Add(frag_attacker, SP_SCORE, ST_SCORE, (frag_damage - excess) * autocvar_g_ca_damage2score_multiplier);

	return false;
}

MUTATOR_HOOKFUNCTION(ca, PlayerRegen)
{
	// no regeneration in CA
	return true;
}

MUTATOR_HOOKFUNCTION(ca, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(ca, SpectateSet)
{
	if(!autocvar_g_ca_spectate_enemies && self.caplayer)
	if(DIFF_TEAM(spec_player, self))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(ca, SpectateNext)
{SELFPARAM();
	if(!autocvar_g_ca_spectate_enemies && self.caplayer)
	{
		spec_player = CA_SpectateNext(self, spec_player);
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(ca, SpectatePrev)
{SELFPARAM();
	if(!autocvar_g_ca_spectate_enemies && self.caplayer)
	{
		do { spec_player = spec_player.chain; }
		while(spec_player && DIFF_TEAM(spec_player, self));

		if (!spec_player)
		{
			spec_player = spec_first;
			while(spec_player && DIFF_TEAM(spec_player, self))
				spec_player = spec_player.chain;
			if(spec_player == self.enemy)
				return MUT_SPECPREV_RETURN;
		}
	}

	return MUT_SPECPREV_FOUND;
}

MUTATOR_HOOKFUNCTION(ca, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	entity head;
	FOR_EACH_REALCLIENT(head)
	{
		if(IS_PLAYER(head) || head.caplayer == 1)
			++bot_activerealplayers;
		++bot_realplayers;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ca, ClientCommand_Spectate)
{
	if(self.caplayer)
	{
		// they're going to spec, we can do other checks
		if(autocvar_sv_spectate && (IS_SPEC(self) || IS_OBSERVER(self)))
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_CA_LEAVE);
		return MUT_SPECCMD_FORCE;
	}

	return MUT_SPECCMD_CONTINUE;
}

MUTATOR_HOOKFUNCTION(ca, WantWeapon)
{
	want_allguns = true;
	return false;
}

MUTATOR_HOOKFUNCTION(ca, GetPlayerStatus)
{
	if(set_player.caplayer == 1)
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(ca, SetWeaponArena)
{
	// most weapons arena
	if(ret_string == "0" || ret_string == "")
		ret_string = "most";
	return false;
}

void ca_Initialize()
{
	allowed_to_spawn = true;

	ca_teams = autocvar_g_ca_teams_override;
	if(ca_teams < 2)
		ca_teams = autocvar_g_ca_teams;
	ca_teams = bound(2, ca_teams, 4);
	ret_float = ca_teams;
	ca_ScoreRules(ca_teams);

	round_handler_Spawn(CA_CheckTeams, CA_CheckWinner, CA_RoundStart);
	round_handler_Init(5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);

	EliminatedPlayers_Init(ca_isEliminated);
}

#endif
