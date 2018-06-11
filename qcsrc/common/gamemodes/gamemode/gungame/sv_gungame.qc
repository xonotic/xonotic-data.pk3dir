/// \file
/// \brief Source file that contains implementation of the GunGame gamemode.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

#include "sv_gungame.qh"

//============================ Constants ======================================

const string GUNGAME_WEAPONS_CVAR = "g_gg_weapons";

//======================= Global variables ====================================

/// \brief Number of kills needed to advance to the next weapon.
int autocvar_g_gg_kills_per_weapon;

int gungame_max_level; ///< Player who reaches this level wins.
string gungame_weapons; ///< Holds weapons corresponding to levels.

entity gungame_leading_player; ///< Holds the leading player.
int gungame_leading_level; ///< Holds the leading level.
entity gungame_leading_weapon; ///< Holds the leading weapon.

//====================== Forward declarations =================================

/// \brief Resets the state to initial one.
void GunGame_Reset();

/// \brief Returns the weapon that corresponds to the given level.
/// \param[in] level Level of the weapon.
/// \return Weapon corresponding to the given level.
entity GunGame_GetWeapon(int level);

/// \brief Updates stats of all players.
void GunGame_UpdateStats();

//========================= Free functions ====================================

void GunGame_Initialize()
{
	GunGame_Reset();
}

void GunGame_Reset()
{
	strcpy(gungame_weapons, cvar_string(GUNGAME_WEAPONS_CVAR));
	gungame_max_level = tokenize_console(gungame_weapons) *
		autocvar_g_gg_kills_per_weapon;
	if (gungame_max_level == 0)
	{
		LOG_FATAL("GunGame: Invalid weapon configuration.");
	}
	GameRules_limit_score(gungame_max_level);
	gungame_leading_player = NULL;
	gungame_leading_level = 0;
	gungame_leading_weapon = GunGame_GetWeapon(0);
	GunGame_UpdateStats();
}

entity GunGame_GetWeapon(int level)
{
	if (level >= gungame_max_level)
	{
		return NULL;
	}
	tokenize_console(gungame_weapons);
	string weapon = argv(floor(level / autocvar_g_gg_kills_per_weapon));
	FOREACH(Weapons, it != WEP_Null,
	{
		if (it.netname == weapon)
		{
			return it;
		}
	});
	LOG_FATAL("GunGame_GetWeapon: Invalid level or weapon name");
	return NULL;
}

/// \brief Returns the player level.
/// \param[in] player Player to check.
/// \return Level of the player.
int GunGame_GetPlayerLevel(entity player)
{
	return PlayerScore_Get(player, SP_SCORE);
}

/// \brief Updates the information about the leading player.
void GunGame_UpdateLeadingPlayer()
{
	entity previous_leader = gungame_leading_player;
	FOREACH_CLIENT(true,
	{
		if (gungame_leading_player == NULL)
		{
			gungame_leading_player = it;
			continue;
		}
		if (GunGame_GetPlayerLevel(it) > GunGame_GetPlayerLevel(
			gungame_leading_player))
		{
			gungame_leading_player = it;
		}
	});
	if (gungame_leading_player == NULL)
	{
		return;
	}
	if ((gungame_leading_player == previous_leader) &&
		(GunGame_GetPlayerLevel(gungame_leading_player) ==
		gungame_leading_level))
	{
		return;
	}
	gungame_leading_level = GunGame_GetPlayerLevel(gungame_leading_player);
	gungame_leading_weapon = GunGame_GetWeapon(gungame_leading_level);
	GunGame_UpdateStats();
	//PrintToChatAll(strcat(gungame_leading_player.netname,
	//	" is leading with level ", ftos(gungame_leading_level)));
}

void GunGame_UpdateStats()
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		STAT(GUNGAME_LEADING_WEAPON, it) = gungame_leading_weapon.m_id;
	});
}

/// \brief Gives the player a weapon that corresponds to their level.
/// \param[in,out] player Player to give weapon to.
void GunGame_GivePlayerWeapon(entity player)
{
	int level = GunGame_GetPlayerLevel(player);
	if (level >= gungame_max_level)
	{
		return;
	}
	entity weapon = GunGame_GetWeapon(level);
	STAT(WEAPONS, player) |= weapon.m_wepset;
	Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_GUNGAME_NEW_LEVEL,
		level + 1, weapon.m_id);
	Send_Notification(NOTIF_ONE, player, MSG_INFO, INFO_GUNGAME_NEW_LEVEL,
		level + 1, weapon.m_id);
}

//============================= Hooks ========================================

/// \brief Hook that is called to determine if there is a weapon arena.
MUTATOR_HOOKFUNCTION(gg, SetWeaponArena)
{
	//PrintToChatAll("SetWeaponArena");
	M_ARGV(0, string) = "off";
}

/// \brief Hook that is called to determine start items of all players.
MUTATOR_HOOKFUNCTION(gg, SetStartItems)
{
	//PrintToChatAll("SetStartItems");
	start_weapons = WEPSET(Null);
	warmup_start_weapons = WEPSET(Null);
}

/// \brief Hook that is called when an item is about to spawn.
MUTATOR_HOOKFUNCTION(gg, FilterItemDefinition)
{
	//PrintToChatAll("FilterItemDefinition");
	entity item = M_ARGV(0, entity);
	if (item.instanceOfAmmo)
	{
		// Block ammo from spawning.
		return true;
	}
	if (item.instanceOfWeaponPickup)
	{
		// Block weapons from spawning.
		return true;
	}
}

/// \brief Hook that is called when player connects to the server.
MUTATOR_HOOKFUNCTION(gg, ClientConnect)
{
	entity player = M_ARGV(0, entity);
	if (!IS_REAL_CLIENT(player))
	{
		return true;
	}
	STAT(GUNGAME_LEADING_WEAPON, player) = gungame_leading_weapon.m_id;
	return true;
}

MUTATOR_HOOKFUNCTION(gg, reset_map_global)
{
	GunGame_Reset();
}

/// \brief Hook that is called when player spawns.
MUTATOR_HOOKFUNCTION(gg, PlayerSpawn, CBC_ORDER_LAST)
{
	entity player = M_ARGV(0, entity);
	STAT(WEAPONS, player) = WEPSET(Null);
	GunGame_GivePlayerWeapon(player);
	player.items |= IT_UNLIMITED_AMMO;
}

/// \brief Hook which is called when the player tries to throw their weapon.
MUTATOR_HOOKFUNCTION(gg, ForbidThrowCurrentWeapon)
{
	return true;
}

/// \brief Hook that is called when player dies.
MUTATOR_HOOKFUNCTION(gg, PlayerDies)
{
	GunGame_UpdateLeadingPlayer();
	entity attacker = M_ARGV(1, entity);
	if (!IS_PLAYER(attacker) || IS_DEAD(attacker) || (GunGame_GetPlayerLevel(
		attacker) >= gungame_max_level))
	{
		return;
	}
	STAT(WEAPONS, attacker) = WEPSET(Null);
	GunGame_GivePlayerWeapon(attacker);
}

/// \brief Hook that determines whether remaining frags are announced.
MUTATOR_HOOKFUNCTION(gg, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}
