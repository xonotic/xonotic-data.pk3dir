#include "assault.qh"

#ifdef MENUQC
METHOD(Assault, describe, string(Assault this))
{
	TC(Assault, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a team-based gametype involving an attacking and a defending team."), COLORED_NAME(this));
	PAR(_("The attacking team has to destroy objects placed on the map, which opens up new doors or pathways to more objects, until the main object is reached and destroyed. "
	      "The defending team has to defend the objects, winning the game if they successfully prevent the attacking team from destroying the main object within the time limit. "
	      "If they fail then a second round is played where teams switch roles and the new attacking team wins only if they destroy the main object within the time the other team took to do it."));
	PAR(_("Objects have waypoints which show their health and position, and they're destroyed by shooting them with any weapon."));
	return PAGE_TEXT;
}
#endif
