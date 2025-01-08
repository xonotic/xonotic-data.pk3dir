#include "hook.qh"

#ifdef MENUQC
#include <common/mutators/mutator/offhand_blaster/offhand_blaster.qh>
#include <common/weapons/weapon/hook.qh>

METHOD(MutatorGrapplingHook, describe, string(MutatorGrapplingHook this))
{
	TC(MutatorGrapplingHook, this);
	return sprintf(_("The %s mutator gives all players a %s as their offhand weapon, used with ^3+hook^7. "
		"It has unlimited ammo, but the ordinary secondary fire can't be used\n\n"
		"Since it's given as an offhand, players can use it to move around and shoot at their enemies at the same time, opening up more gameplay possibilities than the regular %s\n\n"
		"Note that it is overridden by the %s mutator"),
	COLORED_NAME(this), COLORED_NAME(WEP_HOOK), COLORED_NAME(WEP_HOOK), COLORED_NAME(MUTATOR_offhand_blaster));
}
#endif
