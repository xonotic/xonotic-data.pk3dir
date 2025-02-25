#include "nix.qh"

#ifdef MENUQC
METHOD(MutatorNIX, describe, string(MutatorNIX this))
{
	TC(MutatorNIX, this);
	return sprintf(_("%s (\"No Items Xonotic\") is a mutator that removes all weapon and ammo pickups from the map, and gives all players the same randomly selected weapon. "
		"After some time, the weapon is reselected, and this repeats forever."),
	COLORED_NAME(this));
}
#endif
