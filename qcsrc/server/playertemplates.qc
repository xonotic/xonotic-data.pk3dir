/// \file
/// \brief Source file that contains implementation of the player templates
/// system.
/// \author Lyberta
/// \copyright GNU GPLv3 or any later version.

#include <common/items/item.qh>
#include "autocvars.qh"
#include "resources.qh"
#include "mutators/events.qh"
#include <common/mutators/mutator/overkill/hmg.qh>
#include <common/mutators/mutator/overkill/rpc.qh>

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
		case "random_start_weapons_count":
		{
			return "g_random_start_weapons_count";
		}
		case "random_start_weapons":
		{
			return "g_random_start_weapons";
		}
		case "random_start_shells":
		{
			return "g_random_start_shells";
		}
		case "random_start_bullets":
		{
			return "g_random_start_bullets";
		}
		case "random_start_rockets":
		{
			return "g_random_start_rockets";
		}
		case "random_start_cells":
		{
			return "g_random_start_cells";
		}
		case "random_start_plasma":
		{
			return "g_random_start_plasma";
		}
		case "start_ammo_vaporizer_cells":
		{
			return "g_instagib_ammo_start";
		}
		case "drop_weapons":
		{
			return "g_weapon_throwable";
		}
		case "health_regen_factor":
		{
			return "g_balance_health_regen";
		}
		case "health_regen_linear":
		{
			return "g_balance_health_regenlinear";
		}
		case "health_rot_factor":
		{
			return "g_balance_health_rot";
		}
		case "health_rot_linear":
		{
			return "g_balance_health_rotlinear";
		}
		case "health_regen_stable":
		{
			return "g_balance_health_regenstable";
		}
		case "health_rot_stable":
		{
			return "g_balance_health_rotstable";
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
		case "start_ammo_shells":
		case "start_ammo_bullets":
		case "start_ammo_rockets":
		case "start_ammo_cells":
		case "start_ammo_plasma":
		case "start_ammo_fuel":
		case "random_start_weapons_count":
		case "random_start_shells":
		case "random_start_bullets":
		case "random_start_rockets":
		case "random_start_cells":
		case "random_start_plasma":
		case "start_ammo_vaporizer_cells":
		case "drop_weapons":
		case "health_regen_factor":
		case "health_regen_linear":
		case "health_rot_factor":
		case "health_rot_linear":
		case "health_regen_stable":
		case "health_rot_stable":
		{
			return cvar(PlayerTemplate_GetDefaultCvarName(variable));
		}
		case "unlimited_ammo":
		{
			return !autocvar_g_use_ammunition;
		}
		case "default_start_weapons":
		{
			return 1;
		}
		case "start_extra_lives":
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
		case "random_start_weapons":
		{
			cvar_string(PlayerTemplate_GetDefaultCvarName(variable));
		}
		case "start_weapons":
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
				GiveResource(player, RESOURCE_HEALTH, stof(argv(i)));
				break;
			}
			case 2:
			{
				GiveResource(player, RESOURCE_ARMOR, stof(argv(i)));
				break;
			}
			case 3:
			{
				GiveResource(player, RESOURCE_SHELLS, stof(argv(i)));
				break;
			}
			case 4:
			{
				GiveResource(player, RESOURCE_BULLETS, stof(argv(i)));
				break;
			}
			case 5:
			{
				GiveResource(player, RESOURCE_ROCKETS, stof(argv(i)));
				break;
			}
			case 6:
			{
				GiveResource(player, RESOURCE_CELLS, stof(argv(i)));
				break;
			}
			case 7:
			{
				GiveResource(player, RESOURCE_PLASMA, stof(argv(i)));
				break;
			}
			case 8:
			{
				GiveResource(player, RESOURCE_FUEL, stof(argv(i)));
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
			return MUT_ITEMTOUCH_PICKUP;
		}
		default:
		{
			return MUT_ITEMTOUCH_CONTINUE;
		}
	}
}

// =========================== Hook handlers =================================

void PlayerTemplateHook_PlayerSpawn(entity player, string template)
{
	if (template == "default")
	{
		return;
	}
	if (autocvar_g_instagib)
	{
		SetResourceAmount(player, RESOURCE_ARMOR,
			PlayerTemplate_GetFloatValue(template, "start_extra_lives"));
		SetResourceAmount(player, RESOURCE_CELLS,
			PlayerTemplate_GetFloatValue(template,
			"start_ammo_vaporizer_cells"));
		if (PlayerTemplate_GetFloatValue(template, "unlimited_ammo"))
		{
			player.items |= IT_UNLIMITED_AMMO;
		}
		return;
	}
	// Give health, armor and ammo.
	SetResourceAmount(player, RESOURCE_HEALTH,
		PlayerTemplate_GetFloatValue(template, "start_health"));
	SetResourceAmount(player, RESOURCE_ARMOR, 
		PlayerTemplate_GetFloatValue(template, "start_armor"));
	if (PlayerTemplate_GetFloatValue(template, "unlimited_ammo"))
	{
		player.items |= IT_UNLIMITED_AMMO;
	}
	else
	{
		SetResourceAmount(player, RESOURCE_SHELLS,
			PlayerTemplate_GetFloatValue(template, "start_ammo_shells"));
		SetResourceAmount(player, RESOURCE_BULLETS,
			PlayerTemplate_GetFloatValue(template, "start_ammo_bullets"));
		SetResourceAmount(player, RESOURCE_ROCKETS,
			PlayerTemplate_GetFloatValue(template, "start_ammo_rockets"));
		SetResourceAmount(player, RESOURCE_CELLS,
			PlayerTemplate_GetFloatValue(template, "start_ammo_cells"));
		SetResourceAmount(player, RESOURCE_PLASMA,
			PlayerTemplate_GetFloatValue(template, "start_ammo_plasma"));
		SetResourceAmount(player, RESOURCE_FUEL,
			PlayerTemplate_GetFloatValue(template, "start_ammo_fuel"));
	}
	// Give weapons.
	player.weapons = WEPSET(Null);
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
	if (!warmup_stage)
	{
		entity ammo_entity = spawn();
		SetResourceAmount(ammo_entity, RESOURCE_SHELLS,
			PlayerTemplate_GetFloatValue(template, "random_start_shells"));
		SetResourceAmount(ammo_entity, RESOURCE_BULLETS,
			PlayerTemplate_GetFloatValue(template, "random_start_bullets"));
		SetResourceAmount(ammo_entity, RESOURCE_ROCKETS,
			PlayerTemplate_GetFloatValue(template, "random_start_rockets"));
		SetResourceAmount(ammo_entity, RESOURCE_CELLS,
			PlayerTemplate_GetFloatValue(template, "random_start_cells"));
		SetResourceAmount(ammo_entity, RESOURCE_PLASMA,
			PlayerTemplate_GetFloatValue(template, "random_start_plasma"));
		GiveRandomWeapons(player, PlayerTemplate_GetFloatValue(template,
			"random_start_weapons_count"),
			PlayerTemplate_GetStringValue(template, "random_start_weapons"),
			ammo_entity);
		remove(ammo_entity);
		return;
	}
	// Give random weapons.
	numweapons = tokenize_console(PlayerTemplate_GetStringValue(template,
		"random_start_weapons"));
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
}

bool PlayerTemplateHook_ForbidThrowCurrentWeapon(string template)
{
	return !PlayerTemplate_GetFloatValue(template, "drop_weapons");
}

float PlayerTemplateHook_PlayerRegen(entity player, string template)
{
	if (template == "default")
	{
		return false;
	}
	M_ARGV(5, float) = PlayerTemplate_GetFloatValue(template,
		"health_regen_factor");
	M_ARGV(6, float) = PlayerTemplate_GetFloatValue(template,
		"health_regen_linear");
	M_ARGV(7, float) = PlayerTemplate_GetFloatValue(template,
		"health_rot_factor");
	M_ARGV(8, float) = PlayerTemplate_GetFloatValue(template,
		"health_rot_linear");
	M_ARGV(9, float) = PlayerTemplate_GetFloatValue(template,
		"health_regen_stable");
	M_ARGV(10, float) = PlayerTemplate_GetFloatValue(template,
		"health_rot_stable");
	return false;
}

float PlayerTemplateHook_ItemTouch(entity player, entity item, string template)
{
	if (template == "default")
	{
		return MUT_ITEMTOUCH_CONTINUE;
	}
	switch (item.classname)
	{
		case "item_health_small":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_small");
		}
		case "item_health_medium":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_medium");
		}
		case "item_health_big":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_big");
		}
		case "item_health_mega":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_health_mega");
		}
		case "item_armor_small":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_small");
		}
		case "item_armor_medium":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_medium");
		}
		case "item_armor_big":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_big");
		}
		case "item_armor_mega":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_armor_mega");
		}
		case "item_shells":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_shells");
		}
		case "item_bullets":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_bullets");
		}
		case "item_rockets":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_rockets");
		}
		case "item_cells":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_cells");
		}
		case "item_plasma":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_plasma");
		}
		case "item_fuel":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_fuel");
		}
		case "weapon_blaster":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_blaster");
		}
		case "weapon_shotgun":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_shotgun");
		}
		case "weapon_machinegun":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_machinegun");
		}
		case "weapon_mortar":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_mortar");
		}
		case "weapon_electro":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_electro");
		}
		case "weapon_crylink":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_crylink");
		}
		case "weapon_vortex":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_vortex");
		}
		case "weapon_hagar":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_hagar");
		}
		case "weapon_devastator":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_devastator");
		}
		case "weapon_shockwave":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_shockwave");
		}
		case "weapon_arc":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_arc");
		}
		case "weapon_hook":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_hook");
		}
		case "weapon_tuba":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_tuba");
		}
		case "weapon_porto":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_porto");
		}
		case "weapon_fireball":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_fireball");
		}
		case "weapon_minelayer":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_minelayer");
		}
		case "weapon_hlac":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_hlac");
		}
		case "weapon_rifle":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_rifle");
		}
		case "weapon_seeker":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_seeker");
		}
		case "weapon_vaporizer":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_vaporizer");
		}
		case "weapon_hmg":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_hmg");
		}
		case "weapon_rpc":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_weapon_rpc");
		}
		case "item_strength":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_strength");
		}
		case "item_shield":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_shield");
		}
		case "item_fuel_regen":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_fuel_regen");
		}
		case "item_jetpack":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_jetpack");
		}
		case "item_vaporizer_cells":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_vaporizer_cells");
		}
		case "item_invisibility":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_invisibility");
		}
		case "item_extralife":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_extralife");
		}
		case "item_speed":
		{
			return PlayerTemplate_GivePlayerItem(player, template,
				"pickup_item_speed");
		}
		default:
		{
			switch (item.netname)
			{
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

float PlayerTemplateHook_Damage_Calculate(entity attacker,
	string attackertemplate, entity victim, string victimtemplate,
	float deathtype, float damage)
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

void PlayerTemplateHook_PlayerDies(entity player, string template)
{
	if (template == "default")
	{
		return;
	}
	if (PlayerTemplate_GetFloatValue(template, "drop_weapons"))
	{
		return;
	}
	player.weapons = WEPSET(Null);
}
