#include "gamestart.qh"
#ifdef SVQC
void gamestart_use(entity this, entity actor, entity trigger)
{
	SUB_UseTargets(this, this, trigger);
	delete(this);
}

void gamestart_use_this(entity this)
{
	gamestart_use(this, NULL, NULL);
}

spawnfunc(trigger_gamestart)
{
	this.use = gamestart_use;
	this.reset2 = spawnfunc_trigger_gamestart;

	if(this.wait)
	{
		setthink(this, adaptor_think2use);
		this.nextthink = game_starttime + this.wait;
	}
	else
		InitializeEntity(this, gamestart_use_this, INITPRIO_FINDTARGET);
}

#endif
