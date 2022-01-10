#include "scores_rules.qh"

#include <common/gamemodes/rules.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <server/client.qh>
#include <server/scores.qh>
#include <server/teamplay.qh>

int ScoreRules_teams;

bool IsTeamAvailable(int team_num)
{
	return boolean(ScoreRules_teams & Team_TeamToBit(team_num));
}

int NumTeams(int teams)
{
	return boolean(teams & BIT(0)) + boolean(teams & BIT(1)) + boolean(teams & BIT(2)) + boolean(teams & BIT(3));
}

int AvailableTeams()
{
	return NumTeams(ScoreRules_teams);
}

// NOTE: ST_constants may not be >= MAX_TEAMSCORE
// scores that should be in all modes:
void ScoreRules_basics(int teams, float sprio, float stprio, float score_enabled)
{
	FOREACH(Scores, true, {
		ScoreInfo_SetLabel_PlayerScore(it, "", 0);
	});
	for(int i = 0; i < MAX_TEAMSCORE; ++i)
		ScoreInfo_SetLabel_TeamScore(i, "", 0);

	ScoreRules_teams = teams;

	if(score_enabled)
		ScoreInfo_SetLabel_TeamScore(ST_SCORE, "score", stprio);

	if (!INDEPENDENT_PLAYERS)
		ScoreInfo_SetLabel_PlayerScore(SP_KILLS, "kills", 0);

	ScoreInfo_SetLabel_PlayerScore(SP_DEATHS, "deaths", SFL_LOWER_IS_BETTER);

	if (!INDEPENDENT_PLAYERS)
	{
		ScoreInfo_SetLabel_PlayerScore(SP_SUICIDES, "suicides", SFL_LOWER_IS_BETTER);
		ScoreInfo_SetLabel_PlayerScore(SP_TEAMKILLS, "teamkills", SFL_LOWER_IS_BETTER);
	}

	if(score_enabled)
		ScoreInfo_SetLabel_PlayerScore(SP_SCORE, "score", sprio);

	ScoreInfo_SetLabel_PlayerScore(SP_DMG, "dmg", 0);
	ScoreInfo_SetLabel_PlayerScore(SP_DMGTAKEN, "dmgtaken", SFL_LOWER_IS_BETTER);
	ScoreInfo_SetLabel_PlayerScore(SP_ELO, "elo", 0);

	if(STAT(SHOWFPS))
		ScoreInfo_SetLabel_PlayerScore(SP_FPS, "fps", 0);
}

void ScoreRules_basics_end()
{
	ScoreInfo_Init(ScoreRules_teams);
}

void ScoreRules_generic()
{
	int teams = 0;
	if (teamplay)
	{
		entity balance = TeamBalance_CheckAllowedTeams(NULL);
		teams = TeamBalance_GetAllowedTeams(balance);
		TeamBalance_Destroy(balance);
	}
	GameRules_scoring(teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, {});
}
