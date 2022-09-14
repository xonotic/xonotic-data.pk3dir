#include "sv_overkill.qh"

#include "okshotgun.qh"
#include "okhmg.qh"
#include "okrpc.qh"

bool autocvar_g_overkill_powerups_replace;

bool autocvar_g_overkill_itemwaypoints = true;

.Weapon ok_lastwep[MAX_WEAPONSLOTS];

/// \brief Returns a random classname of the overkill item.
/// \param[in] prefix Prefix of the cvars that hold probabilities.
/// \return Random classname of the overkill item.
string RandomItems_GetRandomOverkillItemClassName(string prefix)
{
	RandomSelection_Init();
	IL_EACH(g_overkill_items, !(it.spawnflags & ITEM_FLAG_MUTATORBLOCKED) &&
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
	string cvar_name = sprintf("g_%s_weapon_okhmg_probability", prefix);
	if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
	{
		LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
	}
	else
	{
		RandomSelection_AddString("weapon_okhmg", cvar(cvar_name), 1);
	}
	cvar_name = sprintf("g_%s_weapon_okrpc_probability", prefix);
	if (!(cvar_type(cvar_name) & CVAR_TYPEFLAG_EXISTS))
	{
		LOG_WARNF("Random items: cvar %s doesn't exist.", cvar_name);
	}
	else
	{
		RandomSelection_AddString("weapon_okrpc", cvar(cvar_name), 1);
	}
	return RandomSelection_chosen_string;
}


MUTATOR_HOOKFUNCTION(ok, RandomItems_GetRandomItemClassName)
{
	M_ARGV(1, string) = RandomItems_GetRandomOverkillItemClassName(
		M_ARGV(0, string));
	return true;
}

MUTATOR_HOOKFUNCTION(ok, Damage_Calculate, CBC_ORDER_LAST)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);

	if(IS_PLAYER(frag_attacker) && (IS_PLAYER(frag_target) || IS_VEHICLE(frag_target) || IS_TURRET(frag_target)))
	if(DEATH_ISWEAPON(frag_deathtype, WEP_BLASTER))
	{
		if(frag_attacker != frag_target)
		if(!STAT(FROZEN, frag_target))
		if(!IS_DEAD(frag_target))
		{
			M_ARGV(6, vector) = '0 0 0'; // force
		}

		M_ARGV(4, float) = 0; // damage
	}
}

void ok_DropItem(entity this, entity targ)
{
	entity e = spawn();
	e.ok_item = true;
	Item_InitializeLoot(e, "item_armor_small", this.origin + '0 0 32',
		'0 0 200' + normalize(targ.origin - this.origin) * 500, 5);
}

MUTATOR_HOOKFUNCTION(ok, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	entity targ = ((IS_PLAYER(frag_attacker)) ? frag_attacker : frag_target);

	ok_DropItem(frag_target, targ);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];

		frag_target.ok_lastwep[slot] = frag_target.(weaponentity).m_switchweapon;
	}
}

MUTATOR_HOOKFUNCTION(ok, MonsterDropItem)
{
	entity mon = M_ARGV(0, entity);
	entity olditem = M_ARGV(1, entity);
	entity frag_attacker = M_ARGV(2, entity);

	delete(olditem);

	M_ARGV(1, entity) = NULL;

	ok_DropItem(mon, frag_attacker);
}

MUTATOR_HOOKFUNCTION(ok, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(ok, PlayerPreThink)
{
	if (game_stopped)
	{
		return;
	}
	entity player = M_ARGV(0, entity);
	if (!IS_PLAYER(player) || IS_DEAD(player) || STAT(FROZEN, player))
	{
		return;
	}
	if (!PHYS_INPUT_BUTTON_ATCK2(player) || weaponLocked(player) ||
		!(round_handler_IsActive() && !round_handler_IsRoundStarted()))
	{
		return;
	}
	// Allow secondary blaster during countdown.
	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		Weapon weapon = player.(weaponentity).m_weapon;
		if (weapon == WEP_Null && slot != 0)
		{
			continue;
		}
		weapon.wr_think(weapon, player, weaponentity, 2);
	}
	PHYS_INPUT_BUTTON_ATCK2(player) = false;
}

MUTATOR_HOOKFUNCTION(ok, ForbidRandomStartWeapons)
{
	return true;
}

MUTATOR_HOOKFUNCTION(ok, PlayerWeaponSelect)
{
	entity player = M_ARGV(0, entity);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		entity thiswep = player.(weaponentity);

		if(player.ok_lastwep[slot] && player.ok_lastwep[slot] != WEP_Null)
		{
			Weapon newwep = player.ok_lastwep[slot];
			if(player.ok_lastwep[slot] == WEP_OVERKILL_HMG)
				newwep = WEP_OVERKILL_MACHINEGUN;
			if(player.ok_lastwep[slot] == WEP_OVERKILL_RPC)
				newwep = WEP_OVERKILL_NEX;
			thiswep.m_switchweapon = newwep;
			player.ok_lastwep[slot] = WEP_Null;
		}
	}
}

bool ok_HandleItemWaypoints(entity e)
{
	if(!autocvar_g_overkill_itemwaypoints)
		return false; // don't handle it

	switch(e.itemdef)
	{
		case ITEM_HealthMega: return true;
		case ITEM_ArmorMedium: return true;
		case ITEM_ArmorBig: return true;
		case ITEM_ArmorMega: return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ok, Item_RespawnCountdown)
{
	entity item = M_ARGV(0, entity);
	return ok_HandleItemWaypoints(item);
}

MUTATOR_HOOKFUNCTION(ok, Item_ScheduleRespawn)
{
	entity item = M_ARGV(0, entity);
	return ok_HandleItemWaypoints(item);
}

MUTATOR_HOOKFUNCTION(ok, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if (item.ok_item)
	{
		return false;
	}
	switch(item.itemdef)
	{
		case ITEM_HealthMega: return autocvar_g_overkill_filter_healthmega;
		case ITEM_ArmorMedium: return autocvar_g_overkill_filter_armormedium;
		case ITEM_ArmorBig: return autocvar_g_overkill_filter_armorbig;
		case ITEM_ArmorMega: return autocvar_g_overkill_filter_armormega;
	}
	if (!autocvar_g_powerups || !autocvar_g_overkill_powerups_replace)
	{
		return true;
	}
	if (item.classname == "item_strength")
	{
		entity wep = new(weapon_okhmg);
		setorigin(wep, item.origin);
		wep.ok_item = true;
		wep.noalign = Item_ShouldKeepPosition(item);
		wep.cnt = item.cnt;
		wep.team = item.team;
		wep.respawntime = g_pickup_respawntime_superweapon;
		wep.pickup_anyway = true;
		wep.spawnfunc_checked = true;
		Item_Initialize(wep, "weapon_okhmg"); // doesn't actually use spawnfunc
		return true;
	}
	else if (item.classname == "item_shield")
	{
		entity wep = new(weapon_okrpc);
		setorigin(wep, item.origin);
		wep.ok_item = true;
		wep.noalign = Item_ShouldKeepPosition(item);
		wep.cnt = item.cnt;
		wep.team = item.team;
		wep.respawntime = g_pickup_respawntime_superweapon;
		wep.pickup_anyway = true;
		wep.spawnfunc_checked = true;
		Item_Initialize(wep, "weapon_okrpc"); // doesn't actually use spawnfunc
		return true;
	}
	return true;
}

MUTATOR_HOOKFUNCTION(ok, SetStartItems, CBC_ORDER_LAST)
{
	WepSet ok_start_items = (WEPSET(OVERKILL_MACHINEGUN) | WEPSET(OVERKILL_NEX) | WEPSET(OVERKILL_SHOTGUN));

	if(WEP_OVERKILL_RPC.weaponstart > 0) { ok_start_items |= WEPSET(OVERKILL_RPC); }
	if(WEP_OVERKILL_HMG.weaponstart > 0) { ok_start_items |= WEPSET(OVERKILL_HMG); }

	start_items |= IT_UNLIMITED_AMMO;

	start_weapons = warmup_start_weapons = ok_start_items;
}

MUTATOR_HOOKFUNCTION(ok, SetWeaponArena)
{
	// turn weapon arena off
	M_ARGV(0, string) = "off";
}

MUTATOR_HOOKFUNCTION(ok, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":OK");
}

MUTATOR_HOOKFUNCTION(ok, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Overkill");
}

MUTATOR_HOOKFUNCTION(ok, SetModname)
{
	M_ARGV(0, string) = "Overkill";
	return true;
}

