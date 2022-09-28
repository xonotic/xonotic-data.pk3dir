#include "disablerelay.qh"
#ifdef SVQC
void trigger_disablerelay_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	int a = 0, b = 0;

	for(entity e = NULL; (e = find(e, targetname, this.target)); )
	{
		if(e.active == ACTIVE_ACTIVE)
		{
			e.active = ACTIVE_NOT;
			++a;
		}
		else if(e.active == ACTIVE_NOT)
		{
			e.active = ACTIVE_ACTIVE;
			++b;
		}
	}

	if((!a) == (!b))
		LOG_INFO("Invalid use of trigger_disablerelay: ", ftos(a), " relays were on, ", ftos(b), " relays were off!");
}

spawnfunc(trigger_disablerelay)
{
	this.reset = spawnfunc_trigger_disablerelay; // this spawnfunc resets fully
	this.active = ACTIVE_ACTIVE;
	this.use = trigger_disablerelay_use;
}
#endif
