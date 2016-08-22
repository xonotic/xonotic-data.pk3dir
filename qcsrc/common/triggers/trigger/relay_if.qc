#include "relay_if.qh"
#ifdef SVQC
void trigger_relay_if_use(entity this, entity actor, entity trigger)
{
	int n = this.count;

	// TODO make this generic AND faster than nextent()ing through all, if somehow possible
	n = (cvar_string(this.netname) == cvar_string(this.message));
	if(this.spawnflags & 1)
		n = !n;

	if(n)
		SUB_UseTargets(this, actor, trigger);
}

spawnfunc(trigger_relay_if)
{
	this.use = trigger_relay_if_use;
}
#endif
