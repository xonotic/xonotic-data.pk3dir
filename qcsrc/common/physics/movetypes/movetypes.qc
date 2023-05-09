#include "movetypes.qh"

#ifdef SVQC
void set_movetype(entity this, int mt)
{
	this.move_movetype = mt;
	this.move_qcphysics = (mt != MOVETYPE_PHYSICS && !use_engine_physics);
	if(!IL_CONTAINS(g_moveables, this))
		IL_PUSH(g_moveables, this); // add it to the moveable entities list (even if it doesn't move!) logic: if an object never sets its movetype, we assume it never does anything notable
	this.movetype = (this.move_qcphysics) ? MOVETYPE_QCENTITY : mt;
}
#elif defined(CSQC)
void set_movetype(entity this, int mt)
{
	this.move_movetype = mt;
}
#endif

bool _Movetype_NudgeOutOfSolid_PivotIsKnownGood(entity this, vector pivot) // SV_NudgeOutOfSolid_PivotIsKnownGood
{
	vector stuckorigin = this.origin;
	vector goodmins = pivot, goodmaxs = pivot;
	for(int bump = 0; bump < 6; ++bump)
	{
		int coord = 2 - (bump >> 1);
		int dir = (bump & 1);

		for(int subbump = 0; ; ++subbump)
		{
			vector testorigin = stuckorigin;
			if(dir)
			{
				// pushing maxs
				switch(coord)
				{
					case 0: testorigin.x += this.maxs_x - goodmaxs.x; break;
					case 1: testorigin.y += this.maxs_y - goodmaxs.y; break;
					case 2: testorigin.z += this.maxs_z - goodmaxs.z; break;
				}
			}
			else
			{
				// pushing mins
				switch(coord)
				{
					case 0: testorigin.x += this.mins_x - goodmins.x; break;
					case 1: testorigin.y += this.mins_y - goodmins.y; break;
					case 2: testorigin.z += this.mins_z - goodmins.z; break;
				}
			}

			tracebox(stuckorigin, goodmins, goodmaxs, testorigin, MOVE_NOMONSTERS, this);
			if(trace_startsolid && trace_ent.solid == SOLID_BSP) // NOTE: this checks for bmodelstartsolid in the engine
			{
				// BAD BAD, can't fix that
				return false;
			}

			if(trace_fraction >= 1)
				break; // it WORKS!

			if(subbump >= 10)
			{
				// BAD BAD, can't fix that
				return false;
			}

			// we hit something... let's move out of it
			vector move = trace_endpos - testorigin;
			float nudge = (trace_plane_normal * move) + 0.03125; // FIXME cvar this constant
			stuckorigin += nudge * trace_plane_normal;
		}

		if(dir)
		{
			// pushing maxs
			switch(coord)
			{
				case 0: goodmaxs.x = this.maxs_x; break;
				case 1: goodmaxs.y = this.maxs_y; break;
				case 2: goodmaxs.z = this.maxs_z; break;
			}
		}
		else
		{
			// pushing mins
			switch(coord)
			{
				case 0: goodmins.x = this.mins_x; break;
				case 1: goodmins.y = this.mins_y; break;
				case 2: goodmins.z = this.mins_z; break;
			}
		}
	}

	// WE WIN
	this.origin = stuckorigin;

	return true;
}

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
int _Movetype_FlyMove(entity this, float time_left, bool applygravity, bool applystepnormal, float stepheight) // SV_FlyMove
{
	move_stepnormal = '0 0 0';

	int i;
	int blockedflag = 0;
	vector jumporigin = this.origin;
	LABEL(ReapplyGravityContinue)
	int numplanes;
	float grav = 0;
	vector restore_velocity = this.velocity;

	if(applygravity)
	{
		this.move_didgravity = 1;
		grav = time_left * (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);

		if(!GAMEPLAYFIX_NOGRAVITYONGROUND || !IS_ONGROUND(this))
		{
			if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				this.velocity_z -= grav * 0.5;
			else
				this.velocity_z -= grav;
		}
	}

	vector primal_velocity = this.velocity;

	// Q3: never turn against original velocity
	planes[0] = normalize(this.velocity);
	numplanes = 1;

	for(int bumpcount = 0;bumpcount < MAX_CLIP_PLANES; ++bumpcount)
	{
		if(this.velocity == '0 0 0')
			break;

		if (!_Movetype_PushEntity(this, this.velocity * time_left, false))
		{
			// we got teleported by a touch function
			// let's abort the move
			blockedflag |= 8;
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

		time_left *= 1 - trace_fraction;

		// Q3: if this is the same plane we hit before, nudge velocity
		// out along it, which fixes some epsilon issues with non-axial planes
		for (i = 0; i < numplanes; ++i)
		{
			if (trace_plane_normal * planes[i] > 0.99) // very loose, DOOM 3 uses 0.999 but that fails on dkr14
			{
				// bones_was_here: clip first to prevent this from causing sticking on some concave curves.
				this.velocity = _Movetype_ClipVelocity(this.velocity, trace_plane_normal, 1);
				this.velocity += trace_plane_normal;
				break;
			}
		}
		if (i < numplanes)
			continue;

		vector my_trace_plane_normal = trace_plane_normal;

		if (my_trace_plane_normal.z > 0) // landed on a ground plane or got an edge collision
		{
			// trace to confirm it's really ground to prevent the wallwalk bug
			int clip = PM_GroundTrace(this, false);

			// frametime-independent jumping
			if (PHYS_INPUT_BUTTON_JUMP(this) && (clip & 1)
			&& this.origin != jumporigin) // prevents infinite looping when wedged
			{
				this.velocity = _Movetype_ClipVelocity(this.velocity, my_trace_plane_normal, 1);
				PlayerJump(this);
				if (!IS_ONGROUND(this)) // definitely did jump
				{
					jumporigin = this.origin;
					goto ReapplyGravityContinue;
				}
			}
		}
		else if(stepheight)
		{
			// step - handle it immediately
			vector prestep_org = this.origin;

			if (!_Movetype_PushEntity(this, vec3(0, 0, stepheight), false))
			{
				blockedflag |= 8;
				break;
			}
			if (!trace_fraction) // no room to step up
				goto NoStep;
			float pushdown = prestep_org.z - this.origin.z;

			// gained some height, try to continue the move from this position
			if (!_Movetype_PushEntity(this, this.velocity * time_left, false))
			{
				blockedflag |= 8;
				break;
			}
			if (this.origin.x == prestep_org.x && this.origin.y == prestep_org.y) // no horizontal progress
			{
				my_trace_plane_normal = trace_plane_normal; // so the next move attempt could succeed
				goto NoStep;
			}
			time_left *= 1 - trace_fraction;

			// push down the final amount
			if (!_Movetype_PushEntity(this, vec3(0, 0, pushdown), false))
			{
				blockedflag |= 8;
				break;
			}
			int clip = 0;
			if (trace_fraction < 1)
			{
				if (PHYS_DOUBLEJUMP(this) && PHYS_INPUT_BUTTON_JUMP(this))
					clip = PM_GroundDetected(this);

				if (PHYS_DOUBLEJUMP(this) == 1 && PHYS_INPUT_BUTTON_JUMP(this) && trace_plane_normal.z >= MIN_WALK_NORMAL)
				{
					float f = this.velocity * trace_plane_normal;
					if (f < 0)
						this.velocity -= f * trace_plane_normal;
				}
			}

			// frametime-independent jumping, although the step up can't be fully frametime-independent
			if (PHYS_INPUT_BUTTON_JUMP(this) && (clip & 1)) // no need for jumporigin check
			{
				PlayerJump(this);
				if (!IS_ONGROUND(this)) // definitely did jump
				{
					if (time_left <= 0)
						return blockedflag; // no more gravity, new jump's height would be too low
					jumporigin = this.origin;
					goto ReapplyGravityContinue;
				}
			}

			if (time_left <= 0)
				break;
			// Hit a plane above the step, the pushdown may have cleared it
			// or presented a different one, so try to move again before clipping velocity.
			numplanes = 1;
			continue;

			LABEL(NoStep)
			// failed to step up, velocity will be clipped to my_trace_plane_normal
			this.origin = prestep_org;
		}
		else
		{
			// step - return it to caller
			blockedflag |= 2;
			// save the trace for player extrafriction
			if(applystepnormal)
				move_stepnormal = trace_plane_normal;
		}

		// clipped to another plane
		if(numplanes >= MAX_CLIP_PLANES)
		{
			// this shouldn't really happen
			this.velocity = '0 0 0';
			return 3;
		}

		planes[numplanes] = my_trace_plane_normal;
		++numplanes;

		// Q3: modify velocity so it parallels all of the clip planes
		// bones_was_here: Q3 and DOOM 3 use 0.1 epsilons, changed to 0 here because >= 0 is
		// the correct comparison and helps avoid the triple plane case and works fine in Xonotic.

		// find a plane that it enters
		for (i = 0; i < numplanes; ++i)
		{
			if (this.velocity * planes[i] >= 0)
				continue; // move doesn't interact with the plane

			// slide along the plane
			vector clipvelocity = _Movetype_ClipVelocity(this.velocity, planes[i], OVERCLIP);

			// see if there is a second plane that the new move enters
			for (int j = 0; j < numplanes; ++j)
			{
				if (j == i)
					continue;
				if (clipvelocity * planes[j] >= 0)
					continue; // move doesn't interact with the plane

				// try clipping the move to the plane
				clipvelocity = _Movetype_ClipVelocity(clipvelocity, planes[j], OVERCLIP);

				// see if it goes back into the first clip plane
				if (clipvelocity * planes[i] >= 0)
					continue;

				// slide the original velocity along the crease
				vector dir = normalize(cross(planes[i], planes[j]));
				clipvelocity = dir * (dir * this.velocity);

				// see if there is a third plane the new move enters
				for (int k = 0; k < numplanes; ++k)
				{
					if (k == i || k == j)
						continue;
					if (clipvelocity * planes[k] >= 0)
						continue; // move doesn't interact with the plane

					// stop dead at a triple plane interaction
					this.velocity = '0 0 0';
					return 7;
				}
			}

			// if we have fixed all interactions, try another move
			this.velocity = clipvelocity;
			break;
		}
	}

	// LordHavoc: this came from QW and allows you to get out of water more easily
	if(GAMEPLAYFIX_EASIERWATERJUMP(this) && (this.flags & FL_WATERJUMP) && !(blockedflag & 8))
		this.velocity = primal_velocity;

	if(PHYS_WALLCLIP(this) && this.pm_time && !(this.flags & FL_WATERJUMP) && !(blockedflag & 8))
		this.velocity = primal_velocity;

	if(applygravity)
	{
		if(!GAMEPLAYFIX_NOGRAVITYONGROUND || !IS_ONGROUND(this))
		{
			if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				this.velocity_z -= grav * 0.5f;
		}
	}

	return blockedflag;
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

void _Movetype_Impact(entity this, entity toucher)  // SV_Impact
{
	// due to a lack of pointers in QC, we must save the trace values and restore them for other functions
	bool save_trace_allsolid = trace_allsolid;
	bool save_trace_startsolid = trace_startsolid;
	float save_trace_fraction = trace_fraction;
	bool save_trace_inwater = trace_inwater;
	bool save_trace_inopen = trace_inopen;
	vector save_trace_endpos = trace_endpos;
	vector save_trace_plane_normal = trace_plane_normal;
	float save_trace_plane_dist = trace_plane_dist;
	entity save_trace_ent = trace_ent;
	int save_trace_dpstartcontents = trace_dpstartcontents;
	int save_trace_dphitcontents = trace_dphitcontents;
	int save_trace_dphitq3surfaceflags = trace_dphitq3surfaceflags;
	string save_trace_dphittexturename = trace_dphittexturename;

	if(this.solid != SOLID_NOT && gettouch(this) && !wasfreed(this) && !wasfreed(toucher))
		gettouch(this)(this, toucher);

	if(toucher.solid != SOLID_NOT && gettouch(toucher) && !wasfreed(this) && !wasfreed(toucher))
	{
		trace_endpos = toucher.origin;
		trace_plane_normal = -trace_plane_normal;
		trace_plane_dist = -trace_plane_dist;
		trace_ent = this;
		trace_dpstartcontents = 0;
		trace_dphitcontents = 0;
		trace_dphitq3surfaceflags = 0;
		trace_dphittexturename = string_null;
		gettouch(toucher)(toucher, this);
	}

	trace_allsolid = save_trace_allsolid;
	trace_startsolid = save_trace_startsolid;
	trace_fraction = save_trace_fraction;
	trace_inwater = save_trace_inwater;
	trace_inopen = save_trace_inopen;
	trace_endpos = save_trace_endpos;
	trace_plane_normal = save_trace_plane_normal;
	trace_plane_dist = save_trace_plane_dist;
	trace_ent = save_trace_ent;
	trace_dpstartcontents = save_trace_dpstartcontents;
	trace_dphitcontents = save_trace_dphitcontents;
	trace_dphitq3surfaceflags = save_trace_dphitq3surfaceflags;
	trace_dphittexturename = save_trace_dphittexturename;
}

void _Movetype_LinkEdict_TouchAreaGrid(entity this)  // SV_LinkEdict_TouchAreaGrid
{
	if(this.solid == SOLID_NOT)
		return;

	// due to a lack of pointers in QC, we must save the trace values and restore them for other functions
	bool save_trace_allsolid = trace_allsolid;
	bool save_trace_startsolid = trace_startsolid;
	float save_trace_fraction = trace_fraction;
	bool save_trace_inwater = trace_inwater;
	bool save_trace_inopen = trace_inopen;
	vector save_trace_endpos = trace_endpos;
	vector save_trace_plane_normal = trace_plane_normal;
	float save_trace_plane_dist = trace_plane_dist;
	entity save_trace_ent = trace_ent;
	int save_trace_dpstartcontents = trace_dpstartcontents;
	int save_trace_dphitcontents = trace_dphitcontents;
	int save_trace_dphitq3surfaceflags = trace_dphitq3surfaceflags;
	string save_trace_dphittexturename = trace_dphittexturename;

	vector emin = this.absmin, emax = this.absmax;
	// Xonotic and Nexuiz maps assume triggers will be activated by adjacent players
	// prior to sv_legacy_bbox_expand 0 DP always did this for SVQC and never for CSQC
	// we also need this for zero-size bboxes because radius == 0 returns nothing
	// see also: WarpZoneLib_ExactTrigger_Touch()
	emin -= '1 1 1';
	emax += '1 1 1';

	FOREACH_ENTITY_RADIUS_ORDERED(0.5 * (this.absmin + this.absmax), 0.5 * vlen(emin - emax), true, {
		if (it.solid == SOLID_TRIGGER && it != this)
		if (it.move_nomonsters != MOVE_NOMONSTERS && it.move_nomonsters != MOVE_WORLDONLY)
		if (gettouch(it) && boxesoverlap(it.absmin, it.absmax, emin, emax))
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
			trace_dpstartcontents = 0;
			trace_dphitcontents = 0;
			trace_dphitq3surfaceflags = 0;
			trace_dphittexturename = string_null;

			gettouch(it)(it, this);
		}
	});

	trace_allsolid = save_trace_allsolid;
	trace_startsolid = save_trace_startsolid;
	trace_fraction = save_trace_fraction;
	trace_inwater = save_trace_inwater;
	trace_inopen = save_trace_inopen;
	trace_endpos = save_trace_endpos;
	trace_plane_normal = save_trace_plane_normal;
	trace_plane_dist = save_trace_plane_dist;
	trace_ent = save_trace_ent;
	trace_dpstartcontents = save_trace_dpstartcontents;
	trace_dphitcontents = save_trace_dphitcontents;
	trace_dphitq3surfaceflags = save_trace_dphitq3surfaceflags;
	trace_dphittexturename = save_trace_dphittexturename;
}

bool autocvar__movetype_debug = false;
void _Movetype_LinkEdict(entity this, bool touch_triggers)  // SV_LinkEdict
{
	if(autocvar__movetype_debug)
	{
		this.absmin = this.origin + this.mins;
		this.absmax = this.origin + this.maxs;
	}
	else
		setorigin(this, this.origin); // calls SV_LinkEdict

	if(touch_triggers)
		_Movetype_LinkEdict_TouchAreaGrid(this);
}

int _Movetype_ContentsMask(entity this)  // SV_GenericHitSuperContentsMask
{
	if(this)
	{
		if(this.dphitcontentsmask)
			return this.dphitcontentsmask;
		else if(this.solid == SOLID_SLIDEBOX)
		{
			if(this.flags & FL_MONSTER)
				return DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_MONSTERCLIP;
			else
				return DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
		}
		else if(this.solid == SOLID_CORPSE)
			return DPCONTENTS_SOLID | DPCONTENTS_BODY;
		else if(this.solid == SOLID_TRIGGER)
			return DPCONTENTS_SOLID | DPCONTENTS_BODY;
		else
			return DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	}
	else
		return DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
}

entity _Movetype_TestEntityPosition_ent;
bool _Movetype_TestEntityPosition(vector ofs)  // SV_TestEntityPosition
{
	entity this = _Movetype_TestEntityPosition_ent;
	vector org = this.origin + ofs;

	//int cont = this.dphitcontentsmask;
	//this.dphitcontentsmask = DPCONTENTS_SOLID;
	tracebox(org, this.mins, this.maxs, this.origin, ((this.move_movetype == MOVETYPE_FLY_WORLDONLY) ? MOVE_WORLDONLY : MOVE_NOMONSTERS), this);
	//this.dphitcontentsmask = cont;
	if(trace_dpstartcontents & _Movetype_ContentsMask(this))
		return true;

	if(vlen2(trace_endpos - this.origin) >= 0.0001)
	{
		tracebox(trace_endpos, this.mins, this.maxs, trace_endpos, MOVE_NOMONSTERS, this);
		if(!trace_startsolid)
			this.origin = trace_endpos;
	}
	return false;
}

bool _Movetype_TestEntityPosition_Offset(int offset)
{
	// NOTE: expects _Movetype_TestEntityPosition_ent to be set to the correct entity
	// returns true if stuck

	// start at 2, since the first position has already been checked
	for(int j = 2; j <= offset; ++j)
	{
		if(!_Movetype_TestEntityPosition('0 0 -1' * j))
			return false;
		if(!_Movetype_TestEntityPosition('0 0 1' * j))
			return false;
	}

	return true;
}

int _Movetype_UnstickEntity(entity this)  // SV_UnstickEntity
{
	_Movetype_TestEntityPosition_ent = this;
	if (!_Movetype_TestEntityPosition(' 0  0  0')) {
	    return UNSTICK_FINE;
	}
	#define X(v) if (_Movetype_TestEntityPosition(v))
	X('0  0  -1') X(' 0  0  1')
	X('-1  0  0') X(' 1  0  0')
	X(' 0 -1  0') X(' 0  1  0')
	X('-1 -1  0') X(' 1 -1  0')
	X('-1  1  0') X(' 1  1  0')
	#undef X
	{
		if(_Movetype_TestEntityPosition_Offset(rint((this.maxs.z - this.mins.z) * 0.36)))
		{
			LOG_DEBUGF("Can't unstick an entity (edict: %d, classname: %s, origin: %s)",
			etof(this), this.classname, vtos(this.origin));
			return UNSTICK_STUCK;
		}
	}
	LOG_DEBUGF("Sucessfully unstuck an entity (edict: %d, classname: %s, origin: %s)",
		etof(this), this.classname, vtos(this.origin));
	_Movetype_LinkEdict(this, false);
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

/// This matches PM_ClipVelocity() from Q3 and ProjectOntoPlane() from DOOM 3
vector _Movetype_ClipVelocity(vector vel, vector norm, float ob)
{
	float backoff = vel * norm;

	if (ob != 1)
		backoff < 0 ? backoff *= ob : backoff /= ob;
	return vel - norm * backoff;
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

bool _Movetype_PushEntity(entity this, vector push, bool dolink)  // SV_PushEntity
{
	_Movetype_PushEntityTrace(this, push);

	// NOTE: this is a workaround for the QC's lack of a worldstartsolid trace parameter
	if(trace_startsolid)
	{
		int oldtype = this.move_nomonsters;
		this.move_nomonsters = MOVE_WORLDONLY;
		_Movetype_PushEntityTrace(this, push);
		this.move_nomonsters = oldtype;
		if(trace_startsolid)
		{
			trace_fraction = 0;
			return true;
		}
	}

	this.origin = trace_endpos;

	vector last_origin = this.origin;

	_Movetype_LinkEdict(this, dolink);

	if((this.solid >= SOLID_TRIGGER && trace_fraction < 1 && (!IS_ONGROUND(this) || this.groundentity != trace_ent)))
		_Movetype_Impact(this, trace_ent);

	return (this.origin == last_origin); // false if teleported by touch
}

void _Movetype_Physics_Frame(entity this, float movedt)
{
	this.move_didgravity = -1;
	switch (this.move_movetype)
	{
		case MOVETYPE_PUSH:
		case MOVETYPE_FAKEPUSH:
			_Movetype_Physics_Push(this, movedt);
			break;
		case MOVETYPE_NONE:
			break;
		case MOVETYPE_FOLLOW:
			_Movetype_Physics_Follow(this);
			break;
		case MOVETYPE_NOCLIP:
			_Movetype_CheckWater(this);
			this.origin += movedt * this.velocity;
			this.angles += movedt * this.avelocity;
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
			this.origin += movedt * this.velocity;
			this.angles += movedt * this.avelocity;
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
			if (GAMEPLAYFIX_UNSTICKPLAYERS(this) == 2)
				_Movetype_CheckStuck(this);
			_Movetype_Physics_Toss(this, movedt);
			break;
		case MOVETYPE_PHYSICS:
			break;
	}

	_Movetype_LinkEdict(this, true);
}

void Movetype_Physics_NoMatchTicrate(entity this, float movedt, bool isclient)  // to be run every move frame
{
	bool didmove = (this.move_time != 0);
	this.move_time = time;

	if(isclient)
		_Movetype_Physics_ClientFrame(this, movedt);
	else
	{
		// this doesn't apply to clients, and only applies to unmatched entities
		// don't run think/move on newly spawned projectiles as it messes up
		// movement interpolation and rocket trails, and is inconsistent with
		// respect to entities spawned in the same frame
		// (if an ent spawns a higher numbered ent, it moves in the same frame,
		//  but if it spawns a lower numbered ent, it doesn't - this never moves
		//  ents in the first frame regardless)
		if(!didmove && GAMEPLAYFIX_DELAYPROJECTILES(this) > 0)
			return;
		_Movetype_Physics_Frame(this, movedt);
	}
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

// saved .move_*
.vector tic_origin;
.vector tic_velocity;
.int tic_flags;
.vector tic_avelocity;
.vector tic_angles;

// saved .*
.vector tic_saved_origin;
.vector tic_saved_velocity;
.int tic_saved_flags;
.vector tic_saved_avelocity;
.vector tic_saved_angles;
void Movetype_Physics_MatchTicrate(entity this, float tr, bool sloppy)  // SV_Physics_Entity
{
	// this hack exists to contain the physics feature
	// (so entities can place themselves in the world and not need to update .tic_* themselves)
#define X(s) \
	if(this.(s) != this.tic_saved_##s) \
		this.tic_##s = this.(s)

	X(origin);
	X(velocity);
	X(flags);
	X(avelocity);
	X(angles);
#undef X

	this.flags = this.tic_flags;
	this.velocity = this.tic_velocity;
	setorigin(this, this.tic_origin);
	this.avelocity = this.tic_avelocity;
	this.angles = this.tic_angles;

	if(tr <= 0)
	{
		Movetype_Physics_NoMatchServer(this);

		this.tic_saved_flags = this.tic_flags = this.flags;
		this.tic_saved_velocity = this.tic_velocity = this.velocity;
		this.tic_saved_origin = this.tic_origin = this.origin;
		this.tic_saved_avelocity = this.tic_avelocity = this.avelocity;
		this.tic_saved_angles = this.tic_angles = this.angles;
		return;
	}

	float dt = time - this.move_time;

	int n = bound(0, floor(dt / tr), 32); // limit the number of frames to 32 (CL_MAX_USERCMDS, using DP_SMALLMEMORY value for consideration of QC's limitations)
	dt -= n * tr;
	this.move_time += n * tr;

	if(!this.move_didgravity)
		this.move_didgravity = ((this.move_movetype == MOVETYPE_BOUNCE || this.move_movetype == MOVETYPE_TOSS) && !(this.tic_flags & FL_ONGROUND));

	for (int j = 0; j < n; ++j)
	{
		_Movetype_Physics_Frame(this, tr);
		if(wasfreed(this))
			return;
	}

	// update the physics fields
	this.tic_origin = this.origin;
	this.tic_velocity = this.velocity;
	this.tic_avelocity = this.avelocity;
	this.tic_angles = this.angles;
	this.tic_flags = this.flags;

	// restore their actual values
	this.flags = this.tic_saved_flags;
	this.velocity = this.tic_saved_velocity;
	setorigin(this, this.tic_saved_origin);
	//this.avelocity = this.tic_saved_avelocity;
	this.angles = this.tic_saved_angles;

	this.avelocity = this.tic_avelocity;

	if(dt > 0 && this.move_movetype != MOVETYPE_NONE && !(this.tic_flags & FL_ONGROUND))
	{
		// now continue the move from move_time to time
		this.velocity = this.tic_velocity;

		if(this.move_didgravity > 0)
		{
			this.velocity_z -= (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE ? 0.5 : 1)
			    * dt
			    * ((this.gravity) ? this.gravity : 1)
			    * PHYS_GRAVITY(this);
		}

		this.angles = this.tic_angles + dt * this.avelocity;

		if(sloppy || this.move_movetype == MOVETYPE_NOCLIP)
		{
			setorigin(this, this.tic_origin + dt * this.velocity);
		}
		else
		{
			setorigin(this, this.tic_origin);
			_Movetype_PushEntityTrace(this, dt * this.velocity);
			if(!trace_startsolid)
				setorigin(this, trace_endpos);
			else
				setorigin(this, this.tic_saved_origin);
		}

		if(this.move_didgravity > 0 && GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			this.velocity_z -= 0.5 * dt * ((this.gravity) ? this.gravity : 1) * PHYS_GRAVITY(this);
	}
	else
	{
		this.velocity = this.tic_velocity;
		this.angles = this.tic_angles;
		setorigin(this, this.tic_origin);
	}

	this.flags = this.tic_flags;

	this.tic_saved_flags = this.flags;
	this.tic_saved_velocity = this.velocity;
	this.tic_saved_origin = this.origin;
	this.tic_saved_avelocity = this.avelocity;
	this.tic_saved_angles = this.angles;
}
