#include "jumppads.qh"
// TODO: split target_push and put it in the target folder
#ifdef SVQC
#include <common/physics/movetypes/movetypes.qh>

void trigger_push_use(entity this, entity actor, entity trigger)
{
	if(teamplay)
	{
		this.team = actor.team;
		this.SendFlags |= SF_TRIGGER_UPDATE;
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
	  pushed_entity - object that is to be pushed

	Returns: velocity for the jump
 */
vector trigger_push_calculatevelocity(vector org, entity tgt, float ht, entity pushed_entity)
{
	float grav, sdist, zdist, vs, vz, jumpheight;
	vector sdir, torg;

	torg = tgt.origin + (tgt.mins + tgt.maxs) * 0.5;

	grav = PHYS_GRAVITY(NULL);
	if(pushed_entity && pushed_entity.gravity)
		grav *= pushed_entity.gravity;

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

	float flighttime;
	if(zdist < 0)
	{
		// down-jump
		if(ht < 0)
		{
			// almost straight line type
			// jump apex is before the jump
			// we must take the larger one
			flighttime = solution.y;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one too
			flighttime = solution.y;
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
			flighttime = solution.x;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one
			flighttime = solution.y;
		}
	}
	vs = sdist / flighttime;

	// finally calculate the velocity
	return sdir * vs + '0 0 1' * vz;
}

bool jumppad_push(entity this, entity targ)
{
	if (!isPushable(targ))
		return false;

	vector org = targ.origin;

	if(STAT(Q3COMPAT))
	{
		org.z += targ.mins_z;
		org.z += 1; // off by 1!
	}

	if(this.enemy)
	{
		targ.velocity = trigger_push_calculatevelocity(org, this.enemy, this.height, targ);
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
		targ.velocity = trigger_push_calculatevelocity(org, RandomSelection_chosen_ent, this.height, targ);
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

		// prevent sound spam when a player hits the jumppad more than once
		// or when a dead player gets stuck in the jumppad for some reason
		if(this.pushltime < time && !(IS_DEAD(targ) && targ.velocity == '0 0 0'))
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
			{
				targ.lastteleporttime = time;
				targ.lastteleport_origin = targ.origin;
			}

			if (!IS_DEAD(targ))
				animdecide_setaction(targ, ANIMACTION_JUMP, true);
		}
		else
			targ.jumppadcount = 1;

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
		if(((this.spawnflags & INVERT_TEAMS) == 0) == (DIFF_TEAM(this, toucher)))
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
bool trigger_push_testorigin(entity tracetest_ent, entity targ, entity jp, vector org)
{
	setorigin(tracetest_ent, org);
	tracetoss(tracetest_ent, tracetest_ent);
	if(trace_startsolid)
		return false;

	if (!jp.height)
	{
		// since tracetoss starting from jumppad's origin often fails when target
		// is very close to real destination, start it directly from target's
		// origin instead
		vector ofs = '0 0 0';
		if (vdist(vec2(tracetest_ent.velocity), <, autocvar_sv_maxspeed))
			ofs = stepheightvec;

		tracetest_ent.velocity.z = 0;
		setorigin(tracetest_ent, targ.origin + ofs);
		tracetoss(tracetest_ent, tracetest_ent);
		if (trace_startsolid && ofs.z)
		{
			setorigin(tracetest_ent, targ.origin + ofs / 2);
			tracetoss(tracetest_ent, tracetest_ent);
			if (trace_startsolid && ofs.z)
			{
				setorigin(tracetest_ent, targ.origin);
				tracetoss(tracetest_ent, tracetest_ent);
				if (trace_startsolid)
					return false;
			}
		}
	}
	tracebox(trace_endpos, tracetest_ent.mins, tracetest_ent.maxs, trace_endpos - eZ * 1500, true, tracetest_ent);
	return true;
}

bool trigger_push_testorigin_for_item(entity tracetest_ent, entity item, vector org)
{
	setorigin(tracetest_ent, org);
	tracetoss(tracetest_ent, tracetest_ent);

	if(trace_startsolid)
		return false;
	if (trace_ent == item)
		return true;

	tracebox(trace_endpos, tracetest_ent.mins, tracetest_ent.maxs, trace_endpos - eZ * 1500, true, tracetest_ent);

	if (trace_ent == item)
		return true;

	return false;
}
#endif

#ifdef SVQC
vector trigger_push_get_start_point(entity this)
{
	// calculate a typical start point for the jump
	vector org = (this.absmin + this.absmax) * 0.5;
	org.z = this.absmax.z - PL_MIN_CONST.z - 7;
	return org;
}

float trigger_push_get_push_time(entity this, vector endpos)
{
	vector org = trigger_push_get_start_point(this);

	float grav = PHYS_GRAVITY(NULL);

	entity t = this.enemy;
	if (t)
	{
		entity e = spawn();
		setsize(e, PL_MIN_CONST, PL_MAX_CONST);
		e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
		vector v = trigger_push_calculatevelocity(org, t, this.height, e);
		vector v2 = trigger_push_calculatevelocity(endpos, t, this.height, e);
		delete(e);
		return (v.z + v2.z) / grav;
	}
	else if (!(this.target && this.target != ""))
	{
		if (!this.team)
		{
			vector v = this.movedir;

			float t = v.z / grav;
			float jump_height = 1/2 * grav * (t ** 2);
			float remaining_height = org.z + jump_height - endpos.z;
			float v2_z = sqrt(2 * grav * remaining_height);

			return (v.z + v2_z) / grav;
		}
	}
	return 0;
}
#endif

/// if (item != NULL) returns true if the item can be reached by using this jumppad, false otherwise
/// if (item == NULL) tests jumppad's trajectory and eventually spawns waypoints for it (return value doesn't matter)
bool trigger_push_test(entity this, entity item)
{
#ifdef SVQC
	vector org = trigger_push_get_start_point(this);
#endif

	if (this.target)
	{
		int n = 0;
#ifdef SVQC
		vector vel = '0 0 0';
#endif
		for(entity t = NULL; (t = find(t, targetname, this.target)); )
		{
			++n;
#ifdef SVQC
			if(t.move_movetype != MOVETYPE_NONE)
				continue;

			// bots can't tell teamed jumppads from normal ones
			if (this.team)
				continue;

			entity e = spawn();
			setsize(e, PL_MIN_CONST, PL_MAX_CONST);
			e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
			e.velocity = trigger_push_calculatevelocity(org, t, this.height, e);

			vel = e.velocity;
			vector best_target = '0 0 0';
			vector best_org = '0 0 0';
			vector best_vel = '0 0 0';
			bool valid_best_target = false;
			if (item)
			{
				if (!trigger_push_testorigin_for_item(e, item, org))
				{
					delete(e);
					return false;
				}
			}
			else
			{
				if (trigger_push_testorigin(e, t, this, org))
				{
					best_target = trace_endpos;
					best_org = org;
					best_vel = e.velocity;
					valid_best_target = true;
				}
			}

			vector new_org;
			vector dist = t.origin - org;
			if (dist.x || dist.y) // if not perfectly vertical
			{
				// test trajectory with different starting points, sometimes the trajectory
				// starting from the jumppad origin can't reach the real destination
				// and destination waypoint ends up near the jumppad itself
				vector flatdir = normalize(dist - eZ * dist.z);
				vector ofs = flatdir * 0.5 * min(fabs(this.absmax.x - this.absmin.x), fabs(this.absmax.y - this.absmin.y));
				new_org = org + ofs;

				LABEL(new_test)
				e.velocity = trigger_push_calculatevelocity(new_org, t, this.height, e);
				if (item)
				{
					if (!trigger_push_testorigin_for_item(e, item, new_org))
					{
						delete(e);
						return false;
					}
				}
				else
				{
					vel = e.velocity;
					if (vdist(vec2(e.velocity), <, autocvar_sv_maxspeed))
						e.velocity = autocvar_sv_maxspeed * flatdir;
					if (trigger_push_testorigin(e, t, this, new_org) && (!valid_best_target || trace_endpos.z > best_target.z + 50))
					{
						best_target = trace_endpos;
						best_org = new_org;
						best_vel = vel;
						valid_best_target = true;
					}
				}
				if (ofs && new_org != org - ofs)
				{
					new_org = org - ofs;
					goto new_test;
				}
			}

			if (item)
			{
				delete(e);
				return true;
			}

			if (valid_best_target)
			{
				if (!(boxesoverlap(this.absmin, this.absmax + eZ * 50, best_target + PL_MIN_CONST, best_target + PL_MAX_CONST)))
				{
					float velxy = vlen(vec2(best_vel));
					float cost = vlen(vec2(t.origin - best_org)) / velxy;
					if(velxy < autocvar_sv_maxspeed)
						velxy = autocvar_sv_maxspeed;
					cost += vlen(vec2(best_target - t.origin)) / velxy;
					waypoint_spawnforteleporter(this, best_target, cost, e);
				}
			}
			delete(e);
#endif
		}

		if(item)
			return false;

		if(!n)
		{
			// no dest!
#ifdef SVQC
			objerror (this, "Jumppad with nonexistant target");
#endif
			return false;
		}
		else if(n == 1)
		{
			// exactly one dest - bots love that
			if (!this.team)
				this.enemy = find(NULL, targetname, this.target);
			else // bots can't tell teamed jumppads from normal ones
				this.enemy = NULL;
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
		if (!this.team)
		{
			entity e = spawn();
			setsize(e, PL_MIN_CONST, PL_MAX_CONST);
			e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
			setorigin(e, org);
			e.velocity = this.movedir;
			tracetoss(e, e);
			if (item)
			{
				bool r = (trace_ent == item);
				delete(e);
				return r;
			}
			if (!(boxesoverlap(this.absmin, this.absmax + eZ * 50, trace_endpos + PL_MIN_CONST, trace_endpos + PL_MAX_CONST)))
				waypoint_spawnforteleporter(this, trace_endpos, vlen(trace_endpos - org) / vlen(e.velocity), e);
			delete(e);
		}
		else if (item)
			return false;
	}

	defer(this, 0.1, trigger_push_updatelink);
#endif
	return true;
}

void trigger_push_findtarget(entity this)
{
	trigger_push_test(this, NULL);
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
	this.SendFlags |= SF_TRIGGER_INIT;
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

	IL_PUSH(g_jumppads, this);

	// this must be called to spawn the teleport waypoints for bots
	InitializeEntity(this, trigger_push_findtarget, INITPRIO_FINDTARGET);
}


bool target_push_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TARGET_PUSH);

	WriteByte(MSG_ENTITY, this.cnt);
	WriteString(MSG_ENTITY, this.targetname);
	WriteVector(MSG_ENTITY, this.origin);

	WriteAngleVector(MSG_ENTITY, this.angles);

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

spawnfunc(target_push)
{
	target_push_init2(this);
}

spawnfunc(info_notnull)
{
	target_push_init(this);
}
spawnfunc(target_position)
{
	target_push_init(this);
}

#elif defined(CSQC)

NET_HANDLE(ENT_CLIENT_TRIGGER_PUSH, bool isnew)
{
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
	// strfree(this.classname);
	strfree(this.targetname);
}

NET_HANDLE(ENT_CLIENT_TARGET_PUSH, bool isnew)
{
	this.cnt = ReadByte();
	this.targetname = strzone(ReadString());
	this.origin = ReadVector();

	this.angles = ReadAngleVector();

	return = true;

	setorigin(this, this.origin);

	this.drawmask = MASK_NORMAL;
	this.entremove = target_push_remove;
}
#endif
