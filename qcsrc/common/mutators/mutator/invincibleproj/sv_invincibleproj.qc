#include "sv_invincibleproj.qh"

string autocvar_g_invincible_projectiles;
REGISTER_MUTATOR(invincibleprojectiles, expr_evaluate(autocvar_g_invincible_projectiles));

MUTATOR_HOOKFUNCTION(invincibleprojectiles, EditProjectile)
{
	entity proj = M_ARGV(1, entity);

	if(GetResource(proj, RES_HEALTH))
	{
		// disable health which in effect disables damage calculations
		SetResourceExplicit(proj, RES_HEALTH, 0);
	}
}

MUTATOR_HOOKFUNCTION(invincibleprojectiles, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":InvincibleProjectiles");
}

MUTATOR_HOOKFUNCTION(invincibleprojectiles, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Invincible Projectiles");
}
