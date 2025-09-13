#include "cloaked.qh"

#ifdef MENUQC
#include "../powerups/powerup/invisibility.qh"

METHOD(MutatorCloaked, describe, string(MutatorCloaked this))
{
	TC(MutatorCloaked, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator makes all players nearly invisible, similar to the %s powerup. "
	      "This adds an extra layer of stealth and strategy to gameplay."), COLORED_NAME(this), COLORED_NAME(ITEM_Invisibility));
	return PAGE_TEXT;
}
#endif
