#include "antilag.qh"

#include <common/monsters/sv_monsters.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <server/antilag.qh>
#include <server/weapons/common.qh>

const int ANTILAG_MAX_ORIGINS = 64;
.vector antilag_origins[ANTILAG_MAX_ORIGINS];
.float antilag_times[ANTILAG_MAX_ORIGINS];
.int antilag_index;
.vector antilag_saved_origin;
.float antilag_takenback;

// size (mins/maxs/view_ofs) change log for g_antilag_bbox, only appended to when the size changes.
// It gets at most one entry per origin record time, so with as many slots as the origin ring
// it always covers at least the origin history.
const int ANTILAG_MAX_SIZES = ANTILAG_MAX_ORIGINS;
.float antilag_size_times[ANTILAG_MAX_SIZES];
.vector antilag_size_mins[ANTILAG_MAX_SIZES];
.vector antilag_size_maxs[ANTILAG_MAX_SIZES];
.vector antilag_size_vofs[ANTILAG_MAX_SIZES];
.int antilag_size_index;
.bool antilag_size_init;
.bool antilag_size_takenback;
.vector antilag_saved_mins, antilag_saved_maxs, antilag_saved_vofs;
.vector antilag_applied_mins, antilag_applied_maxs, antilag_applied_vofs;

.float antilag_debug;

void antilag_size_fill(entity e, entity store)
{
	for (int j = 0; j < ANTILAG_MAX_SIZES; ++j)
	{
		store.antilag_size_times[j] = -2342;
		store.antilag_size_mins[j] = e.mins;
		store.antilag_size_maxs[j] = e.maxs;
		store.antilag_size_vofs[j] = e.view_ofs;
	}
	store.antilag_size_index = 0;
	store.antilag_size_init = true;
}

// log a size change at time t (no-op if unchanged, the same t overwrites in place)
void antilag_record_size(entity e, entity store, float t)
{
	if (!store.antilag_size_init)
		antilag_size_fill(e, store); // monsters/nades never get antilag_clear
	int j = store.antilag_size_index;
	if (e.mins == store.antilag_size_mins[j]
	&& e.maxs == store.antilag_size_maxs[j]
	&& e.view_ofs == store.antilag_size_vofs[j])
		return;
	if (store.antilag_size_times[j] != t)
	{
		++j;
		if (j >= ANTILAG_MAX_SIZES)
			j = 0;
		store.antilag_size_index = j;
		store.antilag_size_times[j] = t;
	}
	store.antilag_size_mins[j] = e.mins;
	store.antilag_size_maxs[j] = e.maxs;
	store.antilag_size_vofs[j] = e.view_ofs;
}

void antilag_record(entity e, entity store, float t)
{
	if (e.vehicle) {
		if (e.vehicle.vehicle_flags == VHF_PLAYERSLOT) return;
		antilag_record(e.vehicle, e.vehicle, t);
	}

	if (time < store.antilag_times[store.antilag_index]) return;
	++store.antilag_index;
	if (store.antilag_index >= ANTILAG_MAX_ORIGINS)
		store.antilag_index = 0;
	store.antilag_times[store.antilag_index] = t;
	store.antilag_origins[store.antilag_index] = e.origin;
	// ungated: only writes antilag_size_* fields, keeps the history valid for g_antilag_bbox
	antilag_record_size(e, store, t);

	if (store.antilag_debug)
		te_spark(antilag_takebackorigin(e, store, t - store.antilag_debug), '0 0 0', 32);
}

// finds the index BEFORE t
float antilag_find(entity e, entity store, float t)
{
	for(int i = store.antilag_index; i > 0; --i)
		if(store.antilag_times[i] >= t)
			if(store.antilag_times[i - 1] < t)
				return i - 1;

	if(store.antilag_times[0] >= t)
		if(store.antilag_times[ANTILAG_MAX_ORIGINS - 1] < t)
			return ANTILAG_MAX_ORIGINS - 1;

	for(int i = ANTILAG_MAX_ORIGINS - 1; i > store.antilag_index + 1; --i)
		if(store.antilag_times[i] >= t)
			if(store.antilag_times[i - 1] < t)
				return i - 1;

	// if we get here, t is sandwiched nowhere, so let's assume it's in the present
	return -1;
}

// newest size log entry with time <= T; if none (overflow), the oldest entry (best effort)
int antilag_size_find(entity store, float T)
{
	int j = store.antilag_size_index;
	for (int n = 0; n < ANTILAG_MAX_SIZES; ++n)
	{
		if (store.antilag_size_times[j] <= T)
			return j;
		--j;
		if (j < 0)
			j = ANTILAG_MAX_SIZES - 1;
	}
	j = store.antilag_size_index + 1;
	if (j >= ANTILAG_MAX_SIZES)
		j = 0;
	return j;
}

void antilag_takeback_size(entity e, entity store, float t)
{
	if (!store.antilag_size_takenback)
	{
		store.antilag_saved_mins = e.mins;
		store.antilag_saved_maxs = e.maxs;
		store.antilag_saved_vofs = e.view_ofs;
	}
	// present (find == -1): saved size (== current size unless nested takeback)
	vector mi = store.antilag_saved_mins;
	vector ma = store.antilag_saved_maxs;
	vector vo = store.antilag_saved_vofs;
	if (store.antilag_size_init)
	{
		int i0 = antilag_find(e, store, t);
		if (i0 >= 0)
		{
			// use the sample the client displays at t: CSQC snaps discrete state (duck, corpse)
			// to the newest snapshot while the origin still interpolates toward it
			int i = i0 + 1;
			if (i >= ANTILAG_MAX_ORIGINS)
				i = 0;
			// antilag_find puts t == times[i] into (times[i0], times[i]], but at exactly that
			// time the client already interpolates from sample i toward i + 1 and shows the
			// discrete state of i + 1 (cl.time often lands exactly on snapshot times);
			// 0.1ms tolerance for float rounding of t
			if (t >= store.antilag_times[i] - 0.0001)
			{
				if (i == store.antilag_index)
					i = -1; // newest sample: the next one is the present
				else if (++i >= ANTILAG_MAX_ORIGINS)
					i = 0;
			}
			if (i >= 0)
			{
				int j = antilag_size_find(store, store.antilag_times[i]);
				mi = store.antilag_size_mins[j];
				ma = store.antilag_size_maxs[j];
				vo = store.antilag_size_vofs[j];
			}
		}
	}
	if (mi != e.mins || ma != e.maxs)
		setsize(e, mi, ma); // relinks: absmin/absmax + area grid must match for traces
	e.view_ofs = vo; // Headshot() box uses view_ofs_z together with maxs_z
	store.antilag_applied_mins = e.mins;
	store.antilag_applied_maxs = e.maxs;
	store.antilag_applied_vofs = e.view_ofs;
	store.antilag_size_takenback = true;
}

void antilag_restore_size(entity e, entity store)
{
	// only undo our own change: if something resized the entity during the window
	// (e.g. vehicles_exit in Damage), keep that
	if (e.mins == store.antilag_applied_mins && e.maxs == store.antilag_applied_maxs
	&& (e.mins != store.antilag_saved_mins || e.maxs != store.antilag_saved_maxs))
		setsize(e, store.antilag_saved_mins, store.antilag_saved_maxs);
	if (e.view_ofs == store.antilag_applied_vofs)
		e.view_ofs = store.antilag_saved_vofs;
	store.antilag_size_takenback = false;
}

vector antilag_takebackorigin(entity e, entity store, float t)
{
	int i0 = antilag_find(e, store, t);
	if (i0 < 0)
	{
		// IN THE PRESENT
		if(store.antilag_takenback)
			return store.antilag_saved_origin;
		else
			return e.origin;
	}
	int i1 = i0 + 1;
	if (i1 >= ANTILAG_MAX_ORIGINS)
		i1 = 0;

	return lerpv(store.antilag_times[i0], store.antilag_origins[i0], store.antilag_times[i1], store.antilag_origins[i1], t);
}

vector antilag_takebackavgvelocity(entity e, entity store, float t0, float t1)
{
	if (t0 >= t1) return '0 0 0';
	vector o0 = antilag_takebackorigin(e, store, t0);
	vector o1 = antilag_takebackorigin(e, store, t1);
	return (o1 - o0) * (1 / (t1 - t0));
}

void antilag_takeback(entity e, entity store, float t)
{
	if (e.vehicle) {
		if (e.vehicle.vehicle_flags == VHF_PLAYERSLOT) return;
		antilag_takeback(e.vehicle, e.vehicle, t);
	}

	if (!store.antilag_takenback)
		store.antilag_saved_origin = e.origin;

	if (autocvar_g_antilag_bbox)
		antilag_takeback_size(e, store, t); // before setorigin so the final relink uses both

	vector org = antilag_takebackorigin(e, store, t);
	setorigin(e, org);
	store.antilag_takenback = true;
}

void antilag_restore(entity e, entity store)
{
	if (e.vehicle) {
		if (e.vehicle.vehicle_flags == VHF_PLAYERSLOT) return;
		antilag_restore(e.vehicle, e.vehicle);
	}

	if (!store.antilag_takenback) return;

	// flag-driven, not cvar-driven, so this is safe if the cvar changes mid-window
	if (store.antilag_size_takenback)
		antilag_restore_size(e, store);
	setorigin(e, store.antilag_saved_origin);
	store.antilag_takenback = false;
}

void antilag_clear(entity e, entity store)
{
	// the caller just set the size authoritatively (e.g. setsize in PutPlayerInServer),
	// never restore an old saved size over it
	store.antilag_size_takenback = false;
	antilag_restore(e, store);
	for (int i = 0; i < ANTILAG_MAX_ORIGINS; ++i) {
		store.antilag_times[i] = -2342;
		store.antilag_origins[i] = e.origin;
	}
	store.antilag_index = ANTILAG_MAX_ORIGINS - 1; // next one is 0
	antilag_size_fill(e, store);
}

// TODO: use a single intrusive list across all antilagged entities
void antilag_takeback_all(entity ignore, float lag)
{
	FOREACH_CLIENT(IS_PLAYER(it) && it != ignore, antilag_takeback(it, CS(it), time - lag));
	IL_EACH(g_monsters, it != ignore,
	{
		antilag_takeback(it, it, time - lag);
	});
	IL_EACH(g_projectiles, it != ignore && it.classname == "nade",
	{
		antilag_takeback(it, it, time - lag);
	});
}

void antilag_restore_all(entity ignore)
{
	FOREACH_CLIENT(IS_PLAYER(it) && it != ignore, antilag_restore(it, CS(it)));
	IL_EACH(g_monsters, it != ignore,
	{
		antilag_restore(it, it);
	});
	IL_EACH(g_projectiles, it != ignore && it.classname == "nade",
	{
		antilag_restore(it, it);
	});
}

float antilag_getlag(entity e)
{
	float lag = ((IS_REAL_CLIENT(e)) ? ANTILAG_LATENCY(e) : 0);
	bool noantilag = ((IS_CLIENT(e)) ? CS_CVAR(e).cvar_cl_noantilag : false);
	if(autocvar_g_antilag == 0 || noantilag || lag < 0.001)
		lag = 0;

	return lag;
}

/*
==================
traceline_antilag

A version of traceline that must be used by SOLID_SLIDEBOX things that want to hit SOLID_CORPSE things with a trace attack
Additionally it moves players back into the past before the trace and restores them afterward.
==================
*/
void tracebox_antilag_force_wz(entity source, vector v1, vector mi, vector ma, vector v2,
	float nomonsters, entity forent, float lag,
	bool wz, WarpZone_trace_callback_t cb)
{
	if (lag < 0.001 // check whether antilagged traces are enabled
	|| !IS_REAL_CLIENT(forent)) // only antilag for clients
		lag = 0;

	// change shooter to SOLID_BBOX so the shot can hit corpses
	int oldsolid = source.dphitcontentsmask;
	if (source)
		source.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	if (lag)
		antilag_takeback_all(forent, lag);

	// do the trace
	if (wz)
		WarpZone_TraceBox_ThroughZone(v1, mi, ma, v2, nomonsters, forent, NULL, cb);
	else
	{
		tracebox(v1, mi, ma, v2, nomonsters, forent);
		if (cb)
			cb(v1, trace_endpos, v2);
	}

	// restore players to current positions
	if (lag)
		antilag_restore_all(forent);

	// restore shooter solid type
	if (source)
		source.dphitcontentsmask = oldsolid;
}

void traceline_antilag(entity source, vector v1, vector v2, float nomonsters, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || (IS_CLIENT(source) && CS_CVAR(source).cvar_cl_noantilag))
		lag = 0;
	traceline_antilag_force(source, v1, v2, nomonsters, forent, lag);
}
void WarpZone_traceline_antilag(entity source, vector v1, vector v2, float nomonsters, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || (IS_CLIENT(source) && CS_CVAR(source).cvar_cl_noantilag))
		lag = 0;
	WarpZone_traceline_antilag_force(source, v1, v2, nomonsters, forent, lag);
}

void tracebox_antilag(entity source, vector v1, vector mi, vector ma, vector v2, float nomonsters, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || (IS_CLIENT(source) && CS_CVAR(source).cvar_cl_noantilag))
		lag = 0;
	tracebox_antilag_force_wz(source, v1, mi, ma, v2, nomonsters, forent, lag, false, func_null);
}
void WarpZone_tracebox_antilag(entity source, vector v1, vector mi, vector ma, vector v2, float nomonsters, entity forent, float lag)
{
	if (autocvar_g_antilag != 2 || (IS_CLIENT(source) && CS_CVAR(source).cvar_cl_noantilag))
		lag = 0;
	tracebox_antilag_force_wz(source, v1, mi, ma, v2, nomonsters, forent, lag, true, func_null);
}
