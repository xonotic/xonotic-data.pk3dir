#include "vampire.qh"

#ifdef MENUQC
#include <common/mutators/mutator/buffs/buffs.qh>

METHOD(MutatorVampire, describe, string(MutatorVampire this))
{
	TC(MutatorVampire, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator gives all players a permanent version of the %s buff. "
	      "However, unlike the normal %s buff, when this mutator is enabled players' health can go way above the usual limit of 200."), COLORED_NAME(this), COLORED_NAME(BUFF_VAMPIRE), COLORED_NAME(BUFF_VAMPIRE));
	PAR(_("Additionally the amount of health players get is equal to the damage they deal, which isn't normally the case with the %s buff."), COLORED_NAME(BUFF_VAMPIRE));
	return PAGE_TEXT;
}
#endif
