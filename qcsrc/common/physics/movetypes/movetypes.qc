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
	for(int bump = 0; bump < 6; bump++)
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
			stuckorigin = stuckorigin + nudge * trace_plane_normal;
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
int _Movetype_FlyMove(entity this, float dt, bool applygravity, bool applystepnormal, float stepheight) // SV_FlyMove
{
	move_stepnormal = '0 0 0';

	if(dt <= 0)
		return 0;

	int blockedflag = 0;
	int numplanes = 0;
	float time_left = dt, grav = 0;
	vector push;
	vector primal_velocity, original_velocity;
	vector restore_velocity = this.velocity;

	for(int j = 0; j < MAX_CLIP_PLANES; ++j)
		planes[j] = '0 0 0';

	if(applygravity)
	{
		this.move_didgravity = 1;
		grav = dt * (this.gravity ? this.gravity : 1) * PHYS_GRAVITY(this);

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
		if(!_Movetype_PushEntity(this, push, false))
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

		float my_trace_fraction = trace_fraction;
		vector my_trace_plane_normal = trace_plane_normal;

		if(trace_plane_normal.z)
		{
			if(trace_plane_normal.z > 0.7)
			{
				// floor
				blockedflag |= 1;

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
			vector steppush = vec3(0, 0, stepheight);
			push = this.velocity * time_left;

			if(!_Movetype_PushEntity(this, steppush, false))
			{
				blockedflag |= 8;
				break;
			}
			if(!_Movetype_PushEntity(this, push, false))
			{
				blockedflag |= 8;
				break;
			}
			float trace2_fraction = trace_fraction;
			steppush = vec3(0, 0, org.z - this.origin_z);
			if(!_Movetype_PushEntity(this, steppush, false))
			{
				blockedflag |= 8;
				break;
			}

			// accept the new position if it made some progress...
			// previously this checked if absolute distance >= 0.03125 which made stepping up unreliable
			if(this.origin_x - org.x || this.origin_y - org.y)
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
			blockedflag |= 2;
			// save the trace for player extrafriction
			if(applystepnormal)
				move_stepnormal = trace_plane_normal;
		}

		if(my_trace_fraction >= 0.001)
		{
			// actually covered some distance
			original_velocity = this.velocity;
			numplanes = 0;
		}

		// clipped to another plane
		if(numplanes >= MAX_CLIP_PLANES)
		{
			// this shouldn't really happen
			this.velocity = '0 0 0';
			blockedflag = 3;
			break;
		}

		planes[numplanes] = my_trace_plane_normal;
		numplanes++;

		// modify original_velocity so it parallels all of the clip planes
		vector new_velocity = '0 0 0';
		int plane;
		for (plane = 0;plane < numplanes;plane++)
		{
			int newplane;
			new_velocity = _Movetype_ClipVelocity(original_velocity, planes[plane], 1);
			for (newplane = 0;newplane < numplanes;newplane++)
			{
				if(newplane != plane)
				{
					// not ok
					if((new_velocity * planes[newplane]) < 0)
						break;
				}
			}
			if(newplane == numplanes)
				break;
		}

		if(plane != numplanes)
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
				blockedflag = 7;
				break;
			}
			vector dir = cross(planes[0], planes[1]);
			// LordHavoc: thanks to taniwha of QuakeForge for pointing out this fix for slowed falling in corners
			dir = normalize(dir);
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

.entity touch_chain; // DO NOT REUSE: for calling touch functions only
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
	setorigin(this, this.origin); // SV_LinkEdict
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
				setorigin(this, this.origin); // SV_LinkEdict
			// couldn't unstick, should we warn about this?
			break;
	}
}

vector _Movetype_ClipVelocity(vector vel, vector norm, float f)  // ClipVelocity
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

void WarpZone_Touch(entity this, entity toucher);
.int solid_OG;
bool _Movetype_PushEntity(entity this, vector push, bool trigger_search)  // SV_PushEntity
{
	/* Race-free trigger touching design
	 *
	 * We need to collide with triggers as we move to ensure they're triggered in the correct order and without missing any, even if they're not touching at the start and end of the move.
	 * We temporarily enable collisions on all the triggers touching the move bounding box, except warpzones: often the move in which we'd collide isn't the same one as the move in which we'd satisfy the PlaneDist condition.  If we find potentially triggerable warpzone(s) we prevent races by shortening the trace if necessary.  While moving, EXACTTRIGGER_TOUCH checks are needed only for warpzones, because we collide with the bmodels of normal triggers here.
	 *
	 * We also need to do a stationary search for triggers once per move to detect triggers that we don't move into while they're active, but instead touch by spawning, teleporting, .solid change, etc (trace_startsolid case).  These cases can be detected while moving but not reliably because we usually won't collide with them once inside, and another entity (or a world plane) could be present so trace_ent could return that instead.
	 */

	if (trigger_search && !IS_CLIENT(this)) // clients always do this static search at the start of each move
		_Movetype_LinkEdict_TouchAreaGrid(this);

	entity chain_start = NULL, it;
	vector origin_OG = this.origin;
	vector velocity_OG = this.velocity;
	vector end = this.origin + push;
	bool returnval = true; // will be false if we get teleported
	float push_fraction = 1;
	entity warpzone = NULL;
	vector save_trace_endpos = '0 0 0';
	float save_trace_fraction = 0;
	entity save_trace_ent = NULL;
	vector tele_dest = '0 0 0';

	// enable collisions with all the triggers that could be touched during this move
	if (this.solid >= SOLID_TRIGGER)
	{
		// create the bounding box of the entire move
		vector clipboxmins, clipboxmaxs;
		clipboxmins.x = min(this.origin.x, end.x) + this.mins.x - 1;
		clipboxmins.y = min(this.origin.y, end.y) + this.mins.y - 1;
		clipboxmins.z = min(this.origin.z, end.z) + this.mins.z - 1;
		clipboxmaxs.x = max(this.origin.x, end.x) + this.maxs.x + 1;
		clipboxmaxs.y = max(this.origin.y, end.y) + this.maxs.y + 1;
		clipboxmaxs.z = max(this.origin.z, end.z) + this.maxs.z + 1;

		for (chain_start = it = findbox_tofield(clipboxmins, clipboxmaxs, touch_chain); it; it = it.touch_chain)
		{
			if (it.solid == SOLID_TRIGGER && it != this)
			if (it.move_nomonsters != MOVE_NOMONSTERS && it.move_nomonsters != MOVE_WORLDONLY) // why? matches _Movetype_LinkEdict_TouchAreaGrid()
			if (gettouch(it))
			if (!IL_CONTAINS(g_touched_triggers, it))
			{
				if (gettouch(it) == WarpZone_Touch) // special case :(
				{
					// warping requires origin + view_ofs to be in a specific segment of the trigger: it's bisected by a plane
					float planedist_end = WarpZone_PlaneDist(it, end + this.view_ofs);
					if (planedist_end < 0) // this warpzone is probably triggerable during this move, see: WarpZone_Touch()
					{
//						LOG_INFOF("%s @ %f: WarpZone IS triggerable this move", PROGNAME, time);

						// in case of multiple warpzones (wtf!) choose the one that will become triggerable first
						if (!warpzone || planedist_end < WarpZone_PlaneDist(warpzone, end + this.view_ofs))
							warpzone = it;

						// to make warping race-free we need to move far enough to satisfy the condition in WarpZone_Touch()
						// but not so far that we leave the trigger and/or hit the back wall
						if (planedist_end < -1)
						{
							float planedist_start = WarpZone_PlaneDist(it, this.origin + this.view_ofs);
							push_fraction = bound(0, (planedist_start + 1) / (planedist_start - planedist_end), push_fraction);
//							LOG_INFOF("%s @ %f: shortened trace to push_fraction %f", PROGNAME, time, push_fraction);
						}
					}
					continue; // no collision with warpzones, it would prevent reaching the activation point in a single tracebox
				}
				it.solid_OG = it.solid; // they're all SOLID_TRIGGER but we also need to distinguish them from normally-solid ents
				it.solid = it.trigger_exact ? SOLID_BSP : SOLID_BBOX;
//				LOG_INFOF("%s @ %f: marked a \"%s\" with model \"%s\" trigger_exact %d as %s for \"%s\"", PROGNAME, time, it.classname, it.model, it.trigger_exact, (it.solid == SOLID_BBOX ? "SOLID_BBOX" : "SOLID_BSP"), this.classname);
			}
		}
	}

	while (true)
	{
		_Movetype_PushEntityTrace(this, push * push_fraction);

		/* bones_was_here TODO: implement trace_worldstartsolid (and other tracebox extensions)
		// fail the move if stuck in world
		if (trace_worldstartsolid)
			return true;
		*/
		// NOTE: this is a workaround for the QC's lack of a worldstartsolid trace parameter
		if (trace_startsolid && (!trace_ent || !trace_ent.solid_OG)) // world or not a trigger
		{
//			LOG_WARNF("_Movetype_PushEntity(): \"%s\" in solid with edictnum %d classname \"%s\" at \"%v\"", this.classname, etof(trace_ent), trace_ent.classname, this.origin);
			int oldtype = this.move_nomonsters;
			this.move_nomonsters = MOVE_WORLDONLY;
			_Movetype_PushEntityTrace(this, push * push_fraction);
			this.move_nomonsters = oldtype;
			if (trace_startsolid)
			{
				LOG_WARNF("_Movetype_PushEntity(): failed to move \"%s\" because it's stuck in the world at \"%v\"", this.classname, this.origin);
				return true;
			}
		}

		setorigin(this, save_trace_endpos = trace_endpos); // update absmin, absmax for WarpZoneLib_ExactTrigger_Touch() TODO only needed for WZ?
		save_trace_fraction = trace_fraction;
		save_trace_ent = trace_ent; // TODO only needed for debug prints ?

		if (trace_fraction == 1 && warpzone && returnval) // reached a warpzone activation point without teleporting first
		{
//			LOG_INFOF("%s @ %f: reached a warpzone activation point", PROGNAME, time);

			save_trace_ent = trace_ent = warpzone; // TODO only needed for debug prints ?
			vector save_trace_plane_normal = trace_plane_normal;
			if (!wasfreed(warpzone) && warpzone.solid && gettouch(warpzone))
				gettouch(warpzone)(warpzone, this);

			if (this.origin != save_trace_endpos) // successful warp
			{
//				LOG_INFOF("%s @ %f: ^2\"%s\" was warped after touching a \"%s\", planedist %f trace_fraction %f push_fraction %f", PROGNAME, time, this.classname, save_trace_ent.classname, WarpZone_PlaneDist(save_trace_ent, save_trace_endpos + this.view_ofs), save_trace_fraction, push_fraction);
				returnval = false;
				break;
			}

			trace_plane_normal = save_trace_plane_normal;
			// failed to warp
//			LOG_INFOF("%s @ %f: ^1\"%s\" failed to be warped by \"%s\" at planedist %f trace_fraction %f push_fraction %f", PROGNAME, time, this.classname, save_trace_ent.classname, WarpZone_PlaneDist(save_trace_ent, this.origin + this.view_ofs), save_trace_fraction, push_fraction);
			warpzone = NULL;
			if (push_fraction < 1) // if this was a short trace
			{
				save_trace_fraction = trace_fraction = push_fraction; // NOT finished yet
				push_fraction = 1; // continue with a full length trace
			}
		}

		// many maps use axis-aligned brushes/entities making it fairly common to impact a plane or touch a trigger
		// with trace_fraction == 1 so checking for a plane instead detects these events sooner in real and CPU time.
		// NOT finished if we failed to warp with a short trace: will now continue with a full length trace
		if (trace_plane_normal.z == 0 && trace_plane_normal.y == 0 && trace_plane_normal.x == 0) // didn't hit any plane
		if (trace_fraction == 1) // didn't switch from short trace to full length after failing to warp above
			break; // push finished

		if (trace_ent && trace_ent.solid_OG) // hit a trigger in the chain
		{
//			LOG_INFOF("%s @ %f: marking a \"%s\" as %s after being hit by \"%s\", startsolid: %d", PROGNAME, time, trace_ent.classname, (trace_ent.solid_OG == SOLID_TRIGGER ? "SOLID_TRIGGER" : ftos(trace_ent.solid_OG)), this.classname, trace_startsolid);
			bool te = trace_ent.trigger_exact;
			trace_ent.trigger_exact = false;
			trace_ent.solid = trace_ent.solid_OG;
//			LOG_INFOF("%s @ %f: calling touch func for \"%s\" after being hit by \"%s\"", PROGNAME, time, save_trace_ent.classname, this.classname);
			if (gettouch(trace_ent)) // we already checked, but it could have been unset by another touch func we called
				gettouch(trace_ent)(trace_ent, this);
			if (!wasfreed(save_trace_ent))
			{
				IL_PUSH(g_touched_triggers, save_trace_ent);
				save_trace_ent.trigger_exact = te;
			}
			trace_plane_normal = '0 0 0'; // pretend we didn't hit any plane because triggers don't block entity movement
		}
		else if (returnval) // hit world or a normally solid entity without being teleported first
		{
			if((this.solid >= SOLID_TRIGGER && (!IS_ONGROUND(this) || this.groundentity != trace_ent)))
				_Movetype_Impact(this, trace_ent); // saves and restores trace globals

			if (wasfreed(this))
			{
//				LOG_INFOF("%s @ %f Impact: X was deleted after touching a %s", PROGNAME, time, trace_ent.classname);
			}
			else if (this.origin != trace_endpos) // teleporter
			{
//				LOG_INFOF("%s @ %f Impact: %s was teleported after touching a %s", PROGNAME, time, this.classname, trace_ent.classname);
				returnval = false;
			}
			else if (this.velocity != velocity_OG) // jump pad
			{
				// probs no point doing this for impacts
				//trace_plane_normal = '0 0 0'; // disable velocity clipping in calling func
//				LOG_INFOF("%s @ %f Impact: %s was redirected after touching a %s", PROGNAME, time, this.classname, trace_ent.classname);
			}
			break; // velocity clipping is required
		}

		if (wasfreed(this))
		{
//			LOG_INFOF("%s @ %f: X was deleted after touching a \"%s\"", PROGNAME, time, save_trace_ent.classname);
			break;
		}
		else if (this.origin != save_trace_endpos) // teleported
		{
//			LOG_INFOF("%s @ %f: ^2\"%s\" was teleported after touching a \"%s\", planedist %f trace_fraction %f push_fraction %f", PROGNAME, time, this.classname, save_trace_ent.classname, WarpZone_PlaneDist(save_trace_ent, save_trace_endpos + this.view_ofs), save_trace_fraction, push_fraction);
			returnval = false;
			// don't move past this point, but do touch any other triggers sharing the plane we hit here
			// FIXME NOT reliable for dfwc2010-3 yet!
			push_fraction *= save_trace_fraction;
			tele_dest = this.origin; // need to end up here, but we'll reset origin (etc) below for other touch funcs that may rely on it
		}
		else if (this.velocity != velocity_OG && returnval) // redirected (jump pad etc)
		{
//			LOG_INFOF("%s @ %f: \"%s\" was redirected after touching a \"%s\"", PROGNAME, time, this.classname, save_trace_ent.classname);
			// return so that a new PushEntity call will be made by the movetype
			// pretend we didn't hit any plane, because the trigger has no collision for the purpose of entity movement
			//trace_plane_normal = '0 0 0'; // disable velocity clipping in calling func FIXME this could now be lost because we don't break here
			//trace_fraction = save_trace_fraction; // continue the move with new velocity
			// don't move past this point, but do touch any other triggers sharing the plane we hit here
			push_fraction *= save_trace_fraction;
		}

		setorigin(this, origin_OG); // reset absmin, absmax in case a touch func changed them
	}

	for (it = chain_start; it; it = it.touch_chain)
	{
		if (it.solid_OG) // if we changed .solid
		{
			if (it.solid == (it.trigger_exact ? SOLID_BSP : SOLID_BBOX)) // if it's still as set above
				it.solid = it.solid_OG;
			it.solid_OG = 0;
		}
	}

	trace_fraction = save_trace_fraction * push_fraction;
	if (!wasfreed(this))
		setorigin(this, (tele_dest == '0 0 0' ? this.origin : tele_dest)); // SV_LinkEdict

	return returnval;
}

void _Movetype_Physics_Frame(entity this, float movedt)
{
	IL_CLEAR(g_touched_triggers);

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
			this.origin = this.origin + movedt * this.velocity;
			this.angles = this.angles + movedt * this.avelocity;
			setorigin(this, this.origin); // SV_LinkEdict
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
	IL_CLEAR(g_touched_triggers);

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
			if (GAMEPLAYFIX_UNSTICKPLAYERS(this) == 2)
				_Movetype_CheckStuck(this);
			_Movetype_Physics_Toss(this, movedt);
			break;
		case MOVETYPE_PHYSICS:
			break;
	}

	//_Movetype_CheckVelocity(this);

	setorigin(this, this.origin); // SV_LinkEdict
	_Movetype_LinkEdict_TouchAreaGrid(this);

	//_Movetype_CheckVelocity(this);
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
