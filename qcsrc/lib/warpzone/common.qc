#include "common.qh"

#include <common/checkextension.qh>

#ifdef CSQC
	#include <client/items/items.qh>
#elifdef SVQC
	#include <common/weapons/_all.qh>
#endif

void WarpZone_Accumulator_Clear(entity acc)
{
	acc.warpzone_transform = '0 0 0';
	acc.warpzone_shift = '0 0 0';
}
void WarpZone_Accumulator_AddTransform(entity acc, vector t, vector s)
{
	vector tr = AnglesTransform_Multiply(t, acc.warpzone_transform);
	vector st = AnglesTransform_Multiply_GetPostShift(t, s, acc.warpzone_transform, acc.warpzone_shift);
	acc.warpzone_transform = tr;
	acc.warpzone_shift = st;
}
#define WarpZone_Accumulator_Add(acc, wz) \
	WarpZone_Accumulator_AddTransform(acc, (wz).warpzone_transform, (wz).warpzone_shift)
void WarpZone_Accumulator_AddInverseTransform(entity acc, vector t, vector s)
{
	vector tt = AnglesTransform_Invert(t);
	vector ss = AnglesTransform_PrePostShift_GetPostShift(s, tt, '0 0 0');
	WarpZone_Accumulator_AddTransform(acc, tt, ss);
	// yes, this probably can be done simpler... but this way is "obvious" :)
}
#define WarpZone_Accumulator_AddInverse(acc, wz) \
	WarpZone_Accumulator_AddInverseTransform(acc, (wz).warpzone_transform, (wz).warpzone_shift)

vector WarpZone_camera_transform(entity this, vector org, vector ang)
{
	if (this.warpzone_fadestart
	&& vdist(org - this.origin - 0.5 * (this.mins + this.maxs), >, this.warpzone_fadeend + 400))
		return org;
		// don't transform if zone faded out (plus 400qu safety margin for typical speeds and latencies)
		// unneeded on client, on server this helps a lot
	vector vf = v_forward;
	vector vr = v_right;
	vector vu = v_up;
	org = WarpZone_TransformOrigin(this, org);
	vf  = WarpZone_TransformVelocity(this, vf);
	vr  = WarpZone_TransformVelocity(this, vr);
	vu  = WarpZone_TransformVelocity(this, vu);
	traceline(this.warpzone_targetorigin, org, MOVE_NOMONSTERS, NULL);
	v_forward = vf;
	v_right = vr;
	v_up = vu;
	return org;
}

void WarpZone_SetUp(entity e, vector my_org, vector my_ang, vector other_org, vector other_ang)
{
	e.warpzone_transform = AnglesTransform_RightDivide(other_ang, AnglesTransform_TurnDirectionFR(my_ang));
	e.warpzone_shift = AnglesTransform_PrePostShift_GetPostShift(my_org, e.warpzone_transform, other_org);
	e.warpzone_origin = my_org;
	e.warpzone_targetorigin = other_org;
	e.warpzone_angles = my_ang;
	e.warpzone_targetangles = other_ang;
	vector forward, right, up;
	FIXED_MAKE_VECTORS(my_ang, forward, right, up);
	e.warpzone_forward = forward;
	FIXED_MAKE_VECTORS(other_ang, forward, right, up);
	e.warpzone_targetforward = forward;
	setcamera_transform(e, WarpZone_camera_transform);
}

vector WarpZone_Camera_camera_transform(entity this, vector org, vector ang)
{
	// a fixed camera view
	if (this.warpzone_fadestart
	&& vdist(org - this.origin - 0.5 * (this.mins + this.maxs), >, this.warpzone_fadeend + 400))
		return org;
		// don't transform if zone faded out (plus 400qu safety margin for typical speeds and latencies)
		// unneeded on client, on server this helps a lot
	trace_endpos = this.warpzone_origin;
	makevectors(this.warpzone_angles);
	return this.warpzone_origin;
}

void WarpZone_Camera_SetUp(entity e, vector my_org, vector my_ang) // we assume that e.oldorigin and e.avelocity point to view origin and direction
{
	e.warpzone_origin = my_org;
	e.warpzone_angles = my_ang;
	setcamera_transform(e, WarpZone_Camera_camera_transform);
}

float WarpZoneLib_BoxTouchesBrush_Recurse(vector mi, vector ma, entity e, entity ig)
{
	tracebox('0 0 0', mi, ma, '0 0 0', MOVE_NOMONSTERS, ig);
#ifdef CSQC
	if (trace_networkentity)
	{
		LOG_TRACE("hit a network ent, cannot continue WarpZoneLib_BoxTouchesBrush");
		// we cannot continue, as a player blocks us...
		// so, abort
		return 0;
	}
#endif
	if (!trace_ent)
		return 0;
	if (trace_ent == e)
		return 1;

	entity se = trace_ent;
	float s = se.solid;
	se.solid = SOLID_NOT;
	setorigin(se, se.origin); // unlink
	float f = WarpZoneLib_BoxTouchesBrush_Recurse(mi, ma, e, ig);
	se.solid = s;
	setorigin(se, se.origin); // relink

	return f;
}

float WarpZoneLib_BoxTouchesBrush(vector mi, vector ma, entity e, entity ig)
{
	// bones_was_here: TODO: when findbox_OrFallback() is available, use it to
	// optimise this into a single non-recursive function that only calls tracebox once

	if (!e.modelindex || e.warpzone_isboxy)
		return 1;

	// work around trigger_hurt on geit3ctf1 not being detected by tracebox
	// bones_was_here: FIXME: WHY do these triggers only have supercontents == 128 ?!
	if (Q3COMPAT_COMMON && ig != world)
		ig.dphitcontentsmask |= 128;

	float s = e.solid;
	if (e.solid != SOLID_BSP)
	{
		e.solid = SOLID_BSP;
		setorigin(e, e.origin); // update linking
	}
	float f = WarpZoneLib_BoxTouchesBrush_Recurse(mi, ma, e, ig);
	if (e.solid != s) // if we needed to change .solid temporarily
	{
		e.solid = s; // restore it
		setorigin(e, e.origin); // update linking
	}

	if (Q3COMPAT_COMMON && ig != world)
		ig.dphitcontentsmask &= ~128;

	return f;
}

entity WarpZone_Find(vector mi, vector ma)
{
	// if we are near any warpzone planes - MOVE AWAY (work around nearclip)
	if (warpzone_warpzones_exist)
		IL_EACH(g_warpzones, WarpZoneLib_BoxTouchesBrush(mi, ma, it, NULL), return it);
	return NULL;
}

void WarpZone_MakeAllSolid()
{
	if (warpzone_warpzones_exist)
		IL_EACH(g_warpzones, true, it.solid = SOLID_BSP);
}

void WarpZone_MakeAllOther()
{
	if (warpzone_warpzones_exist)
		IL_EACH(g_warpzones, true, it.solid = SOLID_TRIGGER);
}

void WarpZone_Trace_InitTransform()
{
	if (!WarpZone_trace_transform)
		WarpZone_trace_transform = new_pure(warpzone_trace_transform);
	WarpZone_Accumulator_Clear(WarpZone_trace_transform);
}
#define WarpZone_Trace_AddTransform(wz) \
	WarpZone_Accumulator_Add(WarpZone_trace_transform, wz)

/// Traces a box from `org` to `end`, shifting & transforming each time it goes through a warpzone.
/// Hence it only ends at `end` if it didn't hit something along the way AND it went through no warpzones
void WarpZone_TraceBox_ThroughZone(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent, entity zone, WarpZone_trace_callback_t cb)
{
	WarpZone_trace_forent = forent;
	WarpZone_trace_firstzone = NULL;
	WarpZone_trace_lastzone = NULL;
	WarpZone_Trace_InitTransform();

	bool nearby_warpzones = false;
	// use tracebox if no warpzone is touching the box the entity would be traced through
	if (warpzone_warpzones_exist)
	{
		vector boxmin = mi;
		vector boxmax = ma;
	#define CHOOSE_AXIS(axis) \
		if (org.axis < end.axis) {  boxmin.axis += org.axis;  boxmax.axis += end.axis;  } \
		else                     {  boxmin.axis += end.axis;  boxmax.axis += org.axis;  }
		CHOOSE_AXIS(x);
		CHOOSE_AXIS(y);
		CHOOSE_AXIS(z);
	#undef CHOOSE_AXIS
		/* Above is equivalent to the following, but more efficient
		 *     boxmin += vec_to_min(org, end);
		 *     boxmax += vec_to_max(org, end);
		 */
		IL_EACH(g_warpzones, boxesoverlap(it.absmin, it.absmax, boxmin, boxmax),
		{
			nearby_warpzones = true;
			break;
		});
	}
	if (!nearby_warpzones)
	{
		if (nomonsters == MOVE_NOTHING)
		{
			trace_endpos = end;
			trace_fraction = 1;
		}
		else
			tracebox(org, mi, ma, end, nomonsters, WarpZone_trace_forent);

		if (cb)
			cb(org, trace_endpos, end);
		return;
	}

	vector vf = v_forward;
	vector vr = v_right;
	vector vu = v_up;

	float nomonsters_adjusted;
	switch (nomonsters)
	{
		case MOVE_WORLDONLY:
		case MOVE_NOTHING:
			nomonsters_adjusted = MOVE_NOMONSTERS;
			break;
		default:
			nomonsters_adjusted = nomonsters;
			break;
	}
	bool contents_hack = (WarpZone_trace_forent.dphitcontentsmask && !(WarpZone_trace_forent.dphitcontentsmask & DPCONTENTS_SOLID));
	if (contents_hack)
		BITSET_ASSIGN(WarpZone_trace_forent.dphitcontentsmask, DPCONTENTS_SOLID);

	// if starting in warpzone, first transform
	entity wz = WarpZone_Find(org + mi, org + ma);
	float sol;
	if (wz)
	{
		WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if (zone && wz != zone)
		{
			// we are in ANOTHER warpzone. This is bad. Make a zero length trace and return.
			sol = 1;
			trace_fraction = 0;
			trace_endpos = org;
			goto fail;
		}
		WarpZone_Trace_AddTransform(wz);
		org = WarpZone_TransformOrigin(wz, org);
		end = WarpZone_TransformOrigin(wz, end);
	}
	WarpZone_MakeAllSolid();
	sol = -1;
	float frac = 0;
	float i = 16;
	for (;;)
	{
		if (--i < 1)
		{
			LOG_TRACE("Too many warpzones in sequence, aborting trace.");
			trace_ent = NULL;
			break;
		}
		tracebox(org, mi, ma, end, nomonsters_adjusted, WarpZone_trace_forent);
		if (cb)
			cb(org, trace_endpos, end);
		if (sol < 0)
			sol = trace_startsolid;

		frac = trace_fraction = frac + (1 - frac) * trace_fraction;
		if (trace_fraction >= 1)
			break;
		if (trace_ent.classname != "trigger_warpzone")
		{
			if (nomonsters == MOVE_NOTHING
			|| (nomonsters == MOVE_WORLDONLY && trace_ent)
			|| (contents_hack && (trace_dphitcontents & WarpZone_trace_forent.dphitcontentsmask) == DPCONTENTS_SOLID))
			{
				// continue the trace, ignoring this hit (we only care for warpzones)
				org = trace_endpos + normalize(end - org);
				continue;
				// we cannot do an inverted trace here, as we do care for further warpzones inside that "solid" to be found
				// otherwise, players could block entrances that way
			}
			break;
		}
		/*if (trace_ent == wz)
		{
			// FIXME can this check be removed? Do we really need it?
			LOG_TRACE("I transformed into the same zone again, wtf, aborting the trace");
			trace_ent = NULL;
			break;
		}*/
		wz = trace_ent;
		if (!WarpZone_trace_firstzone)
			WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if (zone && wz != zone)
			break;
		WarpZone_Trace_AddTransform(wz);
		// we hit a warpzone... so, let's perform the trace after the warp again
		org = WarpZone_TransformOrigin(wz, trace_endpos);
		end = WarpZone_TransformOrigin(wz, end);

		// we got warped, so let's step back a bit
		tracebox(org, mi, ma, org + normalize(org - end) * 32, nomonsters_adjusted, WarpZone_trace_forent);
		org = trace_endpos;
	}
	WarpZone_MakeAllOther();
LABEL(fail)
	if (contents_hack)
		BITCLR_ASSIGN(WarpZone_trace_forent.dphitcontentsmask, DPCONTENTS_SOLID);
	trace_startsolid = sol;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
}

/// Traces tossing `e`, shifting & transforming each time it goes through a warpzone.
void WarpZone_TraceToss_ThroughZone(entity e, entity forent, entity zone, WarpZone_trace_callback_t cb)
{
	vector o0 = e.origin;
	vector v0 = e.velocity;
	float dt, i, g = PHYS_GRAVITY(NULL) * e.gravity;

	WarpZone_trace_forent = forent;
	WarpZone_trace_firstzone = NULL;
	WarpZone_trace_lastzone = NULL;
	WarpZone_Trace_InitTransform();
	WarpZone_tracetoss_time = 0;
	if (!warpzone_warpzones_exist)
	{
		tracetoss(e, WarpZone_trace_forent);
		if (cb)
			cb(e.origin, trace_endpos, trace_endpos);
		dt = vlen(e.origin - o0) / vlen(e.velocity);
		WarpZone_tracetoss_time += dt;
		e.velocity.z -= dt * g;
		WarpZone_tracetoss_velocity = e.velocity;
		e.velocity = v0;
		return;
	}

	vector vf = v_forward;
	vector vr = v_right;
	vector vu = v_up;

	// if starting in warpzone, first transform
	entity wz = WarpZone_Find(e.origin + e.mins, e.origin + e.maxs);
	if (wz)
	{
		WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if (zone && wz != zone)
		{
			// we are in ANOTHER warpzone. This is bad. Make a zero length trace and return.

			WarpZone_tracetoss_time = 0;
			trace_endpos = o0;
			goto fail;
		}
		WarpZone_Trace_AddTransform(wz);
		vector org = WarpZone_TransformOrigin(wz, e.origin);
		setorigin(e, org);
		e.velocity = WarpZone_TransformVelocity(wz, e.velocity);
	}
	WarpZone_MakeAllSolid();
	i = 16;
	for (;;)
	{
		if (--i < 1)
		{
			LOG_TRACE("Too many warpzones in sequence, aborting trace.");
			trace_ent = NULL;
			break;
		}
		tracetoss(e, WarpZone_trace_forent);
		if (cb)
			cb(e.origin, trace_endpos, trace_endpos);
		dt = vlen(trace_endpos - e.origin) / vlen(e.velocity);
		WarpZone_tracetoss_time += dt;
		e.origin = trace_endpos;
		e.velocity.z -= dt * g;
		if (trace_fraction >= 1)
			break;
		if (trace_ent.classname != "trigger_warpzone")
			break;
		if (trace_ent == wz)
		{
			// FIXME can this check be removed? Do we really need it?
			LOG_TRACE("I transformed into the same zone again, wtf, aborting the trace");
			trace_ent = NULL;
			break;
		}
		wz = trace_ent;
		if (!WarpZone_trace_firstzone)
			WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if (zone && wz != zone)
			break;
		WarpZone_Trace_AddTransform(wz);
		// we hit a warpzone... so, let's perform the trace after the warp again
		e.origin = WarpZone_TransformOrigin(wz, e.origin);
		e.velocity = WarpZone_TransformVelocity(wz, e.velocity);

		// we got warped, so let's step back a bit
		e.velocity = -e.velocity;
		tracetoss(e, WarpZone_trace_forent);
		dt = vlen(trace_endpos - e.origin) / vlen(e.velocity);
		WarpZone_tracetoss_time -= dt;
		e.origin = trace_endpos;
		e.velocity = -e.velocity;
	}
	WarpZone_MakeAllOther();
LABEL(fail)
	WarpZone_tracetoss_velocity = e.velocity;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
	// restore old entity data (caller just uses trace_endpos, WarpZone_tracetoss_velocity and the transform)
	e.velocity = v0;
	e.origin = o0;
}

entity WarpZone_TrailParticles_trace_callback_own;
float WarpZone_TrailParticles_trace_callback_eff;
void WarpZone_TrailParticles_trace_callback(vector from, vector endpos, vector to)
{
	__trailparticles(WarpZone_TrailParticles_trace_callback_own, WarpZone_TrailParticles_trace_callback_eff, from, endpos);
}

void WarpZone_TrailParticles(entity own, float eff, vector org, vector end)
{
	WarpZone_TrailParticles_trace_callback_own = own;
	WarpZone_TrailParticles_trace_callback_eff = eff;
	WarpZone_TraceBox_ThroughZone(org, '0 0 0', '0 0 0', end, MOVE_NOMONSTERS, NULL, NULL, WarpZone_TrailParticles_trace_callback);
}

#ifdef CSQC
float WarpZone_TrailParticles_trace_callback_f;
float WarpZone_TrailParticles_trace_callback_flags;
void WarpZone_TrailParticles_WithMultiplier_trace_callback(vector from, vector endpos, vector to)
{
	boxparticles(WarpZone_TrailParticles_trace_callback_eff, WarpZone_TrailParticles_trace_callback_own, from, endpos, WarpZone_TrailParticles_trace_callback_own.velocity, WarpZone_TrailParticles_trace_callback_own.velocity, WarpZone_TrailParticles_trace_callback_f, WarpZone_TrailParticles_trace_callback_flags);
}

void WarpZone_TrailParticles_WithMultiplier(entity own, float eff, vector org, vector end, float f, int boxflags)
{
	WarpZone_TrailParticles_trace_callback_own = own;
	WarpZone_TrailParticles_trace_callback_eff = eff;
	WarpZone_TrailParticles_trace_callback_f = f;
	WarpZone_TrailParticles_trace_callback_flags = boxflags | PARTICLES_DRAWASTRAIL;
	WarpZone_TraceBox_ThroughZone(org, '0 0 0', '0 0 0', end, MOVE_NOMONSTERS, NULL, NULL, WarpZone_TrailParticles_WithMultiplier_trace_callback);
}
#endif

float WarpZone_PlaneDist(entity wz, vector p)
{
	return (p - wz.warpzone_origin) * wz.warpzone_forward;
}

float WarpZone_TargetPlaneDist(entity wz, vector p)
{
	return (p - wz.warpzone_targetorigin) * wz.warpzone_targetforward;
}
/// Transforms origin `org` across warpzone `wz`.
/// For example, this'd give you the origin a projectile will have after it crosses the warpzone
vector WarpZone_TransformOrigin(entity wz, vector org)
{
	return wz.warpzone_shift + AnglesTransform_Apply(wz.warpzone_transform, org);
}
/// Transforms velocity `v` across warpzone `wz`.
/// For example, this can give you the updated `v_forward` after crossing the warpzone
vector WarpZone_TransformVelocity(entity wz, vector vel)
{
	return AnglesTransform_Apply(wz.warpzone_transform, vel);
}
/// Transforms angle `v` across warpzone `wz`
vector WarpZone_TransformAngles(entity wz, vector ang)
{
	return AnglesTransform_ApplyToAngles(wz.warpzone_transform, ang);
}
/// Transforms v_angle `ang` across warpzone `wz`
vector WarpZone_TransformVAngles(entity wz, vector ang)
{
#ifdef KEEP_ROLL
	float roll = ang.z;
	ang.z = 0;
#endif

	ang = AnglesTransform_ApplyToVAngles(wz.warpzone_transform, ang);
#ifdef KEEP_ROLL
	ang = AnglesTransform_Normalize(ang, true);
	ang = AnglesTransform_CancelRoll(ang);
	ang.z = roll;
#else
	ang = AnglesTransform_Normalize(ang, false);
#endif
	return ang;
}

/// Transforms origin `org` backwards through warpzone `wz`, as the inverse of WarpZone_TransformOrigin.
/// E.g., WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos):
///   Returns the endpoint of a warpzone-aware trace, as if the trace had never gone through warpzones
vector WarpZone_UnTransformOrigin(entity wz, vector org)
{
	return AnglesTransform_Apply(AnglesTransform_Invert(wz.warpzone_transform), org - wz.warpzone_shift);
}
/// Transforms angle `vel` backwards through warpzone `wz`, as the inverse of WarpZone_TransformVelocity.
vector WarpZone_UnTransformVelocity(entity wz, vector vel)
{
	return AnglesTransform_Apply(AnglesTransform_Invert(wz.warpzone_transform), vel);
}
/// Transforms angle `ang` backwards through warpzone `wz`, as the inverse of WarpZone_TransformAngles.
vector WarpZone_UnTransformAngles(entity wz, vector ang)
{
	return AnglesTransform_ApplyToAngles(AnglesTransform_Invert(wz.warpzone_transform), ang);
}
/// Transforms v_angle `ang` backwards through warpzone `wz`, as the inverse of WarpZone_TransformVAngles.
vector WarpZone_UnTransformVAngles(entity wz, vector ang)
{
#ifdef KEEP_ROLL
	float roll = ang.z;
	ang.z = 0;
#endif

	ang = AnglesTransform_ApplyToVAngles(AnglesTransform_Invert(wz.warpzone_transform), ang);
#ifdef KEEP_ROLL
	ang = AnglesTransform_Normalize(ang, true);
	ang = AnglesTransform_CancelRoll(ang);
	ang.z = roll;
#else
	ang = AnglesTransform_Normalize(ang, false);
#endif
	return ang;
}

// FIXME: the nearest bounding box point can be unreachable via trace,
// despite there actually being line of sight if only the trace was adjusted slightly
#define WarpZoneLib_NearestPointOnBox(mi, ma, org) NearestPointOnBoundingBox(mi, ma, org)

.int WarpZone_findradius_hit;
const int WarpZone_FindRadius_Hit_UNSEEN  = 0;
const int WarpZone_FindRadius_Hit_GOOD    = 1;
const int WarpZone_FindRadius_Hit_BAD     = 2;
/// Blacklist of entities that WarpZone_FindRadius doesn't care about
bool WarpZoneLib_BadEntity(entity e, WarpZone_FindRadius_cond_callback_t cb)
{
	if (e.WarpZone_findradius_hit != WarpZone_FindRadius_Hit_UNSEEN) // also account for caching
		return (e.WarpZone_findradius_hit == WarpZone_FindRadius_Hit_BAD); // either BAD or GOOD
	if (is_pure(e))
		return true;

	string s = e.classname;
	switch (s)
	{
		case "warpzone_refsys": // ignore, especially: do not overwrite the refsys parameters
		case "weaponentity":
		case "exteriorweaponentity":
		case "sprite_waypoint":
		case "waypoint":
		case "spawnfunc":
		case "weaponchild":
		case "chatbubbleentity":
		case "buff_model":
		//case "net_linked": // actually some real entities are linked without classname, fail
		case "":
			return true;
	}
	if (startsWith(s, "target_"))
		return true;
	if (startsWith(s, "info_"))
		return true;

	return (cb && !cb(e));
}

.entity enemy;
entity _WarpZone_FindRadius_goodents_first;
entity _WarpZone_FindRadius_badents_first;
float _WarpZone_FindRadius_nomonsters;
var WarpZone_FindRadius_cond_callback_t _WarpZone_FindRadius_cond_cb;
.entity WarpZone_findradius_next;
void _WarpZone_FindRadius_Recurse(
	/** blast origin of current search */
	vector org,
	float rad,
	/** original blast origin */
	vector org0,
	/** how to untransform (victim to blast system) */
	vector transform,
	vector shift)
{
	if (rad <= 0)
		return;
	entity wz = NULL;
	FOREACH_ENTITY_RADIUS(org, rad, it.WarpZone_findradius_hit != WarpZone_FindRadius_Hit_BAD, // exclude entities we already know are bad
	{
		bool is_warpzone = (it.classname == "trigger_warpzone");
		if (!is_warpzone // warpzones are never bad entities
		&& WarpZoneLib_BadEntity(it, _WarpZone_FindRadius_cond_cb))
		{
			it.WarpZone_findradius_hit = WarpZone_FindRadius_Hit_BAD;
			it.WarpZone_findradius_next = _WarpZone_FindRadius_badents_first;
			// use .WarpZone_findradius_next so that .chain isn't changed on entities not included in the returned list_first
			_WarpZone_FindRadius_badents_first = it;
			continue;
		}

		vector p = WarpZoneLib_NearestPointOnBox(it.origin + it.mins, it.origin + it.maxs, org0);
		if (it.WarpZone_findradius_hit == WarpZone_FindRadius_Hit_GOOD && vlen2(it.WarpZone_findradius_dist) <= vlen2(org0 - p))
			continue;
		if (_WarpZone_FindRadius_nomonsters != MOVE_NOTHING)
		{
			traceline(org, p, _WarpZone_FindRadius_nomonsters, it);
			if (trace_fraction < 1)
				continue;
		}

		it.WarpZone_findradius_nearest = p;
		it.WarpZone_findradius_dist = org0 - p;
		it.WarpZone_findradius_findorigin = org;
		it.WarpZone_findradius_findradius = rad;
		if (is_warpzone)
		{
			it.WarpZone_findradius_next = wz;
			wz = it;
			it.WarpZone_findradius_hit = WarpZone_FindRadius_Hit_GOOD;
			it.enemy.WarpZone_findradius_dist = '0 0 0'; // we don't want to go through this zone ever again
			it.enemy.WarpZone_findradius_hit = WarpZone_FindRadius_Hit_GOOD;
		}
		else // entity we'll include in the list
		{
			it.warpzone_transform = transform;
			it.warpzone_shift = shift;
			if (it.WarpZone_findradius_hit != WarpZone_FindRadius_Hit_GOOD) // add to good ents chain if not already in it
			{
				it.chain = _WarpZone_FindRadius_goodents_first; // fine to use .chain since FOREACH_ENTITY_RADIUS doesn't use it
				_WarpZone_FindRadius_goodents_first = it;
				it.WarpZone_findradius_hit = WarpZone_FindRadius_Hit_GOOD;
			}
		}
	});
	for (entity e = wz; e; e = e.WarpZone_findradius_next)
	{
		vector org0_new = WarpZone_TransformOrigin(e, org);
		traceline(e.warpzone_targetorigin, org0_new, MOVE_NOMONSTERS, e);
		vector org_new = trace_endpos;

		_WarpZone_FindRadius_Recurse(
			org_new,
			rad - max(8, vlen(org_new - org0_new)),
			org0_new,
			AnglesTransform_Multiply(e.warpzone_transform, transform), // new transform
			AnglesTransform_Multiply_GetPostShift(e.warpzone_transform, e.warpzone_shift, transform, shift)); // new shift
		e.WarpZone_findradius_hit = e.enemy.WarpZone_findradius_hit = WarpZone_FindRadius_Hit_UNSEEN;
	}
}
entity WarpZone_SearchInRadius(vector org, float rad, float nomonsters, WarpZone_FindRadius_cond_callback_t cb)
{
	bool nearby_warpzones = false;
	// use FOREACH_ENTITY_RADIUS if no warpzone is touching the box of side 2 * rad and center org
	// which includes the sphere of radius rad and center org
	if (warpzone_warpzones_exist)
	{
		vector boxmin = vec3(org.x - rad, org.y - rad, org.z - rad);
		vector boxmax = vec3(org.x + rad, org.y + rad, org.z + rad);
		IL_EACH(g_warpzones, boxesoverlap(it.absmin, it.absmax, boxmin, boxmax),
		{
			nearby_warpzones = true;
			break;
		});
	}

	_WarpZone_FindRadius_goodents_first = NULL;
	if (nearby_warpzones)
	{
		_WarpZone_FindRadius_badents_first = NULL;
		_WarpZone_FindRadius_nomonsters = nomonsters;
		_WarpZone_FindRadius_cond_cb = cb;
		_WarpZone_FindRadius_Recurse(org, rad, org, '0 0 0', '0 0 0');
		FOREACH_LIST(_WarpZone_FindRadius_goodents, chain,                    true, it.WarpZone_findradius_hit = WarpZone_FindRadius_Hit_UNSEEN);
		FOREACH_LIST(_WarpZone_FindRadius_badents,  WarpZone_findradius_next, true, it.WarpZone_findradius_hit = WarpZone_FindRadius_Hit_UNSEEN);
	}
	else // cheaper than _WarpZone_FindRadius_Recurse
		FOREACH_ENTITY_RADIUS(org, rad, !WarpZoneLib_BadEntity(it, cb),
		{
			vector p = NearestPointOnBoundingBox(it.origin + it.mins, it.origin + it.maxs, org);
			if (nomonsters != MOVE_NOTHING)
			{
				traceline(org, p, nomonsters, it);
				if (trace_fraction < 1)
					continue;
			}

			it.chain = _WarpZone_FindRadius_goodents_first; // fine to use .chain since FOREACH_ENTITY_RADIUS doesn't use it
			_WarpZone_FindRadius_goodents_first = it;
			it.WarpZone_findradius_nearest = p;
			it.WarpZone_findradius_dist = org - p;
			WarpZone_Accumulator_Clear(it); // reset .warpzone_transform and .warpzone_shift
		});

	return _WarpZone_FindRadius_goodents_first;
}

.entity WarpZone_refsys;
// called when an entity is deleted with delete() / remove()
// or when a player disconnects
ACCUMULATE
void ONREMOVE(entity this)
{
    // remove WarpZone_refsys object attached to 'this'
    if (this.WarpZone_refsys && this.WarpZone_refsys.owner == this)
		delete(this.WarpZone_refsys);
}
void WarpZone_RefSys_CheckCreate(entity me)
{
	if (me.WarpZone_refsys.owner == me)
		return;
	me.WarpZone_refsys = new(warpzone_refsys);
	me.WarpZone_refsys.owner = me;
	WarpZone_Accumulator_Clear(me.WarpZone_refsys);
}
void WarpZone_RefSys_Clear(entity me)
{
	if (!me.WarpZone_refsys)
		return;
	delete(me.WarpZone_refsys);
	me.WarpZone_refsys = NULL;
}
void WarpZone_RefSys_AddTransform(entity me, vector t, vector s)
{
	if (t == '0 0 0' && s == '0 0 0')
		return;
	WarpZone_RefSys_CheckCreate(me);
	WarpZone_Accumulator_AddTransform(me.WarpZone_refsys, t, s);
}
void WarpZone_RefSys_AddInverseTransform(entity me, vector t, vector s)
{
	if (t == '0 0 0' && s == '0 0 0')
		return;
	WarpZone_RefSys_CheckCreate(me);
	WarpZone_Accumulator_AddInverseTransform(me.WarpZone_refsys, t, s);
}
.vector WarpZone_refsys_incremental_shift;
.vector WarpZone_refsys_incremental_transform;
void WarpZone_RefSys_AddIncrementally(entity me, entity ref)
{
	//vector t, s;
	if (me.WarpZone_refsys_incremental_transform == ref.WarpZone_refsys.warpzone_transform
	&&  me.WarpZone_refsys_incremental_shift == ref.WarpZone_refsys.warpzone_shift)
		return;
	WarpZone_Accumulator_AddInverseTransform(me.WarpZone_refsys, me.WarpZone_refsys_incremental_transform, me.WarpZone_refsys_incremental_shift);
	WarpZone_Accumulator_Add(me.WarpZone_refsys, ref.WarpZone_refsys);
	me.WarpZone_refsys_incremental_shift = ref.WarpZone_refsys.warpzone_shift;
	me.WarpZone_refsys_incremental_transform = ref.WarpZone_refsys.warpzone_transform;
}
void WarpZone_RefSys_BeginAddingIncrementally(entity me, entity ref)
{
	me.WarpZone_refsys_incremental_shift = ref.WarpZone_refsys.warpzone_shift;
	me.WarpZone_refsys_incremental_transform = ref.WarpZone_refsys.warpzone_transform;
}
/// Transform origin `org` in `from`'s reference into `to`'s reference.
/// E.g., WarpZone_RefSys_TransformOrigin(receiver, flag, receiver.origin + receiver.view_ofs):
///   Returns `receiver`'s view origin as seen by `flag`
vector WarpZone_RefSys_TransformOrigin(entity from, entity to, vector org)
{
	if (from.WarpZone_refsys)
		org = WarpZone_UnTransformOrigin(from.WarpZone_refsys, org);
	if (to.WarpZone_refsys)
		org = WarpZone_TransformOrigin(to.WarpZone_refsys, org);
	return org;
}
/// Transform velocity `vel` in `from`'s reference into `to`'s reference
vector WarpZone_RefSys_TransformVelocity(entity from, entity to, vector vel)
{
	if (from.WarpZone_refsys)
		vel = WarpZone_UnTransformVelocity(from.WarpZone_refsys, vel);
	if (to.WarpZone_refsys)
		vel = WarpZone_TransformVelocity(to.WarpZone_refsys, vel);
	return vel;
}
/// Transform angle `ang` in `from`'s reference into `to`'s reference
vector WarpZone_RefSys_TransformAngles(entity from, entity to, vector ang)
{
	if (from.WarpZone_refsys)
		ang = WarpZone_UnTransformAngles(from.WarpZone_refsys, ang);
	if (to.WarpZone_refsys)
		ang = WarpZone_TransformAngles(to.WarpZone_refsys, ang);
	return ang;
}
/// Transform v_angle `ang` in `from`'s reference into `to`'s reference
vector WarpZone_RefSys_TransformVAngles(entity from, entity to, vector ang)
{
	if (from.WarpZone_refsys)
		ang = WarpZone_UnTransformVAngles(from.WarpZone_refsys, ang);
	if (to.WarpZone_refsys)
		ang = WarpZone_TransformVAngles(to.WarpZone_refsys, ang);
	return ang;
}
/// Copies the warpzone reference of `from` onto `me`.
/// In other words, makes it be "on the same side of the warpzones"
void WarpZone_RefSys_Copy(entity me, entity from)
{
	if (from.WarpZone_refsys)
	{
		WarpZone_RefSys_CheckCreate(me);
		me.WarpZone_refsys.warpzone_shift = from.WarpZone_refsys.warpzone_shift;
		me.WarpZone_refsys.warpzone_transform = from.WarpZone_refsys.warpzone_transform;
	}
	else
		WarpZone_RefSys_Clear(me);
}
/// Spawns an entity in the same warpzone reference as `me`, and sets up its reference.
/// Used when you need to spawn en entity, set up the reference system,
/// and you know you're setting its origin "on the same side of the warpzones" as `me`
entity WarpZone_RefSys_SpawnSameRefSys(entity me)
{
	entity e = spawn();
	WarpZone_RefSys_Copy(e, me);
	return e;
}

bool WarpZoneLib_ExactTrigger_Touch(entity this, entity toucher, bool touchfunc)
{
	vector emin = toucher.absmin, emax = toucher.absmax;
	if (!Q3COMPAT_COMMON)
	{
		// Xonotic and Nexuiz maps assume triggers will be activated by adjacent players
		// prior to sv_legacy_bbox_expand 0 DP always did this for SVQC and never for CSQC
		emin -= '1 1 1';
		emax += '1 1 1';
	}

	// if called from a touch func, we can assume the boxes do overlap
	if (!touchfunc && !boxesoverlap(emin, emax, this.absmin, this.absmax)) // quick
		return false;

	return WarpZoneLib_BoxTouchesBrush(emin, emax, this, toucher); // accurate
}


void WarpZoneLib_MoveOutOfSolid_Expand(entity e, vector by)
{
	const float eps = 1/16; // 0.0625
	tracebox(e.origin, e.mins - '1 1 1' * eps, e.maxs + '1 1 1' * eps, e.origin + by, MOVE_WORLDONLY, e);
	if (trace_startsolid)
		return;
	if (trace_fraction < 1)
		// hit something, adjust origin in the other direction...
		setorigin(e, e.origin - by * (1 - trace_fraction));
}

int WarpZoneLib_MoveOutOfSolid(entity e)
{
	vector o = e.origin;
	traceline(o, o, MOVE_WORLDONLY, e);
	if (trace_startsolid)
		return 0; // too stuck, giving up

	tracebox(o, e.mins, e.maxs, o, MOVE_WORLDONLY, e);
	if (!trace_startsolid)
		return -1; // wasn't stuck

	vector m0 = e.mins;
	vector m1 = e.maxs;
	e.mins = '0 0 0';
	e.maxs = '0 0 0';
	WarpZoneLib_MoveOutOfSolid_Expand(e, eX * m0.x);  e.mins.x = m0.x;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eX * m1.x);  e.maxs.x = m1.x;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eY * m0.y);  e.mins.y = m0.y;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eY * m1.y);  e.maxs.y = m1.y;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eZ * m0.z);  e.mins.z = m0.z;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eZ * m1.z);  e.maxs.z = m1.z;
	setorigin(e, e.origin);

	tracebox(e.origin, e.mins, e.maxs, e.origin, MOVE_WORLDONLY, e);
	if (trace_startsolid)
	{
		setorigin(e, o);
		return 0; // can't fix
	}

	return 1; // was stuck but is fixed now
}
