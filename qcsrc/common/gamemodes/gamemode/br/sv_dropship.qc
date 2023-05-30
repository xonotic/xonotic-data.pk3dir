#include "sv_dropship.qh"

float autocvar_g_br_dropship_scale = 3;
vector autocvar_g_br_dropship_color = '0.5 0 0.5';
float autocvar_g_br_dropship_speed = -1;

entity dropship_spawn(Vehicle info, float entity_scale, vector color);
void dropship_think(entity this);
vector dropship_getMultipliers();
vector dropship_seekPoint(entity this, vector orig, int axis, int direction, float multiplier);

entity dropship_initialize()
{
    entity this = dropship_spawn(VEH_RACER, autocvar_g_br_dropship_scale, autocvar_g_br_dropship_color);

    vector pl_mins = '0 0 0';
    vector pl_maxs = '0 0 0';

    FOREACH_CLIENT(IS_PLAYER(it),
    {
        pl_mins = STAT(PL_MIN, it);
        pl_maxs = STAT(PL_MAX, it);
        break;
    });

    vector path_mins;
    vector path_maxs;

    path_mins.x = min(pl_mins.x, this.mins.x);
    path_maxs.x = max(pl_maxs.x, this.maxs.x);

    path_mins.y = min(pl_mins.y, this.mins.y);
    path_maxs.y = max(pl_maxs.y, this.maxs.y);

    float z_ofs = this.mins.z - pl_maxs.z - 64;
    path_mins.z = min(pl_mins.z + z_ofs, this.mins.z);
    path_maxs.z = max(pl_maxs.z + z_ofs, this.maxs.z);

    vector saved_mins = this.mins;
    vector saved_maxs = this.maxs;
    setsize(this, path_mins, path_maxs);

    for(int i = 0; i < 100; ++i) // try to find a dropship path multiple times
    {
        if(!MoveToRandomLocationWithinBounds(this, world.mins, world.maxs, this.dphitcontentsmask, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 100, 65536, 0, false))
            continue;

        vector mult;

        vector startorigin = this.origin;
        do {
            startorigin = dropship_seekPoint(this, startorigin, 2, 2, 1);
            startorigin = dropship_seekPoint(this, startorigin, 0, 0, 1);
            startorigin = dropship_seekPoint(this, startorigin, 1, 0, 1);
        } while((tracebox(startorigin, this.mins, this.maxs, startorigin + '0 0 1', MOVE_NORMAL, this), trace_fraction) >= 1);

        if(!(trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOIMPACT | Q3SURFACEFLAG_NOMARKS))) // dropship did not reach the sky
            continue;

        mult = dropship_getMultipliers();
        startorigin = dropship_seekPoint(this, startorigin, 0, 1, mult.x);
        startorigin = dropship_seekPoint(this, startorigin, 1, 1, mult.y);

        vector endorigin;
        mult = dropship_getMultipliers();
        endorigin = dropship_seekPoint(this, startorigin, 0, 1, 1 - mult.x);
        endorigin = dropship_seekPoint(this, endorigin,   1, 1, 1 - mult.y);

        endorigin = startorigin + normalize(endorigin - startorigin) * 65536;

        tracebox(startorigin, this.mins, this.maxs, endorigin, MOVE_NORMAL, this);
        dropship_path_length = trace_fraction * vlen(endorigin - startorigin);
        if(dropship_path_length < (vlen(vec2(world.maxs - world.mins)) / 4)) // if the dropship path isn't atleast one quarter of the diagonal length of the map, retry, we're probably in a building
            continue;
        endorigin = trace_endpos;
        dropship_path_direction = normalize(endorigin - startorigin);

        setsize(this, saved_mins, saved_maxs);

        setorigin(this, startorigin);
        this.angles = vectoangles(dropship_path_direction);
        this.velocity = '0 0 0';

        dropship_speed = autocvar_g_br_dropship_speed;
        // if dropship_speed is negative adjust speed dependant on map size
        if(dropship_speed < 0)
            dropship_speed = vlen(vec2(world.maxs - world.mins)) / 60; // dropship needs one minute to diagonally fly over the whole map

        return this;
    }

    delete(this);
    return NULL;
}

entity dropship_spawn(Vehicle info, float entity_scale, vector color)
{
    entity this = new(vehicle);
    this.active = ACTIVE_ACTIVE;

    _setmodel(this, info.model);

    this.vehicle_flags |= VHF_ISVEHICLE;

    this.takedamage             = DAMAGE_NO;
    this.bot_attack             = false;
    this.iscreature             = true;
    this.teleportable           = false;
    this.damagedbycontents      = false;
    this.vehicleid              = info.vehicleid;
    this.vehicledef             = info;
    this.dphitcontentsmask      = DPCONTENTS_SOLID;
    if(autocvar_g_playerclip_collisions)
        this.dphitcontentsmask |= DPCONTENTS_PLAYERCLIP;
    this.flags                  = FL_NOTARGET;
    this.nextthink              = time;
    setthink(this, dropship_think);

    this.scale = entity_scale;
    setsize(this, info.m_mins * entity_scale, info.m_maxs * entity_scale);
    set_movetype(this, MOVETYPE_FLY_WORLDONLY);

    this.colormod = color;
    this.alpha = 1;

    CSQCMODEL_AUTOINIT(this);

    return this;
}

void dropship_think(entity this)
{
    this.nextthink = time;

    if(dropship_path_length > 0){
        this.alpha = bound(0.01, dropship_path_length / autocvar_g_br_drop_distance_force, 1);
        this.velocity = dropship_path_direction * dropship_speed;
        dropship_path_length -= dropship_speed * frametime;
    }
    else{
        delete(this);
    }

    CSQCMODEL_AUTOUPDATE(this);
}

vector dropship_getMultipliers()
{
    vector mult;
    mult.x = (1 - cos(random() * 90 * DEG2RAD)) * 0.5;
    mult.y = min((1 - cos(random() * 90 * DEG2RAD)) * 0.5, 0.5 - mult.x);
    mult.z = 0;
    bool multswap = (random() >= 0.5);
    if(multswap){
        float tmp;
        tmp = mult.x;
        mult.x = mult.y;
        mult.y = tmp;
    }

    return mult;
}

vector dropship_seekPoint(entity this, vector orig, int axis, int direction, float multiplier)
{
    vector vec_axis;
    switch(axis)
    {
        default: case 0:
            vec_axis = eX;
            break;
        case 1:
            vec_axis = eY;
            break;
        case 2:
            vec_axis = eZ;
    }

    float first_fraction;
    float second_fraction = 0;
    vector first_end;
    vector second_end = '0 0 0';

    first_end = orig;
    first_end = first_end - first_end * vec_axis * vec_axis + 65536 * vec_axis;
    first_fraction = (tracebox(orig, this.mins, this.maxs, first_end, MOVE_NORMAL, this), trace_fraction);

    if(direction != 2)
    {
        second_end = orig;
        second_end = second_end - second_end * vec_axis * vec_axis + -65536 * vec_axis;
        second_fraction = (tracebox(orig, this.mins, this.maxs, second_end, MOVE_NORMAL, this), trace_fraction);
    }

    float dist_to_edge;
    if(((direction == 0) && (first_fraction < second_fraction)) ||
       ((direction == 1) && (first_fraction > second_fraction)) ||
        (direction == 2))
    {
        dist_to_edge = (first_end * vec_axis - orig * vec_axis) * first_fraction * multiplier;
    }
    else
    {
        dist_to_edge = (second_end * vec_axis - orig * vec_axis) * second_fraction * multiplier;
    }
    orig = orig + dist_to_edge * vec_axis;

    return orig;
}
