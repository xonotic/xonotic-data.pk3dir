#include "sv_random_items.qh"

/// \file
/// \brief Source file that contains implementation of the random items mutator.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

//============================ Constants ======================================

//======================= Global variables ====================================

// Replace cvars

/// \brief Classnames to replace %s with.
/// string autocvar_g_random_items_replace_%s;

// Map probability cvars

/// \brief Probability of random %s spawning in the map.
/// float autocvar_g_random_items_%s_probability;

/// \brief Probability of random %s spawning in the map during overkill.
/// float autocvar_g_random_items_overkill_%s_probability;

// Loot

float autocvar_g_random_loot_min; ///< Minimum amount of loot items.
float autocvar_g_random_loot_max; ///< Maximum amount of loot items.
float autocvar_g_random_loot_time; ///< Amount of time the loot will stay.
float autocvar_g_random_loot_spread; ///< How far can loot be thrown.

// Loot probability cvars

/// \brief Probability of random %s spawning as loot.
/// float autocvar_g_random_loot_%s_probability;

/// \brief Probability of random %s spawning as loot during overkill.
/// float autocvar_g_random_loot_overkill_%s_probability;

/// \brief Holds whether random item is spawning. Used to prevent infinite
/// recursion.
bool random_items_is_spawning = false;

//====================== Forward declarations =================================

/// \brief Returns a random classname of the item with specific property.
/// \param[in] prefix Prefix of the cvars that hold probabilities.
/// \return Random classname of the item.
string RandomItems_GetRandomItemClassNameWithProperty(string prefix,
	.bool item_property);

//=========================== Public API ======================================

string RandomItems_GetRandomItemClassName(string prefix)
{
	if (MUTATOR_CALLHOOK(RandomItems_GetRandomItemClassName, prefix))
	{
		return M_ARGV(1, string);
	}
	return RandomItems_GetRandomVanillaItemClassName(prefix,
		RANDOM_ITEM_TYPE_ALL);
}

string RandomItems_GetRandomVanillaItemClassName(string prefix, int types)
{
	if (types == 0)
	{
		return "";
	}
	while (types != 0)
	{
		string cvar_name;
		RandomSelection_Init();
		if (types & RANDOM_ITEM_TYPE_HEALTH)
		{
			cvar_name = sprintf("g_%s_health_probability", prefix);
			if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
			{
				LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
			}
			else
			{
				RandomSelection_AddFloat(RANDOM_ITEM_TYPE_HEALTH,
					cvar(cvar_name), 1);
			}
		}
		if (types & RANDOM_ITEM_TYPE_ARMOR)
		{
			cvar_name = sprintf("g_%s_armor_probability", prefix);
			if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
			{
				LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
			}
			else
			{
				RandomSelection_AddFloat(RANDOM_ITEM_TYPE_ARMOR,
					cvar(cvar_name), 1);
			}
		}
		if (types & RANDOM_ITEM_TYPE_RESOURCE)
		{
			cvar_name = sprintf("g_%s_resource_probability", prefix);
			if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
			{
				LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
			}
			else
			{
				RandomSelection_AddFloat(RANDOM_ITEM_TYPE_RESOURCE,
					cvar(cvar_name), 1);
			}
		}
		if (types & RANDOM_ITEM_TYPE_WEAPON)
		{
			cvar_name = sprintf("g_%s_weapon_probability", prefix);
			if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
			{
				LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
			}
			else
			{
				RandomSelection_AddFloat(RANDOM_ITEM_TYPE_WEAPON, cvar(cvar_name), 1);
			}
		}
		if (types & RANDOM_ITEM_TYPE_POWERUP)
		{
			cvar_name = sprintf("g_%s_powerup_probability", prefix);
			if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
			{
				LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
			}
			else
			{
				RandomSelection_AddFloat(RANDOM_ITEM_TYPE_POWERUP, cvar(cvar_name), 1);
			}
		}
		int item_type = RandomSelection_chosen_float;
		string class_name = "";
		switch (item_type)
		{
			case RANDOM_ITEM_TYPE_HEALTH:
			{
				class_name = RandomItems_GetRandomItemClassNameWithProperty(
					prefix, instanceOfHealth);
				break;
			}
			case RANDOM_ITEM_TYPE_ARMOR:
			{
				class_name = RandomItems_GetRandomItemClassNameWithProperty(
					prefix, instanceOfArmor);
				break;
			}
			case RANDOM_ITEM_TYPE_RESOURCE:
			{
				class_name = RandomItems_GetRandomItemClassNameWithProperty(
					prefix, instanceOfAmmo);
				break;
			}
			case RANDOM_ITEM_TYPE_WEAPON:
			{
				RandomSelection_Init();
				FOREACH(Weapons, it != WEP_Null &&
					!(it.spawnflags & WEP_FLAG_MUTATORBLOCKED),
				{
					cvar_name = sprintf("g_%s_%s_probability", prefix,
						it.m_canonical_spawnfunc);
					if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
					{
						LOG_WARNF("Random items: cvar %s doesn't exist.",
							cvar_name);
						continue;
					}
					RandomSelection_AddString(it.m_canonical_spawnfunc,
						cvar(cvar_name), 1);
				});
				class_name = RandomSelection_chosen_string;
				break;
			}
			case RANDOM_ITEM_TYPE_POWERUP:
			{
				class_name = RandomItems_GetRandomItemClassNameWithProperty(
					prefix, instanceOfPowerup);
				break;
			}
		}
		if (class_name != "")
		{
			return class_name;
		}
		types &= ~item_type;
	}
	return "";
}

//========================= Free functions ====================================

/// \brief Returns list of classnames to replace a map item with.
/// \param[in] item Item to inspect.
/// \return List of classnames to replace a map item with.
string RandomItems_GetItemReplacementClassNames(entity item)
{
	string cvar_name = sprintf("g_random_items_replace_%s", item.classname);
	if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
	{
		LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
		return "";
	}
	return cvar_string(cvar_name);
}

string RandomItems_GetRandomItemClassNameWithProperty(string prefix,
	.bool item_property)
{
	RandomSelection_Init();
	FOREACH(Items, it.item_property && (it.spawnflags & ITEM_FLAG_NORMAL) &&
		Item_IsDefinitionAllowed(it),
	{
		string cvar_name = sprintf("g_%s_%s_probability", prefix,
			it.m_canonical_spawnfunc);
		if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
		{
			LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
			continue;
		}
		RandomSelection_AddString(it.m_canonical_spawnfunc, cvar(cvar_name), 1);
	});
	return RandomSelection_chosen_string;
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
		new_classname = RandomItems_GetRandomItemClassName("random_items");
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

	entity new_item = spawn();
	Item_CopyFields(item, new_item);
	new_item.classname = strzone(new_classname);
	new_item.lifetime = -1; // permanent (not loot)
	if (MUTATOR_IS_ENABLED(ok))
		new_item.ok_item = true;
	Item_Initialise(new_item);

	random_items_is_spawning = false;

	return wasfreed(new_item) ? NULL : new_item;
}

/// \brief Spawns a random loot item.
/// \param[in] position Position of the item.
/// \return No return.
void RandomItems_SpawnLootItem(vector position)
{
	string class_name = RandomItems_GetRandomItemClassName("random_loot");
	if (class_name == "")
	{
		return;
	}
	vector spread = '0 0 0';
	spread.z = autocvar_g_random_loot_spread / 2;
	spread += randomvec() * autocvar_g_random_loot_spread;
	random_items_is_spawning = true;

	entity item = spawn();
	item.classname = class_name;
	item.origin = position;
	item.velocity = spread;
	item.lifetime = autocvar_g_random_loot_time;
	if (MUTATOR_IS_ENABLED(ok))
		item.ok_item = true;
	Item_Initialise(item);

	random_items_is_spawning = false;
}

//============================= Hooks ========================================

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
	if (ITEM_IS_LOOT(item))
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
	if (ITEM_IS_LOOT(item))
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
