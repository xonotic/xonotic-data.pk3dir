#include "sv_duel.qh"

MUTATOR_HOOKFUNCTION(duel, ReadLevelCvars)
{
	warmup_stage = 1;
	//sv_ready_restart_after_countdown = 0;
}

MUTATOR_HOOKFUNCTION(duel, GetPlayerLimit)
{
	M_ARGV(0, int) = 2; // duel is always 1v1!
}

MUTATOR_HOOKFUNCTION(duel, Scores_CountFragsRemaining)
{
	// announce remaining frags?
	return true;
}
