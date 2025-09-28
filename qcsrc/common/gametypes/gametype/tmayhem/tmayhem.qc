#include "tmayhem.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/clanarena/clanarena.qh>
#include <common/gametypes/gametype/mayhem/mayhem.qh>

METHOD(tmayhem, describe, string(tmayhem this))
{
	TC(tmayhem, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a constant action team-based gametype based on %s, using the same scoring system. "
	      "It has a lot of similarities to %s, with one of the main differences being that %s is a round-based gametype, and of course the scoring system differences."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_MAYHEM), COLORED_NAME(MAPINFO_TYPE_CA), COLORED_NAME(MAPINFO_TYPE_CA));
	PAR(_("Since it doesn't have rounds, the chaos is nonstop. "
	      "As a consequence of the chaotic nature, team communication is less important in this gametype than other team-based gametypes."));
	return PAGE_TEXT;
}
#endif
