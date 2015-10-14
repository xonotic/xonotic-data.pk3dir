#ifdef SVQC
// button and multiple button

void() button_wait;
void() button_return;

void button_wait()
{SELFPARAM();
	self.state = STATE_TOP;
	self.SUB_NEXTTHINK = self.SUB_LTIME + self.wait;
	self.SUB_THINK = button_return;
	activator = self.enemy;
	SUB_UseTargets();
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

void button_reset()
{SELFPARAM();
	self.health = self.max_health;
	setorigin(self, self.pos1);
	self.frame = 0;			// use normal textures
	self.state = STATE_BOTTOM;
	if (self.health)
		self.takedamage = DAMAGE_YES;	// can be shot again
}

void button_use()
{SELFPARAM();
	if(self.active != ACTIVE_ACTIVE)
		return;

	self.enemy = activator;
	button_fire ();
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

void button_damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.spawnflags & DOOR_NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	self.health = self.health - damage;
	if (self.health <= 0)
	{
		self.enemy = damage_attacker;
		button_fire ();
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
	SetMovedir(self);

	if (!InitMovingBrushTrigger())
		return;
	self.effects |= EF_LOWPRECISION;

	self.blocked = button_blocked;
	self.use = button_use;

//	if (self.health == 0) // all buttons are now shootable
//		self.health = 10;
	if (self.health)
	{
		self.max_health = self.health;
		self.event_damage = button_damage;
		self.takedamage = DAMAGE_YES;
	}
	else
		self.touch = button_touch;

	if (!self.speed)
		self.speed = 40;
	if (!self.wait)
		self.wait = 1;
	if (!self.lip)
		self.lip = 4;

    if(self.noise != "")
        precache_sound(self.noise);

	self.active = ACTIVE_ACTIVE;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);
    self.flags |= FL_NOTARGET;

	button_reset();
}
#endif
