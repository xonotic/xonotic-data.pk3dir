#ifdef SVQC
.entity trigger_gravity_check;
void trigger_gravity_remove(entity own)
{
	if(own.trigger_gravity_check.owner == own)
	{
		UpdateCSQCProjectile(own);
		own.gravity = own.trigger_gravity_check.gravity;
		remove(own.trigger_gravity_check);
	}
	else
		backtrace("Removing a trigger_gravity_check with no valid owner");
	own.trigger_gravity_check = world;
}
void trigger_gravity_check_think()
{SELFPARAM();
	// This spawns when a player enters the gravity zone and checks if he left.
	// Each frame, self.count is set to 2 by trigger_gravity_touch() and decreased by 1 here.
	// It the player has left the gravity trigger, this will be allowed to reach 0 and indicate that.
	if(self.count <= 0)
	{
		if(self.owner.trigger_gravity_check == self)
			trigger_gravity_remove(self.owner);
		else
			remove(self);
		return;
	}
	else
	{
		self.count -= 1;
		self.nextthink = time;
	}
}

void trigger_gravity_use()
{SELFPARAM();
	self.state = !self.state;
}

void trigger_gravity_touch()
{SELFPARAM();
	float g;

	if(self.state != true)
		return;

	EXACTTRIGGER_TOUCH;

	g = self.gravity;

	if (!(self.spawnflags & 1))
	{
		if(other.trigger_gravity_check)
		{
			if(self == other.trigger_gravity_check.enemy)
			{
				// same?
				other.trigger_gravity_check.count = 2; // gravity one more frame...
				return;
			}

			// compare prio
			if(self.cnt > other.trigger_gravity_check.enemy.cnt)
				trigger_gravity_remove(other);
			else
				return;
		}
		other.trigger_gravity_check = spawn();
		other.trigger_gravity_check.enemy = self;
		other.trigger_gravity_check.owner = other;
		other.trigger_gravity_check.gravity = other.gravity;
		other.trigger_gravity_check.think = trigger_gravity_check_think;
		other.trigger_gravity_check.nextthink = time;
		other.trigger_gravity_check.count = 2;
		if(other.gravity)
			g *= other.gravity;
	}

	if (other.gravity != g)
	{
		other.gravity = g;
		if(self.noise != "")
			_sound (other, CH_TRIGGER, self.noise, VOL_BASE, ATTEN_NORM);
		UpdateCSQCProjectile(self.owner);
	}
}

void spawnfunc_trigger_gravity()
{SELFPARAM();
	if(self.gravity == 1)
		return;

	EXACTTRIGGER_INIT;
	self.touch = trigger_gravity_touch;
	if(self.noise != "")
		precache_sound(self.noise);

	self.state = true;
	IFTARGETED
	{
		self.use = trigger_gravity_use;
		if(self.spawnflags & 2)
			self.state = false;
	}
}
#endif
