/// \file
/// \brief Source file that contains implementation of the Player Templates
/// mutator.
/// \author Lyberta
/// \copyright GNU GPLv3 or any later version.

const string playertemplate_cvar_prefix = "g_player_template_";

string PlayerTemplate_GetFullCvarName(string template, string variable)
{
	return strcat(playertemplate_cvar_prefix, template, "_", variable);
}

string PlayerTemplate_GetDefaultCvarName(string variable)
{
	switch (variable)
	{
		case "start_health":
		{
			return "g_balance_health_start";
		}
		case "start_armor":
		{
			return "g_balance_armor_start";
		}
		case "unlimited_ammo":
		{
			return "g_use_ammunition";
		}
		case "start_ammo_shells":
		{
			return "g_start_ammo_shells";
		}
		case "start_ammo_bullets":
		{
			return "g_start_ammo_nails";
		}
		case "start_ammo_rockets":
		{
			return "g_start_ammo_rockets";
		}
		case "start_ammo_cells":
		{
			return "g_start_ammo_cells";
		}
		case "start_ammo_plasma":
		{
			return "g_start_ammo_plasma";
		}
		case "start_ammo_fuel":
		{
			return "g_start_ammo_fuel";
		}
		default:
		{
			// TODO: Report error.
			return "";
		}
	}
}

float PlayerTemplate_GetDefaultFloatValue(string variable)
{
	switch (variable)
	{
		case "start_health":
		case "start_armor":
		case "unlimited_ammo":
		case "start_ammo_shells":
		case "start_ammo_bullets":
		case "start_ammo_rockets":
		case "start_ammo_cells":
		case "start_ammo_plasma":
		case "start_ammo_fuel":
		{
			return cvar(PlayerTemplate_GetDefaultCvarName(variable));
		}
		case "default_start_weapons":
		{
			return 1;
		}
		case "num_random_start_weapons":
		{
			return 0;
		}
		case "attack_scale":
		case "defense_scale":
		{
			return 1;
		}
		default:
		{
			// TODO: Report error.
			return 0;
		}
	}
}

string PlayerTemplate_GetDefaultStringValue(string variable)
{
	switch (variable)
	{
		case "start_weapons":
		case "random_start_weapons":
		{
			return "";
		}
		default:
		{
			// TODO: Report error.
			return "";
		}
	}
}

float PlayerTemplate_GetFloatValue(string template, string variable)
{
	if (template == "default")
	{
		return PlayerTemplate_GetDefaultFloatValue(variable);
	}
	string fullname = PlayerTemplate_GetFullCvarName(template, variable);
	if (cvar_string(fullname) == "default")
	{
		return PlayerTemplate_GetDefaultFloatValue(variable);
	}
	return cvar(fullname);
}

string PlayerTemplate_GetStringValue(string template, string variable)
{
	if (template == "default")
	{
		return PlayerTemplate_GetDefaultStringValue(variable);
	}
	string fullname = PlayerTemplate_GetFullCvarName(template, variable);
	if (cvar_string(fullname) == "default")
	{
		return PlayerTemplate_GetDefaultStringValue(variable);
	}
	return cvar_string(fullname);
}

void PlayerTemplate_PlayerSpawn(entity player, string template)
{
	if (template == "default")
	{
		return;
	}
	// Give health, armor and ammo.
	player.health = PlayerTemplate_GetFloatValue(template, "start_health");
	player.armorvalue = PlayerTemplate_GetFloatValue(template, "start_armor");
	if (PlayerTemplate_GetFloatValue(template, "unlimited_ammo"))
	{
		player.items |= IT_UNLIMITED_AMMO;
	}
	else
	{
		player.ammo_shells = PlayerTemplate_GetFloatValue(template,
			"start_ammo_shells");
		player.ammo_nails = PlayerTemplate_GetFloatValue(template,
			"start_ammo_bullets");
		player.ammo_rockets = PlayerTemplate_GetFloatValue(template,
			"start_ammo_rockets");
		player.ammo_cells = PlayerTemplate_GetFloatValue(template,
			"start_ammo_cells");
	}
	// Give weapons.
	if (PlayerTemplate_GetFloatValue(template, "default_start_weapons"))
	{
		FOREACH(Weapons, it != WEP_Null,
		{
			if (it.weaponstart)
			{
				player.weapons |= it.m_wepset;
			}
		});
	}
	int numweapons = tokenize_console(PlayerTemplate_GetStringValue(template,
		"start_weapons"));
	for (int i = 0; i < numweapons; ++i)
	{
		string weapon = argv(i);
		FOREACH(Weapons, it != WEP_Null,
		{
			if (it.netname == weapon)
			{
				player.weapons |= it.m_wepset;
				break;
			}
		});
	}
	// Give random weapons.
	int numrandomweapons = PlayerTemplate_GetFloatValue(template,
		"num_random_start_weapons");
	numweapons = tokenize_console(PlayerTemplate_GetStringValue(template,
		"random_start_weapons"));
	if (warmup_stage)
	{
		// Give all weapons during warmup stage.
		for (int i = 0; i < numweapons; ++i)
		{
			string weapon = argv(i);
			FOREACH(Weapons, it != WEP_Null,
			{
				if (it.netname == weapon)
				{
					player.weapons |= it.m_wepset;
					break;
				}
			});
		}
		return;
	}
	for (int i = 0; i < numrandomweapons; ++i)
	{
		// Finding weapon which player doesn't have.
		WepSet weaponbit = WEPSET(Null);
		int numattempts = 0;
		do
		{
			string weapon = argv(floor(random() * numweapons));
			FOREACH(Weapons, it != WEP_Null,
			{
				if (it.netname == weapon)
				{
					weaponbit = it.m_wepset;
					break;
				}
			});
			++numattempts;
		}
		while ((player.weapons & weaponbit) && (numattempts < 10));
		player.weapons |= weaponbit;
	}
}

float PlayerTemplate_Damage_Calculate(entity attacker, string attackertemplate,
	entity victim, string victimtemplate, float damage)
{
	damage *= PlayerTemplate_GetFloatValue(attackertemplate, "attack_scale");
	damage /= PlayerTemplate_GetFloatValue(victimtemplate, "defense_scale");
	return damage;
}
