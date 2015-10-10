#ifdef SVQC
void _spawnfunc_trigger_relay();
/*QUAKED spawnfunc_trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
spawnfunc(trigger_relay)
{
	self.use = SUB_UseTargets;
	self.reset = _spawnfunc_trigger_relay; // this spawnfunc resets fully
}
void _spawnfunc_trigger_relay() { SELFPARAM(); spawnfunc_trigger_relay(this); }
#endif
