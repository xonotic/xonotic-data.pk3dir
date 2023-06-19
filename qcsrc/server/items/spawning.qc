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
#include <server/world.qh>

.bool m_isloot; ///< Holds whether item is loot.
/// \brief Holds whether strength, shield or superweapon timers expire while
/// this item is on the ground.
.bool m_isexpiring;

bool Item_IsDefinitionAllowed(entity definition)
{
	return !MUTATOR_CALLHOOK(FilterItemDefinition, definition);
}

// An optimised and generic way to initialise items (loot or permanent)
// required field: itemdef (faster, preferred) OR classname
// optional fields: origin, velocity, lifetime, noalign
// lifetime < 0 means permanent (not loot), lifetime > 0 overrides the default
// permanent items only: noalign means the item is suspended (won't drop to floor)
bool Item_Initialise(entity item)
{
	if (item.lifetime >= 0)
	{
		Item_SetLoot(item, true);
		item.pickup_anyway = true; // these are ALWAYS pickable
	}

	if (item.itemdef) // no search required
	{
		if (item.itemdef.instanceOfWeapon)
			weapon_defaultspawnfunc(item, item.itemdef);
		else
			StartItem(item, item.itemdef);
	}
	else // fall back to classname search
	{
		FOREACH(Weapons, it.m_canonical_spawnfunc == item.classname,
		{
			weapon_defaultspawnfunc(item, it);
			goto classname_found;
		});
		FOREACH(Items, it.m_canonical_spawnfunc == item.classname,
		{
			StartItem(item, it);
			goto classname_found;
		});
		LOG_FATALF("Item_Initialize: Invalid classname: %s", item.classname);
		LABEL(classname_found)
	}

	if (wasfreed(item))
		return false;

	// StartItem sets the default .wait expiry time which is respected by Item_Think()
	if (item.lifetime > 0)
		item.wait = time + item.lifetime;

	item.spawnfunc_checked = true;
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
SPAWNFUNC_ITEM_COND(item_armor1, autocvar_sv_mapformat_is_quake3, ITEM_ArmorSmall, ITEM_ArmorMedium)
SPAWNFUNC_ITEM(item_armor25, ITEM_ArmorMega) // Nexuiz used item_armor25 to spawn a Mega Armor
SPAWNFUNC_ITEM(item_health1, ITEM_HealthSmall)
SPAWNFUNC_ITEM(item_health25, ITEM_HealthMedium)
SPAWNFUNC_ITEM(item_health100, ITEM_HealthMega)
SPAWNFUNC_ITEM(item_armor_large, ITEM_ArmorMega)
SPAWNFUNC_ITEM(item_health_large, ITEM_HealthBig)
