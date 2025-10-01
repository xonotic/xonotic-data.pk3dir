#include "race.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/cts/cts.qh>

METHOD(Race, describe, string(Race this))
{
	TC(Race, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a gametype similar to %s where players run on a track to be the first to cross the finish line after a certain number of laps."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CTS));
	PAR(_("Before the real race starts there's a qualifying session that decides the starting grid based on the best lap time of each player. "
	      "This stage is very similar to %s since weapons can't be used to disturb other players but can still be used to run faster."), COLORED_NAME(MAPINFO_TYPE_CTS));
	PAR(_("During the real race it's possible to shoot other players in order to slow them down."));
	return PAGE_TEXT;
}
#endif
