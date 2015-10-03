#ifdef SVQC
void() fd_secret_move1;
void() fd_secret_move2;
void() fd_secret_move3;
void() fd_secret_move4;
void() fd_secret_move5;
void() fd_secret_move6;
void() fd_secret_done;

const float SECRET_OPEN_ONCE = 1;		// stays open
const float SECRET_1ST_LEFT = 2;		// 1st move is left of arrow
const float SECRET_1ST_DOWN = 4;		// 1st move is down from arrow
const float SECRET_NO_SHOOT = 8;		// only opened by trigger
const float SECRET_YES_SHOOT = 16;	// shootable even if targeted

void fd_secret_use()
{SELFPARAM();
	float temp;
	string message_save;

	self.health = 10000;
	self.bot_attack = true;

	// exit if still moving around...
	if (self.origin != self.oldorigin)
		return;

	message_save = self.message;
	self.message = ""; // no more message
	SUB_UseTargets();				// fire all targets / killtargets
	self.message = message_save;

	self.velocity = '0 0 0';

	// Make a sound, wait a little...

	if (self.noise1 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.SUB_NEXTTHINK = self.SUB_LTIME + 0.1;

	temp = 1 - (self.spawnflags & SECRET_1ST_LEFT);	// 1 or -1
	makevectors(self.mangle);

	if (!self.t_width)
	{
		if (self.spawnflags & SECRET_1ST_DOWN)
			self.t_width = fabs(v_up * self.size);
		else
			self.t_width = fabs(v_right * self.size);
	}

	if (!self.t_length)
		self.t_length = fabs(v_forward * self.size);

	if (self.spawnflags & SECRET_1ST_DOWN)
		self.dest1 = self.origin - v_up * self.t_width;
	else
		self.dest1 = self.origin + v_right * (self.t_width * temp);

	self.dest2 = self.dest1 + v_forward * self.t_length;
	SUB_CalcMove(self.dest1, TSPEED_LINEAR, self.speed, fd_secret_move1);
	if (self.noise2 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
}

void fd_secret_damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	fd_secret_use();
}

// Wait after first movement...
void fd_secret_move1()
{SELFPARAM();
	self.SUB_NEXTTHINK = self.SUB_LTIME + 1.0;
	self.think = fd_secret_move2;
	if (self.noise3 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise3, VOL_BASE, ATTEN_NORM);
}

// Start moving sideways w/sound...
void fd_secret_move2()
{SELFPARAM();
	if (self.noise2 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
	SUB_CalcMove(self.dest2, TSPEED_LINEAR, self.speed, fd_secret_move3);
}

// Wait here until time to go back...
void fd_secret_move3()
{SELFPARAM();
	if (self.noise3 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise3, VOL_BASE, ATTEN_NORM);
	if (!(self.spawnflags & SECRET_OPEN_ONCE))
	{
		self.SUB_NEXTTHINK = self.SUB_LTIME + self.wait;
		self.think = fd_secret_move4;
	}
}

// Move backward...
void fd_secret_move4()
{SELFPARAM();
	if (self.noise2 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
	SUB_CalcMove(self.dest1, TSPEED_LINEAR, self.speed, fd_secret_move5);
}

// Wait 1 second...
void fd_secret_move5()
{SELFPARAM();
	self.SUB_NEXTTHINK = self.SUB_LTIME + 1.0;
	self.think = fd_secret_move6;
	if (self.noise3 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise3, VOL_BASE, ATTEN_NORM);
}

void fd_secret_move6()
{SELFPARAM();
	if (self.noise2 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise2, VOL_BASE, ATTEN_NORM);
	SUB_CalcMove(self.oldorigin, TSPEED_LINEAR, self.speed, fd_secret_done);
}

void fd_secret_done()
{SELFPARAM();
	if (self.spawnflags&SECRET_YES_SHOOT)
	{
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
		//self.th_pain = fd_secret_use;
	}
	if (self.noise3 != "")
		_sound(self, CH_TRIGGER_SINGLE, self.noise3, VOL_BASE, ATTEN_NORM);
}

void secret_blocked()
{SELFPARAM();
	if (time < self.attack_finished_single)
		return;
	self.attack_finished_single = time + 0.5;
	//T_Damage (other, self, self, self.dmg, self.dmg, self.deathtype, DT_IMPACT, (self.absmin + self.absmax) * 0.5, '0 0 0', Obituary_Generic);
}

/*
==============
secret_touch

Prints messages
================
*/
void secret_touch()
{SELFPARAM();
	if (!other.iscreature)
		return;
	if (self.attack_finished_single > time)
		return;

	self.attack_finished_single = time + 2;

	if (self.message)
	{
		if (IS_CLIENT(other))
			centerprint(other, self.message);
		play2(other, SND(TALK));
	}
}

void secret_reset()
{SELFPARAM();
	if (self.spawnflags&SECRET_YES_SHOOT)
	{
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
	}
	setorigin(self, self.oldorigin);
	self.think = func_null;
	self.SUB_NEXTTHINK = 0;
}

/*QUAKED spawnfunc_func_door_secret (0 .5 .8) ? open_once 1st_left 1st_down no_shoot always_shoot
Basic secret door. Slides back, then to the side. Angle determines direction.
wait  = # of seconds before coming back
1st_left = 1st move is left of arrow
1st_down = 1st move is down from arrow
always_shoot = even if targeted, keep shootable
t_width = override WIDTH to move back (or height if going down)
t_length = override LENGTH to move sideways
"dmg"		damage to inflict when blocked (2 default)

If a secret door has a targetname, it will only be opened by it's botton or trigger, not by damage.
"sounds"
1) medieval
2) metal
3) base
*/

spawnfunc(func_door_secret)
{
	/*if (!self.deathtype) // map makers can override this
		self.deathtype = " got in the way";*/

	if (!self.dmg)
		self.dmg = 2;

	// Magic formula...
	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.classname = "door";
	if (!InitMovingBrushTrigger())
		return;
	self.effects |= EF_LOWPRECISION;

	self.touch = secret_touch;
	self.blocked = secret_blocked;
	self.speed = 50;
	self.use = fd_secret_use;
	IFTARGETED
	{
	}
	else
		self.spawnflags |= SECRET_YES_SHOOT;

	if(self.spawnflags&SECRET_YES_SHOOT)
	{
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
		self.event_damage = fd_secret_damage;
	}
	self.oldorigin = self.origin;
	if (!self.wait)
		self.wait = 5;		// 5 seconds before closing

	self.reset = secret_reset;
	secret_reset();
}
#endif
