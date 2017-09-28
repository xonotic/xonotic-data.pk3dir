/// \file
/// \brief Source file that contains implementation of the random items mutator.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

//============================ Constants ======================================

enum
{
	RANDOM_ITEM_TYPE_HEALTH,
	RANDOM_ITEM_TYPE_ARMOR,
	RANDOM_ITEM_TYPE_AMMO,
	RANDOM_ITEM_TYPE_WEAPON,
	RANDOM_ITEM_TYPE_POWERUP
};

enum
{
	RANDOM_ITEM_SUBTYPE_HEALTH_SMALL,
	RANDOM_ITEM_SUBTYPE_HEALTH_MEDIUM,
	RANDOM_ITEM_SUBTYPE_HEALTH_BIG,
	RANDOM_ITEM_SUBTYPE_HEALTH_MEGA
};

enum
{
	RANDOM_ITEM_SUBTYPE_ARMOR_SMALL,
	RANDOM_ITEM_SUBTYPE_ARMOR_MEDIUM,
	RANDOM_ITEM_SUBTYPE_ARMOR_BIG,
	RANDOM_ITEM_SUBTYPE_ARMOR_MEGA
};

enum
{
	RANDOM_ITEM_SUBTYPE_AMMO_SHELLS,
	RANDOM_ITEM_SUBTYPE_AMMO_BULLETS,
	RANDOM_ITEM_SUBTYPE_AMMO_ROCKETS,
	RANDOM_ITEM_SUBTYPE_AMMO_CELLS
};

enum
{
	RANDOM_ITEM_SUBTYPE_WEAPON_BLASTER,
	RANDOM_ITEM_SUBTYPE_WEAPON_SHOTGUN,
	RANDOM_ITEM_SUBTYPE_WEAPON_MACHINEGUN,
	RANDOM_ITEM_SUBTYPE_WEAPON_MORTAR,
	RANDOM_ITEM_SUBTYPE_WEAPON_ELECTRO,
	RANDOM_ITEM_SUBTYPE_WEAPON_CRYLINK,
	RANDOM_ITEM_SUBTYPE_WEAPON_VORTEX,
	RANDOM_ITEM_SUBTYPE_WEAPON_HAGAR,
	RANDOM_ITEM_SUBTYPE_WEAPON_DEVASTATOR,
	RANDOM_ITEM_SUBTYPE_WEAPON_SHOCKWAVE,
	RANDOM_ITEM_SUBTYPE_WEAPON_ARC,
	RANDOM_ITEM_SUBTYPE_WEAPON_HOOK,
	RANDOM_ITEM_SUBTYPE_WEAPON_TUBA,
	RANDOM_ITEM_SUBTYPE_WEAPON_PORTO,
	RANDOM_ITEM_SUBTYPE_WEAPON_FIREBALL,
	RANDOM_ITEM_SUBTYPE_WEAPON_MINELAYER,
	RANDOM_ITEM_SUBTYPE_WEAPON_HLAC,
	RANDOM_ITEM_SUBTYPE_WEAPON_RIFLE,
	RANDOM_ITEM_SUBTYPE_WEAPON_SEEKER,
	RANDOM_ITEM_SUBTYPE_WEAPON_VAPORIZER
};

enum
{
	RANDOM_ITEM_SUBTYPE_POWERUP_STRENGTH,
	RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD
};

//======================= Global variables ====================================

bool autocvar_g_random_items; ///< Whether to enable random items.

// Replace cvars

/// \brief Whether to randomly replace small health.
bool autocvar_g_random_items_replace_health_small;
/// \brief Whether to randomly replace medium health.
bool autocvar_g_random_items_replace_health_medium;
/// \brief Whether to randomly replace big health.
bool autocvar_g_random_items_replace_health_big;
/// \brief Whether to randomly replace mega health.
bool autocvar_g_random_items_replace_health_mega;

/// \brief Whether to randomly replace small armor.
bool autocvar_g_random_items_replace_armor_small;
/// \brief Whether to randomly replace medium armor.
bool autocvar_g_random_items_replace_armor_medium;
/// \brief Whether to randomly replace big armor.
bool autocvar_g_random_items_replace_armor_big;
/// \brief Whether to randomly replace mega armor.
bool autocvar_g_random_items_replace_armor_mega;

/// \brief Whether to randomly replace shells.
bool autocvar_g_random_items_replace_item_shells;
/// \brief Whether to randomly replace bullets.
bool autocvar_g_random_items_replace_item_bullets;
/// \brief Whether to randomly replace rockets.
bool autocvar_g_random_items_replace_item_rockets;
/// \brief Whether to randomly replace cells.
bool autocvar_g_random_items_replace_item_cells;

/// \brief Whether to randomly replace blaster.
bool autocvar_g_random_items_replace_weapon_blaster;
/// \brief Whether to randomly replace shotgun.
bool autocvar_g_random_items_replace_weapon_shotgun;
/// \brief Whether to randomly replace machinegun.
bool autocvar_g_random_items_replace_weapon_machinegun;
/// \brief Whether to randomly replace mortar.
bool autocvar_g_random_items_replace_weapon_mortar;
/// \brief Whether to randomly replace electro.
bool autocvar_g_random_items_replace_weapon_electro;
/// \brief Whether to randomly replace crylink.
bool autocvar_g_random_items_replace_weapon_crylink;
/// \brief Whether to randomly replace vortex.
bool autocvar_g_random_items_replace_weapon_vortex;
/// \brief Whether to randomly replace hagar.
bool autocvar_g_random_items_replace_weapon_hagar;
/// \brief Whether to randomly replace devastator.
bool autocvar_g_random_items_replace_weapon_devastator;
/// \brief Whether to randomly replace shockwave.
bool autocvar_g_random_items_replace_weapon_shockwave;
/// \brief Whether to randomly replace arc.
bool autocvar_g_random_items_replace_weapon_arc;
/// \brief Whether to randomly replace hook.
bool autocvar_g_random_items_replace_weapon_hook;
/// \brief Whether to randomly replace tuba.
bool autocvar_g_random_items_replace_weapon_tuba;
/// \brief Whether to randomly replace port-o-launch.
bool autocvar_g_random_items_replace_weapon_porto;
/// \brief Whether to randomly replace fireball.
bool autocvar_g_random_items_replace_weapon_fireball;
/// \brief Whether to randomly replace mine layer.
bool autocvar_g_random_items_replace_weapon_minelayer;
/// \brief Whether to randomly replace HLAC.
bool autocvar_g_random_items_replace_weapon_hlac;
/// \brief Whether to randomly replace rifle.
bool autocvar_g_random_items_replace_weapon_rifle;
/// \brief Whether to randomly replace TAG seeker.
bool autocvar_g_random_items_replace_weapon_seeker;
/// \brief Whether to randomly replace vaporizer.
bool autocvar_g_random_items_replace_weapon_vaporizer;

/// \brief Whether to randomly replace strength.
bool autocvar_g_random_items_replace_item_strength;
/// \brief Whether to randomly replace shield.
bool autocvar_g_random_items_replace_item_shield;

// Map probability cvars

/// \brief Probability of random health items spawning in the map.
float autocvar_g_random_map_health_probability;
/// \brief Probability of random armor items spawning in the map.
float autocvar_g_random_map_armor_probability;
/// \brief Probability of random ammo items spawning in the map.
float autocvar_g_random_map_ammo_probability;
/// \brief Probability of random weapons spawning in the map.
float autocvar_g_random_map_weapon_probability;
/// \brief Probability of random powerups spawning in the map.
float autocvar_g_random_map_powerup_probability;

/// \brief Probability of random small health spawning in the map.
float autocvar_g_random_map_health_small_probability;
/// \brief Probability of random medium health spawning in the map.
float autocvar_g_random_map_health_medium_probability;
/// \brief Probability of random big health spawning in the map.
float autocvar_g_random_map_health_big_probability;
/// \brief Probability of random mega health spawning in the map.
float autocvar_g_random_map_health_mega_probability;

/// \brief Probability of random small armor spawning in the map.
float autocvar_g_random_map_armor_small_probability;
/// \brief Probability of random medium armor.spawning in the map.
float autocvar_g_random_map_armor_medium_probability;
/// \brief Probability of random big armor spawning in the map.
float autocvar_g_random_map_armor_big_probability;
/// \brief Probability of random mega armor spawning in the map.
float autocvar_g_random_map_armor_mega_probability;

/// \brief Probability of random shells spawning in the map.
float autocvar_g_random_map_ammo_shells_probability;
/// \brief Probability of random bullets spawning in the map.
float autocvar_g_random_map_ammo_bullets_probability;
/// \brief Probability of random rockets spawning in the map.
float autocvar_g_random_map_ammo_rockets_probability;
/// \brief Probability of random cells spawning in the map.
float autocvar_g_random_map_ammo_cells_probability;

/// \brief Probability of random blaster spawning in the map.
float autocvar_g_random_map_weapon_blaster_probability;
/// \brief Probability of random shotgun spawning in the map.
float autocvar_g_random_map_weapon_shotgun_probability;
/// \brief Probability of random machinegun spawning in the map.
float autocvar_g_random_map_weapon_machinegun_probability;
/// \brief Probability of random mortar spawning in the map.
float autocvar_g_random_map_weapon_mortar_probability;
/// \brief Probability of random electro spawning in the map.
float autocvar_g_random_map_weapon_electro_probability;
/// \brief Probability of random crylink spawning in the map.
float autocvar_g_random_map_weapon_crylink_probability;
/// \brief Probability of random vortex spawning in the map.
float autocvar_g_random_map_weapon_vortex_probability;
/// \brief Probability of random hagar spawning in the map.
float autocvar_g_random_map_weapon_hagar_probability;
/// \brief Probability of random devastator spawning in the map.
float autocvar_g_random_map_weapon_devastator_probability;
/// \brief Probability of random shockwave spawning in the map.
float autocvar_g_random_map_weapon_shockwave_probability;
/// \brief Probability of random arc spawning in the map.
float autocvar_g_random_map_weapon_arc_probability;
/// \brief Probability of random hook spawning in the map.
float autocvar_g_random_map_weapon_hook_probability;
/// \brief Probability of random tuba spawning in the map.
float autocvar_g_random_map_weapon_tuba_probability;
/// \brief Probability of random port-o-launch spawning in the map.
float autocvar_g_random_map_weapon_porto_probability;
/// \brief Probability of random fireball spawning in the map.
float autocvar_g_random_map_weapon_fireball_probability;
/// \brief Probability of random mine layer spawning in the map.
float autocvar_g_random_map_weapon_minelayer_probability;
/// \brief Probability of random HLAC spawning in the map.
float autocvar_g_random_map_weapon_hlac_probability;
/// \brief Probability of random rifle spawning in the map.
float autocvar_g_random_map_weapon_rifle_probability;
/// \brief Probability of random TAG seeker spawning in the map.
float autocvar_g_random_map_weapon_seeker_probability;
/// \brief Probability of random vaporizer spawning in the map.
float autocvar_g_random_map_weapon_vaporizer_probability;

/// \brief Probability of random strength spawning in the map.
float autocvar_g_random_map_strength_probability;
/// \brief Probability of random shield spawning in the map.
float autocvar_g_random_map_shield_probability;

// Loot

float autocvar_g_random_loot_min; ///< Minimum amount of loot items.
float autocvar_g_random_loot_max; ///< Maximum amount of loot items.
float autocvar_g_random_loot_time; ///< Amount of time the loot will stay.

/// \brief Holds whether random item is spawning. Used to prevent infinite
/// recursion.
bool random_items_is_spawning = false;

//========================= Free functions ====================================

bool RandomItems_ShouldReplaceItem(entity item)
{
	switch (item.classname)
	{
		case "item_health_small":
		{
			return autocvar_g_random_items_replace_health_small;
		}
		case "item_health_medium":
		{
			return autocvar_g_random_items_replace_health_medium;
		}
		case "item_health_big":
		case "item_health_large":
		{
			return autocvar_g_random_items_replace_health_big;
		}
		case "item_health_mega":
		{
			return autocvar_g_random_items_replace_health_mega;
		}
		case "item_armor_small":
		{
			return autocvar_g_random_items_replace_armor_small;
		}
		case "item_armor_medium":
		{
			return autocvar_g_random_items_replace_armor_medium;
		}
		case "item_armor_big":
		case "item_armor_large":
		{
			return autocvar_g_random_items_replace_armor_big;
		}
		case "item_armor_mega":
		{
			return autocvar_g_random_items_replace_armor_mega;
		}
		case "item_shells":
		{
			return autocvar_g_random_items_replace_item_shells;
		}
		case "item_bullets":
		{
			return autocvar_g_random_items_replace_item_bullets;
		}
		case "item_rockets":
		{
			return autocvar_g_random_items_replace_item_rockets;
		}
		case "item_cells":
		{
			return autocvar_g_random_items_replace_item_cells;
		}
		case "weapon_blaster":
		{
			return autocvar_g_random_items_replace_weapon_blaster;
		}
		case "weapon_shotgun":
		{
			return autocvar_g_random_items_replace_weapon_shotgun;
		}
		case "weapon_machinegun":
		case "weapon_uzi":
		{
			return autocvar_g_random_items_replace_weapon_machinegun;
		}
		case "weapon_grenadelauncher":
		{
			return autocvar_g_random_items_replace_weapon_mortar;
		}
		case "weapon_electro":
		{
			return autocvar_g_random_items_replace_weapon_electro;
		}
		case "weapon_crylink":
		{
			return autocvar_g_random_items_replace_weapon_crylink;
		}
		case "weapon_nex":
		{
			return autocvar_g_random_items_replace_weapon_vortex;
		}
		case "weapon_hagar":
		{
			return autocvar_g_random_items_replace_weapon_hagar;
		}
		case "weapon_rocketlauncher":
		{
			return autocvar_g_random_items_replace_weapon_devastator;
		}
		case "weapon_shockwave":
		{
			return autocvar_g_random_items_replace_weapon_shockwave;
		}
		case "weapon_arc":
		{
			return autocvar_g_random_items_replace_weapon_arc;
		}
		case "weapon_hook":
		{
			return autocvar_g_random_items_replace_weapon_hook;
		}
		case "weapon_tuba":
		{
			return autocvar_g_random_items_replace_weapon_tuba;
		}
		case "weapon_porto":
		{
			return autocvar_g_random_items_replace_weapon_porto;
		}
		case "weapon_fireball":
		{
			return autocvar_g_random_items_replace_weapon_fireball;
		}
		case "weapon_minelayer":
		{
			return autocvar_g_random_items_replace_weapon_minelayer;
		}
		case "weapon_hlac":
		{
			return autocvar_g_random_items_replace_weapon_hlac;
		}
		case "weapon_rifle":
		{
			return autocvar_g_random_items_replace_weapon_rifle;
		}
		case "weapon_seeker":
		{
			return autocvar_g_random_items_replace_weapon_seeker;
		}
		case "weapon_vaporizer":
		{
			return autocvar_g_random_items_replace_weapon_vaporizer;
		}
		case "item_strength":
		{
			return autocvar_g_random_items_replace_item_strength;
		}
		case "item_invincible":
		{
			return autocvar_g_random_items_replace_item_shield;
		}
		case "replacedweapon":
		{
			switch (item.weapon)
			{
				case WEP_MINE_LAYER.m_id:
				{
					return autocvar_g_random_items_replace_weapon_minelayer;
				}
				case WEP_HLAC.m_id:
				{
					return autocvar_g_random_items_replace_weapon_hlac;
				}
				case WEP_RIFLE.m_id:
				{
					return autocvar_g_random_items_replace_weapon_rifle;
				}
				case WEP_SEEKER.m_id:
				{
					return autocvar_g_random_items_replace_weapon_seeker;
				}
				default:
				{
					return false;
				}
			}
		}
		default:
		{
			return false;
		}
	}
}

entity RandomItems_SpawnItem(vector position)
{
	random_items_is_spawning = true;
	RandomSelection_Init();
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_HEALTH,
		autocvar_g_random_map_health_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_ARMOR,
		autocvar_g_random_map_armor_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_AMMO,
		autocvar_g_random_map_ammo_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_WEAPON,
		autocvar_g_random_map_weapon_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_POWERUP,
		autocvar_g_random_map_powerup_probability, 1);
	int item_type = RandomSelection_chosen_float;
	entity item = NULL;
	switch (item_type)
	{
		case RANDOM_ITEM_TYPE_HEALTH:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_SMALL,
				autocvar_g_random_map_health_small_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_MEDIUM,
				autocvar_g_random_map_health_medium_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_BIG,
				autocvar_g_random_map_health_big_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_MEGA,
				autocvar_g_random_map_health_mega_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_HEALTH_SMALL:
				{
					item = new(item_health_small);
					item.spawnfunc_checked = true;
					spawnfunc_item_health_small(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_MEDIUM:
				{
					item = new(item_health_medium);
					item.spawnfunc_checked = true;
					spawnfunc_item_health_medium(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_BIG:
				{
					item = new(item_health_big);
					item.spawnfunc_checked = true;
					spawnfunc_item_health_big(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_MEGA:
				{
					item = new(item_health_mega);
					item.spawnfunc_checked = true;
					spawnfunc_item_health_mega(item);
					break;
				}
			}
			break;
		}
		case RANDOM_ITEM_TYPE_ARMOR:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_SMALL,
				autocvar_g_random_map_armor_small_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_MEDIUM,
				autocvar_g_random_map_armor_medium_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_BIG,
				autocvar_g_random_map_armor_big_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_MEGA,
				autocvar_g_random_map_armor_mega_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_ARMOR_SMALL:
				{
					item = new(item_armor_small);
					item.spawnfunc_checked = true;
					spawnfunc_item_armor_small(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_MEDIUM:
				{
					item = new(item_armor_medium);
					item.spawnfunc_checked = true;
					spawnfunc_item_armor_medium(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_BIG:
				{
					item = new(item_armor_big);
					item.spawnfunc_checked = true;
					spawnfunc_item_armor_big(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_MEGA:
				{
					item = new(item_armor_mega);
					item.spawnfunc_checked = true;
					spawnfunc_item_armor_mega(item);
					break;
				}
			}
			break;
		}
		case RANDOM_ITEM_TYPE_AMMO:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_AMMO_SHELLS,
				autocvar_g_random_map_ammo_shells_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_AMMO_BULLETS,
				autocvar_g_random_map_ammo_bullets_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_AMMO_ROCKETS,
				autocvar_g_random_map_ammo_rockets_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_AMMO_CELLS,
				autocvar_g_random_map_ammo_cells_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_AMMO_SHELLS:
				{
					item = new(item_shells);
					item.spawnfunc_checked = true;
					spawnfunc_item_shells(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_AMMO_BULLETS:
				{
					item = new(item_bullets);
					item.spawnfunc_checked = true;
					spawnfunc_item_bullets(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_AMMO_ROCKETS:
				{
					item = new(item_rockets);
					item.spawnfunc_checked = true;
					spawnfunc_item_rockets(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_AMMO_CELLS:
				{
					item = new(item_cells);
					item.spawnfunc_checked = true;
					spawnfunc_item_cells(item);
					break;
				}
			}
			break;
		}
		case RANDOM_ITEM_TYPE_WEAPON:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_BLASTER,
				autocvar_g_random_map_weapon_blaster_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SHOTGUN,
				autocvar_g_random_map_weapon_shotgun_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MACHINEGUN,
				autocvar_g_random_map_weapon_machinegun_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MORTAR,
				autocvar_g_random_map_weapon_mortar_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_ELECTRO,
				autocvar_g_random_map_weapon_electro_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_CRYLINK,
				autocvar_g_random_map_weapon_crylink_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_VORTEX,
				autocvar_g_random_map_weapon_vortex_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HAGAR,
				autocvar_g_random_map_weapon_hagar_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_DEVASTATOR,
				autocvar_g_random_map_weapon_devastator_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SHOCKWAVE,
				autocvar_g_random_map_weapon_shockwave_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_ARC,
				autocvar_g_random_map_weapon_arc_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HOOK,
				autocvar_g_random_map_weapon_hook_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_TUBA,
				autocvar_g_random_map_weapon_tuba_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_PORTO,
				autocvar_g_random_map_weapon_porto_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_FIREBALL,
				autocvar_g_random_map_weapon_fireball_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MINELAYER,
				autocvar_g_random_map_weapon_minelayer_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HLAC,
				autocvar_g_random_map_weapon_hlac_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_RIFLE,
				autocvar_g_random_map_weapon_rifle_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SEEKER,
				autocvar_g_random_map_weapon_seeker_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_VAPORIZER,
				autocvar_g_random_map_weapon_vaporizer_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_WEAPON_BLASTER:
				{
					item = new(weapon_blaster);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_blaster(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SHOTGUN:
				{
					item = new(weapon_shotgun);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_shotgun(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MACHINEGUN:
				{
					item = new(weapon_machinegun);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_machinegun(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MORTAR:
				{
					item = new(weapon_grenadelauncher);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_grenadelauncher(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_ELECTRO:
				{
					item = new(weapon_electro);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_electro(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_CRYLINK:
				{
					item = new(weapon_crylink);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_crylink(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_VORTEX:
				{
					item = new(weapon_nex);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_nex(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HAGAR:
				{
					item = new(weapon_hagar);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_hagar(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_DEVASTATOR:
				{
					item = new(weapon_rocketlauncher);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_rocketlauncher(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SHOCKWAVE:
				{
					item = new(weapon_shockwave);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_shockwave(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_ARC:
				{
					item = new(weapon_arc);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_arc(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HOOK:
				{
					item = new(weapon_hook);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_hook(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_TUBA:
				{
					item = new(weapon_tuba);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_tuba(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_PORTO:
				{
					item = new(weapon_porto);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_porto(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_FIREBALL:
				{
					item = new(weapon_fireball);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_fireball(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MINELAYER:
				{
					item = new(weapon_minelayer);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_minelayer(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HLAC:
				{
					item = new(weapon_hlac);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_hlac(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_RIFLE:
				{
					item = new(weapon_rifle);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_rifle(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SEEKER:
				{
					item = new(weapon_seeker);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_seeker(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_VAPORIZER:
				{
					item = new(weapon_vaporizer);
					item.spawnfunc_checked = true;
					spawnfunc_weapon_vaporizer(item);
					break;
				}
			}
			break;
		}
		case RANDOM_ITEM_TYPE_POWERUP:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_STRENGTH,
				autocvar_g_random_map_strength_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD,
				autocvar_g_random_map_shield_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_POWERUP_STRENGTH:
				{
					item = new(item_strength);
					item.spawnfunc_checked = true;
					spawnfunc_item_strength(item);
					break;
				}
				case RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD:
				{
					item = new(item_invincible);
					item.spawnfunc_checked = true;
					spawnfunc_item_invincible(item);
					break;
				}
			}
			break;
		}
	}
	random_items_is_spawning = false;
	if (wasfreed(item))
	{
		return NULL;
	}
	setorigin(item, position);
	return item;
}

//============================= Hooks ========================================

REGISTER_MUTATOR(random_items, autocvar_g_random_items);

MUTATOR_HOOKFUNCTION(random_items, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":random_items");
}

MUTATOR_HOOKFUNCTION(random_items, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Random items");
}

/// \brief Hook that is called when an item is about to spawn.
MUTATOR_HOOKFUNCTION(random_items, FilterItem)
{
	//PrintToChatAll("FilterItem");
	if (random_items_is_spawning == true)
	{
		return false;
	}
	entity item = M_ARGV(0, entity);
	if (Item_IsLoot(item))
	{
		return false;
	}
	if (!RandomItems_ShouldReplaceItem(item))
	{
		return false;
	}
	if (RandomItems_SpawnItem(item.origin) == NULL)
	{
		return false;
	}
	return true;
}

/// \brief Hook that is called after the player has touched an item.
MUTATOR_HOOKFUNCTION(random_items, ItemTouched, CBC_ORDER_LAST)
{
	//PrintToChatAll("ItemTouched");
	entity item = M_ARGV(0, entity);
	if (Item_IsLoot(item))
	{
		return;
	}
	if (!RandomItems_ShouldReplaceItem(item))
	{
		return;
	}
	entity new_item = RandomItems_SpawnItem(item.origin);
	if (new_item == NULL)
	{
		return;
	}
	Item_ScheduleRespawn(new_item);
	delete(item);
}

/// \brief Hook which is called when the player dies.
MUTATOR_HOOKFUNCTION(random_items, PlayerDies)
{
	//PrintToChatAll("PlayerDies");
	entity victim = M_ARGV(2, entity);
	int num_loot_items = floor(autocvar_g_random_loot_min + random() *
		autocvar_g_random_loot_max);
	for (int item_index = 0; item_index < num_loot_items; ++item_index)
	{
		entity loot = RandomItems_SpawnItem(victim.origin);
		if (loot == NULL)
		{
			continue;
		}
		Item_SetLoot(loot, true);
		set_movetype(loot, MOVETYPE_TOSS);
        loot.gravity = 1;
        loot.reset = SUB_Remove;
        setorigin(loot, victim.origin + '0 0 32');
        loot.velocity = '0 0 200' + randomvec() * 500;
        SUB_SetFade(loot, time + autocvar_g_random_loot_time, 1);
	}
}
