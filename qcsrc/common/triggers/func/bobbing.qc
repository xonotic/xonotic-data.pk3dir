#ifdef SVQC
.float height;
void func_bobbing_controller_think()
{SELFPARAM();
	vector v;
	self.nextthink = time + 0.1;

	if(self.owner.active != ACTIVE_ACTIVE)
	{
		self.owner.velocity = '0 0 0';
		return;
	}

	// calculate sinewave using makevectors
	makevectors((self.nextthink * self.owner.cnt + self.owner.phase * 360) * '0 1 0');
	v = self.owner.destvec + self.owner.movedir * v_forward_y;
	if(self.owner.classname == "func_bobbing") // don't brake stuff if the func_bobbing was killtarget'ed
		// * 10 so it will arrive in 0.1 sec
		self.owner.velocity = (v - self.owner.SUB_ORIGIN) * 10;
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
	if (self.noise != "")
	{
		precache_sound(self.noise);
		soundto(MSG_INIT, self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_IDLE);
	}
	if (!self.speed)
		self.speed = 4;
	if (!self.height)
		self.height = 32;
	// center of bobbing motion
	self.destvec = self.origin;
	// time scale to get degrees
	self.cnt = 360 / self.speed;

	self.active = ACTIVE_ACTIVE;

	// damage when blocked
	self.blocked = generic_plat_blocked;
	if(self.dmg && (self.message == ""))
		self.message = " was squished";
    if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";
	if(self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;
	self.dmgtime2 = time;

	// how far to bob
	if (self.spawnflags & 1) // X
		self.movedir = '1 0 0' * self.height;
	else if (self.spawnflags & 2) // Y
		self.movedir = '0 1 0' * self.height;
	else // Z
		self.movedir = '0 0 1' * self.height;

	if (!InitMovingBrushTrigger())
		return;

	// wait for targets to spawn
	controller = spawn();
	controller.classname = "func_bobbing_controller";
	controller.owner = self;
	controller.nextthink = time + 1;
	controller.think = func_bobbing_controller_think;
	self.SUB_NEXTTHINK = self.SUB_LTIME + 999999999;
	self.SUB_THINK = SUB_NullThink;

	// Savage: Reduce bandwith, critical on e.g. nexdm02
	self.effects |= EF_LOWPRECISION;

	// TODO make a reset function for this one
}
#endif
