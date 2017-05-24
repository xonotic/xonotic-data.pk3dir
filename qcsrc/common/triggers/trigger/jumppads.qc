#include "jumppads.qh"
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

bool jumppad_push(entity this, entity targ)
{
	if (!isPushable(targ))
		return false;

	if(this.enemy)
	{
		targ.velocity = trigger_push_calculatevelocity(targ.origin, this.enemy, this.height);
	}
	else if(this.target && this.target != "")
	{
		entity e;
		RandomSelection_Init();
		for(e = NULL; (e = find(e, targetname, this.target)); )
		{
			if(e.cnt)
				RandomSelection_AddEnt(e, e.cnt, 1);
			else
				RandomSelection_AddEnt(e, 1, 1);
		}
		targ.velocity = trigger_push_calculatevelocity(targ.origin, RandomSelection_chosen_ent, this.height);
	}
	else
	{
		targ.velocity = this.movedir;
	}

	UNSET_ONGROUND(targ);

#ifdef CSQC
	if (targ.flags & FL_PROJECTILE)
	{
		targ.angles = vectoangles (targ.velocity);
		switch(targ.move_movetype)
		{
			case MOVETYPE_FLY:
				set_movetype(targ, MOVETYPE_TOSS);
				targ.gravity = 1;
				break;
			case MOVETYPE_BOUNCEMISSILE:
				set_movetype(targ, MOVETYPE_BOUNCE);
				targ.gravity = 1;
				break;
		}
	}
#endif

#ifdef SVQC
	if (IS_PLAYER(targ))
	{
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		targ.oldvelocity = targ.velocity;

		if(this.pushltime < time)  // prevent "snorring" sound when a player hits the jumppad more than once
		{
			// flash when activated
			Send_Effect(EFFECT_JUMPPAD, targ.origin, targ.velocity, 1);
			_sound (targ, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
			this.pushltime = time + 0.2;
		}
		if(IS_REAL_CLIENT(targ) || IS_BOT_CLIENT(targ))
		{
			bool found = false;
			for(int i = 0; i < targ.jumppadcount && i < NUM_JUMPPADSUSED; ++i)
				if(targ.(jumppadsused[i]) == this)
					found = true;
			if(!found)
			{
				targ.(jumppadsused[targ.jumppadcount % NUM_JUMPPADSUSED]) = this;
				targ.jumppadcount = targ.jumppadcount + 1;
			}

			if(IS_REAL_CLIENT(targ))
			{
				if(this.message)
					centerprint(targ, this.message);
			}
			else
				targ.lastteleporttime = time;

			if (!IS_DEAD(targ))
				animdecide_setaction(targ, ANIMACTION_JUMP, true);
		}
		else
			targ.jumppadcount = true;

		// reset tracking of who pushed you into a hazard (for kill credit)
		targ.pushltime = 0;
		targ.istypefrag = 0;
	}

	if(this.enemy.target)
		SUB_UseTargets(this.enemy, targ, this);

	if (targ.flags & FL_PROJECTILE)
	{
		targ.angles = vectoangles (targ.velocity);
		targ.com_phys_gravity_factor = 1;
		switch(targ.move_movetype)
		{
			case MOVETYPE_FLY:
				set_movetype(targ, MOVETYPE_TOSS);
				targ.gravity = 1;
				break;
			case MOVETYPE_BOUNCEMISSILE:
				set_movetype(targ, MOVETYPE_BOUNCE);
				targ.gravity = 1;
				break;
		}
		UpdateCSQCProjectile(targ);
	}
#endif

	return true;
}

void trigger_push_touch(entity this, entity toucher)
{
	if (this.active == ACTIVE_NOT)
		return;

	if(this.team)
		if(((this.spawnflags & 4) == 0) == (DIFF_TEAM(this, toucher)))
			return;

	EXACTTRIGGER_TOUCH(this, toucher);

	noref bool success = jumppad_push(this, toucher);

#ifdef SVQC
	if (success && (this.spawnflags & PUSH_ONCE))
	{
		settouch(this, func_null);
		setthink(this, SUB_Remove);
		this.nextthink = time;
	}
#endif
}

#ifdef SVQC
void trigger_push_link(entity this);
void trigger_push_updatelink(entity this);
#endif
void trigger_push_findtarget(entity this)
{
	// first calculate a typical start point for the jump
	vector org = (this.absmin + this.absmax) * 0.5;
	org.z = this.absmax.z - PL_MIN_CONST.z;

	if (this.target)
	{
		int n = 0;
		for(entity t = NULL; (t = find(t, targetname, this.target)); )
		{
			++n;
#ifdef SVQC
			entity e = spawn();
			setorigin(e, org);
			setsize(e, PL_MIN_CONST, PL_MAX_CONST);
			e.velocity = trigger_push_calculatevelocity(org, t, this.height);
			tracetoss(e, e);
			if(e.move_movetype == MOVETYPE_NONE)
				waypoint_spawnforteleporter(this, trace_endpos, vlen(trace_endpos - org) / vlen(e.velocity));
			delete(e);
#endif
		}

		if(!n)
		{
			// no dest!
#ifdef SVQC
			objerror (this, "Jumppad with nonexistant target");
#endif
			return;
		}
		else if(n == 1)
		{
			// exactly one dest - bots love that
			this.enemy = find(NULL, targetname, this.target);
		}
		else
		{
			// have to use random selection every single time
			this.enemy = NULL;
		}
	}
#ifdef SVQC
	else
	{
		entity e = spawn();
		setorigin(e, org);
		setsize(e, PL_MIN_CONST, PL_MAX_CONST);
		e.velocity = this.movedir;
		tracetoss(e, e);
		waypoint_spawnforteleporter(this, trace_endpos, vlen(trace_endpos - org) / vlen(e.velocity));
		delete(e);
	}

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

	WriteCoord(MSG_ENTITY, this.movedir_x);
	WriteCoord(MSG_ENTITY, this.movedir_y);
	WriteCoord(MSG_ENTITY, this.movedir_z);

	trigger_common_write(this, true);

	return true;
}

void trigger_push_updatelink(entity this)
{
	this.SendFlags |= 1;
}

void trigger_push_link(entity this)
{
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

	trigger_push_link(this); // link it now

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

void target_push_use(entity this, entity actor, entity trigger)
{
	if(trigger.classname == "trigger_push" || trigger == this)
		return; // WTF, why is this a thing

	jumppad_push(this, actor);
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

void target_push_init2(entity this)
{
	if(this.target && this.target != "") // we have an old style pusher!
	{
		InitializeEntity(this, trigger_push_findtarget, INITPRIO_FINDTARGET);
		this.use = target_push_use;
	}

	target_push_init(this); // normal push target behaviour can be combined with a legacy pusher?
}

spawnfunc(target_push) { target_push_init2(this); }
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

	this.movedir_x = ReadCoord();
	this.movedir_y = ReadCoord();
	this.movedir_z = ReadCoord();

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
	//if(this.classname)
		//strunzone(this.classname);
	//this.classname = string_null;

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
