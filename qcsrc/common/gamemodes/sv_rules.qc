#include "sv_rules.qh"

void GameRules_teams(bool value)
{
	if (value)
	{
		serverflags |= SERVERFLAG_TEAMPLAY;
		teamplay = 1;  // aka AVAILABLE_TEAMS, updated by ScoreRules_basics() after team ents spawn
		cvar_set("teamplay", "2");  // DP needs this for sending proper getstatus replies.
		Team_InitTeams();
		GameRules_spawning_teams(true);
	}
	else
	{
		serverflags &= ~SERVERFLAG_TEAMPLAY;
		teamplay = 0;
		cvar_set("teamplay", "0");  // DP needs this for sending proper getstatus replies.
		GameRules_spawning_teams(false);
	}
}

bool GameRules_limit_score_initialized;
void GameRules_limit_score(int limit)
{
	if (GameRules_limit_score_initialized) return;
	if (autocvar_g_campaign) return;
	if (limit < 0) return;
	cvar_set("fraglimit", ftos(limit));
	GameRules_limit_score_initialized = true;
}

bool GameRules_limit_lead_initialized;
void GameRules_limit_lead(int limit)
{
	if (GameRules_limit_lead_initialized) return;
	if (autocvar_g_campaign) return;
	if (limit < 0) return;
	cvar_set("leadlimit", ftos(limit));
	GameRules_limit_lead_initialized = true;
}

bool GameRules_limit_time_initialized;
void GameRules_limit_time(int limit)
{
	if (GameRules_limit_time_initialized) return;
	if (autocvar_g_campaign) return;
	if (limit < 0) return;
	cvar_set("timelimit", ftos(limit));
	GameRules_limit_time_initialized = true;
}

bool GameRules_limit_time_qualifying_initialized;
void GameRules_limit_time_qualifying(int limit)
{
	if (GameRules_limit_time_qualifying_initialized) return;
	if (autocvar_g_campaign) return;
	if (limit < 0) return;
	cvar_set("g_race_qualifying_timelimit", ftos(limit));
	GameRules_limit_time_qualifying_initialized = true;
}

void GameRules_limit_fallbacks()
{
	GameRules_limit_score(autocvar_fraglimit_override);
	GameRules_limit_lead(autocvar_leadlimit_override);
	GameRules_limit_time(autocvar_timelimit_override);
}

/// Accumulates the decimal part of the score to player.(decimal_field) and adds the score to the player as int
/// only when at least one unit of score has been accumulated. It works with negative score too
/// Float scores can't be used as score because they aren't supported by the QC score networking system
/// and online server browsers (e.g. qstat)
float _GameRules_scoring_add_float2int(entity client, entity sp, int st, float value, .float decimal_field, float score_factor, bool team)
{
	client.(decimal_field) += value;
	float score_counter = client.(decimal_field) / score_factor;
	if (score_counter >= -0.5 && score_counter < 0.5)
		return 0;

	// NOTE: this code works for subtracting score too
	int points = floor(score_counter + 0.5);
	if (!points)
		return 0;
	client.(decimal_field) -= points * score_factor;
	return team ? PlayerTeamScore_Add(client, sp, st, points) : PlayerScore_Add(client, sp, points);
}
