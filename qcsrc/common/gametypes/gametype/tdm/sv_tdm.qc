#include "sv_tdm.qh"

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

void tdm_DelayedInit(entity this)
{
	int numteams = autocvar_g_tdm_teams_override >= 2 ? autocvar_g_tdm_teams_override : autocvar_g_tdm_teams;
	teamplay_bitmask = Team_MapEnts_FindOrSpawn("tdm_team", BITS(bound(2, numteams, 4)));
}

void tdm_Initialize()
{
	GameRules_teams(true);
	GameRules_spawning_teams(autocvar_g_tdm_team_spawns);
	GameRules_limit_score(autocvar_g_tdm_point_limit);
	GameRules_limit_lead(autocvar_g_tdm_point_leadlimit);

	InitializeEntity(NULL, tdm_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_HOOKFUNCTION(tdm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}
