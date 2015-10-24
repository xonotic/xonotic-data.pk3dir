#ifdef IMPLEMENTATION
REGISTER_MUTATOR(invincibleprojectiles, cvar("g_invincible_projectiles"));

MUTATOR_HOOKFUNCTION(invincibleprojectiles, EditProjectile)
{
	if(other.health)
	{
		// disable health which in effect disables damage calculations
		other.health = 0;
	}
	return 0;
}

MUTATOR_HOOKFUNCTION(invincibleprojectiles, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":InvincibleProjectiles");
	return 0;
}

MUTATOR_HOOKFUNCTION(invincibleprojectiles, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Invincible Projectiles");
	return 0;
}
#endif
