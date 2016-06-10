#ifdef IMPLEMENTATION
REGISTER_MUTATOR(bloodloss, cvar("g_bloodloss"));

.float bloodloss_timer;

MUTATOR_HOOKFUNCTION(bloodloss, PlayerPreThink)
{SELFPARAM();
	if(IS_PLAYER(self))
	if(self.health <= autocvar_g_bloodloss && !IS_DEAD(self))
	{
		PHYS_INPUT_BUTTON_CROUCH(self) = true;

		if(time >= self.bloodloss_timer)
		{
			if(self.vehicle)
				vehicles_exit(VHEF_RELEASE);
			if(self.event_damage)
				self.event_damage(self, self, self, 1, DEATH_ROT.m_id, self.origin, '0 0 0');
			self.bloodloss_timer = time + 0.5 + random() * 0.5;
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(bloodloss, PlayerJump)
{
	entity player = M_ARGV(0, entity);

	if(player.health <= autocvar_g_bloodloss)
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(bloodloss, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":bloodloss");
}

MUTATOR_HOOKFUNCTION(bloodloss, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Blood loss");
}
#endif
