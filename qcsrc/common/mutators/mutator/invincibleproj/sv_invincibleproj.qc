#include "sv_invincibleproj.qh"

REGISTER_MUTATOR(invincibleprojectiles, cvar("g_invincible_projectiles"));

MUTATOR_HOOKFUNCTION(invincibleprojectiles, EditProjectile)
{
	entity proj = M_ARGV(1, entity);

	if(proj.health)
	{
		// disable health which in effect disables damage calculations
		proj.health = 0;
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
