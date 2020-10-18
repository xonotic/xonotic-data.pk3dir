#include "location.qh"
#ifdef SVQC
void target_push_init(entity this);

spawnfunc(target_location)
{
    // location name in netname
    // eventually support: count, teamgame selectors, line of sight?

    target_push_init(this);

    IL_PUSH(g_locations, this);
}

spawnfunc(info_location)
{
    this.message = this.netname;
    spawnfunc_target_location(this);
}
#endif
