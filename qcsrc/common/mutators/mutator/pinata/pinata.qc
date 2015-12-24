#ifdef IMPLEMENTATION
REGISTER_MUTATOR(pinata, cvar("g_pinata") && !cvar("g_instagib") && !cvar("g_overkill"));

MUTATOR_HOOKFUNCTION(pinata, PlayerDies)
{SELFPARAM();
	FOREACH(Weapons, it != WEP_Null, LAMBDA(
		if(self.weapons & WepSet_FromWeapon(it))
		if(PS(self).m_switchweapon != it)
		if(W_IsWeaponThrowable(it.m_id))
			W_ThrowNewWeapon(self, it.m_id, false, CENTER_OR_VIEWOFS(self), randomvec() * 175 + '0 0 325');
	));

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
