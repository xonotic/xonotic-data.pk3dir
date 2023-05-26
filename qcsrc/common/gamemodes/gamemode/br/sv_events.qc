#include "sv_events.qh"

bool drop_from_sky(entity this);

void spawn_supply()
{
    string item_class = RandomItems_GetRandomItemClassName("br_supply");
    entity this = Item_CreateLoot(item_class, '0 0 0', '0 0 0', 999999999);
    this.reset = SUB_Remove;

    if(!drop_from_sky(this))
    {
        delete(this);
        LOG_WARN("supply drop failed");
        return;
    }

    entity wi = REGISTRY_GET(Weapons, this.weapon);
    entity ii = this.itemdef;

    if (wi != WEP_Null)
    {
        entity wp = WaypointSprite_Spawn(WP_Weapon, autocvar_g_br_supply_interval, 0, this, '0 0 64', NULL, 0, this, waypointsprite_attached, true, RADARICON_Weapon);
        wp.wp_extra = wi.m_id;
    }
    else if (ii != NULL)
    {
        entity wp = WaypointSprite_Spawn(WP_Item, autocvar_g_br_supply_interval, 0, this, '0 0 64', NULL, 0, this, waypointsprite_attached, true, RADARICON_Item);
        wp.wp_extra = ii.m_id;
    }
    else
    {
        LOG_WARN("supply drop has no waypoint");
    }
}

void spawn_vehicle()
{
    entity this = spawn();
    this.br_vehicle_drop = true;
    if(!vehicle_initialize(this, VEH_SPIDERBOT, true)) { delete(this); return; }
    this.pos2.y = random() * 360;
    vehicles_spawn(this);
    this.reset = SUB_Remove;

    if(!drop_from_sky(this))
    {
        delete(this);
        LOG_WARN("vehicle drop failed");
        return;
    }

    entity wp = WaypointSprite_Spawn(WP_Vehicle, autocvar_g_br_vehicle_interval, 0, this, '0 0 64', NULL, 0, this, waypointsprite_attached, true, RADARICON_Vehicle);
    wp.wp_extra = this.vehicleid;
}

// TODO: ensure spawn is within ring
bool drop_from_sky(entity this)
{
    bool move_success = false;

    for(int i = 0; i < 100; ++i)
    {
        if(!MoveToRandomLocationWithinBounds(this, world.mins, world.maxs, DPCONTENTS_SOLID, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 100, 0, 0, false))
            continue;

        move_success = true;

        tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 65536', MOVE_NORMAL, this);
        if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY))
            continue;

        setorigin(this, trace_endpos);
        return true;
    }

    if(move_success)
        LOG_WARN("drop from sky not possible, spawning on floor");

    return move_success;
}
