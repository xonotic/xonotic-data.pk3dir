#include "sv_events.qh"

void spawn_supply()
{
    string item_class = RandomItems_GetRandomItemClassName("br_supply");
    entity this = Item_Create(item_class, '0 0 0', false);

    MoveToRandomLocationWithinBounds(this, world.mins, world.maxs, DPCONTENTS_SOLID, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 2500, 0, 0, false);
    tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 65536', MOVE_NORMAL, this);
    setorigin(this, trace_endpos);
}
