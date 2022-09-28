#include "fourier.qh"
#ifdef SVQC
/*QUAKED spawnfunc_func_fourier (0 .5 .8) ?
Brush model that moves in a pattern of added up sine waves, can be used e.g. for circular motions.
netname: list of <frequencymultiplier> <phase> <x> <y> <z> quadruples, separated by spaces; note that phase 0 represents a sine wave, and phase 0.25 a cosine wave (by default, it uses 1 0 0 0 1, to match func_bobbing's defaults
speed: how long one cycle of frequency multiplier 1 in seconds (default 4)
height: amplitude modifier (default 32)
phase: cycle timing adjustment (0-1 as a fraction of the cycle, default 0)
noise: path/name of looping .wav file to play.
dmg: Do this mutch dmg every .dmgtime intervall when blocked
dmgtime: See above.
*/

void func_fourier_controller_think(entity this)
{
	vector v;
	float n, i, t;

	this.nextthink = time + 0.1;
	if(this.owner.active != ACTIVE_ACTIVE)
	{
		this.owner.velocity = '0 0 0';
		return;
	}


	n = floor((tokenize_console(this.owner.netname)) / 5);
	t = this.nextthink * this.owner.cnt + this.owner.phase * 360;

	v = this.owner.destvec;

	for(i = 0; i < n; ++i)
	{
		makevectors((t * stof(argv(i*5)) + stof(argv(i*5+1)) * 360) * '0 1 0');
		v = v + ('1 0 0' * stof(argv(i*5+2)) + '0 1 0' * stof(argv(i*5+3)) + '0 0 1' * stof(argv(i*5+4))) * this.owner.height * v_forward_y;
	}

	if(this.owner.classname == "func_fourier") // don't brake stuff if the func_fourier was killtarget'ed
		// * 10 so it will arrive in 0.1 sec
		this.owner.velocity = (v - this.owner.origin) * 10;
}

spawnfunc(func_fourier)
{
	entity controller;
	if (this.noise != "")
	{
		precache_sound(this.noise);
		soundto(MSG_INIT, this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_IDLE, 0);
	}

	if (!this.speed)
		this.speed = 4;
	if (!this.height)
		this.height = 32;
	this.destvec = this.origin;
	this.cnt = 360 / this.speed;

	setblocked(this, generic_plat_blocked);
	if(this.dmg && (this.message == ""))
		this.message = " was squished";
	if(this.dmg && (this.message2 == ""))
		this.message2 = "was squished by";
	if(this.dmg && (!this.dmgtime))
		this.dmgtime = 0.25;
	this.dmgtime2 = time;

	if(this.netname == "")
		this.netname = "1 0 0 0 1";

	if (!InitMovingBrushTrigger(this))
		return;

	this.active = ACTIVE_ACTIVE;

	// wait for targets to spawn
	controller = new_pure(func_fourier_controller);
	controller.owner = this;
	controller.nextthink = time + 1;
	setthink(controller, func_fourier_controller_think);
	this.nextthink = this.ltime + 999999999;
	setthink(this, SUB_NullThink); // for PushMove

	// Savage: Reduce bandwith, critical on e.g. nexdm02
	this.effects |= EF_LOWPRECISION;

	// TODO make a reset function for this one
}
#endif
