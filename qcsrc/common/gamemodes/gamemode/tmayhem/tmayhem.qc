#include "tmayhem.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/clanarena/clanarena.qh>
#include <common/gamemodes/gamemode/mayhem/mayhem.qh>

METHOD(tmayhem, describe, string(tmayhem this))
{
	TC(tmayhem, this);
	return sprintf(_("%s is a constant action team-based gamemode based on %s, using the same scoring system. "
		"It has a lot of similarities to %s, with one of the main differences being that %s is a round-based gamemode, and of course the scoring system differences.\n\n"
		"Since it doesn't have rounds, the chaos is nonstop. "
		"As a consequence of the chaotic nature, team communication is less important in this gamemode than other team-based gamemodes."),
	COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_MAYHEM), COLORED_NAME(MAPINFO_TYPE_CA), COLORED_NAME(MAPINFO_TYPE_CA));
}
#endif
