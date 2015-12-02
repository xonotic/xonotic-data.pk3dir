#ifdef SVQC
void delay_use()
{SELFPARAM();
    self.think = SUB_UseTargets;
   self.nextthink = self.wait;
}

void delay_reset(entity this)
{
	this.think = func_null;
	this.nextthink = 0;
}

spawnfunc(trigger_delay)
{
    if(!self.wait)
        self.wait = 1;

    self.use = delay_use;
    self.reset = delay_reset;
}
#endif
