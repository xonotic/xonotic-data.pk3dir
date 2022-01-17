#include "sv_dropship.qh"

float autocvar_g_br_dropship_scale = 3;
vector autocvar_g_br_dropship_color = '0.5 0 0.5';

entity dropship_spawn(Vehicle info, float entity_scale, vector color);
void dropship_think(entity this);
vector dropship_getMultipliers();
vector dropship_seekPoint(entity this, vector orig, int axis, int direction, float multiplier);

entity dropship_initialize()
{
    entity this = dropship_spawn(VEH_RACER, autocvar_g_br_dropship_scale, autocvar_g_br_dropship_color);

    bool moveSucceeded = MoveToRandomLocationWithinBounds(this, world.mins, world.maxs, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 2500, 8192, 1024);
    if(!moveSucceeded)
    {
        delete(this);
        return NULL;
    }

    vector mult;

    vector startorigin;
    startorigin = dropship_seekPoint(this, this.origin, 2, 2, 1);
    startorigin = dropship_seekPoint(this, startorigin, 0, 0, 1);
    startorigin = dropship_seekPoint(this, startorigin, 1, 0, 1);
    mult = dropship_getMultipliers();
    startorigin = dropship_seekPoint(this, startorigin, 0, 1, mult.x);
    startorigin = dropship_seekPoint(this, startorigin, 1, 1, mult.y);

    vector endorigin;
    mult = dropship_getMultipliers();
    endorigin = dropship_seekPoint(this, startorigin, 0, 1, 1 - mult.x);
    endorigin = dropship_seekPoint(this, endorigin,   1, 1, 1 - mult.y);

    endorigin = startorigin + normalize(endorigin - startorigin) * vlen(world.maxs - world.mins);

    tracebox(startorigin, this.mins, this.maxs, endorigin, MOVE_NORMAL, this);
    dropship_path_length = trace_fraction * vlen(endorigin - startorigin);
    endorigin = trace_endpos;
    dropship_path_direction = normalize(endorigin - startorigin);

    setorigin(this, startorigin);
    this.angles = vectoangles(dropship_path_direction);
    this.velocity = '0 0 0';

    return this;
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
        this.velocity = dropship_path_direction * autocvar_g_br_dropship_speed;
        dropship_path_length -= autocvar_g_br_dropship_speed * frametime;
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
    first_end = first_end - first_end * vec_axis * vec_axis + world.maxs * vec_axis * vec_axis;
    first_fraction = (tracebox(orig, this.mins, this.maxs, first_end, MOVE_NORMAL, this), trace_fraction);

    if(direction != 2)
    {
        second_end = orig;
        second_end = second_end - second_end * vec_axis * vec_axis + world.mins * vec_axis * vec_axis;
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
