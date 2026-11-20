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

.float antilag_debug;

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

	setorigin(e, store.antilag_saved_origin);
	store.antilag_takenback = false;
}

void antilag_clear(entity e, entity store)
{
	antilag_restore(e, store);
	for (int i = 0; i < ANTILAG_MAX_ORIGINS; ++i) {
		store.antilag_times[i] = -2342;
		store.antilag_origins[i] = e.origin;
	}
	store.antilag_index = ANTILAG_MAX_ORIGINS - 1; // next one is 0
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

// Is the move PM_UpdateButtons is copying a genuinely new client move, or the engine
// re-applying the old host_client->cmd? Called before the copy, so store still holds the
// previous apply.
//  - async (clmovement, outside StartFrame..EndFrame, from SV_ExecuteClientMoves): always a
//    new move, except the second half of a > 50ms move split (same time, same cmd)
//  - in-frame (sync path, SV_Physics_ClientEntity_PreThink): SV_ApplyClientMove re-applies
//    the same cmd every frame. The engine only writes a new ping when it reads a move
//    (sv_user.c SV_ExecuteClientMoves), so any change in ping/aim/movement/attack means a
//    new move. If nothing changed:
//    - the newest new move came in async: this is the clmovement input timeout
//      (sv_phys.c SV_Physics_ClientEntity_PreThink) re-applying it
//    - pure sync mode (vehicles, cl_movement 0, sv_clmovement_minping): a new packet
//      identical in all of these (still player, steady lag) can't be told apart from a
//      re-apply, so it's only treated as one for up to sv_clmovement_inputtimeout, which
//      bounds the age that can be wrongly added
bool antilag_input_isnew(entity this, entity store)
{
	bool same = (this.ping == store.ping
		&& this.v_angle == store.v_angle
		&& this.movement == store.movement
		&& boolean(this.button0) == store.antilag_input_atk_raw);
	if (!antilag_inframe)
		return !(same && store.antilag_input_recv == time);
	if (!same)
		return true;
	if (store.antilag_input_async)
		return false;
	return (time - store.antilag_input_recv >= autocvar_sv_clmovement_inputtimeout);
}

// bookkeeping for g_antilag_inputtime, written regardless of the cvar and read only when it is set
void antilag_input_update(entity this, entity store, bool isnew)
{
	store.antilag_input_atk_raw = boolean(this.button0);
	if (!isnew)
		return; // recv/ping keep describing the move whose aim is still in the edict fields
	store.antilag_input_recv = time; // QC time == sv.time == this move's receivetime for a new move
	store.antilag_input_ping = this.ping;
	store.antilag_input_async = !antilag_inframe;
}

float antilag_latency(entity e)
{
	if (autocvar_g_antilag_inputtime && IS_REAL_CLIENT(e))
	{
		entity s = CS(e);
		// antilag_input_recv/ping belong to the newest genuinely new move (see
		// antilag_input_isnew), i.e. the move whose aim is in v_angle. The age term grows on
		// frames where the engine got no new move, including the sync path (vehicles,
		// cl_movement 0) and input-timeout re-applies of the old cmd.
		if (s.antilag_input_recv)
			return min(0.4, max(0, time - s.antilag_input_recv) + s.antilag_input_ping * 0.001);
	}
	return ANTILAG_LATENCY_PING(e);
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
