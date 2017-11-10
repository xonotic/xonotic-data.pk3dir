#include "sv_random_items.qh"

/// \file
/// \brief Source file that contains implementation of the random items mutator.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

//============================ Constants ======================================

enum
{
	RANDOM_ITEM_TYPE_HEALTH = 1,
	RANDOM_ITEM_TYPE_ARMOR,
	RANDOM_ITEM_TYPE_RESOURCE,
	RANDOM_ITEM_TYPE_WEAPON,
	RANDOM_ITEM_TYPE_POWERUP
};

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

bool autocvar_g_random_loot; ///< Whether to enable random loot.

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

string RandomItems_GetItemVarName(string class_name);

//=========================== Public API ======================================

string RandomItems_GetRandomItemClassName(string prefix)
{
	if (autocvar_g_instagib)
	{
		return RandomItems_GetRandomInstagibItemClassName(prefix);
	}
	if (expr_evaluate(autocvar_g_overkill))
	{
		return RandomItems_GetRandomOverkillItemClassName(prefix);
	}
	return RandomItems_GetRandomVanillaItemClassName(prefix);
}

string RandomItems_GetRandomVanillaItemClassName(string prefix)
{
	RandomSelection_Init();
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_HEALTH,
		cvar(sprintf("g_%s_health_probability", prefix)), 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_ARMOR,
		cvar(sprintf("g_%s_armor_probability", prefix)), 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_RESOURCE,
		cvar(sprintf("g_%s_resource_probability", prefix)), 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_WEAPON,
		cvar(sprintf("g_%s_weapon_probability", prefix)), 1);
	RandomSelection_AddFloat(RANDOM_ITEM_TYPE_POWERUP,
		cvar(sprintf("g_%s_powerup_probability", prefix)), 1);
	int item_type = RandomSelection_chosen_float;
	switch (item_type)
	{
		case RANDOM_ITEM_TYPE_HEALTH:
		{
			return RandomItems_GetRandomItemClassNameWithProperty(prefix,
				instanceOfHealth);
		}
		case RANDOM_ITEM_TYPE_ARMOR:
		{
			return RandomItems_GetRandomItemClassNameWithProperty(prefix,
				instanceOfArmor);
		}
		case RANDOM_ITEM_TYPE_RESOURCE:
		{
			return RandomItems_GetRandomItemClassNameWithProperty(prefix,
				instanceOfAmmo);
		}
		case RANDOM_ITEM_TYPE_WEAPON:
		{
			RandomSelection_Init();
			FOREACH(Weapons, it != WEP_Null &&
				!(it.spawnflags & WEP_FLAG_MUTATORBLOCKED),
			{
				string cvar_name = sprintf("g_%s_%s_probability", prefix,
					it.m_canonical_spawnfunc);
				RandomSelection_AddString(it.m_canonical_spawnfunc,
					cvar(cvar_name), 1);
			});
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_POWERUP:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_%s_%s_probability", prefix, classname)), \
					1 \
				)
			X("item_strength");
			X("item_shield");
			X("item_fuel_regen");
			X("item_jetpack");
			#undef X
			return RandomSelection_chosen_string;
		}
	}
	return "";
}

string RandomItems_GetRandomInstagibItemClassName(string prefix)
{
	RandomSelection_Init();
	#define X(classname) \
		RandomSelection_AddString( \
			classname, \
			cvar(sprintf("g_%s_%s_probability", prefix, classname)), \
			1 \
		)
	X("item_vaporizer_cells");
	X("item_invisibility");
	X("item_extralife");
	X("item_speed");
	#undef X
	return RandomSelection_chosen_string;
}

string RandomItems_GetRandomOverkillItemClassName(string prefix)
{
	RandomSelection_Init();
	string varname;
	#define X(classname) MACRO_BEGIN \
		if ((varname = RandomItems_GetItemVarName(classname))) \
		{ \
			RandomSelection_AddString( \
				classname, \
				cvar(sprintf("g_%s_overkill_%s_probability", prefix, varname)), \
				1 \
			); \
		} \
	MACRO_END
	X("item_health_mega");
	X("item_armor_small");
	X("item_armor_medium");
	X("item_armor_big");
	X("item_armor_mega");
	X("weapon_hmg");
	X("weapon_rpc");
	#undef X
	return RandomSelection_chosen_string;
}

//========================= Free functions ====================================

string RandomItems_GetItemVarName(string class_name)
{
	if (startsWith(class_name, "weapon_"))
	{
		FOREACH(Weapons, it.m_canonical_spawnfunc == class_name, {
			if (it.spawnflags & WEP_FLAG_MUTATORBLOCKED)
			{
				return "";
			}
			return class_name;
		});
	}
	switch (class_name)
	{
		#define XCOND(classname, expr) case #classname: if (expr) return #classname; else break
		XCOND(item_health_mega, !autocvar_g_overkill_filter_healthmega);
		case "item_armor_small": return "item_armor_small";
		XCOND(item_armor_medium, !autocvar_g_overkill_filter_armormedium);
		XCOND(item_armor_big, !autocvar_g_overkill_filter_armorbig);
		XCOND(item_armor_mega, !autocvar_g_overkill_filter_armormega);
		#undef XCOND
	}
	return "";
}

/// \brief Returns list of classnames to replace a map item with.
/// \param[in] item Item to inspect.
/// \return List of classnames to replace a map item with.
string RandomItems_GetItemReplacementClassNames(entity item)
{
	return cvar_string(sprintf("g_random_items_replace_%s", item.classname));
}

string RandomItems_GetRandomItemClassNameWithProperty(string prefix,
	.bool item_property)
{
	RandomSelection_Init();
	FOREACH(Items, it.item_property,
	{
		RandomSelection_AddString(it.m_canonical_spawnfunc,
			cvar(sprintf("g_%s_%s_probability", prefix,
			it.m_canonical_spawnfunc)), 1);
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
	entity new_item;
	if (!expr_evaluate(autocvar_g_overkill))
	{
		new_item = Item_Create(strzone(new_classname), item.origin);
		random_items_is_spawning = false;
		if (new_item == NULL)
		{
			return NULL;
		}
	}
	else
	{
		new_item = spawn();
		new_item.classname = strzone(new_classname);
		new_item.spawnfunc_checked = true;
		new_item.ok_item = true;
		Item_Initialize(new_item, new_classname);
		random_items_is_spawning = false;
		if (wasfreed(new_item))
		{
			return NULL;
		}
		setorigin(new_item, item.origin);
	}
	if (item.team)
	{
		new_item.team = item.team;
	}
	return new_item;
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
	if (!expr_evaluate(autocvar_g_overkill))
	{
		Item_CreateLoot(class_name, position, spread,
			autocvar_g_random_loot_time);
	}
	else
	{
		entity item = spawn();
		item.ok_item = true;
		item.classname = class_name;
		Item_InitializeLoot(item, class_name, position, spread,
			autocvar_g_random_loot_time);
	}
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
