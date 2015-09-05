#ifdef SVQC
void gamestart_use()
{SELFPARAM();
	activator = self;
	SUB_UseTargets();
	remove(self);
}

void spawnfunc_trigger_gamestart()
{SELFPARAM();
	self.use = gamestart_use;
	self.reset2 = spawnfunc_trigger_gamestart;

	if(self.wait)
	{
		self.think = self.use;
		self.nextthink = game_starttime + self.wait;
	}
	else
		InitializeEntity(self, gamestart_use, INITPRIO_FINDTARGET);
}
#endif
