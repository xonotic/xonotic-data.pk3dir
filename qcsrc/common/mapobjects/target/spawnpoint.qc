#include "spawnpoint.qh"

#ifdef SVQC
void target_spawnpoint_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	actor.spawnpoint_targ = this;
}

void target_spawnpoint_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
}

// TODO: persistent spawnflag?
spawnfunc(target_spawnpoint)
{
	this.active = ACTIVE_ACTIVE;
	this.use = target_spawnpoint_use;
	this.reset = target_spawnpoint_reset;
}
#endif
