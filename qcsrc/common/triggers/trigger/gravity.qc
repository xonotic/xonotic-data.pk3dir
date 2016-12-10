#include "gravity.qh"
#ifdef SVQC
.entity trigger_gravity_check;
void trigger_gravity_remove(entity own)
{
	if(own.trigger_gravity_check.owner == own)
	{
		UpdateCSQCProjectile(own);
		own.gravity = own.trigger_gravity_check.gravity;
		delete(own.trigger_gravity_check);
	}
	else
		backtrace("Removing a trigger_gravity_check with no valid owner");
	own.trigger_gravity_check = NULL;
}
void trigger_gravity_check_think(entity this)
{
	// This spawns when a player enters the gravity zone and checks if he left.
	// Each frame, this.count is set to 2 by trigger_gravity_touch() and decreased by 1 here.
	// It the player has left the gravity trigger, this will be allowed to reach 0 and indicate that.
	if(this.count <= 0)
	{
		if(this.owner.trigger_gravity_check == this)
			trigger_gravity_remove(this.owner);
		else
			delete(this);
		return;
	}
	else
	{
		this.count -= 1;
		this.nextthink = time;
	}
}

void trigger_gravity_use(entity this, entity actor, entity trigger)
{
	this.state = !this.state;
}

void trigger_gravity_touch(entity this, entity toucher)
{
	float g;

	if(this.state != true)
		return;

	EXACTTRIGGER_TOUCH(this, toucher);

	g = this.gravity;

	if (!(this.spawnflags & 1))
	{
		if(toucher.trigger_gravity_check)
		{
			if(this == toucher.trigger_gravity_check.enemy)
			{
				// same?
				toucher.trigger_gravity_check.count = 2; // gravity one more frame...
				return;
			}

			// compare prio
			if(this.cnt > toucher.trigger_gravity_check.enemy.cnt)
				trigger_gravity_remove(toucher);
			else
				return;
		}
		toucher.trigger_gravity_check = spawn();
		toucher.trigger_gravity_check.enemy = this;
		toucher.trigger_gravity_check.owner = toucher;
		toucher.trigger_gravity_check.gravity = toucher.gravity;
		setthink(toucher.trigger_gravity_check, trigger_gravity_check_think);
		toucher.trigger_gravity_check.nextthink = time;
		toucher.trigger_gravity_check.count = 2;
		if(toucher.gravity)
			g *= toucher.gravity;
	}

	if (toucher.gravity != g)
	{
		toucher.gravity = g;
		if(this.noise != "")
			_sound (toucher, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
		UpdateCSQCProjectile(this.owner);
	}
}

spawnfunc(trigger_gravity)
{
	if(this.gravity == 1)
		return;

	EXACTTRIGGER_INIT;
	settouch(this, trigger_gravity_touch);
	if(this.noise != "")
		precache_sound(this.noise);

	this.state = true;
	IFTARGETED
	{
		this.use = trigger_gravity_use;
		if(this.spawnflags & 2)
			this.state = false;
	}
}
#endif
