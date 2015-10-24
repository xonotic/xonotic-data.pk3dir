#ifdef IMPLEMENTATION
REGISTER_MUTATOR(vampire, cvar("g_vampire") && !cvar("g_instagib"));

MUTATOR_HOOKFUNCTION(vampire, PlayerDamage_SplitHealthArmor)
{
	if(time >= frag_target.spawnshieldtime)
	if(frag_target != frag_attacker)
	if(frag_target.deadflag == DEAD_NO)
	{
		frag_attacker.health += bound(0, damage_take, frag_target.health);
		frag_attacker.health = bound(0, frag_attacker.health, autocvar_g_balance_health_limit);
	}

	return false;
}

MUTATOR_HOOKFUNCTION(vampire, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":Vampire");
	return 0;
}

MUTATOR_HOOKFUNCTION(vampire, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Vampire");
	return 0;
}
#endif
