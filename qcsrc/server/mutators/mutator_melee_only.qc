
#include "mutator.qh"

MUTATOR_HOOKFUNCTION(melee_SetStartItems)
{
	start_ammo_shells = warmup_start_ammo_shells = 0;
	start_weapons = warmup_start_weapons = WEPSET(SHOTGUN);

	return false;
}

MUTATOR_HOOKFUNCTION(melee_ForbidThrowing)
{
	return true;
}

MUTATOR_HOOKFUNCTION(melee_FilterItem)
{SELFPARAM();
	switch (self.items)
	{
		case ITEM_HealthSmall.m_itemid:
		case ITEM_ArmorSmall.m_itemid:
			return false;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(melee_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":MeleeOnly");
	return false;
}

MUTATOR_HOOKFUNCTION(melee_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Melee Only Arena");
	return false;
}

MUTATOR_DEFINITION(mutator_melee_only)
{
	MUTATOR_HOOK(SetStartItems, melee_SetStartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, melee_ForbidThrowing, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, melee_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, melee_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, melee_BuildMutatorsPrettyString, CBC_ORDER_ANY);

	return false;
}
