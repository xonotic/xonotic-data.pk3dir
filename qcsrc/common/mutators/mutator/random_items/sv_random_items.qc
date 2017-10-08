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

bool autocvar_g_random_items; ///< Whether to enable random items.

// Replace cvars

/// \brief Classnames to replace %s with.
/// string autocvar_g_random_items_replace_%s;

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

/// \brief Probability of random %s spawning as loot.
/// float autocvar_g_random_loot_weapon_%s_probability;

/// \brief Probability of random %s spawning as loot during overkill.
/// float autocvar_g_random_loot_overkill_%s_probability;

/// \brief Holds whether random item is spawning. Used to prevent infinite
/// recursion.
bool random_items_is_spawning = false;

//========================= Free functions ====================================

string RandomItems_GetItemVarName(string class_name)
{
	if (startsWith(class_name, "weapon_"))
	{
		FOREACH(Weapons, sprintf("weapon_%s", it.netname) == class_name, {
			if (it.spawnflags & WEP_FLAG_MUTATORBLOCKED)
			{
				return "";
			}
			return class_name;
		});
	}
	bool is_ok = expr_evaluate(autocvar_g_overkill);
	switch (class_name)
	{
		#define X(classname, var) case #classname: return #var
		#define XCOND(classname, var, expr) case #classname: if (expr) return #var; else break
		X(item_health_small, health_small);
		X(item_health_medium, health_medium);
		X(item_health_big, health_big);
		XCOND(item_health_mega, health_mega, !is_ok || !autocvar_g_overkill_filter_healthmega);

		X(item_armor_small, armor_small);
		XCOND(item_armor_medium, armor_medium, !is_ok || !autocvar_g_overkill_filter_armormedium);
		XCOND(item_armor_big, armor_big, !is_ok || !autocvar_g_overkill_filter_armorbig);
		XCOND(item_armor_mega, armor_mega, !is_ok || !autocvar_g_overkill_filter_armormega);

		X(item_shells, resource_shells);
		X(item_bullets, resource_bullets);
		X(item_rockets, resource_rockets);
		X(item_cells, resource_cells);
		X(item_plasma, resource_plasma);
		X(item_fuel, resource_fuel);

		X(item_strength, strength);
		X(item_invincible, shield);
		X(item_fuel_regen, fuel_regen);
		X(item_jetpack, jetpack);

		X(item_vaporizer_cells, vaporizer_cells);
		X(item_invisibility, invisibility);
		X(item_extralife, extralife);
		X(item_speed, speed);

		#undef X
		#undef XCOND
	}
	return "";
}

/// \brief Returns list of classnames to replace a map item with.
/// \param[in] item Item to inspect.
/// \return List of classnames to replace a map item with.
string RandomItems_GetItemReplacementClassNames(entity item)
{
	string class_name = RandomItems_GetItemVarName(item.classname);
	if (class_name)
	{
		return cvar_string(sprintf("g_random_items_replace_%s", class_name));
	}
	if (item.classname == "replacedweapon")
	{
		Weapon w = Weapons_from(item.weapon);
		if (w != WEP_Null)
		{
			return cvar_string(sprintf("g_random_items_replace_weapon_%s", w.netname));
		}
	}
	return "";
}

/// \brief Returns a random classname of the instagib map item.
/// \return Random classname of the instagib map item.
string RandomItems_GetRandomInstagibMapItemClassName()
{
	RandomSelection_Init();
	#define X(classname) \
		RandomSelection_AddString( \
			classname, \
			cvar(sprintf("g_random_items_%s_probability", RandomItems_GetItemVarName(classname))), \
			1 \
		)
	X("item_vaporizer_cells");
	X("item_invisibility");
	X("item_extralife");
	X("item_speed");
	#undef X
	return RandomSelection_chosen_string;
}

/// \brief Returns a random classname of the overkill map item.
/// \return Random classname of the overkill map item.
string RandomItems_GetRandomOverkillMapItemClassName()
{
	RandomSelection_Init();
	string varname;
	#define X(classname) MACRO_BEGIN \
		if ((varname = RandomItems_GetItemVarName(classname))) \
		{ \
			RandomSelection_AddString( \
				classname, \
				cvar(sprintf("g_random_items_overkill_%s_probability", varname)), \
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

/// \brief Returns a random classname of the map item.
/// \return Random classname of the map item.
string RandomItems_GetRandomMapItemClassName()
{
	if (autocvar_g_instagib)
	{
		return RandomItems_GetRandomInstagibMapItemClassName();
	}
	if (expr_evaluate(autocvar_g_overkill))
	{
		return RandomItems_GetRandomOverkillMapItemClassName();
	}
	RandomSelection_Init();
	#define X(type, name) \
		RandomSelection_AddFloat( \
			RANDOM_ITEM_TYPE_##type, \
			autocvar_g_random_items_##name##_probability, \
			1 \
		)
	X(HEALTH, health);
	X(ARMOR, armor);
	X(RESOURCE, resource);
	X(WEAPON, weapon);
	X(POWERUP, powerup);
	#undef X
	int item_type = RandomSelection_chosen_float;
	switch (item_type)
	{
		case RANDOM_ITEM_TYPE_HEALTH:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_items_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Items, it.instanceOfHealth, {
				X(sprintf("item_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_ARMOR:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_items_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Items, it.instanceOfArmor, {
				X(sprintf("item_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_RESOURCE:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_items_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Items, it.instanceOfAmmo, {
				X(sprintf("item_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_WEAPON:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_items_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Weapons, !(it.spawnflags & WEP_FLAG_MUTATORBLOCKED), {
				X(sprintf("weapon_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_POWERUP:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_items_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			X("item_strength");
			X("item_invincible");
			X("item_fuel_regen");
			X("item_jetpack");
			#undef X
			return RandomSelection_chosen_string;
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
	entity new_item;
	if (!expr_evaluate(autocvar_g_overkill))
	{
		new_item = Item_Create(strzone(new_classname), item.origin);
	}
	else
	{
		new_item = spawn();
		new_item.classname = strzone(new_classname);
		new_item.spawnfunc_checked = true;
		new_item.ok_item = true;
		Item_Initialize(new_item, new_classname);
		if (wasfreed(new_item))
		{
			return NULL;
		}
		setorigin(new_item, item.origin);
	}
	random_items_is_spawning = false;
	return new_item;
}

/// \brief Returns a random classname of the instagib loot item.
/// \return Random classname of the instagib loot item.
string RandomItems_GetRandomInstagibLootItemClassName()
{
	RandomSelection_Init();
	#define X(classname) \
		RandomSelection_AddString( \
			classname, \
			cvar(sprintf("g_random_loot_%s_probability", RandomItems_GetItemVarName(classname))), \
			1 \
		)
	X("item_vaporizer_cells");
	X("item_invisibility");
	X("item_extralife");
	X("item_speed");
	#undef X
	return RandomSelection_chosen_string;
}

/// \brief Returns a random classname of the overkill loot item.
/// \return Random classname of the overkill loot item.
string RandomItems_GetRandomOverkillLootItemClassName()
{
	RandomSelection_Init();
	string varname;
	#define X(classname) MACRO_BEGIN \
		if ((varname = RandomItems_GetItemVarName(classname))) \
		{ \
			RandomSelection_AddString( \
				classname, \
				cvar(sprintf("g_random_loot_overkill_%s_probability", varname)), \
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

/// \brief Returns a random classname of the loot item.
/// \return Random classname of the loot item.
string RandomItems_GetRandomLootItemClassName()
{
	if (autocvar_g_instagib)
	{
		return RandomItems_GetRandomInstagibLootItemClassName();
	}
	if (expr_evaluate(autocvar_g_overkill))
	{
		return RandomItems_GetRandomOverkillLootItemClassName();
	}
	RandomSelection_Init();
	#define X(type, name) \
		RandomSelection_AddFloat( \
			RANDOM_ITEM_TYPE_##type, \
			autocvar_g_random_loot_##name##_probability, \
			1 \
		)
	X(HEALTH, health);
	X(ARMOR, armor);
	X(RESOURCE, resource);
	X(WEAPON, weapon);
	X(POWERUP, powerup);
	#undef X
	int item_type = RandomSelection_chosen_float;
	switch (item_type)
	{
		case RANDOM_ITEM_TYPE_HEALTH:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_loot_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Items, it.instanceOfHealth, {
				X(sprintf("item_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_ARMOR:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_loot_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Items, it.instanceOfArmor, {
				X(sprintf("item_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_RESOURCE:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_loot_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Items, it.instanceOfAmmo, {
				X(sprintf("item_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_WEAPON:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_loot_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			FOREACH(Weapons, !(it.spawnflags & WEP_FLAG_MUTATORBLOCKED), {
				X(sprintf("weapon_%s", it.netname));
			});
			#undef X
			return RandomSelection_chosen_string;
		}
		case RANDOM_ITEM_TYPE_POWERUP:
		{
			RandomSelection_Init();
			#define X(classname) \
				RandomSelection_AddString( \
					classname, \
					cvar(sprintf("g_random_loot_%s_probability", RandomItems_GetItemVarName(classname))), \
					1 \
				)
			X("item_strength");
			X("item_invincible");
			X("item_jetpack");
			X("item_fuel_regen");
			#undef X
			return RandomSelection_chosen_string;
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
