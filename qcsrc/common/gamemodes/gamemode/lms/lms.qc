#include "lms.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/clanarena/clanarena.qh>

METHOD(LastManStanding, describe, string(LastManStanding this))
{
    TC(LastManStanding, this);
    return sprintf(_("%s is a free-for-all gamemode where all players start with a certain number of lives, and are eliminated from the match once they lose all lives. "
        "Players spawn in with all available weapons, maximum health, maximum armor, and health and armor do not regenerate, similar to gamemodes like %s. "
        "Similarly, item pickups don't spawn on the map.\n\n"
        "Hiding is sometimes a viable strategy since if you can't be found you can't lose lives, but often you become a vulnerable target once discovered."),
    COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CA));
}
#endif
