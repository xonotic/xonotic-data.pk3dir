#include "location.qh"
#ifdef SVQC
void target_push_init(entity this);

spawnfunc(target_location)
{
    this.classname = "target_location";
    // location name in netname
    // eventually support: count, teamgame selectors, line of sight?

    target_push_init(this);
}

spawnfunc(info_location)
{
    this.classname = "target_location";
    this.message = this.netname;

    target_push_init(this);
}
#endif
