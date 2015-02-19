#if defined(CSQC)
	#include "../dpdefs/csprogsdefs.qh"
	#include "defs.qh"
	#include "../common/stats.qh"
	#include "../common/util.qh"
	#include "movetypes.qh"
	#include "../csqcmodellib/common.qh"
	#include "../server/t_items.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
#endif


#define GRAVITY_UNAFFECTED_BY_TICRATE (getstati(STAT_MOVEFLAGS) & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE)

.entity move_groundentity; // FIXME add move_groundnetworkentity?
.float move_suspendedinair;
.float move_didgravity;

void _Movetype_CheckVelocity() // SV_CheckVelocity
{
}

float _Movetype_CheckWater(entity ent) // SV_CheckWater
{
	vector point = ent.move_origin;
	point_z += (ent.mins_z + 1);

	int nativecontents = pointcontents(point);

	if(ent.move_watertype)
	if(ent.move_watertype != nativecontents)
	{
		//print(sprintf("_Movetype_CheckWater(): Original: '%d', New: '%d'\n", ent.move_watertype, nativecontents));
		if(ent.contentstransition)
			ent.contentstransition(ent.move_watertype, nativecontents);
	}

	ent.move_waterlevel = 0;
	ent.move_watertype = CONTENT_EMPTY;

	int supercontents = Mod_Q1BSP_SuperContentsFromNativeContents(nativecontents);
	if(supercontents & DPCONTENTS_LIQUIDSMASK)
	{
		ent.move_watertype = nativecontents;
		ent.move_waterlevel = 1;
		point_y = (ent.origin_y + ((ent.mins_z + ent.maxs_y) * 0.5));
		if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
		{
			ent.move_waterlevel = 2;
			point_y = ent.origin_y + ent.view_ofs_y;
			if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
				ent.move_waterlevel = 3;
		}
	}

	return (ent.move_waterlevel > 1);
}

void _Movetype_CheckWaterTransition(entity ent) // SV_CheckWaterTransition
{
	float contents = pointcontents(ent.move_origin);

	if(!ent.move_watertype)
	{
		// just spawned here
		if(!autocvar_cl_gameplayfix_fixedcheckwatertransition)
		{
			ent.move_watertype = contents;
			ent.move_waterlevel = 1;
			return;
		}
	}
	else if(ent.move_watertype != contents)
	{
		//print(sprintf("_Movetype_CheckWaterTransition(): Origin: %s, Direct: '%d', Original: '%d', New: '%d'\n", vtos(ent.move_origin), pointcontents(ent.move_origin), ent.move_watertype, contents));
		if(ent.contentstransition)
			ent.contentstransition(ent.move_watertype, contents);
	}

	if(contents <= CONTENT_WATER)
	{
		ent.move_watertype = contents;
		ent.move_waterlevel = 1;
	}
	else
	{
		ent.move_watertype = CONTENT_EMPTY;
		ent.move_waterlevel = (autocvar_cl_gameplayfix_fixedcheckwatertransition ? 0 : contents);
	}
}

void _Movetype_Impact(entity oth) // SV_Impact
{
	entity oldother, oldself;

	oldself = self;
	oldother = other;

	if(self.move_touch)
	{
		other = oth;

		self.move_touch();

		other = oldother;
	}

	if(oth.move_touch)
	{
		other = self;
		self = oth;

		self.move_touch();

		self = oldself;
		other = oldother;
	}
}

void _Movetype_LinkEdict_TouchAreaGrid() // SV_LinkEdict_TouchAreaGrid
{
	entity e, oldself, oldother;

	oldself = self;
	oldother = other;

	for(e = findradius(0.5 * (self.absmin + self.absmax), 0.5 * vlen(self.absmax - self.absmin)); e; e = e.chain)
	{
		if(e.move_touch)
		if(boxesoverlap(e.absmin, e.absmax, oldself.absmin, oldself.absmax))
		{
			self = e;
			other = oldself;

			trace_allsolid = false;
			trace_startsolid = false;
			trace_fraction = 1;
			trace_inwater = false;
			trace_inopen = true;
			trace_endpos = e.origin;
			trace_plane_normal = '0 0 1';
			trace_plane_dist = 0;
			trace_ent = oldself;

			e.move_touch();
		}
	}

	other = oldother;
	self = oldself;
}

void _Movetype_LinkEdict(float touch_triggers) // SV_LinkEdict
{
	vector mi, ma;
	if(self.solid == SOLID_BSP)
	{
		// TODO set the absolute bbox
		mi = self.mins;
		ma = self.maxs;
	}
	else
	{
		mi = self.mins;
		ma = self.maxs;
	}
	mi = mi + self.origin;
	ma = ma + self.origin;

	if(self.move_flags & FL_ITEM)
	{
		mi_x -= 15;
		mi_y -= 15;
		mi_z -= 1;
		ma_x += 15;
		ma_y += 15;
		ma_z += 1;
	}
	else
	{
		mi_x -= 1;
		mi_y -= 1;
		mi_z -= 1;
		ma_x += 1;
		ma_y += 1;
		ma_z += 1;
	}

	self.absmin = mi;
	self.absmax = ma;

	if(touch_triggers)
		_Movetype_LinkEdict_TouchAreaGrid();
}

float _Movetype_TestEntityPosition(vector ofs) // SV_TestEntityPosition
{
	vector org;
	org = self.move_origin + ofs;

	int cont = self.dphitcontentsmask;
	self.dphitcontentsmask = DPCONTENTS_SOLID;
	tracebox(self.move_origin, self.mins, self.maxs, self.move_origin, MOVE_NOMONSTERS, self);
	self.dphitcontentsmask = cont;

	if(trace_startsolid)
		return true;

	if(vlen(trace_endpos - self.move_origin) > 0.0001)
		self.move_origin = trace_endpos;
	return false;
}

float _Movetype_UnstickEntity() // SV_UnstickEntity
{
	if(!_Movetype_TestEntityPosition('0 0 0'))
		return true;
	if(!_Movetype_TestEntityPosition('-1 0 0')) goto success;
	if(!_Movetype_TestEntityPosition('1 0 0')) goto success;
	if(!_Movetype_TestEntityPosition('0 -1 0')) goto success;
	if(!_Movetype_TestEntityPosition('0 1 0')) goto success;
	if(!_Movetype_TestEntityPosition('-1 -1 0')) goto success;
	if(!_Movetype_TestEntityPosition('1 -1 0')) goto success;
	if(!_Movetype_TestEntityPosition('-1 1 0')) goto success;
	if(!_Movetype_TestEntityPosition('1 1 0')) goto success;
	float i;
	for(i = 1; i <= 17; ++i)
	{
		if(!_Movetype_TestEntityPosition('0 0 -1' * i)) goto success;
		if(!_Movetype_TestEntityPosition('0 0 1' * i)) goto success;
	}
	dprintf("Can't unstick an entity (edict: %d, classname: %s, origin: %s)\n", num_for_edict(self), self.classname, vtos(self.move_origin));
	return false;
:success
	dprintf("Sucessfully unstuck an entity (edict: %d, classname: %s, origin: %s)\n", num_for_edict(self), self.classname, vtos(self.move_origin));
	_Movetype_LinkEdict(true);
	return true;
}

vector _Movetype_ClipVelocity(vector vel, vector norm, float f) // SV_ClipVelocity
{
	vel = vel - ((vel * norm) * norm) * f;

	if(vel_x > -0.1 && vel_x < 0.1) vel_x = 0;
	if(vel_y > -0.1 && vel_y < 0.1) vel_y = 0;
	if(vel_z > -0.1 && vel_z < 0.1) vel_z = 0;

	return vel;
}

void _Movetype_PushEntityTrace(vector push)
{
	vector end;
	float type;

	end = self.move_origin + push;

	if(self.move_nomonsters)
		type = max(0, self.move_nomonsters);
	else if(self.move_movetype == MOVETYPE_FLYMISSILE)
		type = MOVE_MISSILE;
	else if(self.solid == SOLID_TRIGGER || self.solid == SOLID_NOT)
		type = MOVE_NOMONSTERS;
	else
		type = MOVE_NORMAL;

	tracebox(self.move_origin, self.mins, self.maxs, end, type, self);
}

float _Movetype_PushEntity(vector push, float failonstartsolid) // SV_PushEntity
{
	_Movetype_PushEntityTrace(push);

	if(trace_startsolid && failonstartsolid)
		return trace_fraction;

	self.move_origin = trace_endpos;

	if(trace_fraction < 1)
		if(self.solid >= SOLID_TRIGGER && (!(self.move_flags & FL_ONGROUND) || (self.move_groundentity != trace_ent)))
			_Movetype_Impact(trace_ent);

	return trace_fraction;
}


.float ltime;
.void() blocked;
void _Movetype_VectorAngles_FLU(vector myangles)
{
	float angle, sr, sp, sy, cr, cp, cy;

	angle = myangles_y * (M_PI*2 / 360);
	sy = sin(angle);
	cy = cos(angle);
	angle = myangles_x * (M_PI*2 / 360);
	sp = sin(angle);
	cp = cos(angle);
	if(v_forward)
	{
		v_forward_x = cp*cy;
		v_forward_y = cp*sy;
		v_forward_z = -sp;
	}
	if(v_right || v_up)
	{
		if(myangles_z)
		{
			angle = myangles_z * (M_PI*2 / 360);
			sr = sin(angle);
			cr = cos(angle);
			if(v_right)
			{
				v_right_x = sr*sp*cy+cr*-sy;
				v_right_y = sr*sp*sy+cr*cy;
				v_right_z = sr*cp;
			}
			if(v_up)
			{
				v_up_x = cr*sp*cy+-sr*-sy;
				v_up_y = cr*sp*sy+-sr*cy;
				v_up_z = cr*cp;
			}
		}
		else
		{
			if(v_right)
			{
				v_right_x = -sy;
				v_right_y = cy;
				v_right_z = 0;
			}
			if(v_up)
			{
				v_up_x = sp*cy;
				v_up_y = sp*sy;
				v_up_z = cp;
			}
		}
	}
}

void _Movetype_PushMove(float dt) // SV_PushMove
{
	float pushltime;
	//int pusherowner;
	//int i;
	//int num_moved;
	//int numcheckentities;
	int savesolid;
	bool rotated;
	vector move1, moveangle;
	vector a;
	vector pushorig, pushang;
	vector org;
	vector move;
	entity oldself;

	if(!vlen(self.move_velocity) && !vlen(self.move_avelocity))
	{
		self.ltime += dt;
		return;
	}

	switch(self.solid)
	{
	// LordHavoc: valid pusher types
	case SOLID_BSP:
	case SOLID_BBOX:
	case SOLID_SLIDEBOX:
	case SOLID_CORPSE: // LordHavoc: this would be weird...
		break;
	// LordHavoc: no collisions
	case SOLID_NOT:
	case SOLID_TRIGGER:
		
		self.move_origin = self.move_origin + self.move_velocity * dt;
		self.move_angles_x -= 360.0 * floor(self.move_angles_x * (1.0 / 360.0));
		self.move_angles_y -= 360.0 * floor(self.move_angles_y * (1.0 / 360.0));
		self.move_angles_z -= 360.0 * floor(self.move_angles_z * (1.0 / 360.0));
		self.ltime += dt;
		_Movetype_LinkEdict(true);
		return;
	default:
		printf("_Movetype_PushMove: entity %e with classname %s, unrecognized solid type %d\n", num_for_edict(self), self.classname, self.solid);
		return;
	}
	if(!self.modelindex || self.model == "null")
	{
		printf("_Movetype_PushMove: entity %e with classname %s, unusable modelindex %f\n", num_for_edict(self), self.classname, self.modelindex);
		return;
	}
	//pusherowner = self.owner;

	rotated = (self.move_angles * self.move_avelocity) > 0;

	move1 = self.move_velocity * dt;
	moveangle = self.move_avelocity * dt;

	a = -moveangle;

	// sets v_forward, v_right and v_up
	_Movetype_VectorAngles_FLU(a);

	pushorig = self.move_origin;
	pushang = self.move_angles;
	pushltime = self.ltime;

// move the pusher to its final position

	self.move_origin = self.move_origin + self.move_velocity * dt;
	self.move_angles = self.move_angles + self.move_avelocity * dt;
	self.ltime += dt;
	_Movetype_LinkEdict(true);

	//pushermodel = SV_GetModelFromEdict(pusher);
	//Matrix4x4_CreateFromQuakeEntity(&pusherfinalmatrix, PRVM_serveredictvector(pusher, origin)[0], PRVM_serveredictvector(pusher, origin)[1], PRVM_serveredictvector(pusher, origin)[2],
	  //PRVM_serveredictvector(pusher, angles)[0], PRVM_serveredictvector(pusher, angles)[1], PRVM_serveredictvector(pusher, angles)[2], 1);
	//Matrix4x4_Invert_Simple(&pusherfinalimatrix, &pusherfinalmatrix);

	savesolid = self.solid;

// see if any solid entities are inside the final position
	//num_moved = 0;

	entity e;
	if(self.move_movetype != MOVETYPE_FAKEPUSH) // Tenebrae's MOVETYPE_PUSH variant that doesn't push...
	for(e = findradius((self.absmin + self.absmax) * 0.5, vlen(self.absmax - self.absmin) * 0.5 + 1); e; e = e.chain)
	{
		if(e.owner == self)
			continue;

		if(self.owner == e)
			continue;

		//Con_Printf("%i %s ", PRVM_NUM_FOR_EDICT(check), PRVM_GetString(PRVM_serveredictstring(check, classname)));

		// tell any MOVETYPE_STEP entity that it may need to check for water transitions
		//check->priv.server->waterposition_forceupdate = true;

		//int checkcontents = pointcontents(e.move_origin);

		// if the entity is standing on the pusher, it will definitely be moved
		// if the entity is not standing on the pusher, but is in the pusher's
		// final position, move it
		if(!(e.move_flags & FL_ONGROUND) || e.move_groundentity != self)
		{
			//vector pushermins = self.mins;
			//vector pushermaxs = self.maxs;
			//vector checkorigin = e.origin;
			//vector checkmins = e.mins;
			//vector checkmaxs = e.maxs;
			//Collision_ClipToGenericEntity(&trace, pushermodel, pusher->priv.server->frameblend, &pusher->priv.server->skeleton, pushermins, pushermaxs, SUPERCONTENTS_BODY, &pusherfinalmatrix, 
				//&pusherfinalimatrix, checkorigin, checkmins, checkmaxs, checkorigin, checkcontents, collision_extendmovelength.value);
			tracebox(e.move_origin, e.mins, e.maxs, self.move_origin, MOVE_NOMONSTERS, e);
			if(!trace_startsolid)
			{
				//Con_Printf("- not in solid\n");
				continue;
			}
		}
		vector pivot = e.mins + 0.5 * (e.maxs - e.mins);
		//VectorClear(pivot);

		if(rotated)
		{
			vector org2;
			org = e.move_origin - self.move_origin;
			org += pivot;
			org2_x = (org * v_forward);
			org2_y = (org * v_right);
			org2_z = (org * v_up);
			move = org2 - org;
			move += move1;
		}
		else
			move = move1;

		//Con_Printf("- pushing %f %f %f\n", move[0], move[1], move[2]);

		//VectorCopy (PRVM_serveredictvector(check, origin), check->priv.server->moved_from);
		//VectorCopy (PRVM_serveredictvector(check, angles), check->priv.server->moved_fromangles);
		//moved_edicts[num_moved++] = PRVM_NUM_FOR_EDICT(check);

		// physics objects need better collisions than this code can do
		/*if(e.move_movetype == MOVETYPE_PHYSICS)
		{
			e.move_origin += move;
			oldself = self;
			self = e;
			_Movetype_LinkEdict(false);
			_Movetype_LinkEdict_TouchAreaGrid();
			self = oldself;
			continue;
		}*/

		// try moving the contacted entity
		self.solid = SOLID_NOT;
		oldself = self;
		self = e;
		if(!_Movetype_PushEntity(move, true))
		{
			// entity "check" got teleported
			self.angles_y += trace_fraction * moveangle_y;
			oldself.solid = savesolid;
			continue; // pushed enough
		}
		self = oldself;
		// FIXME: turn players specially
		e.angles_y += trace_fraction * moveangle_y;
		self.solid = savesolid;
		//Con_Printf("%s:%d frac %f startsolid %d bmodelstartsolid %d allsolid %d\n", __FILE__, __LINE__, trace.fraction, trace.startsolid, trace.bmodelstartsolid, trace.allsolid);

		// this trace.fraction < 1 check causes items to fall off of pushers
		// if they pass under or through a wall
		// the groundentity check causes items to fall off of ledges
		if(e.move_movetype != MOVETYPE_WALK && (trace_fraction < 1 || e.move_groundentity != self))
			e.move_flags &= ~FL_ONGROUND;

		// if it is still inside the pusher, block
		//vector pushermins = self.mins;
		//vector pushermaxs = self.maxs;
		//vector checkorigin = e.move_origin;
		//vector checkmins = e.mins;
		//vector checkmaxs = e.maxs; 
		//Collision_ClipToGenericEntity(&trace, pushermodel, pusher->priv.server->frameblend, &pusher->priv.server->skeleton, pushermins, pushermaxs, SUPERCONTENTS_BODY, 
				//&pusherfinalmatrix, &pusherfinalimatrix, checkorigin, checkmins, checkmaxs, checkorigin, checkcontents, collision_extendmovelength.value);
		tracebox(e.move_origin, e.mins, e.maxs, self.move_origin, MOVE_NOMONSTERS, e);
		if(trace_startsolid)
		{
			/*vector move2;
			if(SV_NudgeOutOfSolid_PivotIsKnownGood(check, pivot))
			{
				// hack to invoke all necessary movement triggers
				move2 = '0 0 0';
				if(!_Movetype_PushEntity(move2, true))
				{
					// entity "check" got teleported
					continue;
				}
				// we could fix it
				continue;
			}*/

			// still inside pusher, so it's really blocked

			// fail the move
			if(e.mins_x == e.maxs_x)
				continue;
			if(e.solid == SOLID_NOT || e.solid == SOLID_TRIGGER)
			{
				// corpse
				e.mins_x = e.mins_y = 0;
				e.maxs = e.mins;
				continue;
			}

			self.move_origin = pushorig;
			self.move_angles = pushang;
			self.ltime = pushltime;
			_Movetype_LinkEdict(true);

			// move back any entities we already moved
			/*for (i = 0;i < num_moved;i++)
			{
				prvm_edict_t *ed = PRVM_EDICT_NUM(moved_edicts[i]);
				VectorCopy (ed->priv.server->moved_from, PRVM_serveredictvector(ed, origin));
				VectorCopy (ed->priv.server->moved_fromangles, PRVM_serveredictvector(ed, angles));
				SV_LinkEdict(ed);
			}*/

			// if the pusher has a "blocked" function, call it, otherwise just stay in place until the obstacle is gone
			if(self.blocked)
			{
				self.move_time = time;
				other = e;
				self.blocked();
			}
			break;
		}
	}
	self.move_angles_x -= 360.0 * floor(self.move_angles_x * (1.0 / 360.0));
	self.move_angles_y -= 360.0 * floor(self.move_angles_y * (1.0 / 360.0));
	self.move_angles_z -= 360.0 * floor(self.move_angles_z * (1.0 / 360.0));
}

void _Movetype_Physics_Pusher(float dt) // SV_Physics_Pusher
{
	float oldltime, movetime;

	oldltime = self.ltime;

	if (self.nextthink < self.ltime + dt)
	{
		movetime = self.nextthink - self.ltime;
		if (movetime < 0)
			movetime = 0;
	}
	else
		movetime = dt;

	if (movetime)
		// advances PRVM_serveredictfloat(ent, ltime) if not blocked
		_Movetype_PushMove(movetime);

	if (self.nextthink > oldltime && self.nextthink <= self.ltime)
	{
		self.nextthink = 0;
		//time = dt;
		self.move_time = time;
		other = world;
		if(self.think)
			self.think();
	}
}

void _Movetype_Physics_Toss(float dt) // SV_Physics_Toss
{
	if(self.move_flags & FL_ONGROUND)
	{
		if(self.move_velocity_z >= 1/32)
			self.move_flags &= ~FL_ONGROUND;
		else if(!self.move_groundentity)
			return;
		else if(self.move_suspendedinair && wasfreed(self.move_groundentity))
		{
			self.move_groundentity = world;
			return;
		}
	}

	self.move_suspendedinair = false;

	_Movetype_CheckVelocity();

	if(self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS)
	{
		self.move_didgravity = 1;
		if(GRAVITY_UNAFFECTED_BY_TICRATE)
		{
			if(self.gravity)
				self.move_velocity_z -= 0.5 * dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
			else
				self.move_velocity_z -= 0.5 * dt * getstatf(STAT_MOVEVARS_GRAVITY);
		}
		else
		{
			if(self.gravity)
				self.move_velocity_z -= dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
			else
				self.move_velocity_z -= dt * getstatf(STAT_MOVEVARS_GRAVITY);
		}
	}

	self.move_angles = self.move_angles + self.move_avelocity * dt;

	float movetime, bump;
	movetime = dt;
	for(bump = 0; bump < MAX_CLIP_PLANES && movetime > 0; ++bump)
	{
		vector move;
		move = self.move_velocity * movetime;
		_Movetype_PushEntity(move, true);
		if(wasfreed(self))
			return;

		if(trace_startsolid)
		{
			_Movetype_UnstickEntity();
			_Movetype_PushEntity(move, false);
			if(wasfreed(self))
				return;
		}

		if(trace_fraction == 1)
			break;

		movetime *= 1 - min(1, trace_fraction);

		if(self.move_movetype == MOVETYPE_BOUNCEMISSILE)
		{
			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 2.0);
			self.move_flags &= ~FL_ONGROUND;
		}
		else if(self.move_movetype == MOVETYPE_BOUNCE)
		{
			float d, bouncefac, bouncestop;

			bouncefac = self.move_bounce_factor;     if(!bouncefac)  bouncefac = 0.5;
			bouncestop = self.move_bounce_stopspeed; if(!bouncestop) bouncestop = 60 / 800;
			if(self.gravity)
				bouncestop *= self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
			else
				bouncestop *= getstatf(STAT_MOVEVARS_GRAVITY);

			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 1 + bouncefac);

			d = trace_plane_normal * self.move_velocity;
			if(trace_plane_normal_z > 0.7 && d < bouncestop && d > -bouncestop)
			{
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			}
			else
				self.move_flags &= ~FL_ONGROUND;
		}
		else
		{
			self.move_velocity = _Movetype_ClipVelocity(self.move_velocity, trace_plane_normal, 1.0);
			if(trace_plane_normal_z > 0.7)
			{
				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
				if(trace_ent.solid == SOLID_BSP)
					self.move_suspendedinair = true;
				self.move_velocity = '0 0 0';
				self.move_avelocity = '0 0 0';
			}
			else
				self.move_flags &= ~FL_ONGROUND;
		}

		// DP revision 8905 (just, WHY...)
		if(self.move_movetype == MOVETYPE_BOUNCEMISSILE)
			break;

		// DP revision 8918 (WHY...)
		if(self.move_flags & FL_ONGROUND)
			break;
	}

	if(GRAVITY_UNAFFECTED_BY_TICRATE)
	if(self.move_didgravity > 0)
	if(!(self.move_flags & FL_ONGROUND))
	{
		if(self.gravity)
			self.move_velocity_z -= 0.5 * dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
		else
			self.move_velocity_z -= 0.5 * dt * getstatf(STAT_MOVEVARS_GRAVITY);
	}

	_Movetype_CheckWaterTransition(self);
}

void _Movetype_Physics_Frame(float movedt)
{
	self.move_didgravity = -1;
	switch(self.move_movetype)
	{
		case MOVETYPE_PUSH:
		case MOVETYPE_FAKEPUSH:
			_Movetype_Physics_Pusher(movedt);
			break;
		case MOVETYPE_NONE:
			break;
		case MOVETYPE_FOLLOW:
			error("SV_Physics_Follow not implemented");
			break;
		case MOVETYPE_NOCLIP:
			_Movetype_CheckWater(self);
			self.move_origin = self.move_origin + ticrate * self.move_velocity;
			self.move_angles = self.move_angles + ticrate * self.move_avelocity;
			_Movetype_LinkEdict(false);
			break;
		case MOVETYPE_STEP:
			error("SV_Physics_Step not implemented");
			break;
		case MOVETYPE_WALK:
			error("SV_Physics_Walk not implemented");
			break;
		case MOVETYPE_TOSS:
		case MOVETYPE_BOUNCE:
		case MOVETYPE_BOUNCEMISSILE:
		case MOVETYPE_FLYMISSILE:
		case MOVETYPE_FLY:
			_Movetype_Physics_Toss(movedt);
			break;
	}
}

void Movetype_Physics_NoMatchServer() // optimized
{
	float movedt;

	movedt = time - self.move_time;
	self.move_time = time;

	_Movetype_Physics_Frame(movedt);
	if(wasfreed(self))
		return;

	self.avelocity = self.move_avelocity;
	self.velocity = self.move_velocity;
	self.angles = self.move_angles;
	setorigin(self, self.move_origin);
}

void Movetype_Physics_MatchServer(bool sloppy)
{
	Movetype_Physics_MatchTicrate(ticrate, sloppy);
}

void Movetype_Physics_MatchTicrate(float tr, bool sloppy) // SV_Physics_Entity
{
	float n, i, dt, movedt;

	if(tr <= 0)
	{
		Movetype_Physics_NoMatchServer();
		return;
	}

	dt = time - self.move_time;

	movedt = tr;
	n = max(0, floor(dt / tr));
	dt -= n * tr;
	self.move_time += n * tr;

	if(!self.move_didgravity)
		self.move_didgravity = ((self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS) && !(self.move_flags & FL_ONGROUND));

	for(i = 0; i < n; ++i)
	{
		_Movetype_Physics_Frame(movedt);
		if(wasfreed(self))
			return;
	}

	self.avelocity = self.move_avelocity;

	if(dt > 0 && self.move_movetype != MOVETYPE_NONE && !(self.move_flags & FL_ONGROUND))
	{
		// now continue the move from move_time to time
		self.velocity = self.move_velocity;

		if(self.move_didgravity > 0)
		{
			if(GRAVITY_UNAFFECTED_BY_TICRATE)
			{
				if(self.gravity)
					self.velocity_z -= 0.5 * dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
				else
					self.velocity_z -= 0.5 * dt * getstatf(STAT_MOVEVARS_GRAVITY);
			}
			else
			{
				if(self.gravity)
					self.velocity_z -= dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
				else
					self.velocity_z -= dt * getstatf(STAT_MOVEVARS_GRAVITY);
			}
		}

		self.angles = self.move_angles + dt * self.avelocity;

		if(sloppy || self.movetype == MOVETYPE_NOCLIP)
		{
			setorigin(self, self.move_origin + dt * self.velocity);
		}
		else
		{
			_Movetype_PushEntityTrace(dt * self.velocity);
			if(!trace_startsolid)
				setorigin(self, trace_endpos);
		}

		if(self.move_didgravity > 0)
		{
			if(GRAVITY_UNAFFECTED_BY_TICRATE)
			{
				if(self.gravity)
					self.velocity_z -= 0.5 * dt * self.gravity * getstatf(STAT_MOVEVARS_GRAVITY);
				else
					self.velocity_z -= 0.5 * dt * getstatf(STAT_MOVEVARS_GRAVITY);
			}
		}
	}
	else
	{
		self.velocity = self.move_velocity;
		self.angles = self.move_angles;
		setorigin(self, self.move_origin);
	}
}
