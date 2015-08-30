REGISTER_MUTATOR(rm, cvar("g_instagib"));

MUTATOR_HOOKFUNCTION(rm, PlayerDamage_Calculate)
{
	// we do it this way, so rm can be toggled during the match
	if(!autocvar_g_rm) { return false; }

	if(autocvar_g_rm)
	if(DEATH_ISWEAPON(frag_deathtype, WEP_DEVASTATOR.m_id))
	if(frag_attacker == frag_target || frag_target.classname == "nade")
		frag_damage = 0;

	if(autocvar_g_rm && autocvar_g_rm_laser == 1) //|| autocvar_g_rm_laser == 2)
	if(DEATH_ISWEAPON(frag_deathtype, WEP_ELECTRO.m_id))
	if(frag_attacker == frag_target || (round_handler_IsActive() && !round_handler_IsRoundStarted()))
		frag_damage = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(rm, PlayerDies)
{	
	if(	/*(DEATH_ISWEAPON(frag_deathtype, WEP_VAPORIZER))*/
		(autocvar_g_rm && DEATH_ISWEAPON(frag_deathtype, WEP_DEVASTATOR.m_id))
	|| 	(((autocvar_g_rm && autocvar_g_rm_laser == 1) || autocvar_g_rm_laser == 2) && DEATH_ISWEAPON(frag_deathtype, WEP_ELECTRO.m_id))
	)
		frag_damage = 1000; // always gib if it was a vaporizer death

	//(get_weaponinfo(WEP_VAPORIZER)).weaponthrowable = 1; // throwing is forbidden by a mutator hook, enabling this for drop on death

	return false;
}

