#include "nix.qh"

#ifdef MENUQC
METHOD(MutatorNIX, describe, string(MutatorNIX this))
{
	TC(MutatorNIX, this);
	PAGE_TEXT_INIT();
	PAR(_("%s (\"No Items Xonotic\") is a mutator that removes all weapon and ammo pickups from the map, and gives all players the same randomly selected weapon. "
	      "After some time, the weapon is reselected, and this repeats forever."), COLORED_NAME(this));
	PAR(_("This means to get good at %s, you'll need to be proficient in all weapons, which may take a lot of experience."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif
