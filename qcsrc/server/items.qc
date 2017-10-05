#include "items.qh"

/// \file
/// \brief Source file that contains implementation of the functions related to
/// game items.
/// \copyright GNU GPLv2 or any later version.

#include <common/mutators/mutator/instagib/sv_instagib.qh>
#include <common/mutators/mutator/overkill/hmg.qh>
#include <common/mutators/mutator/overkill/rpc.qh>

.bool m_isloot; ///< Holds whether item is loot.

entity Item_Create(string class_name, vector position)
{
	entity item = spawn();
	item.classname = class_name;
	item.spawnfunc_checked = true;
	Item_Initialize(item, class_name);
	if (wasfreed(item))
	{
		return NULL;
	}
	setorigin(item, position);
	return item;
}

void Item_Initialize(entity item, string class_name)
{
	switch (class_name)
	{
		case "item_health_small":
		{
			spawnfunc_item_health_small(item);
			return;
		}
		case "item_health_medium":
		{
			spawnfunc_item_health_medium(item);
			return;
		}
		case "item_health_big":
		case "item_health_large":
		{
			spawnfunc_item_health_big(item);
			return;
		}
		case "item_health_mega":
		{
			spawnfunc_item_health_mega(item);
			return;
		}
		case "item_armor_small":
		{
			spawnfunc_item_armor_small(item);
			return;
		}
		case "item_armor_medium":
		{
			spawnfunc_item_armor_medium(item);
			return;
		}
		case "item_armor_big":
		case "item_armor_large":
		{
			spawnfunc_item_armor_big(item);
			return;
		}
		case "item_armor_mega":
		{
			spawnfunc_item_armor_mega(item);
			return;
		}
		case "item_shells":
		{
			spawnfunc_item_shells(item);
			return;
		}
		case "item_bullets":
		{
			spawnfunc_item_bullets(item);
			return;
		}
		case "item_rockets":
		{
			spawnfunc_item_rockets(item);
			return;
		}
		case "item_cells":
		{
			spawnfunc_item_cells(item);
			return;
		}
		case "item_plasma":
		{
			spawnfunc_item_plasma(item);
			return;
		}
		case "item_fuel":
		{
			spawnfunc_item_fuel(item);
			return;
		}
		case "weapon_blaster":
		case "weapon_laser":
		{
			spawnfunc_weapon_blaster(item);
			return;
		}
		case "weapon_shotgun":
		{
			spawnfunc_weapon_shotgun(item);
			return;
		}
		case "weapon_machinegun":
		case "weapon_uzi":
		{
			spawnfunc_weapon_machinegun(item);
			return;
		}
		case "weapon_mortar":
		case "weapon_grenadelauncher":
		{
			spawnfunc_weapon_mortar(item);
			return;
		}
		case "weapon_electro":
		{
			spawnfunc_weapon_electro(item);
			return;
		}
		case "weapon_crylink":
		{
			spawnfunc_weapon_crylink(item);
			return;
		}
		case "weapon_vortex":
		case "weapon_nex":
		{
			spawnfunc_weapon_vortex(item);
			return;
		}
		case "weapon_hagar":
		{
			spawnfunc_weapon_hagar(item);
			return;
		}
		case "weapon_devastator":
		case "weapon_rocketlauncher":
		{
			spawnfunc_weapon_devastator(item);
			return;
		}
		case "weapon_shockwave":
		{
			spawnfunc_weapon_shockwave(item);
			return;
		}
		case "weapon_arc":
		{
			spawnfunc_weapon_arc(item);
			return;
		}
		case "weapon_hook":
		{
			spawnfunc_weapon_hook(item);
			return;
		}
		case "weapon_tuba":
		{
			spawnfunc_weapon_tuba(item);
			return;
		}
		case "weapon_porto":
		{
			spawnfunc_weapon_porto(item);
			return;
		}
		case "weapon_fireball":
		{
			spawnfunc_weapon_fireball(item);
			return;
		}
		case "weapon_minelayer":
		{
			spawnfunc_weapon_minelayer(item);
			return;
		}
		case "weapon_hlac":
		{
			spawnfunc_weapon_hlac(item);
			return;
		}
		case "weapon_rifle":
		case "weapon_campingrifle":
		case "weapon_sniperrifle":
		{
			spawnfunc_weapon_rifle(item);
			return;
		}
		case "weapon_seeker":
		{
			spawnfunc_weapon_seeker(item);
			return;
		}
		case "weapon_vaporizer":
		case "weapon_minstanex":
		{
			spawnfunc_weapon_vaporizer(item);
			return;
		}
		case "weapon_hmg":
		{
			spawnfunc_weapon_hmg(item);
			return;
		}
		case "weapon_rpc":
		{
			spawnfunc_weapon_rpc(item);
			return;
		}
		case "item_strength":
		{
			spawnfunc_item_strength(item);
			return;
		}
		case "item_invincible":
		{
			spawnfunc_item_invincible(item);
			return;
		}
		case "item_fuel_regen":
		{
			spawnfunc_item_fuel_regen(item);
			return;
		}
		case "item_jetpack":
		{
			spawnfunc_item_jetpack(item);
			return;
		}
		case "item_vaporizer_cells":
		{
			spawnfunc_item_vaporizer_cells(item);
			return;
		}
		case "item_invisibility":
		{
			instagib_invisibility(item);
			return;
		}
		case "item_extralife":
		{
			instagib_extralife(item);
			return;
		}
		case "item_speed":
		{
			instagib_speed(item);
			return;
		}
	}
	error("Item_Initialize: Invalid classname ", class_name);
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

spawnfunc(item_health_small)
{
	StartItem(this, ITEM_HealthSmall);
}

spawnfunc(item_health_medium)
{
	StartItem(this, ITEM_HealthMedium);
}

spawnfunc(item_health_big)
{
	StartItem(this, ITEM_HealthBig);
}

spawnfunc(item_health_mega)
{
	StartItem(this, ITEM_HealthMega);
}

spawnfunc(item_armor_small)
{
	StartItem(this, ITEM_ArmorSmall);
}

spawnfunc(item_armor_medium)
{
	StartItem(this, ITEM_ArmorMedium);
}

spawnfunc(item_armor_big)
{
	StartItem(this, ITEM_ArmorBig);
}

spawnfunc(item_armor_mega)
{
	StartItem(this, ITEM_ArmorMega);
}

spawnfunc(item_shells)
{
	if (!weaponswapping && autocvar_sv_q3acompat_machineshotgunswap &&
		(this.classname != "droppedweapon"))
	{
		weaponswapping = true;
		spawnfunc_item_bullets(this);
		weaponswapping = false;
		return;
	}
	StartItem(this, ITEM_Shells);
}

spawnfunc(item_bullets)
{
	if (!weaponswapping && autocvar_sv_q3acompat_machineshotgunswap &&
		(this.classname != "droppedweapon"))
	{
		weaponswapping = true;
		spawnfunc_item_shells(this);
		weaponswapping = false;
		return;
	}
	StartItem(this, ITEM_Bullets);
}

spawnfunc(item_rockets)
{
	StartItem(this, ITEM_Rockets);
}

spawnfunc(item_cells)
{
	StartItem(this, ITEM_Cells);
}

spawnfunc(item_plasma)
{
	StartItem(this, ITEM_Plasma);
}

spawnfunc(item_fuel)
{
	StartItem(this, ITEM_JetpackFuel);
}

spawnfunc(item_strength)
{
	StartItem(this, ITEM_Strength);
}

spawnfunc(item_invincible)
{
	StartItem(this, ITEM_Shield);
}

spawnfunc(item_fuel_regen)
{
	if (start_items & ITEM_JetpackRegen.m_itemid)
	{
		spawnfunc_item_fuel(this);
		return;
	}
	StartItem(this, ITEM_JetpackRegen);
}

spawnfunc(item_jetpack)
{
	if(start_items & ITEM_Jetpack.m_itemid)
	{
		spawnfunc_item_fuel(this);
		return;
	}
	StartItem(this, ITEM_Jetpack);
}

// Compatibility spawn functions

spawnfunc(item_armor1) { spawnfunc_item_armor_small(this); }  // FIXME: in Quake this is green armor, in Xonotic maps it is an armor shard
spawnfunc(item_armor25) { spawnfunc_item_armor_mega(this); }
spawnfunc(item_armor_large) { spawnfunc_item_armor_mega(this); }
spawnfunc(item_health1) { spawnfunc_item_health_small(this); }
spawnfunc(item_health25) { spawnfunc_item_health_medium(this); }
spawnfunc(item_health_large) { spawnfunc_item_health_big(this); }
spawnfunc(item_health100) { spawnfunc_item_health_mega(this); }
