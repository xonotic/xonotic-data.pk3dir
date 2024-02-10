#include "impulse.qh"
// targeted (directional) mode
void trigger_impulse_touch_directional(entity this, entity toucher)
{
	entity targ;
	float pushdeltatime;
	float str;

	if (this.active != ACTIVE_ACTIVE)
		return;

	if (!isPushable(toucher))
		return;

	EXACTTRIGGER_TOUCH(this, toucher);

	targ = find(NULL, targetname, this.target);
	if(!targ)
	{
		objerror(this, "trigger_force without a (valid) .target!\n");
		delete(this);
		return;
	}

	// falloff is not supported because radius is always 0 in directional mode
	str = this.strength;

	pushdeltatime = time - toucher.lastpushtime;
	if (pushdeltatime > IMPULSE_MAX_PUSHDELTATIME)
	{
		pushdeltatime = 0;
	}
	toucher.lastpushtime = time;
	if(!pushdeltatime)
	{
		return;
	}

	if(this.spawnflags & IMPULSE_DIRECTIONAL_SPEEDTARGET)
	{
		float addspeed = str - toucher.velocity * normalize(targ.origin - this.origin);
		if (addspeed > 0)
		{
			float accelspeed = min(IMPULSE_DIRECTIONAL_MAX_ACCEL_FACTOR * pushdeltatime * str, addspeed);
			toucher.velocity += accelspeed * normalize(targ.origin - this.origin);
		}
	}
	else
		toucher.velocity = toucher.velocity + normalize(targ.origin - this.origin) * str * pushdeltatime;

	UNSET_ONGROUND(toucher);

#ifdef SVQC
	UpdateCSQCProjectile(toucher);
#endif
}

// Directionless (accelerator/decelerator) mode
void trigger_impulse_touch_accel(entity this, entity toucher)
{
	float pushdeltatime;

	if (this.active != ACTIVE_ACTIVE)
		return;

	if (!isPushable(toucher))
		return;

	EXACTTRIGGER_TOUCH(this, toucher);

	pushdeltatime = time - toucher.lastpushtime;
	if (pushdeltatime > IMPULSE_MAX_PUSHDELTATIME)
	{
		pushdeltatime = 0;
	}
	toucher.lastpushtime = time;
	if(!pushdeltatime)
	{
		return;
	}

	// div0: ticrate independent, 1 = identity (not 20)
	toucher.velocity = toucher.velocity * (this.strength ** pushdeltatime);

#ifdef SVQC
	UpdateCSQCProjectile(toucher);
#endif
}

// Spherical (gravity/repulsor) mode
void trigger_impulse_touch_radial(entity this, entity toucher)
{
	float pushdeltatime;
	float str;

	if (this.active != ACTIVE_ACTIVE)
		return;

	if (!isPushable(toucher))
		return;

	EXACTTRIGGER_TOUCH(this, toucher);

	pushdeltatime = time - toucher.lastpushtime;
	if (pushdeltatime > IMPULSE_MAX_PUSHDELTATIME)
	{
		pushdeltatime = 0;
	}
	toucher.lastpushtime = time;
	if(!pushdeltatime)
	{
		return;
	}

	setsize(this, '-1 -1 -1' * this.radius,'1 1 1' * this.radius);

	str = min(this.radius, vlen(this.origin - toucher.origin));

	if(this.falloff == FALLOFF_LINEAR)
		str = (1 - str / this.radius) * this.strength; // 1 in the inside
	else if(this.falloff == FALLOFF_LINEAR_INV)
		str = (str / this.radius) * this.strength; // 0 in the inside
	else
		str = this.strength;

	toucher.velocity = toucher.velocity + normalize(toucher.origin - this.origin) * str * pushdeltatime;

#ifdef SVQC
	UpdateCSQCProjectile(toucher);
#endif
}

REGISTER_NET_LINKED(ENT_CLIENT_TRIGGER_IMPULSE)

/*QUAKED spawnfunc_trigger_impulse (.5 .5 .5) ?
Force field
-------- KEYS --------
target : If this is set, this points to the spawnfunc_target_position to which the player will get pushed.
		 If not, this trigger acts like a damper/accelerator field.

strength : This is how much force to add in the direction of .target each second
		   when .target is set. If not, this is how much to slow down/accelerate
		   something cought inside this trigger. (1=no change, 0,5 half speed rougthly each tic, 2 = doubble)

radius   : If set, act as a spherical device rather then a linear one.

falloff : 0 = none, 1 = liniar, 2 = inverted liniar

-------- NOTES --------
Use a brush textured with common/origin in the trigger entity to determine the origin of the force
in directional and sperical mode. For damper/accelerator mode this is not nessesary (and has no effect).
*/
#ifdef SVQC
bool trigger_impulse_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRIGGER_IMPULSE);

	WriteByte(MSG_ENTITY, this.spawnflags);
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
	WarpZoneLib_ExactTrigger_Init(this, false);
	BITSET_ASSIGN(this.effects, EF_NODEPTHTEST);

	if(this.radius)
	{
		if(!this.strength)
		{
			this.strength = IMPULSE_DEFAULT_RADIAL_STRENGTH * autocvar_g_triggerimpulse_radial_multiplier;
		}
		setorigin(this, this.origin);
		setsize(this, '-1 -1 -1' * this.radius,'1 1 1' * this.radius);
		settouch(this, trigger_impulse_touch_radial);
	}
	else
	{
		if(this.target)
		{
			if(!this.strength)
			{
				this.strength = IMPULSE_DEFAULT_DIRECTIONAL_STRENGTH * autocvar_g_triggerimpulse_directional_multiplier;
			}
			settouch(this, trigger_impulse_touch_directional);
		}
		else
		{
			if(!this.strength)
			{
				this.strength = IMPULSE_DEFAULT_ACCEL_STRENGTH;
			}
			this.strength = (this.strength ** autocvar_g_triggerimpulse_accel_power) * autocvar_g_triggerimpulse_accel_multiplier;
			settouch(this, trigger_impulse_touch_accel);
		}
	}

	trigger_impulse_link(this);
}
#elif defined(CSQC)
NET_HANDLE(ENT_CLIENT_TRIGGER_IMPULSE, bool isnew)
{
	this.spawnflags = ReadByte();
	this.radius = ReadCoord();
	this.strength = ReadCoord();
	this.falloff = ReadByte();
	this.active = ReadByte();

	trigger_common_read(this, true);
	return = true;

	this.solid = SOLID_TRIGGER;
	this.entremove = trigger_remove_generic;
	this.move_time = time;

	if (this.radius)
	{
		settouch(this, trigger_impulse_touch_radial);
	}
	else if (this.target)
	{
		settouch(this, trigger_impulse_touch_directional);
	}
	else
	{
		settouch(this, trigger_impulse_touch_accel);
	}
}
#endif
