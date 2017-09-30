/// \file
/// \brief Source file that contains implementation of the random items mutator.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

//============================ Constants ======================================

enum
{
	RANDOM_ITEM_TYPE_HEALTH,
	RANDOM_ITEM_TYPE_ARMOR,
	RANDOM_ITEM_TYPE_RESOURCE,
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
	RANDOM_ITEM_SUBTYPE_RESOURCE_SHELLS,
	RANDOM_ITEM_SUBTYPE_RESOURCE_BULLETS,
	RANDOM_ITEM_SUBTYPE_RESOURCE_ROCKETS,
	RANDOM_ITEM_SUBTYPE_RESOURCE_CELLS,
	RANDOM_ITEM_SUBTYPE_RESOURCE_PLASMA,
	RANDOM_ITEM_SUBTYPE_RESOURCE_FUEL,
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
	RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD,
	RANDOM_ITEM_SUBTYPE_POWERUP_FUEL_REGEN,
	RANDOM_ITEM_SUBTYPE_POWERUP_JETPACK
};

enum
{
	RANDOM_ITEM_SUBTYPE_INSTAGIB_VAPORIZER_CELLS,
	RANDOM_ITEM_SUBTYPE_INSTAGIB_INVISIBILITY,
	RANDOM_ITEM_SUBTYPE_INSTAGIB_EXTRA_LIFE,
	RANDOM_ITEM_SUBTYPE_INSTAGIB_SPEED
};

//======================= Global variables ====================================

bool autocvar_g_random_items; ///< Whether to enable random items.

// Replace cvars

/// \brief Classnames to replace small health with.
string autocvar_g_random_items_replace_health_small;
/// \brief Classnames to replace medium health with.
string autocvar_g_random_items_replace_health_medium;
/// \brief Classnames to replace big health with.
string autocvar_g_random_items_replace_health_big;
/// \brief Classnames to replace mega health with.
string autocvar_g_random_items_replace_health_mega;

/// \brief Classnames to replace small armor with.
string autocvar_g_random_items_replace_armor_small;
/// \brief Classnames to replace medium armor with.
string autocvar_g_random_items_replace_armor_medium;
/// \brief Classnames to replace big armor with.
string autocvar_g_random_items_replace_armor_big;
/// \brief Classnames to replace mega armor with.
string autocvar_g_random_items_replace_armor_mega;

/// \brief Classnames to replace shells with.
string autocvar_g_random_items_replace_item_shells;
/// \brief Classnames to replace bullets with.
string autocvar_g_random_items_replace_item_bullets;
/// \brief Classnames to replace rockets with.
string autocvar_g_random_items_replace_item_rockets;
/// \brief Classnames to replace cells with.
string autocvar_g_random_items_replace_item_cells;
/// \brief Classnames to replace plasma with.
string autocvar_g_random_items_replace_item_plasma;
/// \brief Classnames to replace fuel with.
string autocvar_g_random_items_replace_item_fuel;

/// \brief Classnames to replace blaster with.
string autocvar_g_random_items_replace_weapon_blaster;
/// \brief Classnames to replace shotgun with.
string autocvar_g_random_items_replace_weapon_shotgun;
/// \brief Classnames to replace machinegun with.
string autocvar_g_random_items_replace_weapon_machinegun;
/// \brief Classnames to replace mortar with.
string autocvar_g_random_items_replace_weapon_mortar;
/// \brief Classnames to replace electro with.
string autocvar_g_random_items_replace_weapon_electro;
/// \brief Classnames to replace crylink with.
string autocvar_g_random_items_replace_weapon_crylink;
/// \brief Classnames to replace vortex with.
string autocvar_g_random_items_replace_weapon_vortex;
/// \brief Classnames to replace hagar with.
string autocvar_g_random_items_replace_weapon_hagar;
/// \brief Classnames to replace devastator with.
string autocvar_g_random_items_replace_weapon_devastator;
/// \brief Classnames to replace shockwave with.
string autocvar_g_random_items_replace_weapon_shockwave;
/// \brief Classnames to replace arc with.
string autocvar_g_random_items_replace_weapon_arc;
/// \brief Classnames to replace hook with.
string autocvar_g_random_items_replace_weapon_hook;
/// \brief Classnames to replace tuba with.
string autocvar_g_random_items_replace_weapon_tuba;
/// \brief Classnames to replace port-o-launch with.
string autocvar_g_random_items_replace_weapon_porto;
/// \brief Classnames to replace fireball with.
string autocvar_g_random_items_replace_weapon_fireball;
/// \brief Classnames to replace mine layer with.
string autocvar_g_random_items_replace_weapon_minelayer;
/// \brief Classnames to replace HLAC with.
string autocvar_g_random_items_replace_weapon_hlac;
/// \brief Classnames to replace rifle with.
string autocvar_g_random_items_replace_weapon_rifle;
/// \brief Classnames to replace TAG seeker with.
string autocvar_g_random_items_replace_weapon_seeker;
/// \brief Classnames to replace vaporizer with.
string autocvar_g_random_items_replace_weapon_vaporizer;

/// \brief Classnames to replace strength with.
string autocvar_g_random_items_replace_item_strength;
/// \brief Classnames to replace shield with.
string autocvar_g_random_items_replace_item_shield;
/// \brief Classnames to replace fuel regeneration with.
string autocvar_g_random_items_replace_item_fuel_regen;
/// \brief Classnames to replace jetpack with.
string autocvar_g_random_items_replace_item_jetpack;

/// \brief Classnames to replace vaporizer cells with.
string autocvar_g_random_items_replace_item_vaporizer_cells;
/// \brief Classnames to replace invisibility with.
string autocvar_g_random_items_replace_item_invisibility;
/// \brief Classnames to replace extra life with.
string autocvar_g_random_items_replace_item_extralife;
/// \brief Classnames to replace speed with.
string autocvar_g_random_items_replace_item_speed;

// Map probability cvars

/// \brief Probability of random health items spawning in the map.
float autocvar_g_random_items_health_probability;
/// \brief Probability of random armor items spawning in the map.
float autocvar_g_random_items_armor_probability;
/// \brief Probability of random resource items spawning in the map.
float autocvar_g_random_items_resource_probability;
/// \brief Probability of random weapons spawning in the map.
float autocvar_g_random_items_weapon_probability;
/// \brief Probability of random powerups spawning in the map.
float autocvar_g_random_items_powerup_probability;

/// \brief Probability of random small health spawning in the map.
float autocvar_g_random_items_health_small_probability;
/// \brief Probability of random medium health spawning in the map.
float autocvar_g_random_items_health_medium_probability;
/// \brief Probability of random big health spawning in the map.
float autocvar_g_random_items_health_big_probability;
/// \brief Probability of random mega health spawning in the map.
float autocvar_g_random_items_health_mega_probability;

/// \brief Probability of random small armor spawning in the map.
float autocvar_g_random_items_armor_small_probability;
/// \brief Probability of random medium armor.spawning in the map.
float autocvar_g_random_items_armor_medium_probability;
/// \brief Probability of random big armor spawning in the map.
float autocvar_g_random_items_armor_big_probability;
/// \brief Probability of random mega armor spawning in the map.
float autocvar_g_random_items_armor_mega_probability;

/// \brief Probability of random shells spawning in the map.
float autocvar_g_random_items_resource_shells_probability;
/// \brief Probability of random bullets spawning in the map.
float autocvar_g_random_items_resource_bullets_probability;
/// \brief Probability of random rockets spawning in the map.
float autocvar_g_random_items_resource_rockets_probability;
/// \brief Probability of random cells spawning in the map.
float autocvar_g_random_items_resource_cells_probability;
/// \brief Probability of random plasma spawning in the map.
float autocvar_g_random_items_resource_plasma_probability;
/// \brief Probability of random fuel spawning in the map.
float autocvar_g_random_items_resource_fuel_probability;

/// \brief Probability of random blaster spawning in the map.
float autocvar_g_random_items_weapon_blaster_probability;
/// \brief Probability of random shotgun spawning in the map.
float autocvar_g_random_items_weapon_shotgun_probability;
/// \brief Probability of random machinegun spawning in the map.
float autocvar_g_random_items_weapon_machinegun_probability;
/// \brief Probability of random mortar spawning in the map.
float autocvar_g_random_items_weapon_mortar_probability;
/// \brief Probability of random electro spawning in the map.
float autocvar_g_random_items_weapon_electro_probability;
/// \brief Probability of random crylink spawning in the map.
float autocvar_g_random_items_weapon_crylink_probability;
/// \brief Probability of random vortex spawning in the map.
float autocvar_g_random_items_weapon_vortex_probability;
/// \brief Probability of random hagar spawning in the map.
float autocvar_g_random_items_weapon_hagar_probability;
/// \brief Probability of random devastator spawning in the map.
float autocvar_g_random_items_weapon_devastator_probability;
/// \brief Probability of random shockwave spawning in the map.
float autocvar_g_random_items_weapon_shockwave_probability;
/// \brief Probability of random arc spawning in the map.
float autocvar_g_random_items_weapon_arc_probability;
/// \brief Probability of random hook spawning in the map.
float autocvar_g_random_items_weapon_hook_probability;
/// \brief Probability of random tuba spawning in the map.
float autocvar_g_random_items_weapon_tuba_probability;
/// \brief Probability of random port-o-launch spawning in the map.
float autocvar_g_random_items_weapon_porto_probability;
/// \brief Probability of random fireball spawning in the map.
float autocvar_g_random_items_weapon_fireball_probability;
/// \brief Probability of random mine layer spawning in the map.
float autocvar_g_random_items_weapon_minelayer_probability;
/// \brief Probability of random HLAC spawning in the map.
float autocvar_g_random_items_weapon_hlac_probability;
/// \brief Probability of random rifle spawning in the map.
float autocvar_g_random_items_weapon_rifle_probability;
/// \brief Probability of random TAG seeker spawning in the map.
float autocvar_g_random_items_weapon_seeker_probability;
/// \brief Probability of random vaporizer spawning in the map.
float autocvar_g_random_items_weapon_vaporizer_probability;

/// \brief Probability of random strength spawning in the map.
float autocvar_g_random_items_strength_probability;
/// \brief Probability of random shield spawning in the map.
float autocvar_g_random_items_shield_probability;
/// \brief Probability of random fuel regeneration spawning in the map.
float autocvar_g_random_items_fuel_regen_probability;
/// \brief Probability of random jetpack spawning in the map.
float autocvar_g_random_items_jetpack_probability;

/// \brief Probability of random vaporizer cells spawning in the map.
float autocvar_g_random_items_vaporizer_cells_probability;
/// \brief Probability of random invisibility spawning in the map.
float autocvar_g_random_items_invisibility_probability;
/// \brief Probability of random extra life spawning in the map.
float autocvar_g_random_items_extralife_probability;
/// \brief Probability of random speed spawning in the map.
float autocvar_g_random_items_speed_probability;

// Loot

bool autocvar_g_random_loot; ///< Whether to enable random loot.

float autocvar_g_random_loot_min; ///< Minimum amount of loot items.
float autocvar_g_random_loot_max; ///< Maximum amount of loot items.
float autocvar_g_random_loot_time; ///< Amount of time the loot will stay.
float autocvar_g_random_loot_spread; ///< How far can loot be thrown.

// Loot probability cvars

/// \brief Probability of random health items spawning as loot.
float autocvar_g_random_loot_health_probability;
/// \brief Probability of random armor items spawning as loot.
float autocvar_g_random_loot_armor_probability;
/// \brief Probability of random resource items spawning as loot.
float autocvar_g_random_loot_resource_probability;
/// \brief Probability of random weapons spawning as loot.
float autocvar_g_random_loot_weapon_probability;
/// \brief Probability of random powerups spawning as loot.
float autocvar_g_random_loot_powerup_probability;

/// \brief Probability of random small health spawning as loot.
float autocvar_g_random_loot_health_small_probability;
/// \brief Probability of random medium health spawning as loot.
float autocvar_g_random_loot_health_medium_probability;
/// \brief Probability of random big health spawning as loot.
float autocvar_g_random_loot_health_big_probability;
/// \brief Probability of random mega health spawning as loot.
float autocvar_g_random_loot_health_mega_probability;

/// \brief Probability of random small armor spawning as loot.
float autocvar_g_random_loot_armor_small_probability;
/// \brief Probability of random medium armor.spawning as loot.
float autocvar_g_random_loot_armor_medium_probability;
/// \brief Probability of random big armor spawning as loot.
float autocvar_g_random_loot_armor_big_probability;
/// \brief Probability of random mega armor spawning as loot.
float autocvar_g_random_loot_armor_mega_probability;

/// \brief Probability of random shells spawning as loot.
float autocvar_g_random_loot_resource_shells_probability;
/// \brief Probability of random bullets spawning as loot.
float autocvar_g_random_loot_resource_bullets_probability;
/// \brief Probability of random rockets spawning as loot.
float autocvar_g_random_loot_resource_rockets_probability;
/// \brief Probability of random cells spawning as loot.
float autocvar_g_random_loot_resource_cells_probability;
/// \brief Probability of random plasma spawning as loot.
float autocvar_g_random_loot_resource_plasma_probability;
/// \brief Probability of random fuel spawning as loot.
float autocvar_g_random_loot_resource_fuel_probability;

/// \brief Probability of random blaster spawning as loot.
float autocvar_g_random_loot_weapon_blaster_probability;
/// \brief Probability of random shotgun spawning as loot.
float autocvar_g_random_loot_weapon_shotgun_probability;
/// \brief Probability of random machinegun spawning as loot.
float autocvar_g_random_loot_weapon_machinegun_probability;
/// \brief Probability of random mortar spawning as loot.
float autocvar_g_random_loot_weapon_mortar_probability;
/// \brief Probability of random electro spawning as loot.
float autocvar_g_random_loot_weapon_electro_probability;
/// \brief Probability of random crylink spawning as loot.
float autocvar_g_random_loot_weapon_crylink_probability;
/// \brief Probability of random vortex spawning as loot.
float autocvar_g_random_loot_weapon_vortex_probability;
/// \brief Probability of random hagar spawning as loot.
float autocvar_g_random_loot_weapon_hagar_probability;
/// \brief Probability of random devastator spawning as loot.
float autocvar_g_random_loot_weapon_devastator_probability;
/// \brief Probability of random shockwave spawning as loot.
float autocvar_g_random_loot_weapon_shockwave_probability;
/// \brief Probability of random arc spawning as loot.
float autocvar_g_random_loot_weapon_arc_probability;
/// \brief Probability of random hook spawning as loot.
float autocvar_g_random_loot_weapon_hook_probability;
/// \brief Probability of random tuba spawning as loot.
float autocvar_g_random_loot_weapon_tuba_probability;
/// \brief Probability of random port-o-launch spawning as loot.
float autocvar_g_random_loot_weapon_porto_probability;
/// \brief Probability of random fireball spawning as loot.
float autocvar_g_random_loot_weapon_fireball_probability;
/// \brief Probability of random mine layer spawning as loot.
float autocvar_g_random_loot_weapon_minelayer_probability;
/// \brief Probability of random HLAC spawning as loot.
float autocvar_g_random_loot_weapon_hlac_probability;
/// \brief Probability of random rifle spawning as loot.
float autocvar_g_random_loot_weapon_rifle_probability;
/// \brief Probability of random TAG seeker spawning as loot.
float autocvar_g_random_loot_weapon_seeker_probability;
/// \brief Probability of random vaporizer spawning as loot.
float autocvar_g_random_loot_weapon_vaporizer_probability;

/// \brief Probability of random strength spawning as loot.
float autocvar_g_random_loot_strength_probability;
/// \brief Probability of random shield spawning as loot.
float autocvar_g_random_loot_shield_probability;
/// \brief Probability of random fuel regeneration spawning as loot.
float autocvar_g_random_loot_fuel_regen_probability;
/// \brief Probability of random jetpack spawning as loot.
float autocvar_g_random_loot_jetpack_probability;

/// \brief Probability of random vaporizer cells spawning as loot.
float autocvar_g_random_loot_vaporizer_cells_probability;
/// \brief Probability of random invisibility spawning as loot.
float autocvar_g_random_loot_invisibility_probability;
/// \brief Probability of random extra life spawning as loot.
float autocvar_g_random_loot_extralife_probability;
/// \brief Probability of random speed spawning as loot.
float autocvar_g_random_loot_speed_probability;

/// \brief Holds whether random item is spawning. Used to prevent infinite
/// recursion.
bool random_items_is_spawning = false;

//========================= Free functions ====================================

/// \brief Returns list of classnames to replace a map item with.
/// \param[in] item Item to inspect.
/// \return List of classnames to replace a map item with.
string RandomItems_GetItemReplacementClassNames(entity item)
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
		case "item_plasma":
		{
			return autocvar_g_random_items_replace_item_plasma;
		}
		case "item_fuel":
		{
			return autocvar_g_random_items_replace_item_fuel;
		}
		case "weapon_blaster":
		case "weapon_laser":
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
		case "weapon_mortar":
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
		case "weapon_vortex":
		case "weapon_nex":
		{
			return autocvar_g_random_items_replace_weapon_vortex;
		}
		case "weapon_hagar":
		{
			return autocvar_g_random_items_replace_weapon_hagar;
		}
		case "weapon_devastator":
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
		case "weapon_campingrifle":
		case "weapon_sniperrifle":
		{
			return autocvar_g_random_items_replace_weapon_rifle;
		}
		case "weapon_seeker":
		{
			return autocvar_g_random_items_replace_weapon_seeker;
		}
		case "weapon_vaporizer":
		case "weapon_minstanex":
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
		case "item_fuel_regen":
		{
			return autocvar_g_random_items_replace_item_fuel_regen;
		}
		case "item_jetpack":
		{
			return autocvar_g_random_items_replace_item_jetpack;
		}
		case "item_vaporizer_cells":
		{
			return autocvar_g_random_items_replace_item_vaporizer_cells;
		}
		case "item_invisibility":
		{
			return autocvar_g_random_items_replace_item_invisibility;
		}
		case "item_extralife":
		{
			return autocvar_g_random_items_replace_item_extralife;
		}
		case "item_speed":
		{
			return autocvar_g_random_items_replace_item_speed;
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
					return "";
				}
			}
		}
		default:
		{
			return "";
		}
	}
}

/// \brief Returns a random instagib classname of the map item.
/// \return Random instagib classname of the map item.
string RandomItems_GetRandomInstagibMapItemClassName()
{
	RandomSelection_Init();
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_VAPORIZER_CELLS,
		autocvar_g_random_items_vaporizer_cells_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_INVISIBILITY,
		autocvar_g_random_items_invisibility_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_EXTRA_LIFE,
		autocvar_g_random_items_extralife_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_SPEED,
		autocvar_g_random_items_speed_probability, 1);
	int item_type = RandomSelection_chosen_float;
	switch (item_type)
	{
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_VAPORIZER_CELLS:
		{
			return "item_vaporizer_cells";
		}
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_INVISIBILITY:
		{
			return "item_invisibility";
		}
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_EXTRA_LIFE:
		{
			return "item_extralife";
		}
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_SPEED:
		{
			return "item_speed";
		}
	}
	return "";
}

/// \brief Returns a random classname of the map item.
/// \return Random classname of the map item.
string RandomItems_GetRandomMapItemClassName()
{
	if (autocvar_g_instagib)
	{
		return RandomItems_GetRandomInstagibMapItemClassName();
	}
	RandomSelection_Init();
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_HEALTH,
		autocvar_g_random_items_health_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_ARMOR,
		autocvar_g_random_items_armor_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_RESOURCE,
		autocvar_g_random_items_resource_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_WEAPON,
		autocvar_g_random_items_weapon_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_POWERUP,
		autocvar_g_random_items_powerup_probability, 1);
	int item_type = RandomSelection_chosen_float;
	switch (item_type)
	{
		case RANDOM_ITEM_TYPE_HEALTH:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_SMALL,
				autocvar_g_random_items_health_small_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_MEDIUM,
				autocvar_g_random_items_health_medium_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_BIG,
				autocvar_g_random_items_health_big_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_MEGA,
				autocvar_g_random_items_health_mega_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_HEALTH_SMALL:
				{
					return "item_health_small";
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_MEDIUM:
				{
					return "item_health_medium";
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_BIG:
				{
					return "item_health_big";
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_MEGA:
				{
					return "item_health_mega";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_ARMOR:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_SMALL,
				autocvar_g_random_items_armor_small_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_MEDIUM,
				autocvar_g_random_items_armor_medium_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_BIG,
				autocvar_g_random_items_armor_big_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_MEGA,
				autocvar_g_random_items_armor_mega_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_ARMOR_SMALL:
				{
					return "item_armor_small";
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_MEDIUM:
				{
					return "item_armor_medium";
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_BIG:
				{
					return "item_armor_big";
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_MEGA:
				{
					return "item_armor_mega";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_RESOURCE:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_SHELLS,
				autocvar_g_random_items_resource_shells_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_BULLETS,
				autocvar_g_random_items_resource_bullets_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_ROCKETS,
				autocvar_g_random_items_resource_rockets_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_CELLS,
				autocvar_g_random_items_resource_cells_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_PLASMA,
				autocvar_g_random_items_resource_plasma_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_FUEL,
				autocvar_g_random_items_resource_fuel_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_RESOURCE_SHELLS:
				{
					return "item_shells";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_BULLETS:
				{
					return "item_bullets";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_ROCKETS:
				{
					return "item_rockets";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_CELLS:
				{
					return "item_cells";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_PLASMA:
				{
					return "item_plasma";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_FUEL:
				{
					return "item_fuel";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_WEAPON:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_BLASTER,
				autocvar_g_random_items_weapon_blaster_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SHOTGUN,
				autocvar_g_random_items_weapon_shotgun_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MACHINEGUN,
				autocvar_g_random_items_weapon_machinegun_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MORTAR,
				autocvar_g_random_items_weapon_mortar_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_ELECTRO,
				autocvar_g_random_items_weapon_electro_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_CRYLINK,
				autocvar_g_random_items_weapon_crylink_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_VORTEX,
				autocvar_g_random_items_weapon_vortex_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HAGAR,
				autocvar_g_random_items_weapon_hagar_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_DEVASTATOR,
				autocvar_g_random_items_weapon_devastator_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SHOCKWAVE,
				autocvar_g_random_items_weapon_shockwave_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_ARC,
				autocvar_g_random_items_weapon_arc_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HOOK,
				autocvar_g_random_items_weapon_hook_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_TUBA,
				autocvar_g_random_items_weapon_tuba_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_PORTO,
				autocvar_g_random_items_weapon_porto_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_FIREBALL,
				autocvar_g_random_items_weapon_fireball_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MINELAYER,
				autocvar_g_random_items_weapon_minelayer_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HLAC,
				autocvar_g_random_items_weapon_hlac_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_RIFLE,
				autocvar_g_random_items_weapon_rifle_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SEEKER,
				autocvar_g_random_items_weapon_seeker_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_VAPORIZER,
				autocvar_g_random_items_weapon_vaporizer_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_WEAPON_BLASTER:
				{
					return "weapon_blaster";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SHOTGUN:
				{
					return "weapon_shotgun";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MACHINEGUN:
				{
					return "weapon_machinegun";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MORTAR:
				{
					return "weapon_mortar";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_ELECTRO:
				{
					return "weapon_electro";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_CRYLINK:
				{
					return "weapon_crylink";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_VORTEX:
				{
					return "weapon_vortex";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HAGAR:
				{
					return "weapon_hagar";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_DEVASTATOR:
				{
					return "weapon_devastator";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SHOCKWAVE:
				{
					return "weapon_shockwave";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_ARC:
				{
					return "weapon_arc";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HOOK:
				{
					return "weapon_hook";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_TUBA:
				{
					return "weapon_tuba";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_PORTO:
				{
					return "weapon_porto";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_FIREBALL:
				{
					return "weapon_fireball";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MINELAYER:
				{
					return "weapon_minelayer";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HLAC:
				{
					return "weapon_hlac";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_RIFLE:
				{
					return "weapon_rifle";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SEEKER:
				{
					return "weapon_seeker";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_VAPORIZER:
				{
					return "weapon_vaporizer";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_POWERUP:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_STRENGTH,
				autocvar_g_random_items_strength_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD,
				autocvar_g_random_items_shield_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_FUEL_REGEN,
				autocvar_g_random_items_fuel_regen_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_JETPACK,
				autocvar_g_random_items_jetpack_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_POWERUP_STRENGTH:
				{
					return "item_strength";
				}
				case RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD:
				{
					return "item_invincible";
				}
				case RANDOM_ITEM_SUBTYPE_POWERUP_FUEL_REGEN:
				{
					return "item_fuel_regen";
				}
				case RANDOM_ITEM_SUBTYPE_POWERUP_JETPACK:
				{
					return "item_jetpack";
				}
			}
			return "";
		}
	}
	return "";
}

/// \brief Replaces a map item.
/// \param[in] item Item to replace.
/// \return Spawned item on success, NULL otherwise.
entity RandomItems_ReplaceMapItem(entity item)
{
	//PrintToChatAll(strcat("Replacing ", item.classname));
	string new_classnames = RandomItems_GetItemReplacementClassNames(item);
	if (new_classnames == "")
	{
		return NULL;
	}
	string new_classname;
	if (new_classnames == "random")
	{
		new_classname = RandomItems_GetRandomMapItemClassName();
		if (new_classname == "")
		{
			return NULL;
		}
	}
	else
	{
		int num_new_classnames = tokenize_console(new_classnames);
		if (num_new_classnames == 1)
		{
			new_classname = new_classnames;
		}
		else
		{
			int classname_index = floor(random() * num_new_classnames);
			new_classname = argv(classname_index);
		}
	}
	//PrintToChatAll(strcat("Replacing with ", new_classname));
	if (new_classname == item.classname)
	{
		return NULL;
	}
	random_items_is_spawning = true;
	entity new_item = Item_Create(strzone(new_classname), item.origin);
	random_items_is_spawning = false;
	return new_item;
}

/// \brief Returns a random instagib classname of the loot item.
/// \return Random instagib classname of the loot item.
string RandomItems_GetRandomInstagibLootItemClassName()
{
	RandomSelection_Init();
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_VAPORIZER_CELLS,
		autocvar_g_random_loot_vaporizer_cells_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_INVISIBILITY,
		autocvar_g_random_loot_invisibility_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_EXTRA_LIFE,
		autocvar_g_random_loot_extralife_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_INSTAGIB_SPEED,
		autocvar_g_random_loot_speed_probability, 1);
	int item_type = RandomSelection_chosen_float;
	switch (item_type)
	{
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_VAPORIZER_CELLS:
		{
			return "item_vaporizer_cells";
		}
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_INVISIBILITY:
		{
			return "item_invisibility";
		}
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_EXTRA_LIFE:
		{
			return "item_extralife";
		}
		case RANDOM_ITEM_SUBTYPE_INSTAGIB_SPEED:
		{
			return "item_speed";
		}
	}
	return "";
}


/// \brief Returns a random classname of the loot item.
/// \return Random classname of the loot item.
string RandomItems_GetRandomLootItemClassName()
{
	if (autocvar_g_instagib)
	{
		return RandomItems_GetRandomInstagibLootItemClassName();
	}
	RandomSelection_Init();
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_HEALTH,
		autocvar_g_random_loot_health_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_ARMOR,
		autocvar_g_random_loot_armor_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_RESOURCE,
		autocvar_g_random_loot_resource_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_WEAPON,
		autocvar_g_random_loot_weapon_probability, 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_POWERUP,
		autocvar_g_random_loot_powerup_probability, 1);
	int item_type = RandomSelection_chosen_float;
	switch (item_type)
	{
		case RANDOM_ITEM_TYPE_HEALTH:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_SMALL,
				autocvar_g_random_loot_health_small_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_MEDIUM,
				autocvar_g_random_loot_health_medium_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_BIG,
				autocvar_g_random_loot_health_big_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_HEALTH_MEGA,
				autocvar_g_random_loot_health_mega_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_HEALTH_SMALL:
				{
					return "item_health_small";
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_MEDIUM:
				{
					return "item_health_medium";
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_BIG:
				{
					return "item_health_big";
				}
				case RANDOM_ITEM_SUBTYPE_HEALTH_MEGA:
				{
					return "item_health_mega";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_ARMOR:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_SMALL,
				autocvar_g_random_loot_armor_small_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_MEDIUM,
				autocvar_g_random_loot_armor_medium_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_BIG,
				autocvar_g_random_loot_armor_big_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_ARMOR_MEGA,
				autocvar_g_random_loot_armor_mega_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_ARMOR_SMALL:
				{
					return "item_armor_small";
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_MEDIUM:
				{
					return "item_armor_medium";
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_BIG:
				{
					return "item_armor_big";
				}
				case RANDOM_ITEM_SUBTYPE_ARMOR_MEGA:
				{
					return "item_armor_mega";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_RESOURCE:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_SHELLS,
				autocvar_g_random_loot_resource_shells_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_BULLETS,
				autocvar_g_random_loot_resource_bullets_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_ROCKETS,
				autocvar_g_random_loot_resource_rockets_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_CELLS,
				autocvar_g_random_loot_resource_cells_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_PLASMA,
				autocvar_g_random_loot_resource_plasma_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_RESOURCE_FUEL,
				autocvar_g_random_loot_resource_fuel_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_RESOURCE_SHELLS:
				{
					return "item_shells";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_BULLETS:
				{
					return "item_bullets";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_ROCKETS:
				{
					return "item_rockets";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_CELLS:
				{
					return "item_cells";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_PLASMA:
				{
					return "item_plasma";
				}
				case RANDOM_ITEM_SUBTYPE_RESOURCE_FUEL:
				{
					return "item_fuel";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_WEAPON:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_BLASTER,
				autocvar_g_random_loot_weapon_blaster_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SHOTGUN,
				autocvar_g_random_loot_weapon_shotgun_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MACHINEGUN,
				autocvar_g_random_loot_weapon_machinegun_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MORTAR,
				autocvar_g_random_loot_weapon_mortar_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_ELECTRO,
				autocvar_g_random_loot_weapon_electro_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_CRYLINK,
				autocvar_g_random_loot_weapon_crylink_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_VORTEX,
				autocvar_g_random_loot_weapon_vortex_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HAGAR,
				autocvar_g_random_loot_weapon_hagar_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_DEVASTATOR,
				autocvar_g_random_loot_weapon_devastator_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SHOCKWAVE,
				autocvar_g_random_loot_weapon_shockwave_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_ARC,
				autocvar_g_random_loot_weapon_arc_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HOOK,
				autocvar_g_random_loot_weapon_hook_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_TUBA,
				autocvar_g_random_loot_weapon_tuba_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_PORTO,
				autocvar_g_random_loot_weapon_porto_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_FIREBALL,
				autocvar_g_random_loot_weapon_fireball_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_MINELAYER,
				autocvar_g_random_loot_weapon_minelayer_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_HLAC,
				autocvar_g_random_loot_weapon_hlac_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_RIFLE,
				autocvar_g_random_loot_weapon_rifle_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_SEEKER,
				autocvar_g_random_loot_weapon_seeker_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_WEAPON_VAPORIZER,
				autocvar_g_random_loot_weapon_vaporizer_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_WEAPON_BLASTER:
				{
					return "weapon_blaster";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SHOTGUN:
				{
					return "weapon_shotgun";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MACHINEGUN:
				{
					return "weapon_machinegun";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MORTAR:
				{
					return "weapon_mortar";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_ELECTRO:
				{
					return "weapon_electro";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_CRYLINK:
				{
					return "weapon_crylink";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_VORTEX:
				{
					return "weapon_vortex";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HAGAR:
				{
					return "weapon_hagar";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_DEVASTATOR:
				{
					return "weapon_devastator";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SHOCKWAVE:
				{
					return "weapon_shockwave";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_ARC:
				{
					return "weapon_arc";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HOOK:
				{
					return "weapon_hook";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_TUBA:
				{
					return "weapon_tuba";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_PORTO:
				{
					return "weapon_porto";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_FIREBALL:
				{
					return "weapon_fireball";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_MINELAYER:
				{
					return "weapon_minelayer";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_HLAC:
				{
					return "weapon_hlac";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_RIFLE:
				{
					return "weapon_rifle";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_SEEKER:
				{
					return "weapon_seeker";
				}
				case RANDOM_ITEM_SUBTYPE_WEAPON_VAPORIZER:
				{
					return "weapon_vaporizer";
				}
			}
			return "";
		}
		case RANDOM_ITEM_TYPE_POWERUP:
		{
			RandomSelection_Init();
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_STRENGTH,
				autocvar_g_random_loot_strength_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD,
				autocvar_g_random_loot_shield_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_FUEL_REGEN,
				autocvar_g_random_loot_fuel_regen_probability, 1);
			RandomSelection_AddFloat(RANDOM_ITEM_SUBTYPE_POWERUP_JETPACK,
				autocvar_g_random_loot_jetpack_probability, 1);
			item_type = RandomSelection_chosen_float;
			switch (item_type)
			{
				case RANDOM_ITEM_SUBTYPE_POWERUP_STRENGTH:
				{
					return "item_strength";
				}
				case RANDOM_ITEM_SUBTYPE_POWERUP_SHIELD:
				{
					return "item_invincible";
				}
				case RANDOM_ITEM_SUBTYPE_POWERUP_FUEL_REGEN:
				{
					return "item_fuel_regen";
				}
				case RANDOM_ITEM_SUBTYPE_POWERUP_JETPACK:
				{
					return "item_jetpack";
				}
			}
			return "";
		}
	}
	return "";
}

/// \brief Spawns a random loot item.
/// \param[in] position Position of the item.
/// \return No return.
void RandomItems_SpawnLootItem(vector position)
{
	string class_name = RandomItems_GetRandomLootItemClassName();
	if (class_name == "")
	{
		return;
	}
	vector spread = '0 0 0';
	spread.z = autocvar_g_random_loot_spread / 2;
	spread += randomvec() * autocvar_g_random_loot_spread;
	random_items_is_spawning = true;
	Item_CreateLoot(class_name, position, spread, autocvar_g_random_loot_time);
	random_items_is_spawning = false;
}

//============================= Hooks ========================================

REGISTER_MUTATOR(random_items, (autocvar_g_random_items ||
	autocvar_g_random_loot));

MUTATOR_HOOKFUNCTION(random_items, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":random_items");
}

MUTATOR_HOOKFUNCTION(random_items, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Random items");
}

/// \brief Hook that is called when an item is about to spawn.
MUTATOR_HOOKFUNCTION(random_items, FilterItem, CBC_ORDER_LAST)
{
	//PrintToChatAll("FilterItem");
	if (!autocvar_g_random_items)
	{
		return false;
	}
	if (random_items_is_spawning == true)
	{
		return false;
	}
	entity item = M_ARGV(0, entity);
	if (Item_IsLoot(item))
	{
		return false;
	}
	if (RandomItems_ReplaceMapItem(item) == NULL)
	{
		return false;
	}
	return true;
}

/// \brief Hook that is called after the player has touched an item.
MUTATOR_HOOKFUNCTION(random_items, ItemTouched, CBC_ORDER_LAST)
{
	//PrintToChatAll("ItemTouched");
	if (!autocvar_g_random_items)
	{
		return;
	}
	entity item = M_ARGV(0, entity);
	if (Item_IsLoot(item))
	{
		return;
	}
	entity new_item = RandomItems_ReplaceMapItem(item);
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
	if (!autocvar_g_random_loot)
	{
		return;
	}
	entity victim = M_ARGV(2, entity);
	vector loot_position = victim.origin + '0 0 32';
	int num_loot_items = floor(autocvar_g_random_loot_min + random() *
		autocvar_g_random_loot_max);
	for (int item_index = 0; item_index < num_loot_items; ++item_index)
	{
		RandomItems_SpawnLootItem(loot_position);
	}
}
