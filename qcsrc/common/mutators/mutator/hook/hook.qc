#include "hook.qh"

#ifdef MENUQC
#include "../offhand_blaster/offhand_blaster.qh"
#include <common/weapons/weapon/hook.qh>

METHOD(MutatorGrapplingHook, describe, string(MutatorGrapplingHook this))
{
	TC(MutatorGrapplingHook, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator gives all players a %s as their offhand weapon, used with %s. "
	      "It has unlimited ammo, but the ordinary secondary fire can't be used."), COLORED_NAME(this), COLORED_NAME(WEP_HOOK), strcat("^3", _("hook"), "^7"));
	PAR(_("Since it's given as an offhand, players can use it to move around and shoot at their enemies at the same time, opening up more gameplay possibilities than the regular %s."), COLORED_NAME(WEP_HOOK));
	PAR(_("Note that it is overridden by the %s mutator."), COLORED_NAME(MUTATOR_offhand_blaster));
	return PAGE_TEXT;
}
#endif
