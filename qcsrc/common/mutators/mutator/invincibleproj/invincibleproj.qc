#ifdef IMPLEMENTATION
REGISTER_MUTATOR(invincibleprojectiles, cvar("g_invincible_projectiles"));

MUTATOR_HOOKFUNCTION(invincibleprojectiles, EditProjectile)
{
	entity proj = M_ARGV(1, entity);

	if(proj.health)
	{
		// disable health which in effect disables damage calculations
		proj.health = 0;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(invincibleprojectiles, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":InvincibleProjectiles");
	return false;
}

MUTATOR_HOOKFUNCTION(invincibleprojectiles, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Invincible Projectiles");
	return false;
}
#endif
