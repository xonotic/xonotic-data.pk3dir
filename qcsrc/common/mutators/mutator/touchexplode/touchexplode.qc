#include "touchexplode.qh"

#ifdef MENUQC
METHOD(MutatorTouchExplode, describe, string(MutatorTouchExplode this))
{
	TC(MutatorTouchExplode, this);
	return sprintf(_("The %s mutator causes an explosion when two players collide if it is enabled\n\n"
		"This is a nice way to add some silly fun to a server, but it also does allow for the use of new tactics in some gamemodes"),
	COLORED_NAME(this));
}
#endif
