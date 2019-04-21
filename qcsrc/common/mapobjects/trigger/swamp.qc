#include "swamp.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <lib/warpzone/util_server.qh>
    #include <common/weapons/_all.qh>
    #include <server/defs.qh>
    #include <common/deathtypes/all.qh>
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
.float swamp_lifetime;  // holds the points remaining until slug dies (not quite health!) 
.entity swampslug;

#ifdef SVQC
spawnfunc(trigger_swamp);
#endif
void swamp_touch(entity this, entity toucher);
void swampslug_think(entity this);


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
void swampslug_think(entity this)
{
	//Slowly kill the slug
	this.swamp_lifetime -= 1;

	//Slug dead? then remove curses.
	if(GetResource(this, RES_HEALTH) <= 0)
	{
		this.owner.in_swamp = 0;
		delete(this);
		//centerprint(this.owner,"Killing slug...\n");
		return;
	}

	// Slug still alive, so we are still in the swamp
	// Or we have exited it very recently.
	// Do the damage and renew the timer.
#ifdef SVQC
	Damage (this.owner, this, this, this.dmg, DEATH_SWAMP.m_id, DMG_NOWEP, this.owner.origin, '0 0 0');
#endif

	this.nextthink = time + this.swamp_interval;
}

void swamp_touch(entity this, entity toucher)
{
	// If whatever thats touching the swamp is not a player
	// or if its a dead player, just dont care abt it.
	if(!IS_PLAYER(toucher) || IS_DEAD(toucher))
		return;

	EXACTTRIGGER_TOUCH(this, toucher);

	// Chech if player alredy got a swampslug.
	if(toucher.in_swamp != 1)
	{
		// If not attach one.
		//centerprint(toucher,"Entering swamp!\n");
		toucher.swampslug = spawn();
		toucher.swampslug.swamp_lifetime = 2;
		setthink(toucher.swampslug, swampslug_think);
		toucher.swampslug.nextthink = time;
		toucher.swampslug.owner = toucher;
		toucher.swampslug.dmg = this.dmg;
		toucher.swampslug.swamp_interval = this.swamp_interval;
		toucher.swamp_slowdown = this.swamp_slowdown;
		toucher.in_swamp = 1;
		return;
	}

	//toucher.in_swamp = 1;

	//Revitalize players swampslug
	toucher.swampslug.swamp_lifetime = 2;
}

REGISTER_NET_LINKED(ENT_CLIENT_SWAMP)

#ifdef SVQC
float swamp_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_SWAMP);

	WriteByte(MSG_ENTITY, this.dmg); // can probably get away with using a single byte here
	WriteByte(MSG_ENTITY, this.swamp_slowdown);
	WriteByte(MSG_ENTITY, this.swamp_interval);

	trigger_common_write(this, false);

	return true;
}

void swamp_link(entity this)
{
	trigger_link(this, swamp_send);
}

/*QUAKED spawnfunc_trigger_swamp (.5 .5 .5) ?
Players gettin into the swamp will
get slowd down and damaged
*/
spawnfunc(trigger_swamp)
{
	// Init stuff
	trigger_init(this);
	settouch(this, swamp_touch);

	// Setup default keys, if missing
	if(this.dmg <= 0)
		this.dmg = 5;
	if(this.swamp_interval <= 0)
		this.swamp_interval = 1;
	if(this.swamp_slowdown <= 0)
		this.swamp_slowdown = 0.5;

	swamp_link(this);
}

#elif defined(CSQC)

NET_HANDLE(ENT_CLIENT_SWAMP, bool isnew)
{
	this.dmg = ReadByte();
	this.swamp_slowdown = ReadByte();
	this.swamp_interval = ReadByte();

	trigger_common_read(this, false);

	return = true;

	this.classname = "trigger_swamp";
	this.solid = SOLID_TRIGGER;
	settouch(this, swamp_touch);
	this.drawmask = MASK_NORMAL;
	this.move_time = time;
	this.entremove = trigger_remove_generic;
}
#endif
