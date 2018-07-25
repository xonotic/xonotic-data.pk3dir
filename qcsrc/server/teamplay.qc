#include "teamplay.qh"

#include "client.qh"
#include "race.qh"
#include "scores.qh"
#include "scores_rules.qh"

#include "bot/api.qh"

#include "command/vote.qh"

#include <server/mutators/_mod.qh>

#include "../common/deathtypes/all.qh"
#include <common/gamemodes/_mod.qh>
#include "../common/teams.qh"

/// \brief Describes a state of team balance entity.
enum
{
	TEAM_BALANCE_UNINITIALIZED, ///< The team balance has not been initialized.
	/// \brief TeamBalance_CheckAllowedTeams has been called.
	TEAM_BALANCE_TEAMS_CHECKED,
	/// \brief TeamBalance_GetTeamCounts has been called.
	TEAM_BALANCE_TEAM_COUNTS_FILLED
};

/// \brief Indicates that the player is not allowed to join a team.
const int TEAM_NOT_ALLOWED = -1;

.int m_team_balance_state; ///< Holds the state of the team balance entity.
.entity m_team_balance_team[NUM_TEAMS]; ///< ???

.float m_team_score; ///< The score of the team.
.int m_num_players; ///< Number of players (both humans and bots) in a team.
.int m_num_bots; ///< Number of bots in a team.
.int m_num_players_alive; ///< Number of alive players in a team.
.int m_num_control_points; ///< Number of control points owned by a team.

entity g_team_entities[NUM_TEAMS]; ///< Holds global team entities.

STATIC_INIT(g_team_entities)
{
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		g_team_entities[i] = spawn();
	}
}

entity Team_GetTeamFromIndex(int index)
{
	if (!Team_IsValidIndex(index))
	{
		LOG_FATALF("Team_GetTeamFromIndex: Index is invalid: %f", index);
	}
	return g_team_entities[index - 1];
}

entity Team_GetTeam(int team_num)
{
	if (!Team_IsValidTeam(team_num))
	{
		LOG_FATALF("Team_GetTeam: Value is invalid: %f", team_num);
	}
	return g_team_entities[Team_TeamToIndex(team_num) - 1];
}

float Team_GetTeamScore(entity team_ent)
{
	return team_ent.m_team_score;
}

void Team_SetTeamScore(entity team_ent, float score)
{
	team_ent.m_team_score = score;
}

int Team_GetNumberOfAlivePlayers(entity team_ent)
{
	return team_ent.m_num_players_alive;
}

void Team_SetNumberOfAlivePlayers(entity team_ent, int number)
{
	team_ent.m_num_players_alive = number;
}

int Team_GetNumberOfAliveTeams()
{
	int result = 0;
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		if (g_team_entities[i].m_num_players_alive > 0)
		{
			++result;
		}
	}
	return result;
}

int Team_GetNumberOfControlPoints(entity team_ent)
{
	return team_ent.m_num_control_points;
}

void Team_SetNumberOfControlPoints(entity team_ent, int number)
{
	team_ent.m_num_control_points = number;
}

int Team_GetNumberOfTeamsWithControlPoints()
{
	int result = 0;
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		if (g_team_entities[i].m_num_control_points > 0)
		{
			++result;
		}
	}
	return result;
}

void setcolor(entity this, int clr)
{
#if 0
	this.clientcolors = clr;
	this.team = (clr & 15) + 1;
#else
	builtin_setcolor(this, clr);
#endif
}

bool Entity_HasValidTeam(entity this)
{
	return Team_IsValidTeam(this.team);
}

int Entity_GetTeamIndex(entity this)
{
	return Team_TeamToIndex(this.team);
}

entity Entity_GetTeam(entity this)
{
	int index = Entity_GetTeamIndex(this);
	if (!Team_IsValidIndex(index))
	{
		return NULL;
	}
	return Team_GetTeamFromIndex(index);
}

void SetPlayerColors(entity player, float _color)
{
	float pants = _color & 0x0F;
	float shirt = _color & 0xF0;
	if (teamplay)
	{
		setcolor(player, 16 * pants + pants);
	}
	else
	{
		setcolor(player, shirt + pants);
	}
}

bool Player_SetTeamIndex(entity player, int index)
{
	int new_team = Team_IndexToTeam(index);
	if (player.team == new_team)
	{
		if (new_team != -1)
		{
			// This is important when players join the game and one of their
			// color matches the team color while other doesn't. For example
			// [BOT]Lion.
			SetPlayerColors(player, new_team - 1);
		}
		return true;
	}
	int old_index = Team_TeamToIndex(player.team);
	if (MUTATOR_CALLHOOK(Player_ChangeTeam, player, old_index, index) == true)
	{
		// Mutator has blocked team change.
		return false;
	}
	if (new_team == -1)
	{
		player.team = -1;
	}
	else
	{
		SetPlayerColors(player, new_team - 1);
	}
	MUTATOR_CALLHOOK(Player_ChangedTeam, player, old_index, index);
	return true;
}

bool SetPlayerTeam(entity player, int team_index, int type)
{
	int old_team_index = Entity_GetTeamIndex(player);
	if (!Player_SetTeamIndex(player, team_index))
	{
		return false;
	}
	LogTeamchange(player.playerid, player.team, type);
	if (team_index != old_team_index)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(player.team,
			INFO_JOIN_PLAY_TEAM), player.netname);
		KillPlayerForTeamChange(player);
	}
	return true;
}

bool MoveToTeam(entity client, int team_index, int type)
{
	//PrintToChatAll(sprintf("MoveToTeam: %s, %f", client.netname, team_index));
	int lockteams_backup = lockteams;  // backup any team lock
	lockteams = 0;  // disable locked teams
	PlayerScore_Clear(client);
	if (!SetPlayerTeam(client, team_index, type))
	{
		lockteams = lockteams_backup;  // restore the team lock
		return false;
	}
	lockteams = lockteams_backup;  // restore the team lock
	return true;
}

void KillPlayerForTeamChange(entity player)
{
	if (IS_DEAD(player))
	{
		return;
	}
	if (MUTATOR_CALLHOOK(Player_ChangeTeamKill, player) == true)
	{
		return;
	}
	Damage(player, player, player, 100000, DEATH_TEAMCHANGE.m_id, DMG_NOWEP,
		player.origin, '0 0 0');
}

void LogTeamchange(float player_id, float team_number, int type)
{
	if(!autocvar_sv_eventlog)
		return;

	if(player_id < 1)
		return;

	GameLogEcho(strcat(":team:", ftos(player_id), ":", ftos(team_number), ":", ftos(type)));
}

entity TeamBalance_CheckAllowedTeams(entity for_whom)
{
	entity balance = spawn();
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		entity team_ent = balance.m_team_balance_team[i] = spawn();
		team_ent.m_team_score = g_team_entities[i].m_team_score;
		team_ent.m_num_players = TEAM_NOT_ALLOWED;
		team_ent.m_num_bots = 0;
	}
	setthink(balance, TeamBalance_Destroy);
	
	int teams_mask = 0;	
	string teament_name = string_null;
	bool mutator_returnvalue = MUTATOR_CALLHOOK(TeamBalance_CheckAllowedTeams,
		teams_mask, teament_name, for_whom);
	teams_mask = M_ARGV(0, float);
	teament_name = M_ARGV(1, string);
	if (mutator_returnvalue)
	{
		for (int i = 0; i < NUM_TEAMS; ++i)
		{
			if (teams_mask & BIT(i))
			{
				balance.m_team_balance_team[i].m_num_players = 0;
			}
		}
	}

	if (teament_name)
	{
		entity head = find(NULL, classname, teament_name);
		while (head)
		{
			if (Team_IsValidTeam(head.team))
			{
				TeamBalance_GetTeam(balance, head.team).m_num_players = 0;
			}
			head = find(head, classname, teament_name);
		}
	}

	// TODO: Balance quantity of bots across > 2 teams when bot_vs_human is set (and remove next line)
	if (AvailableTeams() == 2)
	if (autocvar_bot_vs_human && for_whom)
	{
		if (autocvar_bot_vs_human > 0)
		{
			// find last team available
			if (IS_BOT_CLIENT(for_whom))
			{
				if (TeamBalance_IsTeamAllowedInternal(balance, 4))
				{
					TeamBalance_BanTeamsExcept(balance, 4);
				}
				else if (TeamBalance_IsTeamAllowedInternal(balance, 3))
				{
					TeamBalance_BanTeamsExcept(balance, 3);
				}
				else
				{
					TeamBalance_BanTeamsExcept(balance, 2);
				}
				// no further cases, we know at least 2 teams exist
			}
			else
			{
				if (TeamBalance_IsTeamAllowedInternal(balance, 1))
				{
					TeamBalance_BanTeamsExcept(balance, 1);
				}
				else if (TeamBalance_IsTeamAllowedInternal(balance, 2))
				{
					TeamBalance_BanTeamsExcept(balance, 2);
				}
				else
				{
					TeamBalance_BanTeamsExcept(balance, 3);
				}
				// no further cases, bots have one of the teams
			}
		}
		else
		{
			// find first team available
			if (IS_BOT_CLIENT(for_whom))
			{
				if (TeamBalance_IsTeamAllowedInternal(balance, 1))
				{
					TeamBalance_BanTeamsExcept(balance, 1);
				}
				else if (TeamBalance_IsTeamAllowedInternal(balance, 2))
				{
					TeamBalance_BanTeamsExcept(balance, 2);
				}
				else
				{
					TeamBalance_BanTeamsExcept(balance, 3);
				}
				// no further cases, we know at least 2 teams exist
			}
			else
			{
				if (TeamBalance_IsTeamAllowedInternal(balance, 4))
				{
					TeamBalance_BanTeamsExcept(balance, 4);
				}
				else if (TeamBalance_IsTeamAllowedInternal(balance, 3))
				{
					TeamBalance_BanTeamsExcept(balance, 3);
				}
				else
				{
					TeamBalance_BanTeamsExcept(balance, 2);
				}
				// no further cases, bots have one of the teams
			}
		}
	}

	if (!for_whom)
	{
		balance.m_team_balance_state = TEAM_BALANCE_TEAMS_CHECKED;
		return balance;
	}

	// if player has a forced team, ONLY allow that one
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (for_whom.team_forced == Team_IndexToTeam(i) &&
			TeamBalance_IsTeamAllowedInternal(balance, i))
		{
			TeamBalance_BanTeamsExcept(balance, i);
		}
		break;
	}
	balance.m_team_balance_state = TEAM_BALANCE_TEAMS_CHECKED;
	return balance;
}

void TeamBalance_Destroy(entity balance)
{
	if (balance == NULL)
	{
		return;
	}
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		delete(balance.(m_team_balance_team[i]));
	}
	delete(balance);
}

int TeamBalance_GetAllowedTeams(entity balance)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_GetAllowedTeams: Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("TeamBalance_GetAllowedTeams: "
			"Team balance entity is not initialized.");
	}
	int result = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (TeamBalance_IsTeamAllowedInternal(balance, i))
		{
			result |= Team_IndexToBit(i);
		}
	}
	return result;
}

bool TeamBalance_IsTeamAllowed(entity balance, int index)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_IsTeamAllowed: Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("TeamBalance_IsTeamAllowed: "
			"Team balance entity is not initialized.");
	}
	if (!Team_IsValidIndex(index))
	{
		LOG_FATALF("TeamBalance_IsTeamAllowed: Team index is invalid: %f",
			index);
	}
	return TeamBalance_IsTeamAllowedInternal(balance, index);
}

void TeamBalance_GetTeamCounts(entity balance, entity ignore)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_GetTeamCounts: Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("TeamBalance_GetTeamCounts: "
			"Team balance entity is not initialized.");
	}
	if (MUTATOR_CALLHOOK(TeamBalance_GetTeamCounts) == true)
	{
		// Mutator has overriden the configuration.
		for (int i = 1; i <= NUM_TEAMS; ++i)
		{
			entity team_ent = TeamBalance_GetTeamFromIndex(balance, i);
			if (TeamBalanceTeam_IsAllowed(team_ent))
			{
				MUTATOR_CALLHOOK(TeamBalance_GetTeamCount, i, ignore);
				team_ent.m_num_players = M_ARGV(2, float);
				team_ent.m_num_bots = M_ARGV(3, float);
			}
		}
	}
	else
	{
		// Manually count all players.
		FOREACH_CLIENT(true,
		{
			if (it == ignore)
			{
				continue;
			}
			int team_num;
			if (IS_PLAYER(it) || it.caplayer)
			{
				team_num = it.team;
			}
			else if (it.team_forced > 0)
			{
				team_num = it.team_forced; // reserve the spot
			}
			else
			{
				continue;
			}
			if (!Team_IsValidTeam(team_num))
			{
				continue;
			}
			entity team_ent = TeamBalance_GetTeam(balance, team_num);
			if (!TeamBalanceTeam_IsAllowed(team_ent))
			{
				continue;
			}
			++team_ent.m_num_players;
			if (IS_BOT_CLIENT(it))
			{
				++team_ent.m_num_bots;
			}
		});
	}

	// if the player who has a forced team has not joined yet, reserve the spot
	if (autocvar_g_campaign)
	{
		if (Team_IsValidIndex(autocvar_g_campaign_forceteam))
		{
			entity team_ent = TeamBalance_GetTeamFromIndex(balance,
				autocvar_g_campaign_forceteam);
			if (team_ent.m_num_players == team_ent.m_num_bots)
			{
				++team_ent.m_num_players;
			}
		}
	}
	balance.m_team_balance_state = TEAM_BALANCE_TEAM_COUNTS_FILLED;
}

int TeamBalance_GetNumberOfPlayers(entity balance, int index)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_GetNumberOfPlayers: "
			"Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state != TEAM_BALANCE_TEAM_COUNTS_FILLED)
	{
		LOG_FATAL("TeamBalance_GetNumberOfPlayers: "
			"TeamBalance_GetTeamCounts has not been called.");
	}
	if (!Team_IsValidIndex(index))
	{
		LOG_FATALF("TeamBalance_GetNumberOfPlayers: Team index is invalid: %f",
			index);
	}
	return balance.m_team_balance_team[index - 1].m_num_players;
}

int TeamBalance_FindBestTeam(entity balance, entity player, bool ignore_player)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_FindBestTeam: Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("TeamBalance_FindBestTeam: "
			"Team balance entity is not initialized.");
	}
	// count how many players are in each team
	if (ignore_player)
	{
		TeamBalance_GetTeamCounts(balance, player);
	}
	else
	{
		TeamBalance_GetTeamCounts(balance, NULL);
	}
	int team_bits = TeamBalance_FindBestTeams(balance, player, true);
	if (team_bits == 0)
	{
		LOG_FATALF("TeamBalance_FindBestTeam: No teams available for %s\n",
			MapInfo_Type_ToString(MapInfo_CurrentGametype()));
	}
	RandomSelection_Init();
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (team_bits & Team_IndexToBit(i))
		{
			RandomSelection_AddFloat(i, 1, 1);
		}
	}
	return RandomSelection_chosen_float;
}

int TeamBalance_FindBestTeams(entity balance, entity player, bool use_score)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_FindBestTeams: Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state != TEAM_BALANCE_TEAM_COUNTS_FILLED)
	{
		LOG_FATAL("TeamBalance_FindBestTeams: "
			"TeamBalance_GetTeamCounts has not been called.");
	}
	if (MUTATOR_CALLHOOK(TeamBalance_FindBestTeams, player) == true)
	{
		return M_ARGV(1, float);
	}
	int team_bits = 0;
	int previous_team = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (!TeamBalance_IsTeamAllowedInternal(balance, i))
		{
			continue;
		}
		if (previous_team == 0)
		{
			team_bits = Team_IndexToBit(i);
			previous_team = i;
			continue;
		}
		int compare = TeamBalance_CompareTeams(balance, i, previous_team,
			player, use_score);
		if (compare == TEAMS_COMPARE_LESS)
		{
			team_bits = Team_IndexToBit(i);
			previous_team = i;
			continue;
		}
		if (compare == TEAMS_COMPARE_EQUAL)
		{
			team_bits |= Team_IndexToBit(i);
			previous_team = i;
		}
	}
	return team_bits;
}

void TeamBalance_JoinBestTeam(entity this)
{
	PrintToChatAll(sprintf("JoinBestTeam: %s, %f", this.netname));
	// don't join a team if we're not playing a team game
	if (!teamplay)
	{
		return;
	}

	// find out what teams are available
	entity balance = TeamBalance_CheckAllowedTeams(this);

	if (this.bot_forced_team)
	{
		TeamBalance_Destroy(balance);
		return;
	}
	int best_team_index = TeamBalance_FindBestTeam(balance, this, true);
	int old_team_index = Team_TeamToIndex(this.team);
	TeamBalance_Destroy(balance);
	PlayerScore_Clear(this);
	if (!SetPlayerTeam(this, best_team_index, TEAM_CHANGE_AUTO))
	{
		return;
	}
	if ((old_team_index != -1) && !IS_BOT_CLIENT(this))
	{
		TeamBalance_AutoBalanceBots(best_team_index, old_team_index);
	}
}

int TeamBalance_CompareTeams(entity balance, int team_index_a, int team_index_b,
	entity player, bool use_score)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_CompareTeams: Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state != TEAM_BALANCE_TEAM_COUNTS_FILLED)
	{
		LOG_FATAL("TeamBalance_CompareTeams: "
			"TeamBalance_GetTeamCounts has not been called.");
	}
	if (!Team_IsValidIndex(team_index_a))
	{
		LOG_FATALF("TeamBalance_CompareTeams: team_index_a is invalid: %f",
			team_index_a);
	}
	if (!Team_IsValidIndex(team_index_b))
	{
		LOG_FATALF("TeamBalance_CompareTeams: team_index_b is invalid: %f",
			team_index_b);
	}
	if (team_index_a == team_index_b)
	{
		return TEAMS_COMPARE_EQUAL;
	}
	entity team_a = TeamBalance_GetTeamFromIndex(balance, team_index_a);
	entity team_b = TeamBalance_GetTeamFromIndex(balance, team_index_b);
	return TeamBalance_CompareTeamsInternal(team_a, team_b, player, use_score);
}

void TeamBalance_AutoBalanceBots(int source_team_index,
	int destination_team_index)
{
	if (!Team_IsValidIndex(source_team_index))
	{
		LOG_WARNF("TeamBalance_AutoBalanceBots: "
			"Source team index is invalid: %f", source_team_index);
		return;
	}
	if (!Team_IsValidIndex(destination_team_index))
	{
		LOG_WARNF("TeamBalance_AutoBalanceBots: "
			"Destination team index is invalid: %f", destination_team_index);
		return;
	}
	if (!autocvar_g_balance_teams ||
		!autocvar_g_balance_teams_prevent_imbalance)
	{
		return;
	}
	entity balance = TeamBalance_CheckAllowedTeams(NULL);
	TeamBalance_GetTeamCounts(balance, NULL);
	entity source_team = TeamBalance_GetTeamFromIndex(balance,
		source_team_index);
	entity destination_team = TeamBalance_GetTeamFromIndex(balance,
		destination_team_index);
	if ((source_team.m_num_bots == 0) || (source_team.m_num_players <=
		destination_team.m_num_players))
	{
		TeamBalance_Destroy(balance);
		return;
	}
	TeamBalance_Destroy(balance);
	entity lowest_bot = NULL;
	if (MUTATOR_CALLHOOK(TeamBalance_GetPlayerForTeamSwitch, source_team_index,
		destination_team_index, true))
	{
		lowest_bot = M_ARGV(3, entity);
	}
	else
	{
		float lowest_score = FLOAT_MAX;
		FOREACH_CLIENT(IS_BOT_CLIENT(it) && (Entity_GetTeamIndex(it) ==
			source_team_index),
		{
			float temp_score = PlayerScore_Get(it, SP_SCORE);
			if (temp_score >= lowest_score)
			{
				continue;
			}
			balance = TeamBalance_CheckAllowedTeams(it);
			if (TeamBalance_IsTeamAllowed(balance, destination_team_index))
			{
				lowest_bot = it;
				lowest_score = temp_score;
			}
			TeamBalance_Destroy(balance);
		});
	}
	if (lowest_bot == NULL)
	{
		return;
	}
	if (!Player_SetTeamIndex(lowest_bot, destination_team_index))
	{
		return;
	}
	KillPlayerForTeamChange(lowest_bot);
}

bool TeamBalance_IsTeamAllowedInternal(entity balance, int index)
{
	return balance.m_team_balance_team[index - 1].m_num_players !=
		TEAM_NOT_ALLOWED;
}

void TeamBalance_BanTeamsExcept(entity balance, int index)
{
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (i != index)
		{
			balance.m_team_balance_team[i - 1].m_num_players = TEAM_NOT_ALLOWED;
		}
	}
}

entity TeamBalance_GetTeamFromIndex(entity balance, int index)
{
	if (!Team_IsValidIndex(index))
	{
		LOG_FATALF("TeamBalance_GetTeamFromIndex: Index is invalid: %f", index);
	}
	return balance.m_team_balance_team[index - 1];
}

entity TeamBalance_GetTeam(entity balance, int team_num)
{
	return TeamBalance_GetTeamFromIndex(balance, Team_TeamToIndex(team_num));
}

bool TeamBalanceTeam_IsAllowed(entity team_ent)
{
	return team_ent.m_num_players != TEAM_NOT_ALLOWED;
}

int TeamBalanceTeam_GetNumberOfPlayers(entity team_ent)
{
	return team_ent.m_num_players;
}

int TeamBalanceTeam_GetNumberOfBots(entity team_ent)
{
	return team_ent.m_num_bots;
}

int TeamBalance_CompareTeamsInternal(entity team_a, entity team_b,
	entity player, bool use_score)
{
	if (team_a == team_b)
	{
		return TEAMS_COMPARE_EQUAL;
	}
	if (!TeamBalanceTeam_IsAllowed(team_a) ||
		!TeamBalanceTeam_IsAllowed(team_b))
	{
		return TEAMS_COMPARE_INVALID;
	}
	int num_players_team_a = team_a.m_num_players;
	int num_players_team_b = team_b.m_num_players;
	if (IS_REAL_CLIENT(player) && bots_would_leave)
	{
		num_players_team_a -= team_a.m_num_bots;
		num_players_team_b -= team_b.m_num_bots;
	}
	if (num_players_team_a < num_players_team_b)
	{
		return TEAMS_COMPARE_LESS;
	}
	if (num_players_team_a > num_players_team_b)
	{
		return TEAMS_COMPARE_GREATER;
	}
	if (!use_score)
	{
		return TEAMS_COMPARE_EQUAL;
	}
	if (team_a.m_team_score < team_b.m_team_score)
	{
		return TEAMS_COMPARE_LESS;
	}
	if (team_a.m_team_score > team_b.m_team_score)
	{
		return TEAMS_COMPARE_GREATER;
	}
	return TEAMS_COMPARE_EQUAL;
}

// Called when the player connects or when they change their color with "color"
// command.
void SV_ChangeTeam(entity this, float _color)
{
	//PrintToChatAll(sprintf("SV_ChangeTeam: %s, %f", this.netname, _color));

	// in normal deathmatch we can just apply the color and we're done
	if(!teamplay)
		SetPlayerColors(this, _color);

	if(!IS_CLIENT(this))
	{
		// since this is an engine function, and gamecode doesn't have any calls earlier than this, do the connecting message here
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_CONNECTING, this.netname);
		return;
	}

	if(!teamplay)
		return;

	int source_color, destination_color;
	int source_team_index, destination_team_index;

	source_color = this.clientcolors & 0x0F;
	destination_color = _color & 0x0F;

	source_team_index = Team_TeamToIndex(source_color + 1);
	destination_team_index = Team_TeamToIndex(destination_color + 1);

	if (destination_team_index == -1)
	{
		return;
	}

	entity balance = TeamBalance_CheckAllowedTeams(this);

	if (destination_team_index == 1 && !TeamBalance_IsTeamAllowedInternal(
		balance, 1))
	{
		destination_team_index = 4;
	}
	if (destination_team_index == 4 && !TeamBalance_IsTeamAllowedInternal(
		balance, 4))
	{
		destination_team_index = 3;
	}
	if (destination_team_index == 3 && !TeamBalance_IsTeamAllowedInternal(
		balance, 3))
	{
		destination_team_index = 2;
	}
	if (destination_team_index == 2 && !TeamBalance_IsTeamAllowedInternal(
		balance, 2))
	{
		destination_team_index = 1;
	}

	// not changing teams
	if (source_color == destination_color)
	{
		SetPlayerTeam(this, destination_team_index, TEAM_CHANGE_MANUAL);
		TeamBalance_Destroy(balance);
		return;
	}

	if((autocvar_g_campaign) || (autocvar_g_changeteam_banned && CS(this).wasplayer)) {
		Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_NOTALLOWED);
		return; // changing teams is not allowed
	}

	// autocvar_g_balance_teams_prevent_imbalance only makes sense if autocvar_g_balance_teams is on, as it makes the team selection dialog pointless
	if (autocvar_g_balance_teams && autocvar_g_balance_teams_prevent_imbalance)
	{
		TeamBalance_GetTeamCounts(balance, this);
		if ((Team_IndexToBit(destination_team_index) &
			TeamBalance_FindBestTeams(balance, this, false)) == 0)
		{
			Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_LARGERTEAM);
			TeamBalance_Destroy(balance);
			return;
		}
	}
	TeamBalance_Destroy(balance);
	if (IS_PLAYER(this) && source_team_index != destination_team_index)
	{
		// reduce frags during a team change
		PlayerScore_Clear(this);
	}
	if (!SetPlayerTeam(this, destination_team_index, TEAM_CHANGE_MANUAL))
	{
		return;
	}
	TeamBalance_AutoBalanceBots(destination_team_index, source_team_index);
}
