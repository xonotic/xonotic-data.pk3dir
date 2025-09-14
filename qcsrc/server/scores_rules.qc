#include "scores_rules.qh"

#include <common/gametypes/rules.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <server/client.qh>
#include <server/scores.qh>
#include <server/teamplay.qh>

bool autocvar_sv_showskill;

int NumTeams(int teams)
{
	return boolean(teams & BIT(0)) + boolean(teams & BIT(1)) + boolean(teams & BIT(2)) + boolean(teams & BIT(3));
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

	teamplay_bitmask = teams;
	AVAILABLE_TEAMS = NumTeams(teams);
	if (AVAILABLE_TEAMS)
		Team_InitTeams();

	if(score_enabled)
		ScoreInfo_SetLabel_TeamScore(ST_SCORE, "score", stprio);

	if (!INDEPENDENT_PLAYERS)
		ScoreInfo_SetLabel_PlayerScore(SP_KILLS, "kills", 0);

	ScoreInfo_SetLabel_PlayerScore(SP_DEATHS, "deaths", SFL_LOWER_IS_BETTER);

	if (!INDEPENDENT_PLAYERS)
	{
		ScoreInfo_SetLabel_PlayerScore(SP_SUICIDES, "suicides", SFL_LOWER_IS_BETTER);
		if (teamplay)
			ScoreInfo_SetLabel_PlayerScore(SP_TEAMKILLS, "teamkills", SFL_LOWER_IS_BETTER);
	}

	if(score_enabled)
		ScoreInfo_SetLabel_PlayerScore(SP_SCORE, "score", sprio);

	if (!INDEPENDENT_PLAYERS)
	{
		ScoreInfo_SetLabel_PlayerScore(SP_DMG, "dmg", 0);
		ScoreInfo_SetLabel_PlayerScore(SP_DMGTAKEN, "dmgtaken", SFL_LOWER_IS_BETTER);

		if (autocvar_sv_showskill == 1 || (autocvar_sv_showskill == 2 && teamplay))
			ScoreInfo_SetLabel_PlayerScore(SP_SKILL, "skill", SFL_NOT_SORTABLE);
	}

	if(STAT(SHOWFPS))
		ScoreInfo_SetLabel_PlayerScore(SP_FPS, "fps", SFL_NOT_SORTABLE);
}

void ScoreRules_basics_end()
{
	ScoreInfo_Init(teamplay_bitmask);
}
