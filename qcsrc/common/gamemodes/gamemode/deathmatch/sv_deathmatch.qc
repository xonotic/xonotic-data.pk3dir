#include "sv_deathmatch.qh"

MUTATOR_HOOKFUNCTION(dm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}
