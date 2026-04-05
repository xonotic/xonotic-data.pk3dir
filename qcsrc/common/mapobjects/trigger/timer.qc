#ifdef SVQC
void trigger_timer_think(entity this)
{
	SUB_UseTargets(this, this.enemy, this.goalentity);
	this.nextthink = time + this.wait + crandom() * this.rnd;
}

void trigger_timer_use(entity this, entity actor, entity trigger)
{
	this.enemy = actor;
	this.goalentity = trigger;

	if (this.nextthink)
		this.nextthink = 0;
	else
		trigger_timer_think(this);
}

void trigger_timer_reset(entity this)
{
	this.enemy = world;
	this.goalentity = this;
	if (this.spawnflags & 1)
		this.nextthink = time + FRAMETIME_Q3;
}

/*QUAKED func_timer (0.3 0.1 0.6) (-8 -8 -8) (8 8 8) START_ON
This should be renamed trigger_timer...
Repeatedly fires its targets.
Can be turned on or off by using.

"wait"			base time between triggering all targets, default is 1
"random"		wait variance, default is 1 // NB: documented wrong in Q3!
so, the basic time between firing is a random time between
(wait - random) and (wait + random)

*/
spawnfunc(trigger_timer)
{
	G_SpawnFloat("random", 1, this, rnd);
	G_SpawnFloat("wait", 1, this, wait);
	if (this.rnd >= this.wait)
	{
		this.rnd = this.wait - FRAMETIME_Q3;
		LOG_WARNF("func_timer at %s has random >= wait\n", vtos(this.origin));
	}

	this.use = trigger_timer_use;
	setthink(this, trigger_timer_think);
	this.reset = trigger_timer_reset;

	trigger_timer_reset(this);
}
spawnfunc(func_timer)
{
	spawnfunc_trigger_timer(this);
}
#endif
