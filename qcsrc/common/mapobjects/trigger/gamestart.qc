#include "gamestart.qh"

#ifdef SVQC
void gamestart_think(entity this)
{
	if (this.wait && !getthink(this))
	{
		setthink(this, gamestart_think);
		this.nextthink = time + this.wait;
	}
	else
		SUB_UseTargets(this, world, this);
}

spawnfunc(trigger_gamestart)
{
	this.reset2 = spawnfunc_trigger_gamestart;
	setthink(this, func_null);
	InitializeEntity(this, gamestart_think, INITPRIO_LAST);
}

/*QUAKED trigger_always (.5 .5 .5) (-8 -8 -8) (8 8 8)
This trigger will always fire.  It is activated by the world.
*/
spawnfunc(trigger_always)
{
	// Q3: we must have some delay to make sure our use targets are present
	this.wait = 0.3;
	spawnfunc_trigger_gamestart(this);
}
#endif
