#include "invasion.qh"

#ifdef MENUQC
METHOD(Invasion, describe, string(Invasion this))
{
	TC(Invasion, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a unique gametype played in rounds where a herd of monsters spawn all around the map and players must try to frag as many as possible. "
	      "Since players can't damage each other, they instead fight to steal monster frags from each other. "
	      "The player who frags the most monsters overall wins the match."), COLORED_NAME(this));
	PAR(_("A round ends when either all monsters are fragged, or after a time limit."));
	return PAGE_TEXT;
}
#endif
