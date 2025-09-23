#include "rocketflying.qh"

#ifdef MENUQC
#include <common/weapons/weapon/devastator.qh>

METHOD(MutatorRocketFlying, describe, string(MutatorRocketFlying this))
{
	TC(MutatorRocketFlying, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator removes the slight delay when immediately detonating a %s rocket after firing. "
	      "This allows rockets to be detonated much closer to your hitbox, so they can give you a much larger speed boost, also allowing flying around the map."), COLORED_NAME(this), COLORED_NAME(WEP_DEVASTATOR));
	return PAGE_TEXT;
}
#endif
