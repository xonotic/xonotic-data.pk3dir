#include "common.qh"

#include <common/checkextension.qh>

#if defined(CSQC)
    #include <client/items/items.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <common/weapons/_all.qh>
#endif

void WarpZone_Accumulator_Clear(entity acc)
{
	acc.warpzone_transform = '0 0 0';
	acc.warpzone_shift = '0 0 0';
}
void WarpZone_Accumulator_AddTransform(entity acc, vector t, vector s)
{
	vector tr, st;
	tr = AnglesTransform_Multiply(t, acc.warpzone_transform);
	st = AnglesTransform_Multiply_GetPostShift(t, s, acc.warpzone_transform, acc.warpzone_shift);
	acc.warpzone_transform = tr;
	acc.warpzone_shift = st;
}
void WarpZone_Accumulator_Add(entity acc, entity wz)
{
	WarpZone_Accumulator_AddTransform(acc, wz.warpzone_transform, wz.warpzone_shift);
}
void WarpZone_Accumulator_AddInverseTransform(entity acc, vector t, vector s)
{
	vector tt, ss;
	tt = AnglesTransform_Invert(t);
	ss = AnglesTransform_PrePostShift_GetPostShift(s, tt, '0 0 0');
	WarpZone_Accumulator_AddTransform(acc, tt, ss);
	// yes, this probably can be done simpler... but this way is "obvious" :)
}
void WarpZone_Accumulator_AddInverse(entity acc, entity wz)
{
	WarpZone_Accumulator_AddInverseTransform(acc, wz.warpzone_transform, wz.warpzone_shift);
}

float autocvar_cl_warpzone_usetrace = 1;
vector WarpZone_camera_transform(entity this, vector org, vector ang)
{
	vector vf, vr, vu;
	if(this.warpzone_fadestart)
		if(vdist(org - this.origin - 0.5 * (this.mins + this.maxs), >, this.warpzone_fadeend + 400))
			return org;
			// don't transform if zone faded out (plus 400qu safety margin for typical speeds and latencies)
			// unneeded on client, on server this helps a lot
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	org = WarpZone_TransformOrigin(this, org);
	vf = WarpZone_TransformVelocity(this, vf);
	vr = WarpZone_TransformVelocity(this, vr);
	vu = WarpZone_TransformVelocity(this, vu);
	if(autocvar_cl_warpzone_usetrace)
		traceline(this.warpzone_targetorigin, org, MOVE_NOMONSTERS, NULL);
	else
		trace_endpos = this.warpzone_targetorigin;
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
	if(this.warpzone_fadestart)
		if(vdist(org - this.origin - 0.5 * (this.mins + this.maxs), >, this.warpzone_fadeend + 400))
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

.entity enemy;

float WarpZoneLib_BoxTouchesBrush_Recurse(vector mi, vector ma, entity e, entity ig)
{
	float f, s;
	entity se;

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

	se = trace_ent;
	s = se.solid;
	se.solid = SOLID_NOT;
	setorigin(se, se.origin); // unlink
	f = WarpZoneLib_BoxTouchesBrush_Recurse(mi, ma, e, ig);
	se.solid = s;
	setorigin(se, se.origin); // relink

	return f;
}

float WarpZoneLib_BoxTouchesBrush(vector mi, vector ma, entity e, entity ig)
{
	// bones_was_here: TODO: when findbox_OrFallback() is available, use it to
	// optimise this into a single non-recursive function that only calls tracebox once

	float f, s;

	if(!e.modelindex || e.warpzone_isboxy)
		return 1;

	// work around trigger_hurt on geit3ctf1 not being detected by tracebox
	// bones_was_here: FIXME: WHY do these triggers only have supercontents == 128 ?!
	if (Q3COMPAT_COMMON && ig != world)
		ig.dphitcontentsmask |= 128;

	s = e.solid;
	if (e.solid != SOLID_BSP)
	{
		e.solid = SOLID_BSP;
		setorigin(e, e.origin); // update linking
	}
	f = WarpZoneLib_BoxTouchesBrush_Recurse(mi, ma, e, ig);
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
	if(!warpzone_warpzones_exist)
		return NULL;
	IL_EACH(g_warpzones, WarpZoneLib_BoxTouchesBrush(mi, ma, it, NULL),
	{
		return it;
	});
	return NULL;
}

void WarpZone_MakeAllSolid()
{
	if(!warpzone_warpzones_exist)
		return;
	IL_EACH(g_warpzones, true,
	{
		it.solid = SOLID_BSP;
	});
}

void WarpZone_MakeAllOther()
{
	if(!warpzone_warpzones_exist)
		return;
	IL_EACH(g_warpzones, true,
	{
		it.solid = SOLID_TRIGGER;
	});
}

void WarpZone_Trace_InitTransform()
{
	if(!WarpZone_trace_transform)
	{
		WarpZone_trace_transform = new_pure(warpzone_trace_transform);
	}
	WarpZone_Accumulator_Clear(WarpZone_trace_transform);
}
void WarpZone_Trace_AddTransform(entity wz)
{
	WarpZone_Accumulator_Add(WarpZone_trace_transform, wz);
}

void WarpZone_TraceBox_ThroughZone(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent, entity zone, WarpZone_trace_callback_t cb)
{
	float nomonsters_adjusted;
	float frac, sol, i;
	float contentshack;
	entity wz;
	vector vf, vr, vu;

	WarpZone_trace_forent = forent;
	WarpZone_trace_firstzone = NULL;
	WarpZone_trace_lastzone = NULL;
	WarpZone_Trace_InitTransform();
	if(!warpzone_warpzones_exist)
	{
		if(nomonsters == MOVE_NOTHING)
		{
			trace_endpos = end;
			trace_fraction = 1;
			if(cb)
				cb(org, trace_endpos, end);
			return;
		}
		else
		{
			tracebox(org, mi, ma, end, nomonsters, WarpZone_trace_forent);
			if(cb)
				cb(org, trace_endpos, end);
			return;
		}
	}

	vf = v_forward;
	vr = v_right;
	vu = v_up;

	switch(nomonsters)
	{
		case MOVE_WORLDONLY:
		case MOVE_NOTHING:
			nomonsters_adjusted = MOVE_NOMONSTERS;
			break;
		default:
			nomonsters_adjusted = nomonsters;
			break;
	}
	if((contentshack = (WarpZone_trace_forent.dphitcontentsmask && !(WarpZone_trace_forent.dphitcontentsmask & DPCONTENTS_SOLID))))
		BITSET_ASSIGN(WarpZone_trace_forent.dphitcontentsmask, DPCONTENTS_SOLID);

	// if starting in warpzone, first transform
	wz = WarpZone_Find(org + mi, org + ma);
	if(wz)
	{
		WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if(zone && wz != zone)
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
	frac = 0;
	i = 16;
	for (;;)
	{
		if(--i < 1)
		{
			LOG_TRACE("Too many warpzones in sequence, aborting trace.");
			trace_ent = NULL;
			break;
		}
		tracebox(org, mi, ma, end, nomonsters_adjusted, WarpZone_trace_forent);
		if(cb)
			cb(org, trace_endpos, end);
		if(sol < 0)
			sol = trace_startsolid;

		frac = trace_fraction = frac + (1 - frac) * trace_fraction;
		if(trace_fraction >= 1)
			break;
		if(trace_ent.classname != "trigger_warpzone")
		{
			if((nomonsters == MOVE_NOTHING) || ((nomonsters == MOVE_WORLDONLY) && trace_ent) || (contentshack && (trace_dphitcontents & WarpZone_trace_forent.dphitcontentsmask) == DPCONTENTS_SOLID))
			{
				// continue the trace, ignoring this hit (we only care for warpzones)
				org = trace_endpos + normalize(end - org);
				continue;
				// we cannot do an inverted trace here, as we do care for further warpzones inside that "solid" to be found
				// otherwise, players could block entrances that way
			}
			break;
		}
		/*if(trace_ent == wz)
		{
			// FIXME can this check be removed? Do we really need it?
			LOG_TRACE("I transformed into the same zone again, wtf, aborting the trace");
			trace_ent = NULL;
			break;
		}*/
		wz = trace_ent;
		if(!WarpZone_trace_firstzone)
			WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if(zone && wz != zone)
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
	if(contentshack)
		BITCLR_ASSIGN(WarpZone_trace_forent.dphitcontentsmask, DPCONTENTS_SOLID);
	trace_startsolid = sol;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
}

void WarpZone_TraceBox(vector org, vector mi, vector ma, vector end, float nomonsters, entity forent)
{
	WarpZone_TraceBox_ThroughZone(org, mi, ma, end, nomonsters, forent, NULL, WarpZone_trace_callback_t_null);
}

void WarpZone_TraceLine(vector org, vector end, float nomonsters, entity forent)
{
	WarpZone_TraceBox(org, '0 0 0', '0 0 0', end, nomonsters, forent);
}

void WarpZone_TraceToss_ThroughZone(entity e, entity forent, entity zone, WarpZone_trace_callback_t cb)
{
	float g, dt, i;
	vector vf, vr, vu, v0, o0;
	entity wz;

	o0 = e.origin;
	v0 = e.velocity;
	g = cvar("sv_gravity") * e.gravity;

	WarpZone_trace_forent = forent;
	WarpZone_trace_firstzone = NULL;
	WarpZone_trace_lastzone = NULL;
	WarpZone_Trace_InitTransform();
	WarpZone_tracetoss_time = 0;
	if(!warpzone_warpzones_exist)
	{
		tracetoss(e, WarpZone_trace_forent);
		if(cb)
			cb(e.origin, trace_endpos, trace_endpos);
		dt = vlen(e.origin - o0) / vlen(e.velocity);
		WarpZone_tracetoss_time += dt;
		e.velocity_z -= dt * g;
		WarpZone_tracetoss_velocity = e.velocity;
		e.velocity = v0;
		return;
	}

	vf = v_forward;
	vr = v_right;
	vu = v_up;

	// if starting in warpzone, first transform
	wz = WarpZone_Find(e.origin + e.mins, e.origin + e.maxs);
	if(wz)
	{
		WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if(zone && wz != zone)
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
		if(--i < 1)
		{
			LOG_TRACE("Too many warpzones in sequence, aborting trace.");
			trace_ent = NULL;
			break;
		}
		tracetoss(e, WarpZone_trace_forent);
		if(cb)
			cb(e.origin, trace_endpos, trace_endpos);
		dt = vlen(trace_endpos - e.origin) / vlen(e.velocity);
		WarpZone_tracetoss_time += dt;
		e.origin = trace_endpos;
		e.velocity_z -= dt * g;
		if(trace_fraction >= 1)
			break;
		if(trace_ent.classname != "trigger_warpzone")
			break;
		if(trace_ent == wz)
		{
			// FIXME can this check be removed? Do we really need it?
			LOG_TRACE("I transformed into the same zone again, wtf, aborting the trace");
			trace_ent = NULL;
			break;
		}
		wz = trace_ent;
		if(!WarpZone_trace_firstzone)
			WarpZone_trace_firstzone = wz;
		WarpZone_trace_lastzone = wz;
		if(zone && wz != zone)
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

void WarpZone_TraceToss(entity e, entity forent)
{
	WarpZone_TraceToss_ThroughZone(e, forent, NULL, WarpZone_trace_callback_t_null);
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

float WarpZone_PlaneDist(entity wz, vector v)
{
	return (v - wz.warpzone_origin) * wz.warpzone_forward;
}

float WarpZone_TargetPlaneDist(entity wz, vector v)
{
	return (v - wz.warpzone_targetorigin) * wz.warpzone_targetforward;
}

vector WarpZone_TransformOrigin(entity wz, vector v)
{
	return wz.warpzone_shift + AnglesTransform_Apply(wz.warpzone_transform, v);
}

vector WarpZone_TransformVelocity(entity wz, vector v)
{
	return AnglesTransform_Apply(wz.warpzone_transform, v);
}

vector WarpZone_TransformAngles(entity wz, vector v)
{
	return AnglesTransform_ApplyToAngles(wz.warpzone_transform, v);
}

vector WarpZone_TransformVAngles(entity wz, vector ang)
{
#ifdef KEEP_ROLL
	float roll;
	roll = ang.z;
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

vector WarpZone_UnTransformOrigin(entity wz, vector v)
{
	return AnglesTransform_Apply(AnglesTransform_Invert(wz.warpzone_transform), v - wz.warpzone_shift);
}

vector WarpZone_UnTransformVelocity(entity wz, vector v)
{
	return AnglesTransform_Apply(AnglesTransform_Invert(wz.warpzone_transform), v);
}

vector WarpZone_UnTransformAngles(entity wz, vector v)
{
	return AnglesTransform_ApplyToAngles(AnglesTransform_Invert(wz.warpzone_transform), v);
}

vector WarpZone_UnTransformVAngles(entity wz, vector ang)
{
#ifdef KEEP_ROLL
	float roll;
	roll = ang.z;
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

vector WarpZoneLib_NearestPointOnBox(vector mi, vector ma, vector org)
{
	vector nearest;
	nearest.x = bound(mi.x, org.x, ma.x);
	nearest.y = bound(mi.y, org.y, ma.y);
	nearest.z = bound(mi.z, org.z, ma.z);
	return nearest;
}

// blacklist of entities that WarpZone_FindRadius doesn't care about
bool WarpZoneLib_BadEntity(entity e)
{
	if (is_pure(e)) return true;
	string s = e.classname;

	switch(s)
	{
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

	if (startsWith(s, "target_")) return true;

	if (startsWith(s, "info_")) return true;

	return false;
}

.float WarpZone_findradius_hit;
.entity WarpZone_findradius_next;
void WarpZone_FindRadius_Recurse(
    /** blast origin of current search */
    vector org,
    float rad,
    /** original blast origin */
    vector org0,
    /** how to untransform (victim to blast system) */
    vector transform,
    vector shift,
    bool needlineofsight)
{
	if (rad <= 0) return;
	entity wz = NULL;
	FOREACH_ENTITY_RADIUS(org, rad, !WarpZoneLib_BadEntity(it), {
		vector p = WarpZoneLib_NearestPointOnBox(it.origin + it.mins, it.origin + it.maxs, org0);
		if (needlineofsight)
		{
			traceline(org, p, MOVE_NOMONSTERS, it);
			if (trace_fraction < 1) continue;
		}
		if (!it.WarpZone_findradius_hit || vlen2(it.WarpZone_findradius_dist) > vlen2(org0 - p))
		{
			it.WarpZone_findradius_nearest = p;
			it.WarpZone_findradius_dist = org0 - p;
			it.WarpZone_findradius_findorigin = org;
			it.WarpZone_findradius_findradius = rad;
			if (it.classname == "warpzone_refsys")
			{
				// ignore, especially: do not overwrite the refsys parameters
			}
			else if (it.classname == "trigger_warpzone")
			{
				it.WarpZone_findradius_next = wz;
				wz = it;
				it.WarpZone_findradius_hit = 1;
				it.enemy.WarpZone_findradius_dist = '0 0 0'; // we don't want to go through this zone ever again
				it.enemy.WarpZone_findradius_hit = 1;
			}
			else
			{
				it.warpzone_transform = transform;
				it.warpzone_shift = shift;
				it.WarpZone_findradius_hit = 1;
			}
		}
    });
	for(entity e = wz; e; e = e.WarpZone_findradius_next)
	{
		if (WarpZoneLib_BadEntity(e)) continue;

		vector org0_new = WarpZone_TransformOrigin(e, org);
		traceline(e.warpzone_targetorigin, org0_new, MOVE_NOMONSTERS, e);
		vector org_new = trace_endpos;

		vector transform_new = AnglesTransform_Multiply(e.warpzone_transform, transform);
		vector shift_new = AnglesTransform_Multiply_GetPostShift(e.warpzone_transform, e.warpzone_shift, transform, shift);
		WarpZone_FindRadius_Recurse(
			org_new,
			bound(0, rad - vlen(org_new - org0_new), rad - 8),
			org0_new,
			transform_new, shift_new,
			needlineofsight);
		e.WarpZone_findradius_hit = 0;
		e.enemy.WarpZone_findradius_hit = 0;
	}
}
entity WarpZone_FindRadius(vector org, float rad, bool needlineofsight)
{
    // FIXME: why can't we do this? (sometimes finds nothing, breaking explosions)
    // if (!warpzone_warpzones_exist && !needlineofsight) return findradius(org, rad);
	WarpZone_FindRadius_Recurse(org, rad, org, '0 0 0', '0 0 0', needlineofsight);
	entity list_first = findchainfloat(WarpZone_findradius_hit, 1);
	FOREACH_LIST(list, chain, true, it.WarpZone_findradius_hit = 0);
	return list_first;
}

.entity WarpZone_refsys;
void WarpZone_RefSys_GC(entity this)
{
	// garbage collect unused reference systems
	this.nextthink = time + 1;
	if(this.owner.WarpZone_refsys != this)
		delete(this);
}
void WarpZone_RefSys_CheckCreate(entity me)
{
	if(me.WarpZone_refsys.owner != me)
	{
		me.WarpZone_refsys = new(warpzone_refsys);
		me.WarpZone_refsys.owner = me;
		setthink(me.WarpZone_refsys, WarpZone_RefSys_GC);
		me.WarpZone_refsys.nextthink = time + 1;
		WarpZone_Accumulator_Clear(me.WarpZone_refsys);
	}
}
void WarpZone_RefSys_Clear(entity me)
{
	if(me.WarpZone_refsys)
	{
		delete(me.WarpZone_refsys);
		me.WarpZone_refsys = NULL;
	}
}
void WarpZone_RefSys_AddTransform(entity me, vector t, vector s)
{
	if(t != '0 0 0' || s != '0 0 0')
	{
		WarpZone_RefSys_CheckCreate(me);
		WarpZone_Accumulator_AddTransform(me.WarpZone_refsys, t, s);
	}
}
void WarpZone_RefSys_Add(entity me, entity wz)
{
	WarpZone_RefSys_AddTransform(me, wz.warpzone_transform, wz.warpzone_shift);
}
void WarpZone_RefSys_AddInverseTransform(entity me, vector t, vector s)
{
	if(t != '0 0 0' || s != '0 0 0')
	{
		WarpZone_RefSys_CheckCreate(me);
		WarpZone_Accumulator_AddInverseTransform(me.WarpZone_refsys, t, s);
	}
}
void WarpZone_RefSys_AddInverse(entity me, entity wz)
{
	WarpZone_RefSys_AddInverseTransform(me, wz.warpzone_transform, wz.warpzone_shift);
}
.vector WarpZone_refsys_incremental_shift;
.vector WarpZone_refsys_incremental_transform;
void WarpZone_RefSys_AddIncrementally(entity me, entity ref)
{
	//vector t, s;
	if(me.WarpZone_refsys_incremental_transform == ref.WarpZone_refsys.warpzone_transform)
	if(me.WarpZone_refsys_incremental_shift == ref.WarpZone_refsys.warpzone_shift)
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
vector WarpZone_RefSys_TransformOrigin(entity from, entity to, vector org)
{
	if(from.WarpZone_refsys)
		org = WarpZone_UnTransformOrigin(from.WarpZone_refsys, org);
	if(to.WarpZone_refsys)
		org = WarpZone_TransformOrigin(to.WarpZone_refsys, org);
	return org;
}
vector WarpZone_RefSys_TransformVelocity(entity from, entity to, vector vel)
{
	if(from.WarpZone_refsys)
		vel = WarpZone_UnTransformVelocity(from.WarpZone_refsys, vel);
	if(to.WarpZone_refsys)
		vel = WarpZone_TransformVelocity(to.WarpZone_refsys, vel);
	return vel;
}
vector WarpZone_RefSys_TransformAngles(entity from, entity to, vector ang)
{
	if(from.WarpZone_refsys)
		ang = WarpZone_UnTransformAngles(from.WarpZone_refsys, ang);
	if(to.WarpZone_refsys)
		ang = WarpZone_TransformAngles(to.WarpZone_refsys, ang);
	return ang;
}
vector WarpZone_RefSys_TransformVAngles(entity from, entity to, vector ang)
{
	if(from.WarpZone_refsys)
		ang = WarpZone_UnTransformVAngles(from.WarpZone_refsys, ang);
	if(to.WarpZone_refsys)
		ang = WarpZone_TransformVAngles(to.WarpZone_refsys, ang);
	return ang;
}
void WarpZone_RefSys_Copy(entity me, entity from)
{
	if(from.WarpZone_refsys)
	{
		WarpZone_RefSys_CheckCreate(me);
		me.WarpZone_refsys.warpzone_shift = from.WarpZone_refsys.warpzone_shift;
		me.WarpZone_refsys.warpzone_transform = from.WarpZone_refsys.warpzone_transform;
	}
	else
		WarpZone_RefSys_Clear(me);
}
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
	const float eps = 0.0625;
	tracebox(e.origin, e.mins - '1 1 1' * eps, e.maxs + '1 1 1' * eps, e.origin + by, MOVE_WORLDONLY, e);
	if (trace_startsolid)
		return;
	if (trace_fraction < 1)
	{
		// hit something
		// adjust origin in the other direction...
		setorigin(e, e.origin - by * (1 - trace_fraction));
	}
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
	WarpZoneLib_MoveOutOfSolid_Expand(e, eX * m0.x); e.mins_x = m0.x;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eX * m1.x); e.maxs_x = m1.x;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eY * m0.y); e.mins_y = m0.y;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eY * m1.y); e.maxs_y = m1.y;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eZ * m0.z); e.mins_z = m0.z;
	WarpZoneLib_MoveOutOfSolid_Expand(e, eZ * m1.z); e.maxs_z = m1.z;
	setorigin(e, e.origin);

	tracebox(e.origin, e.mins, e.maxs, e.origin, MOVE_WORLDONLY, e);
	if (trace_startsolid)
	{
		setorigin(e, o);
		return 0; // can't fix
	}

	return 1; // was stuck but is fixed now
}
