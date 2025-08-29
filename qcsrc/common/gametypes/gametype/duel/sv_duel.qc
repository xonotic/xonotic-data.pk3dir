#include "sv_duel.qh"

MUTATOR_HOOKFUNCTION(duel, GetPlayerLimit)
{
	M_ARGV(0, int) = 2; // duel is always 1v1!
}

MUTATOR_HOOKFUNCTION(duel, Scores_CountFragsRemaining)
{
	// announce remaining frags?
	return true;
}

MUTATOR_HOOKFUNCTION(duel, FilterItemDefinition)
{
	entity definition = M_ARGV(0, entity);

	if(definition.instanceOfPowerup)
	{
		return !autocvar_g_duel_with_powerups;
	}
}
