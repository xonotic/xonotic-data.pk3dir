#ifdef SVQC
/*QUAKED spawnfunc_trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
void spawnfunc_trigger_relay()
{SELFPARAM();
	self.use = SUB_UseTargets;
	self.reset = spawnfunc_trigger_relay; // this spawnfunc resets fully
}
#endif
