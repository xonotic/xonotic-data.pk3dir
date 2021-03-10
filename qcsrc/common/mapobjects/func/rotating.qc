#include "rotating.qh"
#ifdef SVQC

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
	{
		this.avelocity = '0 0 0';
		stopsound(this, CH_AMBIENT_SINGLE);
	}
	else
	{
		this.avelocity = this.pos1;
		if(this.noise && this.noise != "")
		{
			_sound(this, CH_AMBIENT_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE);
		}
	}
}

void func_rotating_reset(entity this)
{
	// TODO: reset angles as well?

	if(this.spawnflags & FUNC_ROTATING_STARTOFF)
	{
		this.setactive(this, ACTIVE_NOT);
	}
	else
	{
		this.setactive(this, ACTIVE_ACTIVE);
	}
}

void func_rotating_init_for_player(entity this, entity player)
{
	if (this.noise && this.noise != "" && this.active == ACTIVE_ACTIVE && IS_REAL_CLIENT(player))
	{
		msg_entity = player;
		soundto (MSG_ONE, this, CH_AMBIENT_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE, 0);
	}
}

/*QUAKED spawnfunc_func_rotating (0 .5 .8) ? - - X_AXIS Y_AXIS
Brush model that spins in place on one axis (default Z).
speed   : speed to rotate (in degrees per second)
noise   : path/name of looping .wav file to play.
dmg     : Do this much damage every .dmgtime interval when blocked
dmgtime : See above.
*/

spawnfunc(func_rotating)
{
	if (this.noise && this.noise != "")
	{
		precache_sound(this.noise);
	}

	this.setactive = func_rotating_setactive;

	if (!this.speed)
		this.speed = 100;
	if (this.spawnflags & FUNC_ROTATING_XAXIS)
		this.avelocity = '0 0 1' * this.speed;
	else if (this.spawnflags & FUNC_ROTATING_YAXIS)
		this.avelocity = '1 0 0' * this.speed;
	else // Z
		this.avelocity = '0 1 0' * this.speed;

	this.pos1 = this.avelocity;

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
	this.reset(this);

	// maybe send sound to new players
	IL_PUSH(g_initforplayer, this);
	this.init_for_player = func_rotating_init_for_player;
}
#endif
