/*

Doors are similar to buttons, but can spawn a fat trigger field around them
to open without a touch, and they link together to form simultanious
double/quad doors.

Door.owner is the master door.  If there is only one door, it points to itself.
If multiple doors, all will point to a single one.

Door.enemy chains from the master door through all doors linked in the chain.

*/


/*
=============================================================================

THINK FUNCTIONS

=============================================================================
*/

void() door_go_down;
void() door_go_up;
void() door_rotating_go_down;
void() door_rotating_go_up;

void door_blocked()
{

    if((self.spawnflags & 8) && (other.takedamage != DAMAGE_NO)) { // KIll Kill Kill!!
        Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
    } else {

        if((self.dmg) && (other.takedamage == DAMAGE_YES))    // Shall we bite?
            Damage (other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');

         //Dont chamge direction for dead or dying stuff
        if(other.deadflag != DEAD_NO && (other.takedamage == DAMAGE_NO)) {
            if (self.wait >= 0)
            {
                if (self.state == STATE_DOWN)
			if (self.classname == "door")
			{
				door_go_up ();
			} else
			{
				door_rotating_go_up ();
			}
                else
			if (self.classname == "door")
			{
				door_go_down ();
			} else
			{
				door_rotating_go_down ();
			}
            }
        } else {
            //gib dying stuff just to make sure
            if((self.dmg) && (other.takedamage != DAMAGE_NO))    // Shall we bite?
                Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
        }
    }
}

void door_hit_top()
{
	if (self.noise1 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.state = STATE_TOP;
	if (self.spawnflags & DOOR_TOGGLE)
		return;		// don't come down automatically
	if (self.classname == "door")
	{
		self.think = door_go_down;
	} else
	{
		self.think = door_rotating_go_down;
	}
	self.nextthink = self.ltime + self.wait;
}

void door_hit_bottom()
{
	if (self.noise1 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.state = STATE_BOTTOM;
}

void door_go_down()
{
	if (self.noise2 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
	if (self.max_health)
	{
		self.takedamage = DAMAGE_YES;
		self.health = self.max_health;
	}

	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos1, TSPEED_LINEAR, self.speed, door_hit_bottom);
}

void door_go_up()
{
	if (self.state == STATE_UP)
		return;		// already going up

	if (self.state == STATE_TOP)
	{	// reset top wait time
		self.nextthink = self.ltime + self.wait;
		return;
	}

	if (self.noise2 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
	self.state = STATE_UP;
	SUB_CalcMove (self.pos2, TSPEED_LINEAR, self.speed, door_hit_top);

	string oldmessage;
	oldmessage = self.message;
	self.message = "";
	SUB_UseTargets();
	self.message = oldmessage;
}


/*
=============================================================================

ACTIVATION FUNCTIONS

=============================================================================
*/

float door_check_keys(void) {
	local entity door;


	if (self.owner)
		door = self.owner;
	else
		door = self;

	// no key needed
	if (!door.itemkeys)
		return TRUE;

	// this door require a key
	// only a player can have a key
	if (!IS_PLAYER(other))
		return FALSE;

	if (item_keys_usekey(door, other)) {
		// some keys were used
		if (other.key_door_messagetime <= time) {
			play2(other, "misc/talk.wav");
			Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_DOOR_LOCKED_ALSONEED, item_keys_keylist(door.itemkeys));
			other.key_door_messagetime = time + 2;
		}
	} else {
		// no keys were used
		if (other.key_door_messagetime <= time) {
			play2(other, "misc/talk.wav");
			Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_DOOR_LOCKED_NEED, item_keys_keylist(door.itemkeys));
			other.key_door_messagetime = time + 2;
		}
	}

	if (door.itemkeys) {
		// door is now unlocked
		play2(other, "misc/talk.wav");
		Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_DOOR_UNLOCKED);
		return TRUE;
	} else
		return FALSE;
}

void door_fire()
{
	entity 	oself;
	entity	starte;

	if (self.owner != self)
		objerror ("door_fire: self.owner != self");

	oself = self;

	if (self.spawnflags & DOOR_TOGGLE)
	{
		if (self.state == STATE_UP || self.state == STATE_TOP)
		{
			starte = self;
			do
			{
				if (self.classname == "door")
				{
					door_go_down ();
				}
				else
				{
					door_rotating_go_down ();
				}
				self = self.enemy;
			} while ( (self != starte) && (self != world) );
			self = oself;
			return;
		}
	}

// trigger all paired doors
	starte = self;
	do
	{
		if (self.classname == "door")
		{
			door_go_up ();
		} else
		{
			// if the BIDIR spawnflag (==2) is set and the trigger has set trigger_reverse, reverse the opening direction
			if ((self.spawnflags & 2) && other.trigger_reverse!=0 && self.lip!=666 && self.state == STATE_BOTTOM)
			{
				self.lip = 666; // self.lip is used to remember reverse opening direction for door_rotating
			  	self.pos2 = '0 0 0' - self.pos2;
			}
			// if BIDIR_IN_DOWN (==8) is set, prevent the door from reoping during closing if it is triggered from the wrong side
			if (!((self.spawnflags & 2) &&  (self.spawnflags & 8) && self.state == STATE_DOWN
			    && (((self.lip==666) && (other.trigger_reverse==0)) || ((self.lip!=666) && (other.trigger_reverse!=0)))))
			{
				door_rotating_go_up ();
			}
		}
		self = self.enemy;
	} while ( (self != starte) && (self != world) );
	self = oself;
}

void door_use()
{
	entity oself;

	//dprint("door_use (model: ");dprint(self.model);dprint(")\n");

	if (self.owner)
	{
		oself = self;
		self = self.owner;
		door_fire ();
		self = oself;
	}
}

void door_trigger_touch()
{
	if (other.health < 1)
		if (!(other.iscreature && other.deadflag == DEAD_NO))
			return;

	if (time < self.attack_finished_single)
		return;

	// check if door is locked
	if (!door_check_keys())
		return;

	self.attack_finished_single = time + 1;

	activator = other;

	self = self.owner;
	door_use ();
}

void door_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	entity oself;
	if(self.spawnflags & DOOR_NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	self.health = self.health - damage;

	if (self.itemkeys) {
		// don't allow opening doors through damage if keys are required
		return;
	}

	if (self.health <= 0)
	{
		oself = self;
		self = self.owner;
		self.health = self.max_health;
		self.takedamage = DAMAGE_NO;	// wil be reset upon return
		door_use ();
		self = oself;
	}
}


/*
================
door_touch

Prints messages
================
*/

void door_touch()
{
	if (!IS_PLAYER(other))
		return;
	if (self.owner.attack_finished_single > time)
		return;

	self.owner.attack_finished_single = time + 2;

	if (!(self.owner.dmg) && (self.owner.message != ""))
	{
		if (IS_CLIENT(other))
			centerprint(other, self.owner.message);
		play2(other, "misc/talk.wav");
	}
}

void door_generic_plat_blocked()
{

    if((self.spawnflags & 8) && (other.takedamage != DAMAGE_NO)) { // KIll Kill Kill!!
        Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
    } else {

        if((self.dmg) && (other.takedamage == DAMAGE_YES))    // Shall we bite?
            Damage (other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');

         //Dont chamge direction for dead or dying stuff
        if(other.deadflag != DEAD_NO && (other.takedamage == DAMAGE_NO)) {
            if (self.wait >= 0)
            {
                if (self.state == STATE_DOWN)
                    door_rotating_go_up ();
                else
                    door_rotating_go_down ();
            }
        } else {
            //gib dying stuff just to make sure
            if((self.dmg) && (other.takedamage != DAMAGE_NO))    // Shall we bite?
                Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
        }
    }
}

void door_rotating_hit_top()
{
	if (self.noise1 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.state = STATE_TOP;
	if (self.spawnflags & DOOR_TOGGLE)
		return;		// don't come down automatically
	self.think = door_rotating_go_down;
	self.nextthink = self.ltime + self.wait;
}

void door_rotating_hit_bottom()
{
	if (self.noise1 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	if (self.lip==666) // self.lip is used to remember reverse opening direction for door_rotating
	{
		self.pos2 = '0 0 0' - self.pos2;
		self.lip = 0;
	}
	self.state = STATE_BOTTOM;
}

void door_rotating_go_down()
{
	if (self.noise2 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
	if (self.max_health)
	{
		self.takedamage = DAMAGE_YES;
		self.health = self.max_health;
	}

	self.state = STATE_DOWN;
	SUB_CalcAngleMove (self.pos1, TSPEED_LINEAR, self.speed, door_rotating_hit_bottom);
}

void door_rotating_go_up()
{
	if (self.state == STATE_UP)
		return;		// already going up

	if (self.state == STATE_TOP)
	{	// reset top wait time
		self.nextthink = self.ltime + self.wait;
		return;
	}
	if (self.noise2 != "")
		sound (self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
	self.state = STATE_UP;
	SUB_CalcAngleMove (self.pos2, TSPEED_LINEAR, self.speed, door_rotating_hit_top);

	string oldmessage;
	oldmessage = self.message;
	self.message = "";
	SUB_UseTargets();
	self.message = oldmessage;
}


/*
=============================================================================

SPAWNING FUNCTIONS

=============================================================================
*/

entity spawn_field(vector fmins, vector fmaxs)
{
	entity	trigger;
	vector	t1, t2;

	trigger = spawn();
	trigger.classname = "doortriggerfield";
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = door_trigger_touch;

	t1 = fmins;
	t2 = fmaxs;
	setsize (trigger, t1 - '60 60 8', t2 + '60 60 8');
	return (trigger);
}

entity LinkDoors_nextent(entity cur, entity near, entity pass)
{
	while((cur = find(cur, classname, self.classname)) && ((cur.spawnflags & 4) || cur.enemy))
	{
	}
	return cur;
}

float LinkDoors_isconnected(entity e1, entity e2, entity pass)
{
	float DELTA = 4;
	if (e1.absmin_x > e2.absmax_x + DELTA)
		return FALSE;
	if (e1.absmin_y > e2.absmax_y + DELTA)
		return FALSE;
	if (e1.absmin_z > e2.absmax_z + DELTA)
		return FALSE;
	if (e2.absmin_x > e1.absmax_x + DELTA)
		return FALSE;
	if (e2.absmin_y > e1.absmax_y + DELTA)
		return FALSE;
	if (e2.absmin_z > e1.absmax_z + DELTA)
		return FALSE;
	return TRUE;
}


/*
=============
LinkDoors


=============
*/

void LinkDoors()
{
	entity	t;
	vector	cmins, cmaxs;

	if (self.enemy)
		return;		// already linked by another door
	if (self.spawnflags & 4)
	{
		self.owner = self.enemy = self;

		if (self.health)
			return;
		IFTARGETED
			return;
		if (self.items)
			return;
		self.trigger_field = spawn_field(self.absmin, self.absmax);

		return;		// don't want to link this door
	}

	FindConnectedComponent(self, enemy, LinkDoors_nextent, LinkDoors_isconnected, world);

	// set owner, and make a loop of the chain
	dprint("LinkDoors: linking doors:");
	for(t = self; ; t = t.enemy)
	{
		dprint(" ", etos(t));
		t.owner = self;
		if(t.enemy == world)
		{
			t.enemy = self;
			break;
		}
	}
	dprint("\n");

	// collect health, targetname, message, size
	cmins = self.absmin;
	cmaxs = self.absmax;
	for(t = self; ; t = t.enemy)
	{
		if(t.health && !self.health)
			self.health = t.health;
		if((t.targetname != "") && (self.targetname == ""))
			self.targetname = t.targetname;
		if((t.message != "") && (self.message == ""))
			self.message = t.message;
		if (t.absmin_x < cmins_x)
			cmins_x = t.absmin_x;
		if (t.absmin_y < cmins_y)
			cmins_y = t.absmin_y;
		if (t.absmin_z < cmins_z)
			cmins_z = t.absmin_z;
		if (t.absmax_x > cmaxs_x)
			cmaxs_x = t.absmax_x;
		if (t.absmax_y > cmaxs_y)
			cmaxs_y = t.absmax_y;
		if (t.absmax_z > cmaxs_z)
			cmaxs_z = t.absmax_z;
		if(t.enemy == self)
			break;
	}

	// distribute health, targetname, message
	for(t = self; t; t = t.enemy)
	{
		t.health = self.health;
		t.targetname = self.targetname;
		t.message = self.message;
		if(t.enemy == self)
			break;
	}

	// shootable, or triggered doors just needed the owner/enemy links,
	// they don't spawn a field

	if (self.health)
		return;
	IFTARGETED
		return;
	if (self.items)
		return;

	self.trigger_field = spawn_field(cmins, cmaxs);
}


/*QUAKED spawnfunc_func_door (0 .5 .8) ? START_OPEN x DOOR_DONT_LINK GOLD_KEY SILVER_KEY TOGGLE
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).

GOLD_KEY causes the door to open only if the activator holds a gold key.

SILVER_KEY causes the door to open only if the activator holds a silver key.

"message"	is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"		determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"	if set, door must be shot open
"speed"		movement speed (100 default)
"wait"		wait before returning (3 default, -1 = never return)
"lip"		lip remaining at end of move (8 default)
"dmg"		damage to inflict when blocked (2 default)
"sounds"
0)	no sound
1)	stone
2)	base
3)	stone chain
4)	screechy metal
FIXME: only one sound set available at the time being

*/

void door_init_startopen()
{
	setorigin (self, self.pos2);
	self.pos2 = self.pos1;
	self.pos1 = self.origin;
}

void door_reset()
{
	setorigin(self, self.pos1);
	self.velocity = '0 0 0';
	self.state = STATE_BOTTOM;
	self.think = func_null;
	self.nextthink = 0;
}

// spawnflags require key (for now only func_door)
void spawnfunc_func_door()
{
	// Quake 1 keys compatibility
	if (self.spawnflags & SPAWNFLAGS_GOLD_KEY)
		self.itemkeys |= ITEM_KEY_BIT(0);
	if (self.spawnflags & SPAWNFLAGS_SILVER_KEY)
		self.itemkeys |= ITEM_KEY_BIT(1);

	SetMovedir ();

	self.max_health = self.health;
	if (!InitMovingBrushTrigger())
		return;
	self.effects |= EF_LOWPRECISION;
	self.classname = "door";

	self.blocked = door_blocked;
	self.use = door_use;

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
		self.speed = 100;
	if (!self.wait)
		self.wait = 3;
	if (!self.lip)
		self.lip = 8;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);

// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
// but spawn in the open position
	if (self.spawnflags & DOOR_START_OPEN)
		InitializeEntity(self, door_init_startopen, INITPRIO_SETLOCATION);

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

	self.reset = door_reset;
}
