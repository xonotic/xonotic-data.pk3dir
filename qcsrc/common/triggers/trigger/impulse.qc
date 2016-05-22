// targeted (directional) mode
void trigger_impulse_touch1()
{SELFPARAM();
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

#ifdef SVQC
	str = min(self.radius, vlen(self.origin - other.origin));
#elif defined(CSQC)
	str = min(self.radius, vlen(self.origin - other.move_origin));
#endif

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

	if(self.spawnflags & 64)
	{
#ifdef SVQC
		float addspeed = str - other.velocity * normalize(targ.origin - self.origin);
		if (addspeed > 0)
		{
			float accelspeed = min(8 * pushdeltatime * str, addspeed);
			other.velocity += accelspeed * normalize(targ.origin - self.origin);
		}
#elif defined(CSQC)
		float addspeed = str - other.move_velocity * normalize(targ.origin - self.origin);
		if (addspeed > 0)
		{
			float accelspeed = min(8 * pushdeltatime * str, addspeed);
			other.move_velocity += accelspeed * normalize(targ.origin - self.origin);
		}
#endif
	}
	else
#ifdef SVQC
		other.velocity = other.velocity + normalize(targ.origin - self.origin) * str * pushdeltatime;
#elif defined(CSQC)
		other.move_velocity = other.move_velocity + normalize(targ.origin - self.origin) * str * pushdeltatime;
#endif

#ifdef SVQC
	UNSET_ONGROUND(other);

	UpdateCSQCProjectile(other);
#elif defined(CSQC)
	other.move_flags &= ~FL_ONGROUND;
#endif
}

// Directionless (accelerator/decelerator) mode
void trigger_impulse_touch2()
{SELFPARAM();
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
#ifdef SVQC
	other.velocity = other.velocity * pow(self.strength, pushdeltatime);

	UpdateCSQCProjectile(other);
#elif defined(CSQC)
	other.move_velocity = other.move_velocity * pow(self.strength, pushdeltatime);
#endif
}

// Spherical (gravity/repulsor) mode
void trigger_impulse_touch3()
{SELFPARAM();
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

#ifdef SVQC
	str = min(self.radius, vlen(self.origin - other.origin));
#elif defined(CSQC)
	str = min(self.radius, vlen(self.origin - other.move_origin));
#endif

	if(self.falloff == 1)
		str = (1 - str / self.radius) * self.strength; // 1 in the inside
	else if(self.falloff == 2)
		str = (str / self.radius) * self.strength; // 0 in the inside
	else
		str = self.strength;

#ifdef SVQC
	other.velocity = other.velocity + normalize(other.origin - self.origin) * str * pushdeltatime;

	UpdateCSQCProjectile(other);
#elif defined(CSQC)
	other.move_velocity = other.move_velocity + normalize(other.move_origin - self.origin) * str * pushdeltatime;
#endif
}

REGISTER_NET_LINKED(ENT_CLIENT_TRIGGER_IMPULSE)

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
#ifdef SVQC
bool trigger_impulse_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRIGGER_IMPULSE);

	WriteInt24_t(MSG_ENTITY, this.spawnflags);
	WriteCoord(MSG_ENTITY, this.radius);
	WriteCoord(MSG_ENTITY, this.strength);
	WriteByte(MSG_ENTITY, this.falloff);
	WriteByte(MSG_ENTITY, this.active);

	trigger_common_write(this, true);

	return true;
}

void trigger_impulse_link(entity this)
{
	trigger_link(this, trigger_impulse_send);
}

spawnfunc(trigger_impulse)
{
	this.active = ACTIVE_ACTIVE;

	trigger_init(this);

	if(this.radius)
	{
		if(!this.strength) this.strength = 2000 * autocvar_g_triggerimpulse_radial_multiplier;
		setorigin(this, this.origin);
		setsize(this, '-1 -1 -1' * this.radius,'1 1 1' * this.radius);
		settouch(this, trigger_impulse_touch3);
	}
	else
	{
		if(this.target)
		{
			if(!this.strength) this.strength = 950 * autocvar_g_triggerimpulse_directional_multiplier;
			settouch(this, trigger_impulse_touch1);
		}
		else
		{
			if(!this.strength) this.strength = 0.9;
			this.strength = pow(this.strength, autocvar_g_triggerimpulse_accel_power) * autocvar_g_triggerimpulse_accel_multiplier;
			settouch(this, trigger_impulse_touch2);
		}
	}

	trigger_impulse_link(this);
}
#elif defined(CSQC)
NET_HANDLE(ENT_CLIENT_TRIGGER_IMPULSE, bool isnew)
{
	this.spawnflags = ReadInt24_t();
	this.radius = ReadCoord();
	this.strength = ReadCoord();
	this.falloff = ReadByte();
	this.active = ReadByte();

	trigger_common_read(this, true);
	return = true;

	this.classname = "trigger_impulse";
	this.solid = SOLID_TRIGGER;
	this.entremove = trigger_remove_generic;
	this.move_time = time;

	if(this.radius) { this.move_touch = trigger_impulse_touch3; }
	else if(this.target) { this.move_touch = trigger_impulse_touch1; }
	else { this.move_touch = trigger_impulse_touch2; }
}
#endif
