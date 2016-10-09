#include "delay.qh"
#ifdef SVQC
void delay_use(entity this, entity actor, entity trigger)
{
   setthink(this, SUB_UseTargets_self);
   this.nextthink = time + this.wait;
}

void delay_reset(entity this)
{
	setthink(this, func_null);
	this.nextthink = 0;
}

spawnfunc(trigger_delay)
{
    if(!this.wait)
        this.wait = 1;

    this.use = delay_use;
    this.reset = delay_reset;
}
#endif
