#include "teamplay.qh"

#include "client.qh"
#include "race.qh"
#include "scores.qh"
#include "scores_rules.qh"

#include "bot/api.qh"

#include "command/vote.qh"

#include "mutators/_mod.qh"

#include "../common/deathtypes/all.qh"
#include "../common/gamemodes/_mod.qh"
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
.entity m_lowest_human; ///< Human with the lowest score in a team.
.entity m_lowest_bot; ///< Bot with the lowest score in a team.

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

float Team_GetTeamScore(entity team_)
{
	return team_.m_team_score;
}

void Team_SetTeamScore(entity team_, float score)
{
	team_.m_team_score = score;
}

void TeamchangeFrags(entity e)
{
	PlayerScore_Clear(e);
}

void LogTeamchange(float player_id, float team_number, float type)
{
	if(!autocvar_sv_eventlog)
		return;

	if(player_id < 1)
		return;

	GameLogEcho(strcat(":team:", ftos(player_id), ":", ftos(team_number), ":", ftos(type)));
}

void default_delayedinit(entity this)
{
	if(!scores_initialized)
		ScoreRules_generic();
}

void InitGameplayMode()
{
	VoteReset();

	// find out good world mins/maxs bounds, either the static bounds found by looking for solid, or the mapinfo specified bounds
	get_mi_min_max(1);
	// assign reflectively to avoid "assignment to world" warning
	int done = 0; for (int i = 0, n = numentityfields(); i < n; ++i) {
	    string k = entityfieldname(i); vector v = (k == "mins") ? mi_min : (k == "maxs") ? mi_max : '0 0 0';
	    if (v) {
            putentityfieldstring(i, world, sprintf("%v", v));
            if (++done == 2) break;
        }
	}
	// currently, NetRadiant's limit is 131072 qu for each side
	// distance from one corner of a 131072qu cube to the opposite corner is approx. 227023 qu
	// set the distance according to map size but don't go over the limit to avoid issues with float precision
	// in case somebody makes extremely large maps
	max_shot_distance = min(230000, vlen(world.maxs - world.mins));

	MapInfo_LoadMapSettings(mapname);
	GameRules_teams(false);

	if (!cvar_value_issafe(world.fog))
	{
		LOG_INFO("The current map contains a potentially harmful fog setting, ignored");
		world.fog = string_null;
	}
	if(MapInfo_Map_fog != "")
		if(MapInfo_Map_fog == "none")
			world.fog = string_null;
		else
			world.fog = strzone(MapInfo_Map_fog);
	clientstuff = strzone(MapInfo_Map_clientstuff);

	MapInfo_ClearTemps();

	gamemode_name = MapInfo_Type_ToText(MapInfo_LoadedGametype);

	cache_mutatormsg = strzone("");
	cache_lastmutatormsg = strzone("");

	InitializeEntity(NULL, default_delayedinit, INITPRIO_GAMETYPE_FALLBACK);
}

string GetClientVersionMessage(entity this)
{
	if (CS(this).version_mismatch) {
		if(CS(this).version < autocvar_gameversion) {
			return strcat("This is Xonotic ", autocvar_g_xonoticversion,
				"\n^3Your client version is outdated.\n\n\n### YOU WON'T BE ABLE TO PLAY ON THIS SERVER ###\n\n\nPlease update!!!^8");
		} else {
			return strcat("This is Xonotic ", autocvar_g_xonoticversion,
				"\n^3This server is using an outdated Xonotic version.\n\n\n ### THIS SERVER IS INCOMPATIBLE AND THUS YOU CANNOT JOIN ###.^8");
		}
	} else {
		return strcat("Welcome to Xonotic ", autocvar_g_xonoticversion);
	}
}

string getwelcomemessage(entity this)
{
	MUTATOR_CALLHOOK(BuildMutatorsPrettyString, "");
	string modifications = M_ARGV(0, string);

	if(g_weaponarena)
	{
		if(g_weaponarena_random)
			modifications = strcat(modifications, ", ", ftos(g_weaponarena_random), " of ", g_weaponarena_list, " Arena");
		else
			modifications = strcat(modifications, ", ", g_weaponarena_list, " Arena");
	}
	else if(cvar("g_balance_blaster_weaponstartoverride") == 0)
		modifications = strcat(modifications, ", No start weapons");
	if(cvar("sv_gravity") < stof(cvar_defstring("sv_gravity")))
		modifications = strcat(modifications, ", Low gravity");
	if(g_weapon_stay && !g_cts)
		modifications = strcat(modifications, ", Weapons stay");
	if(g_jetpack)
		modifications = strcat(modifications, ", Jet pack");
	if(autocvar_g_powerups == 0)
		modifications = strcat(modifications, ", No powerups");
	if(autocvar_g_powerups > 0)
		modifications = strcat(modifications, ", Powerups");
	modifications = substring(modifications, 2, strlen(modifications) - 2);

	string versionmessage = GetClientVersionMessage(this);
	string s = strcat(versionmessage, "^8\n^8\nmatch type is ^1", gamemode_name, "^8\n");

	if(modifications != "")
		s = strcat(s, "^8\nactive modifications: ^3", modifications, "^8\n");

	if(cache_lastmutatormsg != autocvar_g_mutatormsg)
	{
		if(cache_lastmutatormsg)
			strunzone(cache_lastmutatormsg);
		if(cache_mutatormsg)
			strunzone(cache_mutatormsg);
		cache_lastmutatormsg = strzone(autocvar_g_mutatormsg);
		cache_mutatormsg = strzone(cache_lastmutatormsg);
	}

	if (cache_mutatormsg != "") {
		s = strcat(s, "\n\n^8special gameplay tips: ^7", cache_mutatormsg);
	}

	string mutator_msg = "";
	MUTATOR_CALLHOOK(BuildGameplayTipsString, mutator_msg);
	mutator_msg = M_ARGV(0, string);

	s = strcat(s, mutator_msg); // trust that the mutator will do proper formatting

	string motd = autocvar_sv_motd;
	if (motd != "") {
		s = strcat(s, "\n\n^8MOTD: ^7", strreplace("\\n", "\n", motd));
	}
	return s;
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

bool SetPlayerTeamSimple(entity player, int team_num)
{
	if (player.team == team_num)
	{
		// This is important when players join the game and one of their color
		// matches the team color while other doesn't. For example [BOT]Lion.
		SetPlayerColors(player, team_num - 1);
		return true;
	}
	int old_team_index = Team_TeamToIndex(player.team);
	int new_team_index = Team_TeamToIndex(team_num);
	if (MUTATOR_CALLHOOK(Player_ChangeTeam, player, old_team_index,
		new_team_index) == true)
	{
		// Mutator has blocked team change.
		return false;
	}
	SetPlayerColors(player, team_num - 1);
	MUTATOR_CALLHOOK(Player_ChangedTeam, player, old_team_index,
		new_team_index);
	return true;
}

bool SetPlayerTeam(entity player, int destination_team_index,
	int source_team_index, bool no_print)
{
	int team_num = Team_IndexToTeam(destination_team_index);
	if (!SetPlayerTeamSimple(player, team_num))
	{
		return false;
	}
	LogTeamchange(player.playerid, player.team, 3);  // log manual team join
	if (no_print)
	{
		return true;
	}
	bprint(playername(player, false), "^7 has changed from ",
		Team_IndexToColoredFullName(source_team_index), "^7 to ",
		Team_IndexToColoredFullName(destination_team_index), "\n");
	return true;
}

entity TeamBalance_CheckAllowedTeams(entity for_whom)
{
	entity balance = spawn();
	for (int i = 0; i < NUM_TEAMS; ++i)
	{
		entity team_ = balance.m_team_balance_team[i] = spawn();
		team_.m_team_score = g_team_entities[i].m_team_score;
		team_.m_num_players = TEAM_NOT_ALLOWED;
		team_.m_num_bots = 0;
		team_.m_lowest_human = NULL;
		team_.m_lowest_bot = NULL;
	}
	
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
		remove(balance.(m_team_balance_team[i]));
	}
	remove(balance);
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
			entity team_ = TeamBalance_GetTeamFromIndex(balance, i);
			if (TeamBalanceTeam_IsAllowed(team_))
			{
				MUTATOR_CALLHOOK(TeamBalance_GetTeamCount, Team_IndexToTeam(i),
					ignore, team_.m_num_players, team_.m_num_bots,
					team_.m_lowest_human, team_.m_lowest_bot);
				team_.m_num_players = M_ARGV(2, float);
				team_.m_num_bots = M_ARGV(3, float);
				team_.m_lowest_human = M_ARGV(4, entity);
				team_.m_lowest_bot = M_ARGV(5, entity);
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
			entity team_ = TeamBalance_GetTeam(balance, team_num);
			if (!TeamBalanceTeam_IsAllowed(team_))
			{
				continue;
			}
			++team_.m_num_players;
			if (IS_BOT_CLIENT(it))
			{
				++team_.m_num_bots;
			}
			float temp_score = PlayerScore_Get(it, SP_SCORE);
			if (!IS_BOT_CLIENT(it))
			{
				if (team_.m_lowest_human == NULL)
				{
					team_.m_lowest_human = it;
					continue;
				}
				if (temp_score < PlayerScore_Get(team_.m_lowest_human,
					SP_SCORE))
				{
					team_.m_lowest_human = it;
				}
				continue;
			}
			if (team_.m_lowest_bot == NULL)
			{
				team_.m_lowest_bot = it;
				continue;
			}
			if (temp_score < PlayerScore_Get(team_.m_lowest_bot, SP_SCORE))
			{
				team_.m_lowest_bot = it;
			}
		});
	}

	// if the player who has a forced team has not joined yet, reserve the spot
	if (autocvar_g_campaign)
	{
		if (Team_IsValidIndex(autocvar_g_campaign_forceteam))
		{
			entity team_ = TeamBalance_GetTeamFromIndex(balance,
				autocvar_g_campaign_forceteam);
			if (team_.m_num_players == team_.m_num_bots)
			{
				++team_.m_num_players;
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

void TeamBalance_JoinBestTeam(entity this, bool force_best_team)
{
	// don't join a team if we're not playing a team game
	if (!teamplay)
	{
		return;
	}

	// find out what teams are available
	entity balance = TeamBalance_CheckAllowedTeams(this);

	// if we don't care what team they end up on, put them on whatever team they entered as.
	// if they're not on a valid team, then let other code put them on the smallest team
	if (!force_best_team)
	{
		int selected_team_num = -1;
		for (int i = 1; i <= NUM_TEAMS; ++i)
		{
			if (TeamBalance_IsTeamAllowedInternal(balance, i) && (this.team ==
				Team_IndexToTeam(i)))
			{
				selected_team_num = this.team;
				break;
			}
		}
		
		if (Team_IsValidTeam(selected_team_num))
		{
			SetPlayerTeamSimple(this, selected_team_num);
			LogTeamchange(this.playerid, this.team, 99);
			TeamBalance_Destroy(balance);
			return;
		}
	}
	// otherwise end up on the smallest team (handled below)
	if (this.bot_forced_team)
	{
		TeamBalance_Destroy(balance);
		return;
	}
	int best_team_index = TeamBalance_FindBestTeam(balance, this, true);
	int best_team_num = Team_IndexToTeam(best_team_index);
	int old_team_index = Team_TeamToIndex(this.team);
	TeamchangeFrags(this);
	SetPlayerTeamSimple(this, best_team_num);
	LogTeamchange(this.playerid, this.team, 2); // log auto join
	if ((old_team_index != -1) && !IS_BOT_CLIENT(this))
	{
		TeamBalance_AutoBalanceBots(balance, old_team_index, best_team_index);
	}
	KillPlayerForTeamChange(this);
	TeamBalance_Destroy(balance);
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

void TeamBalance_AutoBalanceBots(entity balance, int source_team_index,
	int destination_team_index)
{
	if (balance == NULL)
	{
		LOG_FATAL("TeamBalance_AutoBalanceBots: Team balance entity is NULL.");
	}
	if (balance.m_team_balance_state != TEAM_BALANCE_TEAM_COUNTS_FILLED)
	{
		LOG_FATAL("TeamBalance_AutoBalanceBots: "
			"TeamBalance_GetTeamCounts has not been called.");
	}
	if (!Team_IsValidIndex(source_team_index))
	{
		LOG_WARNF("AutoBalanceBots: Source team index is invalid: %f",
			source_team_index);
		return;
	}
	if (!Team_IsValidIndex(destination_team_index))
	{
		LOG_WARNF("AutoBalanceBots: Destination team index is invalid: %f",
			destination_team_index);
		return;
	}
	if (!autocvar_g_balance_teams ||
		!autocvar_g_balance_teams_prevent_imbalance)
	{
		return;
	}
	entity source_team = TeamBalance_GetTeamFromIndex(balance,
		source_team_index);
	if (!TeamBalanceTeam_IsAllowed(source_team))
	{
		return;
	}
	entity destination_team = TeamBalance_GetTeamFromIndex(balance,
		destination_team_index);
	if ((destination_team.m_num_players <= source_team.m_num_players) ||
		(destination_team.m_lowest_bot == NULL))
	{
		return;
	}
	SetPlayerTeamSimple(destination_team.m_lowest_bot,
		Team_IndexToTeam(source_team_index));
	KillPlayerForTeamChange(destination_team.m_lowest_bot);
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

bool TeamBalanceTeam_IsAllowed(entity team_)
{
	return team_.m_num_players != TEAM_NOT_ALLOWED;
}

int TeamBalanceTeam_GetNumberOfPlayers(entity team_)
{
	return team_.m_num_players;
}

int TeamBalanceTeam_GetNumberOfBots(entity team_)
{
	return team_.m_num_bots;
}

entity TeamBalanceTeam_GetLowestHuman(entity team_)
{
	return team_.m_lowest_human;
}

entity TeamBalanceTeam_GetLowestBot(entity team_)
{
	return team_.m_lowest_bot;
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

void SV_ChangeTeam(entity this, float _color)
{
	int source_color, destination_color;
	int source_team_index, destination_team_index;

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
		SetPlayerTeam(this, destination_team_index, source_team_index, true);
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
	if (IS_PLAYER(this) && source_team_index != destination_team_index)
	{
		// reduce frags during a team change
		TeamchangeFrags(this);
	}
	if (!SetPlayerTeam(this, destination_team_index, source_team_index,
		!IS_CLIENT(this)))
	{
		TeamBalance_Destroy(balance);
		return;
	}
	TeamBalance_AutoBalanceBots(balance, source_team_index,
		destination_team_index);
	if (!IS_PLAYER(this) || (source_team_index == destination_team_index))
	{
		TeamBalance_Destroy(balance);
		return;
	}
	KillPlayerForTeamChange(this);
	TeamBalance_Destroy(balance);
}
