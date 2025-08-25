#include "overkill.qh"

#ifdef MENUQC
#include "okhmg.qh"
#include "oknex.qh"
#include "okmachinegun.qh"
#include "okrpc.qh"
#include "okshotgun.qh"
#include <common/mutators/mutator/dodging/dodging.qh>
#include <common/mutators/mutator/nades/nades.qh>

METHOD(MutatorOverkill, describe, string(MutatorOverkill this))
{
	TC(MutatorOverkill, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a mutator that heavily modifies the game, giving players fewer but more powerful weapons, nades, and more movement options."), COLORED_NAME(this));
	PAR(_("In terms of weaponry, players have infinite ammo and spawn in with the %s, %s, and %s, and can pick up the %s and %s superweapons on the map sometimes. "
	      "These weapons are a lot more powerful than the regular weapons, so their time-to-kill is quite low."), COLORED_NAME(WEP_OVERKILL_SHOTGUN), COLORED_NAME(WEP_OVERKILL_MACHINEGUN), COLORED_NAME(WEP_OVERKILL_NEX), COLORED_NAME(WEP_OVERKILL_HMG), COLORED_NAME(WEP_OVERKILL_RPC));
	PAR(_("The secondary fire of all weapons shoots a laser which does not damage or push enemies, but can be used to push yourself around. "
	      "Also since the %s mutator is active, all players have offhand nades."), COLORED_NAME(MUTATOR_nades));
	PAR(_("As for movement tricks, %s is enabled by default in %s, allowing for rapidly changing your movement direction."), COLORED_NAME(MUTATOR_dodging), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif
