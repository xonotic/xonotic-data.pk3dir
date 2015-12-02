#ifdef SVQC
void trigger_disablerelay_use()
{SELFPARAM();
	entity e;

	float a, b;
	a = b = 0;

	for(e = world; (e = find(e, targetname, self.target)); )
	{
		if(e.use == SUB_UseTargets)
		{
			e.use = SUB_DontUseTargets;
			++a;
		}
		else if(e.use == SUB_DontUseTargets)
		{
			e.use = SUB_UseTargets;
			++b;
		}
	}

	if((!a) == (!b))
		LOG_INFO("Invalid use of trigger_disablerelay: ", ftos(a), " relays were on, ", ftos(b), " relays were off!\n");
}

spawnfunc(trigger_disablerelay)
{
	self.use = trigger_disablerelay_use;
}
#endif
