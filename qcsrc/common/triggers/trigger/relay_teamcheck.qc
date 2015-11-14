#ifdef SVQC
void trigger_relay_teamcheck_use()
{SELFPARAM();
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

void trigger_relay_teamcheck_reset(entity this)
{
	this.team = this.team_saved;
}

spawnfunc(trigger_relay_teamcheck)
{
	this.team_saved = this.team;
	this.use = trigger_relay_teamcheck_use;
	this.reset = trigger_relay_teamcheck_reset;
}
#endif
