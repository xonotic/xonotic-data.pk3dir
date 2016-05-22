#ifdef SVQC
// button and multiple button

void() button_wait;
void() button_return;

void button_wait()
{SELFPARAM();
	self.state = STATE_TOP;
	self.SUB_NEXTTHINK = self.SUB_LTIME + self.wait;
	self.SUB_THINK = button_return;
	SUB_UseTargets(self, self.enemy, NULL);
	self.frame = 1;			// use alternate textures
}

void button_done()
{SELFPARAM();
	self.state = STATE_BOTTOM;
}

void button_return()
{SELFPARAM();
	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos1, TSPEED_LINEAR, self.speed, button_done);
	self.frame = 0;			// use normal textures
	if (self.health)
		self.takedamage = DAMAGE_YES;	// can be shot again
}


void button_blocked()
{
	// do nothing, just don't come all the way back out
}


void button_fire()
{SELFPARAM();
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;    // will be reset upon return

	if (self.state == STATE_UP || self.state == STATE_TOP)
		return;

	if (self.noise != "")
		_sound (self, CH_TRIGGER, self.noise, VOL_BASE, ATTEN_NORM);

	self.state = STATE_UP;
	SUB_CalcMove (self.pos2, TSPEED_LINEAR, self.speed, button_wait);
}

void button_reset(entity this)
{
	this.health = this.max_health;
	setorigin(this, this.pos1);
	this.frame = 0;			// use normal textures
	this.state = STATE_BOTTOM;
	if (this.health)
		this.takedamage = DAMAGE_YES;	// can be shot again
}

void button_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	this.enemy = actor;
	WITHSELF(this, button_fire());
}

void button_touch()
{SELFPARAM();
	if (!other)
		return;
	if (!other.iscreature)
		return;
	if(other.velocity * self.movedir < 0)
		return;
	self.enemy = other;
	if (other.owner)
		self.enemy = other.owner;
	button_fire ();
}

void button_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if(this.spawnflags & DOOR_NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	this.health = this.health - damage;
	if (this.health <= 0)
	{
		this.enemy = damage_attacker;
		WITHSELF(this, button_fire());
	}
}


/*QUAKED spawnfunc_func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"		determines the opening direction
"target"	all entities with a matching targetname will be used
"speed"		override the default 40 speed
"wait"		override the default 1 second wait (-1 = never return)
"lip"		override the default 4 pixel lip remaining at end of move
"health"	if set, the button must be killed instead of touched. If set to -1, the button will fire on ANY attack, even damageless ones like the InstaGib laser
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
*/
spawnfunc(func_button)
{
	SetMovedir(this);

	if (!InitMovingBrushTrigger(this))
		return;
	this.effects |= EF_LOWPRECISION;

	this.blocked = button_blocked;
	this.use = button_use;

//	if (this.health == 0) // all buttons are now shootable
//		this.health = 10;
	if (this.health)
	{
		this.max_health = this.health;
		this.event_damage = button_damage;
		this.takedamage = DAMAGE_YES;
	}
	else
		settouch(this, button_touch);

	if (!this.speed)
		this.speed = 40;
	if (!this.wait)
		this.wait = 1;
	if (!this.lip)
		this.lip = 4;

    if(this.noise != "")
        precache_sound(this.noise);

	this.active = ACTIVE_ACTIVE;

	this.pos1 = this.origin;
	this.pos2 = this.pos1 + this.movedir*(fabs(this.movedir*this.size) - this.lip);
    this.flags |= FL_NOTARGET;

	button_reset(this);
}
#endif
