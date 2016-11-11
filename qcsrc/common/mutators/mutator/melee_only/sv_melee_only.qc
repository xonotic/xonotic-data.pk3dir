#include "sv_melee_only.qh"

REGISTER_MUTATOR(melee_only, cvar("g_melee_only") && !cvar("g_instagib") && !cvar("g_overkill") && !g_nexball);

MUTATOR_HOOKFUNCTION(melee_only, SetStartItems, CBC_ORDER_LAST)
{
	start_ammo_shells = warmup_start_ammo_shells = 0;
	start_weapons = warmup_start_weapons = WEPSET(SHOTGUN);
}

MUTATOR_HOOKFUNCTION(melee_only, SetWeaponArena)
{
	// turn weapon arena off
	M_ARGV(0, string) = "off";
}

MUTATOR_HOOKFUNCTION(melee_only, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(melee_only, FilterItem)
{
	entity item = M_ARGV(0, entity);

	switch (item.itemdef)
	{
		case ITEM_HealthSmall:
		case ITEM_ArmorSmall:
			return false;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(melee_only, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":MeleeOnly");
}

MUTATOR_HOOKFUNCTION(melee_only, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Melee Only Arena");
}
