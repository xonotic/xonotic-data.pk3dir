#include "race.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/cts/cts.qh>

METHOD(Race, describe, string(Race this))
{
	TC(Race, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a gametype similar to %s except the start and finish line of the track are identical, so you run laps repeatedly through the track."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CTS));
	PAR(_("Consequently the aim is to keep running constantly to complete as many laps as possible for the shot at the fastest time, rather than resetting runs like in %s to set the individual best time. "
	      "Since you continue straight onto the next lap, having a speedy finish to a lap means that your next lap will start off with high speed, giving you a good shot at beating your personal best."), COLORED_NAME(MAPINFO_TYPE_CTS));
	return PAGE_TEXT;
}
#endif
