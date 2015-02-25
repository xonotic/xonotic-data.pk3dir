void sha_SetCvars()
{
	cvar_settemp("g_balance_shotgun_primary_damage", cvar_string("g_shotgunarena_shotgun_primary_damage"));
	cvar_settemp("g_balance_shotgun_primary_force", cvar_string("g_shotgunarena_shotgun_primary_force"));
	cvar_settemp("g_balance_shotgun_primary_refire", cvar_string("g_shotgunarena_shotgun_primary_refire"));
	cvar_settemp("g_balance_shotgun_primary_spread", cvar_string("g_shotgunarena_shotgun_primary_spread"));
	cvar_settemp("g_balance_shotgun_reload_ammo", cvar_string("g_shotgunarena_shotgun_reload_ammo"));
	cvar_settemp("g_balance_shotgun_reload_time", cvar_string("g_shotgunarena_shotgun_reload_time"));
	cvar_settemp("g_balance_shotgun_secondary_damage", cvar_string("g_shotgunarena_shotgun_secondary_damage"));
	cvar_settemp("g_balance_shotgun_secondary_force", cvar_string("g_shotgunarena_shotgun_secondary_force"));
	cvar_settemp("g_balance_shotgun_secondary_melee_time", cvar_string("g_shotgunarena_shotgun_secondary_melee_time"));
	cvar_settemp("g_balance_shotgun_secondary_refire", cvar_string("g_shotgunarena_shotgun_secondary_refire"));
}

MUTATOR_HOOKFUNCTION(sha_FilterItem)
{
	switch (self.items)
	{
		case IT_5HP:
		case IT_ARMOR_SHARD:
			return false;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(sha_StartItems)
{
	start_items |= IT_UNLIMITED_WEAPON_AMMO;
	//start_ammo_shells = warmup_start_ammo_shells = 100;
	warmup_start_weapons = start_weapons = WEPSET_SHOTGUN;

	return false;
}

MUTATOR_HOOKFUNCTION(sha_ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(sha_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":SHA");
	return false;
}

MUTATOR_HOOKFUNCTION(sha_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Shotgun Arena");
	return false;
}

MUTATOR_HOOKFUNCTION(sha_SetModname)
{
	modname = "Shotgun Arena";
	return true;
}

MUTATOR_DEFINITION(mutator_shotgunarena)
{
	MUTATOR_HOOK(FilterItem, sha_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, sha_StartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, sha_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, sha_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, sha_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetModname, sha_SetModname, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		sha_SetCvars();
	}

	MUTATOR_ONREMOVE
	{
		print("This cannot be removed at runtime\n");
		return -1;
	}

	return false;
}
