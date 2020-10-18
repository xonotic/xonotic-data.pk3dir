#include "unvanquished.qh"

//#include <common/gamemodes/gamemode/ctf/sv_ctf.qh>
#include <server/spawnpoints.qh>

spawnfunc(item_flag_team1);
spawnfunc(item_flag_team2);

//***********************
//UNVANQUISHED ENTITIES - So people can play Unvanquished maps with the xonotic weapons
//***********************

spawnfunc(team_alien_spawn)
{
	this.team = NUM_TEAM_1; // red
	spawnfunc_info_player_deathmatch(this);
}

spawnfunc(team_human_spawn)
{
	this.team = NUM_TEAM_2; // blue
	spawnfunc_info_player_deathmatch(this);
}

spawnfunc(team_alien_overmind) { spawnfunc_item_flag_team1(this); }
spawnfunc(team_human_reactor) { spawnfunc_item_flag_team2(this); }
