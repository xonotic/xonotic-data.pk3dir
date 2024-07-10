#include "sv_infection.qh"

const int NUM_TEAM_SURVIVOR = 2;
const int NUM_TEAM_INFECTED = 1;

float autocvar_g_infection_round_timelimit = 900;
float autocvar_g_infection_warmup = 10;
float autocvar_g_infection_infected_count = 1;
float autocvar_g_infection_round_enddelay = 1;

spawnfunc(inf_team)
{
	if(!g_infection || !this.cnt) { delete(this); return; }

	this.team = this.cnt + 1;
}

// code from here on is just to support maps that don't have team entities
void Infection_SpawnTeam (string teamname, int teamcolor)
{
	entity this = new_pure(inf_team);
	this.netname = teamname;
	this.cnt = teamcolor - 1;
	this.team = teamcolor;
	this.spawnfunc_checked = true;
}

void Infection_InitTeams(entity this)
{
	// if no teams are found, spawn defaults
	if(find(NULL, classname, "Infection_team") == NULL)
	{
		LOG_TRACE("No \"infection_team\" entities found on this map, creating them anyway.");

		int numteams = 2;

		int teams = BITS(numteams);
		if(teams & BIT(0))
			Infection_SpawnTeam("Infected", NUM_TEAM_2);
		if(teams & BIT(1))
			Infection_SpawnTeam("Survivor", NUM_TEAM_1);
	}
}

bool Infection_CheckPlayers()
{
	allowed_to_spawn = true;
	int playercount = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		++playercount;
	});
	if (playercount < 2) {
		Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_PLAYERS);
		return false;
	}
	return true;
}

bool Infection_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0
		&& autocvar_g_infection_round_enddelay == -1)
	{
		// if the match times out, survivors win
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_INFECTION_SURVIVOR_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_INFECTION_SURVIVOR_WIN);

		allowed_to_spawn = false;
		game_stopped = true;
		round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
		return 1;
	}

	int survivor_count = 0, infected_count = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(Entity_GetTeamIndex(it) == NUM_TEAM_SURVIVOR)
			++survivor_count;
		else if(Entity_GetTeamIndex(it) == NUM_TEAM_INFECTED)
			++infected_count;
	});
	// Not enough infected? Let's infect some players.
	int playercount = survivor_count + infected_count;
	int must_infect = bound(1, ((autocvar_g_infection_infected_count >= 1) ? autocvar_g_infection_infected_count : floor(playercount * autocvar_g_infection_infected_count)), playercount - 1); // 20%, but ensure at least 1 and less than total
	FOREACH_CLIENT_RANDOM(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if(infected_count >= must_infect)
			break;
		++infected_count;
		Player_SetTeamIndex(it, NUM_TEAM_INFECTED);
	});

	if (survivor_count > 0) {
		round_handler_ResetEndDelayTime();
		return 0;
	}

	// delay round ending a bit
	if (autocvar_g_infection_round_enddelay
		&& round_handler_GetEndTime() > 0
		&& round_handler_GetEndTime() - time > 0) // don't delay past timelimit
	{
		if (round_handler_GetEndDelayTime() == -1)
		{
			round_handler_SetEndDelayTime(min(time + autocvar_g_infection_round_enddelay, round_handler_GetEndTime()));
			return 0;
		}
		else if (round_handler_GetEndDelayTime() >= time)
		{
			return 0;
		}
	}

	if(infected_count > 0) // infected win
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_INFECTION_INFECTED_WIN);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_INFECTION_INFECTED_WIN);
	} else {
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
	}

	allowed_to_spawn = false;
	game_stopped = true;
	round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
	return 1;
}

void Infection_RoundStart()
{
	allowed_to_spawn = boolean(warmup_stage);
	FOREACH_CLIENT(IS_PLAYER(it), {
		it.player_blocked = false;
		Player_SetTeamIndex(it, NUM_TEAM_SURVIVOR);
	});
}

void Infection_Initialize()
{
	GameRules_teams(true);
	GameRules_spawning_teams(2);
	InitializeEntity(NULL, Infection_InitTeams, INITPRIO_GAMETYPE);

	allowed_to_spawn = true;
	round_handler_Spawn(Infection_CheckPlayers, Infection_CheckWinner, Infection_RoundStart);
	round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
}

MUTATOR_HOOKFUNCTION(inf, TeamBalance_CheckAllowedTeams)
{
	M_ARGV(0, float) = BIT(0);
	return true;
}

MUTATOR_HOOKFUNCTION(inf, PlayerDies)
{
	entity attacker = M_ARGV(1, entity);
	entity target = M_ARGV(2, entity);

	if (!IS_PLAYER(attacker)) {
		Player_SetTeamIndex(target, NUM_TEAM_INFECTED);
		return true;
	}

	int attacker_team = Entity_GetTeamIndex(attacker);

	if (DIFF_TEAM(attacker, target) && attacker_team != NUM_TEAM_SURVIVOR)
		Player_SetTeamIndex(target, attacker_team);

	return true;
}
