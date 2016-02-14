#include "all.qh"

REGISTER_NET_LINKED(ENT_CLIENT_TURRET)

#ifdef SVQC
#include "sv_turrets.qh"
#endif

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION

#ifdef CSQC
#include "cl_turrets.qc"
#endif

#ifdef SVQC
#include "sv_turrets.qc"
#include "config.qc"
#include "util.qc"
#include "checkpoint.qc"
#include "targettrigger.qc"
#endif
