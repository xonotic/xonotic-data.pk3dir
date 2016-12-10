#include "sv_vampire.qh"

REGISTER_MUTATOR(vampire, cvar("g_vampire") && !cvar("g_instagib"));

MUTATOR_HOOKFUNCTION(vampire, PlayerDamage_SplitHealthArmor)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float damage_take = M_ARGV(4, float);

	if(time >= frag_target.spawnshieldtime)
	if(frag_target != frag_attacker)
	if(!IS_DEAD(frag_target))
	{
		frag_attacker.health += bound(0, damage_take, frag_target.health);
		frag_attacker.health = bound(0, frag_attacker.health, autocvar_g_balance_health_limit);
	}
}

MUTATOR_HOOKFUNCTION(vampire, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":Vampire");
}

MUTATOR_HOOKFUNCTION(vampire, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Vampire");
}
