#include "freezetag.qh"

#ifdef MENUQC
METHOD(FreezeTag, describe, string(FreezeTag this))
{
	TC(FreezeTag, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a round-based teamplay gametype where fragged players are frozen and need to be unfrozen to re-enter the round. "
	      "The round ends when all players from all opposing teams are frozen, scoring the remaining team a point."), COLORED_NAME(this));
	PAR(_("Frozen players slowly unfreeze over time, but they unfreeze much faster when \"revived\" by a teammate standing in close proximity. "
	      "Additionally, damaging frozen players on the other team helps unfreeze them, so it is best to try to avoid doing that."));
	PAR(_("Like in many other round-based gametypes, rounds start with a ten second grace period where weapons cannot be fired, meaning it's a good opportunity to grab as many pickups as you can."));
	PAR(_("Sneakily reviving a teammate will bring them back into the match to help outnumber your opponents, but it should be done with caution since often enemies pay close attention to frozen players to make sure they aren't being revived. "
	      "For this reason it's important to have good team communication especially while frozen, so you can let your teammates know where the enemies are."));
	return PAGE_TEXT;
}
#endif
