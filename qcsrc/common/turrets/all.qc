#include "all.qh"

Turret get_turretinfo(int id)
{
    if (id < 1 || id > TUR_COUNT - 1)
        return TUR_Null;
    Turret m = turret_info[id];
    if (m) return m;
    return TUR_Null;
}

#ifdef SVQC
#include "sv_turrets.qh"
#endif

#ifdef CSQC
#include "cl_turrets.qh"
#endif

#define IMPLEMENTATION
#include "all.inc"
#undef IMPLEMENTATION
