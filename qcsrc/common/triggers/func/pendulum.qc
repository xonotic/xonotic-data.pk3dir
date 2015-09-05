#ifdef SVQC
.float freq;
void func_pendulum_controller_think()
{SELFPARAM();
	float v;
	self.nextthink = time + 0.1;

	if (!(self.owner.active == ACTIVE_ACTIVE))
	{
		self.owner.avelocity_x = 0;
		return;
	}

	// calculate sinewave using makevectors
	makevectors((self.nextthink * self.owner.freq + self.owner.phase) * '0 360 0');
	v = self.owner.speed * v_forward_y + self.cnt;
	if(self.owner.classname == "func_pendulum") // don't brake stuff if the func_bobbing was killtarget'ed
	{
		// * 10 so it will arrive in 0.1 sec
		self.owner.avelocity_z = (remainder(v - self.owner.angles_z, 360)) * 10;
	}
}

void spawnfunc_func_pendulum()
{SELFPARAM();
	entity controller;
	if (self.noise != "")
	{
		precache_sound(self.noise);
		soundto(MSG_INIT, self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_IDLE);
	}

	self.active = ACTIVE_ACTIVE;

	// keys: angle, speed, phase, noise, freq

	if(!self.speed)
		self.speed = 30;
	// not initializing self.dmg to 2, to allow damageless pendulum

	if(self.dmg && (self.message == ""))
		self.message = " was squished";
	if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";
	if(self.dmg && (!self.dmgtime))
		self.dmgtime = 0.25;
	self.dmgtime2 = time;

	self.blocked = generic_plat_blocked;

	self.avelocity_z = 0.0000001;
	if (!InitMovingBrushTrigger())
		return;

	if(!self.freq)
	{
		// find pendulum length (same formula as Q3A)
		self.freq = 1 / (M_PI * 2) * sqrt(autocvar_sv_gravity / (3 * max(8, fabs(self.mins_z))));
	}

	// copy initial angle
	self.cnt = self.angles_z;

	// wait for targets to spawn
	controller = spawn();
	controller.classname = "func_pendulum_controller";
	controller.owner = self;
	controller.nextthink = time + 1;
	controller.think = func_pendulum_controller_think;
	self.nextthink = self.SUB_LTIME + 999999999;
	self.SUB_THINK = SUB_NullThink; // for PushMove

	//self.effects |= EF_LOWPRECISION;

	// TODO make a reset function for this one
}
#endif
