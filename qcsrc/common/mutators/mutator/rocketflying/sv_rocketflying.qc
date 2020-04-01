#include "sv_rocketflying.qh"

string autocvar_g_rocket_flying;
bool autocvar_g_rocket_flying_disabledelays = true;
REGISTER_MUTATOR(rocketflying, expr_evaluate(autocvar_g_rocket_flying));

MUTATOR_HOOKFUNCTION(rocketflying, EditProjectile)
{
	entity proj = M_ARGV(1, entity);

	if(autocvar_g_rocket_flying_disabledelays && (proj.classname == "rocket" || proj.classname == "mine"))
	{
		// kill detonate delay of rockets
		proj.spawnshieldtime = time;
	}
}

MUTATOR_HOOKFUNCTION(rocketflying, AllowRocketJumping)
{
	M_ARGV(0, bool) = true; // force rocket jumping
}

MUTATOR_HOOKFUNCTION(rocketflying, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":RocketFlying");
}

MUTATOR_HOOKFUNCTION(rocketflying, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Rocket Flying");
}
