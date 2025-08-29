#include "cl_cts.qh"

#include <common/mutators/base.qh>

REGISTER_MUTATOR(cl_cts, true);

MUTATOR_HOOKFUNCTION(cl_cts, HUD_Physics_showoptional)
{
	return ISGAMETYPE(CTS); // show the optional physics panel
}

MUTATOR_HOOKFUNCTION(cl_cts, HUD_StrafeHUD_showoptional)
{
	return ISGAMETYPE(CTS); // show the optional strafehud
}

MUTATOR_HOOKFUNCTION(cl_cts, HUD_Score_show)
{
	return spectatee_status == -1 && ISGAMETYPE(CTS); // hide the score panel while observing
}

MUTATOR_HOOKFUNCTION(cl_cts, DrawScoreboardItemStats)
{
	return ISGAMETYPE(CTS); // hide the item stats panel
}

MUTATOR_HOOKFUNCTION(cl_cts, DrawDeathScoreboard)
{
	return ISGAMETYPE(CTS); // no scoreboard shown while dead
}

MUTATOR_HOOKFUNCTION(cl_cts, DrawScoreboardAccuracy)
{
	return ISGAMETYPE(CTS); // accuracy is not a factor in this gametype
}

MUTATOR_HOOKFUNCTION(cl_cts, ShowRankings)
{
	if(ISGAMETYPE(CTS))
	{
		M_ARGV(0, string) = _("Rankings");
		return true;
	}
}

MUTATOR_HOOKFUNCTION(cl_cts, ShowRaceTimer)
{
	return ISGAMETYPE(CTS); // show the race timer panel
}
