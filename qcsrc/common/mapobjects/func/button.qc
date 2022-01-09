#include "button.qh"
#ifdef SVQC
// button and multiple button

void button_wait(entity this);
void button_return(entity this);

// in case button is deactivated by a relay_deactivate while it pressed down
// set both fields to -1 in button_return!!
.float wait_remaining;
.float activation_time;

void button_setactive(entity this, int astate)
{
	int oldstate = this.active;
	if (astate == ACTIVE_TOGGLE)
	{
		if (this.active == ACTIVE_ACTIVE)
			this.active = ACTIVE_NOT;
		else
			this.active = ACTIVE_ACTIVE;
	}
	else
		this.active = astate;

	if (this.active == ACTIVE_ACTIVE && oldstate == ACTIVE_NOT)
	{
		// button was deactivated while it was pressed
		if (this.wait_remaining >= 0)
		{
			this.nextthink =  this.wait_remaining + this.ltime;
			setthink(this, button_return);
		}
	}
	else if (this.active == ACTIVE_NOT && oldstate == ACTIVE_ACTIVE)
	{
		// check if button is in pressed state
		if (this.activation_time >= 0)
		{
			this.wait_remaining = this.wait - (time - this.activation_time);
		}
	}
}

void button_wait(entity this)
{
	this.state = STATE_TOP;
	if(this.wait >= 0)
	{
		this.nextthink = this.ltime + this.wait;
		setthink(this, button_return);
	}
	SUB_UseTargets(this, this.enemy, NULL);
	this.frame = 1;			// use alternate textures
}

void button_done(entity this)
{
	this.state = STATE_BOTTOM;
}

void button_return(entity this)
{
	if (this.active != ACTIVE_ACTIVE)
	{
		return;
	}
	this.state = STATE_DOWN;
	SUB_CalcMove (this, this.pos1, TSPEED_LINEAR, this.speed, button_done);
	this.frame = 0;			// use normal textures
	if (GetResource(this, RES_HEALTH))
		this.takedamage = DAMAGE_YES;	// can be shot again
	this.wait_remaining = -1;
	this.activation_time = -1;
}


void button_blocked(entity this, entity blocker)
{
	// do nothing, just don't come all the way back out
}


void button_fire(entity this)
{
	SetResourceExplicit(this, RES_HEALTH, this.max_health);
	this.takedamage = DAMAGE_NO;    // will be reset upon return

	if (this.state == STATE_UP || this.state == STATE_TOP)
		return;

	this.activation_time = time;

	if (this.noise != "")
		_sound (this, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);

	this.state = STATE_UP;
	SUB_CalcMove (this, this.pos2, TSPEED_LINEAR, this.speed, button_wait);
}

void button_reset(entity this)
{
	SetResourceExplicit(this, RES_HEALTH, this.max_health);
	setorigin(this, this.pos1);
	this.frame = 0;			// use normal textures
	this.state = STATE_BOTTOM;
	this.velocity = '0 0 0';
	this.wait_remaining = -1;
	this.activation_time = -1;
	this.active = ACTIVE_ACTIVE;
	setthink(this, func_null);
	this.nextthink = 0;
	if (GetResource(this, RES_HEALTH))
		this.takedamage = DAMAGE_YES;	// can be shot again
}

void button_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	this.enemy = actor;
	button_fire(this);
}

void button_touch(entity this, entity toucher)
{
	if (this.active != ACTIVE_ACTIVE)
		return;
	if (!toucher)
		return;
	if (!toucher.iscreature)
		return;
	if(toucher.velocity * this.movedir < 0)
		return;
	this.enemy = toucher;
	if (toucher.owner)
		this.enemy = toucher.owner;
	button_fire (this);
}

void button_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if (this.active != ACTIVE_ACTIVE)
		return;
	if(this.spawnflags & NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	if (this.spawnflags & BUTTON_DONTACCUMULATEDMG)
	{
		if (GetResource(this, RES_HEALTH) <= damage)
		{
			this.enemy = attacker;
			button_fire(this);
		}
	}
	else
	{
		TakeResource(this, RES_HEALTH, damage);
		if (GetResource(this, RES_HEALTH) <= 0)
		{
			this.enemy = attacker;
			button_fire(this);
		}
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
"noise"		sound that is played when the button is activated
*/
spawnfunc(func_button)
{
	SetMovedir(this);

	if (!InitMovingBrushTrigger(this))
		return;
	this.effects |= EF_LOWPRECISION;

	setblocked(this, button_blocked);
	this.use = button_use;

//	if (this.health == 0) // all buttons are now shootable
//		this.health = 10;
	if (GetResource(this, RES_HEALTH))
	{
		this.max_health = GetResource(this, RES_HEALTH);
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

	if(this.wait < 0 && q3compat)
		this.wait = 0.1; // compatibility for q3: -1 = return immediately

    if(this.noise != "")
        precache_sound(this.noise);

	this.draggable = drag_undraggable;

	this.setactive = button_setactive;

	this.pos1 = this.origin;
	this.pos2 = this.pos1 + this.movedir*(fabs(this.movedir*this.size) - this.lip);
    this.flags |= FL_NOTARGET;

    this.reset = button_reset;

	button_reset(this);
}
#endif
