#ifdef SVQC
void spawnfunc_trigger_swamp(void);
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
{
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
{
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
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_LADDER);

	WriteByte(MSG_ENTITY, self.warpzone_isboxy);
	WriteByte(MSG_ENTITY, self.scale);
	WriteByte(MSG_ENTITY, self.dmg); // can probably get away with using a single byte here
	WriteByte(MSG_ENTITY, self.swamp_slowdown);
	WriteByte(MSG_ENTITY, self.swamp_interval);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteCoord(MSG_ENTITY, self.mins_x);
	WriteCoord(MSG_ENTITY, self.mins_y);
	WriteCoord(MSG_ENTITY, self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x);
	WriteCoord(MSG_ENTITY, self.maxs_y);
	WriteCoord(MSG_ENTITY, self.maxs_z);

	WriteCoord(MSG_ENTITY, self.movedir_x);
	WriteCoord(MSG_ENTITY, self.movedir_y);
	WriteCoord(MSG_ENTITY, self.movedir_z);

	WriteAngle(MSG_ENTITY, self.angles_x);
	WriteAngle(MSG_ENTITY, self.angles_y);
	WriteAngle(MSG_ENTITY, self.angles_z);

	return TRUE;
}

void swamp_link()
{
	Net_LinkEntity(self, FALSE, 0, func_ladder_send);
}

/*QUAKED spawnfunc_trigger_swamp (.5 .5 .5) ?
Players gettin into the swamp will
get slowd down and damaged
*/
void spawnfunc_trigger_swamp(void)
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
{
	self.warpzone_isboxy = ReadByte();
	self.scale = ReadByte();
	self.dmg = ReadByte();
	self.swamp_slowdown = ReadByte();
	self.swamp_interval = ReadByte();

	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	setorigin(self, self.origin);

	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	setsize(self, self.mins, self.maxs);

	self.movedir_x = ReadCoord();
	self.movedir_y = ReadCoord();
	self.movedir_z = ReadCoord();

	self.angles_x = ReadAngle();
	self.angles_y = ReadAngle();
	self.angles_z = ReadAngle();

	self.classname = "trigger_swamp";
	self.solid = SOLID_TRIGGER;
	self.draw = trigger_draw_generic;
	self.trigger_touch = swamp_touch;
	self.drawmask = MASK_NORMAL;
	self.move_time = time;
}
#endif
