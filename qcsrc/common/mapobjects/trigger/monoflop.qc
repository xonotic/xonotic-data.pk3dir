#include "monoflop.qh"
#ifdef SVQC
/*QUAKED spawnfunc_trigger_monoflop (.5 .5 .5) (-8 -8 -8) (8 8 8)
"Mono-flop" trigger gate... turns one trigger event into one "on" and one "off" event, separated by a delay of "wait"
*/
void monoflop_use(entity this, entity actor, entity trigger)
{
	this.nextthink = time + this.wait;
	this.enemy = actor;
	if(this.state)
		return;
	this.state = 1;
	SUB_UseTargets(this, actor, trigger);
}
void monoflop_fixed_use(entity this, entity actor, entity trigger)
{
	if(this.state)
		return;
	this.nextthink = time + this.wait;
	this.state = 1;
	this.enemy = actor;
	SUB_UseTargets(this, actor, trigger);
}

void monoflop_think(entity this)
{
	this.state = 0;
	SUB_UseTargets(this, this.enemy, NULL);
}

void monoflop_reset(entity this)
{
	this.state = 0;
	this.nextthink = 0;
}

spawnfunc(trigger_monoflop)
{
	if(!this.wait)
		this.wait = 1;
	if(this.spawnflags & MONOFLOP_FIXED)
		this.use = monoflop_fixed_use;
	else
		this.use = monoflop_use;
	setthink(this, monoflop_think);
	this.state = 0;
	this.reset = monoflop_reset;
}
#endif
