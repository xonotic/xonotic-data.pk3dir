#include "sv_mayhem.qh"

#include "sv_util.qh"

float autocvar_g_mayhem_point_limit;
float autocvar_g_mayhem_point_leadlimit;

bool autocvar_g_mayhem_regenerate;
bool autocvar_g_mayhem_rot;
string autocvar_g_mayhem_weaponarena;
bool autocvar_g_mayhem_powerups;
bool autocvar_g_mayhem_selfdamage;
float autocvar_g_mayhem_scoring_upscaler;
float autocvar_g_mayhem_scoring_damage_weight;
float autocvar_g_mayhem_scoring_kill_weight;
bool autocvar_g_mayhem_scoring_disable_selfdamage2score;
bool autocvar_g_mayhem_pickup_items;
bool autocvar_g_mayhem_pickup_items_remove_weapons_and_ammo;
bool autocvar_g_mayhem_unlimited_ammo;

float autocvar_g_mayhem_start_health = 200;
float autocvar_g_mayhem_start_armor = 200;
float autocvar_g_mayhem_start_ammo_shells = 60;
float autocvar_g_mayhem_start_ammo_nails = 320;
float autocvar_g_mayhem_start_ammo_rockets = 160;
float autocvar_g_mayhem_start_ammo_cells = 180;
float autocvar_g_mayhem_start_ammo_fuel = 0;


void mayhem_Initialize()
{
	GameRules_limit_score(autocvar_g_mayhem_point_limit);
	GameRules_limit_lead(autocvar_g_mayhem_point_leadlimit);
}

/*
MUTATOR_HOOKFUNCTION(mayhem, Scores_CountFragsRemaining)
{
	// do not announce remaining frags, upscaled score count doesn't match well with this
	// when scorelimit is set to 1000 it would announce 997, 998 and 999 score counts
	// usually a single shot which deals ~40-80 dmg gives 2 or 3 score
	// this usually would cause a "2 fra..." announcement to be played as the match ends
	// without leaving anyone time to even process the announcement
	return false;
}
*/

MUTATOR_HOOKFUNCTION(mayhem, SetStartItems)
{
	mayhem_util_SetStartItems(autocvar_g_mayhem_unlimited_ammo,
		autocvar_g_mayhem_start_health,
		autocvar_g_mayhem_start_armor,
		autocvar_g_mayhem_start_ammo_shells,
		autocvar_g_mayhem_start_ammo_nails,
		autocvar_g_mayhem_start_ammo_rockets,
		autocvar_g_mayhem_start_ammo_cells,
		autocvar_g_mayhem_start_ammo_fuel);
}

MUTATOR_HOOKFUNCTION(mayhem, PlayerRegen)
{
	return mayhem_util_PlayerRegen(autocvar_g_mayhem_regenerate, autocvar_g_mayhem_rot);
}

MUTATOR_HOOKFUNCTION(mayhem, ForbidThrowCurrentWeapon)
{
	return mayhem_util_ForbidThrowCurrentWeapon();
}

MUTATOR_HOOKFUNCTION(mayhem, SetWeaponArena)
{
	mayhem_util_SetWeaponArena(autocvar_g_mayhem_weaponarena);
}

MUTATOR_HOOKFUNCTION(mayhem, FilterItem)
{
	return mayhem_util_FilterItem(autocvar_g_mayhem_powerups,
		autocvar_g_mayhem_pickup_items,
		autocvar_g_mayhem_pickup_items_remove_weapons_and_ammo);
}

MUTATOR_HOOKFUNCTION(mayhem, Damage_Calculate)
{
	mayhem_util_Damage_Calculate(autocvar_g_mayhem_selfdamage);
}

MUTATOR_HOOKFUNCTION(mayhem, PlayerDamage_SplitHealthArmor)
{
	mayhem_util_PlayerDamage_SplitHealthArmor(autocvar_g_mayhem_scoring_upscaler,
		autocvar_g_mayhem_scoring_kill_weight,
		autocvar_g_mayhem_scoring_damage_weight,
		autocvar_g_mayhem_scoring_disable_selfdamage2score);
}

MUTATOR_HOOKFUNCTION(mayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	return mayhem_util_GiveFragsForKill(autocvar_g_mayhem_scoring_upscaler,
		autocvar_g_mayhem_scoring_kill_weight,
		autocvar_g_mayhem_scoring_damage_weight,
		autocvar_g_mayhem_scoring_disable_selfdamage2score);
}

MUTATOR_HOOKFUNCTION(mayhem, reset_map_players)
{
	return mayhem_util_reset_map_players();
}
