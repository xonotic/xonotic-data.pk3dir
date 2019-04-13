#include "sv_deathmatch.qh"

MUTATOR_HOOKFUNCTION(dm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

// broken:
// -2 points for suicide
// ends at 30 score, not kills
// but who cares

MUTATOR_HOOKFUNCTION(dm, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if (frag_target != frag_attacker) {
		GameRules_scoring_add(frag_target, SCORE, -1);
	}
}
