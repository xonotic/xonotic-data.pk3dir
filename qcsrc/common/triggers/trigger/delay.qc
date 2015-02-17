#ifdef SVQC
void delay_use()
{
    self.think = SUB_UseTargets;
   trigger_setnextthink(self, self.wait);
}

void delay_reset()
{
	self.think = func_null;
	self.nextthink = 0;
}

void spawnfunc_trigger_delay()
{
    if(!self.wait)
        self.wait = 1;

    self.use = delay_use;
    self.reset = delay_reset;
}
#endif
