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
#endif
