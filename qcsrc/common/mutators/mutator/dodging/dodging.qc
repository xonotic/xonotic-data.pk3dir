#include "dodging.qh"

#ifdef MENUQC
#include "../overkill/overkill.qh"

METHOD(MutatorDodging, describe, string(MutatorDodging this))
{
	TC(MutatorDodging, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a mutator that enables dodging maneuvers, making evading attacks in close combat easier. "
	      "If enabled, when you're standing on the ground and double tap a movement key, you will leap in that direction. "
	      "This also works while in contact with a wall, allowing quick speed gain if done repeatedly against a long wall."), COLORED_NAME(this));
	PAR(_("Some other mutators like %s enable this by default."), COLORED_NAME(MUTATOR_ok));
	return PAGE_TEXT;
}
#endif
