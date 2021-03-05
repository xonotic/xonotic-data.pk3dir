#include "sv_mayhem.qh"

bool autocvar_g_mayhem_regenerate;

MUTATOR_HOOKFUNCTION(mayhem, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	start_health       = warmup_start_health       = cvar("g_lms_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_lms_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_lms_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_lms_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_lms_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_lms_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_lms_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_lms_start_ammo_fuel");
}

MUTATOR_HOOKFUNCTION(mayhem, PlayerRegen)
{
	if(autocvar_g_mayhem_regenerate)
		return false;
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_mayhem_weaponarena;
}

MUTATOR_HOOKFUNCTION(mayhem, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if (autocvar_g_powerups <= 0)
	if (item.flags & FL_POWERUP)
		return true;

	if (autocvar_g_pickup_items <= 0)
		return true;
}