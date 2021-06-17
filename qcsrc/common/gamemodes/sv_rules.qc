#include "sv_rules.qh"

#include <server/spawnpoints.qh>
#include <server/teamplay.qh>

void GameRules_teams(bool value)
{
    if (value) {
        serverflags |= SERVERFLAG_TEAMPLAY;
        teamplay = 1;
        cvar_set("teamplay", "2");  // DP needs this for sending proper getstatus replies.
        Team_InitTeams();
        GameRules_spawning_teams(true);
    } else {
    	serverflags &= ~SERVERFLAG_TEAMPLAY;
    	teamplay = 0;
    	cvar_set("teamplay", "0");  // DP needs this for sending proper getstatus replies.
    	GameRules_spawning_teams(false);
    }
}

void GameRules_spawning_teams(bool value)
{
    have_team_spawns = value ? -1 : 0;
}

bool _GameRules_score_enabled = true;
void GameRules_score_enabled(bool value)
{
    _GameRules_score_enabled = value;
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

void _GameRules_scoring_begin(int teams, float spprio, float stprio)
{
    ScoreRules_basics(teams, spprio, stprio, _GameRules_score_enabled);
}
void _GameRules_scoring_field(entity i, string label, int scoreflags)
{
    ScoreInfo_SetLabel_PlayerScore(i, label, scoreflags);
}
void _GameRules_scoring_field_team(float i, string label, int scoreflags)
{
    ScoreInfo_SetLabel_TeamScore(i, label, scoreflags);
}
void _GameRules_scoring_end()
{
    ScoreRules_basics_end();
}

.bool m_GameRules_scoring_vip;
void GameRules_scoring_vip(entity player, bool value)
{
    player.m_GameRules_scoring_vip = value;
}
bool GameRules_scoring_is_vip(entity player)
{
    return player.m_GameRules_scoring_vip;
}

float _GameRules_scoring_add(entity client, entity sp, float value)
{
    return PlayerScore_Add(client, sp, value);
}
float _GameRules_scoring_add_team(entity client, entity sp, int st, float value)
{
    return PlayerTeamScore_Add(client, sp, st, value);
}
