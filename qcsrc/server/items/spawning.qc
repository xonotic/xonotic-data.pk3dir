#include "spawning.qh"

/// \file
/// \brief Source file that contains implementation of the functions related to
/// creation of game items.
/// \copyright GNU GPLv2 or any later version.

#include <common/mapobjects/subs.qh>
#include <common/weapons/all.qh>
#include <server/items/items.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/spawning.qh>

.bool m_isloot; ///< Holds whether item is loot.
/// \brief Holds whether strength, shield or superweapon timers expire while
/// this item is on the ground.
.bool m_isexpiring;

entity Item_FindDefinition(string class_name)
{
	FOREACH(Items, it.m_canonical_spawnfunc == class_name,
	{
		return it;
	});
	FOREACH(Weapons, it.m_canonical_spawnfunc == class_name,
	{
		return it.m_pickup;
	});
	return NULL;
}

entity Item_DefinitionFromInternalName(string item_name)
{
	FOREACH(Items, it.netname == item_name,
	{
		return it;
	});
	FOREACH(Weapons, it.netname == item_name,
	{
		return it.m_pickup;
	});
	return NULL;
}

bool Item_IsAllowed(string class_name)
{
	entity definition = Item_FindDefinition(class_name);
	if (definition == NULL)
	{
		return false;
	}
	return Item_IsDefinitionAllowed(definition);
}

bool Item_IsDefinitionAllowed(entity definition)
{
	return !MUTATOR_CALLHOOK(FilterItemDefinition, definition);
}

entity Item_Create(string class_name, vector position, bool no_align)
{
	entity item = spawn();
	item.classname = class_name;
	item.spawnfunc_checked = true;
	setorigin(item, position);
	item.noalign = no_align;
	Item_Initialize(item, class_name);
	if (wasfreed(item))
	{
		return NULL;
	}
	return item;
}

void Item_Initialize(entity item, string class_name)
{
	FOREACH(Weapons, it.m_canonical_spawnfunc == class_name,
	{
		weapon_defaultspawnfunc(item, it);
		return;
	});
	FOREACH(Items, it.m_canonical_spawnfunc == class_name,
	{
		StartItem(item, it);
		return;
	});
	LOG_FATALF("Item_Initialize: Invalid classname: %s", class_name);
}

entity Item_CreateLoot(string class_name, vector position, vector vel,
	float time_to_live)
{
	entity item = spawn();
	if (!Item_InitializeLoot(item, class_name, position, vel, time_to_live))
	{
		return NULL;
	}
	return item;
}

bool Item_InitializeLoot(entity item, string class_name, vector position,
	vector vel, float time_to_live)
{
	item.classname = class_name;
	Item_SetLoot(item, true);
	item.noalign = true;
	setorigin(item, position);
	item.pickup_anyway = true;
	item.spawnfunc_checked = true;
	Item_Initialize(item, class_name);
	if (wasfreed(item))
	{
		return false;
	}
	item.gravity = 1;
	item.velocity = vel;
	SUB_SetFade(item, time + time_to_live, 1);
	return true;
}

bool Item_IsLoot(entity item)
{
	return item.m_isloot || item.classname == "droppedweapon";
}

void Item_SetLoot(entity item, bool loot)
{
	item.m_isloot = loot;
}

bool Item_ShouldKeepPosition(entity item)
{
	return item.noalign || (item.spawnflags & 1);
}

bool Item_IsExpiring(entity item)
{
	return item.m_isexpiring;
}

void Item_SetExpiring(entity item, bool expiring)
{
	item.m_isexpiring = expiring;
}

// Compatibility spawn functions

// in Quake this is green armor, in Xonotic maps it is an armor shard
SPAWNFUNC_ITEM_COND(item_armor1, cvar("sv_mapformat_is_quake3"), ITEM_ArmorSmall, ITEM_ArmorMedium)

SPAWNFUNC_ITEM(item_armor25, ITEM_ArmorMega)

SPAWNFUNC_ITEM(item_armor_large, ITEM_ArmorMega)

SPAWNFUNC_ITEM(item_health1, ITEM_HealthSmall)

SPAWNFUNC_ITEM(item_health25, ITEM_HealthMedium)

SPAWNFUNC_ITEM(item_health_large, ITEM_HealthBig)

SPAWNFUNC_ITEM(item_health100, ITEM_HealthMega)
