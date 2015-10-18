#ifdef IMPLEMENTATION
REGISTER_MUTATOR(rocketflying, cvar("g_rocket_flying"));

MUTATOR_HOOKFUNCTION(rocketflying, EditProjectile)
{
	if(other.classname == "rocket" || other.classname == "mine")
	{
		// kill detonate delay of rockets
		other.spawnshieldtime = time;
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
