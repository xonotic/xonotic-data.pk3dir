#include "costs.qh"

float pathlib_g_static(entity parent,vector to, float static_cost)
{
    return parent.pathlib_node_g + static_cost;
}

float pathlib_g_static_water(entity parent,vector to, float static_cost)
{
    if(inwater(to))
        return parent.pathlib_node_g + static_cost * pathlib_movecost_waterfactor;
    else
        return parent.pathlib_node_g + static_cost;
}

float pathlib_g_euclidean(entity parent,vector to, float static_cost)
{
    return parent.pathlib_node_g + vlen(parent.origin - to);
}

float pathlib_g_euclidean_water(entity parent,vector to, float static_cost)
{
    if(inwater(to))
        return parent.pathlib_node_g + vlen(parent.origin - to) * pathlib_movecost_waterfactor;
    else
        return parent.pathlib_node_g + vlen(parent.origin - to);
}


/**
    Manhattan heuristic means we expect to move up, down left or right
    No diagonal moves expected. (like moving between city blocks)
**/
float pathlib_h_manhattan(vector a, vector b)
{
    //h(n) = D * (abs(n.x-goal.x) + abs(n.y-goal.y))

    float h  = fabs(a.x - b.x);
    h += fabs(a.y - b.y);
    h *= pathlib_gridsize;

    return h;
}

/**
    This heuristic consider both straight and diagonal moves
    to have the same cost.
**/
float pathlib_h_diagonal(vector a, vector b)
{
    //h(n) = D * max(abs(n.x-goal.x), abs(n.y-goal.y))

    float hx = fabs(a.x - b.x);
    float hy = fabs(a.y - b.y);
    float h = pathlib_movecost * max(hx, hy);

    return h;
}

/**
    This heuristic only considers the straight line distance.
    Usually means a lower H then G, resulting in A* spreading more
    (and running slower).
**/
float pathlib_h_euclidean(vector a, vector b)
{
    return vlen(a - b);
}

/**
    This heuristic consider both straight and diagonal moves,
    but has a separate cost for diagonal moves.
**/
float pathlib_h_diagonal2(vector a,vector b)
{
    /*
    h_diagonal(n) = min(abs(n.x-goal.x), abs(n.y-goal.y))
    h_straight(n) = (abs(n.x-goal.x) + abs(n.y-goal.y))
    h(n) = D2 * h_diagonal(n) + D * (h_straight(n) - 2*h_diagonal(n)))
    */

    float hx = fabs(a.x - b.x);
    float hy = fabs(a.y - b.y);

    float h_diag = min(hx,hy);
    float h_str = hx + hy;

    float h =  pathlib_movecost_diag * h_diag;
    h += pathlib_movecost * (h_str - 2 * h_diag);

    return h;
}

/**
    This heuristic consider both straight and diagonal moves,
    But has a separate cost for diagonal moves.
**/
float pathlib_h_diagonal2sdp(vector preprev, vector prev, vector point, vector end)
{
    //h_diagonal(n) = min(abs(n.x-goal.x), abs(n.y-goal.y))
    //h_straight(n) = (abs(n.x-goal.x) + abs(n.y-goal.y))
    //h(n) = D2 * h_diagonal(n) + D * (h_straight(n) - 2*h_diagonal(n)))

    float hx = fabs(point.x - end.x);
    float hy = fabs(point.y - end.y);
    float hz = fabs(point.z - end.z);

    float h_diag = min3(hx,hy,hz);
    float h_str = hx + hy + hz;

    float h =  pathlib_movecost_diag * h_diag;
    h += pathlib_movecost * (h_str - 2 * h_diag);

    vector d1 = normalize(preprev - point);
    vector d2 = normalize(prev    - point);
    float m = vlen(d1 - d2);

    return h * m;
}


float pathlib_h_diagonal3(vector a, vector b)
{
    float hx = fabs(a.x - b.x);
    float hy = fabs(a.y - b.y);
    float hz = fabs(a.z - b.z);

    float h_diag = min3(hx,hy,hz);
    float h_str = hx + hy + hz;

    float h =  pathlib_movecost_diag * h_diag;
    h += pathlib_movecost * (h_str - 2 * h_diag);

    return h;
}
