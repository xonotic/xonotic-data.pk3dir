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

	if(self.spawnflags & 64)
	{
		float addspeed = str - other.velocity * normalize(targ.origin - self.origin);
		if (addspeed > 0)
		{
			float accelspeed = min(8 * pushdeltatime * str, addspeed);
			other.velocity += accelspeed * normalize(targ.origin - self.origin);
		}
	}
	else
		other.velocity = other.velocity + normalize(targ.origin - self.origin) * str * pushdeltatime;
	other.flags &= ~FL_ONGROUND;
#ifdef SVQC
	UpdateCSQCProjectile(other);
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
	other.velocity = other.velocity * pow(self.strength, pushdeltatime);
#ifdef SVQC
	UpdateCSQCProjectile(other);
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

	str = min(self.radius, vlen(self.origin - other.origin));

	if(self.falloff == 1)
		str = (1 - str / self.radius) * self.strength; // 1 in the inside
	else if(self.falloff == 2)
		str = (str / self.radius) * self.strength; // 0 in the inside
	else
		str = self.strength;

	other.velocity = other.velocity + normalize(other.origin - self.origin) * str * pushdeltatime;
#ifdef SVQC
	UpdateCSQCProjectile(other);
#endif
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
#ifdef SVQC
bool trigger_impulse_send(entity to, int sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_TRIGGER_IMPULSE);

	WriteCoord(MSG_ENTITY, self.radius);
	WriteCoord(MSG_ENTITY, self.strength);
	WriteByte(MSG_ENTITY, self.falloff);
	WriteByte(MSG_ENTITY, self.active);

	trigger_common_write(true);

	return true;
}

void trigger_impulse_link()
{
	//Net_LinkEntity(self, 0, false, trigger_impulse_send);
}

spawnfunc(trigger_impulse)
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

	trigger_impulse_link();
}
#elif defined(CSQC)
void ent_trigger_impulse()
{SELFPARAM();
	self.radius = ReadCoord();
	self.strength = ReadCoord();
	self.falloff = ReadByte();
	self.active = ReadByte();

	trigger_common_read(true);


	self.classname = "trigger_impulse";
	self.solid = SOLID_TRIGGER;
	self.entremove = trigger_remove_generic;
	self.draw = trigger_draw_generic;
	self.drawmask = MASK_NORMAL;
	self.move_time = time;

	if(self.radius) { self.trigger_touch = trigger_impulse_touch3; }
	else if(self.target) { self.trigger_touch = trigger_impulse_touch1; }
	else { self.trigger_touch = trigger_impulse_touch2; }
}
#endif
