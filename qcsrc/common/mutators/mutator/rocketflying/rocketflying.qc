#ifdef IMPLEMENTATION
REGISTER_MUTATOR(rocketflying, cvar("g_rocket_flying"));

MUTATOR_HOOKFUNCTION(rocketflying, EditProjectile)
{
	entity proj = M_ARGV(1, entity);

	if(proj.classname == "rocket" || proj.classname == "mine")
	{
		// kill detonate delay of rockets
		proj.spawnshieldtime = time;
	}
	return 0;
}

MUTATOR_HOOKFUNCTION(rocketflying, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":RocketFlying");
	return 0;
}

MUTATOR_HOOKFUNCTION(rocketflying, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Rocket Flying");
	return 0;
}
#endif
