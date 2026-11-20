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

// Hitbox size history for g_antilag_bbox: the newest size is kept in fields, older ones in a
// per-entity buffer that only exists while the size changed recently, written only on change.
// At most one entry per origin sample, so this many always cover the whole origin history
// (slowmo gives more samples per game-second than the tick rate suggests).
const int ANTILAG_SIZE_SLOTS = ANTILAG_MAX_ORIGINS;
const float ANTILAG_SIZE_IDLE = 10; // free the buffer when the size didn't change for this long
.int antilag_size_buf_h; // buffer handle + 1; the _h suffix keeps it out of savegames
.int antilag_size_head;
.int antilag_size_count;
.float antilag_size_changed; // time of the newest size, 0 = no baseline yet
.vector antilag_size_mins, antilag_size_maxs, antilag_size_vofs; // newest size
.vector antilag_saved_mins, antilag_saved_maxs, antilag_saved_vofs;
.int antilag_size_rewound; // size we applied: 0 = none, -1 = newest size, n = buffer slot n - 1
vector antilag_read_mins, antilag_read_maxs, antilag_read_vofs;

.float antilag_debug;

void antilag_size_reset(entity store)
{
	if (store.antilag_size_buf_h)
		buf_del(store.antilag_size_buf_h - 1);
	store.antilag_size_buf_h = 0;
	store.antilag_size_count = 0;
	store.antilag_size_changed = 0;
}

ACCUMULATE void ONREMOVE(entity this)
{
	if (this.antilag_size_buf_h)
		antilag_size_reset(this);
}

void antilag_size_write(entity store, int slot, float t, vector mi, vector ma, vector vo)
{
	// %.9g round-trips a float exactly, vtos and ftos don't
	bufstr_set(store.antilag_size_buf_h - 1, slot, sprintf("%.9g|%.9v|%.9v|%.9v", t, mi, ma, vo));
}

bool antilag_size_read(entity store, int slot)
{
	string s = bufstr_get(store.antilag_size_buf_h - 1, slot);
	int a = strstrofs(s, "|", 0);
	int b = strstrofs(s, "|", a + 1);
	int c = strstrofs(s, "|", b + 1);
	if (a < 0 || b < 0 || c < 0)
		return false;
	antilag_read_mins = stov(substring(s, a + 1, b - a - 1));
	antilag_read_maxs = stov(substring(s, b + 1, c - b - 1));
	antilag_read_vofs = stov(substring(s, c + 1, -1));
	return true;
}

// log a size change at time t (no-op if unchanged, the same t overwrites in place)
void antilag_record_size(entity e, entity store, float t)
{
	// spectators are never taken back and antilag_clear on spawn discards their history
	if (!autocvar_g_antilag_bbox || (IS_CLIENT(e) && !IS_PLAYER(e)))
	{
		if (store.antilag_size_changed)
			antilag_size_reset(store);
		return;
	}
	if (!store.antilag_size_changed) // monsters/nades never get antilag_clear
	{
		store.antilag_size_mins = e.mins;
		store.antilag_size_maxs = e.maxs;
		store.antilag_size_vofs = e.view_ofs;
		store.antilag_size_changed = -2342;
		return;
	}
	if (e.mins == store.antilag_size_mins && e.maxs == store.antilag_size_maxs
	&& e.view_ofs == store.antilag_size_vofs)
	{
		if (store.antilag_size_buf_h && t - store.antilag_size_changed > ANTILAG_SIZE_IDLE)
		{
			buf_del(store.antilag_size_buf_h - 1);
			store.antilag_size_buf_h = 0;
			store.antilag_size_count = 0;
		}
		return;
	}

	bool fresh = !store.antilag_size_buf_h;
	if (fresh)
	{
		int h = buf_create();
		if (h >= 0)
		{
			store.antilag_size_buf_h = h + 1;
			antilag_size_write(store, 0, -2342, store.antilag_size_mins, store.antilag_size_maxs,
				store.antilag_size_vofs);
			store.antilag_size_head = 0;
			store.antilag_size_count = 1;
		}
	}
	if (store.antilag_size_buf_h)
	{
		int j = store.antilag_size_head;
		if (fresh || store.antilag_size_changed != t)
		{
			if (++j >= ANTILAG_SIZE_SLOTS)
				j = 0;
			store.antilag_size_head = j;
			if (store.antilag_size_count < ANTILAG_SIZE_SLOTS)
				++store.antilag_size_count;
		}
		antilag_size_write(store, j, t, e.mins, e.maxs, e.view_ofs);
	}
	store.antilag_size_mins = e.mins;
	store.antilag_size_maxs = e.maxs;
	store.antilag_size_vofs = e.view_ofs;
	store.antilag_size_changed = t;
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
	if (autocvar_g_antilag_bbox || store.antilag_size_changed)
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

int antilag_size_slot(entity store, int age)
{
	int s = store.antilag_size_head - age;
	return (s < 0) ? s + ANTILAG_SIZE_SLOTS : s;
}

// buffer slot of the newest entry with time <= T, or of the oldest entry if there is none.
// The caller knows the newest entry (age 0) is after T. Usually the answer is age 1, so
// check that first, then bisect the rest. stof stops at the first |
int antilag_size_find(entity store, float T)
{
	int h = store.antilag_size_buf_h - 1;
	int hi = store.antilag_size_count - 1;
	int lo = (hi > 0) ? 1 : 0;
	if (lo < hi)
	{
		if (stof(bufstr_get(h, antilag_size_slot(store, lo))) <= T)
			hi = lo;
		else
			++lo;
	}
	while (lo < hi)
	{
		int mid = floor((lo + hi) / 2);
		if (stof(bufstr_get(h, antilag_size_slot(store, mid))) <= T)
			hi = mid;
		else
			lo = mid + 1;
	}
	return antilag_size_slot(store, lo);
}

// only undoes our own change: if something resized the entity during the window
// (e.g. vehicles_exit in Damage), that is kept. The caller's setorigin relinks.
void antilag_restore_size(entity e, entity store)
{
	int applied = store.antilag_size_rewound;
	store.antilag_size_rewound = 0;
	if (applied < 0)
	{
		antilag_read_mins = store.antilag_size_mins;
		antilag_read_maxs = store.antilag_size_maxs;
		antilag_read_vofs = store.antilag_size_vofs;
	}
	else if (!antilag_size_read(store, applied - 1))
	{
		antilag_read_mins = e.mins;
		antilag_read_maxs = e.maxs;
		antilag_read_vofs = e.view_ofs;
	}
	if (e.mins == antilag_read_mins && e.maxs == antilag_read_maxs)
	{
		e.mins = store.antilag_saved_mins;
		e.maxs = store.antilag_saved_maxs;
		e.size = e.maxs - e.mins;
	}
	if (e.view_ofs == antilag_read_vofs)
		e.view_ofs = store.antilag_saved_vofs;
}

// i0 is antilag_find(e, store, t). The caller's setorigin relinks with the new size.
void antilag_takeback_size(entity e, entity store, float t, int i0)
{
	float changed = store.antilag_size_changed;
	if (!changed || i0 < 0)
		return; // no history or in the present: keep the current size
	// the sample used below is at or after t, so it can't be older than the newest size
	if (t >= changed && e.mins == store.antilag_size_mins && e.maxs == store.antilag_size_maxs
	&& e.view_ofs == store.antilag_size_vofs)
		return;

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
			return; // newest sample: the next one is the present
		if (++i >= ANTILAG_MAX_ORIGINS)
			i = 0;
	}

	int applied = -1;
	float T = store.antilag_times[i];
	if (T >= changed)
	{
		antilag_read_mins = store.antilag_size_mins;
		antilag_read_maxs = store.antilag_size_maxs;
		antilag_read_vofs = store.antilag_size_vofs;
	}
	else
	{
		if (!store.antilag_size_buf_h)
			return;
		int j = antilag_size_find(store, T);
		if (!antilag_size_read(store, j))
			return;
		applied = j + 1;
	}
	if (antilag_read_mins == e.mins && antilag_read_maxs == e.maxs
	&& antilag_read_vofs == e.view_ofs)
		return;

	store.antilag_saved_mins = e.mins;
	store.antilag_saved_maxs = e.maxs;
	store.antilag_saved_vofs = e.view_ofs;
	// no setsize: it would only relink, and the caller's setorigin does that anyway
	e.mins = antilag_read_mins;
	e.maxs = antilag_read_maxs;
	e.size = e.maxs - e.mins;
	e.view_ofs = antilag_read_vofs; // Headshot() box uses view_ofs_z together with maxs_z
	store.antilag_size_rewound = applied;
}

vector antilag_takebackorigin_at(entity e, entity store, float t, int i0)
{
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

vector antilag_takebackorigin(entity e, entity store, float t)
{
	return antilag_takebackorigin_at(e, store, t, antilag_find(e, store, t));
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

	int i0 = antilag_find(e, store, t);
	if (store.antilag_size_rewound) // nested takeback: start from the present size again
		antilag_restore_size(e, store);
	if (autocvar_g_antilag_bbox)
		antilag_takeback_size(e, store, t, i0); // before setorigin so its relink uses both

	vector org = antilag_takebackorigin_at(e, store, t, i0);
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
	if (store.antilag_size_rewound)
		antilag_restore_size(e, store);
	setorigin(e, store.antilag_saved_origin);
	store.antilag_takenback = false;
}

void antilag_clear(entity e, entity store)
{
	// the caller just set the size authoritatively (e.g. setsize in PutPlayerInServer),
	// never restore an old saved size over it
	store.antilag_size_rewound = 0;
	antilag_restore(e, store);
	for (int i = 0; i < ANTILAG_MAX_ORIGINS; ++i) {
		store.antilag_times[i] = -2342;
		store.antilag_origins[i] = e.origin;
	}
	store.antilag_index = ANTILAG_MAX_ORIGINS - 1; // next one is 0
	antilag_size_reset(store); // the next record adopts the current size
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
