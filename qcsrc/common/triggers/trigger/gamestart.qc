#ifdef SVQC
void gamestart_use(entity this)
{
	activator = self;
	SUB_UseTargets();
	remove(self);
}

void self_spawnfunc_trigger_gamestart();
spawnfunc(trigger_gamestart)
{
	setuse(this, gamestart_use);
	this.reset2 = self_spawnfunc_trigger_gamestart;

	if(this.wait)
	{
		this.think = this.use;
		this.nextthink = game_starttime + this.wait;
	}
	else
		InitializeEntity(this, gamestart_use, INITPRIO_FINDTARGET);
}
void self_spawnfunc_trigger_gamestart() { SELFPARAM(); spawnfunc_trigger_gamestart(this); }

#endif
