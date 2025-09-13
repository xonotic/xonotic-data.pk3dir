#include "pinata.qh"

#ifdef MENUQC
METHOD(MutatorPinata, describe, string(MutatorPinata this))
{
	TC(MutatorPinata, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a mutator that makes players drop all their weapons when they die. "
	      "Without this mutator, players normally drop only their equipped weapon."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif
