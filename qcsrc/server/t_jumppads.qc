.float height;

#ifdef CSQC
.float active;
.string target;
.string targetname;
#define ACTIVE_NOT 		0
#define ACTIVE_ACTIVE 	1
#define ACTIVE_IDLE 	2
#define ACTIVE_BUSY 	2
#define ACTIVE_TOGGLE	3
#endif

#ifdef SVQC

const float PUSH_ONCE = 1;
const float PUSH_SILENT = 2;

.float pushltime;
.float istypefrag;

void() SUB_UseTargets;

void trigger_push_use()
{
	if(teamplay)
	{
		self.team = activator.team;
		self.SendFlags |= 2;
	}
}
#endif

float trigger_push_calculatevelocity_flighttime;

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

	grav = PHYS_GRAVITY;
	if(PHYS_ENTGRAVITY(other))
		grav *= PHYS_ENTGRAVITY(other);

	zdist = torg_z - org_z;
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
	if(!solution_z)
		solution_y = solution_x; // just in case it is not solvable due to roundoff errors, assume two equal solutions at their center (this is mainly for the usual case with ht == 0)
	if(zdist == 0)
		solution_x = solution_y; // solution_x is 0 in this case, so don't use it, but rather use solution_y (which will be sqrt(0.5 * jumpheight / grav), actually)

	if(zdist < 0)
	{
		// down-jump
		if(ht < 0)
		{
			// almost straight line type
			// jump apex is before the jump
			// we must take the larger one
			trigger_push_calculatevelocity_flighttime = solution_y;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one too
			trigger_push_calculatevelocity_flighttime = solution_y;
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
			trigger_push_calculatevelocity_flighttime = solution_x;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one
			trigger_push_calculatevelocity_flighttime = solution_y;
		}
	}
	vs = sdist / trigger_push_calculatevelocity_flighttime;

	// finally calculate the velocity
	return sdir * vs + '0 0 1' * vz;
}

void trigger_push_touch()
{
	if (self.active == ACTIVE_NOT)
		return;

#ifdef SVQC
	if (!isPushable(other))
		return;
#endif

	if(self.team)
		if(((self.spawnflags & 4) == 0) == (DIFF_TEAM(self, other)))
			return;

	EXACTTRIGGER_TOUCH;

	if(self.enemy)
	{
		other.velocity = trigger_push_calculatevelocity(other.origin, self.enemy, self.height);
	}
	else if(self.target)
	{
		entity e;
		RandomSelection_Init();
		for(e = world; (e = find(e, targetname, self.target)); )
		{
			if(e.cnt)
				RandomSelection_Add(e, 0, string_null, e.cnt, 1);
			else
				RandomSelection_Add(e, 0, string_null, 1, 1);
		}
		other.velocity = trigger_push_calculatevelocity(other.origin, RandomSelection_chosen_ent, self.height);
	}
	else
	{
		other.velocity = self.movedir;
	}

	UNSET_ONGROUND(other);

#ifdef SVQC
	if (IS_PLAYER(other))
	{
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		other.oldvelocity = other.velocity;

		if(self.pushltime < time)  // prevent "snorring" sound when a player hits the jumppad more than once
		{
			// flash when activated
			pointparticles(particleeffectnum("jumppad_activate"), other.origin, other.velocity, 1);
			sound (other, CH_TRIGGER, self.noise, VOL_BASE, ATTEN_NORM);
			self.pushltime = time + 0.2;
		}

		if(IS_REAL_CLIENT(other) || IS_BOT_CLIENT(other))
		{
			float i;
			float found;
			found = FALSE;
			for(i = 0; i < other.jumppadcount && i < NUM_JUMPPADSUSED; ++i)
				if(other.(jumppadsused[i]) == self)
					found = TRUE;
			if(!found)
			{
				other.(jumppadsused[mod(other.jumppadcount, NUM_JUMPPADSUSED)]) = self;
				other.jumppadcount = other.jumppadcount + 1;
			}

			if(IS_REAL_CLIENT(other))
			{
				if(self.message)
					centerprint(other, self.message);
			}
			else
				other.lastteleporttime = time;

			if (other.deadflag == DEAD_NO)
				animdecide_setaction(other, ANIMACTION_JUMP, TRUE);
		}
		else
			other.jumppadcount = TRUE;

		// reset tracking of who pushed you into a hazard (for kill credit)
		other.pushltime = 0;
		other.istypefrag = 0;
	}

	if(self.enemy.target)
	{
		entity oldself;
		oldself = self;
		activator = other;
		self = self.enemy;
		SUB_UseTargets();
		self = oldself;
	}

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

	if (self.spawnflags & PUSH_ONCE)
	{
		self.touch = func_null;
		self.think = SUB_Remove;
		self.nextthink = time;
	}
#endif
}

.vector dest;
void trigger_push_link();
void trigger_push_updatelink();
void trigger_push_findtarget()
{
	entity t;
	vector org;

	// first calculate a typical start point for the jump
	org = (self.absmin + self.absmax) * 0.5;
	org_z = self.absmax_z - PL_MIN_z;

	if (self.target)
	{
		float n = 0;
		for(t = world; (t = find(t, targetname, self.target)); )
		{
			++n;
#ifdef SVQC
			entity e = spawn();
			setorigin(e, org);
			setsize(e, PL_MIN, PL_MAX);
			e.velocity = trigger_push_calculatevelocity(org, t, self.height);
			tracetoss(e, e);
			if(e.movetype == MOVETYPE_NONE)
				waypoint_spawnforteleporter(self, trace_endpos, vlen(trace_endpos - org) / vlen(e.velocity));
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
			self.enemy = find(world, targetname, self.target);
		}
		else
		{
			// have to use random selection every single time
			self.enemy = world;
		}
	}
#ifdef SVQC
	else
	{
		entity e = spawn();
		setorigin(e, org);
		setsize(e, PL_MIN, PL_MAX);
		e.velocity = self.movedir;
		tracetoss(e, e);
		waypoint_spawnforteleporter(self, trace_endpos, vlen(trace_endpos - org) / vlen(e.velocity));
		remove(e);
	}

	trigger_push_link();
	defer(0.1, trigger_push_updatelink);
#endif
}

#ifdef SVQC
float trigger_push_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_TRIGGER_PUSH);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		WriteString(MSG_ENTITY, self.target);
		WriteByte(MSG_ENTITY, self.team);
		WriteInt24_t(MSG_ENTITY, self.spawnflags);
		WriteByte(MSG_ENTITY, self.active);
		WriteByte(MSG_ENTITY, self.warpzone_isboxy);
		WriteByte(MSG_ENTITY, self.height);
		WriteByte(MSG_ENTITY, self.scale);
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);

		WriteCoord(MSG_ENTITY, self.mins_x);
		WriteCoord(MSG_ENTITY, self.mins_y);
		WriteCoord(MSG_ENTITY, self.mins_z);
		WriteCoord(MSG_ENTITY, self.maxs_x);
		WriteCoord(MSG_ENTITY, self.maxs_y);
		WriteCoord(MSG_ENTITY, self.maxs_z);

		WriteCoord(MSG_ENTITY, self.movedir_x);
		WriteCoord(MSG_ENTITY, self.movedir_y);
		WriteCoord(MSG_ENTITY, self.movedir_z);

		WriteCoord(MSG_ENTITY, self.angles_x);
		WriteCoord(MSG_ENTITY, self.angles_y);
		WriteCoord(MSG_ENTITY, self.angles_z);
	}

	if(sf & 2)
	{
		WriteByte(MSG_ENTITY, self.team);
		WriteByte(MSG_ENTITY, self.active);
	}

	return TRUE;
}

void trigger_push_updatelink()
{
	self.SendFlags |= 1;
}

void trigger_push_link()
{
	Net_LinkEntity(self, FALSE, 0, trigger_push_send);
}
#endif
#ifdef SVQC
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
void spawnfunc_trigger_push()
{
	SetMovedir ();

	EXACTTRIGGER_INIT;

	self.active = ACTIVE_ACTIVE;
	self.use = trigger_push_use;
	self.touch = trigger_push_touch;

	// normal push setup
	if (!self.speed)
		self.speed = 1000;
	self.movedir = self.movedir * self.speed * 10;

	if (!self.noise)
		self.noise = "misc/jumppad.wav";
	precache_sound (self.noise);

	// this must be called to spawn the teleport waypoints for bots
	InitializeEntity(self, trigger_push_findtarget, INITPRIO_FINDTARGET);
}


float target_push_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_TARGET_PUSH);

	WriteByte(MSG_ENTITY, self.cnt);
	WriteString(MSG_ENTITY, self.targetname);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	return TRUE;
}

void target_push_link()
{
	Net_LinkEntity(self, FALSE, 0, target_push_send);
	self.SendFlags |= 1; // update
}

void spawnfunc_target_push() { target_push_link(); }
void spawnfunc_info_notnull() { target_push_link(); }
void spawnfunc_target_position() { target_push_link(); }

#endif

#ifdef CSQC
void trigger_push_draw()
{
	/*float dt = time - self.move_time;
	self.move_time = time;
	if(dt <= 0)
		return;*/

	tracebox(self.origin, self.mins, self.maxs, self.origin, MOVE_NORMAL, self);

	//if(trace_fraction < 1)
	if(trace_ent)
	{
		other = trace_ent;
		trigger_push_touch();
	}
}

void ent_trigger_push()
{
	float sf = ReadByte();

	if(sf & 1)
	{
		self.classname = "jumppad";
		self.target = strzone(ReadString());
		float mytm = ReadByte(); if(mytm) { self.team = mytm - 1; }
		self.spawnflags = ReadInt24_t();
		self.active = ReadByte();
		self.warpzone_isboxy = ReadByte();
		self.height = ReadByte();
		self.scale = ReadByte();
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
		self.mins_x = ReadCoord();
		self.mins_y = ReadCoord();
		self.mins_z = ReadCoord();
		self.maxs_x = ReadCoord();
		self.maxs_y = ReadCoord();
		self.maxs_z = ReadCoord();
		setsize(self, self.mins, self.maxs);
		self.movedir_x = ReadCoord();
		self.movedir_y = ReadCoord();
		self.movedir_z = ReadCoord();
		self.angles_x = ReadCoord();
		self.angles_y = ReadCoord();
		self.angles_z = ReadCoord();

		self.solid = SOLID_TRIGGER;
		//self.draw = trigger_push_draw;
		self.drawmask = MASK_ENGINE;
		self.move_time = time;
		//self.touch = trigger_push_touch;
		trigger_push_findtarget();
	}

	if(sf & 2)
	{
		self.team = ReadByte();
		self.active = ReadByte();
	}
}

void ent_target_push()
{
	self.classname = "push_target";
	self.cnt = ReadByte();
	self.targetname = strzone(ReadString());
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	setorigin(self, self.origin);

	self.drawmask = MASK_ENGINE;
}
#endif
