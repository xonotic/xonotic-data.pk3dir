#include "sv_melee_only.qh"

#include "../overkill/sv_overkill.qh"

string autocvar_g_melee_only;
REGISTER_MUTATOR(melee_only, expr_evaluate(autocvar_g_melee_only) && !MUTATOR_IS_ENABLED(mutator_instagib) && !MUTATOR_IS_ENABLED(ok) && !MapInfo_LoadedGametype.m_weaponarena);

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

MUTATOR_HOOKFUNCTION(melee_only, ForbidRandomStartWeapons)
{
	return true;
}

MUTATOR_HOOKFUNCTION(melee_only, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(melee_only, FilterItemDefinition)
{
	entity definition = M_ARGV(0, entity);

	switch (definition)
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
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Melee only Arena");
}
