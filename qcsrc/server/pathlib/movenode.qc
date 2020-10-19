#include "movenode.qh"

#include <common/mapobjects/triggers.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <server/pathlib/pathlib.qh>
#include <server/pathlib/utility.qh>

.vector	pos1, pos2;

vector pathlib_wateroutnode(entity this, vector start, vector end, float doedge)
{
    vector surface;

    pathlib_movenode_goodnode = false;

    end.x = fsnap(end.x, pathlib_gridsize);
    end.y = fsnap(end.y, pathlib_gridsize);

    traceline(end + ('0 0 0.25' * pathlib_gridsize),end - ('0 0 1' * pathlib_gridsize),MOVE_WORLDONLY,this);
    end = trace_endpos;

    if (!(pointcontents(end - '0 0 1') == CONTENT_SOLID))
        return end;

    for(surface = start ; surface.z < (end.z + 32); ++surface.z)
    {
        if(pointcontents(surface) == CONTENT_EMPTY)
            break;
    }

    if(pointcontents(surface + '0 0 1') != CONTENT_EMPTY)
        return end;

    tracebox(start + '0 0 64', movenode_boxmin,movenode_boxmax, end + '0 0 64', MOVE_WORLDONLY, this);
    if(trace_fraction == 1)
        pathlib_movenode_goodnode = true;

    if(fabs(surface.z - end.z) > 32)
        pathlib_movenode_goodnode = false;

    return end;
}

vector pathlib_swimnode(entity this, vector start, vector end, float doedge)
{
    pathlib_movenode_goodnode = false;

    if(pointcontents(start) != CONTENT_WATER)
        return end;

    end.x = fsnap(end.x, pathlib_gridsize);
    end.y = fsnap(end.y, pathlib_gridsize);

    if(pointcontents(end) == CONTENT_EMPTY)
        return pathlib_wateroutnode(this, start, end, doedge);

    tracebox(start, movenode_boxmin,movenode_boxmax, end, MOVE_WORLDONLY, this);
    if(trace_fraction == 1)
        pathlib_movenode_goodnode = true;

    return end;
}

vector pathlib_flynode(entity this, vector start, vector end, float doedge)
{
    pathlib_movenode_goodnode = false;

    end.x = fsnap(end.x, pathlib_gridsize);
    end.y = fsnap(end.y, pathlib_gridsize);

    tracebox(start, movenode_boxmin,movenode_boxmax, end, MOVE_WORLDONLY, this);
    if(trace_fraction == 1)
        pathlib_movenode_goodnode = true;

    return end;
}

void a_think(entity this)
{
    te_lightning1(this,this.origin, this.pos1);
    if(this.cnt < time)
        delete(this);
    else
        this.nextthink = time + 0.2;
}

vector pathlib_walknode(entity this, vector start, vector end, float doedge)
{
    vector point;

    LOG_DEBUG("Walking node from ", vtos(start), " to ", vtos(end));

    pathlib_movenode_goodnode = false;

    end.x = fsnap(end.x,pathlib_gridsize);
    end.y = fsnap(end.y,pathlib_gridsize);
    start.x = fsnap(start.x,pathlib_gridsize);
    start.y = fsnap(start.y,pathlib_gridsize);

    // Find the floor
    traceline(start + movenode_stepup, start - movenode_maxdrop, MOVE_WORLDONLY, this);
    if(trace_fraction == 1.0)
    {
        entity a;
        a = spawn();
        setthink(a, a_think);
        a.nextthink = time;
        setorigin(a, start + movenode_stepup);
        a.pos1 = trace_endpos;
        //start - movenode_maxdrop
        a.cnt = time + 10;

        LOG_TRACE("I cant walk on air!");
        return trace_endpos;
    }

    start = trace_endpos;

    // Find the direcion, without Z
    vector s   = start;
    vector e   = end;
    //e_z = 0; s_z = 0;
    vector direction = normalize(e - s);

    float distance  = vlen(start - end);
    int steps     = rint(distance / movenode_stepsize);

    vector last_point = start;
    for(int i = 1; i < steps; ++i)
    {
        point = last_point + (direction * movenode_stepsize);
        traceline(point + movenode_stepup,point - movenode_maxdrop,MOVE_WORLDONLY,this);
        if(trace_fraction == 1.0)
            return trace_endpos;

        last_point = trace_endpos;
    }

    point = last_point + (direction * movenode_stepsize);
    point.x = fsnap(point.x,pathlib_gridsize);
    point.y = fsnap(point.y,pathlib_gridsize);

    //dprint("end_x:  ",ftos(end_x),  "  end_y:  ",ftos(end_y),"\n");
    //dprint("point_x:",ftos(point_x),"  point_y:",ftos(point_y),"\n\n");

    traceline(point + movenode_stepup, point - movenode_maxdrop,MOVE_WORLDONLY,this);
    if(trace_fraction == 1.0)
        return trace_endpos;

    last_point = trace_endpos;

    tracebox(start + movenode_boxup, movenode_boxmin,movenode_boxmax, last_point + movenode_boxup, MOVE_WORLDONLY, this);
    if(trace_fraction != 1.0)
        return trace_endpos;

    pathlib_movenode_goodnode = true;
    return last_point;
}
