//#include <server/resources.qh>

string autocvar_g_sprint = "0"; ///< Whether to enable sprint.
float autocvar_g_sprint_speed_multiplier; ///< Speed multiplier of sprinting.
bool autocvar_g_sprint_in_air; ///< Whether to increase air acceleration too.
/// \brief Amount of fuel that sprinting costs per second.
float autocvar_g_sprint_cost;

.bool m_is_sprinting; ///< Whether player is sprinting.

REGISTER_MUTATOR(sprint, expr_evaluate(autocvar_g_sprint));

MUTATOR_HOOKFUNCTION(sprint, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":sprint");
}

MUTATOR_HOOKFUNCTION(sprint, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Sprint");
}

MUTATOR_HOOKFUNCTION(sprint, BuildGameplayTipsString)
{
    M_ARGV(0, string) = strcat(M_ARGV(0, string), "\n\n^3Sprint^8 is enabled, press the dodge button to sprint\n");
}

MUTATOR_HOOKFUNCTION(sprint, SetStartItems)
{
	if (autocvar_g_sprint_cost > 0)
	{
		start_items |= ITEM_JetpackRegen.m_itemid;
		start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
		warmup_start_ammo_fuel = start_ammo_fuel;
	}
}

MUTATOR_HOOKFUNCTION(sprint, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);
	if (PHYS_INPUT_BUTTON_DODGE(player))
	{
		player.m_is_sprinting = true;
	}
	else
	{
		player.m_is_sprinting = false;
	}
}

MUTATOR_HOOKFUNCTION(sprint, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	if (!player.m_is_sprinting)
	{
		return;
	}
	float cost = 0;
	float fuel = 0;
	if (autocvar_g_sprint_cost > 0)
	{
		cost = autocvar_g_sprint_cost * frametime;
		fuel = GetResourceAmount(player, RESOURCE_FUEL);
		if (fuel < cost)
		{
			player.m_is_sprinting = false;
			return;
		}
		
	}
	if (!IS_ONGROUND(player) && !autocvar_g_sprint_in_air)
	{
		return;
	}
	STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_sprint_speed_multiplier;
	if (autocvar_g_sprint_cost <= 0)
	{
		return;
	}
	if ((PHYS_INPUT_MOVEVALUES(player).x == 0) &&
		(PHYS_INPUT_MOVEVALUES(player).y == 0))
	{
		return;
	}
	SetResourceAmount(player, RESOURCE_FUEL, fuel - cost);
}
