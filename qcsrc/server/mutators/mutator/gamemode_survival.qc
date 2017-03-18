#include "gamemode_survival.qh"

#include <common/mutators/mutator/overkill/hmg.qh>
#include <common/mutators/mutator/overkill/rpc.qh>

//============================ Constants ======================================

const int SURVIVAL_TEAM_1_BIT = BIT(0); ///< Bitmask of the first team.
const int SURVIVAL_TEAM_2_BIT = BIT(1); ///< Bitmask of the second team.

/// \brief Used when bitfield team count is requested.
const int SURVIVAL_TEAM_BITS = 3;

const int SURVIVAL_COLOR_RED = NUM_TEAM_1 - 1; ///< Used to reference the red.
const int SURVIVAL_COLOR_BLUE = NUM_TEAM_2 - 1; ///< Used to reference the blue.

enum
{
	/// \brief First round where there is timelimit set by the server.
	SURVIVAL_ROUND_FIRST,
	/// \brief Second round where defender team tries to survive for the first
	/// round's time.
	SURVIVAL_ROUND_SECOND
};

enum
{
	/// \brief Player is spectating and has no intention of playing.
	SURVIVAL_STATE_NOT_PLAYING,
	/// \brief Player is playing the game.
	SURVIVAL_STATE_PLAYING = 1
};

enum
{
	SURVIVAL_ROLE_NONE, ///< Player is not playing.
	SURVIVAL_ROLE_ATTACKER, ///< Player is an attacker.
	SURVIVAL_ROLE_DEFENDER, ///< Player is a defender.
	SURVIVAL_ROLE_CANNON_FODDER ///< Player is a cannon fodder.
};

SOUND(SURV_3_FRAGS_LEFT, "announcer/default/3fragsleft");
SOUND(SURV_2_FRAGS_LEFT, "announcer/default/2fragsleft");
SOUND(SURV_1_FRAG_LEFT, "announcer/default/1fragleft");

SOUND(SURV_RED_SCORES, "ctf/red_capture");
SOUND(SURV_BLUE_SCORES, "ctf/blue_capture");

//======================= Global variables ====================================

float autocvar_g_surv_warmup; ///< Warmup time in seconds.
float autocvar_g_surv_round_timelimit; ///< First round time limit in seconds.

int autocvar_g_surv_point_limit; ///< Maximum number of points.
int autocvar_g_surv_point_leadlimit; ///< Maximum lead of a single team.

/// \brief How much players are allowed in teams (excluding cannon fodder).
int autocvar_g_surv_team_size;

/// \brief How much health do defenders get during spawn.
int autocvar_g_surv_defender_start_health;
/// \brief How much armor do defenders get during spawn.
int autocvar_g_surv_defender_start_armor;
/// \brief How many shells do defenders get during spawn.
int autocvar_g_surv_defender_start_ammo_shells;
/// \brief How many bullets do defenders get during spawn.
int autocvar_g_surv_defender_start_ammo_bullets;
/// \brief How many rockets do defenders get during spawn.
int autocvar_g_surv_defender_start_ammo_rockets;
/// \brief How many cells do defenders get during spawn.
int autocvar_g_surv_defender_start_ammo_cells;

/// \brief How many shells do defenders get when they pickup small health/armor.
int autocvar_g_surv_defender_pickup_shells_small;
/// \brief How many shells do defenders get when they pickup medium
/// health/armor.
int autocvar_g_surv_defender_pickup_shells_medium;
/// \brief How many shells do defenders get when they pickup big health/armor.
int autocvar_g_surv_defender_pickup_shells_big;
/// \brief How many shells do defenders get when they pickup mega health/armor.
int autocvar_g_surv_defender_pickup_shells_mega;
/// \brief How many bullets do defenders get when they pickup small
/// health/armor.
int autocvar_g_surv_defender_pickup_bullets_small;
/// \brief How many bullets do defenders get when they pickup medium
/// health/armor.
int autocvar_g_surv_defender_pickup_bullets_medium;
/// \brief How many bullets do defenders get when they pickup big health/armor.
int autocvar_g_surv_defender_pickup_bullets_big;
/// \brief How many bullets do defenders get when they pickup mega health/armor.
int autocvar_g_surv_defender_pickup_bullets_mega;
/// \brief How many rockets do defenders get when they pickup small
/// health/armor.
int autocvar_g_surv_defender_pickup_rockets_small;
/// \brief How many rockets do defenders get when they pickup medium
/// health/armor.
int autocvar_g_surv_defender_pickup_rockets_medium;
/// \brief How many rockets do defenders get when they pickup big health/armor.
int autocvar_g_surv_defender_pickup_rockets_big;
/// \brief How many rockets do defenders get when they pickup mega health/armor.
int autocvar_g_surv_defender_pickup_rockets_mega;
/// \brief How many cells do defenders get when they pickup small health/armor.
int autocvar_g_surv_defender_pickup_cells_small;
/// \brief How many cells do defenders get when they pickup medium health/armor.
int autocvar_g_surv_defender_pickup_cells_medium;
/// \brief How many cells do defenders get when they pickup big health/armor.
int autocvar_g_surv_defender_pickup_cells_big;
/// \brief How many cells do defenders get when they pickup mega health/armor.
int autocvar_g_surv_defender_pickup_cells_mega;

/// \brief How much defenders damage others. Higher values mean more damage.
float autocvar_g_surv_defender_attack_scale;
/// \brief How much defenders get damaged. High values mean less damage.
float autocvar_g_surv_defender_defense_scale;
/// \brief How much cannon fodder damages others. Higher values mean more
/// damage.
float autocvar_g_surv_cannon_fodder_attack_scale;
/// \brief How much cannon fodder gets damaged. Higher values mean less damage.
float autocvar_g_surv_cannon_fodder_defense_scale;

/// \brief A stat that is used to track the time left in the round.
.float surv_round_time_stat = _STAT(SURV_ROUND_TIME);
/// \brief A stat that is used to track the total health of defenders.
.float surv_defender_health_stat = _STAT(SURV_DEFENDER_HEALTH);

/// \brief Holds the state of the player. See SURVIVAL_STATE constants.
.int surv_state;
/// \brief Holds the role of the player. See SURVIVAL_ROLE constants.
.int surv_role;
.string surv_savedplayermodel; ///< Initial player model.
.string surv_playermodel; ///< Player model forced by the game.

.entity surv_attack_sprite; ///< Holds the sprite telling attackers to attack.

/// \brief Holds the type of the current round. See SURVIVAL_ROUND constants.
int surv_roundtype;
bool surv_isroundactive; ///< Holds whether the round is active.
float surv_roundstarttime; ///< Holds the time of the round start.
/// \brief Holds the time needed to survive in the second round.
float surv_timetobeat;

int surv_attackerteam; ///< Holds the attacker team.
int surv_defenderteam; ///< Holds the defender team.

int surv_attackerteambit; ///< Hols the attacker team bitmask.
int surv_defenderteambit; ///< Holds the defender team bitmask.

int surv_attackercolor; ///< Holds the color of attackers.
int surv_defendercolor; ///< Holds the color of defenders.

int surv_numattackers = 0; ///< Holds the number of players in attacker team.
int surv_numdefenders = 0; ///< Holds the number of players in defender team.

/// \brief Holds the number of humans in attacker team.
int surv_numattackerhumans = 0;
/// \brief Holds the number of humans in defender team.
int surv_numdefenderhumans = 0;

/// \brief Holds the number of attacker players that are alive.
int surv_numattackersalive = 0;
/// \brief Holds the number of defender players that are alive.
int surv_numdefendersalive = 0;

bool surv_autobalance = true; ///< Holds whether autobalance is active.
bool surv_allowed_to_spawn; ///< Holds whether players are allowed to spawn.

//====================== Forward declarations =================================

/// \brief Determines whether the round can start.
/// \return True if the round can start, false otherwise.
bool Surv_CanRoundStart();

/// \brief Determines whether the round can end.
/// \return True if the round can end, false otherwise.
bool Surv_CanRoundEnd();

/// \brief Called when the round starts.
/// \return No return.
void Surv_RoundStart();

/// \brief Returns whether player has been eliminated.
/// \param[in] player Player to check.
/// \return True if player is eliminated, false otherwise.
bool Surv_IsEliminated(entity player);

/// \brief Updates stats of alive players on HUD.
/// \return No return.
void Surv_UpdateAliveStats();

/// \brief Updates defender health on the HUD.
/// \return No return.
void Surv_UpdateDefenderHealthStat();

//========================= Free functions ====================================

void Surv_Initialize()
{
	surv_roundtype = SURVIVAL_ROUND_FIRST;
	surv_isroundactive = false;
	surv_roundstarttime = time;
	surv_timetobeat = autocvar_g_surv_round_timelimit;
	if (random() < 0.5)
	{
		surv_attackerteam = NUM_TEAM_1;
		surv_defenderteam = NUM_TEAM_2;
		surv_attackerteambit = SURVIVAL_TEAM_1_BIT;
		surv_defenderteambit = SURVIVAL_TEAM_2_BIT;
		surv_attackercolor = SURVIVAL_COLOR_RED;
		surv_defendercolor = SURVIVAL_COLOR_BLUE;
	}
	else
	{
		surv_attackerteam = NUM_TEAM_2;
		surv_defenderteam = NUM_TEAM_1;
		surv_attackerteambit = SURVIVAL_TEAM_2_BIT;
		surv_defenderteambit = SURVIVAL_TEAM_1_BIT;
		surv_attackercolor = SURVIVAL_COLOR_BLUE;
		surv_defendercolor = SURVIVAL_COLOR_RED;
	}
	surv_allowed_to_spawn = true;
	precache_all_playermodels("models/ok_player/*.dpm");
	WEP_RPC.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;
	WEP_HMG.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;
	ScoreRules_basics(SURVIVAL_TEAM_BITS, SFL_SORT_PRIO_PRIMARY, 0, true);
	ScoreInfo_SetLabel_TeamScore(1, "rounds", SFL_SORT_PRIO_PRIMARY);
	ScoreRules_basics_end();
	round_handler_Spawn(Surv_CanRoundStart, Surv_CanRoundEnd, Surv_RoundStart);
	round_handler_Init(5, autocvar_g_surv_warmup, surv_timetobeat);
	EliminatedPlayers_Init(Surv_IsEliminated);
	ActivateTeamplay();
	SetLimits(autocvar_g_surv_point_limit, autocvar_g_surv_point_leadlimit,
		autocvar_timelimit_override, -1);
}

/// \brief Sets the player role.
/// \param[in,out] player Player to adjust.
/// \param[in] role Role to set.
/// \return No return.
void Surv_SetPlayerRole(entity player, int role)
{
	if (player.surv_role == role)
	{
		return;
	}
	player.surv_role = role;
	switch (role)
	{
		case SURVIVAL_ROLE_NONE:
		{
			string message = strcat(player.netname, " now has no role.");
			LOG_TRACE(message);
			break;
		}
		case SURVIVAL_ROLE_ATTACKER:
		{
			string message = strcat(player.netname, " is now an attacker.");
			LOG_TRACE(message);
			if (!IS_BOT_CLIENT(player))
			{
				PrintToChat(player, "You are now an attacker.");
			}
			break;
		}
		case SURVIVAL_ROLE_DEFENDER:
		{
			string message = strcat(player.netname, " is now a defender.");
			LOG_TRACE(message);
			if (!IS_BOT_CLIENT(player))
			{
				PrintToChat(player, "You are now a defender.");
			}
			break;
		}
		case SURVIVAL_ROLE_CANNON_FODDER:
		{
			string message = strcat(player.netname, " is now a cannon fodder.");
			LOG_TRACE(message);
			break;
		}
	}
}

/// \brief Adds player to team. Handles bookkeeping information.
/// \param[in] player Player to add.
/// \param[in] teamnum Team to add to.
/// \return No return.
void Surv_AddPlayerToTeam(entity player, int teamnum)
{
	LOG_TRACE("Survival: AddPlayerToTeam, player: ", player.netname);
	switch (teamnum)
	{
		case surv_attackerteam:
		{
			LOG_TRACE("Attacker team");
			if (player.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
			{
				LOG_TRACE("Cannon fodder is switching team");
				return;
			}
			if (IS_BOT_CLIENT(player))
			{
				LOG_TRACE("Client is bot");
				LOG_TRACE("Attackers = ", ftos(surv_numattackers));
				if (surv_numattackers < autocvar_g_surv_team_size)
				{
					Surv_SetPlayerRole(player, SURVIVAL_ROLE_ATTACKER);
					++surv_numattackers;
					LOG_TRACE("Numattackers = ", ftos(surv_numattackers));
					return;
				}
				Surv_SetPlayerRole(player, SURVIVAL_ROLE_CANNON_FODDER);
				return;
			}
			LOG_TRACE("Client is not a bot");
			LOG_TRACE("Attackers = ", ftos(surv_numattackers));
			if (surv_numattackers >= autocvar_g_surv_team_size)
			{
				LOG_TRACE("Removing bot");
				// Remove bot to make space for human.
				bool removedbot = false;
				surv_autobalance = false;
				FOREACH_CLIENT(true,
				{
					if ((it.surv_role == SURVIVAL_ROLE_ATTACKER) &&
						IS_BOT_CLIENT(it))
					{
						Surv_SetPlayerRole(it, SURVIVAL_ROLE_CANNON_FODDER);
						--surv_numattackers;
						removedbot = true;
						break;
					}
				});
				surv_autobalance = true;
				if (!removedbot)
				{
					LOG_TRACE("No valid bot to remove");
					// No space in team, denying team change.
					TRANSMUTE(Spectator, player);
					return;
				}
				LOG_TRACE("Removed bot");
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_ATTACKER);
			++surv_numattackers;
			++surv_numattackerhumans;
			LOG_TRACE("Numattackers = ", ftos(surv_numattackers),
				" human attackers = ", ftos(surv_numattackerhumans));
			return;
		}
		case surv_defenderteam:
		{
			LOG_TRACE("Defender team");
			if (IS_BOT_CLIENT(player))
			{
				LOG_TRACE("Client is bot");
				LOG_TRACE("Defenders = ", ftos(surv_numdefenders));
				if (surv_numdefenders < autocvar_g_surv_team_size)
				{
					Surv_SetPlayerRole(player, SURVIVAL_ROLE_DEFENDER);
					++surv_numdefenders;
					LOG_TRACE("Numdefenders = ", ftos(surv_numdefenders));
					return;
				}
				LOG_TRACE("No space for defender, switching to attacker");
				SetPlayerTeamSimple(player, surv_attackerteam);
				return;
			}
			LOG_TRACE("Client is not a bot");
			LOG_TRACE("Defenders = ", ftos(surv_numdefenders));
			if (surv_numdefenders >= autocvar_g_surv_team_size)
			{
				LOG_TRACE("Removing bot");
				// Remove bot to make space for human.
				bool removedbot = false;
				surv_autobalance = false;
				FOREACH_CLIENT(true,
				{
					if ((it.surv_role == SURVIVAL_ROLE_DEFENDER) &&
						IS_BOT_CLIENT(it))
					{
						LOG_TRACE("Removing bot ", it.netname);
						SetPlayerTeamSimple(it, surv_attackerteam);
						removedbot = true;
						break;
					}
				});
				surv_autobalance = true;
				if (!removedbot)
				{
					LOG_TRACE("No valid bot to remove");
					// No space in team, denying team change.
					TRANSMUTE(Spectator, player);
					return;
				}
				LOG_TRACE("Removed bot");
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_DEFENDER);
			++surv_numdefenders;
			++surv_numdefenderhumans;
			LOG_TRACE("Numdefenders = ", ftos(surv_numdefenders),
				" human defenders = ", ftos(surv_numdefenderhumans));
			return;
		}
	}
	player.surv_role = SURVIVAL_ROLE_NONE;
}

/// \brief Removes player from team. Handles bookkeeping information.
/// \param[in] player Player to remove.
/// \param[in] Team to remove from.
/// \return No return.
void Surv_RemovePlayerFromTeam(entity player, int teamnum)
{
	LOG_TRACE("Survival: RemovePlayerFromTeam, player: ", player.netname);
	// TODO: This should be in RemovePlayerFromAliveList.
	if (player.surv_attack_sprite)
	{
		WaypointSprite_Kill(player.surv_attack_sprite);
	}
	switch (teamnum)
	{
		case surv_attackerteam:
		{
			LOG_TRACE("Attacker team");
			if (player.surv_role != SURVIVAL_ROLE_ATTACKER)
			{
				if (player.surv_role != SURVIVAL_ROLE_CANNON_FODDER)
				{
					string message = strcat("RemovePlayerFromTeam: ",
						player.netname, " has invalid role.");
					LOG_TRACE(message);
					FOREACH_CLIENT(true,
					{
						PrintToChat(it, message);
					});
				}
				return;
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_NONE);
			--surv_numattackers;
			LOG_TRACE("Removed attacker. Attackers = ",
				ftos(surv_numattackers));
			if (!IS_BOT_CLIENT(player))
			{
				--surv_numattackerhumans;
			}
			if (surv_autobalance && (surv_numattackers < surv_numdefenders))
			{
				// Add bot to keep teams balanced.
				FOREACH_CLIENT(true,
				{
					if (it.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
					{
						Surv_SetPlayerRole(it, SURVIVAL_ROLE_ATTACKER);
						++surv_numattackers;
						return;
					}
				});
			}
			break;
		}
		case surv_defenderteam:
		{
			LOG_TRACE("Defender team");
			if (player.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
			{
				// This happens during team switch. We don't need to change
				// anything.
				LOG_TRACE("Cannon fodder. Assuming team switch");
				return;
			}
			if (player.surv_role != SURVIVAL_ROLE_DEFENDER)
			{
				string message = strcat("RemovePlayerFromTeam: ",
					player.netname, " has invalid role.");
				LOG_TRACE(message);
				FOREACH_CLIENT(true,
				{
					PrintToChat(it, message);
				});
				return;
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_NONE);
			--surv_numdefenders;
			LOG_TRACE("Removed defender. Defenders = ",
				ftos(surv_numdefenders));
			if (!IS_BOT_CLIENT(player))
			{
				--surv_numdefenderhumans;
			}
			if (surv_autobalance && (surv_numdefenders < surv_numattackers))
			{
				// Add bot to keep teams balanced.
				FOREACH_CLIENT(true,
				{
					if (it.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
					{
						SetPlayerTeamSimple(it, surv_defenderteam);						
						return;
					}
				});
			}
			break;
		}
		default:
		{
			LOG_TRACE("Invalid team");
			break;
		}
	}
}

/// \brief Adds player to alive list. Handles bookkeeping information.
/// \param[in] player Player to add.
/// \param[in] t Team of the player.
/// \return No return.
void Surv_AddPlayerToAliveList(entity player, int t)
{
	switch (t)
	{
		case surv_attackerteam:
		{
			if (player.surv_role == SURVIVAL_ROLE_ATTACKER)
			{
				++surv_numattackersalive;
				LOG_TRACE("SURVIVAL: Added alive attacker, total = ", ftos(
					surv_numattackersalive));
			}
			break;
		}
		case surv_defenderteam:
		{
			++surv_numdefendersalive;
			LOG_TRACE("SURVIVAL: Added alive defender, total = ", ftos(
					surv_numdefendersalive));
			break;
		}
	}
	Surv_UpdateAliveStats();
}

/// \brief Removes player from alive list. Handles bookkeeping information.
/// \param[in] player Player to remove.
/// \return No return.
void Surv_RemovePlayerFromAliveList(entity player)
{
	switch (player.team)
	{
		case surv_attackerteam:
		{
			if (player.surv_role == SURVIVAL_ROLE_ATTACKER)
			{
				--surv_numattackersalive;
				LOG_TRACE("SURVIVAL: Removed alive attacker, total = ", ftos(
					surv_numattackersalive));
			}
			break;
		}
		case surv_defenderteam:
		{
			--surv_numdefendersalive;
			LOG_TRACE("SURVIVAL: Removed alive defender, total = ", ftos(
					surv_numdefendersalive));
			switch (surv_numdefendersalive)
			{
				case 1:
				{
					sound(NULL, CH_TRIGGER, SND_SURV_1_FRAG_LEFT,
						VOL_BASE, ATTEN_NONE);
					break;
				}
				case 2:
				{
					sound(NULL, CH_TRIGGER, SND_SURV_2_FRAGS_LEFT,
						VOL_BASE, ATTEN_NONE);
					break;
				}
				case 3:
				{
					sound(NULL, CH_TRIGGER, SND_SURV_3_FRAGS_LEFT,
						VOL_BASE, ATTEN_NONE);
					break;
				}
			}
			break;
		}
	}
	Surv_UpdateAliveStats();
}

/// \brief Counts alive players.
/// \return No return.
/// \note In a perfect world this function shouldn't exist. However, since QC
/// code is so bad and spurious mutators can really mess with your code, this
/// function is called as a last resort.
void Surv_CountAlivePlayers()
{
	int savednumdefenders = surv_numdefendersalive;
	surv_numattackersalive = 0;
	surv_numdefendersalive = 0;
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		switch (it.team)
		{
			case surv_attackerteam:
			{
				if ((it.surv_role == SURVIVAL_ROLE_ATTACKER) && !IS_DEAD(it))
				{
					++surv_numattackersalive;
				}
				break;
			}
			case surv_defenderteam:
			{
				if ((it.surv_role == SURVIVAL_ROLE_DEFENDER) && !IS_DEAD(it))
				{
					++surv_numdefendersalive;
				}
				break;
			}
		}
	});
	if (!warmup_stage)
	{
		eliminatedPlayers.SendFlags |= 1;
	}
	Surv_UpdateAliveStats();
	if (warmup_stage || (savednumdefenders == surv_numdefendersalive))
	{
		return;
	}
	switch (surv_numdefendersalive)
	{
		case 1:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_1_FRAG_LEFT, VOL_BASE, ATTEN_NONE);
			break;
		}
		case 2:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_2_FRAGS_LEFT, VOL_BASE,
				ATTEN_NONE);
			break;
		}
		case 3:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_3_FRAGS_LEFT, VOL_BASE,
				ATTEN_NONE);
			break;
		}
	}
}

/// \brief Updates stats of alive players on HUD.
/// \return No return.
void Surv_UpdateAliveStats()
{
	if (surv_attackercolor == SURVIVAL_COLOR_RED)
	{
		redalive = surv_numattackersalive;
		bluealive = surv_numdefendersalive;
		// Debug stuff
		yellowalive = surv_numattackers;
		pinkalive = surv_numdefenders;
	}
	else
	{
		bluealive = surv_numattackersalive;
		redalive = surv_numdefendersalive;
		// Debug stuff
		pinkalive = surv_numattackers;
		yellowalive = surv_numdefenders;
	}
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		it.redalive_stat = redalive;
		it.bluealive_stat = bluealive;
		it.yellowalive_stat = yellowalive;
		it.pinkalive_stat = pinkalive;
	});
	Surv_UpdateDefenderHealthStat();
}

/// \brief Updates defender health on the HUD.
/// \return No return.
void Surv_UpdateDefenderHealthStat()
{
	float maxhealth = surv_numdefenders * (
		autocvar_g_surv_defender_start_health +
		autocvar_g_surv_defender_start_armor);
	float totalhealth = 0;
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		if (it.team == surv_defenderteam)
		{
			totalhealth += it.health;
			totalhealth += it.armorvalue;
		}
	});
	float healthratio;
	if (maxhealth == 0)
	{
		healthratio = 0;
	}
	else
	{
		healthratio = totalhealth / maxhealth;
	}
	FOREACH_CLIENT(true,
	{
		it.surv_defender_health_stat = healthratio;
	});
}

/// \brief Returns whether the player can spawn.
/// \param[in] player Player to check.
/// \return True if the player can spawn, false otherwise.
bool Surv_CanPlayerSpawn(entity player)
{
	if (player.team == surv_attackerteam)
	{
		return true;
	}
	return surv_allowed_to_spawn;
}

/// \brief Switches the round type.
/// \return No return.
void Surv_SwitchRoundType()
{
	switch (surv_roundtype)
	{
		case SURVIVAL_ROUND_FIRST:
		{
			surv_roundtype = SURVIVAL_ROUND_SECOND;
			return;
		}
		case SURVIVAL_ROUND_SECOND:
		{
			surv_roundtype = SURVIVAL_ROUND_FIRST;
			return;
		}
	}
}

/// \brief Cleans up the mess after the round has finished.
/// \return No return.
void Surv_RoundCleanup()
{
	surv_allowed_to_spawn = false;
	surv_isroundactive = false;
	game_stopped = true;
	FOREACH_CLIENT(true, {
		if (it.surv_attack_sprite)
		{
			WaypointSprite_Kill(it.surv_attack_sprite);
		}
	});
	Surv_SwitchRoundType();
	round_handler_Init(5, autocvar_g_surv_warmup, surv_timetobeat);
}

/// \brief Swaps attacker and defender teams.
/// \return No return.
void Surv_SwapTeams()
{
	int temp = surv_attackerteam;
	surv_attackerteam = surv_defenderteam;
	surv_defenderteam = temp;
	temp = surv_attackerteambit;
	surv_attackerteambit = surv_defenderteambit;
	surv_defenderteambit = temp;
	temp = surv_attackercolor;
	surv_attackercolor = surv_defendercolor;
	surv_defendercolor = temp;
	temp = surv_numattackers;
	surv_numattackers = surv_numdefenders;
	surv_numdefenders = temp;
	temp = surv_numattackerhumans;
	surv_numattackerhumans = surv_numdefenderhumans;
	surv_numdefenderhumans = temp;
	FOREACH_CLIENT(true,
	{
		switch (it.team)
		{
			case surv_attackerteam:
			{
				if (it.surv_role == SURVIVAL_ROLE_DEFENDER)
				{
					Surv_SetPlayerRole(it, SURVIVAL_ROLE_ATTACKER);
					break;
				}
				else
				{
					string message = strcat("SwapTeams: ", it.netname,
						" has invalid role.");
					LOG_TRACE(message);
					FOREACH_CLIENT(true,
					{
						PrintToChat(it, message);
					});
				}
				break;
			}
			case surv_defenderteam:
			{
				switch (it.surv_role)
				{
					case SURVIVAL_ROLE_ATTACKER:
					{
						Surv_SetPlayerRole(it, SURVIVAL_ROLE_DEFENDER);
						break;
					}
					case SURVIVAL_ROLE_CANNON_FODDER:
					{
						SetPlayerTeamSimple(it, surv_attackerteam);
						break;
					}
					default:
					{
						string message = strcat("SwapTeams: ", it.netname,
							" has invalid role.");
						LOG_TRACE(message);
						FOREACH_CLIENT(true,
						{
							PrintToChat(it, message);
						});
						break;
					}
				}
				break;
			}
		}
	});
}

/// \brief Gives player shells.
/// \param[in,out] player Player to give shells to.
/// \param[in] amount Amount of shells to give.
/// \return No return.
void Surv_GivePlayerShells(entity player, float amount)
{
	player.ammo_shells = bound(player.ammo_shells, player.ammo_shells + amount,
		g_pickup_shells_max);
}

/// \brief Gives player bullets.
/// \param[in,out] player Player to give bullets to.
/// \param[in] amount Amount of bullets to give.
/// \return No return.
void Surv_GivePlayerBullets(entity player, float amount)
{
	player.ammo_nails = bound(player.ammo_nails, player.ammo_nails + amount,
		g_pickup_nails_max);
}

/// \brief Gives player rockets.
/// \param[in,out] player Player to give rockets to.
/// \param[in] amount Amount of rockets to give.
/// \return No return.
void Surv_GivePlayerRockets(entity player, float amount)
{
	player.ammo_rockets = bound(player.ammo_rockets, player.ammo_rockets +
		amount, g_pickup_rockets_max);
}

/// \brief Gives player cells.
/// \param[in,out] player Player to give cells to.
/// \param[in] amount Amount of cells to give.
/// \return No return.
void Surv_GivePlayerCells(entity player, float amount)
{
	player.ammo_cells = bound(player.ammo_cells, player.ammo_cells + amount,
		g_pickup_cells_max);
}

//=============================== Callbacks ===================================

bool Surv_CanRoundStart()
{
	return (surv_numattackersalive > 0) && (surv_numdefendersalive > 0);
}

bool Surv_CanRoundEnd()
{
	if (warmup_stage)
	{
		return false;
	}
	if((round_handler_GetEndTime() > 0) && (round_handler_GetEndTime() -
		time <= 0))
	{
		if (surv_roundtype == SURVIVAL_ROUND_FIRST)
		{
			surv_timetobeat = time - surv_roundstarttime;
			FOREACH_CLIENT(true,
			{
				centerprint(it, "Defenders have survived.");
				PrintToChat(it, "Defenders have survived.");
			});
			Surv_RoundCleanup();
			return true;
		}
		surv_timetobeat = autocvar_g_surv_round_timelimit;
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(
			surv_defenderteam, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(
			surv_defenderteam, INFO_ROUND_TEAM_WIN));
		switch (surv_defendercolor)
		{
			case SURVIVAL_COLOR_RED:
			{
				sound(NULL, CH_TRIGGER, SND_SURV_RED_SCORES, VOL_BASE,
					ATTEN_NONE);
				break;
			}
			case SURVIVAL_COLOR_BLUE:
			{
				sound(NULL, CH_TRIGGER, SND_SURV_BLUE_SCORES, VOL_BASE,
					ATTEN_NONE);
				break;
			}
		}
		TeamScore_AddToTeam(surv_defenderteam, 1, 1);
		Surv_RoundCleanup();
		return true;
	}
	if (surv_numdefendersalive > 0)
	{
		return false;
	}
	if (surv_roundtype == SURVIVAL_ROUND_FIRST)
	{
		surv_timetobeat = time - surv_roundstarttime;
		string message = strcat("Defenders were eliminated in ^2",
			seconds_tostring(surv_timetobeat), "^7.");
		FOREACH_CLIENT(true,
		{
			centerprint(it, message);
			PrintToChat(it, message);
		});
		Surv_RoundCleanup();
		return true;
	}
	surv_timetobeat = autocvar_g_surv_round_timelimit;
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(
		surv_attackerteam, CENTER_ROUND_TEAM_WIN));
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(surv_attackerteam,
		INFO_ROUND_TEAM_WIN));
	switch (surv_attackercolor)
	{
		case SURVIVAL_COLOR_RED:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_RED_SCORES, VOL_BASE,
				ATTEN_NONE);
			break;
		}
		case SURVIVAL_COLOR_BLUE:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_BLUE_SCORES, VOL_BASE,
				ATTEN_NONE);
			break;
		}
	}
	TeamScore_AddToTeam(surv_attackerteam, 1, 1);
	Surv_RoundCleanup();
	return true;
}

void Surv_RoundStart()
{
	if (warmup_stage)
	{
		surv_allowed_to_spawn = true;
		return;
	}
	surv_isroundactive = true;
	surv_roundstarttime = time;
	surv_allowed_to_spawn = false;
	string attackmessage = "";
	string defendmessage = "";
	switch (surv_roundtype)
	{
		case SURVIVAL_ROUND_FIRST:
		{
			attackmessage = "First round. Eliminate the enemy team as fast as you can.";
			defendmessage = "First round. Defend yourself as long as you can.";
			break;
		}
		case SURVIVAL_ROUND_SECOND:
		{
			attackmessage = strcat(
				"Second round. Eliminate the enemy team in less than ^2",
				seconds_tostring(surv_timetobeat), "^7.");
			defendmessage = strcat("Second round. Defend yourself for ^2",
				seconds_tostring(surv_timetobeat), "^7.");
			break;
		}
	}
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		switch (it.team)
		{
			case surv_attackerteam:
			{
				if (it.surv_role == SURVIVAL_ROLE_ATTACKER)
				{
					centerprint(it, attackmessage);
					PrintToChat(it, attackmessage);
				}
				break;
			}
			case surv_defenderteam:
			{
				if (it.surv_role == SURVIVAL_ROLE_DEFENDER)
				{
					centerprint(it, defendmessage);
					PrintToChat(it, defendmessage);
					WaypointSprite_Spawn(WP_AssaultDestroy, 0, 0, it, '0 0 64',
						NULL, surv_attackerteam, it, surv_attack_sprite, false,
						RADARICON_OBJECTIVE);
					WaypointSprite_UpdateMaxHealth(it.surv_attack_sprite, 100);
					WaypointSprite_UpdateHealth(it.surv_attack_sprite, 100);
				}
				break;
			}
		}
	});
}

bool Surv_IsEliminated(entity player)
{
	switch (player.surv_state)
	{
		case SURVIVAL_STATE_NOT_PLAYING:
		{
			return true;
		}
		case SURVIVAL_STATE_PLAYING:
		{
			if (player.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
			{
				// A hack until proper scoreboard is done.
				return true;
			}
			if ((player.team == surv_defenderteam) && (IS_DEAD(player) ||
				IS_OBSERVER(player)))
			{
				return true;
			}
			return false;
		}
	}
	// Should never reach here
	return true;
}

//============================= Hooks ========================================

/// \brief Hook that is called to determine if there is a weapon arena.
MUTATOR_HOOKFUNCTION(surv, SetWeaponArena)
{
	// Removing any weapon arena.
	M_ARGV(0, string) = "off";
}

/// \brief Hook that is called to determine start items of all players.
MUTATOR_HOOKFUNCTION(surv, SetStartItems)
{
	start_weapons = WEPSET(Null);
}

MUTATOR_HOOKFUNCTION(surv, SV_StartFrame)
{
	if (game_stopped || !surv_isroundactive)
	{
		return;
	}
	float roundtime = 0;
	switch (surv_roundtype)
	{
		case SURVIVAL_ROUND_FIRST:
		{
			roundtime = time - surv_roundstarttime;
			break;
		}
		case SURVIVAL_ROUND_SECOND:
		{
			roundtime = round_handler_GetEndTime() - time;
			break;
		}
	}
	FOREACH_CLIENT(true,
	{
		it.surv_round_time_stat = roundtime;
	});
}

/// \brief Hook that determines which team player can join. This is called
/// before ClientConnect.
MUTATOR_HOOKFUNCTION(surv, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	entity player = M_ARGV(2, entity);
	LOG_TRACE("SURVIVAL: CheckAllowedTeams, player = ", player.netname);
	if (!IS_BOT_CLIENT(player))
	{
		int teambits = 0;
		if (surv_numattackerhumans < autocvar_g_surv_team_size)
		{
			teambits |= surv_attackerteambit;
		}
		if (surv_numdefenderhumans < autocvar_g_surv_team_size)
		{
			teambits |= surv_defenderteambit;
		}
		M_ARGV(0, float) = teambits;
		return;
	}
	int teambits = surv_attackerteambit;
	if (surv_numdefenders < autocvar_g_surv_team_size)
	{
		teambits |= surv_defenderteambit;
	}
	M_ARGV(0, float) = teambits;
}

/// \brief Hook that is called when player has changed the team.
MUTATOR_HOOKFUNCTION(surv, Player_ChangedTeam)
{
	entity player = M_ARGV(0, entity);
	int oldteam = M_ARGV(1, float);
	int newteam = M_ARGV(2, float);
	LOG_TRACE("SURVIVAL: Player_ChangedTeam, ", player.netname, ", old team = ",
		ftos(oldteam), " new team = ", ftos(newteam));
	//FOREACH_CLIENT(true, { centerprint(it, "Player_ChangeTeam"); });
	//if (!IS_DEAD(player))
	//{
	//	surv_RemovePlayerFromAliveList(player);
	//}
	Surv_RemovePlayerFromTeam(player, oldteam);
	Surv_AddPlayerToTeam(player, newteam);
	Surv_CountAlivePlayers();
	//if (IS_PLAYER(player) && !IS_DEAD(player))
	//{
	//	surv_AddPlayerToAliveList(player, newteam);
	//}
}

/// \brief Hook that is called when player connects to the server.
MUTATOR_HOOKFUNCTION(surv, ClientConnect)
{
	entity player = M_ARGV(0, entity);
	LOG_TRACE("SURVIVAL: ClientConnect, player = ", player.netname);
	player.surv_savedplayermodel = player.playermodel;
	return true;
}

/// \brief Hook that is called when player disconnects from the server.
MUTATOR_HOOKFUNCTION(surv, ClientDisconnect)
{
    entity player = M_ARGV(0, entity);
	Surv_CountAlivePlayers();
	//if (!IS_DEAD(player))
	//{
	//	Surv_RemovePlayerFromAliveList(player);
	//}
	Surv_RemovePlayerFromTeam(player, player.team);
}

MUTATOR_HOOKFUNCTION(surv, PutClientInServer)
{
	entity player = M_ARGV(0, entity);
	LOG_TRACE("SURVIVAL: PutClientInServer, player = ", player.netname);
	//if (surv_CanPlayerSpawn(player) && (player.surv_state ==
	//	SURVIVAL_STATE_NOT_PLAYING))
	//{
	//	return;
	//}
	if (!Surv_CanPlayerSpawn(player) && IS_PLAYER(player))
	{
		TRANSMUTE(Observer, player);
	}
}

MUTATOR_HOOKFUNCTION(surv, MakePlayerObserver)
{
	//FOREACH_CLIENT(true, { centerprint(it, "MakePlayerObserver"); });
	//backtrace("SURVIVAL: MakePlayerObserver");
    entity player = M_ARGV(0, entity);
	LOG_TRACE("SURVIVAL: MakePlayerObserver, player = ", player.netname);
	if (player.killindicator_teamchange == -2) // player wants to spectate
	{
		LOG_TRACE("killindicator_teamchange == -2");
		//FOREACH_CLIENT(true, { centerprint(it, "Removing Observer from alive list"); });
		//Surv_CountAlivePlayers();
		//surv_RemovePlayerFromAliveList(player);
		//Surv_RemovePlayerFromTeam(player, player.team);
		player.surv_state = SURVIVAL_STATE_NOT_PLAYING;
	}
	if (!warmup_stage)
	{
		eliminatedPlayers.SendFlags |= 1;
	}
	if (player.surv_state == SURVIVAL_STATE_NOT_PLAYING)
	{
		return false;  // allow team reset
	}
	return true;  // prevent team reset
}

/// \brief Hook that determines whether player can spawn. It is not called for
/// players who have joined the team and are dead.
MUTATOR_HOOKFUNCTION(surv, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);
	LOG_TRACE("SURVIVAL: ForbidSpawn, player = ", player.netname);
	if (player.surv_state == SURVIVAL_STATE_NOT_PLAYING)
	{
		return false;
	}
	return !Surv_CanPlayerSpawn(player);
}

MUTATOR_HOOKFUNCTION(surv, reset_map_global)
{
	LOG_TRACE("SURVIVAL: reset_map_global");
	//FOREACH_CLIENT(true, { centerprint(it, "reset_map_global"); });
	surv_allowed_to_spawn = true;
	surv_numattackersalive = 0;
	surv_numdefendersalive = 0;
	return true;
}

MUTATOR_HOOKFUNCTION(surv, reset_map_players)
{
	LOG_TRACE("SURVIVAL: reset_map_players");
	//FOREACH_CLIENT(true, { centerprint(it, "reset_map_players"); });
	Surv_SwapTeams();
	FOREACH_CLIENT(true, {
		it.killcount = 0;
		if ((it.surv_state == SURVIVAL_STATE_NOT_PLAYING) && IS_BOT_CLIENT(it))
		{
			it.team = -1;
			it.surv_state = SURVIVAL_STATE_PLAYING;
		}
		if (it.surv_state != SURVIVAL_STATE_NOT_PLAYING)
		{
			TRANSMUTE(Player, it);
			it.surv_state = SURVIVAL_STATE_PLAYING;
			PutClientInServer(it);
		}
	});
	bot_relinkplayerlist();
	return true;
}

/// \brief Hook that is called when player spawns.
MUTATOR_HOOKFUNCTION(surv, PlayerSpawn)
{
	//FOREACH_CLIENT(true, { centerprint(it, "PlayerSpawn"); });
	entity player = M_ARGV(0, entity);
	LOG_TRACE("SURVIVAL: PlayerSpawn, player = ", player.netname);
	player.surv_state = SURVIVAL_STATE_PLAYING;
	Surv_CountAlivePlayers();
	//surv_AddPlayerToAliveList(player, player.team);
	//W_GiveWeapon(player, WEP_HMG.m_id);
	//W_GiveWeapon(player, WEP_RPC.m_id);
	switch (player.team)
	{
		case surv_attackerteam:
		{
			player.surv_playermodel = player.surv_savedplayermodel;
			switch (player.surv_role)
			{
				case SURVIVAL_ROLE_ATTACKER:
				{
					FOREACH(Weapons, it != WEP_Null,
					{
						if (it.weaponstart)
						{
							player.weapons |= it.m_wepset;
						}
					});
					for (int i = 0; i < 2; ++i)
					{
						// Finding weapon which player doesn't have.
						vector weaponbit;
						int numattempts = 0;
						do
						{
							weaponbit = WepSet_FromWeapon(Weapons_from(
								floor(random() * 8 + 3)));
							++numattempts;
						}
						while ((player.weapons & weaponbit) &&
							(numattempts < 10));
						player.weapons |= weaponbit;
					}
					player.items |= IT_UNLIMITED_AMMO;
					break;
				}
				case SURVIVAL_ROLE_CANNON_FODDER:
				{
					FOREACH(Weapons, it != WEP_Null,
					{
						if (it.weaponstart)
						{
							player.weapons |= it.m_wepset;
						}
					});
					for (int i = 0; i < 2; ++i)
					{
						// Finding weapon which player doesn't have.
						vector weaponbit;
						int numattempts = 0;
						do
						{
							weaponbit = WepSet_FromWeapon(Weapons_from(
								floor(random() * 8 + 3)));
							++numattempts;
						}
						while ((player.weapons & weaponbit) &&
							(numattempts < 10));
					}
					player.items |= IT_UNLIMITED_AMMO;
					break;
				}
				default:
				{
					centerprint(player, "INVALID ROLE");
					LOG_TRACE("Survival::PlayerSpawn: Invalid attacker role.");
					break;
				}
			}
			break;
		}
		case surv_defenderteam:
		{
			if (player.surv_role != SURVIVAL_ROLE_DEFENDER)
			{
				centerprint(player, "INVALID ROLE");
				LOG_TRACE("Survival::PlayerSpawn: Invalid defender role.");
			}
			switch (surv_defendercolor)
			{
				case SURVIVAL_COLOR_RED:
				{
					switch (floor(random() * 4))
					{
						case 0:
						{
							player.surv_playermodel =
								"models/ok_player/okrobot1.dpm";
							break;
						}
						case 1:
						{
							player.surv_playermodel =
								"models/ok_player/okrobot2.dpm";
							break;
						}
						case 2:
						{
							player.surv_playermodel =
								"models/ok_player/okrobot3.dpm";
							break;
						}
						case 3:
						{
							player.surv_playermodel =
								"models/ok_player/okrobot4.dpm";
							break;
						}
					}
					break;
				}
				case SURVIVAL_COLOR_BLUE:
				{
					switch (floor(random() * 4))
					{
						case 0:
						{
							player.surv_playermodel =
								"models/ok_player/okmale1.dpm";
							break;
						}
						case 1:
						{
							player.surv_playermodel =
								"models/ok_player/okmale2.dpm";
							break;
						}
						case 2:
						{
							player.surv_playermodel =
								"models/ok_player/okmale3.dpm";
							break;
						}
						case 3:
						{
							player.surv_playermodel =
								"models/ok_player/okmale4.dpm";
							break;
						}
					}
					break;
				}
			}
			player.health = autocvar_g_surv_defender_start_health;
			player.armorvalue = autocvar_g_surv_defender_start_armor;
			player.ammo_shells = autocvar_g_surv_defender_start_ammo_shells;
			player.ammo_nails = autocvar_g_surv_defender_start_ammo_bullets;
			player.ammo_rockets = autocvar_g_surv_defender_start_ammo_rockets;
			player.ammo_cells = autocvar_g_surv_defender_start_ammo_cells;
			int numweapons = tokenize_console(cvar_string(
				"g_surv_defender_start_weapons"));
			for (int i = 0; i < numweapons; ++i)
			{
				string weapon = argv(i);
				FOREACH(Weapons, it != WEP_Null,
				{
					if (it.netname == weapon)
					{
						player.weapons |= it.m_wepset;
						//W_GiveWeapon(player, it.m_id);
						break;
					}
				});
			}
			break;
		}
	}
}

/// \brief UGLY HACK. This is called every frame to keep player model correct.
MUTATOR_HOOKFUNCTION(surv, FixPlayermodel)
{
	entity player = M_ARGV(2, entity);
	M_ARGV(0, string) = player.surv_playermodel;
}

/// \brief Hook that is called every frame to determine how player health should
/// regenerate.
MUTATOR_HOOKFUNCTION(surv, PlayerRegen)
{
	entity player = M_ARGV(1, entity);
	if (player.team == surv_defenderteam)
	{
		return true;
	}
	return false;
}

/// \brief Hook that is called to determine if balance messages will appear.
MUTATOR_HOOKFUNCTION(surv, HideTeamNagger)
{
	return true;
}

/// \brief Hook that is called when player touches an item.
MUTATOR_HOOKFUNCTION(surv, ItemTouch)
{
	entity item = M_ARGV(0, entity);
	entity player = M_ARGV(1, entity);
	switch (player.team)
	{
		case surv_attackerteam:
		{
			switch (item.classname)
			{
				case "item_shells":
				case "item_bullets":
				case "item_rockets":
				case "item_cells":
				case "droppedweapon":
				{
					// FIXME: proper health pickup function.
					player.health += g_pickup_healthmedium;
					player.armorvalue += g_pickup_armormedium;
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_ITEMPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
			}
			return MUT_ITEMTOUCH_CONTINUE;
		}
		case surv_defenderteam:
		{
			switch (item.classname)
			{
				case "item_health_small":
				case "item_armor_small":
				{
					Surv_GivePlayerShells(player,
						autocvar_g_surv_defender_pickup_shells_small);
					Surv_GivePlayerBullets(player,
						autocvar_g_surv_defender_pickup_bullets_small);
					Surv_GivePlayerRockets(player,
						autocvar_g_surv_defender_pickup_rockets_small);
					Surv_GivePlayerCells(player,
						autocvar_g_surv_defender_pickup_cells_small);
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthSmall, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "item_health_medium":
				case "item_armor_medium":
				{
					Surv_GivePlayerShells(player,
						autocvar_g_surv_defender_pickup_shells_medium);
					Surv_GivePlayerBullets(player,
						autocvar_g_surv_defender_pickup_bullets_medium);
					Surv_GivePlayerRockets(player,
						autocvar_g_surv_defender_pickup_rockets_medium);
					Surv_GivePlayerCells(player,
						autocvar_g_surv_defender_pickup_cells_medium);
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthMedium, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "item_health_big":
				case "item_armor_big":
				{
					Surv_GivePlayerShells(player,
						autocvar_g_surv_defender_pickup_shells_big);
					Surv_GivePlayerBullets(player,
						autocvar_g_surv_defender_pickup_bullets_big);
					Surv_GivePlayerRockets(player,
						autocvar_g_surv_defender_pickup_rockets_big);
					Surv_GivePlayerCells(player,
						autocvar_g_surv_defender_pickup_cells_big);
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthBig, VOL_BASE, ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "item_health_mega":
				case "item_armor_mega":
				{
					Surv_GivePlayerShells(player,
						autocvar_g_surv_defender_pickup_shells_mega);
					Surv_GivePlayerBullets(player,
						autocvar_g_surv_defender_pickup_bullets_mega);
					Surv_GivePlayerRockets(player,
						autocvar_g_surv_defender_pickup_rockets_mega);
					Surv_GivePlayerCells(player,
						autocvar_g_surv_defender_pickup_cells_mega);
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_HealthMega, VOL_BASE, ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "item_shells":
				case "item_bullets":
				case "item_rockets":
				case "item_cells":
				{
					return MUT_ITEMTOUCH_CONTINUE;
				}
				case "droppedweapon":
				{
					switch (item.weapon)
					{
						case WEP_SHOTGUN.m_id:
						{
							Surv_GivePlayerShells(player, cvar(
								"g_pickup_shells_weapon"));
							break;
						}
						case WEP_MACHINEGUN.m_id:
						{
							Surv_GivePlayerBullets(player, cvar(
								"g_pickup_nails_weapon"));
							break;
						}
						case WEP_MORTAR.m_id:
						case WEP_HAGAR.m_id:
						case WEP_DEVASTATOR.m_id:
						{
							Surv_GivePlayerRockets(player, cvar(
								"g_pickup_rockets_weapon"));
							break;
						}
						case WEP_ELECTRO.m_id:
						case WEP_CRYLINK.m_id:
						case WEP_VORTEX.m_id:
						{
							Surv_GivePlayerCells(player, cvar(
								"g_pickup_cells_weapon"));
							break;
						}
					}
					delete(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "weapon_machinegun":
				case "weapon_uzi":
				{
					Surv_GivePlayerBullets(player, cvar(
						"g_pickup_nails_weapon"));
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "weapon_grenadelauncher":
				case "weapon_hagar":
				case "weapon_rocketlauncher":
				{
					Surv_GivePlayerRockets(player,
						cvar("g_pickup_rockets_weapon"));
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "weapon_electro":
				case "weapon_crylink":
				case "weapon_nex":
				{
					Surv_GivePlayerCells(player, cvar("g_pickup_cells_weapon"));
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_WEAPONPICKUP, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "item_strength":
				{
					W_GiveWeapon(player, WEP_HMG.m_id);
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_Strength, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "item_invincible":
				{
					W_GiveWeapon(player, WEP_RPC.m_id);
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_Shield, VOL_BASE, ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
			}
			centerprint(player, item.classname);
			return MUT_ITEMTOUCH_RETURN;
		}
	}
	return MUT_ITEMTOUCH_CONTINUE;
}

/// \brief Hook which is called when the damage amount must be determined.
MUTATOR_HOOKFUNCTION(surv, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float damage = M_ARGV(4, float);
	switch (frag_attacker.team)
	{
		case surv_attackerteam:
		{
			switch (frag_attacker.surv_role)
			{
				case SURVIVAL_ROLE_CANNON_FODDER:
				{
					damage *= autocvar_g_surv_cannon_fodder_attack_scale;
					break;
				}
			}
			break;
		}
		case surv_defenderteam:
		{
			damage *= autocvar_g_surv_defender_attack_scale;
			break;
		}
	}
	switch (frag_target.team)
	{
		case surv_attackerteam:
		{
			switch (frag_target.surv_role)
			{
				case SURVIVAL_ROLE_CANNON_FODDER:
				{
					damage /= autocvar_g_surv_cannon_fodder_defense_scale;
					break;
				}
			}
			break;
		}
		case surv_defenderteam:
		{
			damage /= autocvar_g_surv_defender_defense_scale;
			break;
		}
	}
	M_ARGV(4, float) = damage;
}

/// \brief Hook which is called when the player was damaged.
MUTATOR_HOOKFUNCTION(surv, PlayerDamaged)
{
	entity target = M_ARGV(1, entity);
	//float health = M_ARGV(2, float);
	if (target.team != surv_defenderteam)
	{
		return;
	}
	Surv_UpdateDefenderHealthStat();
	if (target.health < 1)
	{
		WaypointSprite_Kill(target.surv_attack_sprite);
		return;
	}
	WaypointSprite_UpdateHealth(target.surv_attack_sprite, target.health);
}

//MUTATOR_HOOKFUNCTION(surv, ClientKill)
//{
	//FOREACH_CLIENT(true, { centerprint(it, "ClientKill"); });
	//entity player = M_ARGV(0, entity);
//}

/// \brief Hook which is called when the player dies.
MUTATOR_HOOKFUNCTION(surv, PlayerDies)
{
	//FOREACH_CLIENT(true, { centerprint(it, "PlayerDies"); });
	entity frag_target = M_ARGV(2, entity);
	//surv_RemovePlayerFromAliveList(frag_target);
	if (!Surv_CanPlayerSpawn(frag_target))
	{
		frag_target.respawn_flags = RESPAWN_SILENT;
		if (IS_BOT_CLIENT(frag_target))
		{
			bot_clear(frag_target);
		}
	}
	return true;
}

/// \brief Hook which is called after the player died.
MUTATOR_HOOKFUNCTION(surv, PlayerDied)
{
	Surv_CountAlivePlayers();
}

/// \brief Hook which is called when player has scored a frag.
MUTATOR_HOOKFUNCTION(surv, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity player = M_ARGV(0, entity);
	if ((player.team == surv_defenderteam) || (player.surv_role ==
		SURVIVAL_ROLE_CANNON_FODDER))
	{
		M_ARGV(2, float) = 0;
	}
	return true;
}

/// \brief I'm not sure exactly what this function does but it is very
/// important. Without it bots are completely broken. Is it a hack? Of course.
MUTATOR_HOOKFUNCTION(surv, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (IS_PLAYER(it) || (it.surv_state == SURVIVAL_STATE_PLAYING))
		{
			++M_ARGV(0, int);
		}
		++M_ARGV(1, int);
	});
	return true;
}

MUTATOR_HOOKFUNCTION(surv, Scores_CountFragsRemaining)
{
	// Don't announce remaining frags
	return false;
}

//MUTATOR_HOOKFUNCTION(surv, MatchEnd)
//{
//	surv_numattackers = 0;
//	surv_numdefenders = 0;
//	surv_numattackerhumans = 0;
//	surv_numdefenderhumans = 0;
//	surv_numattackersalive = 0;
//	surv_numdefendersalive = 0;
//	FOREACH_CLIENT(true,
//	{
//		it.surv_role = SURVIVAL_ROLE_NONE;
//	});
//}
