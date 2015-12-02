#ifdef IMPLEMENTATION

float autocvar_g_midair_shieldtime;

REGISTER_MUTATOR(midair, cvar("g_midair"));

.float midair_shieldtime;

MUTATOR_HOOKFUNCTION(midair, PlayerDamage_Calculate)
{SELFPARAM();
	if(IS_PLAYER(frag_attacker))
	if(IS_PLAYER(frag_target))
	if(time < self.midair_shieldtime)
		frag_damage = false;

	return false;
}

MUTATOR_HOOKFUNCTION(midair, PlayerPowerups)
{SELFPARAM();
	if(time >= game_starttime)
	if(self.flags & FL_ONGROUND)
	{
		self.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
		self.midair_shieldtime = max(self.midair_shieldtime, time + autocvar_g_midair_shieldtime);
	}

	return false;
}

MUTATOR_HOOKFUNCTION(midair, PlayerSpawn)
{SELFPARAM();
	if(IS_BOT_CLIENT(self))
		self.bot_moveskill = 0; // disable bunnyhopping

	return false;
}

MUTATOR_HOOKFUNCTION(midair, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":midair");
	return false;
}

MUTATOR_HOOKFUNCTION(midair, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Midair");
	return false;
}
#endif
