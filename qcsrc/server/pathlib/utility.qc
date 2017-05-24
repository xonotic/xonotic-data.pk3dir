#include "utility.qh"

#include "pathlib.qh"

bool location_isok(vector point, bool waterok, bool air_isok)
{
    if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
        return false;

    int pc = pointcontents(point);
    int pc2 = pointcontents(point - '0 0 1');

    if(pc == CONTENT_EMPTY && pc2 == CONTENT_SOLID)
        return true;
    if(pc == CONTENT_EMPTY && pc2 == CONTENT_WATER && waterok)
        return true;
    if(pc == CONTENT_EMPTY && pc2 == CONTENT_EMPTY && air_isok)
        return true;
    if(pc == CONTENT_WATER && waterok)
        return true;
    return false;
}

entity pathlib_nodeatpoint(vector where)
{
    entity node;

    ++pathlib_searched_cnt;

    where.x = fsnap(where.x,pathlib_gridsize);
    where.y = fsnap(where.y,pathlib_gridsize);

    node = findradius(where,pathlib_gridsize * 0.5);
    while(node)
    {
        if(node.is_path_node == true)
            return node;

        node = node.chain;
    }

    return NULL;
}

float tile_check_cross(entity this, vector where)
{
    vector p,f,r;

    f = PLIB_FORWARD * tile_check_size;
    r = PLIB_RIGHT   * tile_check_size;


    // forward-right
    p = where + f + r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (!location_isok(trace_endpos, 1, 0))
        return 0;

    // Forward-left
    p = where + f - r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (!location_isok(trace_endpos, 1, 0))
        return 0;

    // Back-right
    p = where - f + r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (!location_isok(trace_endpos, 1 ,0))
        return 0;

    //Back-left
    p = where - f - r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (!location_isok(trace_endpos, 1, 0))
        return 0;

    return 1;
}

float tile_check_plus(entity this, vector where)
{
    vector p,f,r;

    f = PLIB_FORWARD * tile_check_size;
    r = PLIB_RIGHT   * tile_check_size;

    // forward
    p = where + f;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (!location_isok(trace_endpos,1,0))
        return 0;


    //left
    p = where - r;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (!location_isok(trace_endpos,1,0))
        return 0;

    // Right
    p = where + r;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (!location_isok(trace_endpos,1,0))
        return 0;

    //Back
    p = where - f;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (!location_isok(trace_endpos,1,0))
        return 0;

    return 1;
}

float tile_check_plus2(entity this, vector where)
{
    vector p,f,r;
    float i = 0, e = 0;

    f = PLIB_FORWARD * pathlib_gridsize;
    r = PLIB_RIGHT   * pathlib_gridsize;

//#define pathlib_node_edgeflag_left    2
//#define pathlib_node_edgeflag_right   4
//#define pathlib_node_edgeflag_forward 8
//#define pathlib_node_edgeflag_back    16

    // forward
    p = where + f;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (location_isok(trace_endpos,1,0))
    {
       ++i;
       e |= pathlib_node_edgeflag_forward;
    }


    //left
    p = where - r;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (location_isok(trace_endpos,1,0))
    {
       ++i;
       e |= pathlib_node_edgeflag_left;
    }


    // Right
    p = where + r;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (location_isok(trace_endpos,1,0))
    {
       ++i;
       e |= pathlib_node_edgeflag_right;
    }

    //Back
    p = where - f;
    traceline(p+tile_check_up,p-tile_check_down,MOVE_WORLDONLY,this);
    if (location_isok(trace_endpos,1,0))
    {
       ++i;
       e |= pathlib_node_edgeflag_back;
    }

    // forward-right
    p = where + f + r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (location_isok(trace_endpos, 1, 0))
    {
       ++i;
       e |= pathlib_node_edgeflag_forwardright;
    }

    // Forward-left
    p = where + f - r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (location_isok(trace_endpos, 1, 0))
    {
       ++i;
       e |= pathlib_node_edgeflag_forwardleft;
    }

    // Back-right
    p = where - f + r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (location_isok(trace_endpos, 1 ,0))
    {
       ++i;
       e |= pathlib_node_edgeflag_backright;
    }

    //Back-left
    p = where - f - r;
    traceline(p + tile_check_up, p - tile_check_down, MOVE_WORLDONLY, this);
    if (location_isok(trace_endpos, 1, 0))
    {
       ++i;
       e |= pathlib_node_edgeflag_backleft;
    }


    if(i == 0)
        e = pathlib_node_edgeflag_none;

    return e;
}

float tile_check_star(entity this, vector where)
{
    if(tile_check_plus(this, where))
        return tile_check_cross(this, where);

    return 0;
}

