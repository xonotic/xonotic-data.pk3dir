const float STAT_MOVEFLAGS = 225;
const float MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE = 4;
#define GRAVITY_UNAFFECTED_BY_TICRATE (getstati(STAT_MOVEFLAGS) & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE)

.entity move_groundentity; // FIXME add move_groundnetworkentity?
.float move_suspendedinair;
.float move_didgravity;

void _Movetype_CheckVelocity() // SV_CheckVelocity
{
}

#if 0
int Mod_Q1BSP_SuperContentsFromNativeContents(dp_model_t *model, int nativecontents)
{
	switch(nativecontents)
	{
		case CONTENTS_EMPTY:
			return 0;
		case CONTENTS_SOLID:
			return SUPERCONTENTS_SOLID | SUPERCONTENTS_OPAQUE;
		case CONTENTS_WATER:
			return SUPERCONTENTS_WATER;
		case CONTENTS_SLIME:
			return SUPERCONTENTS_SLIME;
		case CONTENTS_LAVA:
			return SUPERCONTENTS_LAVA | SUPERCONTENTS_NODROP;
		case CONTENTS_SKY:
			return SUPERCONTENTS_SKY | SUPERCONTENTS_NODROP | SUPERCONTENTS_OPAQUE; // to match behaviour of Q3 maps, let sky count as opaque
	}
	return 0;
}
int Mod_Q1BSP_NativeContentsFromSuperContents(dp_model_t *model, int supercontents)
{
	if (supercontents & (SUPERCONTENTS_SOLID | SUPERCONTENTS_BODY))
		return CONTENTS_SOLID;
	if (supercontents & SUPERCONTENTS_SKY)
		return CONTENTS_SKY;
	if (supercontents & SUPERCONTENTS_LAVA)
		return CONTENTS_LAVA;
	if (supercontents & SUPERCONTENTS_SLIME)
		return CONTENTS_SLIME;
	if (supercontents & SUPERCONTENTS_WATER)
		return CONTENTS_WATER;
	return CONTENTS_EMPTY;
}
static qboolean SV_CheckWater (prvm_edict_t *ent)
{
	prvm_prog_t *prog = SVVM_prog;
	int cont;
	int nNativeContents;
	vec3_t point;

	point[0] = PRVM_serveredictvector(ent, origin)[0];
	point[1] = PRVM_serveredictvector(ent, origin)[1];
	point[2] = PRVM_serveredictvector(ent, origin)[2] + PRVM_serveredictvector(ent, mins)[2] + 1;

	// DRESK - Support for Entity Contents Transition Event
	// NOTE: Some logic needed to be slightly re-ordered
	// to not affect performance and allow for the feature.

	// Acquire Super Contents Prior to Resets
	cont = SV_PointSuperContents(point);
	// Acquire Native Contents Here
	nNativeContents = Mod_Q1BSP_NativeContentsFromSuperContents(NULL, cont);

	// DRESK - Support for Entity Contents Transition Event
	if(PRVM_serveredictfloat(ent, watertype))
		// Entity did NOT Spawn; Check
		SV_CheckContentsTransition(ent, nNativeContents);


	PRVM_serveredictfloat(ent, waterlevel) = 0;
	PRVM_serveredictfloat(ent, watertype) = CONTENTS_EMPTY;
	cont = SV_PointSuperContents(point);
	if (cont & (SUPERCONTENTS_LIQUIDSMASK))
	{
		PRVM_serveredictfloat(ent, watertype) = nNativeContents;
		PRVM_serveredictfloat(ent, waterlevel) = 1;
		point[2] = PRVM_serveredictvector(ent, origin)[2] + (PRVM_serveredictvector(ent, mins)[2] + PRVM_serveredictvector(ent, maxs)[2])*0.5;
		if (SV_PointSuperContents(point) & (SUPERCONTENTS_LIQUIDSMASK))
		{
			PRVM_serveredictfloat(ent, waterlevel) = 2;
			point[2] = PRVM_serveredictvector(ent, origin)[2] + PRVM_serveredictvector(ent, view_ofs)[2];
			if (SV_PointSuperContents(point) & (SUPERCONTENTS_LIQUIDSMASK))
				PRVM_serveredictfloat(ent, waterlevel) = 3;
		}
	}

	return PRVM_serveredictfloat(ent, waterlevel) > 1;
}
static int SV_CheckContentsTransition(prvm_edict_t *ent, const int nContents)
{
	prvm_prog_t *prog = SVVM_prog;
	int bValidFunctionCall;

	// Default Valid Function Call to False
	bValidFunctionCall = false;

	if(PRVM_serveredictfloat(ent, watertype) != nContents)
	{ // Changed Contents
		// Acquire Contents Transition Function from QC
		if(PRVM_serveredictfunction(ent, contentstransition))
		{ // Valid Function; Execute
			// Assign Valid Function
			bValidFunctionCall = true;
			// Prepare Parameters (Original Contents, New Contents)
			// Original Contents
			PRVM_G_FLOAT(OFS_PARM0) = PRVM_serveredictfloat(ent, watertype);
			// New Contents
			PRVM_G_FLOAT(OFS_PARM1) = nContents;
			// Assign Self
			PRVM_serverglobaledict(self) = PRVM_EDICT_TO_PROG(ent);
			// Set Time
			PRVM_serverglobalfloat(time) = sv.time;
			// Execute VM Function
			prog->ExecuteProgram(prog, PRVM_serveredictfunction(ent, contentstransition), "contentstransition: NULL function");
		}
	}

	// Return if Function Call was Valid
	return bValidFunctionCall;
}

static void SV_CheckWaterTransition (prvm_edict_t *ent)
{
	vec3_t entorigin;
	prvm_prog_t *prog = SVVM_prog;
	// LordHavoc: bugfixes in this function are keyed to the sv_gameplayfix_bugfixedcheckwatertransition cvar - if this cvar is 0 then all the original bugs should be reenabled for compatibility
	int cont;
	VectorCopy(PRVM_serveredictvector(ent, origin), entorigin);
	cont = Mod_Q1BSP_NativeContentsFromSuperContents(NULL, SV_PointSuperContents(entorigin));
	if (!PRVM_serveredictfloat(ent, watertype))
	{
		// just spawned here
		if (!sv_gameplayfix_fixedcheckwatertransition.integer)
		{
			PRVM_serveredictfloat(ent, watertype) = cont;
			PRVM_serveredictfloat(ent, waterlevel) = 1;
			return;
		}
	}
	// DRESK - Support for Entity Contents Transition Event
	// NOTE: Call here BEFORE updating the watertype below,
	// and suppress watersplash sound if a valid function
	// call was made to allow for custom "splash" sounds.
	else if( !SV_CheckContentsTransition(ent, cont) )
	{ // Contents Transition Function Invalid; Potentially Play Water Sound
		// check if the entity crossed into or out of water
		if (sv_sound_watersplash.string && ((PRVM_serveredictfloat(ent, watertype) == CONTENTS_WATER || PRVM_serveredictfloat(ent, watertype) == CONTENTS_SLIME) != (cont == CONTENTS_WATER || cont == CONTENTS_SLIME)))
			SV_StartSound (ent, 0, sv_sound_watersplash.string, 255, 1, false, 1.0f);
	}

	if (cont <= CONTENTS_WATER)
	{
		PRVM_serveredictfloat(ent, watertype) = cont;
		PRVM_serveredictfloat(ent, waterlevel) = 1;
	}
	else
	{
		PRVM_serveredictfloat(ent, watertype) = CONTENTS_EMPTY;
		PRVM_serveredictfloat(ent, waterlevel) = sv_gameplayfix_fixedcheckwatertransition.integer ? 0 : cont;
	}
}
#endif

.float watertype;
.float waterlevel;
float Mod_Q1BSP_SuperContentsFromNativeContents(float nativecontents)
{
	switch(nativecontents)
	{
		case CONTENT_EMPTY:
			return 0;
		case CONTENT_SOLID:
			return DPCONTENTS_SOLID | DPCONTENTS_OPAQUE;
		case CONTENT_WATER:
			return DPCONTENTS_WATER;
		case CONTENT_SLIME:
			return DPCONTENTS_SLIME;
		case CONTENT_LAVA:
			return DPCONTENTS_LAVA | DPCONTENTS_NODROP;
		case CONTENT_SKY:
			return DPCONTENTS_SKY | DPCONTENTS_NODROP | DPCONTENTS_OPAQUE; // to match behaviour of Q3 maps, let sky count as opaque
	}
	return 0;
}

float Mod_Q1BSP_NativeContentsFromSuperContents(float supercontents)
{
	if (supercontents & (DPCONTENTS_SOLID | DPCONTENTS_BODY))
		return CONTENT_SOLID;
	if (supercontents & DPCONTENTS_SKY)
		return CONTENT_SKY;
	if (supercontents & DPCONTENTS_LAVA)
		return CONTENT_LAVA;
	if (supercontents & DPCONTENTS_SLIME)
		return CONTENT_SLIME;
	if (supercontents & DPCONTENTS_WATER)
		return CONTENT_WATER;
	return CONTENT_EMPTY;
}

float _Movetype_CheckWater(entity ent) // SV_CheckWater
{
	float supercontents;
	float nativecontents;
	vector point;

	point = ent.move_origin;
	point_z += (ent.mins_z + 1);

	nativecontents = pointcontents(point);

	if(ent.watertype)
	if(ent.watertype != nativecontents)
	{
		print(sprintf("_Movetype_CheckWater(): Original: '%d', New: '%d'\n", ent.watertype, nativecontents));
		//ent.contentstransition(ent.watertype, contents);
	}

	ent.waterlevel = 0;
	ent.watertype = CONTENT_EMPTY;

	supercontents = Mod_Q1BSP_SuperContentsFromNativeContents(nativecontents);
	//supercontents = Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point));
	if(supercontents & DPCONTENTS_LIQUIDSMASK)
	{
		ent.watertype = nativecontents;
		ent.waterlevel = 1;
		point_y = (ent.origin_y + ((ent.mins_z + ent.maxs_y) * 0.5));
		if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
		{
			ent.waterlevel = 2;
			point_y = ent.origin_y + ent.view_ofs_y;
			if(Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(point)) & DPCONTENTS_LIQUIDSMASK)
				ent.waterlevel = 3;
		}
	}

	return (ent.waterlevel > 1);
}

#if 0
void _Movetype_CheckContentsTransition(entity ent, float contents)
{
	if(ent.watertype != contents)
	{
		print(sprintf("_Movetype_CheckWaterTransition(): Original: '%d', New: '%d'\n", ent.watertype, contents));
		//ent.contentstransition(ent.watertype, contents);
	}
}
#endif

float autocvar_sv_gameplayfix_fixedcheckwatertransition;
void _Movetype_CheckWaterTransition(entity ent) // SV_CheckWaterTransition
{
	float contents = pointcontents(ent.move_origin);
	
	if(!ent.watertype)
	{
		// just spawned here
		if(!autocvar_sv_gameplayfix_fixedcheckwatertransition)
		{
			ent.watertype = contents;
			ent.waterlevel = 1;
			return;
		}
	}
	//else if(!_Movetype_CheckContentsTransition(ent, contents))
	//{
		//if (sv_sound_watersplash.string && ((PRVM_serveredictfloat(ent, watertype) == CONTENTS_WATER || PRVM_serveredictfloat(ent, watertype) == CONTENTS_SLIME) != (cont == CONTENTS_WATER || cont == CONTENTS_SLIME)))
		//	SV_StartSound (ent, 0, sv_sound_watersplash.string, 255, 1, false, 1.0f);
	//}
	else if(ent.watertype != contents)
	{
		print(sprintf("_Movetype_CheckWaterTransition(): Origin: %s, Direct: '%d', Original: '%d', New: '%d'\n", vtos(ent.move_origin), pointcontents(ent.move_origin), ent.watertype, contents));
		//ent.contentstransition(ent.watertype, contents);
	}

	if(contents <= CONTENT_WATER)
	{
		ent.watertype = contents;
		ent.waterlevel = 1;
	}
	else
	{
		ent.watertype = CONTENT_EMPTY;
		ent.waterlevel = (autocvar_sv_gameplayfix_fixedcheckwatertransition ? 0 : contents);
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

			trace_allsolid = FALSE;
			trace_startsolid = FALSE;
			trace_fraction = 1;
			trace_inwater = FALSE;
			trace_inopen = TRUE;
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
	float cont;
	org = self.move_origin + ofs;

	cont = self.dphitcontentsmask;
	self.dphitcontentsmask = DPCONTENTS_SOLID;
	tracebox(self.move_origin, self.mins, self.maxs, self.move_origin, MOVE_NOMONSTERS, self);
	self.dphitcontentsmask = cont;

	if(trace_startsolid)
		return TRUE;

	if(vlen(trace_endpos - self.move_origin) > 0.0001)
		self.move_origin = trace_endpos;
	return FALSE;
}

float _Movetype_UnstickEntity() // SV_UnstickEntity
{
	if(!_Movetype_TestEntityPosition('0 0 0'))
		return TRUE;
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
	dprint(sprintf(_("Can't unstick an entity (edict: %d, classname: %s, origin: %s)\n"), num_for_edict(self), self.classname, vtos(self.move_origin)));
	return FALSE;
:success
	dprint(sprintf(_("Sucessfully unstuck an entity (edict: %d, classname: %s, origin: %s)\n"), num_for_edict(self), self.classname, vtos(self.move_origin)));
	_Movetype_LinkEdict(TRUE);
	return TRUE;
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

#define MAX_CLIP_PLANES 5
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

	self.move_suspendedinair = FALSE;

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
		_Movetype_PushEntity(move, TRUE);
		if(wasfreed(self))
			return;

		if(trace_startsolid)
		{
			_Movetype_UnstickEntity();
			_Movetype_PushEntity(move, FALSE);
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
					self.move_suspendedinair = TRUE;
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
			_Movetype_LinkEdict(FALSE);
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

void Movetype_Physics_MatchServer(float sloppy)
{
	Movetype_Physics_MatchTicrate(ticrate, sloppy);
}

void Movetype_Physics_MatchTicrate(float tr, float sloppy) // SV_Physics_Entity
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
