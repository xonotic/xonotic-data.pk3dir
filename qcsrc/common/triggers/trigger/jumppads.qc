// TODO: split target_push and put it in the target folder
#ifdef SVQC
#include "jumppads.qh"
#include <common/physics/movetypes/movetypes.qh>

void trigger_push_use(entity this, entity actor, entity trigger)
{
	if(teamplay)
	{
		this.team = actor.team;
		this.SendFlags |= 2;
	}
}
#endif

REGISTER_NET_LINKED(ENT_CLIENT_TRIGGER_PUSH)
REGISTER_NET_LINKED(ENT_CLIENT_TARGET_PUSH)

/*
	trigger_push_calculatevelocity

	Arguments:
	  org - origin of the object which is to be pushed
	  tgt - target entity (can be either a point or a model entity; if it is
	        the latter, its midpoint is used)
	  ht  - jump height, measured from the higher one of org and tgt's midpoint

	Returns: velocity for the jump
	the global trigger_push_calculatevelocity_flighttime is set to the total
	jump time
 */

vector trigger_push_calculatevelocity(vector org, entity tgt, float ht)
{
	float grav, sdist, zdist, vs, vz, jumpheight;
	vector sdir, torg;

	torg = tgt.origin + (tgt.mins + tgt.maxs) * 0.5;

	grav = PHYS_GRAVITY(other);
	if(PHYS_ENTGRAVITY(other))
		grav *= PHYS_ENTGRAVITY(other);

	zdist = torg.z - org.z;
	sdist = vlen(torg - org - zdist * '0 0 1');
	sdir = normalize(torg - org - zdist * '0 0 1');

	// how high do we need to push the player?
	jumpheight = fabs(ht);
	if(zdist > 0)
		jumpheight = jumpheight + zdist;

	/*
		STOP.

		You will not understand the following equations anyway...
		But here is what I did to get them.

		I used the functions

		  s(t) = t * vs
		  z(t) = t * vz - 1/2 grav t^2

		and solved for:

		  s(ti) = sdist
		  z(ti) = zdist
		  max(z, ti) = jumpheight

		From these three equations, you will find the three parameters vs, vz
		and ti.
	 */

	// push him so high...
	vz = sqrt(fabs(2 * grav * jumpheight)); // NOTE: sqrt(positive)!

	// we start with downwards velocity only if it's a downjump and the jump apex should be outside the jump!
	if(ht < 0)
		if(zdist < 0)
			vz = -vz;

	vector solution;
	solution = solve_quadratic(0.5 * grav, -vz, zdist); // equation "z(ti) = zdist"
	// ALWAYS solvable because jumpheight >= zdist
	if(!solution.z)
		solution_y = solution.x; // just in case it is not solvable due to roundoff errors, assume two equal solutions at their center (this is mainly for the usual case with ht == 0)
	if(zdist == 0)
		solution_x = solution.y; // solution_x is 0 in this case, so don't use it, but rather use solution_y (which will be sqrt(0.5 * jumpheight / grav), actually)

	if(zdist < 0)
	{
		// down-jump
		if(ht < 0)
		{
			// almost straight line type
			// jump apex is before the jump
			// we must take the larger one
			trigger_push_calculatevelocity_flighttime = solution.y;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one too
			trigger_push_calculatevelocity_flighttime = solution.y;
		}
	}
	else
	{
		// up-jump
		if(ht < 0)
		{
			// almost straight line type
			// jump apex is after the jump
			// we must take the smaller one
			trigger_push_calculatevelocity_flighttime = solution.x;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one
			trigger_push_calculatevelocity_flighttime = solution.y;
		}
	}
	vs = sdist / trigger_push_calculatevelocity_flighttime;

	// finally calculate the velocity
	return sdir * vs + '0 0 1' * vz;
}

void trigger_push_touch(entity this)
{
	if (this.active == ACTIVE_NOT)
		return;

	if (!isPushable(other))
		return;

	if(this.team)
		if(((this.spawnflags & 4) == 0) == (DIFF_TEAM(this, other)))
			return;

	EXACTTRIGGER_TOUCH;

	if(this.enemy)
	{
		other.velocity = trigger_push_calculatevelocity(other.origin, this.enemy, this.height);
		other.move_velocity = other.velocity;
	}
	else if(this.target)
	{
		entity e;
		RandomSelection_Init();
		for(e = world; (e = find(e, targetname, this.target)); )
		{
			if(e.cnt)
				RandomSelection_Add(e, 0, string_null, e.cnt, 1);
			else
				RandomSelection_Add(e, 0, string_null, 1, 1);
		}
		other.velocity = trigger_push_calculatevelocity(other.origin, RandomSelection_chosen_ent, this.height);
		other.move_velocity = other.velocity;
	}
	else
	{
		other.velocity = this.movedir;
		other.move_velocity = other.velocity;
	}

#ifdef SVQC
	UNSET_ONGROUND(other);
#elif defined(CSQC)
	other.move_flags &= ~FL_ONGROUND;

	if (other.flags & FL_PROJECTILE)
	{
		other.move_angles = vectoangles (other.move_velocity);
		switch(other.move_movetype)
		{
			case MOVETYPE_FLY:
				other.move_movetype = MOVETYPE_TOSS;
				other.gravity = 1;
				break;
			case MOVETYPE_BOUNCEMISSILE:
				other.move_movetype = MOVETYPE_BOUNCE;
				other.gravity = 1;
				break;
		}
	}
#endif

#ifdef SVQC
	if (IS_PLAYER(other))
	{
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		other.oldvelocity = other.velocity;

		if(this.pushltime < time)  // prevent "snorring" sound when a player hits the jumppad more than once
		{
			// flash when activated
			Send_Effect(EFFECT_JUMPPAD, other.origin, other.velocity, 1);
			_sound (other, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
			this.pushltime = time + 0.2;
		}
		if(IS_REAL_CLIENT(other) || IS_BOT_CLIENT(other))
		{
			bool found = false;
			for(int i = 0; i < other.jumppadcount && i < NUM_JUMPPADSUSED; ++i)
				if(other.(jumppadsused[i]) == this)
					found = true;
			if(!found)
			{
				other.(jumppadsused[other.jumppadcount % NUM_JUMPPADSUSED]) = this;
				other.jumppadcount = other.jumppadcount + 1;
			}

			if(IS_REAL_CLIENT(other))
			{
				if(this.message)
					centerprint(other, this.message);
			}
			else
				other.lastteleporttime = time;

			if (!IS_DEAD(other))
				animdecide_setaction(other, ANIMACTION_JUMP, true);
		}
		else
			other.jumppadcount = true;

		// reset tracking of who pushed you into a hazard (for kill credit)
		other.pushltime = 0;
		other.istypefrag = 0;
	}

	if(this.enemy.target)
		SUB_UseTargets(this.enemy, other, other); // TODO: do we need other as trigger too?

	if (other.flags & FL_PROJECTILE)
	{
		other.angles = vectoangles (other.velocity);
		switch(other.movetype)
		{
			case MOVETYPE_FLY:
				other.movetype = MOVETYPE_TOSS;
				other.gravity = 1;
				break;
			case MOVETYPE_BOUNCEMISSILE:
				other.movetype = MOVETYPE_BOUNCE;
				other.gravity = 1;
				break;
		}
		UpdateCSQCProjectile(other);
	}

	/*if (other.flags & FL_ITEM)
	{
		ItemUpdate(other);
		other.SendFlags |= ISF_DROP;
	}*/

	if (this.spawnflags & PUSH_ONCE)
	{
		settouch(this, func_null);
		setthink(this, SUB_Remove);
		this.nextthink = time;
	}
#endif
}

#ifdef SVQC
void trigger_push_link();
void trigger_push_updatelink(entity this);
#endif
void trigger_push_findtarget(entity this)
{
	entity t;
	vector org;

	// first calculate a typical start point for the jump
	org = (this.absmin + this.absmax) * 0.5;
	org_z = this.absmax.z - STAT(PL_MIN, NULL).z;

	if (this.target)
	{
		float n = 0;
		for(t = world; (t = find(t, targetname, this.target)); )
		{
			++n;
#ifdef SVQC
			entity e = spawn();
			setorigin(e, org);
			setsize(e, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL));
			e.velocity = trigger_push_calculatevelocity(org, t, this.height);
			tracetoss(e, e);
			if(e.movetype == MOVETYPE_NONE)
				waypoint_spawnforteleporter(this, trace_endpos, vlen(trace_endpos - org) / vlen(e.velocity));
			remove(e);
#endif
		}

		if(!n)
		{
			// no dest!
#ifdef SVQC
			objerror ("Jumppad with nonexistant target");
#endif
			return;
		}
		else if(n == 1)
		{
			// exactly one dest - bots love that
			this.enemy = find(world, targetname, this.target);
		}
		else
		{
			// have to use random selection every single time
			this.enemy = world;
		}
	}
#ifdef SVQC
	else
	{
		entity e = spawn();
		setorigin(e, org);
		setsize(e, STAT(PL_MIN, NULL), STAT(PL_MAX, NULL));
		e.velocity = this.movedir;
		tracetoss(e, e);
		waypoint_spawnforteleporter(this, trace_endpos, vlen(trace_endpos - org) / vlen(e.velocity));
		remove(e);
	}

	trigger_push_link();
	defer(this, 0.1, trigger_push_updatelink);
#endif
}

#ifdef SVQC
float trigger_push_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRIGGER_PUSH);

	WriteByte(MSG_ENTITY, this.team);
	WriteInt24_t(MSG_ENTITY, this.spawnflags);
	WriteByte(MSG_ENTITY, this.active);
	WriteCoord(MSG_ENTITY, this.height);

	trigger_common_write(this, true);

	return true;
}

void trigger_push_updatelink(entity this)
{
	this.SendFlags |= 1;
}

void trigger_push_link()
{
    SELFPARAM();
	trigger_link(this, trigger_push_send);
}

/*
 * ENTITY PARAMETERS:
 *
 *   target:  target of jump
 *   height:  the absolute value is the height of the highest point of the jump
 *            trajectory above the higher one of the player and the target.
 *            the sign indicates whether the highest point is INSIDE (positive)
 *            or OUTSIDE (negative) of the jump trajectory. General rule: use
 *            positive values for targets mounted on the floor, and use negative
 *            values to target a point on the ceiling.
 *   movedir: if target is not set, this * speed * 10 is the velocity to be reached.
 */
spawnfunc(trigger_push)
{
	SetMovedir(this);

	trigger_init(this);

	this.active = ACTIVE_ACTIVE;
	this.use = trigger_push_use;
	settouch(this, trigger_push_touch);

	// normal push setup
	if (!this.speed)
		this.speed = 1000;
	this.movedir = this.movedir * this.speed * 10;

	if (!this.noise)
		this.noise = "misc/jumppad.wav";
	precache_sound (this.noise);

	// this must be called to spawn the teleport waypoints for bots
	InitializeEntity(this, trigger_push_findtarget, INITPRIO_FINDTARGET);
}


bool target_push_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TARGET_PUSH);

	WriteByte(MSG_ENTITY, this.cnt);
	WriteString(MSG_ENTITY, this.targetname);
	WriteCoord(MSG_ENTITY, this.origin_x);
	WriteCoord(MSG_ENTITY, this.origin_y);
	WriteCoord(MSG_ENTITY, this.origin_z);

	WriteAngle(MSG_ENTITY, this.angles_x);
	WriteAngle(MSG_ENTITY, this.angles_y);
	WriteAngle(MSG_ENTITY, this.angles_z);

	return true;
}

void target_push_link(entity this)
{
	BITSET_ASSIGN(this.effects, EF_NODEPTHTEST);
	Net_LinkEntity(this, false, 0, target_push_send);
	//this.SendFlags |= 1; // update
}

void target_push_init(entity this)
{
	this.mangle = this.angles;
	setorigin(this, this.origin);
	target_push_link(this);
}

spawnfunc(target_push) { target_push_init(this); }
spawnfunc(info_notnull) { target_push_init(this); }
spawnfunc(target_position) { target_push_init(this); }

#elif defined(CSQC)

NET_HANDLE(ENT_CLIENT_TRIGGER_PUSH, bool isnew)
{
	this.classname = "jumppad";
	int mytm = ReadByte(); if(mytm) { this.team = mytm - 1; }
	this.spawnflags = ReadInt24_t();
	this.active = ReadByte();
	this.height = ReadCoord();

	trigger_common_read(this, true);

	this.entremove = trigger_remove_generic;
	this.solid = SOLID_TRIGGER;
	settouch(this, trigger_push_touch);
	this.move_time = time;
	defer(this, 0.25, trigger_push_findtarget);

	return true;
}

void target_push_remove(entity this)
{
	if(this.classname)
		strunzone(this.classname);
	this.classname = string_null;

	if(this.targetname)
		strunzone(this.targetname);
	this.targetname = string_null;
}

NET_HANDLE(ENT_CLIENT_TARGET_PUSH, bool isnew)
{
	this.classname = "push_target";
	this.cnt = ReadByte();
	this.targetname = strzone(ReadString());
	this.origin_x = ReadCoord();
	this.origin_y = ReadCoord();
	this.origin_z = ReadCoord();

	this.angles_x = ReadAngle();
	this.angles_y = ReadAngle();
	this.angles_z = ReadAngle();

	return = true;

	setorigin(this, this.origin);

	this.drawmask = MASK_NORMAL;
	this.entremove = target_push_remove;
}
#endif
