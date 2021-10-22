#include "sv_mh.qh"

// TODO: change this?
int autocvar_g_mh_teams;
int autocvar_g_mh_teams_override;

spawnfunc(mh_team)
{
	if(!g_mh || !this.cnt) { delete(this); return; }

	this.team = this.cnt + 1;
}

// code from here on is just to support maps that don't have team entities
void mh_SpawnTeam (string teamname, int teamcolor)
{
	entity this = new_pure(mh_team);
	this.netname = teamname;
	this.cnt = teamcolor - 1;
	this.team = teamcolor;
	this.spawnfunc_checked = true;
	//spawnfunc_mh_team(this);
}

void mh_DelayedInit(entity this)
{
	// TODO: change this?

	// if no teams are found, spawn defaults
	if(find(NULL, classname, "mh_team") == NULL)
	{
		LOG_TRACE("No \"mh_team\" entities found on this map, creating them anyway.");

		int numteams = autocvar_g_mh_teams_override;
		if(numteams < 2) { numteams = autocvar_g_mh_teams; }

		int teams = BITS(bound(2, numteams, 2));
		if(teams & BIT(0))
			mh_SpawnTeam("Red", NUM_TEAM_1);
		if(teams & BIT(1))
			mh_SpawnTeam("Blue", NUM_TEAM_2);
	}
}

void mh_Initialize()
{
	GameRules_teams(true);
	GameRules_spawning_teams(autocvar_g_mh_team_spawns);
	GameRules_limit_score(autocvar_g_mh_point_limit);
	GameRules_limit_lead(autocvar_g_mh_point_leadlimit);

	InitializeEntity(NULL, mh_DelayedInit, INITPRIO_GAMETYPE);
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
