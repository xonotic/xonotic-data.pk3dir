#include "cl_ctscup.qh"

#include <common/mutators/base.qh>

REGISTER_MUTATOR(cl_ctscup, true);

MUTATOR_HOOKFUNCTION(cl_ctscup, HUD_Physics_showoptional)
{
	return ISGAMETYPE(CTSCUP); // show the optional physics panel
}

MUTATOR_HOOKFUNCTION(cl_ctscup, HUD_StrafeHUD_showoptional)
{
	return ISGAMETYPE(CTSCUP); // show the optional strafehud
}

MUTATOR_HOOKFUNCTION(cl_ctscup, HUD_Score_show)
{
	return spectatee_status == -1 && ISGAMETYPE(CTSCUP); // hide the score panel while observing
}

MUTATOR_HOOKFUNCTION(cl_ctscup, DrawScoreboardItemStats)
{
	return ISGAMETYPE(CTSCUP); // hide the item stats panel
}

MUTATOR_HOOKFUNCTION(cl_ctscup, DrawDeathScoreboard)
{
	return ISGAMETYPE(CTSCUP); // no scoreboard shown while dead
}

MUTATOR_HOOKFUNCTION(cl_ctscup, DrawScoreboardAccuracy)
{
	return ISGAMETYPE(CTSCUP); // accuracy is not a factor in this gamemode
}

MUTATOR_HOOKFUNCTION(cl_ctscup, ShowRankings)
{
	if(ISGAMETYPE(CTSCUP))
	{
		M_ARGV(0, string) = _("Rankings");
		return true;
	}
}

MUTATOR_HOOKFUNCTION(cl_ctscup, ShowNames_Draw)
{
	return (ISGAMETYPE(CTSCUP) && M_ARGV(1, float) < ALPHA_MIN_VISIBLE);
}

MUTATOR_HOOKFUNCTION(cl_ctscup, ShowRaceTimer)
{
	return ISGAMETYPE(CTSCUP); // show the race timer panel
}
