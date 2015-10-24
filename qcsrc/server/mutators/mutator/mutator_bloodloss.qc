#ifdef IMPLEMENTATION
REGISTER_MUTATOR(bloodloss, cvar("g_bloodloss"));

.float bloodloss_timer;

MUTATOR_HOOKFUNCTION(bloodloss, PlayerPreThink)
{SELFPARAM();
	if(IS_PLAYER(self))
	if(self.health <= autocvar_g_bloodloss && self.deadflag == DEAD_NO)
	{
		self.BUTTON_CROUCH = true;

		if(time >= self.bloodloss_timer)
		{
			if(self.vehicle)
				vehicles_exit(VHEF_RELEASE);
			if(self.event_damage)
				self.event_damage(self, self, 1, DEATH_ROT.m_id, self.origin, '0 0 0');
			self.bloodloss_timer = time + 0.5 + random() * 0.5;
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(bloodloss, PlayerJump)
{SELFPARAM();
	if(self.health <= autocvar_g_bloodloss)
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(bloodloss, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":bloodloss");
	return false;
}

MUTATOR_HOOKFUNCTION(bloodloss, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Blood loss");
	return false;
}
#endif
