#include "gamemode_survival.qh"

#include <common/mutators/mutator/playertemplates/sv_playertemplates.qh>
#include <common/mutators/mutator/overkill/hmg.qh>
#include <common/mutators/mutator/overkill/rpc.qh>

//============================ Constants ======================================

const int SURVIVAL_TEAM_1_BIT = BIT(0); ///< Bitmask of the first team.
const int SURVIVAL_TEAM_2_BIT = BIT(1); ///< Bitmask of the second team.

/// \brief Used when bitfield team count is requested.
const int SURVIVAL_TEAM_BITS = 3;

enum
{
	SURVIVAL_TYPE_COOP, ///< All humans are on the defender team.
	SURVIVAL_TYPE_VERSUS ///< Humans take turns between attackers and defenders.
};

const string SURVIVAL_TYPE_COOP_VALUE = "coop"; ///< Cvar value for coop.
const string SURVIVAL_TYPE_VERSUS_VALUE = "versus"; ///< Cvar value for versus.

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
	SURVIVAL_ROLE_PLAYER, ///< Player is an attacker or defender.
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
/// \brief If set, defenders will not be shown on the radar.
int autocvar_g_surv_stealth;

/// \brief Whether to force overkill player models for attackers.
int autocvar_g_surv_attacker_force_overkill_models;
/// \brief Whether to force overkill player models for defenders.
int autocvar_g_surv_defender_force_overkill_models;
/// \brief Whether to force overkill player models for cannon fodder.
int autocvar_g_surv_cannon_fodder_force_overkill_models;

/// \brief How much score attackers gain per 1 point of damage.
float autocvar_g_surv_attacker_damage_score;

/// \brief How much score attackers get for fragging defenders.
float autocvar_g_surv_attacker_frag_score;

/// \brief How much health do defenders get when they frag an attacker.
int autocvar_g_surv_defender_attacker_frag_health;
/// \brief How much armor do defenders get when they frag an attacker.
int autocvar_g_surv_defender_attacker_frag_armor;
/// \brief How many shells do defenders get when they frag an attacker.
int autocvar_g_surv_defender_attacker_frag_shells;
/// \brief How many bullets do defenders get when they frag an attacker.
int autocvar_g_surv_defender_attacker_frag_bullets;
/// \brief How many rockets do defenders get when they frag an attacker.
int autocvar_g_surv_defender_attacker_frag_rockets;
/// \brief How many cells do defenders get when they frag an attacker.
int autocvar_g_surv_defender_attacker_frag_cells;
/// \brief How much health do defenders get when they frag cannon fodder.
int autocvar_g_surv_defender_cannon_fodder_frag_health;
/// \brief How much armor do defenders get when they frag cannon fodder.
int autocvar_g_surv_defender_cannon_fodder_frag_armor;
/// \brief How many shells do defenders get when they frag cannon fodder.
int autocvar_g_surv_defender_cannon_fodder_frag_shells;
/// \brief How many bullets do defenders get when they frag cannon fodder.
int autocvar_g_surv_defender_cannon_fodder_frag_bullets;
/// \brief How many rockets do defenders get when they frag cannon fodder.
int autocvar_g_surv_defender_cannon_fodder_frag_rockets;
/// \brief How many cells do defenders get when they frag cannon fodder.
int autocvar_g_surv_defender_cannon_fodder_frag_cells;

/// \brief Whether defenders drop weapons after death.
int autocvar_g_surv_defender_drop_weapons;

/// \brief A stat that is used to track the time left in the round.
.float surv_round_time_stat = _STAT(SURV_ROUND_TIME);
/// \brief A stat that is used to track defender team.
.int surv_defender_team_stat = _STAT(SURV_DEFENDER_TEAM);
/// \brief A stat that is used to track number of defenders alive.
.int surv_defenders_alive_stat = _STAT(SURV_DEFENDERS_ALIVE);
/// \brief A stat that is used to track the total health of defenders.
.float surv_defender_health_stat = _STAT(SURV_DEFENDER_HEALTH);

/// \brief Holds the state of the player. See SURVIVAL_STATE constants.
.int surv_state;
/// \brief Holds the role of the player. See SURVIVAL_ROLE constants.
.int surv_role;
.string surv_savedplayermodel; ///< Initial player model.
.string surv_playermodel; ///< Player model forced by the game.

.entity surv_attack_sprite; ///< Holds the sprite telling attackers to attack.

int surv_type; ///< Holds the type of survival. See SURVIVAL_TYPE constants.
bool surv_warmup; ///< Holds whether warmup is active.
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

int surv_numattackers; ///< Holds the number of players in attacker team.
int surv_numdefenders; ///< Holds the number of players in defender team.

/// \brief Holds the number of humans in attacker team.
int surv_numattackerhumans;
/// \brief Holds the number of humans in defender team.
int surv_numdefenderhumans;

/// \brief Holds the number of attacker players that are alive.
int surv_numattackersalive;
/// \brief Holds the number of defender players that are alive.
int surv_numdefendersalive;

bool surv_autobalance; ///< Holds whether autobalance is active.
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

/// \brief Updates stats of team count on HUD.
/// \return No return.
void Surv_UpdateTeamStats();

/// \brief Updates stats of alive players on HUD.
/// \return No return.
void Surv_UpdateAliveStats();

/// \brief Updates defender health on the HUD.
/// \return No return.
void Surv_UpdateDefenderHealthStat();

//========================= Free functions ====================================

void Surv_Initialize()
{
	switch (cvar_string("g_surv_type"))
	{
		case SURVIVAL_TYPE_COOP_VALUE:
		{
			surv_type = SURVIVAL_TYPE_COOP;
			break;
		}
		case SURVIVAL_TYPE_VERSUS_VALUE:
		{
			surv_type = SURVIVAL_TYPE_VERSUS;
			break;
		}
		default:
		{
			error("Invalid survival type.");
		}
	}
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
	}
	else
	{
		surv_attackerteam = NUM_TEAM_2;
		surv_defenderteam = NUM_TEAM_1;
		surv_attackerteambit = SURVIVAL_TEAM_2_BIT;
		surv_defenderteambit = SURVIVAL_TEAM_1_BIT;
	}
	surv_numattackers = 0;
	surv_numdefenders = 0;
	surv_numattackerhumans = 0;
	surv_numdefenderhumans = 0;
	surv_numattackersalive = 0;
	surv_numdefendersalive = 0;
	surv_autobalance = true;
	surv_allowed_to_spawn = true;
	precache_all_playermodels("models/ok_player/*.dpm");
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

string Surv_GetPlayerTemplate(entity player)
{
	switch (player.team)
	{
		case surv_attackerteam:
		{
			switch (player.surv_role)
			{
				case SURVIVAL_ROLE_NONE:
				case SURVIVAL_ROLE_PLAYER:
				{
					return "surv_attacker";
				}
				case SURVIVAL_ROLE_CANNON_FODDER:
				{
					return "surv_cannon_fodder";
				}
			}
		}
		case surv_defenderteam:
		{
			return "surv_defender";
		}
	}
	return "default";
}

/// \brief Changes the number of players in a team.
/// \param[in] teamnum Team to adjust.
/// \param[in] delta Amount to adjust by.
/// \return No return.
void Surv_ChangeNumberOfPlayers(int teamnum, int delta)
{
	switch (teamnum)
	{
		case surv_attackerteam:
		{
			surv_numattackers += delta;
			LOG_TRACE("Number of attackers = ", ftos(surv_numattackers),
				" was = ", ftos(surv_numattackers - delta));
			Surv_UpdateTeamStats();
			return;
		}
		case surv_defenderteam:
		{
			surv_numdefenders += delta;
			LOG_TRACE("Number of defenders = ", ftos(surv_numdefenders),
				" was = ", ftos(surv_numdefenders - delta));
			Surv_UpdateTeamStats();
			return;
		}
	}
}

/// \brief Changes the number of alive players in a team.
/// \param[in] teamnum Team to adjust.
/// \param[in] delta Amount to adjust by.
/// \return No return.
void Surv_ChangeNumberOfAlivePlayers(int teamnum, int delta)
{
	switch (teamnum)
	{
		case surv_attackerteam:
		{
			surv_numattackersalive += delta;
			LOG_TRACE("Number of alive attackers = ", ftos(
				surv_numattackersalive), " was = ", ftos(surv_numattackersalive
				- delta));
			break;
		}
		case surv_defenderteam:
		{
			surv_numdefendersalive += delta;
			LOG_TRACE("Number of alive defenders = ", ftos(
				surv_numdefendersalive), " was = ", ftos(surv_numdefendersalive
				- delta));
			break;
		}
	}
	Surv_UpdateAliveStats();
	eliminatedPlayers.SendFlags |= 1;
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
			LOG_TRACE(player.netname, " now has no role.");
			break;
		}
		case SURVIVAL_ROLE_PLAYER:
		{
			LOG_TRACE(player.netname, " is now a player.");
			break;
		}
		case SURVIVAL_ROLE_CANNON_FODDER:
		{
			LOG_TRACE(player.netname, " is now a cannon fodder.");
			break;
		}
	}
}

/// \brief Adds player to team. Handles bookkeeping information.
/// \param[in] player Player to add.
/// \param[in] teamnum Team to add to.
/// \return True on success, false otherwise.
bool Surv_AddPlayerToTeam(entity player, int teamnum)
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
				return true;
			}
			if (IS_BOT_CLIENT(player))
			{
				LOG_TRACE("Client is bot");
				LOG_TRACE("Attackers = ", ftos(surv_numattackers));
				if (surv_numattackers < autocvar_g_surv_team_size)
				{
					Surv_SetPlayerRole(player, SURVIVAL_ROLE_PLAYER);
					Surv_ChangeNumberOfPlayers(teamnum, +1);
					return true;
				}
				Surv_SetPlayerRole(player, SURVIVAL_ROLE_CANNON_FODDER);
				return true;
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
					if ((it.team == surv_attackerteam) && (it.surv_role ==
						SURVIVAL_ROLE_PLAYER) && IS_BOT_CLIENT(it))
					{
						LOG_TRACE("Changing ", it.netname,
							" from attacker to cannon fodder.");
						Surv_SetPlayerRole(it, SURVIVAL_ROLE_CANNON_FODDER);
						if (!IS_DEAD(it))
						{
							Surv_ChangeNumberOfAlivePlayers(teamnum, -1);
						}
						Surv_ChangeNumberOfPlayers(teamnum, -1);
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
					return false;
				}
				LOG_TRACE("Removed bot");
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_PLAYER);
			Surv_ChangeNumberOfPlayers(teamnum, +1);
			++surv_numattackerhumans;
			LOG_TRACE("Human attackers = ", ftos(surv_numattackerhumans));
			return true;
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
					Surv_SetPlayerRole(player, SURVIVAL_ROLE_PLAYER);
					Surv_ChangeNumberOfPlayers(teamnum, +1);
					return true;
				}
				LOG_TRACE("No space for defender, switching to attacker");
				SetPlayerTeamSimple(player, surv_attackerteam);
				return false;
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
					if ((it.team == surv_defenderteam) && IS_BOT_CLIENT(it))
					{
						LOG_TRACE("Changing ", it.netname,
							" from defender to cannon fodder.");
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
					return false;
				}
				LOG_TRACE("Removed bot");
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_PLAYER);
			Surv_ChangeNumberOfPlayers(teamnum, +1);
			++surv_numdefenderhumans;
			LOG_TRACE("Human defenders = ", ftos(surv_numdefenderhumans));
			return true;
		}
	}
	player.surv_role = SURVIVAL_ROLE_NONE;
	return false;
}

/// \brief Removes player from team. Handles bookkeeping information.
/// \param[in] player Player to remove.
/// \param[in] Team to remove from.
/// \return No return.
void Surv_RemovePlayerFromTeam(entity player, int teamnum)
{
	LOG_TRACE("Survival: RemovePlayerFromTeam, player: ", player.netname);
	switch (teamnum)
	{
		case surv_attackerteam:
		{
			LOG_TRACE("Attacker team");
			if (player.surv_role == SURVIVAL_ROLE_NONE)
			{
				string message = strcat("RemovePlayerFromTeam: ",
					player.netname, " has invalid role.");
				DebugPrintToChatAll(message);
				return;
			}
			if (player.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
			{
				Surv_SetPlayerRole(player, SURVIVAL_ROLE_NONE);
				return;
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_NONE);
			Surv_ChangeNumberOfPlayers(teamnum, -1);
			if (!IS_BOT_CLIENT(player))
			{
				--surv_numattackerhumans;
			}
			if ((surv_autobalance == false) || (surv_numattackers >=
				surv_numdefenders))
			{
				return;
			}
			// Add bot to keep teams balanced.
			FOREACH_CLIENT(true,
			{
				if (it.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
				{
					LOG_TRACE("Changing ", it.netname,
						" from cannon fodder to attacker.");
					Surv_SetPlayerRole(it, SURVIVAL_ROLE_PLAYER);
					Surv_ChangeNumberOfPlayers(teamnum, +1);
					if (!IS_DEAD(it))
					{
						Surv_ChangeNumberOfAlivePlayers(teamnum, +1);
					}
					return;
				}
			});
			return;
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
			if (player.surv_role != SURVIVAL_ROLE_PLAYER)
			{
				string message = strcat("RemovePlayerFromTeam: ",
					player.netname, " has invalid role.");
				DebugPrintToChatAll(message);
				return;
			}
			Surv_SetPlayerRole(player, SURVIVAL_ROLE_NONE);
			Surv_ChangeNumberOfPlayers(teamnum, -1);
			if (!IS_BOT_CLIENT(player))
			{
				--surv_numdefenderhumans;
			}
			if ((surv_autobalance == false) || (surv_numdefenders >=
				surv_numattackers))
			{
				return;
			}
			// Add bot to keep teams balanced.
			FOREACH_CLIENT(true,
			{
				if (it.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
				{
					LOG_TRACE("Changing ", it.netname,
						" from cannon fodder to defender.");
					SetPlayerTeamSimple(it, surv_defenderteam);						
					return;
				}
			});
			return;
		}
		default:
		{
			LOG_TRACE("Invalid team");
			return;
		}
	}
}

/// \brief Updates stats of team count on HUD.
/// \return No return.
void Surv_UpdateTeamStats()
{
	// Debug stuff
	if (surv_attackerteam == NUM_TEAM_1)
	{
		yellowalive = surv_numattackers;
		pinkalive = surv_numdefenders;
	}
	else
	{
		pinkalive = surv_numattackers;
		yellowalive = surv_numdefenders;
	}
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		it.yellowalive_stat = yellowalive;
		it.pinkalive_stat = pinkalive;
	});
}

/// \brief Adds player to alive list. Handles bookkeeping information.
/// \param[in] player Player to add.
/// \param[in] teamnum Team of the player.
/// \return No return.
void Surv_AddPlayerToAliveList(entity player, int teamnum)
{
	switch (teamnum)
	{
		case surv_attackerteam:
		{
			if (player.surv_role == SURVIVAL_ROLE_PLAYER)
			{
				Surv_ChangeNumberOfAlivePlayers(teamnum, +1);
			}
			return;
		}
		case surv_defenderteam:
		{
			Surv_ChangeNumberOfAlivePlayers(teamnum, +1);
			return;
		}
	}
}

/// \brief Removes player from alive list. Handles bookkeeping information.
/// \param[in] player Player to remove.
/// \param[in] teamnum Team of the player.
/// \return No return.
void Surv_RemovePlayerFromAliveList(entity player, int teamnum)
{
	if (player.surv_attack_sprite)
	{
		WaypointSprite_Kill(player.surv_attack_sprite);
	}
	switch (teamnum)
	{
		case surv_attackerteam:
		{
			if (player.surv_role == SURVIVAL_ROLE_PLAYER)
			{
				Surv_ChangeNumberOfAlivePlayers(teamnum, -1);
			}
			return;
		}
		case surv_defenderteam:
		{
			if (player.surv_role == SURVIVAL_ROLE_CANNON_FODDER)
			{
				// This happens during team switch. We don't need to change
				// anything.
				return;
			}
			Surv_ChangeNumberOfAlivePlayers(teamnum, -1);
			if (warmup_stage || surv_allowed_to_spawn)
			{
				return;
			}
			switch (surv_numdefendersalive)
			{
				case 1:
				{
					sound(NULL, CH_TRIGGER, SND_SURV_1_FRAG_LEFT,
						VOL_BASE, ATTEN_NONE);
					FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
					{
						if (it.team == surv_defenderteam)
						{
							Send_Notification(NOTIF_ONE, it, MSG_CENTER,
								CENTER_ALONE);
							return;
						}
					});
					return;
				}
				case 2:
				{
					sound(NULL, CH_TRIGGER, SND_SURV_2_FRAGS_LEFT,
						VOL_BASE, ATTEN_NONE);
					return;
				}
				case 3:
				{
					sound(NULL, CH_TRIGGER, SND_SURV_3_FRAGS_LEFT,
						VOL_BASE, ATTEN_NONE);
					return;
				}
			}
			return;
		}
	}
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
				if ((it.surv_role == SURVIVAL_ROLE_PLAYER) && !IS_DEAD(it))
				{
					++surv_numattackersalive;
				}
				break;
			}
			case surv_defenderteam:
			{
				if ((it.surv_role == SURVIVAL_ROLE_PLAYER) && !IS_DEAD(it))
				{
					++surv_numdefendersalive;
				}
				break;
			}
		}
	});
	Surv_UpdateAliveStats();
	eliminatedPlayers.SendFlags |= 1;
	if (warmup_stage || surv_allowed_to_spawn || (savednumdefenders <=
		surv_numdefendersalive))
	{
		return;
	}
	switch (surv_numdefendersalive)
	{
		case 1:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_1_FRAG_LEFT, VOL_BASE, ATTEN_NONE);
			FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
			{
				if (it.team == surv_defenderteam)
				{
					Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_ALONE);
					return;
				}
			});
			return;
		}
		case 2:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_2_FRAGS_LEFT, VOL_BASE,
				ATTEN_NONE);
			return;
		}
		case 3:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_3_FRAGS_LEFT, VOL_BASE,
				ATTEN_NONE);
			return;
		}
	}
}

/// \brief Updates stats of alive players on HUD.
/// \return No return.
void Surv_UpdateAliveStats()
{
	// Debug stuff
	if (surv_attackerteam == NUM_TEAM_1)
	{
		redalive = surv_numattackersalive;
		bluealive = surv_numdefendersalive;
	}
	else
	{
		bluealive = surv_numattackersalive;
		redalive = surv_numdefendersalive;
	}
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		it.surv_defenders_alive_stat = surv_numdefendersalive;
		it.redalive_stat = redalive;
		it.bluealive_stat = bluealive;
	});
	Surv_UpdateDefenderHealthStat();
}

/// \brief Updates defender health on the HUD.
/// \return No return.
void Surv_UpdateDefenderHealthStat()
{
	float maxhealth = surv_numdefenders * (PlayerTemplate_GetFloatValue(
		"surv_defender", "start_health") + PlayerTemplate_GetFloatValue(
		"surv_defender", "start_armor"));
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
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
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
	FOREACH_CLIENT(true,
	{
		if (it.surv_attack_sprite)
		{
			WaypointSprite_Kill(it.surv_attack_sprite);
		}
	});
	if (surv_type == SURVIVAL_TYPE_VERSUS)
	{
		Surv_SwitchRoundType();
		round_handler_Init(5, autocvar_g_surv_warmup, surv_timetobeat);
		return;
	}
	round_handler_Init(5, autocvar_g_surv_warmup,
		autocvar_g_surv_round_timelimit);
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
	temp = surv_numattackers;
	surv_numattackers = surv_numdefenders;
	surv_numdefenders = temp;
	temp = surv_numattackerhumans;
	surv_numattackerhumans = surv_numdefenderhumans;
	surv_numdefenderhumans = temp;
	FOREACH_CLIENT(true,
	{
		if ((it.team == surv_defenderteam) && (it.surv_role ==
			SURVIVAL_ROLE_CANNON_FODDER))
		{
			SetPlayerTeamSimple(it, surv_attackerteam);
		}
	});
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		it.surv_defender_team_stat = Team_TeamToNumber(surv_defenderteam);
	});
}

/// \brief Forces the overkill model for specific player.
/// \param[in,out] player Player to force the model of.
/// \return No return.
void Surv_ForceOverkillPlayerModel(entity player)
{
	switch (player.team)
	{
		case NUM_TEAM_1:
		{
			switch (floor(random() * 4))
			{
				case 0:
				{
					player.surv_playermodel = "models/ok_player/okrobot1.dpm";
					return;
				}
				case 1:
				{
					player.surv_playermodel = "models/ok_player/okrobot2.dpm";
					return;
				}
				case 2:
				{
					player.surv_playermodel = "models/ok_player/okrobot3.dpm";
					return;
				}
				case 3:
				{
					player.surv_playermodel = "models/ok_player/okrobot4.dpm";
					return;
				}
			}
			return;
		}
		case NUM_TEAM_2:
		{
			switch (floor(random() * 4))
			{
				case 0:
				{
					player.surv_playermodel = "models/ok_player/okmale1.dpm";
					return;
				}
				case 1:
				{
					player.surv_playermodel = "models/ok_player/okmale2.dpm";
					return;
				}
				case 2:
				{
					player.surv_playermodel = "models/ok_player/okmale3.dpm";
					return;
				}
				case 3:
				{
					player.surv_playermodel = "models/ok_player/okmale4.dpm";
					return;
				}
			}
			return;
		}
	}
}

/// \brief Determines the player model to the one configured for the gamemode.
/// \param[in,out] player Player to determine the model of.
/// \return No return.
void Surv_DeterminePlayerModel(entity player)
{
	switch (player.team)
	{
		case surv_attackerteam:
		{
			switch (player.surv_role)
			{
				case SURVIVAL_ROLE_PLAYER:
				{
					if (!autocvar_g_surv_attacker_force_overkill_models)
					{
						player.surv_playermodel = player.surv_savedplayermodel;
						return;
					}
					Surv_ForceOverkillPlayerModel(player);
					return;
				}
				case SURVIVAL_ROLE_CANNON_FODDER:
				{
					if (!autocvar_g_surv_cannon_fodder_force_overkill_models)
					{
						player.surv_playermodel = player.surv_savedplayermodel;
						return;
					}
					Surv_ForceOverkillPlayerModel(player);
					return;
				}
			}
		}
		case surv_defenderteam:
		{
			if (!autocvar_g_surv_defender_force_overkill_models)
			{
				player.surv_playermodel = player.surv_savedplayermodel;
				return;
			}
			Surv_ForceOverkillPlayerModel(player);
			return;
		}
	}
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
			Send_Notification(NOTIF_ALL, NULL, MSG_CENTER,
				CENTER_SURVIVAL_DEFENDERS_SURVIVED);
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO,
				INFO_SURVIVAL_DEFENDERS_SURVIVED);
			Surv_RoundCleanup();
			return true;
		}
		surv_timetobeat = autocvar_g_surv_round_timelimit;
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER,
			CENTER_SURVIVAL_DEFENDERS_SURVIVED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO,
			INFO_SURVIVAL_DEFENDERS_SURVIVED);
		switch (surv_defenderteam)
		{
			case NUM_TEAM_1:
			{
				sound(NULL, CH_TRIGGER, SND_SURV_RED_SCORES, VOL_BASE,
					ATTEN_NONE);
				break;
			}
			case NUM_TEAM_2:
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
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER,
			CENTER_SURVIVAL_DEFENDERS_ELIMINATED_IN, surv_timetobeat);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO,
			INFO_SURVIVAL_DEFENDERS_ELIMINATED_IN, surv_timetobeat);
		Surv_RoundCleanup();
		return true;
	}
	surv_timetobeat = autocvar_g_surv_round_timelimit;
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER,
		CENTER_SURVIVAL_DEFENDERS_ELIMINATED);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO,
		INFO_SURVIVAL_DEFENDERS_ELIMINATED);
	switch (surv_attackerteam)
	{
		case NUM_TEAM_1:
		{
			sound(NULL, CH_TRIGGER, SND_SURV_RED_SCORES, VOL_BASE,
				ATTEN_NONE);
			break;
		}
		case NUM_TEAM_2:
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
	switch (surv_roundtype)
	{
		case SURVIVAL_ROUND_FIRST:
		{
			FOREACH_CLIENT(IS_PLAYER(it),
			{
				if (it.team == surv_attackerteam)
				{
					Send_Notification(NOTIF_TEAM, it, MSG_CENTER,
						CENTER_SURVIVAL_1ST_ROUND_ATTACKER);
					Send_Notification(NOTIF_TEAM, it, MSG_INFO,
						INFO_SURVIVAL_1ST_ROUND_ATTACKER);
					break;
				}
			});
			FOREACH_CLIENT(IS_PLAYER(it),
			{
				if (it.team == surv_defenderteam)
				{
					if (surv_type == SURVIVAL_TYPE_COOP)
					{
						Send_Notification(NOTIF_TEAM, it, MSG_CENTER,
							CENTER_SURVIVAL_COOP_DEFENDER);
						Send_Notification(NOTIF_TEAM, it, MSG_INFO,
							INFO_SURVIVAL_COOP_DEFENDER);
						break;
					}
					Send_Notification(NOTIF_TEAM, it, MSG_CENTER,
						CENTER_SURVIVAL_1ST_ROUND_DEFENDER);
					Send_Notification(NOTIF_TEAM, it, MSG_INFO,
						INFO_SURVIVAL_1ST_ROUND_DEFENDER);
					break;
				}
			});
			break;
		}
		case SURVIVAL_ROUND_SECOND:
		{
			FOREACH_CLIENT(IS_PLAYER(it),
			{
				if (it.team == surv_attackerteam)
				{
					Send_Notification(NOTIF_TEAM, it, MSG_CENTER,
						CENTER_SURVIVAL_2ND_ROUND_ATTACKER, surv_timetobeat);
					Send_Notification(NOTIF_TEAM, it, MSG_INFO,
						INFO_SURVIVAL_2ND_ROUND_ATTACKER, surv_timetobeat);
					break;
				}
			});
			FOREACH_CLIENT(IS_PLAYER(it),
			{
				if (it.team == surv_defenderteam)
				{
					Send_Notification(NOTIF_TEAM, it, MSG_CENTER,
						CENTER_SURVIVAL_2ND_ROUND_DEFENDER, surv_timetobeat);
					Send_Notification(NOTIF_TEAM, it, MSG_INFO,
						INFO_SURVIVAL_2ND_ROUND_DEFENDER, surv_timetobeat);
					break;
				}
			});
			break;
		}
	}
	if (autocvar_g_surv_stealth)
	{
		return;
	}
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		switch (it.team)
		{
			case surv_defenderteam:
			{
				if (it.surv_role == SURVIVAL_ROLE_PLAYER)
				{
					WaypointSprite_Spawn(WP_AssaultDestroy, 0, 0, it, '0 0 64',
						NULL, surv_attackerteam, it, surv_attack_sprite, false,
						RADARICON_OBJECTIVE);
					WaypointSprite_UpdateMaxHealth(it.surv_attack_sprite,
						PlayerTemplate_GetFloatValue("surv_defender",
						"start_health") + PlayerTemplate_GetFloatValue(
						"surv_defender", "start_armor"));
					WaypointSprite_UpdateHealth(it.surv_attack_sprite,
						it.health + it.armorvalue);
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

/// \brief Hook that is called to determine general rules of the game. 
MUTATOR_HOOKFUNCTION(surv, ReadLevelCvars)
{
	surv_warmup = warmup_stage;
}

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
	warmup_start_weapons = WEPSET(Null);
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
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		it.surv_round_time_stat = roundtime;
	});
}

/// \brief Hook that determines which team player can join. This is called
/// before ClientConnect.
MUTATOR_HOOKFUNCTION(surv, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	entity player = M_ARGV(2, entity);
	LOG_TRACE("Survival: CheckAllowedTeams, player = ", player.netname);
	if (!IS_BOT_CLIENT(player))
	{
		if (surv_type == SURVIVAL_TYPE_COOP)
		{
			if (surv_numdefenderhumans < autocvar_g_surv_team_size)
			{
				M_ARGV(0, float) = surv_defenderteambit;
				return;
			}
			M_ARGV(0, float) = 0;
			return;
		}
		int teambits = 0;
		if (surv_numattackerhumans < autocvar_g_surv_team_size)
		{
			teambits |= surv_attackerteambit;
		}
		if (surv_allowed_to_spawn && (surv_numdefenderhumans <
			autocvar_g_surv_team_size))
		{
			teambits |= surv_defenderteambit;
		}
		M_ARGV(0, float) = teambits;
		return;
	}
	int teambits = surv_attackerteambit;
	if ((player.team == surv_defenderteam) || (surv_numdefenders <
		autocvar_g_surv_team_size))
	{
		teambits |= surv_defenderteambit;
	}
	M_ARGV(0, float) = teambits;
}

/// \brief Hook that determines the best team for the player to join.
MUTATOR_HOOKFUNCTION(surv, JoinBestTeam, CBC_ORDER_EXCLUSIVE)
{
	if (surv_type == SURVIVAL_TYPE_COOP)
	{
		return;
	}
	entity player = M_ARGV(0, entity);
	if (IS_BOT_CLIENT(player))
	{
		return;
	}
	int numattackerhumans = surv_numattackerhumans;
	int numdefenderhumans = surv_numdefenderhumans;
	if (player.team == surv_attackerteam)
	{
		--numattackerhumans;
	}
	else if (player.team == surv_defenderteam)
	{
		--numdefenderhumans;
	}
	if (numattackerhumans < numdefenderhumans)
	{
		M_ARGV(1, float) = Team_TeamToNumber(surv_attackerteam);
		return;
	}
	if (numattackerhumans > numdefenderhumans)
	{
		M_ARGV(1, float) = Team_TeamToNumber(surv_defenderteam);
		return;
	}
	M_ARGV(1, float) = floor(random() * 2) + 1;
}

/// \brief Hook that is called when player has changed the team.
MUTATOR_HOOKFUNCTION(surv, Player_ChangedTeam)
{
	entity player = M_ARGV(0, entity);
	int oldteam = M_ARGV(1, float);
	int newteam = M_ARGV(2, float);
	string message = strcat("Survival: Player_ChangedTeam, ", player.netname,
		", old team = ", ftos(oldteam), " new team = ", ftos(newteam));
	LOG_TRACE(message);
	DebugPrintToChatAll(message);
	if ((oldteam != -1) && IS_PLAYER(player) && !IS_DEAD(player))
	{
		Surv_RemovePlayerFromAliveList(player, oldteam);
	}
	Surv_RemovePlayerFromTeam(player, oldteam);
	if (Surv_AddPlayerToTeam(player, newteam) == false)
	{
		return;
	}
	//Surv_CountAlivePlayers();
	if ((oldteam != -1) && IS_PLAYER(player) && !IS_DEAD(player))
	{
		Surv_AddPlayerToAliveList(player, newteam);
	}
}

/// \brief Hook that is called when player connects to the server.
MUTATOR_HOOKFUNCTION(surv, ClientConnect)
{
	entity player = M_ARGV(0, entity);
	LOG_TRACE("Survival: ClientConnect, player = ", player.netname);
	player.surv_savedplayermodel = player.playermodel;
	if (IS_REAL_CLIENT(player))
	{
		player.surv_defender_team_stat = Team_TeamToNumber(surv_defenderteam);
		player.surv_defenders_alive_stat = surv_numdefendersalive;
		player.redalive_stat = redalive;
		player.bluealive_stat = bluealive;
		player.yellowalive_stat = yellowalive;
		player.pinkalive_stat = pinkalive;
	}
	if (player.surv_role == SURVIVAL_ROLE_NONE)
	{
		Surv_AddPlayerToTeam(player, player.team);
	}
	return true;
}

/// \brief Hook that is called when player disconnects from the server.
MUTATOR_HOOKFUNCTION(surv, ClientDisconnect)
{
    entity player = M_ARGV(0, entity);
	if (!IS_DEAD(player))
	{
		Surv_RemovePlayerFromAliveList(player, player.team);
	}
	Surv_RemovePlayerFromTeam(player, player.team);
	//Surv_CountAlivePlayers();
}

MUTATOR_HOOKFUNCTION(surv, PutClientInServer)
{
	entity player = M_ARGV(0, entity);
	LOG_TRACE("Survival: PutClientInServer, player = ", player.netname);
	if (!Surv_CanPlayerSpawn(player) && IS_PLAYER(player))
	{
		TRANSMUTE(Observer, player);
	}
}

MUTATOR_HOOKFUNCTION(surv, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);
	LOG_TRACE("Survival: MakePlayerObserver, player = ", player.netname);
	if (player.killindicator_teamchange == -2) // player wants to spectate
	{
		LOG_TRACE("killindicator_teamchange == -2");
		player.surv_state = SURVIVAL_STATE_NOT_PLAYING;
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
	LOG_TRACE("Survival: ForbidSpawn, player = ", player.netname);
	if (player.surv_state == SURVIVAL_STATE_NOT_PLAYING)
	{
		return false;
	}
	return !Surv_CanPlayerSpawn(player);
}

MUTATOR_HOOKFUNCTION(surv, reset_map_global)
{
	LOG_TRACE("Survival: reset_map_global");
	surv_allowed_to_spawn = true;
	if (surv_roundtype == SURVIVAL_ROUND_FIRST)
	{
		FOREACH_CLIENT(IS_REAL_CLIENT(it),
		{
			it.surv_round_time_stat = 0;
		});
	}
	return true;
}

MUTATOR_HOOKFUNCTION(surv, reset_map_players)
{
	LOG_TRACE("Survival: reset_map_players");
	surv_numattackersalive = 0;
	surv_numdefendersalive = 0;
	if (surv_warmup)
	{
		surv_warmup = false;
	}
	else if (surv_type == SURVIVAL_TYPE_VERSUS)
	{
		Surv_SwapTeams();
	}
	FOREACH_CLIENT(true,
	{
		it.killcount = 0;
		if ((it.surv_state == SURVIVAL_STATE_NOT_PLAYING) && IS_BOT_CLIENT(it))
		{
			it.team = -1;
			it.surv_state = SURVIVAL_STATE_PLAYING;
		}
		if (it.surv_state == SURVIVAL_STATE_PLAYING)
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
	entity player = M_ARGV(0, entity);
	LOG_TRACE("Survival: PlayerSpawn, player = ", player.netname);
	player.surv_state = SURVIVAL_STATE_PLAYING;
	Surv_DeterminePlayerModel(player);
	PlayerTemplate_PlayerSpawn(player, Surv_GetPlayerTemplate(player));
	switch (player.team)
	{
		case surv_attackerteam:
		{
			switch (player.surv_role)
			{
				case SURVIVAL_ROLE_PLAYER:
				{
					Send_Notification(NOTIF_ONE, player, MSG_CENTER,
						CENTER_ASSAULT_ATTACKING);
					break;
				}
				default:
				{
					LOG_TRACE("Survival: PlayerSpawn: Invalid attacker role.");
					break;
				}
			}
			break;
		}
		case surv_defenderteam:
		{
			if (player.surv_role != SURVIVAL_ROLE_PLAYER)
			{
				LOG_TRACE("Survival: PlayerSpawn: ", player.netname,
					" has invalid defender role.");
			}
			Send_Notification(NOTIF_ONE, player, MSG_CENTER,
				CENTER_ASSAULT_DEFENDING);
			break;
		}
	}
	//Surv_CountAlivePlayers();
	Surv_AddPlayerToAliveList(player, player.team);
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
	entity player = M_ARGV(0, entity);
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
			return PlayerTemplate_ItemTouch(player, item,
				Surv_GetPlayerTemplate(player));
		}
		case surv_defenderteam:
		{
			switch (item.classname)
			{
				case "item_strength":
				{
					W_GiveWeapon(player, WEP_HMG.m_id);
					player.superweapons_finished = max(
						player.superweapons_finished, time) +
						autocvar_g_balance_superweapons_time;
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_Strength, VOL_BASE,
						ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				case "item_invincible":
				{
					W_GiveWeapon(player, WEP_RPC.m_id);
					player.superweapons_finished = max(
						player.superweapons_finished, time) +
						autocvar_g_balance_superweapons_time;
					Item_ScheduleRespawn(item);
					sound(player, CH_TRIGGER, SND_Shield, VOL_BASE, ATTEN_NORM);
					return MUT_ITEMTOUCH_RETURN;
				}
				default:
				{
					return PlayerTemplate_ItemTouch(player, item,
						Surv_GetPlayerTemplate(player));
				}
			}
			DebugPrintToChat(player, item.classname);
			return MUT_ITEMTOUCH_RETURN;
		}
	}
	return MUT_ITEMTOUCH_CONTINUE;
}

/// \brief Hook which is called when the player tries to throw their weapon.
MUTATOR_HOOKFUNCTION(surv, ForbidThrowCurrentWeapon)
{
	entity player = M_ARGV(0, entity);
	if (player.team == surv_defenderteam)
	{
		return true;
	}
}

/// \brief Hook which is called when the damage amount must be determined.
MUTATOR_HOOKFUNCTION(surv, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float damage = M_ARGV(4, float);
	M_ARGV(4, float) = PlayerTemplate_Damage_Calculate(frag_attacker,
		Surv_GetPlayerTemplate(frag_attacker), frag_target,
		Surv_GetPlayerTemplate(frag_target), damage);
}

/// \brief Hook which is called when the player was damaged.
MUTATOR_HOOKFUNCTION(surv, PlayerDamaged)
{
	entity target = M_ARGV(1, entity);
	if (target.team != surv_defenderteam)
	{
		return;
	}
	Surv_UpdateDefenderHealthStat();
	entity attacker = M_ARGV(0, entity);
	if ((attacker.team == surv_attackerteam) && (attacker.surv_role ==
		SURVIVAL_ROLE_PLAYER))
	{
		float health = M_ARGV(2, float);
		float armor = M_ARGV(3, float);
		float score = (health + armor) * autocvar_g_surv_attacker_damage_score;
		PlayerScore_Add(attacker, SP_SCORE, score);
	}
	if (autocvar_g_surv_stealth)
	{
		return;
	}
	if (target.health < 1)
	{
		WaypointSprite_Kill(target.surv_attack_sprite);
	}
	else
	{
		WaypointSprite_UpdateHealth(target.surv_attack_sprite, target.health +
			target.armorvalue);
	}
}

/// \brief Hook which is called when the player dies.
MUTATOR_HOOKFUNCTION(surv, PlayerDies)
{
	//DebugPrintToChatAll("PlayerDies");
	entity attacker = M_ARGV(1, entity);
	entity victim = M_ARGV(2, entity);
	if ((attacker.team == surv_defenderteam) &&
		(victim.team == surv_attackerteam))
	{
		switch (victim.surv_role)
		{
			case SURVIVAL_ROLE_PLAYER:
			{
				GivePlayerHealth(attacker,
					autocvar_g_surv_defender_attacker_frag_health);
				GivePlayerArmor(attacker,
					autocvar_g_surv_defender_attacker_frag_armor);
				GivePlayerAmmo(attacker, ammo_shells,
					autocvar_g_surv_defender_attacker_frag_shells);
				GivePlayerAmmo(attacker, ammo_nails,
					autocvar_g_surv_defender_attacker_frag_bullets);
				GivePlayerAmmo(attacker, ammo_rockets,
					autocvar_g_surv_defender_attacker_frag_rockets);
				GivePlayerAmmo(attacker, ammo_cells,
					autocvar_g_surv_defender_attacker_frag_cells);
				break;
			}
			case SURVIVAL_ROLE_CANNON_FODDER:
			{
				GivePlayerHealth(attacker,
					autocvar_g_surv_defender_cannon_fodder_frag_health);
				GivePlayerArmor(attacker,
					autocvar_g_surv_defender_cannon_fodder_frag_armor);
				GivePlayerAmmo(attacker, ammo_shells,
					autocvar_g_surv_defender_cannon_fodder_frag_shells);
				GivePlayerAmmo(attacker, ammo_nails,
					autocvar_g_surv_defender_cannon_fodder_frag_bullets);
				GivePlayerAmmo(attacker, ammo_rockets,
					autocvar_g_surv_defender_cannon_fodder_frag_rockets);
				GivePlayerAmmo(attacker, ammo_cells,
					autocvar_g_surv_defender_cannon_fodder_frag_cells);
				break;
			}
		}
	}
	if ((victim.team == surv_defenderteam) &&
		(autocvar_g_surv_defender_drop_weapons == false))
	{
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity went = weaponentities[slot];
			victim.(went).m_weapon = WEP_Null;
		}
	}
	if (!Surv_CanPlayerSpawn(victim))
	{
		victim.respawn_flags = RESPAWN_SILENT;
		if (IS_BOT_CLIENT(victim))
		{
			bot_clear(victim);
		}
	}
	return true;
}

/// \brief Hook which is called after the player died.
MUTATOR_HOOKFUNCTION(surv, PlayerDied)
{
	//DebugPrintToChatAll("PlayerDied");
	entity player = M_ARGV(0, entity);
	Surv_RemovePlayerFromAliveList(player, player.team);
	//Surv_CountAlivePlayers();
}

/// \brief Hook which is called when player has scored a frag.
MUTATOR_HOOKFUNCTION(surv, GiveFragsForKill, CBC_ORDER_FIRST)
{
	if (surv_type == SURVIVAL_TYPE_COOP)
	{
		return true;
	}
	entity attacker = M_ARGV(0, entity);
	if ((attacker.team == surv_defenderteam) || (attacker.surv_role ==
		SURVIVAL_ROLE_CANNON_FODDER))
	{
		M_ARGV(2, float) = 0;
		return true;
	}
	entity target = M_ARGV(1, entity);
	if ((attacker.surv_role == SURVIVAL_ROLE_PLAYER) && (target.team ==
		surv_defenderteam))
	{
		M_ARGV(2, float) = autocvar_g_surv_attacker_frag_score;
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
