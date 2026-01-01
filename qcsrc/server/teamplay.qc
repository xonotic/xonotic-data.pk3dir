#include "teamplay.qh"

#include <common/deathtypes/all.qh>
#include <common/gametypes/_mod.qh>
#include <common/teams.qh>
#include <server/bot/api.qh>
#include <server/bot/default/cvars.qh>
#include <server/campaign.qh>
#include <server/client.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/gamelog.qh>
#include <server/mutators/_mod.qh>
#include <server/race.qh>
#include <server/scores.qh>
#include <server/scores_rules.qh>

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
.int m_num_owned_items; ///< Number of items owned by a team.

string autocvar_g_forced_team_red;
string autocvar_g_forced_team_blue;
string autocvar_g_forced_team_yellow;
string autocvar_g_forced_team_pink;

entity g_team_entities[NUM_TEAMS]; ///< Holds global team entities.

void Team_InitTeams()
{
	if (g_team_entities[0])
		return;
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		g_team_entities[i] = new_pure(team_entity);
	}
}

entity Team_GetTeamFromIndex(int index)
{
	if (!Team_IsValidIndex(index))
	{
		LOG_FATALF("Index is invalid: %f", index);
	}
	return g_team_entities[index - 1];
}

entity Team_GetTeam(int team_num)
{
	if (!Team_IsValidTeam(team_num))
	{
		LOG_FATALF("Value is invalid: %f", team_num);
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

int Team_GetWinnerAliveTeam()
{
	int winner = 0;
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		if (g_team_entities[i].m_num_players_alive > 0)
		{
			if (winner)
				return 0;
			winner = Team_IndexToTeam(i + 1);
		}
	}
	return (winner ? winner : -1);
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

int Team_GetWinnerTeam_WithOwnedItems(int min_control_points)
{
	int winner = 0;
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		if (g_team_entities[i].m_num_owned_items >= min_control_points)
		{
			if (winner)
				return 0;
			winner = Team_IndexToTeam(i + 1);
		}
	}
	return (winner ? winner : -1);
}

int Team_GetNumberOfOwnedItems(entity team_ent)
{
	return team_ent.m_num_owned_items;
}

void Team_SetNumberOfOwnedItems(entity team_ent, int number)
{
	team_ent.m_num_owned_items = number;
}

int Team_GetNumberOfTeamsWithOwnedItems()
{
	int result = 0;
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		if (g_team_entities[i].m_num_owned_items > 0)
		{
			++result;
		}
	}
	return result;
}

void setcolor(entity this, int clr)
{
#if 1
	this.clientcolors = clr;
	if(teamplay)
		this.team = (clr & 15) + 1;
	else
		this.team = -1;
#else
	// sets clientcolors and team (even in FFA games)
	// and sends notification to all clients
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
		return true;

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

/** Returns true when enough players are queued that the next will join directly
 * to the only available team (also triggering the joins of the queued players).
 * Optionally only counts players who selected a specific team when joining the queue.
 */
bool QueuedPlayersReady(entity this, bool checkspecificteam)
{
	int numplayersqueued = 0;

	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != this
	&& (checkspecificteam ? it.wants_join > 0 : it.wants_join),
	{
		LOG_DEBUGF("Player %s is waiting to join team %d", it.netname, it.wants_join);
		++numplayersqueued;
		if (numplayersqueued >= AVAILABLE_TEAMS - 1)
			return true;
	});

	LOG_DEBUG("No players waiting to join.");
	return false;
}

bool SetPlayerTeam(entity player, int team_index, int type)
{
	int old_team_index = Entity_GetTeamIndex(player);

	if (!Player_SetTeamIndex(player, team_index))
		return false;

	LogTeamChange(player.playerid, player.team, type);

	if (team_index != old_team_index)
	{
		KillPlayerForTeamChange(player);
		PlayerScore_Clear(player); // works only in gametypes without teams

		if (!IS_BOT_CLIENT(player))
			TeamBalance_AutoBalanceBots();

		if (team_index != -1)
		{
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(player.team, INFO_JOIN_PLAY_TEAM), player.netname);
			player.team_selected = team_index; // no autoselect in Join()

			if (warmup_stage)
				ReadyCount(); // teams might be balanced now
		}
	}

	if (team_index == -1)
	{
		if (autocvar_sv_maxidle_playertospectator > 0 && CS(player).idlekick_lasttimeleft)
		{
			// this done here so it happens even when manually speccing during the countdown
			Kill_Notification(NOTIF_ONE_ONLY, player, MSG_CENTER, CPID_IDLING);
			CS(player).idlekick_lasttimeleft = 0;
		}
		else if (!CS(player).just_joined && player.frags != FRAGS_SPECTATOR)
		{
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_SPECTATE, player.netname);
		}
	}

	return true;
}

bool MoveToTeam(entity client, int team_index, int type)
{
	//PrintToChatAll(sprintf("MoveToTeam: %s, %f", client.netname, team_index));
	int lockteams_backup = lockteams;  // backup any team lock
	lockteams = 0;  // disable locked teams
	if (!SetPlayerTeam(client, team_index, type))
	{
		lockteams = lockteams_backup;  // restore the team lock
		return false;
	}
	lockteams = lockteams_backup;  // restore the team lock
	return true;
}

bool Player_HasRealForcedTeam(entity player)
{
	return player.team_forced > TEAM_FORCE_DEFAULT;
}

int Player_GetForcedTeamIndex(entity player)
{
	return player.team_forced;
}

void Player_SetForcedTeamIndex(entity player, int team_index)
{
	switch (team_index)
	{
		case TEAM_FORCE_SPECTATOR:
		case TEAM_FORCE_DEFAULT:
		{
			player.team_forced = team_index;
			break;
		}
		default:
		{
			if (!Team_IsValidIndex(team_index))
			{
				LOG_FATAL("Invalid team index.");
			}
			else
			{
				player.team_forced = team_index;
				break;
			}
		}
	}
}

void Player_DetermineForcedTeam(entity player)
{
	if (autocvar_g_campaign)
	{
		if (IS_REAL_CLIENT(player)) // only players, not bots
		{
			if (Team_IsValidIndex(autocvar_g_campaign_forceteam))
			{
				player.team_forced = autocvar_g_campaign_forceteam;
			}
			else
			{
				player.team_forced = TEAM_FORCE_DEFAULT;
			}
		}
	}
	else if (PlayerInList(player, autocvar_g_forced_team_red))
	{
		player.team_forced = 1;
	}
	else if (PlayerInList(player, autocvar_g_forced_team_blue))
	{
		player.team_forced = 2;
	}
	else if (PlayerInList(player, autocvar_g_forced_team_yellow))
	{
		player.team_forced = 3;
	}
	else if (PlayerInList(player, autocvar_g_forced_team_pink))
	{
		player.team_forced = 4;
	}
	else
	{
		switch (autocvar_g_forced_team_otherwise)
		{
			case "red":
			{
				player.team_forced = 1;
				break;
			}
			case "blue":
			{
				player.team_forced = 2;
				break;
			}
			case "yellow":
			{
				player.team_forced = 3;
				break;
			}
			case "pink":
			{
				player.team_forced = 4;
				break;
			}
			case "spectate":
			case "spectator":
			{
				player.team_forced = TEAM_FORCE_SPECTATOR;
				break;
			}
			default:
			{
				player.team_forced = TEAM_FORCE_DEFAULT;
				break;
			}
		}
	}
	if (!teamplay && Player_HasRealForcedTeam(player))
	{
		player.team_forced = TEAM_FORCE_DEFAULT;
	}
}

void TeamBalance_JoinBestTeam(entity player)
{
	//PrintToChatAll(sprintf("TeamBalance_JoinBestTeam: %s", player.netname));
	if (!teamplay)
	{
		return;
	}
	if (player.bot_forced_team)
	{
		return;
	}
	entity balance = TeamBalance_CheckAllowedTeams(player);
	if (Player_HasRealForcedTeam(player))
	{
		int forced_team_index = player.team_forced;
		bool is_team_allowed = TeamBalance_IsTeamAllowedInternal(balance,
			forced_team_index);
		TeamBalance_Destroy(balance);
		if (!is_team_allowed)
		{
			return;
		}
		if (!SetPlayerTeam(player, forced_team_index, TEAM_CHANGE_AUTO))
		{
			return;
		}
		return;
	}
	int best_team_index = TeamBalance_FindBestTeam(balance, player, true);
	TeamBalance_Destroy(balance);
	if (!SetPlayerTeam(player, best_team_index, TEAM_CHANGE_AUTO))
	{
		return;
	}
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
	balance.nextthink = time;

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
	if (autocvar_bot_vs_human && AVAILABLE_TEAMS == 2 && for_whom)
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
		if (for_whom.team_forced == i &&
			TeamBalance_IsTeamAllowedInternal(balance, i))
		{
			TeamBalance_BanTeamsExcept(balance, i);
			break;
		}
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
		LOG_FATAL("Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("Team balance entity is not initialized.");
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

int TeamBalance_SizeDifference(entity ignore)
{
	if (!teamplay)
		return 0;

	entity balance = TeamBalance_CheckAllowedTeams(ignore);
	TeamBalance_GetTeamCounts(balance, ignore);

	int ts_min = 255, ts_max = 0;
	for (int i = 1; i <= AVAILABLE_TEAMS; ++i)
	{
		int ts = TeamBalance_GetTeamFromIndex(balance, i).m_num_players;
		if (ts_min > ts)
			ts_min = ts;
		if (ts_max < ts)
			ts_max = ts;
	}

	TeamBalance_Destroy(balance);

	return ts_max - ts_min;
}

bool TeamBalance_AreEqual(entity ignore, bool would_leave)
{
	entity balance = TeamBalance_CheckAllowedTeams(ignore);
	TeamBalance_GetTeamCounts(balance, ignore);

	bool equality = true;
	int total;
	int prev_total = 0;
	int bots = 0;

	for(int i = 1; i <= AVAILABLE_TEAMS; ++i)
	{
		total = TeamBalance_GetTeamFromIndex(balance, i).m_num_players;
		bots += TeamBalance_GetTeamFromIndex(balance, i).m_num_bots;
		if(i > 1 && total != prev_total)
		{
			equality = false;
			break;
		}
		prev_total = total;
	}
	TeamBalance_Destroy(balance);

	// Ignore if there are "ghost" bots that would leave if anyone joined
	if (would_leave && bots_would_leave)
		return false;

	return equality;
}

entity remove_countdown;
void Remove_Countdown(entity this)
{
	if(this.lifetime <= 0 || TeamBalance_AreEqual(NULL, false))
	{
		if(this.lifetime <= 0)
		{
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_MOVETOSPEC_REMOVE, playername(remove_countdown.enemy.netname, remove_countdown.enemy.team, true));
			PutObserverInServer(remove_countdown.enemy, true, true);
		}

		Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_REMOVE);

		delete(this);
		remove_countdown = NULL;

		TeamBalance_RemoveExcessPlayers(NULL); // Check again for excess players in case someone also left while in countdown
		return;
	}

	--this.lifetime;
	this.nextthink = time + 1;
}

// FIXME: support more than 2 teams, the notification will be... awkward
// FIXME: also don't kick the fc/bc/kc lol
void TeamBalance_RemoveExcessPlayers(entity ignore)
{
	if(AVAILABLE_TEAMS != 2 || autocvar_g_campaign) return;

	entity balance = TeamBalance_CheckAllowedTeams(ignore);
	TeamBalance_GetTeamCounts(balance, ignore);

	int min = 0;

	for(int i = 1; i <= AVAILABLE_TEAMS; ++i)
	{
		int cur = TeamBalance_GetTeamFromIndex(balance, i).m_num_players;
		if(i == 1 || cur < min)
			min = cur;
	}

	for(int tmi = 1; tmi <= AVAILABLE_TEAMS; ++tmi)
	{
		int cur = TeamBalance_GetTeamFromIndex(balance, tmi).m_num_players;
		if(cur > 0 && cur > min) // If this team has excess players
		{
			// Get newest player
			int latest_join = 0;
			entity latest_join_pl = NULL;

			FOREACH_CLIENT(IS_REAL_CLIENT(it) || INGAME(it), {
				if(it.team == Team_IndexToTeam(tmi) && CS(it).startplaytime > latest_join)
				{
					latest_join = CS(it).startplaytime;
					latest_join_pl = it;
				}
			});

			// Force player to spectate
			if(latest_join_pl)
			{
				// Send player to spectate
				if(autocvar_g_balance_teams_remove_wait)
				{
					// Give a warning before moving to spect
					if (!remove_countdown)
					{
						remove_countdown = new_pure(remove_countdown);
						setthink(remove_countdown, Remove_Countdown);
						remove_countdown.nextthink = time;
						Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MOVETOSPEC_REMOVE, playername(latest_join_pl.netname, latest_join_pl.team, true), autocvar_g_balance_teams_remove_wait);
					}
					remove_countdown.enemy = latest_join_pl;
					remove_countdown.lifetime = autocvar_g_balance_teams_remove_wait;
				}
				else
				{
					// Move to spects immediately
					Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_MOVETOSPEC_REMOVE, latest_join_pl.netname);
					PutObserverInServer(latest_join_pl, true, true);
				}
			}
		}
	}

	TeamBalance_Destroy(balance);
}

bool TeamBalance_QueuedPlayersTagIn(entity ignore)
{
	if (!teamplay)
		return true;

	int j, teamplayers_deficit = 0, teamplayers_max = 0;
	entity it, balance = TeamBalance_CheckAllowedTeams(ignore);
	TeamBalance_GetTeamCounts(balance, ignore);

	for (int bots_would_leave_remaining = bots_would_leave, j = 1; j <= AVAILABLE_TEAMS; ++j)
	{
		it = TeamBalance_GetTeamFromIndex(balance, j);
		// deduct bots that would leave if a player joined their team, distributing the deductions between teams
		if (bots_would_leave_remaining)
		{
			int to_remove = min(it.m_num_bots, ceil(bots_would_leave_remaining / AVAILABLE_TEAMS));
			it.m_num_players -= to_remove;
			bots_would_leave_remaining -= to_remove;
		}
		// find the largest team size
		if (it.m_num_players > teamplayers_max)
			teamplayers_max = it.m_num_players;
	}
	// find how many players we'd need to join to achieve balanced numbers that way
	for (j = 1; j <= AVAILABLE_TEAMS; ++j)
		teamplayers_deficit += teamplayers_max - TeamBalance_GetTeamFromIndex(balance, j).m_num_players;

	// first pass: find clients(s) who want to play on a specific team
	for (j = 1; teamplayers_deficit > 0 && j <= maxclients; ++j)
	{
		it = ftoe(j);
		if (it.wants_join <= 0 || it == ignore) continue;
		if (TeamBalance_GetTeamFromIndex(balance, it.wants_join).m_num_players >= teamplayers_max) continue;
		Join(it, false);
		++TeamBalance_GetTeam(balance, it.team).m_num_players;
		--teamplayers_deficit;
	}

	// second pass: find clients(s) who want to play on any team
	for (j = 1; teamplayers_deficit > 0 && j <= maxclients; ++j)
	{
		it = ftoe(j);
		if (it.wants_join >= 0 || it == ignore) continue;
		Join(it, false);
		--teamplayers_deficit; // don't need to update .m_num_players as we won't read it again
	}

	TeamBalance_Destroy(balance);
	return teamplayers_deficit <= 0; // return true if teams are now balanced
}

bool TeamBalance_IsTeamAllowed(entity balance, int index)
{
	if (balance == NULL)
	{
		LOG_FATAL("Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("Team balance entity is not initialized.");
	}
	if (!Team_IsValidIndex(index))
	{
		LOG_FATALF("Team index is invalid: %f",
			index);
	}
	return TeamBalance_IsTeamAllowedInternal(balance, index);
}

// maybe include qcsrc/server/clientkill.qh instead of declaring this?
.int killindicator_teamchange;
void TeamBalance_GetTeamCounts(entity balance, entity ignore)
{
	if (balance == NULL)
	{
		LOG_FATAL("Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("Team balance entity is not initialized.");
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
			// TODO: Reconsider when the player is truly on the team.
			if (IS_CLIENT(it) || INGAME(it))
			{
				team_num = it.killindicator_teamchange > 0 ? it.killindicator_teamchange : it.team;
			}
			else if (Player_HasRealForcedTeam(it))
			{
				// Do we really need this? Probably not.
				team_num = Team_IndexToTeam(it.team_forced); // reserve the spot
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
		LOG_FATAL("Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state != TEAM_BALANCE_TEAM_COUNTS_FILLED)
	{
		LOG_FATAL("TeamBalance_GetTeamCounts has not been called.");
	}
	if (!Team_IsValidIndex(index))
	{
		LOG_FATALF("Team index is invalid: %f", index);
	}
	return balance.m_team_balance_team[index - 1].m_num_players;
}

int TeamBalance_FindBestTeam(entity balance, entity player, bool ignore_player)
{
	if (balance == NULL)
	{
		LOG_FATAL("Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state == TEAM_BALANCE_UNINITIALIZED)
	{
		LOG_FATAL("Team balance entity is not initialized.");
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
		LOG_FATALF("No teams available for %s\n", GetGametype());
	}

	// don't punish players for UI mistakes by changing teams randomly when already on a best team
	if (player.team > 0 && (team_bits & Team_TeamToBit(player.team)))
		return Team_TeamToIndex(player.team);

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
		LOG_FATAL("Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state != TEAM_BALANCE_TEAM_COUNTS_FILLED)
	{
		LOG_FATAL("TeamBalance_GetTeamCounts has not been called.");
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

int TeamBalance_CompareTeams(entity balance, int team_index_a, int team_index_b,
	entity player, bool use_score)
{
	if (balance == NULL)
	{
		LOG_FATAL("Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state != TEAM_BALANCE_TEAM_COUNTS_FILLED)
	{
		LOG_FATAL("TeamBalance_GetTeamCounts has not been called.");
	}
	if (!Team_IsValidIndex(team_index_a))
	{
		LOG_FATALF("team_index_a is invalid: %f",
			team_index_a);
	}
	if (!Team_IsValidIndex(team_index_b))
	{
		LOG_FATALF("team_index_b is invalid: %f",
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

void TeamBalance_AutoBalanceBots()
{
	// checks disabled because we always want auto-balanced bots
	//if (!autocvar_g_balance_teams_prevent_imbalance)
	//	return;

	if (intermission_running) return;

	entity balance = TeamBalance_CheckAllowedTeams(NULL);
	TeamBalance_GetTeamCounts(balance, NULL);
	int smallest_team_index = 0;
	int smallest_team_player_count = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		entity team_ = TeamBalance_GetTeamFromIndex(balance, i);
		if (!TeamBalanceTeam_IsAllowed(team_))
		{
			continue;
		}
		int playercount = TeamBalanceTeam_GetNumberOfPlayers(team_);
		if (smallest_team_index == 0)
		{
			smallest_team_index = i;
			smallest_team_player_count = playercount;
		}
		else if (playercount < smallest_team_player_count)
		{
			smallest_team_index = i;
			smallest_team_player_count = playercount;
		}
	}
	//PrintToChatAll(sprintf("Smallest team: %f", smallest_team_index));
	//PrintToChatAll(sprintf("Smallest team players: %f", smallest_team_player_count));
	entity switchable_bot = NULL;
	int teams = BITS(NUM_TEAMS);
	while (teams != 0)
	{
		int largest_team_index = TeamBalance_GetLargestTeamIndex(balance,
			teams);
		if (smallest_team_index == largest_team_index)
		{
			TeamBalance_Destroy(balance);
			return;
		}
		entity largest_team = TeamBalance_GetTeamFromIndex(balance,
			largest_team_index);
		int largest_team_player_count = TeamBalanceTeam_GetNumberOfPlayers(
			largest_team);
		if (largest_team_player_count - smallest_team_player_count < 2)
		{
			TeamBalance_Destroy(balance);
			return;
		}
		//PrintToChatAll(sprintf("Largest team: %f", largest_team_index));
		//PrintToChatAll(sprintf("Largest team players: %f", largest_team_player_count));
		switchable_bot = TeamBalance_GetPlayerForTeamSwitch(largest_team_index,
			smallest_team_index, true);
		if (switchable_bot != NULL)
		{
			break;
		}
		teams &= ~Team_IndexToBit(largest_team_index);
	}
	TeamBalance_Destroy(balance);
	if (switchable_bot == NULL)
	{
		//PrintToChatAll("No bot found after searching through all the teams");
		return;
	}
	SetPlayerTeam(switchable_bot, smallest_team_index, TEAM_CHANGE_AUTO);
}

int TeamBalance_GetLargestTeamIndex(entity balance, int teams)
{
	int largest_team_index = 0;
	int largest_team_player_count = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (!(Team_IndexToBit(i) & teams))
		{
			continue;
		}
		entity team_ = TeamBalance_GetTeamFromIndex(balance, i);
		if (!TeamBalanceTeam_IsAllowed(team_))
		{
			continue;
		}
		int playercount = TeamBalanceTeam_GetNumberOfPlayers(team_);
		if (largest_team_index == 0)
		{
			largest_team_index = i;
			largest_team_player_count = playercount;
		}
		else if (playercount > largest_team_player_count)
		{
			largest_team_index = i;
			largest_team_player_count = playercount;
		}
	}
	return largest_team_index;
}

entity TeamBalance_GetPlayerForTeamSwitch(int source_team_index,
	int destination_team_index, bool is_bot)
{
	if (MUTATOR_CALLHOOK(TeamBalance_GetPlayerForTeamSwitch, source_team_index,
		destination_team_index, is_bot))
	{
		return M_ARGV(3, entity);
	}
	entity lowest_player = NULL;
	float lowest_score = FLOAT_MAX;
	FOREACH_CLIENT(Entity_GetTeamIndex(it) == source_team_index,
	{
		if (IS_BOT_CLIENT(it) != is_bot)
		{
			continue;
		}
		float temp_score = PlayerScore_Get(it, SP_SCORE);
		if (temp_score >= lowest_score)
		{
			continue;
		}
		//PrintToChatAll(sprintf(
		//	"Found %s with lowest score, checking allowed teams", it.netname));
		entity balance = TeamBalance_CheckAllowedTeams(it);
		if (TeamBalance_IsTeamAllowed(balance, source_team_index))
		{
			//PrintToChatAll("Allowed");
			lowest_player = it;
			lowest_score = temp_score;
		}
		else
		{
			//PrintToChatAll("Not allowed");
		}
		TeamBalance_Destroy(balance);
	});
	return lowest_player;
}

void LogTeamChange(float player_id, float team_number, int type)
{
	if (!autocvar_sv_eventlog)
	{
		return;
	}
	if (player_id < 1)
	{
		return;
	}
	GameLogEcho(sprintf(":team:%d:%d:%d", player_id, team_number, type));
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
		LOG_FATALF("Index is invalid: %f", index);
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
	// deduct bots that would leave if a player joined their team, distributing the deductions between teams
	int num_players_team_a = team_a.m_num_players;
	int num_players_team_b = team_b.m_num_players;
	if (IS_REAL_CLIENT(player) && bots_would_leave)
	{
		int bots_would_leave_remaining = bots_would_leave;
		int to_remove = min(team_a.m_num_bots, ceil(bots_would_leave_remaining * 0.5));
		num_players_team_a -= to_remove;
		bots_would_leave_remaining -= to_remove;
		num_players_team_b -= min(team_b.m_num_bots, bots_would_leave_remaining);
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

void SV_ChangeTeam(entity player, int new_color)
{
	if (!teamplay)
		SetPlayerColors(player, new_color);
}

bool QueueNeeded(entity ignore)
{
	if (!teamplay || warmup_stage || !autocvar_g_balance_teams_queue || autocvar_g_campaign || ignore.team > 0)
		return false;

	int human_clients = 0;
	FOREACH_CLIENT(IS_REAL_CLIENT(it),
	{
		if (++human_clients > 1)
			return TeamBalance_AreEqual(ignore, true);
	});
	return false;
}
