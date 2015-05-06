#include "movetypes.qh"
#include "_all.qh"

#include "t_items.qh"

#include "../common/stats.qh"
#include "../common/util.qh"

#include "../csqcmodellib/common.qh"


const int MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE = 4;
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
	point.z += (ent.mins.z + 1);

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
		point.y = (ent.origin.y + ((ent.mins.z + ent.maxs.y) * 0.5));
		if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
		{
			ent.move_waterlevel = 2;
			point.y = ent.origin.y + ent.view_ofs.y;
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

	if(vel.x > -0.1 && vel.x < 0.1) vel.x = 0;
	if(vel.y > -0.1 && vel.y < 0.1) vel.y = 0;
	if(vel.z > -0.1 && vel.z < 0.1) vel.z = 0;

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

const float MAX_CLIP_PLANES = 5;
void _Movetype_Physics_Toss(float dt) // SV_Physics_Toss
{
	if(self.move_flags & FL_ONGROUND)
	{
		if(self.move_velocity.z >= 1/32)
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
			if(trace_plane_normal.z > 0.7 && d < bouncestop && d > -bouncestop)
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
			if(trace_plane_normal.z > 0.7)
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
			error("SV_Physics_Pusher not implemented");
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
