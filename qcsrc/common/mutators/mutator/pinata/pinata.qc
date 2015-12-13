#ifdef IMPLEMENTATION
REGISTER_MUTATOR(pinata, cvar("g_pinata") && !cvar("g_instagib") && !cvar("g_overkill"));

MUTATOR_HOOKFUNCTION(pinata, PlayerDies)
{SELFPARAM();
	for(int j = WEP_FIRST; j <= WEP_LAST; ++j)
	if(self.weapons & WepSet_FromWeapon(Weapons_from(j)))
	if(PS(self).m_switchweapon.m_id != j)
	if(W_IsWeaponThrowable(j))
		W_ThrowNewWeapon(self, j, false, self.origin + (self.mins + self.maxs) * 0.5, randomvec() * 175 + '0 0 325');

	return true;
}

MUTATOR_HOOKFUNCTION(pinata, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":Pinata");
	return false;
}

MUTATOR_HOOKFUNCTION(pinata, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Piñata");
	return false;
}

#endif
