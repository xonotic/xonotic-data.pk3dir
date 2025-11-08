#include "scores.qh"

#include <common/mapinfo.qh>
#include <common/mutators/base.qh>
#include <common/net_linked.qh>
#include <common/playerstats.qh>
#include <common/scores.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/teams.qh>
#include <common/weapons/_all.qh>
#include <server/client.qh>
#include <server/command/common.qh>
#include <server/intermission.qh>
#include <server/mutators/_mod.qh>
#include <server/round_handler.qh>
#include <server/world.qh>

.entity scorekeeper;
entity teamscorekeepers[16];
float teamscores_entities_count;
var .float scores_primary;
var .float teamscores_primary;
float scores_flags_primary;
float teamscores_flags_primary;
var .float scores_secondary;
float scores_flags_secondary;

// returns cmp value
int ScoreField_Compare(entity t1, entity t2, .float field, float fieldflags, int previous)
{
	if(fieldflags & SFL_NOT_SORTABLE) // column does not sort
		return previous;
	if (t1.(field) == t2.(field))
		return previous;

	if(fieldflags & SFL_ZERO_IS_WORST)
	{
		if (t1.(field) == 0)
		{
			previous = -1;
			return previous;
		}
		else if (t2.(field) == 0)
		{
			previous = +1;
			return previous;
		}
	}

	if (fieldflags & SFL_LOWER_IS_BETTER)
		previous = (t2.(field) - t1.(field));
	else
		previous = (t1.(field) - t2.(field));

	return previous;
}

/*
 * teamscore entities
 */

bool TeamScore_SendEntity(entity this, entity to, float sendflags)
{
	float i, longflags;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_TEAMSCORES);
	int t = this.team - 1;
	assert(t, eprint(this));
	WriteByte(MSG_ENTITY, t);

	longflags = 0;
	for(i = 0; i < MAX_TEAMSCORE; ++i)
		if(this.(teamscores(i)) > 127 || this.(teamscores(i)) <= -128)
			longflags |= BIT(i);

#if MAX_TEAMSCORE <= 8
	WriteByte(MSG_ENTITY, sendflags);
	WriteByte(MSG_ENTITY, longflags);
#else
	WriteShort(MSG_ENTITY, sendflags);
	WriteShort(MSG_ENTITY, longflags);
#endif
	for(i = 0; i < MAX_TEAMSCORE; ++i)
		if(sendflags & BIT(i))
		{
			if(longflags & BIT(i))
				WriteInt24_t(MSG_ENTITY, this.(teamscores(i)));
			else
				WriteChar(MSG_ENTITY, this.(teamscores(i)));
		}

	return true;
}

void TeamScore_Spawn(float t, string name)
{
	entity ts = new_pure(csqc_score_team);
	ts.netname = name; // not used yet, FIXME
	ts.team = t;
	Net_LinkEntity(ts, false, 0, TeamScore_SendEntity);
	teamscorekeepers[t - 1] = ts;
	++teamscores_entities_count;
	PlayerStats_GameReport_AddTeam(t);
}

float TeamScore_AddToTeam(int t, float scorefield, float score)
{
	entity s;

	if(game_stopped)
	{
		score = 0;
	}

	if(!scores_initialized) return 0; // FIXME remove this when everything uses this system
	if(t <= 0 || t >= 16)
	{
		if(game_stopped)
			return 0;
		error("Adding score to invalid team!");
	}
	s = teamscorekeepers[t - 1];
	if(!s)
	{
		if(game_stopped)
			return 0;
		error("Adding score to unknown team!");
	}
	if(score)
		if(teamscores_label(scorefield) != "")
			s.SendFlags |= BIT(scorefield);
	return (s.(teamscores(scorefield)) += score);
}

float TeamScore_Add(entity player, float scorefield, float score)
{
	return TeamScore_AddToTeam(player.team, scorefield, score);
}

// strict: compare others fields too besides primary and secondary
int TeamScore_Compare(entity t1, entity t2, bool strict)
{
	if(!t1 || !t2) return (!t2) - !t1;

	// supporting MAX_TEAMSCORE > 2 requires keeping track of primary and secondary teamscore
	if (MAX_TEAMSCORE > 2)
		error("MAX_TEAMSCORE > 2 not supported");

	// first compare primary, then others (don't check secondary flag since there are only 2 teamscores)
	int result = 0;
	int i = boolean(teamscores_primary && teamscores_primary == teamscores(1));
	result = ScoreField_Compare(t1, t2, teamscores(i), teamscores_flags(i), result);
	if (result == 0 && strict)
	{
		i = (i + 1) % MAX_TEAMSCORE;
		result = ScoreField_Compare(t1, t2, teamscores(i), teamscores_flags(i), result);
		if (result == 0)
			result = t1.team - t2.team;
	}

	return result;
}

/*
 * the scoreinfo entity
 */

void ScoreInfo_SetLabel_PlayerScore(PlayerScoreField i, string label, float scoreflags)
{
	scores_label(i) = label;
	scores_flags(i) = scoreflags;
	if((scoreflags & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_PRIMARY)
	{
		scores_primary = scores(i);
		scores_flags_primary = scoreflags;
	}
	else if((scoreflags & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_SECONDARY)
	{
		scores_secondary = scores(i);
		scores_flags_secondary = scoreflags;
	}
	if(label != "")
	{
		PlayerStats_GameReport_AddEvent(strcat(PLAYERSTATS_TOTAL, label));
		PlayerStats_GameReport_AddEvent(strcat(PLAYERSTATS_SCOREBOARD, label));
	}
}

void ScoreInfo_SetLabel_TeamScore(float i, string label, float scoreflags)
{
	teamscores_label(i) = label;
	teamscores_flags(i) = scoreflags;
	if((scoreflags & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_PRIMARY)
	{
		teamscores_primary = teamscores(i);
		teamscores_flags_primary = scoreflags;
	}
	if(label != "")
	{
		PlayerStats_GameReport_AddEvent(strcat(PLAYERSTATS_TOTAL, label));
		PlayerStats_GameReport_AddEvent(strcat(PLAYERSTATS_SCOREBOARD, label));
	}
}

bool ScoreInfo_SendEntity(entity this, entity to, int sf)
{
	float i;
	WriteHeader(MSG_ENTITY, ENT_CLIENT_SCORES_INFO);
	WriteRegistered(Gametypes, MSG_ENTITY, MapInfo_LoadedGametype);
	string gt_name = "";
	if (loaded_gametype_custom_string != "")
		gt_name = cvar_string(strcat("sv_vote_gametype_", loaded_gametype_custom_string, "_name"));
	WriteString(MSG_ENTITY, gt_name);
	FOREACH(Scores, true, {
		WriteString(MSG_ENTITY, scores_label(it));
		WriteByte(MSG_ENTITY, scores_flags(it));
	});
	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		WriteString(MSG_ENTITY, teamscores_label(i));
		WriteByte(MSG_ENTITY, teamscores_flags(i));
	}
	// prevent sending the welcome message again when score types are sent again because the scoring system has changed
	// it can happen in some gametypes like Race when the qualyfing session ends and the race starts
	bool welcome_msg_too = (!CS(to) || time < CS(to).jointime + 5);
	WriteByte(MSG_ENTITY, welcome_msg_too);
	// welcome message is sent here because it needs to know the gametype
	if (welcome_msg_too)
		SendWelcomeMessage(to, MSG_ENTITY);
	return true;
}

void ScoreInfo_Init(int teams)
{
	if(scores_initialized)
	{
		scores_initialized.SendFlags |= 1; // force a resend
	}
	else
	{
		scores_initialized = new_pure(ent_client_scoreinfo);
		Net_LinkEntity(scores_initialized, false, 0, ScoreInfo_SendEntity);
	}
	if(teams & BIT(0))
		TeamScore_Spawn(NUM_TEAM_1, "Red");
	if(teams & BIT(1))
		TeamScore_Spawn(NUM_TEAM_2, "Blue");
	if(teams & BIT(2))
		TeamScore_Spawn(NUM_TEAM_3, "Yellow");
	if(teams & BIT(3))
		TeamScore_Spawn(NUM_TEAM_4, "Pink");
}

/*
 * per-player score entities
 */

bool PlayerScore_SendEntity(entity this, entity to, float sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_SCORES);
	WriteByte(MSG_ENTITY, etof(this.owner));

	int longflags = 0;
	FOREACH(Scores, true, {
		int p = BIT(i % 16);
		if (this.(scores(it)) > 127 || this.(scores(it)) <= -128)
			longflags |= p;
	});

	WriteShort(MSG_ENTITY, sendflags);
	WriteShort(MSG_ENTITY, longflags);
	FOREACH(Scores, true, {
		int p = BIT(i % 16);
		if (sendflags & p)
		{
			if(longflags & p)
				WriteInt24_t(MSG_ENTITY, this.(scores(it)));
			else
				WriteChar(MSG_ENTITY, this.(scores(it)));
		}
	});

	return true;
}

float PlayerScore_Clear(entity player)
{
	entity sk;

	if(teamscores_entities_count)
		return 0;

	if(MUTATOR_CALLHOOK(ForbidPlayerScore_Clear)) return 0;

	sk = CS(player).scorekeeper;
	FOREACH(Scores, true, {
		if(sk.(scores(it)) != 0)
			if(scores_label(it) != "")
				sk.SendFlags |= BIT(i % 16);
		if(i != SP_SKILL.m_id)
			sk.(scores(it)) = 0;
	});

	return 1;
}

void Score_ClearAll()
{
	entity sk;
	float t;
	FOREACH_CLIENTSLOT(true, {
		sk = CS(it).scorekeeper;
		if (!sk) continue;
		FOREACH(Scores, true, {
			if(sk.(scores(it)) != 0)
				if(scores_label(it) != "")
					sk.SendFlags |= BIT(i % 16);
			if(i != SP_SKILL.m_id)
				sk.(scores(it)) = 0;
		});
	});
	for(t = 0; t < 16; ++t)
	{
		sk = teamscorekeepers[t];
		if(!sk)
			continue;
		for(int j = 0; j < MAX_TEAMSCORE; ++j)
		{
			if(sk.(teamscores(j)) != 0)
				if(teamscores_label(j) != "")
					sk.SendFlags |= BIT(j);
			sk.(teamscores(j)) = 0;
		}
	}
}

void PlayerScore_Attach(entity player)
{
	if(CS(player).scorekeeper)
		error("player already has a scorekeeper");
	entity sk = new_pure(scorekeeper);
	sk.owner = player;
	Net_LinkEntity(sk, false, 0, PlayerScore_SendEntity);
	CS(player).scorekeeper = sk;
}

void PlayerScore_Detach(entity player)
{
	if(!CS(player).scorekeeper)
		error("player has no scorekeeper");
	delete(CS(player).scorekeeper);
	CS(player).scorekeeper = NULL;
}

float PlayerScore_Add(entity player, PlayerScoreField scorefield, float score)
{
	bool mutator_returnvalue = MUTATOR_CALLHOOK(AddPlayerScore, scorefield, score, player);
	score = M_ARGV(1, float);

	if(!mutator_returnvalue && game_stopped)
	{
		score = 0;
	}

	if(!scores_initialized) return 0; // FIXME remove this when everything uses this system
	entity s = CS(player).scorekeeper;
	if(!s)
	{
		if(game_stopped)
			return 0;
		LOG_WARN("Adding score to unknown player!");
		return 0;
	}
	if(!score)
	{
		return s.(scores(scorefield));
	}
	if(scores_label(scorefield) != "")
		s.SendFlags |= BIT(scorefield.m_id % 16);
	if(!warmup_stage)
		PlayerStats_GameReport_Event_Player(s.owner, strcat(PLAYERSTATS_TOTAL, scores_label(scorefield)), score);
	s.(scores(scorefield)) += score;
	MUTATOR_CALLHOOK(AddedPlayerScore, scorefield, score, player);
	return s.(scores(scorefield));
}

float PlayerScore_Set(entity player, PlayerScoreField scorefield, float score)
{
	if(!scores_initialized) return 0; // FIXME remove this when everything uses this system
	entity s = CS(player).scorekeeper;
	if(!s)
	{
		if(game_stopped)
			return 0;
		LOG_WARN("Setting score of unknown player!");
		return 0;
	}

	float oldscore = s.(scores(scorefield));
	if(oldscore == score)
		return oldscore;

	if(scores_label(scorefield) != "")
		s.SendFlags |= BIT(scorefield.m_id % 16);
	s.(scores(scorefield)) = score;
	return s.(scores(scorefield));
}

float PlayerTeamScore_Add(entity player, PlayerScoreField pscorefield, float tscorefield, float score)
{
	float r;
	r = PlayerScore_Add(player, pscorefield, score);
	if(teamscores_entities_count) // only for teamplay
		r = TeamScore_Add(player, tscorefield, score);
	return r;
}

// strict: compare others fields too besides primary and secondary
float PlayerScore_Compare(entity t1, entity t2, bool strict)
{
	if(!t1 || !t2) return (!t2) - !t1;

	int result = 0;
	result = ScoreField_Compare(t1, t2, scores_primary, scores_flags_primary, result);
	// NOTE: if (scores_secondary) doesn't work because it's a field pointer
	if (result == 0 && scores_flags_secondary)
		result = ScoreField_Compare(t1, t2, scores_secondary, scores_flags_secondary, result);

	if (result == 0 && strict)
	{
		FOREACH(Scores, true, {
			if (scores_flags(it) & SFL_SORT_PRIO_MASK)
				continue;
			if (scores_label(it) == "")
				continue;
			var .float f = scores(it);
			result = ScoreField_Compare(t1, t2, f, scores_flags(it), result);
			if (result) break;
		});
		if (result == 0)
			result = t1.owner.playerid - t2.owner.playerid;
	}

	return result;
}

void WinningConditionHelper(entity this)
{
	float c;
	string s;
	entity winnerscorekeeper;
	entity secondscorekeeper;
	entity sk;

	// format:
	// gametype:P<pure>:S<slots>::plabel,plabel:tlabel,tlabel:teamid:tscore,tscore:teamid:tscore,tscore
	// score labels always start with a symbol or with lower case
	// so to match pure, match for :P0:
	// to match full, match for :S0:

	// NOTE can't use a single strcat because strcat concatenates max 8 strings
	s = strcat(GetGametype(),
		":", autocvar_g_xonoticversion,
		":P", ftos(cvar_purechanges_count),
		":S", ftos(nJoinAllowed(NULL)));
	s = strcat(s,
		":F", ftos(serverflags),
		":T", sv_termsofservice_url_escaped,
		":M", modname);
	s = strcat(s,
		"::", GetPlayerScoreString(NULL, (autocvar_g_full_getstatus_responses ? 1 : 2)));

	if(teamscores_entities_count)
	{
		float t;

		s = strcat(s, ":", GetTeamScoreString(0, 1));
		for(t = 0; t < 16; ++t)
			if(teamscorekeepers[t])
				s = strcat(s, ":", ftos(t+1), ":", GetTeamScoreString(t+1, 1));

		WinningConditionHelper_winnerteam = -1;
		WinningConditionHelper_secondteam = -1;
		winnerscorekeeper = NULL;
		secondscorekeeper = NULL;
		for(t = 0; t < 16; ++t)
		{
			sk = teamscorekeepers[t];
			c = TeamScore_Compare(winnerscorekeeper, sk, true);
			if(c < 0)
			{
				WinningConditionHelper_secondteam = WinningConditionHelper_winnerteam;
				WinningConditionHelper_winnerteam = t + 1;
				secondscorekeeper = winnerscorekeeper;
				winnerscorekeeper = sk;
			}
			else
			{
				c = TeamScore_Compare(secondscorekeeper, sk, true);
				if(c < 0)
				{
					WinningConditionHelper_secondteam = t + 1;
					secondscorekeeper = sk;
				}
			}
		}

		WinningConditionHelper_equality = (TeamScore_Compare(winnerscorekeeper, secondscorekeeper, false) == 0);
		if(WinningConditionHelper_equality)
			WinningConditionHelper_winnerteam = WinningConditionHelper_secondteam = -1;

		WinningConditionHelper_topscore = winnerscorekeeper.teamscores_primary;
		WinningConditionHelper_secondscore = secondscorekeeper.teamscores_primary;
		WinningConditionHelper_lowerisbetter = (teamscores_flags_primary & SFL_LOWER_IS_BETTER);
		WinningConditionHelper_zeroisworst = (teamscores_flags_primary & SFL_ZERO_IS_WORST);

		WinningConditionHelper_winner = NULL; // not supported in teamplay
		WinningConditionHelper_second = NULL; // not supported in teamplay
	}
	else
	{
		WinningConditionHelper_winner = NULL;
		WinningConditionHelper_second = NULL;
		winnerscorekeeper = NULL;
		secondscorekeeper = NULL;
		FOREACH_CLIENT(IS_PLAYER(it), {
			sk = CS(it).scorekeeper;
			c = PlayerScore_Compare(winnerscorekeeper, sk, true);
			if(c < 0)
			{
				WinningConditionHelper_second = WinningConditionHelper_winner;
				WinningConditionHelper_winner = it;
				secondscorekeeper = winnerscorekeeper;
				winnerscorekeeper = sk;
			}
			else
			{
				c = PlayerScore_Compare(secondscorekeeper, sk, true);
				if(c < 0)
				{
					WinningConditionHelper_second = it;
					secondscorekeeper = sk;
				}
			}
		});

		WinningConditionHelper_equality = (PlayerScore_Compare(winnerscorekeeper, secondscorekeeper, false) == 0);
		if(WinningConditionHelper_equality)
			WinningConditionHelper_winner = WinningConditionHelper_second = NULL;

		WinningConditionHelper_topscore = winnerscorekeeper.scores_primary;
		WinningConditionHelper_secondscore = secondscorekeeper.scores_primary;
		WinningConditionHelper_lowerisbetter = (scores_flags_primary & SFL_LOWER_IS_BETTER);
		WinningConditionHelper_zeroisworst = (scores_flags_primary & SFL_ZERO_IS_WORST);

		WinningConditionHelper_winnerteam = -1; // no teamplay
		WinningConditionHelper_secondteam = -1; // no teamplay
	}

	if(WinningConditionHelper_topscore == 0)
	{
		if(scores_flags_primary & SFL_ZERO_IS_WORST)
		{
			if(WinningConditionHelper_lowerisbetter)
				WinningConditionHelper_topscore = 999999999;
			else
				WinningConditionHelper_topscore = -999999999;
		}
		if(player_count == 0) // special case: empty servers DO end the match at a 0:0 tie
			WinningConditionHelper_equality = 0;
	}

	if(WinningConditionHelper_secondscore == 0)
	{
		if(scores_flags_primary & SFL_ZERO_IS_WORST)
		{
			if(WinningConditionHelper_lowerisbetter)
				WinningConditionHelper_secondscore = 999999999;
			else
				WinningConditionHelper_secondscore = -999999999;
		}
	}

	if (s != worldstatus)
		strcpy(worldstatus, s);

	FOREACH_CLIENT(true, {
		string s = "";
		if(autocvar_g_full_getstatus_responses)
		{
			s = GetPlayerScoreString(it, 1);
			s = strcat(s, IS_REAL_CLIENT(it) ? ":human" : ":bot");
			if(!(IS_PLAYER(it) || INGAME_JOINED(it)))
				s = strcat(s, ":spectator");
		}
		else
		{
			if (IS_PLAYER(it) || INGAME_JOINED(it))
				s = GetPlayerScoreString(it, 2);
			else
				s = "-666";
		}

		if (s != it.clientstatus)
			strcpy(it.clientstatus, s);
	});
}

string GetScoreLogLabel(string label, float fl)
{
	if(fl & SFL_LOWER_IS_BETTER)
		label = strcat(label, "<");
	if((fl & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_PRIMARY)
		label = strcat(label, "!!");
	else if((fl & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_SECONDARY)
		label = strcat(label, "!");
	return label;
}

string GetPlayerScoreString(entity pl, float shortString)
{
	string out;
	entity sk;
	float f;
	string l;

	out = "";
	if(!pl)
	{
		// label
		FOREACH(Scores, true, {
			if ((scores_flags(it) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_PRIMARY)
			{
				f = scores_flags(it);
				l = scores_label(it);
				out = strcat(out, GetScoreLogLabel(l, f), ",");
			}
		});
		if(shortString < 2)
		FOREACH(Scores, true, {
			if((scores_flags(it) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_SECONDARY)
			{
				f = scores_flags(it);
				l = scores_label(it);
				out = strcat(out, GetScoreLogLabel(l, f), ",");
			}
		});
		if(shortString < 1)
		FOREACH(Scores, true, {
			if((scores_flags(it) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_PRIMARY)
			if((scores_flags(it) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_SECONDARY)
			{
				f = scores_flags(it);
				l = scores_label(it);
				out = strcat(out, GetScoreLogLabel(l, f), ",");
			}
		});
		out = substring(out, 0, strlen(out) - 1);
	}
	else if((sk = CS(pl).scorekeeper))
	{
		FOREACH(Scores, true, {
			if ((scores_flags(it) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_PRIMARY)
				out = strcat(out, ftos(sk.(scores(it))), ",");
		});
		if(shortString < 2)
		FOREACH(Scores, true, {
			if ((scores_flags(it) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(scores(it))), ",");
		});
		if(shortString < 1)
		FOREACH(Scores, true, {
			if((scores_flags(it) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_PRIMARY)
			if((scores_flags(it) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(scores(it))), ",");
		});
		out = substring(out, 0, strlen(out) - 1);
	}
	return out;
}

string GetTeamScoreString(float tm, float shortString)
{
	string out;
	entity sk;
	float i, f;
	string l;

	out = "";
	if(tm == 0)
	{
		// label
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_PRIMARY)
			{
				f = teamscores_flags(i);
				l = teamscores_label(i);
				out = strcat(out, GetScoreLogLabel(l, f), ",");
			}
		if(shortString < 2)
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_SECONDARY)
			{
				f = teamscores_flags(i);
				l = teamscores_label(i);
				out = strcat(out, GetScoreLogLabel(l, f), ",");
			}
		if(shortString < 1)
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_PRIMARY)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_SECONDARY)
			{
				f = teamscores_flags(i);
				l = teamscores_label(i);
				out = strcat(out, GetScoreLogLabel(l, f), ",");
			}
		out = substring(out, 0, strlen(out) - 1);
	}
	else if((sk = teamscorekeepers[tm - 1]))
	{
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_PRIMARY)
				out = strcat(out, ftos(sk.(teamscores(i))), ",");
		if(shortString < 2)
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) == SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(teamscores(i))), ",");
		if(shortString < 1)
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_PRIMARY)
			if((teamscores_flags(i) & SFL_SORT_PRIO_MASK) != SFL_SORT_PRIO_SECONDARY)
				out = strcat(out, ftos(sk.(teamscores(i))), ",");
		out = substring(out, 0, strlen(out) - 1);
	}
	return out;
}

// strict: compare others fields too besides primary and secondary
int PlayerTeamScore_Compare(entity p1, entity p2, float teams, bool strict)
{
	if(teams && teamscores_entities_count)
	{
		if(p1.team != p2.team)
		{
			entity t1, t2;
			float r;
			t1 = teamscorekeepers[p1.team - 1];
			t2 = teamscorekeepers[p2.team - 1];
			r = TeamScore_Compare(t1, t2, ((teams >= 0) ? 1 : strict));
			return r;
		}
		if(teams < 0)
			return 0;
	}

	return PlayerScore_Compare(CS(p1).scorekeeper, CS(p2).scorekeeper, strict);
}

entity PlayerScore_Sort(.float field, int teams, bool strict, bool nospectators)
{
	entity p, plist, pprev, pbest, pbestprev, pfirst, plast;
	float i, j;

	plist = NULL;

	FOREACH_CLIENT(true, { it.(field) = 0; });

	FOREACH_CLIENT(CS(it).scorekeeper,
	{
		if(nospectators)
			if(it.frags == FRAGS_SPECTATOR)
				continue;

		it.chain = plist;
		plist = it;
	});
	// Now plist points to the whole list.

	pfirst = plast = NULL;

	i = j = 0;
	while(plist)
	{
		pprev = pbestprev = NULL;
		pbest = plist;
		for(p = plist; (pprev = p), (p = p.chain); )
		{
			if(PlayerTeamScore_Compare(p, pbest, teams, strict) > 0)
			{
				pbest = p;
				pbestprev = pprev;
			}
		}

		// remove pbest out of the chain
		if(pbestprev == NULL)
			plist = pbest.chain;
		else
			pbestprev.chain = pbest.chain;
		pbest.chain = NULL;

		++i;
		if(!plast || PlayerTeamScore_Compare(plast, pbest, teams, strict))
			j = i;

		pbest.(field) = j;

		if (!pfirst)
			pfirst = pbest;
		if(plast)
			plast.chain = pbest;
		plast = pbest;
	}

	return pfirst;
}

float TeamScore_GetCompareValue(float t)
{
	float s;
	entity sk;

	if(t <= 0 || t >= 16)
	{
		if(game_stopped)
			return 0;
		error("Reading score of invalid team!");
	}

	sk = teamscorekeepers[t - 1];
	if (!sk)
		return -999999999;
	s = sk.teamscores_primary;
	if(teamscores_flags_primary & SFL_ZERO_IS_WORST)
		if(!s)
			return -999999999;
	if(teamscores_flags_primary & SFL_LOWER_IS_BETTER)
		s = -s;
	return s;
}

const float NAMEWIDTH = 22;
const float SCORESWIDTH = 58;
// TODO put this somewhere in common?
string Score_NicePrint_ItemColor(float vflags)
{
	if(vflags & SFL_SORT_PRIO_PRIMARY)
		return "^3";
	else if(vflags & SFL_SORT_PRIO_SECONDARY)
		return "^5";
	else
		return "^7";
}

void Score_NicePrint_Team(entity to, float t, float w)
{
	string s, s2;
	float i;
	entity sk;
	float fl, sc;
	s = "";

	sk = teamscorekeepers[t - 1];
	if(sk)
	{
		s = strcat(s, Team_ColoredFullName(t));
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if(teamscores_label(i) != "")
			{
				fl = teamscores_flags(i);
				sc = sk.(teamscores(i));
				s = strcat(s, " ", Score_NicePrint_ItemColor(fl), ScoreString(fl, sc, 0));
			}
	}
	else
		s = "Scores:";

	s = strcat(s, strpad(max(0, NAMEWIDTH - strlennocol(s)), ""));

	FOREACH(Scores, true, {
		if(scores_label(it) != "")
		{
			fl = scores_flags(it);
			s2 = scores_label(it);
			s = strcat(s, " ", Score_NicePrint_ItemColor(fl), strpad(-w, substring(s2, 0, w)));
		}
    });

	print_to(to, s);
}

void Score_NicePrint_Player(entity to, entity p, float w)
{
	string s;
	float i;
	entity sk;
	float fl, sc;
	s = "  ";

	sk = CS(p).scorekeeper;

	s = strcat(s, playername(p.netname, p.team, false));
	for (;;)
	{
		i = strlennocol(s) - NAMEWIDTH;
		if(i > 0)
			s = substring(s, 0, strlen(s) - i);
		else
		{
			s = strcat(s, strpad(i, ""));
			break;
		}
	}

	FOREACH(Scores, true, {
		if(scores_label(it) != "")
		{
			fl = scores_flags(it);
			sc = sk.(scores(it));
			s = strcat(s, " ", Score_NicePrint_ItemColor(fl), strpad(-w, ScoreString(fl, sc, 0)));
		}
    });

	print_to(to, s);
}

void Score_NicePrint_Spectators(entity to)
{
	print_to(to, "Spectators:");
}

void Score_NicePrint_Spectator(entity to, entity p)
{
	print_to(to, strcat("  ", playername(p.netname, p.team, false)));
}

.float score_dummyfield;
void Score_NicePrint(entity to)
{
	entity p;
	float w;

	int t = 0;
	FOREACH(Scores, true, {
		if(scores_label(it) != "")
			++t;
    });
	w = bound(6, floor(SCORESWIDTH / t - 1), 9);

	p = PlayerScore_Sort(score_dummyfield, 1, true, false);
	t = -1;

	if(!teamscores_entities_count)
		Score_NicePrint_Team(to, t, w);
	while(p)
	{
		if(teamscores_entities_count)
			if(t != p.team)
				Score_NicePrint_Team(to, p.team, w);
		Score_NicePrint_Player(to, p, w);
		t = p.team;
		p = p.chain;
	}

	t = 0;
	FOREACH_CLIENT(!IS_PLAYER(it), {
		if (!t)
			Score_NicePrint_Spectators(to);
		Score_NicePrint_Spectator(to, it);
		t = 1;
	});
}

void PlayerScore_PlayerStats(entity p)
{
	entity s = CS(p).scorekeeper;
	FOREACH(Scores, true, {
		if(s.(scores(it)) != 0 && scores_label(it) != "")
			PlayerStats_GameReport_Event_Player(s.owner,
				strcat(PLAYERSTATS_SCOREBOARD, scores_label(it)), s.(scores(it)));
	});
}

void PlayerScore_TeamStats()
{
	entity sk;
	float t, i;
	for(t = 0; t < 16; ++t)
	{
		sk = teamscorekeepers[t];
		if(!sk)
			continue;
		for(i = 0; i < MAX_TEAMSCORE; ++i)
			if(sk.(teamscores(i)) != 0 && teamscores_label(i) != "")
				// the +1 is important here!
				PlayerStats_GameReport_Event_Team(t+1,
					strcat(PLAYERSTATS_SCOREBOARD, teamscores_label(i)), sk.(teamscores(i)));
	}
}
