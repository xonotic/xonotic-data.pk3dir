#include "sv_melee_only.qh"

REGISTER_MUTATOR(melee_only, cvar("g_melee_only") && !cvar("g_instagib") && !g_nexball);

MUTATOR_HOOKFUNCTION(melee_only, SetStartItems, CBC_ORDER_LAST)
{
	start_ammo_shells = warmup_start_ammo_shells = 0;
	start_weapons = warmup_start_weapons = WEPSET(SHOTGUN);
}

MUTATOR_HOOKFUNCTION(melee_only, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(melee_only, FilterItem)
{
	entity item = M_ARGV(0, entity);

	switch (item.items)
	{
		case ITEM_HealthSmall.m_itemid:
		case ITEM_ArmorSmall.m_itemid:
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
