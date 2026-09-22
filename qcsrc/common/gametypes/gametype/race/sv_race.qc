#include "sv_race.qh"

#include "sv_util.qh"

#include <common/ent_cs.qh>
#include <common/mapobjects/triggers.qh>
#include <server/client.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/race.qh>
#include <server/world.qh>

#define autocvar_g_race_laps_limit cvar("g_race_laps_limit")
float autocvar_g_race_qualifying_timelimit;
float autocvar_g_race_qualifying_timelimit_override;
int autocvar_g_race_teams;

void race_ScoreRules()
{
	GameRules_score_enabled(false);
	GameRules_scoring(teamplay_bitmask, 0, 0,
	{
		if (teamplay_bitmask)
			field_team(ST_RACE_LAPS, "laps", SFL_SORT_PRIO_PRIMARY);
		else if (g_race_qualifying)
			field(SP_RACE_FASTEST, "fastest", SFL_SORT_PRIO_PRIMARY | SFL_LOWER_IS_BETTER | SFL_TIME);
		if (teamplay_bitmask || !g_race_qualifying)
		{
			field(SP_RACE_LAPS, "laps", SFL_SORT_PRIO_PRIMARY);
			field(SP_RACE_TIME, "time", SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER | SFL_TIME);
			field(SP_RACE_FASTEST, "fastest", SFL_LOWER_IS_BETTER | SFL_TIME);
		}
	});
}

void race_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":race:", mode, ":", (actor != NULL ? strcat(":", itos(actor.playerid)) : "")));
}

float WinningCondition_Race(float fraglimit)
{
	int n = 0;
	int c = 0;
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		++n;
		if (CS(it).race_completed)
			++c;
	});
	if (n && n == c)
		return WINNING_YES;
	float wc = WinningCondition_Scores(fraglimit, 0);

	// ALWAYS initiate overtime, unless EVERYONE has finished the race!
	if (wc == WINNING_YES || wc == WINNING_STARTSUDDENDEATHOVERTIME)
		// do NOT support equality when the laps are all raced!
		return WINNING_STARTSUDDENDEATHOVERTIME;
	return WINNING_NEVER;
}

float WinningCondition_QualifyingThenRace(float limit)
{
	float wc = WinningCondition_Scores(limit, 0);

	// NEVER initiate overtime
	if (wc == WINNING_YES || wc == WINNING_STARTSUDDENDEATHOVERTIME)
		return WINNING_YES;
	return wc;
}

MUTATOR_HOOKFUNCTION(rc, ClientKill)
{
	if (g_race_qualifying)
		M_ARGV(1, float) = 0; // killtime
}

MUTATOR_HOOKFUNCTION(rc, AbortSpeedrun)
{
	race_util_AbortSpeedrun();
}

MUTATOR_HOOKFUNCTION(rc, PlayerPhysics)
{
	race_util_PlayerPhysics();
}

MUTATOR_HOOKFUNCTION(rc, reset_map_global)
{
	race_util_reset_map_global(race_EventLog);
}

MUTATOR_HOOKFUNCTION(rc, ClientConnect)
{
	race_util_ClientConnect();
}

MUTATOR_HOOKFUNCTION(rc, MakePlayerObserver)
{
	race_util_MakePlayerObserver();
}

MUTATOR_HOOKFUNCTION(rc, PlayerSpawn)
{
	race_util_PlayerSpawn();
}

MUTATOR_HOOKFUNCTION(rc, PutClientInServer)
{
	race_util_PutClientInServer();
}

MUTATOR_HOOKFUNCTION(rc, PlayerDamaged)
{
	int frag_deathtype = M_ARGV(5, int);
	if (frag_deathtype == DEATH_KILL.m_id)
		return true; // forbid logging damage
}

MUTATOR_HOOKFUNCTION(rc, PlayerDies)
{
	race_util_PlayerDies();
}

MUTATOR_HOOKFUNCTION(rc, HavocBot_ChooseRole)
{
	return race_util_HavocBot_ChooseRole();
}

MUTATOR_HOOKFUNCTION(rc, GetPressedKeys)
{
	race_util_GetPressedKeys();
}

MUTATOR_HOOKFUNCTION(rc, PreferPlayerScore_Clear)
{
	if (!g_race_qualifying)
		return true; // in qualifying, you don't lose score by observing
}

MUTATOR_HOOKFUNCTION(rc, Scores_CountFragsRemaining)
{
	// announce remaining frags if not in qualifying mode
	if (!g_race_qualifying)
		return true;
}

MUTATOR_HOOKFUNCTION(rc, GetRecords)
{
	race_util_GetRecords();
}

MUTATOR_HOOKFUNCTION(rc, FixClientCvars)
{
	race_util_FixClientCvars();
}

MUTATOR_HOOKFUNCTION(rc, CheckRules_World)
{
	float checkrules_timelimit = M_ARGV(1, float);
	float checkrules_fraglimit = M_ARGV(2, float);

	if (checkrules_timelimit < 0)
		return;

	if (!g_race_qualifying)
	{
		M_ARGV(0, float) = WinningCondition_Race(checkrules_fraglimit);
		return true;
	}
	else if (g_race_qualifying == 2)
	{
		M_ARGV(0, float) = WinningCondition_QualifyingThenRace(checkrules_fraglimit);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(rc, ReadLevelCvars)
{
	if (g_race_qualifying == 2)
		warmup_stage = 0;
}

void race_Initialize()
{
	race_ScoreRules();
	if (g_race_qualifying == 2)
		warmup_stage = 0;
	radar_showenemies = true;
}

void rc_SetLimits()
{
	if (autocvar_g_race_teams)
	{
		GameRules_teams(true);
		teamplay_bitmask = BITS(bound(2, autocvar_g_race_teams, 4));
	}
	else
		teamplay_bitmask = 0;

	float qualifying_override = autocvar_g_race_qualifying_timelimit_override;
	int fraglimit_override = autocvar_g_race_laps_limit;
	int leadlimit_override = 0; // currently not supported by race
	float timelimit_override = autocvar_timelimit_override;

	bool want_qualifying = ((qualifying_override >= 0) ? qualifying_override : autocvar_g_race_qualifying_timelimit) > 0;

	record_type = RACE_RECORD;

	if (autocvar_g_campaign)
	{
		g_race_qualifying = 1;
		independent_players = 1;
	}
	else if (want_qualifying)
	{
		g_race_qualifying = 2;
		independent_players = 1;
		race_fraglimit = (fraglimit_override >= 0) ? fraglimit_override : autocvar_fraglimit;
		race_leadlimit = (leadlimit_override >= 0) ? leadlimit_override : autocvar_leadlimit;
		race_timelimit = (timelimit_override >= 0) ? timelimit_override : autocvar_timelimit;
		qualifying_override = (qualifying_override >= 0) ? qualifying_override : autocvar_g_race_qualifying_timelimit;
		fraglimit_override = 0;
		leadlimit_override = 0;
		timelimit_override = qualifying_override;
	}
	else
		g_race_qualifying = 0;

	GameRules_limit_score(fraglimit_override);
	GameRules_limit_lead(leadlimit_override);
	GameRules_limit_time(timelimit_override);
	GameRules_limit_time_qualifying(qualifying_override);
}
