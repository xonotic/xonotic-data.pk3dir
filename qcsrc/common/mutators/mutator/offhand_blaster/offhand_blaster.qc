#include "offhand_blaster.qh"

#ifdef MENUQC
#include <common/mutators/mutator/hook/hook.qh>
#include <common/weapons/weapon/blaster.qh>

METHOD(MutatorOffhandBlaster, describe, string(MutatorOffhandBlaster this))
{
	TC(MutatorOffhandBlaster, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator gives all players a %s as their offhand weapon, used with %s. "
	      "It can be fired at any time, but the ordinary secondary fire can't be used."), COLORED_NAME(this), COLORED_NAME(WEP_BLASTER), strcat("^3", _("hook"), "^7"));
	PAR(_("Since it's given as an offhand, you can fire it at the same time as the ordinary %s while laser jumping to achieve even more height."), COLORED_NAME(WEP_BLASTER));
	PAR(_("Note that it overrides the %s mutator, since they use the same bind."), COLORED_NAME(MUTATOR_hook));
	return PAGE_TEXT;
}
#endif
