#include "tdm.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/deathmatch/deathmatch.qh>

METHOD(TeamDeathmatch, describe, string(TeamDeathmatch this))
{
	TC(TeamDeathmatch, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is the team version of %s, played in teams rather than solo."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_DEATHMATCH));
	PAR(_("Scoring is quite simple, adding a point for every frag, and subtracting a point for fragging yourself or a teammate."));
	PAR(_("Careful team coordination and map control is often key to winning a match, and sometimes players will share weapons with their teammates."));
	return PAGE_TEXT;
}
#endif
