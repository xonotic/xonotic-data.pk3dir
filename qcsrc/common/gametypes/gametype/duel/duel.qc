#include "duel.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/deathmatch/deathmatch.qh>
#include <common/items/item/health.qh>
#include <common/items/item/armor.qh>

METHOD(Duel, describe, string(Duel this))
{
	TC(Duel, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a 1-vs-1 arena battle to decide the winner, essentially a 2-player version of %s, making it one of the most competitive gametypes."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_DEATHMATCH));
	PAR(_("Since players are on their own, important items like the %s and %s are heavily contested, "
	      "and are often \"timed\" by observing the in-game timer when they are picked up to determine when they'll next spawn. "
	      "The player with the best item control is often the winner, so this is a key aspect to master."), COLORED_NAME(ITEM_HealthMega), COLORED_NAME(ITEM_ArmorMega));
	PAR(_("Once you frag your opponent, they will spawn with few weapons and limited health, so it is a good opportunity to search the map for them to pick up an easy frag and continue your streak."));
	PAR(_("%s is often played with %s rules."), COLORED_NAME(this), _("XPM"));
	return PAGE_TEXT;
}
#endif
