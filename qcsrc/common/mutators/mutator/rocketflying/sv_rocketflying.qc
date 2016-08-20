#include "sv_rocketflying.qh"

REGISTER_MUTATOR(rocketflying, cvar("g_rocket_flying"));

MUTATOR_HOOKFUNCTION(rocketflying, EditProjectile)
{
	entity proj = M_ARGV(1, entity);

	if(proj.classname == "rocket" || proj.classname == "mine")
	{
		// kill detonate delay of rockets
		proj.spawnshieldtime = time;
	}
}

MUTATOR_HOOKFUNCTION(rocketflying, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":RocketFlying");
}

MUTATOR_HOOKFUNCTION(rocketflying, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Rocket Flying");
}
