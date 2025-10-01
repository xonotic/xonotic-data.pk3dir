#include "mayhem.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/deathmatch/deathmatch.qh>

METHOD(mayhem, describe, string(mayhem this))
{
	TC(mayhem, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a fast-paced free-for-all deathmatch where players spawn in with all available weapons and maximum health and armor. "
	      "There are no pickups enabled on maps, but buffs are still available."), COLORED_NAME(this));
	PAR(_("It shines in its unique handling of scoring, accounting for both frags but also damage dealt. "
	      "This means that if you almost frag a player you will still be rewarded with points, but dealing the final blow is always better if possible. "
	      "Points are deducted when you walk into hazards, but not when you do movement tricks like blaster jumping since self damage is disabled."));
	PAR(_("Since damage is always rewarded in %s, the more you shoot the better, turning this gametype into chaotic fun at times."), COLORED_NAME(this));
	PAR(_("This gametype is often seen as a more newbie-friendly version of %s."), COLORED_NAME(MAPINFO_TYPE_DEATHMATCH));
	return PAGE_TEXT;
}
#endif
