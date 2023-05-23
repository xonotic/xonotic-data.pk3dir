#include "sv_events.qh"

void drop_from_sky(entity this);

void spawn_supply()
{
    string item_class = RandomItems_GetRandomItemClassName("br_supply");
    entity this = Item_CreateLoot(item_class, '0 0 0', '0 0 0', 999999999);
    this.reset = SUB_Remove;

    drop_from_sky(this);
}

void spawn_vehicle()
{
    entity this = spawn();
    this.br_vehicle_drop = true;
    if(!vehicle_initialize(this, VEH_SPIDERBOT, true)) { delete(this); return; }
    this.pos2.y = random() * 360;
    vehicles_spawn(this);
    this.reset = SUB_Remove;

    drop_from_sky(this);
}

// TODO: ensure spawn is within ring
void drop_from_sky(entity this)
{
    for(int i = 0; i < 100; ++i)
    {
        MoveToRandomLocationWithinBounds(this, world.mins, world.maxs, DPCONTENTS_SOLID, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 0, 0, false);
        tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 65536', MOVE_NORMAL, this);
        if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY))
            continue;

        setorigin(this, trace_endpos);
        return;
    }

    LOG_WARN("drop from sky not possible, spawning on floor");
}
