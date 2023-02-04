#include "speed.qh"

#define XYZ_ARRAY(name) float name[3]
#define ARRAY_AS_VECTOR(a) ((a)[0] * '1 0 0' + (a)[1] * '0 1 0' + (a)[2] * '0 0 1')
#define VECTOR_TO_ARRAY(a, e) { vector v = (e); (a)[0] = v.x; (a)[1] = v.y; (a)[2] = v.z; }
#define FOR_XYZ(idx) for(int idx = 0; idx < 3; ++idx)
vector target_speed_calculatevelocity(entity this, float speed, entity pushed_entity)
{
	bool is_percentage = boolean(this.spawnflags & SPEED_PERCENTAGE);
	bool is_add = boolean(this.spawnflags & SPEED_ADD);
	bool is_launcher = boolean(this.spawnflags & SPEED_LAUNCHER);

	bool is_positive[3];
	is_positive[0] = boolean(this.spawnflags & SPEED_POSITIVE_X);
	is_positive[1] = boolean(this.spawnflags & SPEED_POSITIVE_Y);
	is_positive[2] = boolean(this.spawnflags & SPEED_POSITIVE_Z);

	bool is_negative[3];
	is_negative[0] = boolean(this.spawnflags & SPEED_NEGATIVE_X);
	is_negative[1] = boolean(this.spawnflags & SPEED_NEGATIVE_Y);
	is_negative[2] = boolean(this.spawnflags & SPEED_NEGATIVE_Z);

	if(!is_add)
	{
		speed = max(speed, 0); // speed cannot be negative except when subtracting
	}

	XYZ_ARRAY(pushvel);
	VECTOR_TO_ARRAY(pushvel, pushed_entity.velocity);

	FOR_XYZ(i)
	{
		if(is_launcher && is_positive[i] && is_negative[i])
		{
			is_positive[i] = is_negative[i] = false; // launcher can only be either positive or negative not both
		}

		if(!is_positive[i] && !is_negative[i])
		{
			pushvel[i] = 0; // ignore this direction
		}
	}

	float oldspeed = vlen(ARRAY_AS_VECTOR(pushvel));

	if(is_percentage)
	{
		speed = oldspeed * speed / 100; // the speed field is used to specify the percentage of the current speed
	}

	float launcherspeed = 0;

	if(!STAT(Q3COMPAT)) // no need to simulate this bug
	{
		launcherspeed += speed;
		if(is_add) launcherspeed += oldspeed; // add the add speed in the same variable as it goes in the same direction
	}

	FOR_XYZ(i)
	{
		if(((pushvel[i] != 0) || is_launcher) && (is_positive[i] != is_negative[i]))
		{
			if(is_launcher)
			{
				pushvel[i] = 1; // every direction weighs the same amount on launchers, movedir does not matter
				if(STAT(Q3COMPAT))
				{
					launcherspeed += speed;
					if(is_add) launcherspeed += oldspeed; // add the add speed in the same variable as it goes in the same direction
				}
			}

			if(is_positive[i])
			{
				pushvel[i] = copysign(pushvel[i], 1);
			}
			else if(is_negative[i])
			{
				pushvel[i] = copysign(pushvel[i], -1);
			}
		}
	}

	XYZ_ARRAY(oldvel);
	VECTOR_TO_ARRAY(oldvel, pushed_entity.velocity);

	if(is_launcher)
	{
		VECTOR_TO_ARRAY(pushvel, normalize(ARRAY_AS_VECTOR(pushvel)) * fabs(launcherspeed)); // launcher will always launch you in the correct direction even if speed is negative, fabs() is correct
	}
	else
	{
		VECTOR_TO_ARRAY(pushvel, normalize(ARRAY_AS_VECTOR(pushvel)) * speed)

		if(is_add)
		{
			VECTOR_TO_ARRAY(pushvel, ARRAY_AS_VECTOR(pushvel) + ARRAY_AS_VECTOR(oldvel));
		}
	}

	FOR_XYZ(i)
	{
		if(!is_positive[i] && !is_negative[i])
		{
			pushvel[i] = oldvel[i]; // preserve unaffected directions
		}
	}

	return ARRAY_AS_VECTOR(pushvel);
}
#undef XYZ_ARRAY
#undef ARRAY_AS_VECTOR
#undef VECTOR_TO_ARRAY
#undef FOR_XYZ

REGISTER_NET_LINKED(ENT_CLIENT_TARGET_SPEED)

void target_speed_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	actor.velocity = target_speed_calculatevelocity(this, this.speed, actor);
}

void target_speed_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
}

#ifdef SVQC
void target_speed_link(entity this);

/*
 * ENTITY PARAMETERS:
 *
 *   targetname:  Activating trigger points to this.
 *   speed:       Speed value to set (default: 100).
 */
spawnfunc(target_speed)
{
	this.active = ACTIVE_ACTIVE;
	this.setactive = generic_netlinked_setactive;
	this.use = target_speed_use;
	this.reset = target_speed_reset;

	// FIXME: zero and unset cannot be disambiguated in xonotic
	//if (!this.speed)
	//	this.speed = 100;

	target_speed_link(this);
}

bool target_speed_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TARGET_SPEED);

	WriteInt24_t(MSG_ENTITY, this.spawnflags);
	WriteByte(MSG_ENTITY, this.active);
	WriteString(MSG_ENTITY, this.targetname);
	WriteCoord(MSG_ENTITY, this.speed);

	return true;
}

void target_speed_link(entity this)
{
	Net_LinkEntity(this, false, 0, target_speed_send);
}

#elif defined(CSQC)

void target_speed_remove(entity this)
{
	strfree(this.targetname);
}

NET_HANDLE(ENT_CLIENT_TARGET_SPEED, bool isnew)
{
	this.spawnflags = ReadInt24_t();
	this.active = ReadByte();
	this.targetname = strzone(ReadString());
	this.speed = ReadCoord();

	this.use = target_speed_use;
	this.entremove = target_speed_remove;

	return true;
}
#endif
