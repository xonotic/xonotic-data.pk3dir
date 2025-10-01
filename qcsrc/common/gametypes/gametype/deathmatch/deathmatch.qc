#include "deathmatch.qh"

#ifdef MENUQC
#include <common/items/item/health.qh>
#include <common/items/item/armor.qh>

METHOD(Deathmatch, describe, string(Deathmatch this))
{
	TC(Deathmatch, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a simple free-for-all fight to the death, where everyone plays against everyone else, and the winner is the one with the most points. "
	      "When fragged, you respawn with only the starter weapons, so any you collected will have to be picked up again."), COLORED_NAME(this));
	PAR(_("Scoring is quite simple, fragging an opponent adds one to your score, and fragging yourself subtracts one."));
	PAR(_("Maps often have powerups and items like %s and %s, which are usually highly contested since they sometimes have the power to make or break a game, so making good use of them is important."), COLORED_NAME(ITEM_HealthMega), COLORED_NAME(ITEM_ArmorMega));
	return PAGE_TEXT;
}
#endif
