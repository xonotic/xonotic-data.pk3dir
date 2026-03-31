#ifdef SVQC
void trigger_always_think(entity this)
{
	SUB_UseTargets(this, world, this);
}

/*QUAKED trigger_always (.5 .5 .5) (-8 -8 -8) (8 8 8)
This trigger will always fire.  It is activated by the world.
*/
spawnfunc(trigger_always)
{
	// Q3: we must have some delay to make sure our use targets are present
	this.nextthink = time + 0.3;
	setthink(this, trigger_always_think);
	this.reset = spawnfunc_trigger_always;
}
#endif
