#include "disablerelay.qh"
#ifdef SVQC
void trigger_disablerelay_use(entity this, entity actor, entity trigger)
{
	int a = 0, b = 0;

	for(entity e = NULL; (e = find(e, targetname, this.target)); )
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
	this.use = trigger_disablerelay_use;
}
#endif
