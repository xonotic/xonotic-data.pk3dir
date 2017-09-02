#include "gamemode_tdm.qh"

/*QUAKED spawnfunc_tdm_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for TDM gameplay, this allows you to decide what team names and control point models are used in your map.
Note: If you use spawnfunc_tdm_team entities you must define at least 2!  However, unlike domination, you don't need to make a blank one too.
Keys:
"netname" Name of the team (for example Red, Blue, Green, Yellow, Life, Death, Offense, Defense, etc)...
"cnt" Scoreboard color of the team (for example 4 is red and 13 is blue)... */
spawnfunc(tdm_team)
{
	if(!g_tdm || !this.cnt) { delete(this); return; }

	this.classname = "tdm_team";
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

MUTATOR_HOOKFUNCTION(tdm, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "tdm_team";
	return true;
}

MUTATOR_HOOKFUNCTION(tdm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}
