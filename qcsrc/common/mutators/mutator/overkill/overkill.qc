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
	string s = sprintf(_("%s is a mutator that heavily modifies the game, giving players fewer but more powerful weapons, nades, and more movement options.\n\n"
		"In terms of weaponry, players have infinite ammo and spawn in with the %s, %s, and %s, and can pick up the %s and %s superweapons on the map sometimes. "
		"These weapons are a lot more powerful than the regular weapons, so their time-to-kill is quite low.\n\n"
		"The secondary fire of all weapons shoots a laser which does not damage or push enemies, but can be used to push yourself around. "),
	COLORED_NAME(this), COLORED_NAME(WEP_OVERKILL_SHOTGUN), COLORED_NAME(WEP_OVERKILL_MACHINEGUN), COLORED_NAME(WEP_OVERKILL_NEX), COLORED_NAME(WEP_OVERKILL_HMG), COLORED_NAME(WEP_OVERKILL_RPC));
	s = strcat(s, sprintf(_("Also since the %s mutator is active, all players have offhand nades.\n\n"
		"As for movement tricks, %s is enabled by default in %s, allowing for rapidly changing your movement direction."),
	COLORED_NAME(MUTATOR_nades), COLORED_NAME(MUTATOR_dodging), COLORED_NAME(this)));
	return s;
}
#endif
