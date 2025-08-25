#include "lms.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/clanarena/clanarena.qh>

METHOD(LastManStanding, describe, string(LastManStanding this))
{
    TC(LastManStanding, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a free-for-all gametype where all players start with a certain number of lives, and are eliminated from the match once they lose all lives. "
        "Players spawn in with all available weapons, maximum health, maximum armor, and health and armor do not regenerate, similar to gametypes like %s. "
	      "Similarly, item pickups don't spawn on the map."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CA));
	PAR(_("Hiding is sometimes a viable strategy since if you can't be found you can't lose lives, but often you become a vulnerable target once discovered."));
	return PAGE_TEXT;
}
#endif
