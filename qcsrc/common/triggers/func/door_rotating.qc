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

void door_rotating_reset()
{SELFPARAM();
	self.angles = self.pos1;
	self.avelocity = '0 0 0';
	self.state = STATE_BOTTOM;
	self.think = func_null;
	self.nextthink = 0;
}

void door_rotating_init_startopen()
{SELFPARAM();
	self.angles = self.movedir;
	self.pos2 = '0 0 0';
	self.pos1 = self.movedir;
}


void spawnfunc_func_door_rotating()
{SELFPARAM();

	//if (!self.deathtype) // map makers can override this
	//	self.deathtype = " got in the way";

	// I abuse "movedir" for denoting the axis for now
	if (self.spawnflags & 64) // X (untested)
		self.movedir = '0 0 1';
	else if (self.spawnflags & 128) // Y (untested)
		self.movedir = '1 0 0';
	else // Z
		self.movedir = '0 1 0';

	if (self.angles_y==0) self.angles_y = 90;

	self.movedir = self.movedir * self.angles_y;
	self.angles = '0 0 0';

	self.max_health = self.health;
	self.avelocity = self.movedir;
	if (!InitMovingBrushTrigger())
		return;
	self.velocity = '0 0 0';
	//self.effects |= EF_LOWPRECISION;
	self.classname = "door_rotating";

	self.blocked = door_blocked;
	self.use = door_use;

    if(self.spawnflags & 8)
        self.dmg = 10000;

    if(self.dmg && (self.message == ""))
		self.message = "was squished";
    if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";

    if (self.sounds > 0)
	{
		precache_sound ("plats/medplat1.wav");
		precache_sound ("plats/medplat2.wav");
		self.noise2 = "plats/medplat1.wav";
		self.noise1 = "plats/medplat2.wav";
	}

	if (!self.speed)
		self.speed = 50;
	if (!self.wait)
		self.wait = 1;
	self.lip = 0; // self.lip is used to remember reverse opening direction for door_rotating

	self.pos1 = '0 0 0';
	self.pos2 = self.movedir;

// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
// but spawn in the open position
	if (self.spawnflags & DOOR_START_OPEN)
		InitializeEntity(self, door_rotating_init_startopen, INITPRIO_SETLOCATION);

	self.state = STATE_BOTTOM;

	if (self.health)
	{
		self.takedamage = DAMAGE_YES;
		self.event_damage = door_damage;
	}

	if (self.items)
		self.wait = -1;

	self.touch = door_touch;

// LinkDoors can't be done until all of the doors have been spawned, so
// the sizes can be detected properly.
	InitializeEntity(self, LinkDoors, INITPRIO_LINKDOORS);

	self.reset = door_rotating_reset;
}
#endif
