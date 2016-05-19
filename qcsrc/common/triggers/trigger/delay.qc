#ifdef SVQC
void delay_use(entity this, entity actor, entity trigger)
{
   this.think = SUB_UseTargets_self;
   this.nextthink = this.wait;
}

void delay_reset(entity this)
{
	this.think = func_null;
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
