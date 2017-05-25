/// \file
/// \brief Source file that contains implementation of the Player Templates
/// mutator.
/// \author Lyberta
/// \copyright GNU GPLv3 or any later version.

const string playertemplate_cvar_prefix = "g_player_template_";

float PlayerTemplate_GetFloatCvar(string template, string variable)
{
	return cvar(strcat(playertemplate_cvar_prefix, template, "_", variable));
}

string PlayerTemplate_GetStringCvar(string template, string variable)
{
	return cvar_string(strcat(playertemplate_cvar_prefix, template, "_",
		variable));
}

void PlayerTemplate_PlayerSpawn(entity player, string template)
{
	// Give health, armor and ammo.
	player.health = PlayerTemplate_GetFloatCvar(template, "start_health");
	player.armorvalue = PlayerTemplate_GetFloatCvar(template, "start_armor");
	if (PlayerTemplate_GetFloatCvar(template, "unlimited_ammo"))
	{
		player.items |= IT_UNLIMITED_AMMO;
	}
	else
	{
		player.ammo_shells = PlayerTemplate_GetFloatCvar(template,
			"start_ammo_shells");
		player.ammo_nails = PlayerTemplate_GetFloatCvar(template,
			"start_ammo_bullets");
		player.ammo_rockets = PlayerTemplate_GetFloatCvar(template,
			"start_ammo_rockets");
		player.ammo_cells = PlayerTemplate_GetFloatCvar(template,
			"start_ammo_cells");
	}
	// Give weapons.
	if (PlayerTemplate_GetFloatCvar(template, "default_start_weapons"))
	{
		FOREACH(Weapons, it != WEP_Null,
		{
			if (it.weaponstart)
			{
				player.weapons |= it.m_wepset;
			}
		});
	}
	int numweapons = tokenize_console(PlayerTemplate_GetStringCvar(template,
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
	int numrandomweapons = PlayerTemplate_GetFloatCvar(template,
		"num_random_start_weapons");
	numweapons = tokenize_console(PlayerTemplate_GetStringCvar(template,
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
	damage *= PlayerTemplate_GetFloatCvar(attackertemplate, "attack_scale");
	damage /= PlayerTemplate_GetFloatCvar(victimtemplate, "defense_scale");
	return damage;
}
