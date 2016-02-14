#ifndef GAMEMODE_TDM_H
#define GAMEMODE_TDM_H

int autocvar_g_tdm_point_limit;
int autocvar_g_tdm_point_leadlimit;
bool autocvar_g_tdm_team_spawns;
void tdm_DelayedInit();

REGISTER_MUTATOR(tdm, false)
{
	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		InitializeEntity(world, tdm_DelayedInit, INITPRIO_GAMETYPE);

		ActivateTeamplay();
		SetLimits(autocvar_g_tdm_point_limit, autocvar_g_tdm_point_leadlimit, -1, -1);
		if (autocvar_g_tdm_team_spawns)
			have_team_spawns = -1; // request team spawns
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back tdm_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}

#endif

#ifdef IMPLEMENTATION
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
	if(!g_tdm || !self.cnt) { remove(self); return; }

	self.classname = "tdm_team";
	self.team = self.cnt + 1;
}

// code from here on is just to support maps that don't have team entities
void tdm_SpawnTeam (string teamname, float teamcolor)
{
	entity this = new(tdm_team);
	this.netname = teamname;
	this.cnt = teamcolor;
	this.spawnfunc_checked = true;
	WITH(entity, self, this, spawnfunc_tdm_team(this));
}

void tdm_DelayedInit()
{
	// if no teams are found, spawn defaults
	if(find(world, classname, "tdm_team") == world)
	{
		LOG_TRACE("No \"tdm_team\" entities found on this map, creating them anyway.\n");

		int numteams = min(4, autocvar_g_tdm_teams_override);

		if(numteams < 2) { numteams = autocvar_g_tdm_teams; }
		numteams = bound(2, numteams, 4);

		float i;
		for(i = 1; i <= numteams; ++i)
			tdm_SpawnTeam(Team_ColorName(Team_NumberToTeam(i)), Team_NumberToTeam(i) - 1);
	}
}

MUTATOR_HOOKFUNCTION(tdm, GetTeamCount, CBC_ORDER_EXCLUSIVE)
{
	ret_string = "tdm_team";
	return true;
}

MUTATOR_HOOKFUNCTION(tdm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

#endif
