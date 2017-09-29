#include "items.qh"

/// \file
/// \brief Source file that contains implementation of the functions related to
/// game items.
/// \copyright GNU GPLv2 or any later version.

#include <common/t_items.qh>

.bool m_isloot; ///< Holds whether item is loot.

void Item_Initialize(entity item, string class_name)
{
	switch (class_name)
	{
		case "item_health_small":
		{
			StartItem(item, ITEM_HealthSmall);
			return;
		}
		case "item_health_medium":
		{
			StartItem(item, ITEM_HealthMedium);
			return;
		}
		case "item_health_big":
		case "item_health_large":
		{
			StartItem(item, ITEM_HealthBig);
			return;
		}
		case "item_health_mega":
		{
			StartItem(item, ITEM_HealthMega);
			return;
		}
		case "item_armor_small":
		{
			StartItem(item, ITEM_ArmorSmall);
			return;
		}
		case "item_armor_medium":
		{
			StartItem(item, ITEM_ArmorMedium);
			return;
		}
		case "item_armor_big":
		case "item_armor_large":
		{
			StartItem(item, ITEM_ArmorBig);
			return;
		}
		case "item_armor_mega":
		{
			StartItem(item, ITEM_ArmorMega);
			return;
		}
		case "item_shells":
		{
			StartItem(item, ITEM_Shells);
			return;
		}
		case "item_bullets":
		{
			StartItem(item, ITEM_Bullets);
			return;
		}
		case "item_rockets":
		{
			StartItem(item, ITEM_Rockets);
			return;
		}
		case "item_cells":
		{
			StartItem(item, ITEM_Cells);
			return;
		}
		case "item_plasma":
		{
			StartItem(item, ITEM_Plasma);
			return;
		}
		case "item_fuel":
		{
			StartItem(item, ITEM_JetpackFuel);
			return;
		}
		case "weapon_blaster":
		case "weapon_laser":
		{
			weapon_defaultspawnfunc(item, WEP_BLASTER);
			return;
		}
		case "weapon_shotgun":
		{
			weapon_defaultspawnfunc(item, WEP_SHOTGUN);
			return;
		}
		case "weapon_machinegun":
		case "weapon_uzi":
		{
			weapon_defaultspawnfunc(item, WEP_MACHINEGUN);
			return;
		}
		case "weapon_mortar":
		case "weapon_grenadelauncher":
		{
			weapon_defaultspawnfunc(item, WEP_MORTAR);
			return;
		}
		case "weapon_electro":
		{
			weapon_defaultspawnfunc(item, WEP_ELECTRO);
			return;
		}
		case "weapon_crylink":
		{
			weapon_defaultspawnfunc(item, WEP_CRYLINK);
			return;
		}
		case "weapon_vortex":
		case "weapon_nex":
		{
			weapon_defaultspawnfunc(item, WEP_VORTEX);
			return;
		}
		case "weapon_hagar":
		{
			weapon_defaultspawnfunc(item, WEP_HAGAR);
			return;
		}
		case "weapon_devastator":
		case "weapon_rocketlauncher":
		{
			weapon_defaultspawnfunc(item, WEP_DEVASTATOR);
			return;
		}
		case "weapon_shockwave":
		{
			weapon_defaultspawnfunc(item, WEP_SHOCKWAVE);
			return;
		}
		case "weapon_arc":
		{
			weapon_defaultspawnfunc(item, WEP_ARC);
			return;
		}
		case "weapon_hook":
		{
			weapon_defaultspawnfunc(item, WEP_HOOK);
			return;
		}
		case "weapon_tuba":
		{
			weapon_defaultspawnfunc(item, WEP_TUBA);
			return;
		}
		case "weapon_porto":
		{
			weapon_defaultspawnfunc(item, WEP_PORTO);
			return;
		}
		case "weapon_fireball":
		{
			weapon_defaultspawnfunc(item, WEP_FIREBALL);
			return;
		}
		case "weapon_minelayer":
		{
			weapon_defaultspawnfunc(item, WEP_MINE_LAYER);
			return;
		}
		case "weapon_hlac":
		{
			weapon_defaultspawnfunc(item, WEP_HLAC);
			return;
		}
		case "weapon_rifle":
		case "weapon_campingrifle":
		case "weapon_sniperrifle":
		{
			weapon_defaultspawnfunc(item, WEP_RIFLE);
			return;
		}
		case "weapon_seeker":
		{
			weapon_defaultspawnfunc(item, WEP_SEEKER);
			return;
		}
		case "weapon_vaporizer":
		case "weapon_minstanex":
		{
			weapon_defaultspawnfunc(item, WEP_VAPORIZER);
			return;
		}
		case "item_strength":
		{
			StartItem(item, ITEM_Strength);
			return;
		}
		case "item_invincible":
		{
			StartItem(item, ITEM_Shield);
			return;
		}
		case "item_fuel_regen":
		{
			StartItem(item, ITEM_JetpackRegen);
			return;
		}
		case "item_jetpack":
		{
			StartItem(item, ITEM_Jetpack);
			return;
		}
	}
	error("Item_Initialize: Invalid classname");
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
	item.pickup_anyway = true;
	item.spawnfunc_checked = true;
	Item_Initialize(item, class_name);
	if (wasfreed(item))
	{
		return false;
	}
	item.gravity = 1;
	setorigin(item, position);
	item.velocity = vel;
	SUB_SetFade(item, time + time_to_live, 1);
	return true;
}

bool Item_IsLoot(entity item)
{
	return item.m_isloot || (item.classname == "droppedweapon");
}

void Item_SetLoot(entity item, bool loot)
{
	item.m_isloot = loot;
}
