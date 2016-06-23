#include "scores_rules.qh"

#include "cl_client.qh"
#include "scores.qh"

void CheckAllowedTeams (entity for_whom);

int NumTeams(int teams)
{
	return boolean(teams & BIT(0)) + boolean(teams & BIT(1)) + boolean(teams & BIT(2)) + boolean(teams & BIT(3));
}

// NOTE: SP_ constants may not be >= MAX_SCORE; ST_constants may not be >= MAX_TEAMSCORE
// scores that should be in all modes:
int ScoreRules_teams;
void ScoreRules_basics(int teams, float sprio, float stprio, float score_enabled)
{
	float i;
	for(i = 0; i < MAX_SCORE; ++i)
		ScoreInfo_SetLabel_PlayerScore(i, "", 0);
	for(i = 0; i < MAX_TEAMSCORE; ++i)
		ScoreInfo_SetLabel_TeamScore(i, "", 0);

	ScoreRules_teams = teams;

	if(score_enabled)
		ScoreInfo_SetLabel_TeamScore  (ST_SCORE,        "score",     stprio);

	if (!INDEPENDENT_PLAYERS)
		ScoreInfo_SetLabel_PlayerScore(SP_KILLS,        "kills",     0);

	ScoreInfo_SetLabel_PlayerScore(SP_DEATHS,       "deaths",    SFL_LOWER_IS_BETTER);

	if (!INDEPENDENT_PLAYERS)
		ScoreInfo_SetLabel_PlayerScore(SP_SUICIDES,     "suicides",  SFL_LOWER_IS_BETTER);

	if(score_enabled)
		ScoreInfo_SetLabel_PlayerScore(SP_SCORE,        "score",     sprio);

	ScoreInfo_SetLabel_PlayerScore(SP_DMG, "damage", 0);
	ScoreInfo_SetLabel_PlayerScore(SP_DMGTAKEN, "damagetaken", SFL_LOWER_IS_BETTER);
}
void ScoreRules_basics_end()
{
	ScoreInfo_Init(ScoreRules_teams);
}
void ScoreRules_generic()
{
	if(teamplay)
	{
		CheckAllowedTeams(NULL);
		int teams = 0;
		if(c1 >= 0) teams |= BIT(0);
		if(c2 >= 0) teams |= BIT(1);
		if(c3 >= 0) teams |= BIT(2);
		if(c4 >= 0) teams |= BIT(3);
		ScoreRules_basics(teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, true);
	}
	else
		ScoreRules_basics(0, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, true);
	ScoreRules_basics_end();
}
