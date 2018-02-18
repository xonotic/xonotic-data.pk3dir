#include "rotating.qh"
#ifdef SVQC
const int FUNC_ROTATING_STARTOFF = BIT(4);

void func_rotating_setactive(entity this, int astate)
{
	if (astate == ACTIVE_TOGGLE)
	{
		if(this.active == ACTIVE_ACTIVE)
			this.active = ACTIVE_NOT;
		else
			this.active = ACTIVE_ACTIVE;
	}
	else
		this.active = astate;

	if(this.active  == ACTIVE_NOT)
		this.avelocity = '0 0 0';
	else
		this.avelocity = this.pos1;
}

void func_rotating_reset(entity this)
{
	// TODO: reset angles as well?

	if(this.spawnflags & FUNC_ROTATING_STARTOFF)
	{
		this.avelocity = '0 0 0';
		this.active = ACTIVE_NOT;
	}
	else
	{
		this.avelocity = this.pos1;
		this.active = ACTIVE_ACTIVE;
	}
}

/*QUAKED spawnfunc_func_rotating (0 .5 .8) ? - - X_AXIS Y_AXIS
Brush model that spins in place on one axis (default Z).
speed   : speed to rotate (in degrees per second)
noise   : path/name of looping .wav file to play.
dmg     : Do this mutch dmg every .dmgtime intervall when blocked
dmgtime : See above.
*/

spawnfunc(func_rotating)
{
	if (this.noise != "")
	{
		precache_sound(this.noise);
		ambientsound(this.origin, this.noise, VOL_BASE, ATTEN_IDLE);
	}

	this.setactive = func_rotating_setactive;

	if (!this.speed)
		this.speed = 100;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	if (this.spawnflags & BIT(2)) // X (untested)
		this.avelocity = '0 0 1' * this.speed;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	else if (this.spawnflags & BIT(3)) // Y (untested)
		this.avelocity = '1 0 0' * this.speed;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	else // Z
		this.avelocity = '0 1 0' * this.speed;

	this.pos1 = this.avelocity;

	// do this after setting pos1, so we can safely reactivate the func_rotating
	if(this.spawnflags & FUNC_ROTATING_STARTOFF)
	{
		this.avelocity = '0 0 0';
		this.active = ACTIVE_NOT;
	}
	else
		this.active = ACTIVE_ACTIVE;

    if(this.dmg && (this.message == ""))
        this.message = " was squished";
    if(this.dmg && (this.message2 == ""))
		this.message2 = "was squished by";


    if(this.dmg && (!this.dmgtime))
        this.dmgtime = 0.25;

    this.dmgtime2 = time;

	if (!InitMovingBrushTrigger(this))
		return;
	// no EF_LOWPRECISION here, as rounding angles is bad

    setblocked(this, generic_plat_blocked);

	// wait for targets to spawn
	this.nextthink = this.ltime + 999999999;
	setthink(this, SUB_NullThink); // for PushMove

	this.reset = func_rotating_reset;
}
#endif
