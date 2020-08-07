#include "delay.qh"

#ifdef SVQC
void delay_delayeduse(entity this)
{
	SUB_UseTargets(this, this.enemy, this.goalentity);
	this.enemy = this.goalentity = NULL;
}

void delay_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	this.enemy = actor;
	this.goalentity = trigger;
	setthink(this, delay_delayeduse);
	this.nextthink = time + this.wait;
}

void delay_reset(entity this)
{
	this.enemy = this.goalentity = NULL;
	setthink(this, func_null);
	this.nextthink = 0;
	this.active = ACTIVE_ACTIVE;
}

spawnfunc(trigger_delay)
{
    if(!this.wait)
        this.wait = 1;

    this.use = delay_use;
    this.reset = delay_reset;
    this.active = ACTIVE_ACTIVE;
}
#endif
