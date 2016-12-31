#include "door_rotating.qh"
#ifdef SVQC
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
	if (this.spawnflags & 64) // X (untested)
		this.movedir = '0 0 1';
	else if (this.spawnflags & 128) // Y (untested)
		this.movedir = '1 0 0';
	else // Z
		this.movedir = '0 1 0';

	if (this.angles_y==0) this.angles_y = 90;

	this.movedir = this.movedir * this.angles_y;
	this.angles = '0 0 0';

	this.max_health = this.health;
	this.avelocity = this.movedir;
	if (!InitMovingBrushTrigger(this))
		return;
	this.velocity = '0 0 0';
	//this.effects |= EF_LOWPRECISION;
	this.classname = "door_rotating";

	setblocked(this, door_blocked);
	this.use = door_use;

    if(this.spawnflags & 8)
        this.dmg = 10000;

    if(this.dmg && (this.message == ""))
		this.message = "was squished";
    if(this.dmg && (this.message2 == ""))
		this.message2 = "was squished by";

    if (this.sounds > 0)
	{
		precache_sound ("plats/medplat1.wav");
		precache_sound ("plats/medplat2.wav");
		this.noise2 = "plats/medplat1.wav";
		this.noise1 = "plats/medplat2.wav";
	}

	if (!this.speed)
		this.speed = 50;
	if (!this.wait)
		this.wait = 1;
	this.lip = 0; // this.lip is used to remember reverse opening direction for door_rotating

	this.pos1 = '0 0 0';
	this.pos2 = this.movedir;

// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
// but spawn in the open position
	if (this.spawnflags & DOOR_START_OPEN)
		InitializeEntity(this, door_rotating_init_startopen, INITPRIO_SETLOCATION);

	this.state = STATE_BOTTOM;

	if (this.health)
	{
		this.takedamage = DAMAGE_YES;
		this.event_damage = door_damage;
	}

	if (this.items)
		this.wait = -1;

	settouch(this, door_touch);

// LinkDoors can't be done until all of the doors have been spawned, so
// the sizes can be detected properly.
	InitializeEntity(this, LinkDoors, INITPRIO_LINKDOORS);

	this.reset = door_rotating_reset;
}
#endif
