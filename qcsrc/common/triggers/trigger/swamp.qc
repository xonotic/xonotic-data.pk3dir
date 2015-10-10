#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../../../server/_all.qh"
    #include "../../../warpzonelib/util_server.qh"
    #include "../../weapons/all.qh"
    #include "../../../server/defs.qh"
    #include "../../deathtypes.qh"
#endif

/*
*		t_swamp.c
*		Adds spawnfunc_trigger_swamp and suppoart routines for xonotic 1.2.1+
*		Author tZork (Jakob MG)
*		jakob@games43.se
*		2005 11 29
*/

.float swamp_interval;	//Hurt players in swamp with this interval
.float swamp_slowdown;	//Players in swamp get slowd down by this mutch 0-1 is slowdown 1-~ is speedup (!?)
.entity swampslug;

#ifdef SVQC
spawnfunc(trigger_swamp);
#endif
void swamp_touch(void);
void swampslug_think();


/*
* Uses a entity calld swampslug to handle players in the swamp
* It works like this: When the plyer enters teh swamp the spawnfunc_trigger_swamp
* attaches a new "swampslug" to the player. As long as the plyer is inside
* the swamp the swamp gives the slug new health. But the slug slowly kills itself
* so when the player goes outside the swamp, it dies and releases the player from the
* swamps curses (dmg/slowdown)
*
* I do it this way becuz there is no "untouch" event.
*/
void swampslug_think(void)
{SELFPARAM();
	//Slowly kill the slug
	self.health = self.health - 1;

	//Slug dead? then remove curses.
	if(self.health <= 0)
	{
		self.owner.in_swamp = 0;
		remove(self);
		//centerprint(self.owner,"Killing slug...\n");
		return;
	}

	// Slug still alive, so we are still in the swamp
	// Or we have exited it very recently.
	// Do the damage and renew the timer.
#ifdef SVQC
	Damage (self.owner, self, self, self.dmg, DEATH_SWAMP, other.origin, '0 0 0');
#endif

	self.nextthink = time + self.swamp_interval;
}

void swamp_touch(void)
{SELFPARAM();
	// If whatever thats touching the swamp is not a player
	// or if its a dead player, just dont care abt it.
	if(!IS_PLAYER(other) || PHYS_DEAD(other))
		return;

	EXACTTRIGGER_TOUCH;

	// Chech if player alredy got a swampslug.
	if(other.in_swamp != 1)
	{
		// If not attach one.
		//centerprint(other,"Entering swamp!\n");
		other.swampslug = spawn();
		other.swampslug.health = 2;
		other.swampslug.think = swampslug_think;
		other.swampslug.nextthink = time;
		other.swampslug.owner = other;
		other.swampslug.dmg = self.dmg;
		other.swampslug.swamp_interval = self.swamp_interval;
		other.swamp_slowdown = self.swamp_slowdown;
		other.in_swamp = 1;
		return;
	}

	//other.in_swamp = 1;

	//Revitalize players swampslug
	other.swampslug.health = 2;
}

#ifdef SVQC
float swamp_send(entity to, float sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_LADDER);

	WriteByte(MSG_ENTITY, self.dmg); // can probably get away with using a single byte here
	WriteByte(MSG_ENTITY, self.swamp_slowdown);
	WriteByte(MSG_ENTITY, self.swamp_interval);

	trigger_common_write(false);

	return true;
}

void swamp_link()
{SELFPARAM();
	Net_LinkEntity(self, false, 0, func_ladder_send);
}

/*QUAKED spawnfunc_trigger_swamp (.5 .5 .5) ?
Players gettin into the swamp will
get slowd down and damaged
*/
spawnfunc(trigger_swamp)
{
	// Init stuff
	EXACTTRIGGER_INIT;
	self.touch = swamp_touch;

	// Setup default keys, if missing
	if(self.dmg <= 0)
		self.dmg = 5;
	if(self.swamp_interval <= 0)
		self.swamp_interval = 1;
	if(self.swamp_slowdown <= 0)
		self.swamp_slowdown = 0.5;

	swamp_link();
}

#elif defined(CSQC)

void ent_swamp()
{SELFPARAM();
	self.dmg = ReadByte();
	self.swamp_slowdown = ReadByte();
	self.swamp_interval = ReadByte();

	trigger_common_read(false);

	self.classname = "trigger_swamp";
	self.solid = SOLID_TRIGGER;
	self.draw = trigger_draw_generic;
	self.trigger_touch = swamp_touch;
	self.drawmask = MASK_NORMAL;
	self.move_time = time;
	self.entremove = trigger_remove_generic;
}
#endif
