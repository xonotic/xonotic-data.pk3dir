#ifdef SVQC
void multivibrator_send()
{SELFPARAM();
	float newstate;
	float cyclestart;

	cyclestart = floor((time + self.phase) / (self.wait + self.respawntime)) * (self.wait + self.respawntime) - self.phase;

	newstate = (time < cyclestart + self.wait);

	if(self.state != newstate)
		SUB_UseTargets(self, self, NULL);
	self.state = newstate;

	if(self.state)
		self.nextthink = cyclestart + self.wait + 0.01;
	else
		self.nextthink = cyclestart + self.wait + self.respawntime + 0.01;
}

void multivibrator_toggle(entity this, entity actor, entity trigger)
{
	if(this.nextthink == 0)
	{
		WITHSELF(this, multivibrator_send());
	}
	else
	{
		if(this.state)
		{
			SUB_UseTargets(this, actor, trigger);
			this.state = 0;
		}
		this.nextthink = 0;
	}
}

void multivibrator_reset()
{SELFPARAM();
	if(!(self.spawnflags & 1))
		self.nextthink = 0; // wait for a trigger event
	else
		self.nextthink = max(1, time);
}

/*QUAKED trigger_multivibrator (.5 .5 .5) (-8 -8 -8) (8 8 8) START_ON
"Multivibrator" trigger gate... repeatedly sends trigger events. When triggered, turns on or off.
-------- KEYS --------
target: trigger all entities with this targetname when it goes off
targetname: name that identifies this entity so it can be triggered; when off, it always uses the OFF state
phase: offset of the timing
wait: "on" cycle time (default: 1)
respawntime: "off" cycle time (default: same as wait)
-------- SPAWNFLAGS --------
START_ON: assume it is already turned on (when targeted)
*/
spawnfunc(trigger_multivibrator)
{
	if(!self.wait)
		self.wait = 1;
	if(!self.respawntime)
		self.respawntime = self.wait;

	self.state = 0;
	self.use = multivibrator_toggle;
	self.think = multivibrator_send;
	self.nextthink = max(1, time);

	IFTARGETED
		multivibrator_reset();
}
#endif
