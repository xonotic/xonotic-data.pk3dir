#ifdef SVQC
/*QUAKED spawnfunc_trigger_monoflop (.5 .5 .5) (-8 -8 -8) (8 8 8)
"Mono-flop" trigger gate... turns one trigger event into one "on" and one "off" event, separated by a delay of "wait"
*/
void monoflop_use()
{SELFPARAM();
	self.nextthink = time + self.wait;
	self.enemy = activator;
	if(self.state)
		return;
	self.state = 1;
	SUB_UseTargets();
}
void monoflop_fixed_use()
{SELFPARAM();
	if(self.state)
		return;
	self.nextthink = time + self.wait;
	self.state = 1;
	self.enemy = activator;
	SUB_UseTargets();
}

void monoflop_think()
{SELFPARAM();
	self.state = 0;
	activator = self.enemy;
	SUB_UseTargets();
}

void monoflop_reset()
{SELFPARAM();
	self.state = 0;
	self.nextthink = 0;
}

void spawnfunc_trigger_monoflop()
{SELFPARAM();
	if(!self.wait)
		self.wait = 1;
	if(self.spawnflags & 1)
		self.use = monoflop_fixed_use;
	else
		self.use = monoflop_use;
	self.think = monoflop_think;
	self.state = 0;
	self.reset = monoflop_reset;
}
#endif
