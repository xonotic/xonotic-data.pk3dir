#include "flipflop.qh"

#ifdef SVQC
/*QUAKED spawnfunc_trigger_flipflop (.5 .5 .5) (-8 -8 -8) (8 8 8) START_ENABLED
"Flip-flop" trigger gate... lets only every second trigger event through
*/
void flipflop_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

    this.state = !this.state;
    if(this.state)
        SUB_UseTargets(this, actor, trigger);
}

spawnfunc(trigger_flipflop)
{
	this.active = ACTIVE_ACTIVE;
    this.state = (this.spawnflags & START_ENABLED);
    this.use = flipflop_use;
    this.reset = spawnfunc_trigger_flipflop; // perfect resetter
}
#endif
