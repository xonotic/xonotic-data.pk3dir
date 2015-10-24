#ifdef IMPLEMENTATION
REGISTER_MUTATOR(melee_only, cvar("g_melee_only") && !cvar("g_instagib") && !g_nexball);

MUTATOR_HOOKFUNCTION(melee_only, SetStartItems)
{
	start_ammo_shells = warmup_start_ammo_shells = 0;
	start_weapons = warmup_start_weapons = WEPSET(SHOTGUN);

	return false;
}

MUTATOR_HOOKFUNCTION(melee_only, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(melee_only, FilterItem)
{SELFPARAM();
	switch (self.items)
	{
		case ITEM_HealthSmall.m_itemid:
		case ITEM_ArmorSmall.m_itemid:
			return false;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(melee_only, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":MeleeOnly");
	return false;
}

MUTATOR_HOOKFUNCTION(melee_only, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Melee Only Arena");
	return false;
}
#endif
