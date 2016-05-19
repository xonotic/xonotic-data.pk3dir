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

void fd_secret_use(entity this, entity actor, entity trigger)
{
	float temp;
	string message_save;

	this.health = 10000;
	this.bot_attack = true;

	// exit if still moving around...
	if (this.origin != this.oldorigin)
		return;

	message_save = this.message;
	this.message = ""; // no more message
	SUB_UseTargets(this, actor, trigger);				// fire all targets / killtargets
	this.message = message_save;

	this.velocity = '0 0 0';

	// Make a sound, wait a little...

	if (this.noise1 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	this.SUB_NEXTTHINK = this.SUB_LTIME + 0.1;

	temp = 1 - (this.spawnflags & SECRET_1ST_LEFT);	// 1 or -1
	makevectors(this.mangle);

	if (!this.t_width)
	{
		if (this.spawnflags & SECRET_1ST_DOWN)
			this.t_width = fabs(v_up * this.size);
		else
			this.t_width = fabs(v_right * this.size);
	}

	if (!this.t_length)
		this.t_length = fabs(v_forward * this.size);

	if (this.spawnflags & SECRET_1ST_DOWN)
		this.dest1 = this.origin - v_up * this.t_width;
	else
		this.dest1 = this.origin + v_right * (this.t_width * temp);

	this.dest2 = this.dest1 + v_forward * this.t_length;
	WITHSELF(this, SUB_CalcMove(this.dest1, TSPEED_LINEAR, this.speed, fd_secret_move1));
	if (this.noise2 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
}

void fd_secret_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	fd_secret_use(this, NULL, NULL);
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

.float door_finished;

void secret_blocked()
{SELFPARAM();
	if (time < self.door_finished)
		return;
	self.door_finished = time + 0.5;
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
	if (self.door_finished > time)
		return;

	self.door_finished = time + 2;

	if (self.message)
	{
		if (IS_CLIENT(other))
			centerprint(other, self.message);
		play2(other, self.noise);
	}
}

void secret_reset(entity this)
{
	if (this.spawnflags & SECRET_YES_SHOOT)
	{
		this.health = 10000;
		this.takedamage = DAMAGE_YES;
	}
	setorigin(this, this.oldorigin);
	this.think = func_null;
	this.SUB_NEXTTHINK = 0;
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
	/*if (!this.deathtype) // map makers can override this
		this.deathtype = " got in the way";*/

	if (!this.dmg) this.dmg = 2;

	// Magic formula...
	this.mangle = this.angles;
	this.angles = '0 0 0';
	this.classname = "door";
	if (!InitMovingBrushTrigger(this)) return;
	this.effects |= EF_LOWPRECISION;

	if (this.noise == "") this.noise = "misc/talk.wav";
	precache_sound(this.noise);

	this.touch = secret_touch;
	this.blocked = secret_blocked;
	this.speed = 50;
	this.use = fd_secret_use;
	IFTARGETED
	{
	}
	else
		this.spawnflags |= SECRET_YES_SHOOT;

	if (this.spawnflags & SECRET_YES_SHOOT)
	{
		this.health = 10000;
		this.takedamage = DAMAGE_YES;
		this.event_damage = fd_secret_damage;
	}
	this.oldorigin = this.origin;
	if (!this.wait) this.wait = 5; // seconds before closing

	this.reset = secret_reset;
	this.reset(this);
}
#endif
