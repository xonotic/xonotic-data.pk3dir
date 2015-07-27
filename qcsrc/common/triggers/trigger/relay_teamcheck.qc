#ifdef SVQC
void trigger_relay_teamcheck_use()
{
	if(activator.team)
	{
		if(self.spawnflags & 2)
		{
			if(DIFF_TEAM(activator, self))
				SUB_UseTargets();
		}
		else
		{
			if(SAME_TEAM(activator, self))
				SUB_UseTargets();
		}
	}
	else
	{
		if(self.spawnflags & 1)
			SUB_UseTargets();
	}
}

void trigger_relay_teamcheck_reset()
{
	self.team = self.team_saved;
}

void spawnfunc_trigger_relay_teamcheck()
{
	self.team_saved = self.team;
	self.use = trigger_relay_teamcheck_use;
	self.reset = trigger_relay_teamcheck_reset;
}
#endif
