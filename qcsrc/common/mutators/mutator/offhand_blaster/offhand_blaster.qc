#include "offhand_blaster.qh"

#ifdef MENUQC
#include <common/mutators/mutator/hook/hook.qh>
#include <common/weapons/weapon/blaster.qh>

METHOD(MutatorOffhandBlaster, describe, string(MutatorOffhandBlaster this))
{
	TC(MutatorOffhandBlaster, this);
	return sprintf(_("The %s mutator gives all players a %s as their offhand weapon, used with ^3+hook^7. "
		"It can be fired at any time, but the ordinary secondary fire can't be used\n\n"
		"Since it's given as an offhand, you can fire it at the same time as the ordinary %s while laser jumping to achieve even more height\n\n"
		"Note that it overrides the %s mutator, since they use the same bind"),
	COLORED_NAME(this), COLORED_NAME(WEP_BLASTER), COLORED_NAME(WEP_BLASTER), COLORED_NAME(MUTATOR_hook));
}
#endif
