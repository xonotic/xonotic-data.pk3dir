#include "deathmatch.qh"

// TODO: sv_deathmatch?
#ifdef SVQC
MUTATOR_HOOKFUNCTION(dm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}
#endif
