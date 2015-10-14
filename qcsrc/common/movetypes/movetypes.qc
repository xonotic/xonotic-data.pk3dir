#include "include.qh"
#include "../physics.qh"

#if defined(CSQC)
	#include "../../client/defs.qh"
	#include "../stats.qh"
	#include "../util.qh"
	#include "movetypes.qh"
	#include "../../lib/csqcmodel/common.qh"
	#include "../../server/t_items.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../../server/autocvars.qh"
#endif

void _Movetype_WallFriction(vector stepnormal)  // SV_WallFriction
{
	/*float d, i;
	vector into, side;
	makevectors(self.v_angle);
	d = (stepnormal * v_forward) + 0.5;

	if(d < 0)
	{
	    i = (stepnormal * self.move_velocity);
	    into = i * stepnormal;
	    side = self.move_velocity - into;
	    self.move_velocity_x = side.x * (1 * d);
	    self.move_velocity_y = side.y * (1 * d);
	}*/
}

vector planes[MAX_CLIP_PLANES];
int _Movetype_FlyMove(float dt, bool applygravity, vector stepnormal, float stepheight) // SV_FlyMove
{SELFPARAM();
	int blocked = 0, bumpcount;
	int i, j, numplanes = 0;
	float time_left = dt, grav = 0;
	vector push;
	vector primal_velocity, original_velocity, restore_velocity;

	for(i = 0; i < MAX_CLIP_PLANES; ++i)
		planes[i] = '0 0 0';

	if(applygravity)
	{
		self.move_didgravity = 1;
		grav = dt * (PHYS_ENTGRAVITY(self) ? PHYS_ENTGRAVITY(self) : 1) * PHYS_GRAVITY;

		if(!GAMEPLAYFIX_NOGRAVITYONGROUND || !(self.move_flags & FL_ONGROUND))
		{
			if(GRAVITY_UNAFFECTED_BY_TICRATE)
				self.move_velocity_z -= grav * 0.5;
			else
				self.move_velocity_z -= grav;
		}
	}

	original_velocity = primal_velocity = restore_velocity = self.move_velocity;

	for(bumpcount = 0;bumpcount < MAX_CLIP_PLANES;bumpcount++)
	{
		if(self.move_velocity == '0 0 0')
			break;

		push = self.move_velocity * time_left;
		vector prev_origin = self.move_origin;
		_Movetype_PushEntity(push, true);
		if(trace_startsolid && self.move_origin != prev_origin)
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
			self.move_velocity = restore_velocity;
			return 3;
		}

		if(trace_fraction == 1)
			break;

		float my_trace_fraction = trace_fraction;
		vector my_trace_plane_normal = trace_plane_normal;

		if(trace_plane_normal_z)
		{
			if(trace_plane_normal_z > 0.7)
			{
				// floor
				blocked |= 1;

				if(!trace_ent)
				{
					//dprint("_Movetype_FlyMove: !trace_ent\n");
					trace_ent = world;
				}

				self.move_flags |= FL_ONGROUND;
				self.move_groundentity = trace_ent;
			}
		}
		else if(stepheight)
		{
			// step - handle it immediately
			vector org = self.move_origin;
			vector steppush = '0 0 1' * stepheight;

			_Movetype_PushEntity(steppush, true);
			if(trace_startsolid && self.move_origin != org)
			{
				blocked |= 8;
				break;
			}
			_Movetype_PushEntity(push, true);
			if(trace_startsolid && self.move_origin != org)
			{
				blocked |= 8;
				break;
			}
			float trace2_fraction = trace_fraction;
			steppush = '0 0 1' * (org_z - self.move_origin_z);
			_Movetype_PushEntity(steppush, true);
			if(trace_startsolid && self.move_origin != org)
			{
				blocked |= 8;
				break;
			}

			// accept the new position if it made some progress...
			if(fabs(self.move_origin_x - org_x) >= 0.03125 || fabs(self.move_origin_y - org_y) >= 0.03125)
			{
				trace_endpos = self.move_origin;
				time_left *= 1 - trace2_fraction;
				numplanes = 0;
				continue;
			}
			else
				self.move_origin = org;
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
			original_velocity = self.move_velocity;
			numplanes = 0;
		}

		time_left *= 1 - my_trace_fraction;

		// clipped to another plane
		if(numplanes >= MAX_CLIP_PLANES)
		{
			// this shouldn't really happen
			self.move_velocity = '0 0 0';
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
			self.move_velocity = new_velocity;
		}
		else
		{
			// go along the crease
			if(numplanes != 2)
			{
				self.move_velocity = '0 0 0';
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
			float d = (dir * self.move_velocity);
			self.move_velocity = dir * d;
		}

		// if current velocity is against the original velocity,
		// stop dead to avoid tiny occilations in sloping corners
		if((self.move_velocity * primal_velocity) <= 0)
		{
			self.move_velocity = '0 0 0';
			break;
		}
	}

	// LordHavoc: this came from QW and allows you to get out of water more easily
	if(GAMEPLAYFIX_EASIERWATERJUMP && (self.move_flags & FL_WATERJUMP) && !(blocked & 8))
		self.move_velocity = primal_velocity;

	if(applygravity)
	{
		if(!GAMEPLAYFIX_NOGRAVITYONGROUND || !(self.move_flags & FL_ONGROUND))
		{
			if(GRAVITY_UNAFFECTED_BY_TICRATE)
				self.move_velocity_z -= grav * 0.5f;
		}
	}

	return blocked;
}

void _Movetype_CheckVelocity()  // SV_CheckVelocity
{
	// if(vlen(self.move_velocity) < 0.0001)
	// self.move_velocity = '0 0 0';
}

bool _Movetype_CheckWater(entity ent)  // SV_CheckWater
{
	vector point = ent.move_origin;
	point.z += (ent.mins.z + 1);

	int nativecontents = pointcontents(point);
	if(ent.move_watertype && ent.move_watertype != nativecontents)
	{
		// dprintf("_Movetype_CheckWater(): Original: '%d', New: '%d'\n", ent.move_watertype, nativecontents);
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
		point.y = (ent.origin.y + ((ent.mins.z + ent.maxs.y) * 0.5));
		if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
		{
			ent.move_waterlevel = 2;
			point.y = ent.origin.y + ent.view_ofs.y;
			if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
				ent.move_waterlevel = 3;
		}
	}

	return ent.move_waterlevel > 1;
}

void _Movetype_CheckWaterTransition(entity ent)  // SV_CheckWaterTransition
{
	int contents = pointcontents(ent.move_origin);

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
		// dprintf("_Movetype_CheckWaterTransition(): Origin: %s, Direct: '%d', Original: '%d', New: '%d'\n", vtos(ent.move_origin), pointcontents(ent.move_origin), ent.move_watertype, contents);
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

void _Movetype_Impact(entity oth)  // SV_Impact
{SELFPARAM();
	entity oldother = other;

	if(self.move_touch)
	{
		other = oth;

		self.move_touch();

		other = oldother;
	}

	if(oth.move_touch)
	{
		other = self;

		WITH(entity, self, oth, oth.move_touch());

		other = oldother;
	}
}

void _Movetype_LinkEdict_TouchAreaGrid()  // SV_LinkEdict_TouchAreaGrid
{SELFPARAM();
	entity oldother = other;

	for (entity e = findradius(0.5 * (self.absmin + self.absmax), 0.5 * vlen(self.absmax - self.absmin)); e; e = e.chain)
	{
		if(e.move_touch && boxesoverlap(e.absmin, e.absmax, this.absmin, this.absmax))
		{
			setself(e);
			other = this;

			trace_allsolid = false;
			trace_startsolid = false;
			trace_fraction = 1;
			trace_inwater = false;
			trace_inopen = true;
			trace_endpos = e.origin;
			trace_plane_normal = '0 0 1';
			trace_plane_dist = 0;
			trace_ent = this;

			e.move_touch();
		}
	}

	other = oldother;
	setself(this);
}

void _Movetype_LinkEdict(bool touch_triggers)  // SV_LinkEdict
{SELFPARAM();
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
	mi += self.move_origin;
	ma += self.move_origin;

	if(self.move_flags & FL_ITEM)
	{
		mi.x -= 15;
		mi.y -= 15;
		mi.z -= 1;
		ma.x += 15;
		ma.y += 15;
		ma.z += 1;
	}
	else
	{
		mi.x -= 1;
		mi.y -= 1;
		mi.z -= 1;
		ma.x += 1;
		ma.y += 1;
		ma.z += 1;
	}

	self.absmin = mi;
	self.absmax = ma;

	if(touch_triggers)
		_Movetype_LinkEdict_TouchAreaGrid();
}

bool _Movetype_TestEntityPosition(vector ofs)  // SV_TestEntityPosition
{SELFPARAM();
//	vector org = self.move_origin + ofs;

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

bool _Movetype_UnstickEntity()  // SV_UnstickEntity
{SELFPARAM();
	if(!_Movetype_TestEntityPosition('0 0 0')) return true;
	if(!_Movetype_TestEntityPosition('-1 0 0')) goto success;
	if(!_Movetype_TestEntityPosition('1 0 0')) goto success;
	if(!_Movetype_TestEntityPosition('0 -1 0')) goto success;
	if(!_Movetype_TestEntityPosition('0 1 0')) goto success;
	if(!_Movetype_TestEntityPosition('-1 -1 0')) goto success;
	if(!_Movetype_TestEntityPosition('1 -1 0')) goto success;
	if(!_Movetype_TestEntityPosition('-1 1 0')) goto success;
	if(!_Movetype_TestEntityPosition('1 1 0')) goto success;
	for (int i = 1; i <= 17; ++i)
	{
		if(!_Movetype_TestEntityPosition('0 0 -1' * i)) goto success;
		if(!_Movetype_TestEntityPosition('0 0 1' * i)) goto success;
	}
	LOG_TRACEF("Can't unstick an entity (edict: %d, classname: %s, origin: %s)\n",
		num_for_edict(self), self.classname, vtos(self.move_origin));
	return false;
	: success;
	LOG_TRACEF("Sucessfully unstuck an entity (edict: %d, classname: %s, origin: %s)\n",
		num_for_edict(self), self.classname, vtos(self.move_origin));
	_Movetype_LinkEdict(true);
	return true;
}

vector _Movetype_ClipVelocity(vector vel, vector norm, float f)  // SV_ClipVelocity
{
	vel -= ((vel * norm) * norm) * f;

	if(vel.x > -0.1 && vel.x < 0.1) vel.x = 0;
	if(vel.y > -0.1 && vel.y < 0.1) vel.y = 0;
	if(vel.z > -0.1 && vel.z < 0.1) vel.z = 0;

	return vel;
}

void _Movetype_PushEntityTrace(vector push)
{SELFPARAM();
	vector end = self.move_origin + push;
	int type;
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

float _Movetype_PushEntity(vector push, bool failonstartsolid)  // SV_PushEntity
{SELFPARAM();
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
// matrix version of makevectors, sets v_forward, v_right and v_up
void makevectors_matrix(vector myangles)  // AngleVectorsFLU
{
	v_forward = v_right = v_up = '0 0 0';

	float y = myangles.y * (M_PI * 2 / 360);
	float sy = sin(y);
	float cy = cos(y);
	float p = myangles.x * (M_PI * 2 / 360);
	float sp = sin(p);
	float cp = cos(p);
	if(v_forward)
	{
		v_forward.x = cp * cy;
		v_forward.y = cp * sy;
		v_forward.z = -sp;
	}
	if(v_right || v_up)
	{
		if(myangles.z)
		{
			float r = myangles.z * (M_PI * 2 / 360);
			float sr = sin(r);
			float cr = cos(r);
			if(v_right)
			{
				v_right.x = sr * sp * cy + cr * -sy;
				v_right.y = sr * sp * sy + cr * cy;
				v_right.z = sr * cp;
			}
			if(v_up)
			{
				v_up.x = cr * sp * cy + -sr * -sy;
				v_up.y = cr * sp * sy + -sr * cy;
				v_up.z = cr * cp;
			}
		}
		else
		{
			if(v_right)
			{
				v_right.x = -sy;
				v_right.y = cy;
				v_right.z = 0;
			}
			if(v_up)
			{
				v_up.x = sp * cy;
				v_up.y = sp * sy;
				v_up.z = cp;
			}
		}
	}
}

void _Movetype_Physics_Frame(float movedt)
{SELFPARAM();
	self.move_didgravity = -1;
	switch (self.move_movetype)
	{
		case MOVETYPE_PUSH:
		case MOVETYPE_FAKEPUSH:
			_Movetype_Physics_Pusher(movedt);
			break;
		case MOVETYPE_NONE:
			break;
		case MOVETYPE_FOLLOW:
			_Movetype_Physics_Follow();
			break;
		case MOVETYPE_NOCLIP:
			_Movetype_CheckWater(self);
			self.move_origin = self.move_origin + TICRATE * self.move_velocity;
			self.move_angles = self.move_angles + TICRATE * self.move_avelocity;
			_Movetype_LinkEdict(false);
			break;
		case MOVETYPE_STEP:
			_Movetype_Physics_Step(movedt);
			break;
		case MOVETYPE_WALK:
			_Movetype_Physics_Walk(movedt);
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

void Movetype_Physics_NoMatchServer()  // optimized
{SELFPARAM();
	float movedt = time - self.move_time;
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
	Movetype_Physics_MatchTicrate(TICRATE, sloppy);
}

void Movetype_Physics_MatchTicrate(float tr, bool sloppy)  // SV_Physics_Entity
{SELFPARAM();
	if(tr <= 0)
	{
		Movetype_Physics_NoMatchServer();
		return;
	}

	float dt = time - self.move_time;

	int n = max(0, floor(dt / tr));
	dt -= n * tr;
	self.move_time += n * tr;

	if(!self.move_didgravity)
		self.move_didgravity = ((self.move_movetype == MOVETYPE_BOUNCE || self.move_movetype == MOVETYPE_TOSS) && !(self.move_flags & FL_ONGROUND));

	for (int i = 0; i < n; ++i)
	{
		_Movetype_Physics_Frame(tr);
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
			self.velocity_z -= (GRAVITY_UNAFFECTED_BY_TICRATE ? 0.5 : 1)
			    * dt
			    * (self.gravity ? self.gravity : 1)
			    * PHYS_GRAVITY;
		}

		self.angles = self.move_angles + dt * self.avelocity;

		if(sloppy || self.move_movetype == MOVETYPE_NOCLIP)
		{
			setorigin(self, self.move_origin + dt * self.velocity);
		}
		else
		{
			_Movetype_PushEntityTrace(dt * self.velocity);
			if(!trace_startsolid)
				setorigin(self, trace_endpos);
		}

		if(self.move_didgravity > 0 && GRAVITY_UNAFFECTED_BY_TICRATE)
			self.velocity_z -= 0.5 * dt * (self.gravity ? self.gravity : 1) * PHYS_GRAVITY;
	}
	else
	{
		self.velocity = self.move_velocity;
		self.angles = self.move_angles;
		setorigin(self, self.move_origin);
	}
}
