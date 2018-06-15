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
			modifications = strcat(modifications, ", ", ftos(g_weaponarena_random), " of ", g_weaponarena_list, " Arena"); // TODO: somehow get this into the mutator
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
		modifications = strcat(modifications, ", Jetpack");
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
		strcpy(cache_lastmutatormsg, autocvar_g_mutatormsg);
		strcpy(cache_mutatormsg, cache_lastmutatormsg);
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
	Damage(player, player, player, 100000, DEATH_TEAMCHANGE.m_id, DMG_NOWEP, player.origin,
		'0 0 0');
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
	if (MUTATOR_CALLHOOK(Player_ChangeTeam, player, Team_TeamToNumber(
		player.team), Team_TeamToNumber(team_num)) == true)
	{
		// Mutator has blocked team change.
		return false;
	}
	int old_team = player.team;
	SetPlayerColors(player, team_num - 1);
	MUTATOR_CALLHOOK(Player_ChangedTeam, player, old_team, player.team);
	return true;
}

bool SetPlayerTeam(entity player, int destination_team, int source_team,
	bool no_print)
{
	int team_num = Team_NumberToTeam(destination_team);
	if (!SetPlayerTeamSimple(player, team_num))
	{
		return false;
	}
	LogTeamchange(player.playerid, player.team, 3);  // log manual team join
	if (no_print)
	{
		return true;
	}
	bprint(playername(player, false), "^7 has changed from ", Team_NumberToColoredFullName(source_team), "^7 to ", Team_NumberToColoredFullName(destination_team), "\n");
	return true;
}

// set c1...c4 to show what teams are allowed
void CheckAllowedTeams(entity for_whom)
{
	int teams_mask = 0;

	c1 = c2 = c3 = c4 = -1;
	num_bots_team1 = num_bots_team2 = num_bots_team3 = num_bots_team4 = 0;

	string teament_name = string_null;

	bool mutator_returnvalue = MUTATOR_CALLHOOK(CheckAllowedTeams, teams_mask, teament_name, for_whom);
	teams_mask = M_ARGV(0, float);
	teament_name = M_ARGV(1, string);

	if(!mutator_returnvalue)
	{
		if(teams_mask & BIT(0)) c1 = 0;
		if(teams_mask & BIT(1)) c2 = 0;
		if(teams_mask & BIT(2)) c3 = 0;
		if(teams_mask & BIT(3)) c4 = 0;
	}

	// find out what teams are allowed if necessary
	if(teament_name)
	{
		entity head = find(NULL, classname, teament_name);
		while(head)
		{
			switch(head.team)
			{
				case NUM_TEAM_1: c1 = 0; break;
				case NUM_TEAM_2: c2 = 0; break;
				case NUM_TEAM_3: c3 = 0; break;
				case NUM_TEAM_4: c4 = 0; break;
			}

			head = find(head, classname, teament_name);
		}
	}

	// TODO: Balance quantity of bots across > 2 teams when bot_vs_human is set (and remove next line)
	if(AvailableTeams() == 2)
	if(autocvar_bot_vs_human && for_whom)
	{
		if(autocvar_bot_vs_human > 0)
		{
			// find last team available

			if(IS_BOT_CLIENT(for_whom))
			{
				if(c4 >= 0) { c3 = c2 = c1 = -1; }
				else if(c3 >= 0) { c4 = c2 = c1 = -1; }
				else { c4 = c3 = c1 = -1; }
				// no further cases, we know at least 2 teams exist
			}
			else
			{
				if(c1 >= 0) { c2 = c3 = c4 = -1; }
				else if(c2 >= 0) { c1 = c3 = c4 = -1; }
				else { c1 = c2 = c4 = -1; }
				// no further cases, bots have one of the teams
			}
		}
		else
		{
			// find first team available

			if(IS_BOT_CLIENT(for_whom))
			{
				if(c1 >= 0) { c2 = c3 = c4 = -1; }
				else if(c2 >= 0) { c1 = c3 = c4 = -1; }
				else { c1 = c2 = c4 = -1; }
				// no further cases, we know at least 2 teams exist
			}
			else
			{
				if(c4 >= 0) { c3 = c2 = c1 = -1; }
				else if(c3 >= 0) { c4 = c2 = c1 = -1; }
				else { c4 = c3 = c1 = -1; }
				// no further cases, bots have one of the teams
			}
		}
	}

	if(!for_whom)
		return;

	// if player has a forced team, ONLY allow that one
	if(for_whom.team_forced == NUM_TEAM_1 && c1 >= 0)
		c2 = c3 = c4 = -1;
	else if(for_whom.team_forced == NUM_TEAM_2 && c2 >= 0)
		c1 = c3 = c4 = -1;
	else if(for_whom.team_forced == NUM_TEAM_3 && c3 >= 0)
		c1 = c2 = c4 = -1;
	else if(for_whom.team_forced == NUM_TEAM_4 && c4 >= 0)
		c1 = c2 = c3 = -1;
}

float PlayerValue(entity p)
{
	return 1;
	// FIXME: it always returns 1...
}

// c1...c4 should be set to -1 (not allowed) or 0 (allowed).
// teams that are allowed will now have their player counts stored in c1...c4
void GetTeamCounts(entity ignore)
{
	if (MUTATOR_CALLHOOK(GetTeamCounts) == true)
	{
		if (c1 >= 0)
		{
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_1, ignore, c1,
				num_bots_team1, lowest_human_team1, lowest_bot_team1);
			c1 = M_ARGV(2, float);
			num_bots_team1 = M_ARGV(3, float);
			lowest_human_team1 = M_ARGV(4, entity);
			lowest_bot_team1 = M_ARGV(5, entity);
		}
		if (c2 >= 0)
		{
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_2, ignore, c2,
				num_bots_team2, lowest_human_team2, lowest_bot_team2);
			c2 = M_ARGV(2, float);
			num_bots_team2 = M_ARGV(3, float);
			lowest_human_team2 = M_ARGV(4, entity);
			lowest_bot_team2 = M_ARGV(5, entity);
		}
		if (c3 >= 0)
		{
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_3, ignore, c3,
				num_bots_team3, lowest_human_team3, lowest_bot_team3);
			c3 = M_ARGV(2, float);
			num_bots_team3 = M_ARGV(3, float);
			lowest_human_team3 = M_ARGV(4, entity);
			lowest_bot_team3 = M_ARGV(5, entity);
		}
		if (c4 >= 0)
		{
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_4, ignore,
				c4, num_bots_team4, lowest_human_team4, lowest_bot_team4);
			c4 = M_ARGV(2, float);
			num_bots_team4 = M_ARGV(3, float);
			lowest_human_team4 = M_ARGV(4, entity);
			lowest_bot_team4 = M_ARGV(5, entity);
		}
	}
	else
	{
		float value, bvalue;
		// now count how many players are on each team already
		float lowest_human_score1 = FLOAT_MAX;
		float lowest_bot_score1 = FLOAT_MAX;
		float lowest_human_score2 = FLOAT_MAX;
		float lowest_bot_score2 = FLOAT_MAX;
		float lowest_human_score3 = FLOAT_MAX;
		float lowest_bot_score3 = FLOAT_MAX;
		float lowest_human_score4 = FLOAT_MAX;
		float lowest_bot_score4 = FLOAT_MAX;
		FOREACH_CLIENT(true,
		{
			float t;
			if (IS_PLAYER(it) || it.caplayer)
			{
				t = it.team;
			}
			else if (it.team_forced > 0)
			{
				t = it.team_forced; // reserve the spot
			}
			else
			{
				continue;
			}
			if (it == ignore)
			{
				continue;
			}
			value = PlayerValue(it);
			if (IS_BOT_CLIENT(it))
			{
				bvalue = value;
			}
			else
			{
				bvalue = 0;
			}
			if (value == 0)
			{
				continue;
			}
			switch (t)
			{
				case NUM_TEAM_1:
				{
					if (c1 < 0)
					{
						break;
					}
					c1 += value;
					num_bots_team1 += bvalue;
					float temp_score = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (temp_score < lowest_human_score1)
						{
							lowest_human_team1 = it;
							lowest_human_score1 = temp_score;
						}
						break;
					}
					if (temp_score < lowest_bot_score1)
					{
						lowest_bot_team1 = it;
						lowest_bot_score1 = temp_score;
					}
					break;
				}
				case NUM_TEAM_2:
				{
					if (c2 < 0)
					{
						break;
					}
					c2 += value;
					num_bots_team2 += bvalue;
					float temp_score = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (temp_score < lowest_human_score2)
						{
							lowest_human_team2 = it;
							lowest_human_score2 = temp_score;
						}
						break;
					}
					if (temp_score < lowest_bot_score2)
					{
						lowest_bot_team2 = it;
						lowest_bot_score2 = temp_score;
					}
					break;
				}
				case NUM_TEAM_3:
				{
					if (c3 < 0)
					{
						break;
					}
					c3 += value;
					num_bots_team3 += bvalue;
					float temp_score = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (temp_score < lowest_human_score3)
						{
							lowest_human_team3 = it;
							lowest_human_score3 = temp_score;
						}
						break;
					}
					if (temp_score < lowest_bot_score3)
					{
						lowest_bot_team3 = it;
						lowest_bot_score3 = temp_score;
					}
					break;
				}
				case NUM_TEAM_4:
				{
					if (c4 < 0)
					{
						break;
					}
					c4 += value;
					num_bots_team4 += bvalue;
					float temp_score = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (temp_score < lowest_human_score4)
						{
							lowest_human_team4 = it;
							lowest_human_score4 = temp_score;
						}
						break;
					}
					if (temp_score < lowest_bot_score4)
					{
						lowest_bot_team4 = it;
						lowest_bot_score4 = temp_score;
					}
					break;
				}
			}
		});
	}

	// if the player who has a forced team has not joined yet, reserve the spot
	if(autocvar_g_campaign)
	{
		switch(autocvar_g_campaign_forceteam)
		{
			case 1: if(c1 == num_bots_team1) ++c1; break;
			case 2: if(c2 == num_bots_team2) ++c2; break;
			case 3: if(c3 == num_bots_team3) ++c3; break;
			case 4: if(c4 == num_bots_team4) ++c4; break;
		}
	}
}

bool IsTeamSmallerThanTeam(int team_a, int team_b, entity player,
	bool use_score)
{
	if (!Team_IsValidNumber(team_a))
	{
		LOG_FATALF("IsTeamSmallerThanTeam: team_a is invalid: %f", team_a);
	}
	if (!Team_IsValidNumber(team_b))
	{
		LOG_FATALF("IsTeamSmallerThanTeam: team_b is invalid: %f", team_b);
	}
	if (team_a == team_b)
	{
		return false;
	}
	// we assume that CheckAllowedTeams and GetTeamCounts have already been called
	int num_players_team_a = -1, num_players_team_b = -1;
	int num_bots_team_a = 0, num_bots_team_b = 0;
	float score_team_a = 0, score_team_b = 0;
	switch (team_a)
	{
		case 1:
		{
			num_players_team_a = c1;
			num_bots_team_a = num_bots_team1;
			score_team_a = team1_score;
			break;
		}
		case 2:
		{
			num_players_team_a = c2;
			num_bots_team_a = num_bots_team2;
			score_team_a = team2_score;
			break;
		}
		case 3:
		{
			num_players_team_a = c3;
			num_bots_team_a = num_bots_team3;
			score_team_a = team3_score;
			break;
		}
		case 4:
		{
			num_players_team_a = c4;
			num_bots_team_a = num_bots_team4;
			score_team_a = team4_score;
			break;
		}
	}
	switch (team_b)
	{
		case 1:
		{
			num_players_team_b = c1;
			num_bots_team_b = num_bots_team1;
			score_team_b = team1_score;
			break;
		}
		case 2:
		{
			num_players_team_b = c2;
			num_bots_team_b = num_bots_team2;
			score_team_b = team2_score;
			break;
		}
		case 3:
		{
			num_players_team_b = c3;
			num_bots_team_b = num_bots_team3;
			score_team_b = team3_score;
			break;
		}
		case 4:
		{
			num_players_team_b = c4;
			num_bots_team_b = num_bots_team4;
			score_team_b = team4_score;
			break;
		}
	}
	// invalid
	if (num_players_team_a < 0 || num_players_team_b < 0)
	{
		return false;
	}
	if (IS_REAL_CLIENT(player) && bots_would_leave)
	{
		num_players_team_a -= num_bots_team_a;
		num_players_team_b -= num_bots_team_b;
	}
	if (!use_score)
	{
		return num_players_team_a < num_players_team_b;
	}
	if (num_players_team_a < num_players_team_b)
	{
		return true;
	}
	if (num_players_team_a > num_players_team_b)
	{
		return false;
	}
	return score_team_a < score_team_b;
}

bool IsTeamEqualToTeam(int team_a, int team_b, entity player, bool use_score)
{
	if (!Team_IsValidNumber(team_a))
	{
		LOG_FATALF("IsTeamEqualToTeam: team_a is invalid: %f", team_a);
	}
	if (!Team_IsValidNumber(team_b))
	{
		LOG_FATALF("IsTeamEqualToTeam: team_b is invalid: %f", team_b);
	}
	if (team_a == team_b)
	{
		return true;
	}
	// we assume that CheckAllowedTeams and GetTeamCounts have already been called
	int num_players_team_a = -1, num_players_team_b = -1;
	int num_bots_team_a = 0, num_bots_team_b = 0;
	float score_team_a = 0, score_team_b = 0;
	switch (team_a)
	{
		case 1:
		{
			num_players_team_a = c1;
			num_bots_team_a = num_bots_team1;
			score_team_a = team1_score;
			break;
		}
		case 2:
		{
			num_players_team_a = c2;
			num_bots_team_a = num_bots_team2;
			score_team_a = team2_score;
			break;
		}
		case 3:
		{
			num_players_team_a = c3;
			num_bots_team_a = num_bots_team3;
			score_team_a = team3_score;
			break;
		}
		case 4:
		{
			num_players_team_a = c4;
			num_bots_team_a = num_bots_team4;
			score_team_a = team4_score;
			break;
		}
	}
	switch (team_b)
	{
		case 1:
		{
			num_players_team_b = c1;
			num_bots_team_b = num_bots_team1;
			score_team_b = team1_score;
			break;
		}
		case 2:
		{
			num_players_team_b = c2;
			num_bots_team_b = num_bots_team2;
			score_team_b = team2_score;
			break;
		}
		case 3:
		{
			num_players_team_b = c3;
			num_bots_team_b = num_bots_team3;
			score_team_b = team3_score;
			break;
		}
		case 4:
		{
			num_players_team_b = c4;
			num_bots_team_b = num_bots_team4;
			score_team_b = team4_score;
			break;
		}
	}
	// invalid
	if (num_players_team_a < 0 || num_players_team_b < 0)
		return false;

	if (IS_REAL_CLIENT(player) && bots_would_leave)
	{
		num_players_team_a -= num_bots_team_a;
		num_players_team_b -= num_bots_team_b;
	}
	if (!use_score)
	{
		return num_players_team_a == num_players_team_b;
	}
	if (num_players_team_a != num_players_team_b)
	{
		return false;
	}
	return score_team_a == score_team_b;
}

int FindBestTeams(entity player, bool use_score)
{
	if (MUTATOR_CALLHOOK(FindBestTeams, player) == true)
	{
		return M_ARGV(1, float);
	}
	int team_bits = 0;
	int previous_team = 0;
	if (c1 >= 0)
	{
		team_bits = BIT(0);
		previous_team = 1;
	}
	if (c2 >= 0)
	{
		if (previous_team == 0)
		{
			team_bits = BIT(1);
			previous_team = 2;
		}
		else if (IsTeamSmallerThanTeam(2, previous_team, player, use_score))
		{
			team_bits = BIT(1);
			previous_team = 2;
		}
		else if (IsTeamEqualToTeam(2, previous_team, player, use_score))
		{
			team_bits |= BIT(1);
			previous_team = 2;
		}
	}
	if (c3 >= 0)
	{
		if (previous_team == 0)
		{
			team_bits = BIT(2);
			previous_team = 3;
		}
		else if (IsTeamSmallerThanTeam(3, previous_team, player, use_score))
		{
			team_bits = BIT(2);
			previous_team = 3;
		}
		else if (IsTeamEqualToTeam(3, previous_team, player, use_score))
		{
			team_bits |= BIT(2);
			previous_team = 3;
		}
	}
	if (c4 >= 0)
	{
		if (previous_team == 0)
		{
			team_bits = BIT(3);
		}
		else if (IsTeamSmallerThanTeam(4, previous_team, player, use_score))
		{
			team_bits = BIT(3);
		}
		else if (IsTeamEqualToTeam(4, previous_team, player, use_score))
		{
			team_bits |= BIT(3);
		}
	}
	return team_bits;
}

// returns # of smallest team (1, 2, 3, 4)
// NOTE: Assumes CheckAllowedTeams has already been called!
int FindSmallestTeam(entity player, float ignore_player)
{
	// count how many players are in each team
	if (ignore_player)
	{
		GetTeamCounts(player);
	}
	else
	{
		GetTeamCounts(NULL);
	}
	int team_bits = FindBestTeams(player, true);
	if (team_bits == 0)
	{
		error(sprintf("No teams available for %s\n", MapInfo_Type_ToString(MapInfo_CurrentGametype())));
	}
	RandomSelection_Init();
	if ((team_bits & BIT(0)) != 0)
	{
		RandomSelection_AddFloat(1, 1, 1);
	}
	if ((team_bits & BIT(1)) != 0)
	{
		RandomSelection_AddFloat(2, 1, 1);
	}
	if ((team_bits & BIT(2)) != 0)
	{
		RandomSelection_AddFloat(3, 1, 1);
	}
	if ((team_bits & BIT(3)) != 0)
	{
		RandomSelection_AddFloat(4, 1, 1);
	}
	return RandomSelection_chosen_float;
}

void JoinBestTeam(entity this, bool force_best_team)
{
	// don't join a team if we're not playing a team game
	if (!teamplay)
	{
		return;
	}

	// find out what teams are available
	CheckAllowedTeams(this);

	// if we don't care what team they end up on, put them on whatever team they entered as.
	// if they're not on a valid team, then let other code put them on the smallest team
	if (!force_best_team)
	{
		int selected_team;
		if ((c1 >= 0) && (this.team == NUM_TEAM_1))
		{
			selected_team = this.team;
		}
		else if ((c2 >= 0) && (this.team == NUM_TEAM_2))
		{
			selected_team = this.team;
		}
		else if ((c3 >= 0) && (this.team == NUM_TEAM_3))
		{
			selected_team = this.team;
		}
		else if ((c4 >= 0) && (this.team == NUM_TEAM_4))
		{
			selected_team = this.team;
		}
		else
		{
			selected_team = -1;
		}

		if (selected_team > 0)
		{
			SetPlayerTeamSimple(this, selected_team);
			LogTeamchange(this.playerid, this.team, 99);
			return;
		}
	}
	// otherwise end up on the smallest team (handled below)
	if (this.bot_forced_team)
	{
		return;
	}
	int best_team = FindSmallestTeam(this, true);
	best_team = Team_NumberToTeam(best_team);
	if (best_team == -1)
	{
		error("JoinBestTeam: invalid team\n");
	}
	int old_team = Team_TeamToNumber(this.team);
	TeamchangeFrags(this);
	SetPlayerTeamSimple(this, best_team);
	LogTeamchange(this.playerid, this.team, 2); // log auto join
	if ((old_team != -1) && !IS_BOT_CLIENT(this))
	{
		AutoBalanceBots(old_team, Team_TeamToNumber(best_team));
	}
	KillPlayerForTeamChange(this);
}

void SV_ChangeTeam(entity this, float _color)
{
	float source_color, destination_color, source_team, destination_team;

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

	source_team = Team_TeamToNumber(source_color + 1);
	destination_team = Team_TeamToNumber(destination_color + 1);

	if (destination_team == -1)
	{
		return;
	}

	CheckAllowedTeams(this);

	if (destination_team == 1 && c1 < 0) destination_team = 4;
	if (destination_team == 4 && c4 < 0) destination_team = 3;
	if (destination_team == 3 && c3 < 0) destination_team = 2;
	if (destination_team == 2 && c2 < 0) destination_team = 1;

	// not changing teams
	if (source_color == destination_color)
	{
		SetPlayerTeam(this, destination_team, source_team, true);
		return;
	}

	if((autocvar_g_campaign) || (autocvar_g_changeteam_banned && CS(this).wasplayer)) {
		Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_NOTALLOWED);
		return; // changing teams is not allowed
	}

	// autocvar_g_balance_teams_prevent_imbalance only makes sense if autocvar_g_balance_teams is on, as it makes the team selection dialog pointless
	if (autocvar_g_balance_teams && autocvar_g_balance_teams_prevent_imbalance)
	{
		GetTeamCounts(this);
		if ((BIT(destination_team - 1) & FindBestTeams(this, false)) == 0)
		{
			Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_LARGERTEAM);
			return;
		}
	}
	if(IS_PLAYER(this) && source_team != destination_team)
	{
		// reduce frags during a team change
		TeamchangeFrags(this);
	}
	if (!SetPlayerTeam(this, destination_team, source_team, !IS_CLIENT(this)))
	{
		return;
	}
	AutoBalanceBots(source_team, destination_team);
	if (!IS_PLAYER(this) || (source_team == destination_team))
	{
		return;
	}
	KillPlayerForTeamChange(this);
}

void AutoBalanceBots(int source_team, int destination_team)
{
	if (!Team_IsValidNumber(source_team))
	{
		LOG_WARNF("AutoBalanceBots: Source team is invalid: %f", source_team);
		return;
	}
	if (!Team_IsValidNumber(destination_team))
	{
		LOG_WARNF("AutoBalanceBots: Destination team is invalid: %f",
			destination_team);
		return;
	}
	if (!autocvar_g_balance_teams ||
		!autocvar_g_balance_teams_prevent_imbalance)
	{
		return;
	}
	int num_players_source_team = 0;
	int num_players_destination_team = 0;
	entity lowest_bot_destination_team = NULL;
	switch (source_team)
	{
		case 1:
		{
			num_players_source_team = c1;
			break;
		}
		case 2:
		{
			num_players_source_team = c2;
			break;
		}
		case 3:
		{
			num_players_source_team = c3;
			break;
		}
		case 4:
		{
			num_players_source_team = c4;
			break;
		}
	}
	if (num_players_source_team < 0)
	{
		return;
	}
	switch (destination_team)
	{
		case 1:
		{
			num_players_destination_team = c1;
			lowest_bot_destination_team = lowest_bot_team1;
			break;
		}
		case 2:
		{
			num_players_destination_team = c2;
			lowest_bot_destination_team = lowest_bot_team2;
			break;
		}
		case 3:
		{
			num_players_destination_team = c3;
			lowest_bot_destination_team = lowest_bot_team3;
			break;
		}
		case 4:
		{
			num_players_destination_team = c4;
			lowest_bot_destination_team = lowest_bot_team4;
			break;
		}
	}
	if ((num_players_destination_team <= num_players_source_team) ||
		(lowest_bot_destination_team == NULL))
	{
		return;
	}
	SetPlayerTeamSimple(lowest_bot_destination_team,
		Team_NumberToTeam(source_team));
	KillPlayerForTeamChange(lowest_bot_destination_team);
}
