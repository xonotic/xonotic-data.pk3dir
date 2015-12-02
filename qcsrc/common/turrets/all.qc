#include "all.qh"

REGISTER_NET_LINKED(ENT_CLIENT_TURRET)

#ifdef SVQC
#include "sv_turrets.qh"
#endif

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION
