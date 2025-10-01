#include "cts.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/race/race.qh>

METHOD(RaceCTS, describe, string(RaceCTS this))
{
	TC(RaceCTS, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a unique gametype, focusing on racing against other players on the map, rather than fighting them with weapons. "
	      "Players run through the map from start to finish as fast as possible and try to beat the times set by others."), COLORED_NAME(this));
	PAR(_("%s is similar to %s, except you don't run in laps, and instead run from the start line to the finish line then start over again."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_RACE));
	PAR(_("Although this gametype is quite different from the rest, it is played quite frequently since it's a great way to master movement skills and there are heaps of community-made maps available. "
	      "Also, it only requires one player to play."));
	return PAGE_TEXT;
}
#endif
