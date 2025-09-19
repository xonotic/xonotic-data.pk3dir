#include "vampire.qh"

#ifdef MENUQC
#include <common/mutators/mutator/buffs/buffs.qh>

METHOD(MutatorVampire, describe, string(MutatorVampire this))
{
	TC(MutatorVampire, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator gives all players a permanent version of the %s. "
	      "However, unlike the normal %s, when this mutator is enabled players' health can go way above the usual limit of 200."), COLORED_NAME(this), COLORED_NAME_WITH_CONCAT(BUFF_VAMPIRE, _("Buff")), COLORED_NAME_WITH_CONCAT(BUFF_VAMPIRE, _("Buff")));
	PAR(_("Additionally the amount of health players get is equal to the damage they deal, which isn't normally the case with the %s."), COLORED_NAME_WITH_CONCAT(BUFF_VAMPIRE, _("Buff")));
	return PAGE_TEXT;
}
#endif
