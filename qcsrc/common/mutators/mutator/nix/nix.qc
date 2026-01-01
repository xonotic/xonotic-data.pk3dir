#include "nix.qh"

#ifdef MENUQC
METHOD(MutatorNIX, describe, string(MutatorNIX this))
{
	TC(MutatorNIX, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a mutator that gives all players the same randomly-selected weapon. After some time the weapon is reselected, and this repeats forever. "
	      "Weapon and ammo pickups are also removed from the map."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif
