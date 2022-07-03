#include "sv_deathmatch.qh"

MUTATOR_HOOKFUNCTION(dm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(dm, ReadLevelCvars)
{
	Mayhem_FragLimit_Override();
}

MUTATOR_HOOKFUNCTION(dm, PlayerDamage_SplitHealthArmor)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	//float dmg_taken = M_ARGV(4, float);
	//float dmg_saved = M_ARGV(5, float);
	float frag_deathtype = M_ARGV(6, float);
	float frag_damage = M_ARGV(7, float);

	Mayhem_Scoring_Method( 
		frag_attacker, 
		frag_target, 
		M_ARGV(4, float), 
		M_ARGV(5, float), 
		frag_deathtype, 
		frag_damage
	);
}

MUTATOR_HOOKFUNCTION(dm, GiveFragsForKill, CBC_ORDER_FIRST)
{
	if (autocvar_g_mayhem)
	{
		entity frag_attacker = M_ARGV(0, entity);
		M_ARGV(2, float) = 0; //score to give for the frag directly

		if (IS_PLAYER(frag_attacker)) FFAMayhemCalculatePlayerScore(frag_attacker);

		return true;
	}
}
