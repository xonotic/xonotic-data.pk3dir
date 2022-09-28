#include "multivibrator.qh"
#ifdef SVQC
void multivibrator_send(entity this)
{
	float newstate;
	float cyclestart;

	cyclestart = floor((time + this.phase) / (this.wait + this.respawntime)) * (this.wait + this.respawntime) - this.phase;

	newstate = (time < cyclestart + this.wait);

	if(this.state != newstate)
		SUB_UseTargets(this, this, NULL);
	this.state = newstate;

	if(this.state)
		this.nextthink = cyclestart + this.wait + 0.01;
	else
		this.nextthink = cyclestart + this.wait + this.respawntime + 0.01;
}

void multivibrator_send_think(entity this)
{
	multivibrator_send(this);
}

void multivibrator_toggle(entity this, entity actor, entity trigger)
{
	if(this.nextthink == 0)
	{
		multivibrator_send(this);
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

void multivibrator_reset(entity this)
{
	if(!(this.spawnflags & START_ENABLED))
		this.nextthink = 0; // wait for a trigger event
	else
		this.nextthink = max(1, time);
}

/*QUAKED trigger_multivibrator (.5 .5 .5) (-8 -8 -8) (8 8 8) START_ENABLED
"Multivibrator" trigger gate... repeatedly sends trigger events. When triggered, turns on or off.
-------- KEYS --------
target: trigger all entities with this targetname when it goes off
targetname: name that identifies this entity so it can be triggered; when off, it always uses the OFF state
phase: offset of the timing
wait: "on" cycle time (default: 1)
respawntime: "off" cycle time (default: same as wait)
-------- SPAWNFLAGS --------
START_ENABLED: assume it is already turned on (when targeted)
*/
spawnfunc(trigger_multivibrator)
{
	if(!this.wait)
		this.wait = 1;
	if(!this.respawntime)
		this.respawntime = this.wait;

	this.state = 0;
	this.use = multivibrator_toggle;
	setthink(this, multivibrator_send_think);
	this.nextthink = max(1, time);

	if(this.targetname && this.targetname != "")
		multivibrator_reset(this);
}
#endif
