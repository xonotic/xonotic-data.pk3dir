float total_players;
float redalive, bluealive, yellowalive, pinkalive;
.float redalive_stat, bluealive_stat, yellowalive_stat, pinkalive_stat;
float ca_teams;
float allowed_to_spawn;

void CA_count_alive_players()
{
	entity e;
	total_players = redalive = bluealive = yellowalive = pinkalive = 0;
	FOR_EACH_PLAYER(e) {
		if(e.team == COLOR_TEAM1)
		{
			++total_players;
			if (e.health >= 1) ++redalive;
		}
		else if(e.team == COLOR_TEAM2)
		{
			++total_players;
			if (e.health >= 1) ++bluealive;
		}
		else if(e.team == COLOR_TEAM3)
		{
			++total_players;
			if (e.health >= 1) ++yellowalive;
		}
		else if(e.team == COLOR_TEAM4)
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
		winner_team = COLOR_TEAM1;
	if(bluealive >= 1)
	{
		if(winner_team) return 0;
		winner_team = COLOR_TEAM2;
	}
	if(yellowalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = COLOR_TEAM3;
	}
	if(pinkalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = COLOR_TEAM4;
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
	if(round_handler_GetTimeLeft() <= 0)
	{
		FOR_EACH_REALCLIENT(e)
			centerprint(e, "Round over, there's no winner");
		bprint("Round over, there's no winner.\n");
		allowed_to_spawn = TRUE;
		return 1;
	}

	CA_count_alive_players();
	if(CA_ALIVE_TEAMS() > 1)
		return 0;

	float winner_team;
	string teamname;
	winner_team = CA_GetWinnerTeam();
	if(winner_team > 0)
	{
		teamname = ColoredTeamName(winner_team);
		FOR_EACH_REALCLIENT(e)
			centerprint(e, strcat(teamname, " wins the round"));
		bprint(teamname, " wins the round.\n");
		TeamScore_AddToTeam(winner_team, ST_SCORE, +1);
	}
	else if(winner_team == -1)
	{
		FOR_EACH_REALCLIENT(e)
			centerprint(e, "Round tied");
		bprint("Round tied.\n");
	}

	allowed_to_spawn = TRUE;
	return 1;
}

void CA_RoundStart()
{
	if(inWarmupStage)
		allowed_to_spawn = TRUE;
	else
		allowed_to_spawn = FALSE;
}

float prev_total_players;
float CA_CheckTeams()
{
	entity e;
	allowed_to_spawn = TRUE;
	CA_count_alive_players();
	if(CA_ALIVE_TEAMS_OK())
	{
		if(prev_total_players != -1)
		{
			FOR_EACH_REALCLIENT(e)
				Send_CSQC_Centerprint_Generic_Expire(e, CPID_WAITING_PLAYERS);
		}
		prev_total_players = -1;
		return 1;
	}
	if(prev_total_players != total_players)
	{
		string teams_missing = "";
		if(!redalive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM1), ", ");
		if(!bluealive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM2), ", ");
		if(ca_teams >= 3)
		if(!yellowalive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM3), ", ");
		if(ca_teams == 4)
		if(!pinkalive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM4), ", ");
		teams_missing = substring(teams_missing, 0, strlen(teams_missing)-2);

		FOR_EACH_REALCLIENT(e)
			Send_CSQC_Centerprint_Generic(e, CPID_WAITING_PLAYERS, strcat("Waiting for players to join...\n\nNeed active players for: ", teams_missing), -1, 0);
		prev_total_players = total_players;
	}
	return 0;
}

MUTATOR_HOOKFUNCTION(ca_PlayerSpawn)
{
	self.caplayer = TRUE;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_PutClientInServer)
{
	if(clienttype(self) == CLIENTTYPE_BOT)
		self.caplayer = TRUE;
	if(!allowed_to_spawn)
		self.classname = "observer";
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_reset_map_players)
{
	FOR_EACH_CLIENT(self)
	{
		if(self.caplayer)
		{
			self.classname = "player";
			PutClientInServer();
		}
	}
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_ClientConnect)
{
	self.classname = "observer";
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_reset_map_global)
{
	allowed_to_spawn = TRUE;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_GetTeamCount)
{
	ca_teams = autocvar_g_ca_teams_override;
	if(ca_teams < 2)
		ca_teams = autocvar_g_ca_teams;
	ca_teams = bound(2, ca_teams, 4);
	ret_float = ca_teams;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_PlayerPreThink)
{
	if(!allowed_to_spawn)
		self.stat_respawn_time = 0;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_ForbidPlayerScore_Clear)
{
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_MakePlayerObserver)
{
	if(self.caplayer)
		self.frags = FRAGS_LMS_LOSER;
	return 1;
}

MUTATOR_HOOKFUNCTION(ca_ForbidThrowCurrentWeapon)
{
	return 1;
}

void ca_Initialize()
{
	allowed_to_spawn = TRUE;

	round_handler_Spawn(CA_CheckTeams, CA_CheckWinner, CA_RoundStart, 5, autocvar_g_ca_warmup, autocvar_g_ca_round_timelimit);

	addstat(STAT_REDALIVE, AS_INT, redalive_stat);
	addstat(STAT_BLUEALIVE, AS_INT, bluealive_stat);
	addstat(STAT_YELLOWALIVE, AS_INT, yellowalive_stat);
	addstat(STAT_PINKALIVE, AS_INT, pinkalive_stat);
}

MUTATOR_DEFINITION(gamemode_ca)
{
	MUTATOR_HOOK(PlayerSpawn, ca_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PutClientInServer, ca_PutClientInServer, CBC_ORDER_ANY);
	MUTATOR_HOOK(MakePlayerObserver, ca_MakePlayerObserver, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientConnect, ca_ClientConnect, CBC_ORDER_ANY);
	MUTATOR_HOOK(reset_map_global, ca_reset_map_global, CBC_ORDER_ANY);
	MUTATOR_HOOK(reset_map_players, ca_reset_map_players, CBC_ORDER_ANY);
	MUTATOR_HOOK(GetTeamCount, ca_GetTeamCount, CBC_ORDER_EXCLUSIVE);
	MUTATOR_HOOK(PlayerPreThink, ca_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidPlayerScore_Clear, ca_ForbidPlayerScore_Clear, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, ca_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		ca_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		error("This is a game type and it cannot be removed at runtime.");
	}

	return 0;
}
