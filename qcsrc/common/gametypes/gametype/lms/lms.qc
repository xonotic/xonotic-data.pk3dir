#include "lms.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/clanarena/clanarena.qh>

METHOD(LastManStanding, describe, string(LastManStanding this))
{
	TC(LastManStanding, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a free-for-all gametype where all players start with a certain number of lives, and are eliminated from the match once they lose all lives. "
	      "Players spawn in with all available weapons, maximum health and armor, and health and armor do not regenerate, similar to gametypes like %s. "
	      "Similarly, item pickups don't spawn on the map."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CA));
	PAR(_("Hiding is sometimes a viable strategy since if you can't be found you can't lose lives, but often you become a vulnerable target once discovered."));
	PAR(_("Players leading the game by at least 2 lives glow and periodically have waypoints over their heads visible to all players for a few seconds in order to prevent hiding too much. "
	      "Players who aren't in the lead steal a small percentage of health when they attack leaders, like in the %s mutator."), COLORED_NAME(MUTATOR_vampire));
	return PAGE_TEXT;
}
#endif
