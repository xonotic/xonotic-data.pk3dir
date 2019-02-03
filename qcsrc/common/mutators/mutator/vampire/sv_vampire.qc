#include "sv_vampire.qh"

string autocvar_g_vampire;
REGISTER_MUTATOR(vampire, expr_evaluate(autocvar_g_vampire) && !MUTATOR_IS_ENABLED(mutator_instagib));

MUTATOR_HOOKFUNCTION(vampire, PlayerDamage_SplitHealthArmor)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float damage_take = M_ARGV(4, float);

	if(time >= frag_target.spawnshieldtime)
	if(frag_target != frag_attacker)
	if(!IS_DEAD(frag_target))
	{
		GiveResource(frag_attacker, RES_HEALTH,
			bound(0, damage_take, GetResource(frag_target, RES_HEALTH)));
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
