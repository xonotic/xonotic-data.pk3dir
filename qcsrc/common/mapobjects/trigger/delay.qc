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
	this.nextthink = time + this.wait + this.rnd * crandom();
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
	G_SpawnFloat("random", 0, this, rnd);
	if(!this.wait)
		this.wait = 1;

	this.use = delay_use;
	this.reset = delay_reset;
	this.active = ACTIVE_ACTIVE;
}

/*QUAKED target_delay (1 0 0) (-8 -8 -8) (8 8 8)
"wait" seconds to pause before firing targets.
"random" delay variance, total delay = delay +/- random seconds
*/
spawnfunc(target_delay)
{
	// Q3: check delay for backwards compatability
	if (this.delay)
	{
		this.wait = this.delay;
		this.delay = 0; // don't spawn delay entities in SUB_UseTargets() as well
	}
	spawnfunc_trigger_delay(this);
}
#endif
