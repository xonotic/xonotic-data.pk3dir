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
		case "blaster_self_damage":
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
	if (!(cvar_type(fullname) & CVAR_TYPEFLAG_EXISTS))
	{
		return PlayerTemplate_GetDefaultFloatValue(variable);
	}
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
	if (!(cvar_type(fullname) & CVAR_TYPEFLAG_EXISTS))
	{
		return PlayerTemplate_GetDefaultStringValue(variable);
	}
	if (cvar_string(fullname) == "default")
	{
		return PlayerTemplate_GetDefaultStringValue(variable);
	}
	return cvar_string(fullname);
}

float PlayerTemplate_GivePlayerItem(entity player, string template,
	string variable)
{
	string value = PlayerTemplate_GetStringValue(template, variable);
	if (value == "default")
	{
		return MUT_ITEMTOUCH_CONTINUE;
	}
	int numfields = tokenize_console(PlayerTemplate_GetStringValue(template,
		variable));
	if (numfields == 0)
	{
		return MUT_ITEMTOUCH_CONTINUE;
	}
	for (int i = 1; i < numfields; ++i)
	{
		switch (i)
		{
			case 1:
			{
				GivePlayerHealth(player, stof(argv(i)));
				break;
			}
			case 2:
			{
				GivePlayerArmor(player, stof(argv(i)));
				break;
			}
			case 3:
			{
				GivePlayerAmmo(player, ammo_shells, stof(argv(i)));
				break;
			}
			case 4:
			{
				GivePlayerAmmo(player, ammo_nails, stof(argv(i)));
				break;
			}
			case 5:
			{
				GivePlayerAmmo(player, ammo_rockets, stof(argv(i)));
				break;
			}
			case 6:
			{
				GivePlayerAmmo(player, ammo_cells, stof(argv(i)));
				break;
			}
		}
	}
	switch (argv(0))
	{
		case "add":
		{
			return MUT_ITEMTOUCH_CONTINUE;
		}
		case "override":
		{
			return MUT_ITEMTOUCH_RETURN;
		}
		default:
		{
			return MUT_ITEMTOUCH_CONTINUE;
		}
	}
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
	if (autocvar_g_instagib == 1)
	{
		return;
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

float PlayerTemplate_ItemTouch(entity player, entity item, string template)
{
	if (template == "default")
	{
		return MUT_ITEMTOUCH_CONTINUE;
	}
	switch (item.classname)
	{
		case "item_health_small":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_small");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthSmall, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_health_medium":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_medium");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthMedium, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_health_big":
		case "item_health_large":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_big");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthBig, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_health_mega":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_mega");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthMega, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_armor_small":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_small");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ArmorSmall, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_armor_medium":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_medium");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ArmorMedium, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_armor_big":
		case "item_armor_large":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_big");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ArmorBig, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_armor_mega":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_mega");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ArmorMega, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_shells":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_shells");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ITEMPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_bullets":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_bullets");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ITEMPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_rockets":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_rockets");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ITEMPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_cells":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_cells");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ITEMPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "weapon_machinegun":
		case "weapon_uzi":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_machinegun");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "weapon_grenadelauncher":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_mortar");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "weapon_electro":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_electro");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "weapon_crylink":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_crylink");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "weapon_nex":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_vortex");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "weapon_hagar":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_hagar");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "weapon_rocketlauncher":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_devastator");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "droppedweapon":
		{
			float result;
			switch (item.weapon)
			{
				case WEP_SHOTGUN.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_shotgun");
					break;
				}
				case WEP_MACHINEGUN.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_machinegun");
					break;
				}
				case WEP_MORTAR.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_mortar");
					break;
				}
				case WEP_ELECTRO.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_electro");
					break;
				}
				case WEP_CRYLINK.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_crylink");
					break;
				}
				case WEP_VORTEX.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_vortex");
					break;
				}
				case WEP_HAGAR.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_hagar");
					break;
				}
				case WEP_DEVASTATOR.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_devastator");
					break;
				}
				case WEP_MINE_LAYER.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_minelayer");
					break;
				}
				case WEP_HLAC.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_hlac");
					break;
				}
				case WEP_RIFLE.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_rifle");
					break;
				}
				case WEP_SEEKER.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_dropped_seeker");
					break;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					delete(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "replacedweapon":
		{
			float result;
			switch (item.weapon)
			{
				case WEP_MINE_LAYER.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_minelayer");
					break;
				}
				case WEP_HLAC.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_hlac");
					break;
				}
				case WEP_RIFLE.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_rifle");
					break;
				}
				case WEP_SEEKER.m_id:
				{
					result = PlayerTemplate_GivePlayerItem(player, template,
						"pickup_weapon_seeker");
					break;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_strength":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_strength");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_Strength, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		case "item_invincible":
		{
			float result = PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_shield");
			switch (result)
			{
				case MUT_ITEMTOUCH_CONTINUE:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case MUT_ITEMTOUCH_RETURN:
				{
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_Shield, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
		default:
		{
			switch (item.netname)
			{
				case "Vaporizer Ammo":
				case "Extra life":
				case "Invisibility":
				case "Speed":
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				default:
				{
					PrintToChatAll(strcat("Unrecognized item, classname: ",
						item.classname, " netname: ", item.netname));
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}
		}
	}
	return MUT_ITEMTOUCH_CONTINUE;
}

float PlayerTemplate_Damage_Calculate(entity attacker, string attackertemplate,
	entity victim, string victimtemplate, float deathtype, float damage)
{
	if (autocvar_g_instagib == 1)
	{
		return damage;
	}
	if ((attacker == victim) && (DEATH_ISWEAPON(deathtype, WEP_BLASTER)) &&
		(PlayerTemplate_GetFloatValue(victimtemplate, "blaster_self_damage") ==
		0))
	{
		return 0;
	}
	damage *= PlayerTemplate_GetFloatValue(attackertemplate, "attack_scale");
	damage /= PlayerTemplate_GetFloatValue(victimtemplate, "defense_scale");
	return damage;
}
