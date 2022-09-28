#include "relay.qh"
#ifdef SVQC

void relay_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	SUB_UseTargets(this, actor, trigger);
}

/*QUAKED spawnfunc_trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
spawnfunc(trigger_relay)
{
	this.active = ACTIVE_ACTIVE;
	this.use = relay_use;
	this.reset = spawnfunc_trigger_relay; // this spawnfunc resets fully
}

spawnfunc(target_relay)
{
	spawnfunc_trigger_relay(this);
}

spawnfunc(target_delay)
{
	if(!this.wait)
		this.wait = 1;
	if(!this.delay)
		this.delay = this.wait; // fall back to quake 3 field
	spawnfunc_trigger_relay(this);
}
#endif
