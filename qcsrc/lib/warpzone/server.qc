#include "server.qh"

#include "common.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/constants.qh>
	#include <common/net_linked.qh>
	#include <common/mapobjects/subs.qh>
	#include <common/mapobjects/teleporters.qh>
	#include <common/util.qh>
	#include <common/weapons/_all.qh>
	#include <common/stats.qh>
	#include <server/utils.qh>
	#include <server/weapons/common.qh>
#endif

#ifdef SVQC
bool autocvar_sv_warpzone_allow_selftarget;
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

#define WarpZone_StoreProjectileData(e_) MACRO_BEGIN \
	entity e = e_; \
	e.warpzone_oldorigin = e.origin; \
	e.warpzone_oldvelocity = e.velocity; \
	e.warpzone_oldangles = e.angles; \
	MACRO_END

void WarpZone_TeleportPlayer(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity)
{
#ifdef SVQC
	player.lastteleport_origin = player.origin;
	player.lastteleporttime = time;
#endif
	setorigin(player, to); // NOTE: this also aborts the move, when this is called by touch
	player.angles = to_angles;
#ifdef SVQC
	player.oldorigin = to; // for DP's unsticking
	player.fixangle = true;
	if (IS_BOT_CLIENT(player))
	{
		// FIXME find a way to smooth view's angles change for bots too
		player.v_angle = player.angles;
		bot_aim_reset(player);
	}
#endif
	player.velocity = to_velocity;

	BITXOR_ASSIGN(player.effects, EF_TELEPORT_BIT);

	if(IS_PLAYER(player))
		BITCLR_ASSIGN(player.flags, FL_ONGROUND);

	WarpZone_PostTeleportPlayer_Callback(player);
}

#ifdef SVQC
bool WarpZone_Teleported_Send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_WARPZONE_TELEPORTED);
	WriteVector(MSG_ENTITY, this.angles);
	return true;
}
#endif

float WarpZone_Teleport(entity wz, entity player, float f0, float f1)
{
	vector o0, a0, v0, o1, a1, v1, o10;

	o0 = player.origin + player.view_ofs;
	v0 = player.velocity;
	a0 = player.angles;

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
			player.owner = NULL;
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

	// put them out of solid
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
			LOG_INFO("would have to put player in solid, won't do that");
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
	float dt = (v1 != '0 0 0') ? (o1 - o10) * v1 * (1 / (v1 * v1)) : 0;
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
		setSendEntity(ts, WarpZone_Teleported_Send);
		ts.SendFlags = 0xFFFFFF;
		ts.drawonlytoclient = player;
		setthink(ts, SUB_Remove);
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

void WarpZone_Touch(entity this, entity toucher)
{
	if(toucher.classname == "trigger_warpzone")
		return;

	if(time <= toucher.warpzone_teleport_finishtime) // already teleported this frame
		return;

	// FIXME needs a better check to know what is safe to teleport and what not
	if(toucher.move_movetype == MOVETYPE_NONE || toucher.move_movetype == MOVETYPE_FOLLOW || toucher.tag_entity)
		return;

	if(WarpZone_PlaneDist(this, toucher.origin + toucher.view_ofs) >= 0) // wrong side of the trigger_warpzone (don't teleport yet)
		return;

	EXACTTRIGGER_TOUCH(this, toucher);

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
	d = 24 + max(vlen(toucher.mins), vlen(toucher.maxs));
	if(IS_NOT_A_CLIENT(toucher))
		f = -d / bound(frametime * d * 1, frametime * vlen(toucher.velocity), d);
	else
		f = -1;
	if(WarpZone_Teleport(this, toucher, f, 0))
	{
#ifdef SVQC
		SUB_UseTargets_SkipTargets(this, toucher, toucher, BIT(1) | BIT(3)); // use toucher too?
		SUB_UseTargets_SkipTargets(this.enemy, toucher, toucher, BIT(1) | BIT(2)); // use toucher too?
#endif
	}
	else
	{
		LOG_TRACE("WARPZONE FAIL AHAHAHAHAH))");
	}
}

#ifdef SVQC
bool WarpZone_Send(entity this, entity to, int sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_WARPZONE);

	// we must send this flag for clientside to match properly too
	int f = 0;
	if(this.warpzone_isboxy)
		BITSET_ASSIGN(f, 1);
	if(this.warpzone_fadestart)
		BITSET_ASSIGN(f, 2);
	if(this.origin != '0 0 0')
		BITSET_ASSIGN(f, 4);
	WriteByte(MSG_ENTITY, f);

	// we need THESE to render the warpzone (and cull properly)...
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, this.origin.x);
		WriteCoord(MSG_ENTITY, this.origin.y);
		WriteCoord(MSG_ENTITY, this.origin.z);
	}

	WriteShort(MSG_ENTITY, this.modelindex);
	WriteCoord(MSG_ENTITY, this.mins.x);
	WriteCoord(MSG_ENTITY, this.mins.y);
	WriteCoord(MSG_ENTITY, this.mins.z);
	WriteCoord(MSG_ENTITY, this.maxs.x);
	WriteCoord(MSG_ENTITY, this.maxs.y);
	WriteCoord(MSG_ENTITY, this.maxs.z);
	WriteByte(MSG_ENTITY, bound(1, this.scale * 16, 255));

	// we need THESE to calculate the proper transform
	WriteCoord(MSG_ENTITY, this.warpzone_origin.x);
	WriteCoord(MSG_ENTITY, this.warpzone_origin.y);
	WriteCoord(MSG_ENTITY, this.warpzone_origin.z);
	WriteCoord(MSG_ENTITY, this.warpzone_angles.x);
	WriteCoord(MSG_ENTITY, this.warpzone_angles.y);
	WriteCoord(MSG_ENTITY, this.warpzone_angles.z);
	WriteCoord(MSG_ENTITY, this.warpzone_targetorigin.x);
	WriteCoord(MSG_ENTITY, this.warpzone_targetorigin.y);
	WriteCoord(MSG_ENTITY, this.warpzone_targetorigin.z);
	WriteCoord(MSG_ENTITY, this.warpzone_targetangles.x);
	WriteCoord(MSG_ENTITY, this.warpzone_targetangles.y);
	WriteCoord(MSG_ENTITY, this.warpzone_targetangles.z);

	if(f & 2)
	{
		WriteShort(MSG_ENTITY, this.warpzone_fadestart);
		WriteShort(MSG_ENTITY, this.warpzone_fadeend);
	}

	return true;
}

bool WarpZone_Camera_Send(entity this, entity to, int sendflags)
{
	int f = 0;
	WriteHeader(MSG_ENTITY, ENT_CLIENT_WARPZONE_CAMERA);

	if(this.warpzone_fadestart)
		BITSET_ASSIGN(f, 2);
	if(this.origin != '0 0 0')
		BITSET_ASSIGN(f, 4);
	WriteByte(MSG_ENTITY, f);

	// we need THESE to render the warpzone (and cull properly)...
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, this.origin.x);
		WriteCoord(MSG_ENTITY, this.origin.y);
		WriteCoord(MSG_ENTITY, this.origin.z);
	}

	WriteShort(MSG_ENTITY, this.modelindex);
	WriteCoord(MSG_ENTITY, this.mins.x);
	WriteCoord(MSG_ENTITY, this.mins.y);
	WriteCoord(MSG_ENTITY, this.mins.z);
	WriteCoord(MSG_ENTITY, this.maxs.x);
	WriteCoord(MSG_ENTITY, this.maxs.y);
	WriteCoord(MSG_ENTITY, this.maxs.z);
	WriteByte(MSG_ENTITY, bound(1, this.scale * 16, 255));

	// we need THESE to calculate the proper transform
	WriteCoord(MSG_ENTITY, this.enemy.origin.x);
	WriteCoord(MSG_ENTITY, this.enemy.origin.y);
	WriteCoord(MSG_ENTITY, this.enemy.origin.z);
	WriteCoord(MSG_ENTITY, this.enemy.angles.x);
	WriteCoord(MSG_ENTITY, this.enemy.angles.y);
	WriteCoord(MSG_ENTITY, this.enemy.angles.z);

	if(f & 2)
	{
		WriteShort(MSG_ENTITY, this.warpzone_fadestart);
		WriteShort(MSG_ENTITY, this.warpzone_fadeend);
	}

	return true;
}

#ifdef WARPZONELIB_KEEPDEBUG
float WarpZone_CheckProjectileImpact(entity player)
{
	vector o0, v0;

	o0 = player.origin + player.view_ofs;
	v0 = player.velocity;

	// if we teleported shortly before, abort
	if(time <= player.warpzone_teleport_finishtime + 0.1)
		return 0;

	// if player hit a warpzone, abort
	entity wz;
	wz = WarpZone_Find(o0 + player.mins, o0 + player.maxs);
	if(!wz)
		return 0;

#ifdef WARPZONELIB_REMOVEHACK
	LOG_INFO("impactfilter found something - and it no longer gets handled correctly - please tell divVerent whether anything behaves broken now");
#else
	LOG_INFO("impactfilter found something - and it even gets handled correctly - please tell divVerent that this code apparently gets triggered again");
#endif
	LOG_INFO("Entity type: ", player.classname);
	LOG_INFO("Origin: ", vtos(player.origin));
	LOG_INFO("Velocity: ", vtos(player.velocity));

#ifdef WARPZONELIB_REMOVEHACK
	return 0;
#else
	// retry previous move
	setorigin(player, player.warpzone_oldorigin);
	player.velocity = player.warpzone_oldvelocity;
	if(WarpZone_Teleport(wz, player, 0, 1))
	{
		SUB_UseTargets_SkipTargets(wz, player, player, BIT(1) | BIT(3));
		SUB_UseTargets_SkipTargets(wz.enemy, player, player, BIT(1) | BIT(2));
	}
	else
	{
		setorigin(player, o0 - player.view_ofs);
		player.velocity = v0;
	}

	return +1;
#endif
}
#endif
#endif

float WarpZone_Projectile_Touch(entity this, entity toucher)
{
	if(toucher.classname == "trigger_warpzone")
		return true;

	// no further impacts if we teleported this frame!
	// this is because even if we did teleport, the engine still may raise
	// touch events for the previous location
	// engine now aborts moves on teleport, so this SHOULD not happen any more
	// but if this is called from TouchAreaGrid of the projectile moving,
	// then this won't do
	if(time == this.warpzone_teleport_time)
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
		float f = WarpZone_CheckProjectileImpact(this);
		if (f) return (f > 0);
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

	if(WarpZone_Projectile_Touch_ImpactFilter_Callback(this, toucher))
		return true;
#endif

	return false;
}

#ifdef SVQC

void WarpZone_InitStep_FindOriginTarget(entity this)
{
	if(this.killtarget != "")
	{
		this.aiment = find(NULL, targetname, this.killtarget);
		if(this.aiment == NULL)
		{
			error("Warp zone with nonexisting killtarget");
			return;
		}
		this.killtarget = string_null;
	}
}

void WarpZonePosition_InitStep_FindTarget(entity this)
{
	if(this.target == "")
	{
		error("Warp zone position with no target");
		return;
	}
	this.enemy = find(NULL, targetname, this.target);
	if(this.enemy == NULL)
	{
		error("Warp zone position with nonexisting target");
		return;
	}
	if(this.enemy.aiment)
	{
		// already is positioned
		error("Warp zone position targeting already oriented warpzone");
		return;
	}
	this.enemy.aiment = this;
}

void WarpZoneCamera_Think(entity this)
{
	if(this.warpzone_save_origin != this.origin
	|| this.warpzone_save_angles != this.angles
	|| this.warpzone_save_eorigin != this.enemy.origin
	|| this.warpzone_save_eangles != this.enemy.angles)
	{
		WarpZone_Camera_SetUp(this, this.enemy.origin, this.enemy.angles);
		this.warpzone_save_origin = this.origin;
		this.warpzone_save_angles = this.angles;
		this.warpzone_save_eorigin = this.enemy.origin;
		this.warpzone_save_eangles = this.enemy.angles;
	}
	this.nextthink = time;
}

void WarpZoneCamera_InitStep_FindTarget(entity this)
{
	entity e;
	float i;
	if(this.target == "")
	{
		error("Camera with no target");
		return;
	}
	this.enemy = NULL;
	for(e = NULL, i = 0; (e = find(e, targetname, this.target)); )
		if(random() * ++i < 1)
			this.enemy = e;
	if(this.enemy == NULL)
	{
		error("Camera with nonexisting target");
		return;
	}
	warpzone_cameras_exist = 1;
	WarpZone_Camera_SetUp(this, this.enemy.origin, this.enemy.angles);
	this.SendFlags = 0xFFFFFF;
	if(this.spawnflags & 1)
	{
		setthink(this, WarpZoneCamera_Think);
		this.nextthink = time;
	}
	else
		this.nextthink = 0;
}

void WarpZone_InitStep_UpdateTransform(entity this)
{
	vector org, ang, norm, point;
	float area;
	vector tri, a, b, c, n;
	float i_s, i_t, n_t;
	string tex;

	org = this.origin;
	if(org == '0 0 0')
		org = 0.5 * (this.mins + this.maxs);

	norm = point = '0 0 0';
	area = 0;
	for(i_s = 0; ; ++i_s)
	{
		tex = getsurfacetexture(this, i_s);
		if (!tex)
			break; // this is beyond the last one
		if(tex == "textures/common/trigger" || tex == "trigger")
			continue;
		n_t = getsurfacenumtriangles(this, i_s);
		for(i_t = 0; i_t < n_t; ++i_t)
		{
			tri = getsurfacetriangle(this, i_s, i_t);
			a = getsurfacepoint(this, i_s, tri.x);
			b = getsurfacepoint(this, i_s, tri.y);
			c = getsurfacepoint(this, i_s, tri.z);
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
		if(vdist(norm, <, 0.99))
		{
			LOG_INFO("trigger_warpzone near ", vtos(this.aiment.origin), " is nonplanar. BEWARE.");
			area = 0; // no autofixing in this case
		}
		norm = normalize(norm);
	}

	ang = '0 0 0';
	if(this.aiment)
	{
		org = this.aiment.origin;
		ang = this.aiment.angles;
		if(area > 0)
		{
			org = org - ((org - point) * norm) * norm; // project to plane
			vector forward, right, up;
			MAKE_VECTORS(ang, forward, right, up);
			if(norm * forward < 0)
			{
				LOG_INFO("Position target of trigger_warpzone near ", vtos(this.aiment.origin), " points into trigger_warpzone. BEWARE.");
				norm = -1 * norm;
			}
			ang = vectoangles2(norm, up); // keep rotation, but turn exactly against plane
			ang.x = -ang.x;
			if(norm * forward < 0.99)
				LOG_INFO("trigger_warpzone near ", vtos(this.aiment.origin), " has been turned to match plane orientation (", vtos(this.aiment.angles), " -> ", vtos(ang));
			if(vdist(org - this.aiment.origin, >, 0.5))
				LOG_INFO("trigger_warpzone near ", vtos(this.aiment.origin), " has been moved to match the plane (", vtos(this.aiment.origin), " -> ", vtos(org), ").");
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

	this.warpzone_origin = org;
	this.warpzone_angles = ang;
}

void WarpZone_InitStep_ClearTarget(entity this)
{
	if(this.enemy)
		this.enemy.enemy = NULL;
	this.enemy = NULL;
}

void WarpZone_InitStep_FindTarget(entity this)
{
	float i;
	entity e, e2;

	if(this.enemy)
		return;

	// this way only one of the two ents needs to target
	if(this.target != "")
	{
		if(!autocvar_sv_warpzone_allow_selftarget)
			this.enemy = this; // so the if(!e.enemy) check also skips this, saves one IF

		e2 = NULL;
		for(e = NULL, i = 0; (e = find(e, targetname, this.target)); )
			if(!e.enemy)
				if(e.classname == this.classname) // possibly non-warpzones may use the same targetname!
					if(random() * ++i < 1)
						e2 = e;
		if(!e2)
		{
			this.enemy = NULL;
			error("Warpzone with non-existing target");
			return;
		}
		this.enemy = e2;
		e2.enemy = this;
	}
}

void WarpZone_Think(entity this);
void WarpZone_InitStep_FinalizeTransform(entity this)
{
	if(!this.enemy || this.enemy.enemy != this)
	{
		error("Invalid warp zone detected. Killed.");
		return;
	}

	warpzone_warpzones_exist = 1;
	WarpZone_SetUp(this, this.warpzone_origin, this.warpzone_angles, this.enemy.warpzone_origin, this.enemy.warpzone_angles);
	settouch(this, WarpZone_Touch);
	this.SendFlags = 0xFFFFFF;
	if(this.spawnflags & 1)
	{
		setthink(this, WarpZone_Think);
		this.nextthink = time;
	}
	else
		this.nextthink = 0;
}

float warpzone_initialized;
//entity warpzone_first;
entity warpzone_position_first;
entity warpzone_camera_first;
.entity warpzone_next;
spawnfunc(misc_warpzone_position)
{
	// "target", "angles", "origin"
	this.warpzone_next = warpzone_position_first;
	warpzone_position_first = this;
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

	if(!this.scale)
		this.scale = this.modelscale;
	if(!this.scale)
		this.scale = 1;

	WarpZoneLib_ExactTrigger_Init(this, false);

	setSendEntity(this, WarpZone_Send);
	this.SendFlags = 0xFFFFFF;
	BITSET_ASSIGN(this.effects, EF_NODEPTHTEST);
	this.warpzone_next = warpzone_first;
	warpzone_first = this;

	IL_PUSH(g_warpzones, this);
}
spawnfunc(func_camera)
{
	if(!this.scale)
		this.scale = this.modelscale;
	if(!this.scale)
		this.scale = 1;
 	if(this.model != "")
 	{
 		precache_model(this.model);
 		_setmodel(this, this.model); // no precision needed
	}
	setorigin(this, this.origin);
	if(this.scale)
		setsize(this, this.mins * this.scale, this.maxs * this.scale);
	else
		setsize(this, this.mins, this.maxs);
	if(!this.solid)
		this.solid = SOLID_BSP;
	else if(this.solid < 0)
		this.solid = SOLID_NOT;
	setSendEntity(this, WarpZone_Camera_Send);
	this.SendFlags = 0xFFFFFF;
	this.warpzone_next = warpzone_camera_first;
	warpzone_camera_first = this;
}
void WarpZones_Reconnect()
{
	for(entity e = warpzone_first; e; e = e.warpzone_next)
		WarpZone_InitStep_ClearTarget(e);
	for(entity e = warpzone_first; e; e = e.warpzone_next)
		WarpZone_InitStep_FindTarget(e);
	for(entity e = warpzone_camera_first; e; e = e.warpzone_next)
		WarpZoneCamera_InitStep_FindTarget(e);
	for(entity e = warpzone_first; e; e = e.warpzone_next)
		WarpZone_InitStep_FinalizeTransform(e);
}

void WarpZone_Think(entity this)
{
	if(this.warpzone_save_origin != this.origin
	|| this.warpzone_save_angles != this.angles
	|| this.warpzone_save_eorigin != this.enemy.origin
	|| this.warpzone_save_eangles != this.enemy.angles)
	{
		WarpZone_InitStep_UpdateTransform(this);
		WarpZone_InitStep_UpdateTransform(this.enemy);
		WarpZone_InitStep_FinalizeTransform(this);
		WarpZone_InitStep_FinalizeTransform(this.enemy);
		this.warpzone_save_origin = this.origin;
		this.warpzone_save_angles = this.angles;
		this.warpzone_save_eorigin = this.enemy.origin;
		this.warpzone_save_eangles = this.enemy.angles;
	}
	this.nextthink = time;
}

void WarpZone_StartFrame()
{
	if (!warpzone_initialized)
	{
		warpzone_initialized = true;
		for(entity e = warpzone_first; e; e = e.warpzone_next)
			WarpZone_InitStep_FindOriginTarget(e);
		for(entity e = warpzone_position_first; e; e = e.warpzone_next)
			WarpZonePosition_InitStep_FindTarget(e);
		for(entity e = warpzone_first; e; e = e.warpzone_next)
			WarpZone_InitStep_UpdateTransform(e);
		WarpZones_Reconnect();
		WarpZone_PostInitialize_Callback();
	}

	if(warpzone_warpzones_exist)
	{
		IL_EACH(g_projectiles, true,
		{
			WarpZone_StoreProjectileData(it);
		});
	}


	FOREACH_CLIENT(true,
	{
		if(warpzone_warpzones_exist)
			WarpZone_StoreProjectileData(it); // TODO: not actually needed

		if((IS_OBSERVER(it) || it.solid == SOLID_NOT))
		{
			// warpzones
			if (warpzone_warpzones_exist) {
				entity e = WarpZone_Find(it.origin + it.mins, it.origin + it.maxs);
				if (e)
				if (WarpZoneLib_ExactTrigger_Touch(e, it, false))
				if (WarpZone_PlaneDist(e, it.origin + it.view_ofs) <= 0)
					WarpZone_Teleport(e, it, -1, 0); // NOT triggering targets by this!
			}

			// teleporters
			if(it.teleportable)
			{
				entity ent = Teleport_Find(it.origin + it.mins, it.origin + it.maxs);
				if (ent)
				if (WarpZoneLib_ExactTrigger_Touch(ent, it, false))
					Simple_TeleportPlayer(ent, it); // NOT triggering targets by this!
			}
		}
	});
}

.float warpzone_reconnecting;
bool visible_to_some_client(entity ent)
{
	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it) && checkpvs(it.origin + it.view_ofs, ent),
	{
		return true;
	});
	return false;
}
void trigger_warpzone_reconnect_use(entity this, entity actor, entity trigger)
{
	// NOTE: this matches for target, not targetname, but of course
	// targetname must be set too on the other entities
	for(entity e = warpzone_first; e; e = e.warpzone_next)
		e.warpzone_reconnecting = ((this.target == "" || e.target == this.target) && !((this.spawnflags & 1) && (visible_to_some_client(e) || visible_to_some_client(e.enemy))));
	for(entity e = warpzone_camera_first; e; e = e.warpzone_next)
		e.warpzone_reconnecting = ((this.target == "" || e.target == this.target) && !((this.spawnflags & 1) && visible_to_some_client(e)));
	for(entity e = warpzone_first; e; e = e.warpzone_next)
		if(e.warpzone_reconnecting)
			WarpZone_InitStep_ClearTarget(e);
	for(entity e = warpzone_first; e; e = e.warpzone_next)
		if(e.warpzone_reconnecting)
			WarpZone_InitStep_FindTarget(e);
	for(entity e = warpzone_camera_first; e; e = e.warpzone_next)
		if(e.warpzone_reconnecting)
			WarpZoneCamera_InitStep_FindTarget(e);
	for(entity e = warpzone_first; e; e = e.warpzone_next)
		if(e.warpzone_reconnecting || e.enemy.warpzone_reconnecting)
			WarpZone_InitStep_FinalizeTransform(e);
}

spawnfunc(trigger_warpzone_reconnect)
{
	this.use = trigger_warpzone_reconnect_use;
}

spawnfunc(target_warpzone_reconnect)
{
	spawnfunc_trigger_warpzone_reconnect(this); // both names make sense here :(
}

void WarpZone_PlayerPhysics_FixVAngle(entity this)
{
#ifndef WARPZONE_DONT_FIX_VANGLE
	if(IS_REAL_CLIENT(this))
	if(this.v_angle.z <= 360) // if not already adjusted
	if(time - CS(this).ping * 0.001 < this.warpzone_teleport_time)
	{
		this.v_angle = WarpZone_TransformVAngles(this.warpzone_teleport_zone, this.v_angle);
		this.v_angle_z += 720; // mark as adjusted
	}
#endif
}

#endif
