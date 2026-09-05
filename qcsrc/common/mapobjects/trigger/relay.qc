#include "relay.qh"
#ifdef SVQC

void relay_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;
	if(this.team && this.team != actor.team)
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
	// Q3 spawnflags
	if (this.spawnflags & 1)
		this.team = NUM_TEAM_1;
	if (this.spawnflags & 2)
		this.team = NUM_TEAM_2;
	if (this.spawnflags & 4)
		this.target_random = true;
	spawnfunc_trigger_relay(this);
}
#endif
