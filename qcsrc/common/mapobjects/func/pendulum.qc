#include "pendulum.qh"
#ifdef SVQC
.float freq;
void func_pendulum_controller_think(entity this)
{
	float v;
	this.nextthink = time + 0.1;

	if (!(this.owner.active == ACTIVE_ACTIVE))
	{
		this.owner.avelocity_x = 0;
		return;
	}

	// calculate sinewave using makevectors
	makevectors((this.nextthink * this.owner.freq + this.owner.phase) * '0 360 0');
	v = this.owner.speed * v_forward_y + this.cnt;
	if(this.owner.classname == "func_pendulum") // don't brake stuff if the func_bobbing was killtarget'ed
	{
		// * 10 so it will arrive in 0.1 sec
		this.owner.avelocity_z = (remainder(v - this.owner.angles_z, 360)) * 10;
	}
}

spawnfunc(func_pendulum)
{
	entity controller;
	if (this.noise != "")
	{
		precache_sound(this.noise);
		soundto(MSG_INIT, this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE, 0);
	}

	this.active = ACTIVE_ACTIVE;

	// keys: angle, speed, phase, noise, freq

	if(!this.speed)
		this.speed = 30;
	// not initializing this.dmg to 2, to allow damageless pendulum

	if(this.dmg && (this.message == ""))
		this.message = " was squished";
	if(this.dmg && (this.message2 == ""))
		this.message2 = "was squished by";
	if(this.dmg && (!this.dmgtime))
		this.dmgtime = 0.25;
	this.dmgtime2 = time;

	setblocked(this, generic_plat_blocked);

	this.avelocity_z = 0.0000001;
	if (!InitMovingBrushTrigger(this))
		return;

	if(!this.freq)
	{
		// find pendulum length (same formula as Q3A)
		this.freq = 1 / (M_PI * 2) * sqrt(autocvar_sv_gravity / (3 * max(8, fabs(this.mins_z))));
	}

	// copy initial angle
	this.cnt = this.angles_z;

	// wait for targets to spawn
	controller = new_pure(func_pendulum_controller);
	controller.owner = this;
	controller.nextthink = time + 1;
	setthink(controller, func_pendulum_controller_think);
	this.nextthink = this.ltime + 999999999;
	setthink(this, SUB_NullThink); // for PushMove

	//this.effects |= EF_LOWPRECISION;

	// TODO make a reset function for this one
}
#endif
