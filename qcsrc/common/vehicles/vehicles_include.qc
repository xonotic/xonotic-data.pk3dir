#ifndef VEHICLES_INCLUDE_C
#define VEHICLES_INCLUDE_C

#include "vehicles_include.qh"

#ifdef CSQC
#include "cl_vehicles.qc"
#include "vehicles.qc"
#endif // CSQC
#ifdef SVQC
#include "sv_vehicles.qc"
#include "vehicles.qc"
#endif // SVQC

#endif
