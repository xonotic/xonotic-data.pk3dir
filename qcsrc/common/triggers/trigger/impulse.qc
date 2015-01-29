#ifdef SVQC
// tZorks trigger impulse / gravity
.float radius;
.float falloff;
.float strength;
.float lastpushtime;

// targeted (directional) mode
void trigger_impulse_touch1()
{
	entity targ;
    float pushdeltatime;
    float str;

	if (self.active != ACTIVE_ACTIVE)
		return;

	if (!isPushable(other))
		return;

	EXACTTRIGGER_TOUCH;

    targ = find(world, targetname, self.target);
    if(!targ)
    {
        objerror("trigger_force without a (valid) .target!\n");
        remove(self);
        return;
    }

    str = min(self.radius, vlen(self.origin - other.origin));

    if(self.falloff == 1)
        str = (str / self.radius) * self.strength;
    else if(self.falloff == 2)
        str = (1 - (str / self.radius)) * self.strength;
    else
        str = self.strength;

    pushdeltatime = time - other.lastpushtime;
    if (pushdeltatime > 0.15) pushdeltatime = 0;
    other.lastpushtime = time;
    if(!pushdeltatime) return;

    other.velocity = other.velocity + normalize(targ.origin - self.origin) * str * pushdeltatime;
    other.flags &= ~FL_ONGROUND;
    UpdateCSQCProjectile(other);
}

// Directionless (accelerator/decelerator) mode
void trigger_impulse_touch2()
{
    float pushdeltatime;

	if (self.active != ACTIVE_ACTIVE)
		return;

	if (!isPushable(other))
		return;

	EXACTTRIGGER_TOUCH;

    pushdeltatime = time - other.lastpushtime;
    if (pushdeltatime > 0.15) pushdeltatime = 0;
    other.lastpushtime = time;
    if(!pushdeltatime) return;

    // div0: ticrate independent, 1 = identity (not 20)
    other.velocity = other.velocity * pow(self.strength, pushdeltatime);
    UpdateCSQCProjectile(other);
}

// Spherical (gravity/repulsor) mode
void trigger_impulse_touch3()
{
    float pushdeltatime;
    float str;

	if (self.active != ACTIVE_ACTIVE)
		return;

	if (!isPushable(other))
		return;

	EXACTTRIGGER_TOUCH;

    pushdeltatime = time - other.lastpushtime;
    if (pushdeltatime > 0.15) pushdeltatime = 0;
    other.lastpushtime = time;
    if(!pushdeltatime) return;

    setsize(self, '-1 -1 -1' * self.radius,'1 1 1' * self.radius);

	str = min(self.radius, vlen(self.origin - other.origin));

    if(self.falloff == 1)
        str = (1 - str / self.radius) * self.strength; // 1 in the inside
    else if(self.falloff == 2)
        str = (str / self.radius) * self.strength; // 0 in the inside
    else
        str = self.strength;

    other.velocity = other.velocity + normalize(other.origin - self.origin) * str * pushdeltatime;
    UpdateCSQCProjectile(other);
}

/*QUAKED spawnfunc_trigger_impulse (.5 .5 .5) ?
-------- KEYS --------
target : If this is set, this points to the spawnfunc_target_position to which the player will get pushed.
         If not, this trigger acts like a damper/accelerator field.

strength : This is how mutch force to add in the direction of .target each second
           when .target is set. If not, this is hoe mutch to slow down/accelerate
           someting cought inside this trigger. (1=no change, 0,5 half speed rougthly each tic, 2 = doubble)

radius   : If set, act as a spherical device rather then a liniar one.

falloff : 0 = none, 1 = liniar, 2 = inverted liniar

-------- NOTES --------
Use a brush textured with common/origin in the trigger entity to determine the origin of the force
in directional and sperical mode. For damper/accelerator mode this is not nessesary (and has no effect).
*/

void spawnfunc_trigger_impulse()
{
	self.active = ACTIVE_ACTIVE;

	EXACTTRIGGER_INIT;
    if(self.radius)
    {
        if(!self.strength) self.strength = 2000 * autocvar_g_triggerimpulse_radial_multiplier;
        setorigin(self, self.origin);
        setsize(self, '-1 -1 -1' * self.radius,'1 1 1' * self.radius);
        self.touch = trigger_impulse_touch3;
    }
    else
    {
        if(self.target)
        {
            if(!self.strength) self.strength = 950 * autocvar_g_triggerimpulse_directional_multiplier;
            self.touch = trigger_impulse_touch1;
        }
        else
        {
            if(!self.strength) self.strength = 0.9;
			self.strength = pow(self.strength, autocvar_g_triggerimpulse_accel_power) * autocvar_g_triggerimpulse_accel_multiplier;
            self.touch = trigger_impulse_touch2;
        }
    }
}
#endif
