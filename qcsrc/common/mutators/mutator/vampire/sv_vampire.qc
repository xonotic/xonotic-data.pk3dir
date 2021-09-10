#include "sv_vampire.qh"

string autocvar_g_vampire;
float autocvar_g_vampire_factor = 1.0;
bool autocvar_g_vampire_use_total_damage = false;

REGISTER_MUTATOR(vampire, expr_evaluate(autocvar_g_vampire) && !MUTATOR_IS_ENABLED(mutator_instagib));

MUTATOR_HOOKFUNCTION(vampire, PlayerDamage_SplitHealthArmor)
{
	// NOTE: vampire buff PlayerDamage_SplitHealthArmor code is similar
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float health_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
	float armor_take = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));
	float damage_take = (autocvar_g_vampire_use_total_damage) ? health_take + armor_take : health_take;

	if (!StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && frag_target != frag_attacker
		&& IS_PLAYER(frag_attacker) && !IS_DEAD(frag_target) && !STAT(FROZEN, frag_target))
	{
		GiveResource(frag_attacker, RES_HEALTH, autocvar_g_vampire_factor * damage_take);
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
