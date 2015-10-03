#ifdef SVQC
void trigger_relay_if_use()
{SELFPARAM();
	float n;
	n = self.count;

	// TODO make this generic AND faster than nextent()ing through all, if somehow possible
	n = (cvar_string(self.netname) == cvar_string(self.message));
	if(self.spawnflags & 1)
		n = !n;

	if(n)
		SUB_UseTargets();
}

spawnfunc(trigger_relay_if)
{
	self.use = trigger_relay_if_use;
}
#endif
