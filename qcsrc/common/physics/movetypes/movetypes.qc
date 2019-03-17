#include "movetypes.qh"

#ifdef SVQC
void set_movetype(entity this, int mt)
{
	this.move_movetype = mt;
	if (mt == MOVETYPE_PHYSICS || mt == MOVETYPE_PUSH || mt == MOVETYPE_FAKEPUSH) {
		this.move_qcphysics = false;
	}
	this.movetype = (this.move_qcphysics) ? MOVETYPE_NONE : mt;
}
#elif defined(CSQC)
void set_movetype(entity this, int mt)
{
	this.move_movetype = mt;
}
#endif

void _Movetype_WallFriction(entity this, vector stepnormal)  // SV_WallFriction
{
	/*float d, i;
	vector into, side;
	makevectors(this.v_angle);
	d = (stepnormal * v_forward) + 0.5;

	if(d < 0)
	{
	    i = (stepnormal * this.velocity);
	    into = i * stepnormal;
	    side = this.velocity - into;
	    this.velocity_x = side.x * (1 * d);
	    this.velocity_y = side.y * (1 * d);
	}*/
}

vector planes[MAX_CLIP_PLANES];
int _Movetype_FlyMove(entity this, float dt, bool applygravity, vector stepnormal, float stepheight) // SV_FlyMove
{
	if(dt <= 0)
		return 0;

	int blocked = 0;
	int i, j, numplanes = 0;
	float time_left = dt, grav = 0;
	vector push;
	vector primal_velocity, original_velocity;
	vector restore_velocity = this.velocity;

	for(i = 0; i < MAX_CLIP_PLANES; ++i)
		planes[i] = '0 0 0';

	if(applygravity)
	{
		this.move_didgravity = 1;
		grav = dt * (PHYS_ENTGRAVITY(this) ? PHYS_ENTGRAVITY(this) : 1) * PHYS_GRAVITY(this);

		if(!GAMEPLAYFIX_NOGRAVITYONGROUND || !IS_ONGROUND(this))
		{
			if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				this.velocity_z -= grav * 0.5;
			else
				this.velocity_z -= grav;
		}
	}

	original_velocity = primal_velocity = this.velocity;

	for(int bumpcount = 0;bumpcount < MAX_CLIP_PLANES;bumpcount++)
	{
		if(this.velocity == '0 0 0')
			break;

		push = this.velocity * time_left;
		if(!_Movetype_PushEntity(this, push, true, false))
		{
			// we got teleported by a touch function
			// let's abort the move
			blocked |= 8;
			break;
		}

		// this code is used by MOVETYPE_WALK and MOVETYPE_STEP and SV_UnstickEntity
		// abort move if we're stuck in the world (and didn't make it out)
		if(trace_startsolid && trace_allsolid)
		{
			this.velocity = restore_velocity;
			return 3;
		}

		if(trace_fraction == 1)
			break;

		float my_trace_fraction = trace_fraction;
		vector my_trace_plane_normal = trace_plane_normal;

		if(trace_plane_normal.z)
		{
			if(trace_plane_normal.z > 0.7)
			{
				// floor
				blocked |= 1;

				if(!trace_ent)
				{
					//dprint("_Movetype_FlyMove: !trace_ent\n");
					trace_ent = NULL;
				}

				SET_ONGROUND(this);
				this.groundentity = trace_ent;
			}
		}
		else if(stepheight)
		{
			// step - handle it immediately
			vector org = this.origin;
			vector steppush = '0 0 1' * stepheight;

			if(!_Movetype_PushEntity(this, steppush, true, false))
			{
				blocked |= 8;
				break;
			}
			if(!_Movetype_PushEntity(this, push, true, false))
			{
				blocked |= 8;
				break;
			}
			float trace2_fraction = trace_fraction;
			steppush = vec3(0, 0, org.z - this.origin_z);
			if(!_Movetype_PushEntity(this, steppush, true, false))
			{
				blocked |= 8;
				break;
			}

			// accept the new position if it made some progress...
			if(fabs(this.origin_x - org.x) >= 0.03125 || fabs(this.origin_y - org.y) >= 0.03125)
			{
				trace_endpos = this.origin;
				time_left *= 1 - trace2_fraction;
				numplanes = 0;
				continue;
			}
			else
				this.origin = org;
		}
		else
		{
			// step - return it to caller
			blocked |= 2;
			// save the trace for player extrafriction
			if(stepnormal)
				stepnormal = trace_plane_normal;
		}

		if(my_trace_fraction >= 0.001)
		{
			// actually covered some distance
			original_velocity = this.velocity;
			numplanes = 0;
		}

		time_left *= 1 - my_trace_fraction;

		// clipped to another plane
		if(numplanes >= MAX_CLIP_PLANES)
		{
			// this shouldn't really happen
			this.velocity = '0 0 0';
			blocked = 3;
			break;
		}

		planes[numplanes] = my_trace_plane_normal;
		numplanes++;

		// modify original_velocity so it parallels all of the clip planes
		vector new_velocity = '0 0 0';
		for (i = 0;i < numplanes;i++)
		{
			new_velocity = _Movetype_ClipVelocity(original_velocity, planes[i], 1);
			for (j = 0;j < numplanes;j++)
			{
				if(j != i)
				{
					// not ok
					if((new_velocity * planes[j]) < 0)
						break;
				}
			}
			if(j == numplanes)
				break;
		}

		if(i != numplanes)
		{
			// go along this plane
			this.velocity = new_velocity;
		}
		else
		{
			// go along the crease
			if(numplanes != 2)
			{
				this.velocity = '0 0 0';
				blocked = 7;
				break;
			}
			vector dir = cross(planes[0], planes[1]);
			// LordHavoc: thanks to taniwha of QuakeForge for pointing out this fix for slowed falling in corners
			float ilength = sqrt((dir * dir));
			if(ilength)
				ilength = 1.0 / ilength;
			dir.x *= ilength;
			dir.y *= ilength;
			dir.z *= ilength;
			float d = (dir * this.velocity);
			this.velocity = dir * d;
		}

		// if current velocity is against the original velocity,
		// stop dead to avoid tiny occilations in sloping corners
		if((this.velocity * primal_velocity) <= 0)
		{
			this.velocity = '0 0 0';
			break;
		}
	}

	// LordHavoc: this came from QW and allows you to get out of water more easily
	if(GAMEPLAYFIX_EASIERWATERJUMP(this) && (this.flags & FL_WATERJUMP) && !(blocked & 8))
		this.velocity = primal_velocity;

	if(PHYS_WALLCLIP(this) && this.pm_time && !(this.flags & FL_WATERJUMP) && !(blocked & 8))
		this.velocity = primal_velocity;

	if(applygravity)
	{
		if(!GAMEPLAYFIX_NOGRAVITYONGROUND || !IS_ONGROUND(this))
		{
			if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				this.velocity_z -= grav * 0.5f;
		}
	}

	return blocked;
}

void _Movetype_CheckVelocity(entity this)  // SV_CheckVelocity
{
	// if(vlen(this.velocity) < 0.0001)
	// this.velocity = '0 0 0';
}

bool _Movetype_CheckWater(entity this)  // SV_CheckWater
{
	vector point = this.origin;
	point.z += this.mins.z + 1;

	int nativecontents = pointcontents(point);
	if(this.watertype && this.watertype != nativecontents)
	{
		// dprintf("_Movetype_CheckWater(): Original: '%d', New: '%d'\n", this.watertype, nativecontents);
		if(this.contentstransition)
			this.contentstransition(this.watertype, nativecontents);
	}

	this.waterlevel = WATERLEVEL_NONE;
	this.watertype = CONTENT_EMPTY;

	int supercontents = Mod_Q1BSP_SuperContentsFromNativeContents(nativecontents);
	if(supercontents & DPCONTENTS_LIQUIDSMASK)
	{
		this.watertype = nativecontents;
		this.waterlevel = WATERLEVEL_WETFEET;
		point.z = this.origin.z + (this.mins.z + this.maxs.z) * 0.5;
		if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
		{
			this.waterlevel = WATERLEVEL_SWIMMING;
			point.z = this.origin.z + this.view_ofs.z;
			if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
				this.waterlevel = WATERLEVEL_SUBMERGED;
		}
	}

	return this.waterlevel > 1;
}

void _Movetype_CheckWaterTransition(entity ent)  // SV_CheckWaterTransition
{
	int contents = pointcontents(ent.origin);

	if(!ent.watertype)
	{
		// just spawned here
		if(!GAMEPLAYFIX_WATERTRANSITION(ent))
		{
			ent.watertype = contents;
			ent.waterlevel = 1;
			return;
		}
	}
	else if(ent.watertype != contents)
	{
		// dprintf("_Movetype_CheckWaterTransition(): Origin: %s, Direct: '%d', Original: '%d', New: '%d'\n", vtos(ent.origin), pointcontents(ent.origin), ent.watertype, contents);
		if(ent.contentstransition)
			ent.contentstransition(ent.watertype, contents);
	}

	if(contents <= CONTENT_WATER)
	{
		ent.watertype = contents;
		ent.waterlevel = 1;
	}
	else
	{
		ent.watertype = CONTENT_EMPTY;
		ent.waterlevel = (GAMEPLAYFIX_WATERTRANSITION(ent) ? 0 : contents);
	}
}

void _Movetype_Impact(entity this, entity oth)  // SV_Impact
{
	if(gettouch(this))
		gettouch(this)(this, oth);

	if(gettouch(oth))
		gettouch(oth)(oth, this);
}

void _Movetype_LinkEdict_TouchAreaGrid(entity this)  // SV_LinkEdict_TouchAreaGrid
{
	if(this.solid == SOLID_NOT)
		return;

    FOREACH_ENTITY_RADIUS(0.5 * (this.absmin + this.absmax), 0.5 * vlen(this.absmax - this.absmin), true, {
		if (it.solid == SOLID_TRIGGER && it != this)
		if (it.move_nomonsters != MOVE_NOMONSTERS && it.move_nomonsters != MOVE_WORLDONLY)
		if (gettouch(it) && boxesoverlap(it.absmin, it.absmax, this.absmin, this.absmax))
		{
			trace_allsolid = false;
			trace_startsolid = false;
			trace_fraction = 1;
			trace_inwater = false;
			trace_inopen = true;
			trace_endpos = it.origin;
			trace_plane_normal = '0 0 1';
			trace_plane_dist = 0;
			trace_ent = this;

			gettouch(it)(it, this);
		}
    });
}

bool autocvar__movetype_debug = false;
void _Movetype_LinkEdict(entity this, bool touch_triggers)  // SV_LinkEdict
{
	if(autocvar__movetype_debug)
	{
		vector mi, ma;
		if(this.solid == SOLID_BSP)
		{
			// TODO set the absolute bbox
			mi = this.mins;
			ma = this.maxs;
		}
		else
		{
			mi = this.mins;
			ma = this.maxs;
		}
		mi += this.origin;
		ma += this.origin;

		if(this.flags & FL_ITEM)
		{
			mi -= '15 15 1';
			ma += '15 15 1';
		}
		else
		{
			mi -= '1 1 1';
			ma += '1 1 1';
		}

		this.absmin = mi;
		this.absmax = ma;
	}
	else
	{
		setorigin(this, this.origin); // calls SV_LinkEdict
	#ifdef CSQC
		// NOTE: CSQC's version of setorigin doesn't expand
		this.absmin -= '1 1 1';
		this.absmax += '1 1 1';
	#endif
	}

	if(touch_triggers)
		_Movetype_LinkEdict_TouchAreaGrid(this);
}

entity _Movetype_TestEntityPosition_ent;
bool _Movetype_TestEntityPosition(vector ofs)  // SV_TestEntityPosition
{
    entity this = _Movetype_TestEntityPosition_ent;
	vector org = this.origin + ofs;

	int cont = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID;
	tracebox(org, this.mins, this.maxs, org, ((this.move_movetype == MOVETYPE_FLY_WORLDONLY) ? MOVE_WORLDONLY : MOVE_NOMONSTERS), this);
	this.dphitcontentsmask = cont;

	if(trace_startsolid)
		return true;

	if(vdist(trace_endpos - this.origin, >, 0.0001))
		this.origin = trace_endpos;
	return false;
}

int _Movetype_UnstickEntity(entity this)  // SV_UnstickEntity
{
    _Movetype_TestEntityPosition_ent = this;
	if (!_Movetype_TestEntityPosition(' 0  0  0')) {
	    return UNSTICK_FINE;
	}
	#define X(v) if (_Movetype_TestEntityPosition(v))
	X('-1  0  0') X(' 1  0  0')
	X(' 0 -1  0') X(' 0  1  0')
	X('-1 -1  0') X(' 1 -1  0')
	X('-1  1  0') X(' 1  1  0')
	#undef X
	{
        #define X(i) \
            if (_Movetype_TestEntityPosition('0 0 -1' * i)) \
            if (_Movetype_TestEntityPosition('0 0 1' * i))
        X(1) X(2) X(3) X(4) X(5) X(6) X(7) X(8)
        X(9) X(10) X(11) X(12) X(13) X(14) X(15) X(16)
        X(17)
        #undef X
        {
            LOG_DEBUGF("Can't unstick an entity (edict: %d, classname: %s, origin: %s)",
                etof(this), this.classname, vtos(this.origin));
            return UNSTICK_STUCK;
        }
	}
	LOG_DEBUGF("Sucessfully unstuck an entity (edict: %d, classname: %s, origin: %s)",
		etof(this), this.classname, vtos(this.origin));
	_Movetype_LinkEdict(this, true);
	return UNSTICK_FIXED;
}

void _Movetype_CheckStuck(entity this)  // SV_CheckStuck
{
	int unstick = _Movetype_UnstickEntity(this); // sets test position entity
	switch(unstick)
	{
		case UNSTICK_FINE:
			this.oldorigin = this.origin;
			break;
		case UNSTICK_FIXED:
			break; // already sorted
		case UNSTICK_STUCK:
			vector offset = this.oldorigin - this.origin;
			if(!_Movetype_TestEntityPosition(offset))
				_Movetype_LinkEdict(this, false);
			// couldn't unstick, should we warn about this?
			break;
	}
}

vector _Movetype_ClipVelocity(vector vel, vector norm, float f)  // SV_ClipVelocity
{
	vel -= ((vel * norm) * norm) * f;

	if(vel.x > -0.1 && vel.x < 0.1) vel.x = 0;
	if(vel.y > -0.1 && vel.y < 0.1) vel.y = 0;
	if(vel.z > -0.1 && vel.z < 0.1) vel.z = 0;

	return vel;
}

void _Movetype_PushEntityTrace(entity this, vector push)
{
	vector end = this.origin + push;
	int type;
	if(this.move_nomonsters)
		type = max(0, this.move_nomonsters);
	else if(this.move_movetype == MOVETYPE_FLYMISSILE)
		type = MOVE_MISSILE;
	else if(this.move_movetype == MOVETYPE_FLY_WORLDONLY)
		type = MOVE_WORLDONLY;
	else if(this.solid == SOLID_TRIGGER || this.solid == SOLID_NOT)
		type = MOVE_NOMONSTERS;
	else
		type = MOVE_NORMAL;

	tracebox(this.origin, this.mins, this.maxs, end, type, this);
}

bool _Movetype_PushEntity(entity this, vector push, bool failonstartsolid, bool dolink)  // SV_PushEntity
{
	_Movetype_PushEntityTrace(this, push);

	if(trace_startsolid && failonstartsolid)
	{
		int oldtype = this.move_nomonsters;
		this.move_nomonsters = MOVE_NOMONSTERS;
		_Movetype_PushEntityTrace(this, push);
		this.move_nomonsters = oldtype;
		if(trace_startsolid)
			return true;
	}

	this.origin = trace_endpos;

	vector last_origin = this.origin;

	if(dolink)
		_Movetype_LinkEdict(this, true);

	if(trace_fraction < 1)
		if(this.solid >= SOLID_TRIGGER && (!IS_ONGROUND(this) || (this.groundentity != trace_ent)))
			_Movetype_Impact(this, trace_ent);

	return (this.origin == last_origin); // false if teleported by touch
}


.float ltime;
.void() blocked;

void _Movetype_Physics_Frame(entity this, float movedt)
{
	this.move_didgravity = -1;
	switch (this.move_movetype)
	{
		case MOVETYPE_PUSH:
		case MOVETYPE_FAKEPUSH:
			LOG_DEBUG("Physics: Lacking QuakeC support for Push movetype, FIX ME by using engine physics!");
			break;
		case MOVETYPE_NONE:
			break;
		case MOVETYPE_FOLLOW:
			_Movetype_Physics_Follow(this);
			break;
		case MOVETYPE_NOCLIP:
			_Movetype_CheckWater(this);
			this.origin = this.origin + movedt * this.velocity;
			this.angles = this.angles + movedt * this.avelocity;
			_Movetype_LinkEdict(this, false);
			break;
		case MOVETYPE_STEP:
			_Movetype_Physics_Step(this, movedt);
			break;
		case MOVETYPE_WALK:
			_Movetype_Physics_Walk(this, movedt);
			break;
		case MOVETYPE_TOSS:
		case MOVETYPE_BOUNCE:
		case MOVETYPE_BOUNCEMISSILE:
		case MOVETYPE_FLYMISSILE:
		case MOVETYPE_FLY:
		case MOVETYPE_FLY_WORLDONLY:
			_Movetype_Physics_Toss(this, movedt);
			if(wasfreed(this))
				return;
			_Movetype_LinkEdict(this, true);
			break;
		case MOVETYPE_PHYSICS:
			break;
	}
}

void _Movetype_Physics_ClientFrame(entity this, float movedt)
{
	this.move_didgravity = -1;
	switch (this.move_movetype)
	{
		case MOVETYPE_PUSH:
		case MOVETYPE_FAKEPUSH:
			LOG_DEBUG("Physics: Lacking QuakeC support for Push movetype, FIX ME by using engine physics!");
			break;
		case MOVETYPE_NONE:
			break;
		case MOVETYPE_FOLLOW:
			_Movetype_Physics_Follow(this);
			break;
		case MOVETYPE_NOCLIP:
			_Movetype_CheckWater(this);
			this.origin = this.origin + movedt * this.velocity;
			this.angles = this.angles + movedt * this.avelocity;
			break;
		case MOVETYPE_STEP:
			_Movetype_Physics_Step(this, movedt);
			break;
		case MOVETYPE_WALK:
		case MOVETYPE_FLY:
		case MOVETYPE_FLY_WORLDONLY:
			_Movetype_Physics_Walk(this, movedt);
			break;
		case MOVETYPE_TOSS:
		case MOVETYPE_BOUNCE:
		case MOVETYPE_BOUNCEMISSILE:
		case MOVETYPE_FLYMISSILE:
			_Movetype_Physics_Toss(this, movedt);
			break;
		case MOVETYPE_PHYSICS:
			break;
	}

	//_Movetype_CheckVelocity(this);

	_Movetype_LinkEdict(this, true);

	//_Movetype_CheckVelocity(this);
}

void Movetype_Physics_NoMatchTicrate(entity this, float movedt, bool isclient)  // to be run every move frame
{
	this.move_time = time;

	if(isclient)
		_Movetype_Physics_ClientFrame(this, movedt);
	else
		_Movetype_Physics_Frame(this, movedt);
	if(wasfreed(this))
		return;

	setorigin(this, this.origin);
}

void Movetype_Physics_NoMatchServer(entity this)  // optimized
{
	float movedt = time - this.move_time;
	this.move_time = time;

	_Movetype_Physics_Frame(this, movedt);
	if(wasfreed(this))
		return;

	setorigin(this, this.origin);
}

void Movetype_Physics_MatchServer(entity this, bool sloppy)
{
	Movetype_Physics_MatchTicrate(this, TICRATE, sloppy);
}

.vector tic_origin;
.vector tic_velocity;
.int tic_flags;
.vector tic_avelocity;
.vector tic_angles;

.vector tic_saved_origin;
.vector tic_saved_velocity;
.int tic_saved_flags;
.vector tic_saved_avelocity;
.vector tic_saved_angles;
void Movetype_Physics_MatchTicrate(entity this, float tr, bool sloppy)  // SV_Physics_Entity
{
#define X(s) \
	if(this.(s) != this.tic_saved_##s) \
		this.tic_##s = this.(s)

	X(origin);
	X(velocity);
	X(flags);
	X(avelocity);
	X(angles);
#undef X

	if(tr <= 0)
	{
		this.flags = this.tic_flags;
		this.velocity = this.tic_velocity;
		this.origin = this.tic_origin;
		this.avelocity = this.tic_avelocity;
		this.angles = this.tic_angles;
		Movetype_Physics_NoMatchServer(this);
		this.tic_origin = this.origin;
		this.tic_velocity = this.velocity;
		this.tic_avelocity = this.avelocity;
		this.tic_angles = this.angles;
		this.tic_flags = this.flags;

		this.tic_saved_flags = this.flags;
		this.tic_saved_velocity = this.velocity;
		this.tic_saved_origin = this.origin;
		this.tic_saved_avelocity = this.avelocity;
		this.tic_saved_angles = this.angles;
		return;
	}

	float dt = time - this.move_time;

	int n = max(0, floor(dt / tr));
	dt -= n * tr;
	this.move_time += n * tr;

	if(!this.move_didgravity)
		this.move_didgravity = ((this.move_movetype == MOVETYPE_BOUNCE || this.move_movetype == MOVETYPE_TOSS) && !(this.tic_flags & FL_ONGROUND));

	for (int i = 0; i < n; ++i)
	{
		this.flags = this.tic_flags;
		this.velocity = this.tic_velocity;
		setorigin(this, this.tic_origin);
		this.avelocity = this.tic_avelocity;
		this.angles = this.tic_angles;
		_Movetype_Physics_Frame(this, tr);
		this.tic_origin = this.origin;
		this.tic_velocity = this.velocity;
		this.tic_avelocity = this.avelocity;
		this.tic_angles = this.angles;
		this.tic_flags = this.flags;
		if(wasfreed(this))
			return;
	}

	this.avelocity = this.tic_avelocity;

	if(dt > 0 && this.move_movetype != MOVETYPE_NONE && !(this.tic_flags & FL_ONGROUND))
	{
		// now continue the move from move_time to time
		this.velocity = this.tic_velocity;

		if(this.move_didgravity > 0)
		{
			this.velocity_z -= (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE ? 0.5 : 1)
			    * dt
			    * (this.gravity ? this.gravity : 1)
			    * PHYS_GRAVITY(this);
		}

		this.angles = this.tic_angles + dt * this.avelocity;

		if(sloppy || this.move_movetype == MOVETYPE_NOCLIP)
		{
			setorigin(this, this.tic_origin + dt * this.velocity);
		}
		else
		{
			vector oldorg = this.origin;
			this.origin = this.tic_origin;
			_Movetype_PushEntityTrace(this, dt * this.velocity);
			this.origin = oldorg;
			if(!trace_startsolid)
				setorigin(this, trace_endpos);
		}

		if(this.move_didgravity > 0 && GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			this.velocity_z -= 0.5 * dt * (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);
	}
	else
	{
		this.velocity = this.tic_velocity;
		this.angles = this.tic_angles;
		setorigin(this, this.tic_origin);
	}

	this.tic_saved_flags = this.flags;
	this.tic_saved_velocity = this.velocity;
	this.tic_saved_origin = this.origin;
	this.tic_saved_avelocity = this.avelocity;
	this.tic_saved_angles = this.angles;
}
