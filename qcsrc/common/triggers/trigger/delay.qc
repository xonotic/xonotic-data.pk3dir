#ifdef SVQC
void delay_use()
{SELFPARAM();
    self.think = SUB_UseTargets;
   self.nextthink = self.wait;
}

void delay_reset()
{SELFPARAM();
	self.think = func_null;
	self.nextthink = 0;
}

spawnfunc(trigger_delay)
{
    if(!self.wait)
        self.wait = 1;

    self.use = delay_use;
    self.reset = delay_reset;
}
#endif
