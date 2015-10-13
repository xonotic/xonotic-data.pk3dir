#include "all.qh"

#ifdef SVQC
#include "sv_turrets.qh"
#endif

#ifdef CSQC
#include "cl_turrets.qh"
#endif

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION
