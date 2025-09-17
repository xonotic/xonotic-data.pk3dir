#include "touchexplode.qh"

#ifdef MENUQC
METHOD(MutatorTouchExplode, describe, string(MutatorTouchExplode this))
{
	TC(MutatorTouchExplode, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator causes an explosion when two players collide if it is enabled."), COLORED_NAME(this));
	PAR(_("This is a nice way to add some silly fun to a server, but it also does allow for the use of new tactics in some gametypes."));
	return PAGE_TEXT;
}
#endif
