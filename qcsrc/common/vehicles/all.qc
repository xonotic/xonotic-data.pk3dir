#include "all.qh"
#ifndef VEHICLES_ALL_C
#define VEHICLES_ALL_C

REGISTER_NET_LINKED(ENT_CLIENT_AUXILIARYXHAIR)

#if defined(SVQC)
	#include "sv_vehicles.qc"
#elif defined(CSQC)
	#include "cl_vehicles.qc"
#endif

#define IMPLEMENTATION
#include "vehicle/_mod.inc"
#undef IMPLEMENTATION

#endif
