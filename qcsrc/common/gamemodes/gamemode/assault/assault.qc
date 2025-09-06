#include "assault.qh"

#ifdef MENUQC
METHOD(Assault, describe, string(Assault this))
{
	TC(Assault, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a team-based gametype involving an attacking and a defending team."), COLORED_NAME(this));
	PAR(_("The attacking team destroys objects placed on the map, which opens up new doors or pathways to more objects, until a main object (the enemy power core) is reached. "
	      "The attacking team wins the round if they manage to destroy the power core before time runs out, and then teams switch roles in the next round."));
	PAR(_("The defending team has to defend the objects, winning the round if they successfully prevent the attacking team from destroying the power core."));
	PAR(_("A team will win the match overall once they win at least one round where they attacked and one round where they defended, meaning there can be ties."));
	PAR(_("Objects have waypoints which show their health and position, and they're destroyed by shooting them with any weapon."));
	return PAGE_TEXT;
}
#endif
