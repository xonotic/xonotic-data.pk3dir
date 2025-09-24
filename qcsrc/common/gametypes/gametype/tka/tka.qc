#include "tka.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/keepaway/keepaway.qh>

METHOD(TeamKeepaway, describe, string(TeamKeepaway this))
{
	TC(TeamKeepaway, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is the team version of %s, where teams compete to maintain superior control over the ball."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_KEEPAWAY));
	PAR(_("Scoring is similar to in %s, except that points are awarded for frags for all members of the team of the player holding the ball."), COLORED_NAME(MAPINFO_TYPE_KEEPAWAY));
	return PAGE_TEXT;
}
#endif
