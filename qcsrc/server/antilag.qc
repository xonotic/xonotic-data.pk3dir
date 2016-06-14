#include "antilag.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <common/state.qh>
    #include <common/vehicles/all.qh>
    #include "antilag.qh"
#endif

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
	store.antilag_index += 1;
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
