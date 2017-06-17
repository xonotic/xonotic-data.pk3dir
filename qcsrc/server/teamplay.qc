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

void ActivateTeamplay()
{
	serverflags |= SERVERFLAG_TEAMPLAY;
	teamplay = 1;
	cvar_set("teamplay", "2");  // DP needs this for sending proper getstatus replies.
}

void InitGameplayMode()
{
	VoteReset();

	// find out good world mins/maxs bounds, either the static bounds found by looking for solid, or the mapinfo specified bounds
	get_mi_min_max(1);
	world.mins = mi_min;
	world.maxs = mi_max;
	// currently, NetRadiant's limit is 131072 qu for each side
	// distance from one corner of a 131072qu cube to the opposite corner is approx. 227023 qu
	// set the distance according to map size but don't go over the limit to avoid issues with float precision
	// in case somebody makes extremely large maps
	max_shot_distance = min(230000, vlen(world.maxs - world.mins));

	MapInfo_LoadMapSettings(mapname);
	serverflags &= ~SERVERFLAG_TEAMPLAY;
	teamplay = 0;
	cvar_set("teamplay", "0");  // DP needs this for sending proper getstatus replies.

	if (!cvar_value_issafe(world.fog))
	{
		LOG_INFO("The current map contains a potentially harmful fog setting, ignored\n");
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
	if (this.version_mismatch) {
		if(this.version < autocvar_gameversion) {
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

bool SetPlayerTeamSimple(entity player, int teamnum)
{
	if (player.team == teamnum)
	{
		// This is important when players join the game and one of their color
		// matches the team color while other doesn't. For example [BOT]Lion.
		SetPlayerColors(player, teamnum - 1);
		return true;
	}
	if (MUTATOR_CALLHOOK(Player_ChangeTeam, player, Team_TeamToNumber(
		player.team), Team_TeamToNumber(teamnum)) == true)
	{
		// Mutator has blocked team change.
		return false;
	}
	int oldteam = player.team;
	SetPlayerColors(player, teamnum - 1);
	MUTATOR_CALLHOOK(Player_ChangedTeam, player, oldteam, player.team);
	return true;
}

void SetPlayerTeam(entity player, int destinationteam, int sourceteam, bool noprint)
{
	int teamnum = Team_NumberToTeam(destinationteam);
	if (!SetPlayerTeamSimple(player, teamnum))
	{
		return;
	}
	LogTeamchange(player.playerid, player.team, 3);  // log manual team join
	if (noprint)
	{
		return;
	}
	bprint(playername(player, false), "^7 has changed from ", Team_NumberToColoredFullName(sourceteam), "^7 to ", Team_NumberToColoredFullName(destinationteam), "\n");
}

// set c1...c4 to show what teams are allowed
void CheckAllowedTeams (entity for_whom)
{
	int teams_mask = 0;

	c1 = c2 = c3 = c4 = -1;
	numbotsteam1 = numbotsteam2 = numbotsteam3 = numbotsteam4 = 0;

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
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_1, ignore, c1, numbotsteam1,
				lowestplayerteam1, lowestbotteam1);
			c1 = M_ARGV(2, float);
			numbotsteam1 = M_ARGV(3, float);
			lowestplayerteam1 = M_ARGV(4, entity);
			lowestbotteam1 = M_ARGV(5, entity);
		}
		if (c2 >= 0)
		{
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_2, ignore, c2, numbotsteam2,
				lowestplayerteam2, lowestbotteam2);
			c2 = M_ARGV(2, float);
			numbotsteam2 = M_ARGV(3, float);
			lowestplayerteam2 = M_ARGV(4, entity);
			lowestbotteam2 = M_ARGV(5, entity);
		}
		if (c3 >= 0)
		{
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_3, ignore, c3, numbotsteam3,
				lowestplayerteam3, lowestbotteam3);
			c3 = M_ARGV(2, float);
			numbotsteam3 = M_ARGV(3, float);
			lowestplayerteam3 = M_ARGV(4, entity);
			lowestbotteam3 = M_ARGV(5, entity);
		}
		if (c4 >= 0)
		{
			MUTATOR_CALLHOOK(GetTeamCount, NUM_TEAM_4, ignore, c4, numbotsteam4,
				lowestplayerteam4, lowestbotteam4);
			c4 = M_ARGV(2, float);
			numbotsteam4 = M_ARGV(3, float);
			lowestplayerteam4 = M_ARGV(4, entity);
			lowestbotteam4 = M_ARGV(5, entity);
		}
	}
	else
	{
		float value, bvalue;
		// now count how many players are on each team already
		float lowestplayerscore1 = FLOAT_MAX;
		float lowestbotscore1 = FLOAT_MAX;
		float lowestplayerscore2 = FLOAT_MAX;
		float lowestbotscore2 = FLOAT_MAX;
		float lowestplayerscore3 = FLOAT_MAX;
		float lowestbotscore3 = FLOAT_MAX;
		float lowestplayerscore4 = FLOAT_MAX;
		float lowestbotscore4 = FLOAT_MAX;
		FOREACH_CLIENT(true, LAMBDA(
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
					numbotsteam1 += bvalue;
					float tempscore = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (tempscore < lowestplayerscore1)
						{
							lowestplayerteam1 = it;
							lowestplayerscore1 = tempscore;
						}
						break;
					}
					if (tempscore < lowestbotscore1)
					{
						lowestbotteam1 = it;
						lowestbotscore1 = tempscore;
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
					numbotsteam2 += bvalue;
					float tempscore = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (tempscore < lowestplayerscore2)
						{
							lowestplayerteam2 = it;
							lowestplayerscore2 = tempscore;
						}
						break;
					}
					if (tempscore < lowestbotscore2)
					{
						lowestbotteam2 = it;
						lowestbotscore2 = tempscore;
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
					numbotsteam3 += bvalue;
					float tempscore = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (tempscore < lowestplayerscore3)
						{
							lowestplayerteam3 = it;
							lowestplayerscore3 = tempscore;
						}
						break;
					}
					if (tempscore < lowestbotscore3)
					{
						lowestbotteam3 = it;
						lowestbotscore3 = tempscore;
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
					numbotsteam4 += bvalue;
					float tempscore = PlayerScore_Get(it, SP_SCORE);
					if (!bvalue)
					{
						if (tempscore < lowestplayerscore4)
						{
							lowestplayerteam4 = it;
							lowestplayerscore4 = tempscore;
						}
						break;
					}
					if (tempscore < lowestbotscore4)
					{
						lowestbotteam4 = it;
						lowestbotscore4 = tempscore;
					}
					break;
				}
			}
		));
	}

	// if the player who has a forced team has not joined yet, reserve the spot
	if(autocvar_g_campaign)
	{
		switch(autocvar_g_campaign_forceteam)
		{
			case 1: if(c1 == numbotsteam1) ++c1; break;
			case 2: if(c2 == numbotsteam2) ++c2; break;
			case 3: if(c3 == numbotsteam3) ++c3; break;
			case 4: if(c4 == numbotsteam4) ++c4; break;
		}
	}
}

bool IsTeamSmallerThanTeam(int teama, int teamb, entity e, bool usescore)
{
	// equal
	if (teama == teamb)
	{
		return false;
	}
	// we assume that CheckAllowedTeams and GetTeamCounts have already been called
	float numplayersteama = -1, numplayersteamb = -1;
	float numbotsteama = 0, numbotsteamb = 0;
	float scoreteama = 0, scoreteamb = 0;

	switch (teama)
	{
		case 1: numplayersteama = c1; numbotsteama = numbotsteam1; scoreteama = team1_score; break;
		case 2: numplayersteama = c2; numbotsteama = numbotsteam2; scoreteama = team2_score; break;
		case 3: numplayersteama = c3; numbotsteama = numbotsteam3; scoreteama = team3_score; break;
		case 4: numplayersteama = c4; numbotsteama = numbotsteam4; scoreteama = team4_score; break;
	}
	switch (teamb)
	{
		case 1: numplayersteamb = c1; numbotsteamb = numbotsteam1; scoreteamb = team1_score; break;
		case 2: numplayersteamb = c2; numbotsteamb = numbotsteam2; scoreteamb = team2_score; break;
		case 3: numplayersteamb = c3; numbotsteamb = numbotsteam3; scoreteamb = team3_score; break;
		case 4: numplayersteamb = c4; numbotsteamb = numbotsteam4; scoreteamb = team4_score; break;
	}

	// invalid
	if (numplayersteama < 0 || numplayersteamb < 0)
		return false;

	if ((IS_REAL_CLIENT(e) && bots_would_leave))
	{
		numplayersteama -= numbotsteama;
		numplayersteamb -= numbotsteamb;
	}
	if (!usescore)
	{
		return numplayersteama < numplayersteamb;
	}
	if (numplayersteama < numplayersteamb)
	{
		return true;
	}
	if (numplayersteama > numplayersteamb)
	{
		return false;
	}
	return scoreteama < scoreteamb;	
}

bool IsTeamEqualToTeam(int teama, int teamb, entity e, bool usescore)
{
	// equal
	if (teama == teamb)
	{
		return true;
	}
	// we assume that CheckAllowedTeams and GetTeamCounts have already been called
	float numplayersteama = -1, numplayersteamb = -1;
	float numbotsteama = 0, numbotsteamb = 0;
	float scoreteama = 0, scoreteamb = 0;

	switch (teama)
	{
		case 1: numplayersteama = c1; numbotsteama = numbotsteam1; scoreteama = team1_score; break;
		case 2: numplayersteama = c2; numbotsteama = numbotsteam2; scoreteama = team2_score; break;
		case 3: numplayersteama = c3; numbotsteama = numbotsteam3; scoreteama = team3_score; break;
		case 4: numplayersteama = c4; numbotsteama = numbotsteam4; scoreteama = team4_score; break;
	}
	switch (teamb)
	{
		case 1: numplayersteamb = c1; numbotsteamb = numbotsteam1; scoreteamb = team1_score; break;
		case 2: numplayersteamb = c2; numbotsteamb = numbotsteam2; scoreteamb = team2_score; break;
		case 3: numplayersteamb = c3; numbotsteamb = numbotsteam3; scoreteamb = team3_score; break;
		case 4: numplayersteamb = c4; numbotsteamb = numbotsteam4; scoreteamb = team4_score; break;
	}

	// invalid
	if (numplayersteama < 0 || numplayersteamb < 0)
		return false;

	if ((IS_REAL_CLIENT(e) && bots_would_leave))
	{
		numplayersteama -= numbotsteama;
		numplayersteamb -= numbotsteamb;
	}
	if (!usescore)
	{
		return numplayersteama == numplayersteamb;
	}
	if (numplayersteama < numplayersteamb)
	{
		return false;
	}
	if (numplayersteama > numplayersteamb)
	{
		return false;
	}
	return scoreteama == scoreteamb;	
}

int FindBestTeams(entity player, bool usescore)
{
	if (MUTATOR_CALLHOOK(FindBestTeams, player) == true)
	{
		return M_ARGV(1, float);
	}
	int teambits = 0;
	int previousteam = 0;
	if (c1 >= 0)
	{
		teambits = BIT(0);
		previousteam = 1;
	}
	if (c2 >= 0)
	{
		if (previousteam == 0)
		{
			teambits = BIT(1);
			previousteam = 2;
		}
		else if (IsTeamSmallerThanTeam(2, previousteam, player, usescore))
		{
			teambits = BIT(1);
			previousteam = 2;
		}
		else if (IsTeamEqualToTeam(2, previousteam, player, usescore))
		{
			teambits |= BIT(1);
			previousteam = 2;
		}
	}
	if (c3 >= 0)
	{
		if (previousteam == 0)
		{
			teambits = BIT(2);
			previousteam = 3;
		}
		else if (IsTeamSmallerThanTeam(3, previousteam, player, usescore))
		{
			teambits = BIT(2);
			previousteam = 3;
		}
		else if (IsTeamEqualToTeam(3, previousteam, player, usescore))
		{
			teambits |= BIT(2);
			previousteam = 3;
		}
	}
	if (c4 >= 0)
	{
		if (previousteam == 0)
		{
			teambits = BIT(3);
		}
		else if (IsTeamSmallerThanTeam(4, previousteam, player, usescore))
		{
			teambits = BIT(3);
		}
		else if (IsTeamEqualToTeam(4, previousteam, player, usescore))
		{
			teambits |= BIT(3);
		}
	}
	return teambits;
}

// returns # of smallest team (1, 2, 3, 4)
// NOTE: Assumes CheckAllowedTeams has already been called!
float FindSmallestTeam(entity pl, float ignore_pl)
{
	// count how many players are in each team
	if (ignore_pl)
	{
		GetTeamCounts(pl);
	}
	else
	{
		GetTeamCounts(NULL);
	}
	int teambits = FindBestTeams(pl, true);
	if (teambits == 0)
	{
		error(sprintf("No teams available for %s\n", MapInfo_Type_ToString(MapInfo_CurrentGametype())));
	}
	RandomSelection_Init();
	if ((teambits & BIT(0)) != 0)
	{
		RandomSelection_AddFloat(1, 1, 1);
	}
	if ((teambits & BIT(1)) != 0)
	{
		RandomSelection_AddFloat(2, 1, 1);
	}
	if ((teambits & BIT(2)) != 0)
	{
		RandomSelection_AddFloat(3, 1, 1);
	}
	if ((teambits & BIT(3)) != 0)
	{
		RandomSelection_AddFloat(4, 1, 1);
	}
	return RandomSelection_chosen_float;
}

int JoinBestTeam(entity this, bool only_return_best, bool forcebestteam)
{
	// don't join a team if we're not playing a team game
	if (!teamplay)
	{
		return 0;
	}

	// find out what teams are available
	CheckAllowedTeams(this);

	float selectedteam;

	// if we don't care what team he ends up on, put him on whatever team he entered as.
	// if he's not on a valid team, then let other code put him on the smallest team
	if (!forcebestteam)
	{
		if(     c1 >= 0 && this.team == NUM_TEAM_1)
			selectedteam = this.team;
		else if(c2 >= 0 && this.team == NUM_TEAM_2)
			selectedteam = this.team;
		else if(c3 >= 0 && this.team == NUM_TEAM_3)
			selectedteam = this.team;
		else if(c4 >= 0 && this.team == NUM_TEAM_4)
			selectedteam = this.team;
		else
			selectedteam = -1;

		if (selectedteam > 0)
		{
			if (!only_return_best)
			{
				SetPlayerTeamSimple(this, selectedteam);

				// when JoinBestTeam is called by client.qc/ClientKill_Now_TeamChange the players team is -1 and thus skipped
				// when JoinBestTeam is called by client.qc/ClientConnect the player_id is 0 the log attempt is rejected
				LogTeamchange(this.playerid, this.team, 99);
			}
			return selectedteam;
		}
		// otherwise end up on the smallest team (handled below)
	}

	float bestteam = FindSmallestTeam(this, true);
	if (only_return_best || this.bot_forced_team)
	{
		return bestteam;
	}
	bestteam = Team_NumberToTeam(bestteam);
	if (bestteam == -1)
	{
		error("JoinBestTeam: invalid team\n");
	}
	int oldteam = Team_TeamToNumber(this.team);
	TeamchangeFrags(this);
	SetPlayerTeamSimple(this, bestteam);
	LogTeamchange(this.playerid, this.team, 2); // log auto join
	if (!IS_BOT_CLIENT(this))
	{
		AutoBalanceBots(oldteam, Team_TeamToNumber(bestteam));
	}
	if (!IS_DEAD(this) && (MUTATOR_CALLHOOK(Player_ChangeTeamKill, this) ==
		false))
	{
		Damage(this, this, this, 100000, DEATH_TEAMCHANGE.m_id, this.origin, '0 0 0');
	}
	return bestteam;
}

void SV_ChangeTeam(entity this, float _color)
{
	float sourcecolor, destinationcolor, sourceteam, destinationteam;

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

	sourcecolor = this.clientcolors & 0x0F;
	destinationcolor = _color & 0x0F;

	sourceteam = Team_TeamToNumber(sourcecolor + 1);
	destinationteam = Team_TeamToNumber(destinationcolor + 1);
	
	CheckAllowedTeams(this);

	if (destinationteam == 1 && c1 < 0) destinationteam = 4;
	if (destinationteam == 4 && c4 < 0) destinationteam = 3;
	if (destinationteam == 3 && c3 < 0) destinationteam = 2;
	if (destinationteam == 2 && c2 < 0) destinationteam = 1;

	// not changing teams
	if (sourcecolor == destinationcolor)
	{
		SetPlayerTeam(this, destinationteam, sourceteam, true);
		return;
	}

	if (autocvar_g_campaign || (autocvar_g_changeteam_banned && this.wasplayer))
	{
		Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_NOTALLOWED);
		return; // changing teams is not allowed
	}

	// autocvar_g_balance_teams_prevent_imbalance only makes sense if autocvar_g_balance_teams is on, as it makes the team selection dialog pointless
	if (autocvar_g_balance_teams && autocvar_g_balance_teams_prevent_imbalance)
	{
		GetTeamCounts(this);
		if ((BIT(destinationteam - 1) & FindBestTeams(this, false)) == 0)
		{
			Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_TEAMCHANGE_LARGERTEAM);
			return;
		}
	}
	if(IS_PLAYER(this) && sourceteam != destinationteam)
	{
		// reduce frags during a team change
		TeamchangeFrags(this);
	}
	SetPlayerTeam(this, destinationteam, sourceteam, !IS_CLIENT(this));
	AutoBalanceBots(sourceteam, destinationteam);
	if (!IS_PLAYER(this) || (sourceteam == destinationteam))
	{
		return;
	}
	// kill player when changing teams
	if (IS_DEAD(this) || (MUTATOR_CALLHOOK(Player_ChangeTeamKill, this) == true))
	{
		return;
	}
	Damage(this, this, this, 100000, DEATH_TEAMCHANGE.m_id, this.origin, '0 0 0');
}

void AutoBalanceBots(int sourceteam, int destinationteam)
{
	if ((sourceteam == -1) || (destinationteam == -1))
	{
		return;
	}
	if (!autocvar_g_balance_teams ||
		!autocvar_g_balance_teams_prevent_imbalance)
	{
		return;
	}
	int numplayerssourceteam = 0;
	int numplayersdestinationteam = 0;
	entity lowestbotdestinationteam = NULL;
	switch (sourceteam)
	{
		case 1:
		{
			numplayerssourceteam = c1;
			break;
		}
		case 2:
		{
			numplayerssourceteam = c2;
			break;
		}
		case 3:
		{
			numplayerssourceteam = c3;
			break;
		}
		case 4:
		{
			numplayerssourceteam = c4;
			break;
		}
	}
	switch (destinationteam)
	{
		case 1:
		{
			numplayersdestinationteam = c1;
			lowestbotdestinationteam = lowestbotteam1;
			break;
		}
		case 2:
		{
			numplayersdestinationteam = c2;
			lowestbotdestinationteam = lowestbotteam2;
			break;
		}
		case 3:
		{
			numplayersdestinationteam = c3;
			lowestbotdestinationteam = lowestbotteam3;
			break;
		}
		case 4:
		{
			numplayersdestinationteam = c4;
			lowestbotdestinationteam = lowestbotteam4;
			break;
		}
	}
	if ((numplayersdestinationteam <= numplayerssourceteam) ||
		(lowestbotdestinationteam == NULL))
	{
		return;
	}
	SetPlayerTeamSimple(lowestbotdestinationteam, Team_NumberToTeam(sourceteam));
	if (IS_DEAD(lowestbotdestinationteam) || (MUTATOR_CALLHOOK(
		Player_ChangeTeamKill, lowestbotdestinationteam) == true))
	{
		return;
	}
	Damage(lowestbotdestinationteam, lowestbotdestinationteam,
		lowestbotdestinationteam, 100000, DEATH_TEAMCHANGE.m_id,
		lowestbotdestinationteam.origin, '0 0 0');
}

void ShufflePlayerOutOfTeam (float source_team)
{
	float smallestteam, smallestteam_count, steam;
	float lowest_bot_score, lowest_player_score;
	entity lowest_bot, lowest_player, selected;

	smallestteam = 0;
	smallestteam_count = 999999999;

	if(c1 >= 0 && c1 < smallestteam_count)
	{
		smallestteam = 1;
		smallestteam_count = c1;
	}
	if(c2 >= 0 && c2 < smallestteam_count)
	{
		smallestteam = 2;
		smallestteam_count = c2;
	}
	if(c3 >= 0 && c3 < smallestteam_count)
	{
		smallestteam = 3;
		smallestteam_count = c3;
	}
	if(c4 >= 0 && c4 < smallestteam_count)
	{
		smallestteam = 4;
		smallestteam_count = c4;
	}

	if(!smallestteam)
	{
		bprint("warning: no smallest team\n");
		return;
	}

	if(source_team == 1)
		steam = NUM_TEAM_1;
	else if(source_team == 2)
		steam = NUM_TEAM_2;
	else if(source_team == 3)
		steam = NUM_TEAM_3;
	else // if(source_team == 4)
		steam = NUM_TEAM_4;

	lowest_bot = NULL;
	lowest_bot_score = 999999999;
	lowest_player = NULL;
	lowest_player_score = 999999999;

	// find the lowest-scoring player & bot of that team
	FOREACH_CLIENT(IS_PLAYER(it) && it.team == steam, LAMBDA(
		if(it.isbot)
		{
			if(it.totalfrags < lowest_bot_score)
			{
				lowest_bot = it;
				lowest_bot_score = it.totalfrags;
			}
		}
		else
		{
			if(it.totalfrags < lowest_player_score)
			{
				lowest_player = it;
				lowest_player_score = it.totalfrags;
			}
		}
	));

	// prefers to move a bot...
	if(lowest_bot != NULL)
		selected = lowest_bot;
	// but it will move a player if it has to
	else
		selected = lowest_player;
	// don't do anything if it couldn't find anyone
	if(!selected)
	{
		bprint("warning: couldn't find a player to move from team\n");
		return;
	}

	// smallest team gains a member
	if(smallestteam == 1)
	{
		c1 = c1 + 1;
	}
	else if(smallestteam == 2)
	{
		c2 = c2 + 1;
	}
	else if(smallestteam == 3)
	{
		c3 = c3 + 1;
	}
	else if(smallestteam == 4)
	{
		c4 = c4 + 1;
	}
	else
	{
		bprint("warning: destination team invalid\n");
		return;
	}
	// source team loses a member
	if(source_team == 1)
	{
		c1 = c1 + 1;
	}
	else if(source_team == 2)
	{
		c2 = c2 + 2;
	}
	else if(source_team == 3)
	{
		c3 = c3 + 3;
	}
	else if(source_team == 4)
	{
		c4 = c4 + 4;
	}
	else
	{
		bprint("warning: source team invalid\n");
		return;
	}

	// move the player to the new team
	TeamchangeFrags(selected);
	SetPlayerTeam(selected, smallestteam, source_team, false);

	if (IS_DEAD(selected) || MUTATOR_CALLHOOK(Player_ChangeTeamKill, selected) == true)
	{
		return;
	}
	Damage(selected, selected, selected, 100000, DEATH_AUTOTEAMCHANGE.m_id, selected.origin, '0 0 0');
	Send_Notification(NOTIF_ONE, selected, MSG_CENTER, CENTER_DEATH_SELF_AUTOTEAMCHANGE, selected.team);
}
