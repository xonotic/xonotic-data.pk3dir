#include "sv_tmayhem.qh"

#include <common/gametypes/gametype/mayhem/sv_util.qh>

float autocvar_g_tmayhem_point_limit;
float autocvar_g_tmayhem_point_leadlimit;

int autocvar_g_tmayhem_teams;
int autocvar_g_tmayhem_teams_override;
bool autocvar_g_tmayhem_team_spawns;

bool autocvar_g_tmayhem_regenerate;
bool autocvar_g_tmayhem_rot;
string autocvar_g_tmayhem_weaponarena;
bool autocvar_g_tmayhem_powerups;
bool autocvar_g_tmayhem_selfdamage;
float autocvar_g_tmayhem_scoring_upscaler;
float autocvar_g_tmayhem_scoring_kill_weight;
float autocvar_g_tmayhem_scoring_damage_weight;
bool autocvar_g_tmayhem_scoring_disable_selfdamage2score;
bool autocvar_g_tmayhem_pickup_items;
bool autocvar_g_tmayhem_pickup_items_remove_weapons_and_ammo;
bool autocvar_g_tmayhem_unlimited_ammo;

float autocvar_g_tmayhem_start_health = 200;
float autocvar_g_tmayhem_start_armor = 200;
float autocvar_g_tmayhem_start_ammo_shells = 60;
float autocvar_g_tmayhem_start_ammo_nails = 320;
float autocvar_g_tmayhem_start_ammo_rockets = 160;
float autocvar_g_tmayhem_start_ammo_cells = 180;
float autocvar_g_tmayhem_start_ammo_fuel = 0;


void tmayhem_DelayedInit(entity this)
{
	int numteams = (autocvar_g_tmayhem_teams_override >= 2)
		? autocvar_g_tmayhem_teams_override
		: autocvar_g_tmayhem_teams;
	teamplay_bitmask = Team_MapEnts_FindOrSpawn("tmayhem_team", BITS(bound(2, numteams, 4)));
}

void tmayhem_Initialize()
{
	GameRules_teams(true);
	GameRules_spawning_teams(autocvar_g_tmayhem_team_spawns);

	GameRules_limit_score(autocvar_g_tmayhem_point_limit);
	GameRules_limit_lead(autocvar_g_tmayhem_point_leadlimit);

	InitializeEntity(NULL, tmayhem_DelayedInit, INITPRIO_GAMETYPE);
}

/*
MUTATOR_HOOKFUNCTION(tmayhem, Scores_CountFragsRemaining)
{
	// do not announce remaining frags, upscaled score count doesn't match well with this
	// when scorelimit is set to 1000 it would announce 997, 998 and 999 score counts
	// usually a single shot which deals ~40-80 dmg gives 2 or 3 score
	// this usually would cause a "2 fra..." announcement to be played as the match ends
	// without leaving anyone time to even process the announcement
	return false;
}
*/

MUTATOR_HOOKFUNCTION(tmayhem, SetStartItems)
{
	mayhem_util_SetStartItems(autocvar_g_tmayhem_unlimited_ammo,
		autocvar_g_tmayhem_start_health,
		autocvar_g_tmayhem_start_armor,
		autocvar_g_tmayhem_start_ammo_shells,
		autocvar_g_tmayhem_start_ammo_nails,
		autocvar_g_tmayhem_start_ammo_rockets,
		autocvar_g_tmayhem_start_ammo_cells,
		autocvar_g_tmayhem_start_ammo_fuel);
}

MUTATOR_HOOKFUNCTION(tmayhem, PlayerRegen)
{
	return mayhem_util_PlayerRegen(autocvar_g_tmayhem_regenerate, autocvar_g_tmayhem_rot);
}

MUTATOR_HOOKFUNCTION(tmayhem, ForbidThrowCurrentWeapon)
{
	return mayhem_util_ForbidThrowCurrentWeapon();
}

MUTATOR_HOOKFUNCTION(tmayhem, SetWeaponArena)
{
	mayhem_util_SetWeaponArena(autocvar_g_tmayhem_weaponarena);
}

MUTATOR_HOOKFUNCTION(tmayhem, FilterItem)
{
	return mayhem_util_FilterItem(autocvar_g_tmayhem_powerups,
		autocvar_g_tmayhem_pickup_items,
		autocvar_g_tmayhem_pickup_items_remove_weapons_and_ammo);
}

MUTATOR_HOOKFUNCTION(tmayhem, Damage_Calculate)
{
	mayhem_util_Damage_Calculate(autocvar_g_tmayhem_selfdamage);

	M_ARGV(5, float) = 0; // no mirror damaging
}

MUTATOR_HOOKFUNCTION(tmayhem, PlayerDamage_SplitHealthArmor)
{
	mayhem_util_PlayerDamage_SplitHealthArmor(autocvar_g_tmayhem_scoring_upscaler,
		autocvar_g_tmayhem_scoring_kill_weight,
		autocvar_g_tmayhem_scoring_damage_weight,
		autocvar_g_tmayhem_scoring_disable_selfdamage2score);
}

MUTATOR_HOOKFUNCTION(tmayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	return mayhem_util_GiveFragsForKill(autocvar_g_tmayhem_scoring_upscaler,
		autocvar_g_tmayhem_scoring_kill_weight,
		autocvar_g_tmayhem_scoring_damage_weight,
		autocvar_g_tmayhem_scoring_disable_selfdamage2score);
}

MUTATOR_HOOKFUNCTION(tmayhem, reset_map_players)
{
	return mayhem_util_reset_map_players();
}
