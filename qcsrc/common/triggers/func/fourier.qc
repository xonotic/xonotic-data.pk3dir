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

void func_fourier_controller_think()
{SELFPARAM();
	vector v;
	float n, i, t;

	self.nextthink = time + 0.1;
	if(self.owner.active != ACTIVE_ACTIVE)
	{
		self.owner.velocity = '0 0 0';
		return;
	}


	n = floor((tokenize_console(self.owner.netname)) / 5);
	t = self.nextthink * self.owner.cnt + self.owner.phase * 360;

	v = self.owner.destvec;

	for(i = 0; i < n; ++i)
	{
		makevectors((t * stof(argv(i*5)) + stof(argv(i*5+1)) * 360) * '0 1 0');
		v = v + ('1 0 0' * stof(argv(i*5+2)) + '0 1 0' * stof(argv(i*5+3)) + '0 0 1' * stof(argv(i*5+4))) * self.owner.height * v_forward_y;
	}

	if(self.owner.classname == "func_fourier") // don't brake stuff if the func_fourier was killtarget'ed
		// * 10 so it will arrive in 0.1 sec
		self.owner.velocity = (v - self.owner.origin) * 10;
}

spawnfunc(func_fourier)
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
	self.destvec = self.origin;
	self.cnt = 360 / self.speed;

	self.blocked = generic_plat_blocked;
	if(self.dmg && (self.message == ""))
		self.message = " was squished";
    if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";
	if(self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;
	self.dmgtime2 = time;

	if(self.netname == "")
		self.netname = "1 0 0 0 1";

	if (!InitMovingBrushTrigger())
		return;

	self.active = ACTIVE_ACTIVE;

	// wait for targets to spawn
	controller = new(func_fourier_controller);
	controller.owner = self;
	controller.nextthink = time + 1;
	controller.think = func_fourier_controller_think;
	self.SUB_NEXTTHINK = self.SUB_LTIME + 999999999;
	self.SUB_THINK = SUB_NullThink; // for PushMove

	// Savage: Reduce bandwith, critical on e.g. nexdm02
	self.effects |= EF_LOWPRECISION;

	// TODO make a reset function for this one
}
#endif
