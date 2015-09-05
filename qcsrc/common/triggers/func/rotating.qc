#ifdef SVQC
void func_rotating_setactive(float astate)
{SELFPARAM();

	if (astate == ACTIVE_TOGGLE)
	{
		if(self.active == ACTIVE_ACTIVE)
			self.active = ACTIVE_NOT;
		else
			self.active = ACTIVE_ACTIVE;
	}
	else
		self.active = astate;

	if(self.active  == ACTIVE_NOT)
		self.avelocity = '0 0 0';
	else
		self.avelocity = self.pos1;
}

/*QUAKED spawnfunc_func_rotating (0 .5 .8) ? - - X_AXIS Y_AXIS
Brush model that spins in place on one axis (default Z).
speed   : speed to rotate (in degrees per second)
noise   : path/name of looping .wav file to play.
dmg     : Do this mutch dmg every .dmgtime intervall when blocked
dmgtime : See above.
*/

void spawnfunc_func_rotating()
{SELFPARAM();
	if (self.noise != "")
	{
		precache_sound(self.noise);
		ambientsound(self.origin, self.noise, VOL_BASE, ATTEN_IDLE);
	}

	self.active = ACTIVE_ACTIVE;
	self.setactive = func_rotating_setactive;

	if (!self.speed)
		self.speed = 100;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	if (self.spawnflags & 4) // X (untested)
		self.avelocity = '0 0 1' * self.speed;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	else if (self.spawnflags & 8) // Y (untested)
		self.avelocity = '1 0 0' * self.speed;
	// FIXME: test if this turns the right way, then remove this comment (negate as needed)
	else // Z
		self.avelocity = '0 1 0' * self.speed;

	self.pos1 = self.avelocity;

    if(self.dmg && (self.message == ""))
        self.message = " was squished";
    if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";


    if(self.dmg && (!self.dmgtime))
        self.dmgtime = 0.25;

    self.dmgtime2 = time;

	if (!InitMovingBrushTrigger())
		return;
	// no EF_LOWPRECISION here, as rounding angles is bad

    self.blocked = generic_plat_blocked;

	// wait for targets to spawn
	self.SUB_NEXTTHINK = self.SUB_LTIME + 999999999;
	self.SUB_THINK = SUB_NullThink; // for PushMove

	// TODO make a reset function for this one
}
#endif
