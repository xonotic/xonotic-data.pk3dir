#include "door_secret.qh"
#ifdef SVQC
void fd_secret_move1(entity this);
void fd_secret_move2(entity this);
void fd_secret_move3(entity this);
void fd_secret_move4(entity this);
void fd_secret_move5(entity this);
void fd_secret_move6(entity this);
void fd_secret_done(entity this);

void fd_secret_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	SetResourceExplicit(this, RES_HEALTH, 10000);
	if(!this.bot_attack)
		IL_PUSH(g_bot_targets, this);
	this.bot_attack = true;

	// exit if still moving around...
	if (this.origin != this.oldorigin)
		return;

	string message_save = this.message;
	this.message = ""; // no more message
	SUB_UseTargets(this, actor, trigger);				// fire all targets / killtargets
	this.message = message_save;

	this.velocity = '0 0 0';

	// Make a sound, wait a little...

	if (this.noise1 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	this.nextthink = this.ltime + 0.1;

	int temp = 1 - (this.spawnflags & DOOR_SECRET_1ST_LEFT);	// 1 or -1
	makevectors(this.mangle);

	if (!this.t_width)
	{
		if (this.spawnflags & DOOR_SECRET_1ST_DOWN)
			this.t_width = fabs(v_up * this.size);
		else
			this.t_width = fabs(v_right * this.size);
	}

	if (!this.t_length)
		this.t_length = fabs(v_forward * this.size);

	if (this.spawnflags & DOOR_SECRET_1ST_DOWN)
		this.dest1 = this.origin - v_up * this.t_width;
	else
		this.dest1 = this.origin + v_right * (this.t_width * temp);

	this.dest2 = this.dest1 + v_forward * this.t_length;
	SUB_CalcMove(this, this.dest1, TSPEED_LINEAR, this.speed, fd_secret_move1);
	if (this.noise2 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
}

void fd_secret_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	fd_secret_use(this, NULL, NULL);
}

// Wait after first movement...
void fd_secret_move1(entity this)
{
	this.nextthink = this.ltime + 1.0;
	setthink(this, fd_secret_move2);
	if (this.noise3 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise3, VOL_BASE, ATTEN_NORM);
}

// Start moving sideways w/sound...
void fd_secret_move2(entity this)
{
	if (this.noise2 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
	SUB_CalcMove(this, this.dest2, TSPEED_LINEAR, this.speed, fd_secret_move3);
}

// Wait here until time to go back...
void fd_secret_move3(entity this)
{
	if (this.noise3 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise3, VOL_BASE, ATTEN_NORM);
	if (!(this.spawnflags & DOOR_SECRET_OPEN_ONCE) && this.wait >= 0)
	{
		this.nextthink = this.ltime + this.wait;
		setthink(this, fd_secret_move4);
	}
}

// Move backward...
void fd_secret_move4(entity this)
{
	if (this.noise2 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
	SUB_CalcMove(this, this.dest1, TSPEED_LINEAR, this.speed, fd_secret_move5);
}

// Wait 1 second...
void fd_secret_move5(entity this)
{
	this.nextthink = this.ltime + 1.0;
	setthink(this, fd_secret_move6);
	if (this.noise3 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise3, VOL_BASE, ATTEN_NORM);
}

void fd_secret_move6(entity this)
{
	if (this.noise2 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise2, VOL_BASE, ATTEN_NORM);
	SUB_CalcMove(this, this.oldorigin, TSPEED_LINEAR, this.speed, fd_secret_done);
}

void fd_secret_done(entity this)
{
	if (this.spawnflags&DOOR_SECRET_YES_SHOOT)
	{
		SetResourceExplicit(this, RES_HEALTH, 10000);
		this.takedamage = DAMAGE_YES;
		//this.th_pain = fd_secret_use;
	}
	if (this.noise3 != "")
		_sound(this, CH_TRIGGER_SINGLE, this.noise3, VOL_BASE, ATTEN_NORM);
}

.float door_finished;

void secret_blocked(entity this, entity blocker)
{
	if (time < this.door_finished)
		return;
	this.door_finished = time + 0.5;
	//T_Damage (other, this, this, this.dmg, this.dmg, this.deathtype, DT_IMPACT, (this.absmin + this.absmax) * 0.5, '0 0 0', Obituary_Generic);
}

/*
==============
secret_touch

Prints messages
================
*/
void secret_touch(entity this, entity toucher)
{
	if (!toucher.iscreature)
		return;
	if (this.door_finished > time)
		return;
	if (this.active != ACTIVE_ACTIVE)
		return;

	this.door_finished = time + 2;

	if (this.message)
	{
		if (IS_CLIENT(toucher))
			centerprint(toucher, this.message);
		play2(toucher, this.noise);
	}
}

void secret_reset(entity this)
{
	if (this.spawnflags & DOOR_SECRET_YES_SHOOT)
	{
		SetResourceExplicit(this, RES_HEALTH, 10000);
		this.takedamage = DAMAGE_YES;
	}
	setorigin(this, this.oldorigin);
	setthink(this, func_null);
	this.nextthink = 0;
	this.active = ACTIVE_ACTIVE;
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

	if (!this.dmg)
	{
		this.dmg = 2;
	}

	// Magic formula...
	this.mangle = this.angles;
	this.angles = '0 0 0';
	this.classname = "door";
	if (!InitMovingBrushTrigger(this)) return;
	this.effects |= EF_LOWPRECISION;

	// TODO: other soundpacks
	if (this.sounds > 0)
	{
		this.noise1 = "plats/medplat1.wav";
		this.noise2 = "plats/medplat1.wav";
		this.noise3 = "plats/medplat2.wav";
	}

	// sound on touch
	if (this.noise == "")
	{
		this.noise = "misc/talk.wav";
	}
	precache_sound(this.noise);
	// sound while moving backwards
	if (this.noise1 && this.noise1 != "")
	{
		precache_sound(this.noise1);
	}
	// sound while moving sideways
	if (this.noise2 && this.noise2 != "")
	{
		precache_sound(this.noise2);
	}
	// sound when door stops moving
	if (this.noise3 && this.noise3 != "")
	{
		precache_sound(this.noise3);
	}

	settouch(this, secret_touch);
	setblocked(this, secret_blocked);
	this.speed = 50;
	this.use = fd_secret_use;
	this.active = ACTIVE_ACTIVE;
	if(!this.targetname || this.targetname == "")
		this.spawnflags |= DOOR_SECRET_YES_SHOOT;

	if (this.spawnflags & DOOR_SECRET_YES_SHOOT)
	{
		//this.canteamdamage = true; // TODO
		SetResourceExplicit(this, RES_HEALTH, 10000);
		this.takedamage = DAMAGE_YES;
		this.event_damage = fd_secret_damage;
	}
	this.oldorigin = this.origin;
	if (!this.wait) this.wait = 5; // seconds before closing

	this.reset = secret_reset;
	this.reset(this);
}
#endif
