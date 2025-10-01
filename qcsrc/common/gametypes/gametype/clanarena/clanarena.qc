#include "clanarena.qh"

#ifdef MENUQC
METHOD(ClanArena, describe, string(ClanArena this))
{
	TC(ClanArena, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a common round-based gametype played with teams, where players spawn with all weapons available, have maximum health and armor, but only have one life per round. "
	      "There are no pickups available on the map in %s, making the gameplay fast-paced and focused on combat."), COLORED_NAME(this), COLORED_NAME(this));
	PAR(_("Rounds start with a ten second grace period where weapons cannot be fired, so it's a good opportunity to group up with your team."));
	PAR(_("The match ends once a team reaches a certain number of rounds won, or has a considerable lead over the other team."));
	PAR(_("Since players only have one life per round, it's important to group up with fellow teammates and pay attention to any callouts from them. "
	      "Team coordination is key!"));
	return PAGE_TEXT;
}
#endif
