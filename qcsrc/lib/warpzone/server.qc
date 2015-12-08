#include "server.qh"

#include "common.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../../common/constants.qh"
	#include "../../common/triggers/subs.qh"
	#include "../../common/util.qh"
	#include "../../server/command/common.qh"
	#include "../../server/constants.qh"
	#include "../../server/defs.qh"
#endif

#ifdef WARPZONELIB_KEEPDEBUG
#define WARPZONELIB_REMOVEHACK
#endif

// for think function
.vector warpzone_save_origin;
.vector warpzone_save_angles;
.vector warpzone_save_eorigin;
.vector warpzone_save_eangles;

// for all entities
.vector warpzone_oldorigin, warpzone_oldvelocity, warpzone_oldangles;
.float warpzone_teleport_time;
.float warpzone_teleport_finishtime;
.entity warpzone_teleport_zone;

void WarpZone_StoreProjectileData(entity e)
{
#ifdef SVQC
	e.warpzone_oldorigin = e.origin;
	e.warpzone_oldvelocity = e.velocity;
	e.warpzone_oldangles = e.angles;
#elif defined(CSQC)
	e.warpzone_oldorigin = e.move_origin;
	e.warpzone_oldvelocity = e.move_velocity;
	e.warpzone_oldangles = e.move_angles;
#endif
}

void WarpZone_TeleportPlayer(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity)
{
#ifdef SVQC
	setorigin (player, to); // NOTE: this also aborts the move, when this is called by touch
	player.oldorigin = to; // for DP's unsticking
	player.angles = to_angles;
	player.fixangle = true;
	player.velocity = to_velocity;
#elif defined(CSQC)
	player.move_origin = to;
	player.move_angles = to_angles;
	player.move_velocity = to_velocity;
#endif

	BITXOR_ASSIGN(player.effects, EF_TELEPORT_BIT);

	if(IS_PLAYER(player))
#ifdef SVQC
		BITCLR_ASSIGN(player.flags, FL_ONGROUND);
#elif defined(CSQC)
		BITCLR_ASSIGN(player.move_flags, FL_ONGROUND);
#endif

	WarpZone_PostTeleportPlayer_Callback(player);
}

#ifdef SVQC
bool WarpZone_Teleported_Send(entity to, int sf)
{SELFPARAM();
	WriteHeader(MSG_ENTITY, ENT_CLIENT_WARPZONE_TELEPORTED);
	WriteCoord(MSG_ENTITY, self.angles.x);
	WriteCoord(MSG_ENTITY, self.angles.y);
	WriteCoord(MSG_ENTITY, self.angles.z);
	return true;
}
#endif

float WarpZone_Teleport(entity wz, entity player, float f0, float f1)
{
	vector o0, a0, v0, o1, a1, v1, o10;

#ifdef SVQC
	o0 = player.origin + player.view_ofs;
	v0 = player.velocity;
	a0 = player.angles;
#elif defined(CSQC)
	o0 = player.move_origin + player.view_ofs;
	v0 = player.move_velocity;
	a0 = player.move_angles;
#endif

	o10 = o1 = WarpZone_TransformOrigin(wz, o0);
	v1 = WarpZone_TransformVelocity(wz, v0);
	if (!IS_NOT_A_CLIENT(player))
		a1 = WarpZone_TransformVAngles(wz, PHYS_INPUT_ANGLES(player));
	else
		a1 = WarpZone_TransformAngles(wz, a0);

	if(f0 != 0 || f1 != 0)
	{
		// retry last move but behind the warpzone!
		// we must first go back as far as we can, then forward again, to not cause double touch events!

		tracebox(o1 - player.view_ofs + v1 * frametime * f1, player.mins, player.maxs, o1 - player.view_ofs + v1 * frametime * f0, MOVE_WORLDONLY, player);
		{
			entity own;
			own = player.owner;
			player.owner = world;
			tracebox(trace_endpos, player.mins, player.maxs, o1 - player.view_ofs + v1 * frametime * f1, MOVE_NORMAL, player); // this should get us through the warpzone
			player.owner = own;
		}
		o1 = trace_endpos + player.view_ofs;

		float d, dv, md;
		md = max(vlen(player.mins), vlen(player.maxs));
		d = WarpZone_TargetPlaneDist(wz, o1);
		dv = WarpZone_TargetPlaneDist(wz, v1);
		if(d < 0)
			o1 = o1 - v1 * (d / dv);
	}

	// put him out of solid
	tracebox(o1 - player.view_ofs, player.mins, player.maxs, o1 - player.view_ofs, MOVE_NOMONSTERS, player);
	if(trace_startsolid)
	{
		setorigin(player, o1 - player.view_ofs);
		if(WarpZoneLib_MoveOutOfSolid(player))
		{
			o1 = player.origin + player.view_ofs;
			setorigin(player, o0 - player.view_ofs);
		}
		else
		{
			LOG_INFO("would have to put player in solid, won't do that\n");
			setorigin(player, o0 - player.view_ofs);
			return 0;
		}
	}

	// do the teleport
	WarpZone_RefSys_Add(player, wz);
	WarpZone_TeleportPlayer(wz, player, o1 - player.view_ofs, a1, v1);
	WarpZone_StoreProjectileData(player);
	player.warpzone_teleport_time = time;
	player.warpzone_teleport_finishtime = time;
	player.warpzone_teleport_zone = wz;

#ifdef SVQC
	// prevent further teleports back
	float dt = (o1 - o10) * v1 * (1 / (v1 * v1));
	if(dt < PHYS_INPUT_FRAMETIME)
		player.warpzone_teleport_finishtime += PHYS_INPUT_FRAMETIME - dt;
#endif

#ifndef WARPZONE_USE_FIXANGLE
	#ifdef SVQC
	if(IS_VEHICLE(player) && player.owner)
		player = player.owner; // hax
	if(IS_PLAYER(player))
	{
		// instead of fixangle, send the transform to the client for smoother operation
		player.fixangle = false;

		entity ts = new(warpzone_teleported);
		setmodel(ts, MDL_Null);
		ts.SendEntity = WarpZone_Teleported_Send;
		ts.SendFlags = 0xFFFFFF;
		ts.drawonlytoclient = player;
		ts.think = SUB_Remove_self;
		ts.nextthink = time + 1;
		ts.owner = player;
		ts.enemy = wz;
		ts.effects = EF_NODEPTHTEST;
		ts.angles = wz.warpzone_transform;
	}
	#elif defined(CSQC)
	setproperty(VF_CL_VIEWANGLES, WarpZone_TransformVAngles(wz, getpropertyvec(VF_CL_VIEWANGLES)));
	//if(checkextension("DP_CSQC_ROTATEMOVES"))
		//CL_RotateMoves(wz.warpzone_transform);
	#endif
#endif

	return 1;
}

void WarpZone_Touch ()
{SELFPARAM();
	if(other.classname == "trigger_warpzone")
		return;

	if(time <= other.warpzone_teleport_finishtime) // already teleported this frame
		return;

	// FIXME needs a better check to know what is safe to teleport and what not
#ifdef SVQC
	if(other.movetype == MOVETYPE_NONE || other.movetype == MOVETYPE_FOLLOW || other.tag_entity)
#elif defined(CSQC)
	if(other.move_movetype == MOVETYPE_NONE || other.move_movetype == MOVETYPE_FOLLOW || other.tag_networkentity)
#endif
		return;

	if(WarpZoneLib_ExactTrigger_Touch())
		return;

#ifdef SVQC
	if(WarpZone_PlaneDist(self, other.origin + other.view_ofs) >= 0) // wrong side of the trigger_warpzone (don't teleport yet)
#elif defined(CSQC)
	if(WarpZone_PlaneDist(self, other.move_origin + other.view_ofs) >= 0) // wrong side of the trigger_warpzone (don't teleport yet)
#endif
		return;

	float f;
	// number of frames we need to go back:
	//   dist = 16*sqrt(2) qu
	//   dist ~ 24 qu
	//   24 qu = v*t
	//   24 qu = v*frametime*n
	//       n = 24 qu/(v*frametime)
	// for clients go only one frame though, may be too irritating otherwise
	// but max 0.25 sec = 0.25/frametime frames
	//       24/(0.25/frametime)
	//       96*frametime
	float d;
	d = 24 + max(vlen(other.mins), vlen(other.maxs));
	if(IS_NOT_A_CLIENT(other))
	#ifdef SVQC
		f = -d / bound(frametime * d * 1, frametime * vlen(other.velocity), d);
	#elif defined(CSQC)
		f = -d / bound(frametime * d * 1, frametime * vlen(other.move_velocity), d);
	#endif
	else
		f = -1;
	if(WarpZone_Teleport(self, other, f, 0))
	{
#ifdef SVQC
		string save1, save2;
		activator = other;

		save1 = self.target; self.target = string_null;
		save2 = self.target3; self.target3 = string_null;
		SUB_UseTargets();
		if (!self.target) self.target = save1;
		if (!self.target3) self.target3 = save2;

		setself(self.enemy);
		save1 = self.target; self.target = string_null;
		save2 = self.target2; self.target2 = string_null;
		SUB_UseTargets();
		if (!self.target) self.target = save1;
		if (!self.target2) self.target2 = save2;
		setself(this);
#endif
	}
	else
	{
		LOG_TRACE("WARPZONE FAIL AHAHAHAHAH))\n");
	}
}

#ifdef SVQC
bool WarpZone_Send(entity to, int sendflags)
{SELFPARAM();
	WriteHeader(MSG_ENTITY, ENT_CLIENT_WARPZONE);

	// we must send this flag for clientside to match properly too
	int f = 0;
	if(self.warpzone_isboxy)
		BITSET_ASSIGN(f, 1);
	if(self.warpzone_fadestart)
		BITSET_ASSIGN(f, 2);
	if(self.origin != '0 0 0')
		BITSET_ASSIGN(f, 4);
	WriteByte(MSG_ENTITY, f);

	// we need THESE to render the warpzone (and cull properly)...
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, self.origin.x);
		WriteCoord(MSG_ENTITY, self.origin.y);
		WriteCoord(MSG_ENTITY, self.origin.z);
	}

	WriteShort(MSG_ENTITY, self.modelindex);
	WriteCoord(MSG_ENTITY, self.mins.x);
	WriteCoord(MSG_ENTITY, self.mins.y);
	WriteCoord(MSG_ENTITY, self.mins.z);
	WriteCoord(MSG_ENTITY, self.maxs.x);
	WriteCoord(MSG_ENTITY, self.maxs.y);
	WriteCoord(MSG_ENTITY, self.maxs.z);
	WriteByte(MSG_ENTITY, bound(1, self.scale * 16, 255));

	// we need THESE to calculate the proper transform
	WriteCoord(MSG_ENTITY, self.warpzone_origin.x);
	WriteCoord(MSG_ENTITY, self.warpzone_origin.y);
	WriteCoord(MSG_ENTITY, self.warpzone_origin.z);
	WriteCoord(MSG_ENTITY, self.warpzone_angles.x);
	WriteCoord(MSG_ENTITY, self.warpzone_angles.y);
	WriteCoord(MSG_ENTITY, self.warpzone_angles.z);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin.x);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin.y);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin.z);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles.x);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles.y);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles.z);

	if(f & 2)
	{
		WriteShort(MSG_ENTITY, self.warpzone_fadestart);
		WriteShort(MSG_ENTITY, self.warpzone_fadeend);
	}

	return true;
}

bool WarpZone_Camera_Send(entity to, int sendflags)
{SELFPARAM();
	int f = 0;
	WriteHeader(MSG_ENTITY, ENT_CLIENT_WARPZONE_CAMERA);

	if(self.warpzone_fadestart)
		BITSET_ASSIGN(f, 2);
	if(self.origin != '0 0 0')
		BITSET_ASSIGN(f, 4);
	WriteByte(MSG_ENTITY, f);

	// we need THESE to render the warpzone (and cull properly)...
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, self.origin.x);
		WriteCoord(MSG_ENTITY, self.origin.y);
		WriteCoord(MSG_ENTITY, self.origin.z);
	}

	WriteShort(MSG_ENTITY, self.modelindex);
	WriteCoord(MSG_ENTITY, self.mins.x);
	WriteCoord(MSG_ENTITY, self.mins.y);
	WriteCoord(MSG_ENTITY, self.mins.z);
	WriteCoord(MSG_ENTITY, self.maxs.x);
	WriteCoord(MSG_ENTITY, self.maxs.y);
	WriteCoord(MSG_ENTITY, self.maxs.z);
	WriteByte(MSG_ENTITY, bound(1, self.scale * 16, 255));

	// we need THESE to calculate the proper transform
	WriteCoord(MSG_ENTITY, self.enemy.origin.x);
	WriteCoord(MSG_ENTITY, self.enemy.origin.y);
	WriteCoord(MSG_ENTITY, self.enemy.origin.z);
	WriteCoord(MSG_ENTITY, self.enemy.angles.x);
	WriteCoord(MSG_ENTITY, self.enemy.angles.y);
	WriteCoord(MSG_ENTITY, self.enemy.angles.z);

	if(f & 2)
	{
		WriteShort(MSG_ENTITY, self.warpzone_fadestart);
		WriteShort(MSG_ENTITY, self.warpzone_fadeend);
	}

	return true;
}

#ifdef WARPZONELIB_KEEPDEBUG
float WarpZone_CheckProjectileImpact(entity player)
{SELFPARAM();
	vector o0, v0;

	.vector orgvec, velvec;
#ifdef SVQC
	orgvec = origin;
	velvec = velocity;
#elif defined(CSQC)
	orgvec = move_origin;
	velvec = move_velocity;
#endif

	o0 = player.orgvec + player.view_ofs;
	v0 = player.velvec;

	// if we teleported shortly before, abort
	if(time <= player.warpzone_teleport_finishtime + 0.1)
		return 0;

	// if player hit a warpzone, abort
	entity wz;
	wz = WarpZone_Find(o0 + player.mins, o0 + player.maxs);
	if(!wz)
		return 0;

#ifdef WARPZONELIB_REMOVEHACK
	LOG_INFO("impactfilter found something - and it no longer gets handled correctly - please tell divVerent whether anything behaves broken now\n");
#else
	LOG_INFO("impactfilter found something - and it even gets handled correctly - please tell divVerent that this code apparently gets triggered again\n");
#endif
	LOG_INFO("Entity type: ", player.classname, "\n");
	LOG_INFO("Origin: ", vtos(player.orgvec), "\n");
	LOG_INFO("Velocity: ", vtos(player.velvec), "\n");

#ifdef WARPZONELIB_REMOVEHACK
	return 0;
#else
	// retry previous move
#ifdef SVQC
	setorigin(player, player.warpzone_oldorigin);
#elif defined(CSQC)
	player.move_origin = player.warpzone_oldorigin;
#endif
	player.velvec = player.warpzone_oldvelocity;
	if(WarpZone_Teleport(wz, player, 0, 1))
	{
		entity oldself;
		string save1, save2;

		oldself = self;
		self = wz;
		other = player;
		activator = player;

		save1 = self.target; self.target = string_null;
		save2 = self.target3; self.target3 = string_null;
		SUB_UseTargets();
		if (!self.target) self.target = save1;
		if (!self.target3) self.target3 = save2;

		self = self.enemy;
		save1 = self.target; self.target = string_null;
		save2 = self.target2; self.target2 = string_null;
		SUB_UseTargets();
		if (!self.target) self.target = save1;
		if (!self.target2) self.target2 = save2;
		self = oldself;
	}
	else
	{
		setorigin(player, o0 - player.view_ofs);
		player.velvec = v0;
	}

	return +1;
#endif
}
#endif
#endif

float WarpZone_Projectile_Touch()
{SELFPARAM();
	if(other.classname == "trigger_warpzone")
		return true;

	// no further impacts if we teleported this frame!
	// this is because even if we did teleport, the engine still may raise
	// touch events for the previous location
	// engine now aborts moves on teleport, so this SHOULD not happen any more
	// but if this is called from TouchAreaGrid of the projectile moving,
	// then this won't do
	if(time == self.warpzone_teleport_time)
		return true;

#ifdef SVQC
#ifdef WARPZONELIB_KEEPDEBUG
	// this SEEMS to not happen at the moment, but if it did, it would be more reliable
	{
		float save_dpstartcontents;
		float save_dphitcontents;
		float save_dphitq3surfaceflags;
		string save_dphittexturename;
		float save_allsolid;
		float save_startsolid;
		float save_fraction;
		vector save_endpos;
		vector save_plane_normal;
		float save_plane_dist;
		entity save_ent;
		float save_inopen;
		float save_inwater;
		save_dpstartcontents = trace_dpstartcontents;
		save_dphitcontents = trace_dphitcontents;
		save_dphitq3surfaceflags = trace_dphitq3surfaceflags;
		save_dphittexturename = trace_dphittexturename;
		save_allsolid = trace_allsolid;
		save_startsolid = trace_startsolid;
		save_fraction = trace_fraction;
		save_endpos = trace_endpos;
		save_plane_normal = trace_plane_normal;
		save_plane_dist = trace_plane_dist;
		save_ent = trace_ent;
		save_inopen = trace_inopen;
		save_inwater = trace_inwater;
		float f;
		if((f = WarpZone_CheckProjectileImpact(self)) != 0)
			return (f > 0);
		trace_dpstartcontents = save_dpstartcontents;
		trace_dphitcontents = save_dphitcontents;
		trace_dphitq3surfaceflags = save_dphitq3surfaceflags;
		trace_dphittexturename = save_dphittexturename;
		trace_allsolid = save_allsolid;
		trace_startsolid = save_startsolid;
		trace_fraction = save_fraction;
		trace_endpos = save_endpos;
		trace_plane_normal = save_plane_normal;
		trace_plane_dist = save_plane_dist;
		trace_ent = save_ent;
		trace_inopen = save_inopen;
		trace_inwater = save_inwater;
	}
#endif

	if(WarpZone_Projectile_Touch_ImpactFilter_Callback())
		return true;
#endif

	return false;
}

#ifdef SVQC

void WarpZone_InitStep_FindOriginTarget()
{SELFPARAM();
	if(self.killtarget != "")
	{
		self.aiment = find(world, targetname, self.killtarget);
		if(self.aiment == world)
		{
			error("Warp zone with nonexisting killtarget");
			return;
		}
		self.killtarget = string_null;
	}
}

void WarpZonePosition_InitStep_FindTarget()
{SELFPARAM();
	if(self.target == "")
	{
		error("Warp zone position with no target");
		return;
	}
	self.enemy = find(world, targetname, self.target);
	if(self.enemy == world)
	{
		error("Warp zone position with nonexisting target");
		return;
	}
	if(self.enemy.aiment)
	{
		// already is positioned
		error("Warp zone position targeting already oriented warpzone");
		return;
	}
	self.enemy.aiment = self;
}

void WarpZoneCamera_Think()
{SELFPARAM();
	if(self.warpzone_save_origin != self.origin
	|| self.warpzone_save_angles != self.angles
	|| self.warpzone_save_eorigin != self.enemy.origin
	|| self.warpzone_save_eangles != self.enemy.angles)
	{
		WarpZone_Camera_SetUp(self, self.enemy.origin, self.enemy.angles);
		self.warpzone_save_origin = self.origin;
		self.warpzone_save_angles = self.angles;
		self.warpzone_save_eorigin = self.enemy.origin;
		self.warpzone_save_eangles = self.enemy.angles;
	}
	self.nextthink = time;
}

void WarpZoneCamera_InitStep_FindTarget()
{SELFPARAM();
	entity e;
	float i;
	if(self.target == "")
	{
		error("Camera with no target");
		return;
	}
	self.enemy = world;
	for(e = world, i = 0; (e = find(e, targetname, self.target)); )
		if(random() * ++i < 1)
			self.enemy = e;
	if(self.enemy == world)
	{
		error("Camera with nonexisting target");
		return;
	}
	warpzone_cameras_exist = 1;
	WarpZone_Camera_SetUp(self, self.enemy.origin, self.enemy.angles);
	self.SendFlags = 0xFFFFFF;
	if(self.spawnflags & 1)
	{
		self.think = WarpZoneCamera_Think;
		self.nextthink = time;
	}
	else
		self.nextthink = 0;
}

void WarpZone_InitStep_UpdateTransform()
{SELFPARAM();
	vector org, ang, norm, point;
	float area;
	vector tri, a, b, c, n;
	float i_s, i_t, n_t;
	string tex;

	org = self.origin;
	if(org == '0 0 0')
		org = 0.5 * (self.mins + self.maxs);

	norm = point = '0 0 0';
	area = 0;
	for(i_s = 0; ; ++i_s)
	{
		tex = getsurfacetexture(self, i_s);
		if (!tex)
			break; // this is beyond the last one
		if(tex == "textures/common/trigger" || tex == "trigger")
			continue;
		n_t = getsurfacenumtriangles(self, i_s);
		for(i_t = 0; i_t < n_t; ++i_t)
		{
			tri = getsurfacetriangle(self, i_s, i_t);
			a = getsurfacepoint(self, i_s, tri.x);
			b = getsurfacepoint(self, i_s, tri.y);
			c = getsurfacepoint(self, i_s, tri.z);
			n = cross(c - a, b - a);
			area = area + vlen(n);
			norm = norm + n;
			point = point + vlen(n) * (a + b + c);
		}
	}
	if(area > 0)
	{
		norm = norm * (1 / area);
		point = point * (1 / (3 * area));
		if(vlen(norm) < 0.99)
		{
			LOG_INFO("trigger_warpzone near ", vtos(self.aiment.origin), " is nonplanar. BEWARE.\n");
			area = 0; // no autofixing in this case
		}
		norm = normalize(norm);
	}

	ang = '0 0 0';
	if(self.aiment)
	{
		org = self.aiment.origin;
		ang = self.aiment.angles;
		if(area > 0)
		{
			org = org - ((org - point) * norm) * norm; // project to plane
			makevectors(ang);
			if(norm * v_forward < 0)
			{
				LOG_INFO("Position target of trigger_warpzone near ", vtos(self.aiment.origin), " points into trigger_warpzone. BEWARE.\n");
				norm = -1 * norm;
			}
			ang = vectoangles2(norm, v_up); // keep rotation, but turn exactly against plane
			ang.x = -ang.x;
			if(norm * v_forward < 0.99)
				LOG_INFO("trigger_warpzone near ", vtos(self.aiment.origin), " has been turned to match plane orientation (", vtos(self.aiment.angles), " -> ", vtos(ang), "\n");
			if(vlen(org - self.aiment.origin) > 0.5)
				LOG_INFO("trigger_warpzone near ", vtos(self.aiment.origin), " has been moved to match the plane (", vtos(self.aiment.origin), " -> ", vtos(org), ").\n");
		}
	}
	else if(area > 0)
	{
		org = point;
		ang = vectoangles(norm);
		ang.x = -ang.x;
	}
	else
		error("cannot infer origin/angles for this warpzone, please use a killtarget or a trigger_warpzone_position");

	self.warpzone_origin = org;
	self.warpzone_angles = ang;
}

void WarpZone_InitStep_ClearTarget()
{SELFPARAM();
	if(self.enemy)
		self.enemy.enemy = world;
	self.enemy = world;
}

entity warpzone_first; .entity warpzone_next;
void WarpZone_InitStep_FindTarget()
{SELFPARAM();
	float i;
	entity e, e2;

	if(self.enemy)
		return;

	// this way only one of the two ents needs to target
	if(self.target != "")
	{
		self.enemy = self; // so the if(!e.enemy) check also skips self, saves one IF

		e2 = world;
		for(e = world, i = 0; (e = find(e, targetname, self.target)); )
			if(!e.enemy)
				if(e.classname == self.classname) // possibly non-warpzones may use the same targetname!
					if(random() * ++i < 1)
						e2 = e;
		if(!e2)
		{
			self.enemy = world;
			error("Warpzone with non-existing target");
			return;
		}
		self.enemy = e2;
		e2.enemy = self;
	}
}

void WarpZone_Think();
void WarpZone_InitStep_FinalizeTransform()
{SELFPARAM();
	if(!self.enemy || self.enemy.enemy != self)
	{
		error("Invalid warp zone detected. Killed.");
		return;
	}

	warpzone_warpzones_exist = 1;
	WarpZone_SetUp(self, self.warpzone_origin, self.warpzone_angles, self.enemy.warpzone_origin, self.enemy.warpzone_angles);
	self.touch = WarpZone_Touch;
	self.SendFlags = 0xFFFFFF;
	if(self.spawnflags & 1)
	{
		self.think = WarpZone_Think;
		self.nextthink = time;
	}
	else
		self.nextthink = 0;
}

float warpzone_initialized;
//entity warpzone_first;
entity warpzone_position_first;
entity warpzone_camera_first;
.entity warpzone_next;
spawnfunc(misc_warpzone_position)
{
	// "target", "angles", "origin"
	self.warpzone_next = warpzone_position_first;
	warpzone_position_first = self;
}
spawnfunc(trigger_warpzone_position)
{
	spawnfunc_misc_warpzone_position(this);
}
spawnfunc(trigger_warpzone)
{
	// warp zone entities must have:
	// "killtarget" pointing to a target_position with a direction arrow
	//              that points AWAY from the warp zone, and that is inside
	//              the warp zone trigger
	// "target"     pointing to an identical warp zone at another place in
	//              the map, with another killtarget to designate its
	//              orientation

	if(!self.scale)
		self.scale = self.modelscale;
	if(!self.scale)
		self.scale = 1;
	string m;
	m = self.model;
	WarpZoneLib_ExactTrigger_Init();
 	if(m != "")
 	{
 		precache_model(m);
 		_setmodel(self, m); // no precision needed
	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
	self.SendEntity = WarpZone_Send;
	self.SendFlags = 0xFFFFFF;
	BITSET_ASSIGN(self.effects, EF_NODEPTHTEST);
	self.warpzone_next = warpzone_first;
	warpzone_first = self;
}
spawnfunc(func_camera)
{
	if(!self.scale)
		self.scale = self.modelscale;
	if(!self.scale)
		self.scale = 1;
 	if(self.model != "")
 	{
 		precache_model(self.model);
 		_setmodel(self, self.model); // no precision needed
	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
	if(!self.solid)
		self.solid = SOLID_BSP;
	else if(self.solid < 0)
		self.solid = SOLID_NOT;
	self.SendEntity = WarpZone_Camera_Send;
	self.SendFlags = 0xFFFFFF;
	self.warpzone_next = warpzone_camera_first;
	warpzone_camera_first = self;
}
void WarpZones_Reconnect()
{SELFPARAM();
	for(setself(warpzone_first); self; setself(self.warpzone_next))
		WarpZone_InitStep_ClearTarget();
	for(setself(warpzone_first); self; setself(self.warpzone_next))
		WarpZone_InitStep_FindTarget();
	for(setself(warpzone_camera_first); self; setself(self.warpzone_next))
		WarpZoneCamera_InitStep_FindTarget();
	for(setself(warpzone_first); self; setself(self.warpzone_next))
		WarpZone_InitStep_FinalizeTransform();
	setself(this);
}

void WarpZone_Think()
{SELFPARAM();
	if(self.warpzone_save_origin != self.origin
	|| self.warpzone_save_angles != self.angles
	|| self.warpzone_save_eorigin != self.enemy.origin
	|| self.warpzone_save_eangles != self.enemy.angles)
	{
		WarpZone_InitStep_UpdateTransform();
		setself(self.enemy);
		WarpZone_InitStep_UpdateTransform();
		setself(this);
		WarpZone_InitStep_FinalizeTransform();
		setself(self.enemy);
		WarpZone_InitStep_FinalizeTransform();
		setself(this);
		self.warpzone_save_origin = self.origin;
		self.warpzone_save_angles = self.angles;
		self.warpzone_save_eorigin = self.enemy.origin;
		self.warpzone_save_eangles = self.enemy.angles;
	}
	self.nextthink = time;
}

void WarpZone_StartFrame()
{
	SELFPARAM();
	if (!warpzone_initialized)
	{
		warpzone_initialized = true;
		for (setself(warpzone_first); self; setself(self.warpzone_next))
			WarpZone_InitStep_FindOriginTarget();
		for (setself(warpzone_position_first); self; setself(self.warpzone_next))
			WarpZonePosition_InitStep_FindTarget();
		for (setself(warpzone_first); self; setself(self.warpzone_next))
			WarpZone_InitStep_UpdateTransform();
		setself(this);
		WarpZones_Reconnect();
		WarpZone_PostInitialize_Callback();
	}

	entity oldother = other;
	for (entity e = world; (e = nextent(e)); )
	{
		if (warpzone_warpzones_exist) WarpZone_StoreProjectileData(e);
		if (IS_REAL_CLIENT(e))
		{
			if (e.solid == SOLID_NOT) // not spectating?
			if (e.movetype == MOVETYPE_NOCLIP || e.movetype == MOVETYPE_FLY || e.movetype == MOVETYPE_FLY_WORLDONLY) // not spectating? (this is to catch observers)
			{
				other = e; // player

				// warpzones
				if (warpzone_warpzones_exist) {
					setself(WarpZone_Find(e.origin + e.mins, e.origin + e.maxs));
					if (self)
					if (!WarpZoneLib_ExactTrigger_Touch())
					if (WarpZone_PlaneDist(self, e.origin + e.view_ofs) <= 0)
						WarpZone_Teleport(self, e, -1, 0); // NOT triggering targets by this!
				}

				// teleporters
				setself(Teleport_Find(e.origin + e.mins, e.origin + e.maxs));
				if (self)
				if (!WarpZoneLib_ExactTrigger_Touch())
					Simple_TeleportPlayer(self, other); // NOT triggering targets by this!
			}
		}
		else if (IS_NOT_A_CLIENT(e))
		{
			if (warpzone_warpzones_exist)
				while ((e = nextent(e)))
					WarpZone_StoreProjectileData(e);
			break;
		}
	}
	setself(this);
	other = oldother;
}

.float warpzone_reconnecting;
bool visible_to_some_client(entity ent)
{
	FOREACH_ENTITY(!IS_NOT_A_CLIENT(it), LAMBDA(
		if (IS_PLAYER(it) && IS_REAL_CLIENT(it) && checkpvs(it.origin + it.view_ofs, ent)) return true;
	));
	return false;
}
void trigger_warpzone_reconnect_use()
{SELFPARAM();
	entity e;
	e = self;
	// NOTE: this matches for target, not targetname, but of course
	// targetname must be set too on the other entities
	for(setself(warpzone_first); self; setself(self.warpzone_next))
		self.warpzone_reconnecting = ((e.target == "" || self.target == e.target) && !((e.spawnflags & 1) && (visible_to_some_client(self) || visible_to_some_client(self.enemy))));
	for(setself(warpzone_camera_first); self; setself(self.warpzone_next))
		self.warpzone_reconnecting = ((e.target == "" || self.target == e.target) && !((e.spawnflags & 1) && visible_to_some_client(self)));
	for(setself(warpzone_first); self; setself(self.warpzone_next))
		if(self.warpzone_reconnecting)
			WarpZone_InitStep_ClearTarget();
	for(setself(warpzone_first); self; setself(self.warpzone_next))
		if(self.warpzone_reconnecting)
			WarpZone_InitStep_FindTarget();
	for(setself(warpzone_camera_first); self; setself(self.warpzone_next))
		if(self.warpzone_reconnecting)
			WarpZoneCamera_InitStep_FindTarget();
	for(setself(warpzone_first); self; setself(self.warpzone_next))
		if(self.warpzone_reconnecting || self.enemy.warpzone_reconnecting)
			WarpZone_InitStep_FinalizeTransform();
	setself(e);
}

spawnfunc(trigger_warpzone_reconnect)
{
	self.use = trigger_warpzone_reconnect_use;
}

spawnfunc(target_warpzone_reconnect)
{
	spawnfunc_trigger_warpzone_reconnect(this); // both names make sense here :(
}

void WarpZone_PlayerPhysics_FixVAngle()
{SELFPARAM();
#ifndef WARPZONE_DONT_FIX_VANGLE
	if(IS_REAL_CLIENT(self))
	if(self.v_angle.z <= 360) // if not already adjusted
	if(time - self.ping * 0.001 < self.warpzone_teleport_time)
	{
		self.v_angle = WarpZone_TransformVAngles(self.warpzone_teleport_zone, self.v_angle);
		self.v_angle_z += 720; // mark as adjusted
	}
#endif
}

#endif
