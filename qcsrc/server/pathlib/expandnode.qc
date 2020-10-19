#include "expandnode.qh"

#include <server/pathlib/pathlib.qh>
#include <server/pathlib/utility.qh>

/*
vector plib_points2[8];
vector plib_points[8];
float  plib_fvals[8];

float pathlib_expandnode_starf(entity node, vector start, vector goal)
{
    float fc;

    vector where = node.origin;

    vector f = PLIB_FORWARD * pathlib_gridsize;
    vector r = PLIB_RIGHT   * pathlib_gridsize;

    // Forward
    plib_points[0] = where + f;

    // Back
    plib_points[1] = where - f;

    // Right
    plib_points[2] = where + r;

    // Left
    plib_points[3] = where - r;

    // Forward-right
    plib_points[4] = where + f + r;

    // Forward-left
    plib_points[5] = where + f - r;

    // Back-right
    plib_points[6] = where - f + r;

    // Back-left
    plib_points[7] = where - f - r;

    for(int i=0;i < 8; ++i)
    {
        vector t = plib_points[i];
        fc  = pathlib_heuristic(t,goal) + pathlib_cost(node, t, pathlib_gridsize);
        plib_fvals[i] = fc;

    }

    fc = plib_fvals[0];
    plib_points2[0] = plib_points[0];
    vector bp;
    bp = plib_points[0];
    int fc2 = 0;
    for(int i = 0; i < 8; ++i)
    {
        bool c = false;
        entity nap = pathlib_nodeatpoint(plib_points[i]);
        if(nap)
        {
            if(nap.owner == openlist)
                c = true;
        }
        else
            c = true;

        if(c)
        if(plib_fvals[i] < fc)
        {
            bp = plib_points[i];
            fc = plib_fvals[i];
            plib_points2[fc2] = plib_points[i];
            ++fc2;
        }

        //nap = pathlib_nodeatpoint(plib_points[i]);
        //if(nap)
        //if not nap.owner == closedlist)
        //{
        //}
    }

    pathlib_makenode(node, start, bp, goal, pathlib_gridsize);

    for(int i = 0; i < 3; ++i)
    {
        pathlib_makenode(node, start, plib_points2[i], goal, pathlib_gridsize);
    }

    return pathlib_open_cnt;
}
*/

float pathlib_expandnode_star(entity node, vector start, vector goal)
{
    vector point;

    vector where = node.origin;

    vector f = PLIB_FORWARD * pathlib_gridsize;
    vector r = PLIB_RIGHT   * pathlib_gridsize;

    if (node.pathlib_node_edgeflags == pathlib_node_edgeflag_unknown)
        node.pathlib_node_edgeflags = tile_check_plus2(node, node.origin);

    if(node.pathlib_node_edgeflags == pathlib_node_edgeflag_none)
    {
        LOG_TRACE("Node at ", vtos(node.origin), " not expanable");
        return pathlib_open_cnt;
    }

    // Forward
    if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_forward)
    {
        point = where + f;
        pathlib_makenode(node, start, point, goal, pathlib_movecost);
    }

    // Back
    if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_back)
    {
        point = where - f;
        pathlib_makenode(node, start, point, goal, pathlib_movecost);
    }

    // Right
        if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_right)
    {
        point = where + r;
        pathlib_makenode(node, start, point, goal, pathlib_movecost);
    }

    // Left
    if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_left)
    {
        point = where - r;
        pathlib_makenode(node, start, point, goal, pathlib_movecost);

    }

    // Forward-right
    if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_forwardright)
    {
        point = where + f + r;
        pathlib_makenode(node, start, point, goal, pathlib_movecost_diag);
    }

    // Forward-left
    if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_forwardleft)
    {
        point = where + f - r;
        pathlib_makenode(node, start, point, goal, pathlib_movecost_diag);

    }

    // Back-right
    if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_backright)
    {
        point = where - f + r;
        pathlib_makenode(node, start, point, goal, pathlib_movecost_diag);
    }

    // Back-left
    if (node.pathlib_node_edgeflags & pathlib_node_edgeflag_backleft)
    {
        point = where - f - r;
        pathlib_makenode(node, start, point, goal, pathlib_movecost_diag);
    }

    return pathlib_open_cnt;
}

/*
float pathlib_expandnode_octagon(entity node, vector start, vector goal)
{
    vector point;

    vector where = node.origin;

    vector f = PLIB_FORWARD * pathlib_gridsize;
    vector r = PLIB_RIGHT   * pathlib_gridsize;

    // Forward
    point = where + f;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    // Back
    point = where - f;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    // Right
    point = where + r;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    // Left
    point = where - r;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    f = PLIB_FORWARD * pathlib_gridsize * 0.5;
    r = PLIB_RIGHT   * pathlib_gridsize * 0.5;

    // Forward-right
    point = where + f + r;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    // Forward-left
    point = where + f - r;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    // Back-right
    point = where - f + r;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    // Back-left
    point = where - f - r;
    pathlib_makenode(node, start, point, goal, pathlib_movecost);

    return pathlib_open_cnt;
}
*/

float pathlib_expandnode_box(entity node, vector start, vector goal)
{
    vector v;

    for(v.z = node.origin.z - pathlib_gridsize; v.z <= node.origin.z + pathlib_gridsize; v.z += pathlib_gridsize)
    for(v.y = node.origin.y - pathlib_gridsize; v.y <= node.origin.y + pathlib_gridsize; v.y += pathlib_gridsize)
    for(v.x = node.origin.x - pathlib_gridsize; v.x <= node.origin.x + pathlib_gridsize; v.x += pathlib_gridsize)
    {
        //if(vlen(v - node.origin))
            pathlib_makenode(node,start,v,goal,pathlib_movecost);
    }

    return pathlib_open_cnt;
}
