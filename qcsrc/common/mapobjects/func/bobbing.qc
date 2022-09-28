#include "bobbing.qh"
#ifdef SVQC
.float height;
void func_bobbing_controller_think(entity this)
{
	vector v;
	this.nextthink = time + 0.1;

	if(this.owner.active != ACTIVE_ACTIVE)
	{
		this.owner.velocity = '0 0 0';
		return;
	}

	// calculate sinewave using makevectors
	makevectors((this.nextthink * this.owner.cnt + this.owner.phase * 360) * '0 1 0');
	v = this.owner.destvec + this.owner.movedir * v_forward_y;
	if(this.owner.classname == "func_bobbing") // don't brake stuff if the func_bobbing was killtarget'ed
		// * 10 so it will arrive in 0.1 sec
		this.owner.velocity = (v - this.owner.origin) * 10;
}

/*QUAKED spawnfunc_func_bobbing (0 .5 .8) ? X_AXIS Y_AXIS
Brush model that moves back and forth on one axis (default Z).
speed : how long one cycle takes in seconds (default 4)
height : how far the cycle moves (default 32)
phase : cycle timing adjustment (0-1 as a fraction of the cycle, default 0)
noise : path/name of looping .wav file to play.
dmg : Do this mutch dmg every .dmgtime intervall when blocked
dmgtime : See above.
*/
spawnfunc(func_bobbing)
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
	// center of bobbing motion
	this.destvec = this.origin;
	// time scale to get degrees
	this.cnt = 360 / this.speed;

	this.active = ACTIVE_ACTIVE;

	this.draggable = drag_undraggable;

	// damage when blocked
	setblocked(this, generic_plat_blocked);
	if(this.dmg && (this.message == ""))
		this.message = " was squished";
	if(this.dmg && (this.message2 == ""))
		this.message2 = "was squished by";
	if(this.dmg && (!this.dmgtime))
		this.dmgtime = 0.25;
	this.dmgtime2 = time;

	// how far to bob
	if (this.spawnflags & BOBBING_XAXIS)
		this.movedir = '1 0 0' * this.height;
	else if (this.spawnflags & BOBBING_YAXIS)
		this.movedir = '0 1 0' * this.height;
	else // Z
		this.movedir = '0 0 1' * this.height;

	if (!InitMovingBrushTrigger(this))
		return;

	// wait for targets to spawn
	controller = new_pure(func_bobbing_controller);
	controller.owner = this;
	controller.nextthink = time + 1;
	setthink(controller, func_bobbing_controller_think);
	this.nextthink = this.ltime + 999999999;
	setthink(this, SUB_NullThink);

	// Savage: Reduce bandwith, critical on e.g. nexdm02
	this.effects |= EF_LOWPRECISION;

	// TODO make a reset function for this one
}
#endif
