#include "mayhem.qh"

#ifdef MENUQC
METHOD(mayhem, describe, string(mayhem this))
{
	TC(mayhem, this);
	return sprintf(_("%s is a fast-paced free-for-all deathmatch where players spawn in with all available weapons and maximum health and armor. "
		"There are no pickups enabled on maps, but buffs are still available\n\n"
		"It shines in its unique handling of scoring, accouting for both frags but also damage dealt. "
		"This means that if you almost frag a player you will still be rewarded with points, but dealing the final blow is always better if possible. "
		"Points are deducted when you walk into damage triggers, but not when you do movement tricks like blaster jumping since self damage is disabled\n\n"
		"Since damage is always rewarded in %s, the more you shoot the better, turning this gamemode into chaotic fun at times"),
	COLORED_NAME(this), COLORED_NAME(this));
}
#endif
