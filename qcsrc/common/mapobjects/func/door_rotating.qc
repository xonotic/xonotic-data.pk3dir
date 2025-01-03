#include "door_rotating.qh"
/*QUAKED spawnfunc_func_door_rotating (0 .5 .8) ? START_OPEN BIDIR DOOR_DONT_LINK BIDIR_IN_DOWN x TOGGLE X_AXIS Y_AXIS
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

BIDIR makes the door work bidirectional, so that the opening direction is always away from the requestor.
The usage of bidirectional doors requires two manually instantiated triggers (trigger_multiple), the one to open it in the other direction
must have set trigger_reverse to 1.
BIDIR_IN_DOWN will the door prevent from reopening while closing if it is triggered from the other side.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not usefull for touch or takedamage doors).

"message"	is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"		determines the destination angle for opening. negative values reverse the direction.
"targetname"    if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"	if set, door must be shot open
"speed"		movement speed (100 default)
"wait"		wait before returning (3 default, -1 = never return)
"dmg"		damage to inflict when blocked (2 default)
"sounds"
0)	no sound
1)	stone
2)	base
3)	stone chain
4)	screechy metal
FIXME: only one sound set available at the time being
*/

#ifdef GAMEQC
void door_rotating_hit_top(entity this)
{
	if (this.noise1 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	this.state = STATE_TOP;
	if (this.spawnflags & DOOR_TOGGLE)
		return;		// don't come down automatically
	setthink(this, door_rotating_go_down);
	this.nextthink = this.ltime + this.wait;
}

void door_rotating_hit_bottom(entity this)
{
	if (this.noise1 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	if (this.lip==666) // this.lip is used to remember reverse opening direction for door_rotating
	{
		this.pos2 = '0 0 0' - this.pos2;
		this.lip = 0;
	}
	this.state = STATE_BOTTOM;
}

void door_rotating_go_down(entity this)
{
	if (this.noise2 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
	if (this.max_health)
	{
		this.takedamage = DAMAGE_YES;
		SetResourceExplicit(this, RES_HEALTH, this.max_health);
	}

	this.state = STATE_DOWN;
	SUB_CalcAngleMove (this, this.pos1, TSPEED_LINEAR, this.speed, door_rotating_hit_bottom);
}

void door_rotating_go_up(entity this, entity oth)
{
	if (this.state == STATE_UP)
		return;		// already going up

	if (this.state == STATE_TOP)
	{	// reset top wait time
		this.nextthink = this.ltime + this.wait;
		return;
	}
	if (this.noise2 != "")
		_sound (this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
	this.state = STATE_UP;
	SUB_CalcAngleMove (this, this.pos2, TSPEED_LINEAR, this.speed, door_rotating_hit_top);

	string oldmessage;
	oldmessage = this.message;
	this.message = "";
	SUB_UseTargets(this, NULL, oth); // TODO: is oth needed here?
	this.message = oldmessage;
}
#endif

#ifdef SVQC
void door_rotating_reset(entity this)
{
	this.angles = this.pos1;
	this.avelocity = '0 0 0';
	this.state = STATE_BOTTOM;
	setthink(this, func_null);
	this.nextthink = 0;
}

void door_rotating_init_startopen(entity this)
{
	this.angles = this.movedir;
	this.pos2 = '0 0 0';
	this.pos1 = this.movedir;
}

spawnfunc(func_door_rotating)
{
	//if (!this.deathtype) // map makers can override this
	//	this.deathtype = " got in the way";

	// I abuse "movedir" for denoting the axis for now
	if (this.spawnflags & DOOR_ROTATING_XAXIS)
		this.movedir = '0 0 1';
	else if (this.spawnflags & DOOR_ROTATING_YAXIS)
		this.movedir = '1 0 0';
	else // Z
		this.movedir = '0 1 0';

	if (this.angles_y==0) this.angles_y = 90;

	this.movedir = this.movedir * this.angles_y;
	this.angles = '0 0 0';

	this.avelocity = this.movedir;
	if (!InitMovingBrushTrigger(this))
		return;
	this.velocity = '0 0 0';
	//this.effects |= EF_LOWPRECISION;
	this.classname = "door_rotating";

	setblocked(this, door_blocked);
	this.use = door_use;
	this.active = ACTIVE_ACTIVE;

	this.pos1 = '0 0 0';
	this.pos2 = this.movedir;

// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
// but spawn in the open position
	if (this.spawnflags & DOOR_START_OPEN)
		InitializeEntity(this, door_rotating_init_startopen, INITPRIO_SETLOCATION);

	door_init_shared(this);
	if (!this.speed)
	{
		this.speed = 50;
	}
	this.lip = 0; // this.lip is used to remember reverse opening direction for door_rotating

	settouch(this, door_touch);

// LinkDoors can't be done until all of the doors have been spawned, so
// the sizes can be detected properly.
	InitializeEntity(this, LinkDoors, INITPRIO_LINKDOORS);

	this.reset = door_rotating_reset;
}
#endif
