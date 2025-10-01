#include "sv_tdm.qh"

// TODO? rename to teamdeathmatch
int autocvar_g_tdm_teams;
int autocvar_g_tdm_teams_override;

/*QUAKED spawnfunc_tdm_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for TDM gameplay, this allows you to decide what team names and control point models are used in your map.
Note: If you use spawnfunc_tdm_team entities you must define at least 2!  However, unlike domination, you don't need to make a blank one too.
Keys:
"netname" Name of the team (for example Red, Blue, Green, Yellow, Life, Death, Offense, Defense, etc)...
"cnt" Scoreboard color of the team (for example 4 is red and 13 is blue)... */
spawnfunc(tdm_team)
{
	if(!g_tdm || !this.cnt) { delete(this); return; }

	this.team = this.cnt + 1;
}

// code from here on is just to support maps that don't have team entities
void tdm_SpawnTeam (string teamname, int teamcolor)
{
	entity this = new_pure(tdm_team);
	this.netname = teamname;
	this.cnt = teamcolor - 1;
	this.team = teamcolor;
	this.spawnfunc_checked = true;
	//spawnfunc_tdm_team(this);
}

void tdm_DelayedInit(entity this)
{
	// if no teams are found, spawn defaults
	if(find(NULL, classname, "tdm_team") == NULL)
	{
		LOG_TRACE("No \"tdm_team\" entities found on this map, creating them anyway.");

		int numteams = autocvar_g_tdm_teams_override;
		if(numteams < 2) { numteams = autocvar_g_tdm_teams; }

		int teams = BITS(bound(2, numteams, 4));
		if(teams & BIT(0))
			tdm_SpawnTeam("Red", NUM_TEAM_1);
		if(teams & BIT(1))
			tdm_SpawnTeam("Blue", NUM_TEAM_2);
		if(teams & BIT(2))
			tdm_SpawnTeam("Yellow", NUM_TEAM_3);
		if(teams & BIT(3))
			tdm_SpawnTeam("Pink", NUM_TEAM_4);
	}
}

void tdm_Initialize()
{
	GameRules_teams(true);
	GameRules_spawning_teams(autocvar_g_tdm_team_spawns);
	GameRules_limit_score(autocvar_g_tdm_point_limit);
	GameRules_limit_lead(autocvar_g_tdm_point_leadlimit);

	InitializeEntity(NULL, tdm_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_HOOKFUNCTION(tdm, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "tdm_team";
}

MUTATOR_HOOKFUNCTION(tdm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}
