#include "new_toys.qh"

#include <common/weapons/_all.qh>

// TODO: unhardcode this
bool nt_IsNewToy(int w)
{
	switch (w)
	{
		case WEP_SEEKER.m_id:
		case WEP_MINE_LAYER.m_id:
		case WEP_HLAC.m_id:
		case WEP_RIFLE.m_id:
		case WEP_ARC.m_id:
			return true;
		default:
			return false;
	}
}

#ifdef MENUQC
#include <common/mutators/mutator/instagib/instagib.qh>
#include <common/mutators/mutator/overkill/overkill.qh>

METHOD(MutatorNewToys, describe, string(MutatorNewToys this))
{
	TC(MutatorNewToys, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s mutator, enabled by default, allows the spawning of new gimmicky weapons, sometimes replacing a core weapon."), COLORED_NAME(this));
	PAR(_("Since these weapons can't spawn in %s and %s, the %s mutator can't be enabled concurrently."), COLORED_NAME(MUTATOR_mutator_instagib), COLORED_NAME(MUTATOR_ok), COLORED_NAME(this));
	PAR(_("The current %s weapons are:"), COLORED_NAME(this)); // do it like this so that the string doesn't need to change when the list is updated
	FOREACH(Weapons, nt_IsNewToy(it.m_id), {
		PAGE_TEXT = strcat(PAGE_TEXT, "\n* ", COLORED_NAME(it));
	});
	return PAGE_TEXT;
}
#endif
