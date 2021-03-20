#include "main.qh"

#include <common/stats.qh>
#include <common/turrets/util.qh>
#include <common/weapons/_all.qh>
#include <server/command/common.qh>
#include <server/pathlib/pathlib.qh>
#include <server/pathlib/utility.qh>

void pathlib_deletepath(entity start)
{
    if(!start)
        return;

    FOREACH_ENTITY_ENT(owner, start,
    {
        setthink(it, SUB_Remove);
        it.nextthink = time;
    });
}

const float PATHLIB_NODEEXPIRE = 20; // 0.05

void dumpnode(entity n)
{
    if(n.is_path_node)
        IL_REMOVE(g_pathlib_nodes, n);
    n.is_path_node = false;
    setthink(n, SUB_Remove);
    n.nextthink    = time;
}

#if DEBUGPATHING
#include "debug.qh"
#endif


entity pathlib_mknode(vector where,entity parent)
{
    entity node = pathlib_nodeatpoint(where);
    if(node)
    {
    	#ifdef TURRET_DEBUG
        mark_error(where, 60);
        #endif
        return node;
    }

    node = spawn();

    setthink(node, SUB_Remove);
    node.nextthink    = time + PATHLIB_NODEEXPIRE;
    IL_PUSH(g_pathlib_nodes, node);
    node.is_path_node = true;
    node.owner        = openlist;
    node.path_prev    = parent;

    setsize(node, '0 0 0', '0 0 0');

    setorigin(node, where);
#if DEBUGPATHING
    pathlib_showsquare(where, 1 ,15);
#endif
    ++pathlib_made_cnt;
    ++pathlib_open_cnt;

    return node;
}

bool pathlib_makenode_adaptive(entity parent,vector start, vector to, vector goal,float cost)
{
    bool dodge = false;
    float f, h, g;

    ++pathlib_searched_cnt;

    if(inwater(parent.origin))
    {
        LOG_DEBUG("FromWater");
        pathlib_expandnode = pathlib_expandnode_box;
        pathlib_movenode   = pathlib_swimnode;
    }
    else
    {
        if(inwater(to))
        {
            LOG_DEBUG("ToWater");
            pathlib_expandnode = pathlib_expandnode_box;
            pathlib_movenode   = pathlib_walknode;
        }
        else
        {
            LOG_DEBUG("LandToLoand");
            //if(edge_check(parent.origin))
            //    return 0;

            pathlib_expandnode = pathlib_expandnode_star;
            pathlib_movenode   = pathlib_walknode;
            dodge = true;
        }
    }

    entity node = pathlib_nodeatpoint(to);
    if(node)
    {
        LOG_DEBUG("NodeAtPoint");
        ++pathlib_merge_cnt;

        if(node.owner == openlist)
        {
            h = pathlib_heuristic(node.origin,goal);
            float g = pathlib_cost(parent,node.origin,cost);
            f = g + h;

            if(node.pathlib_node_g > g)
            {
                node.pathlib_node_h = h;
                node.pathlib_node_g = g;
                node.pathlib_node_f = f;

                node.path_prev = parent;
            }

            if (!best_open_node)
                best_open_node = node;
            else if(best_open_node.pathlib_node_f > node.pathlib_node_f)
                best_open_node = node;
        }

        return true;
    }

    vector where = pathlib_movenode(parent, parent.origin, to, 0);

    if (!pathlib_movenode_goodnode)
    {
        //pathlib_showsquare(where, 0 ,30);
        //pathlib_showsquare(parent.origin, 1 ,30);
        LOG_DEBUG("pathlib_movenode_goodnode = 0");
        return false;
    }

    //pathlib_showsquare(where, 1 ,30);

    if(pathlib_nodeatpoint(where))
    {
        LOG_DEBUG("NAP WHERE :",vtos(where));
        LOG_DEBUG("not NAP TO:",vtos(to));
        LOG_DEBUG("NAP-NNAP:",ftos(vlen(to-where)));
        return false;
    }


    if(dodge)
        if (!tile_check(parent, where))
        {
            LOG_DEBUG("tile_check fail");
#if DEBUGPATHING
            pathlib_showsquare(where, 0 ,30);
#endif
            return false;
        }


    h = pathlib_heuristic(where,goal);
    g = pathlib_cost(parent,where,cost);
    f = g + h;

    /*
    node = findradius(where,pathlib_gridsize * 0.5);
    while(node)
    {
        if(node.is_path_node == true)
        {
            ++pathlib_merge_cnt;
            if(node.owner == openlist)
            {
                if(node.pathlib_node_g > g)
                {
                    //pathlib_movenode(node, where,node.origin,0);
                    //if(pathlib_movenode_goodnode)
                    //{
                        //mark_error(node.origin + '0 0 128',30);
                        node.pathlib_node_h = h;
                        node.pathlib_node_g = g;
                        node.pathlib_node_f = f;
                        node.path_prev = parent;
                    //}
                }

                if (!best_open_node)
                    best_open_node = node;
                else if(best_open_node.pathlib_node_f > node.pathlib_node_f)
                    best_open_node = node;
            }

            return 1;
        }
        node = node.chain;
    }
    */

    node = pathlib_mknode(where, parent);
    node.pathlib_node_h = h;
    node.pathlib_node_g = g;
    node.pathlib_node_f = f;

    if (!best_open_node)
        best_open_node = node;
    else if(best_open_node.pathlib_node_f > node.pathlib_node_f)
        best_open_node = node;

    return true;
}

entity pathlib_getbestopen()
{
    if(best_open_node)
    {
        ++pathlib_bestcash_hits;
        pathlib_bestcash_saved += pathlib_open_cnt;

        return best_open_node;
    }

    entity bestnode = NULL;
    FOREACH_ENTITY_ENT(owner, openlist,
    {
        ++pathlib_bestopen_searched;

        if(!bestnode || it.pathlib_node_f < bestnode.pathlib_node_f)
            bestnode = it;
    });

    return bestnode;
}

void pathlib_close_node(entity node,vector goal)
{
    if(node.owner == closedlist)
    {
        LOG_TRACE("Pathlib: Tried to close a closed node!");
        return;
    }

    if(node == best_open_node)
        best_open_node = NULL;

    ++pathlib_closed_cnt;
    --pathlib_open_cnt;

    node.owner = closedlist;

    if(vdist(node.origin - goal, <=, pathlib_gridsize))
    {
        vector goalmove;

        goalmove = pathlib_walknode(node, node.origin, goal, 1);
        if(pathlib_movenode_goodnode)
        {
            goal_node         = node;
            pathlib_foundgoal = true;
        }
    }
}

void pathlib_cleanup()
{
    best_open_node = NULL;

    //return;

    IL_EACH(g_pathlib_nodes, it.is_path_node,
    {
    	dumpnode(it);
    });

    IL_CLEAR(g_pathlib_nodes);

    if(openlist)
        delete(openlist);

    if(closedlist)
        delete(closedlist);

    openlist = NULL;
    closedlist = NULL;
}

float Cosine_Interpolate(float a, float b, float c)
{
	float ft = c * M_PI;
	float f = (1 - cos(ft)) * 0.5;

	return a*(1-f) + b*f;
}

bool buildpath_nodefilter_directional(vector n,vector c,vector p)
{
    vector d2 = normalize(p - c);
    vector d1 = normalize(c - n);

    if(vdist(d1 - d2, <, 0.25))
    {
        //mark_error(c,30);
        return true;
    }
    //mark_info(c,30);
    return false;
}

bool buildpath_nodefilter_moveskip(entity this, vector n,vector c,vector p)
{
    pathlib_walknode(this, p, n, 1);
    if(pathlib_movenode_goodnode)
        return true;

    return false;
}

bool buildpath_nodefilter_none(vector n,vector c,vector p)
{
    return false;
}

entity path_build(entity next, vector where, entity prev, entity start)
{
    if(prev && next)
        if(buildpath_nodefilter)
            if(buildpath_nodefilter(next.origin,where,prev.origin))
                return next;


    entity path    = spawn();
    path.owner     = start;
    path.path_next = next;

    setorigin(path, where);

    if(!next)
        path.classname = "path_end";
    else
    {
        if(!prev)
            path.classname = "path_start";
        else
            path.classname = "path_node";
    }

    return path;
}

entity pathlib_astar(entity this, vector from, vector to)
{
	entity open;
    float ptime = gettime(GETTIME_REALTIME);
    pathlib_starttime = ptime;

    pathlib_cleanup();

    // Select water<->land capable node make/link
    pathlib_makenode     = pathlib_makenode_adaptive;

    // Select XYZ cost estimate
    //pathlib_heuristic    = pathlib_h_diagonal3;
    pathlib_heuristic    = pathlib_h_diagonal;

    // Select distance + waterfactor cost
    pathlib_cost         = pathlib_g_euclidean_water;

    // Select star expander
    pathlib_expandnode   = pathlib_expandnode_star;

    // Select walk simulation movement test
    pathlib_movenode     = pathlib_walknode;

    // Filter final nodes by direction
    buildpath_nodefilter = buildpath_nodefilter_directional;

    // Filter tiles with cross pattern
    tile_check = tile_check_cross;

    // If the start is in water we need diffrent settings
    if(inwater(from))
    {
        // Select volumetric node expaner
        pathlib_expandnode = pathlib_expandnode_box;

        // Water movement test
        pathlib_movenode   = pathlib_swimnode;
    }

    if (!openlist)
        openlist       = spawn();

    if (!closedlist)
        closedlist     = spawn();

    pathlib_closed_cnt       = 0;
    pathlib_open_cnt         = 0;
    pathlib_made_cnt         = 0;
    pathlib_merge_cnt        = 0;
    pathlib_searched_cnt     = 0;
    pathlib_bestopen_searched = 0;
    pathlib_bestcash_hits    = 0;
    pathlib_bestcash_saved   = 0;

    pathlib_gridsize       = 128;
    pathlib_movecost       = pathlib_gridsize;
    pathlib_movecost_diag  = vlen(('1 1 0' * pathlib_gridsize));
    pathlib_movecost_waterfactor = 25000000;
    pathlib_foundgoal      = 0;

    movenode_boxmax   = this.maxs * 1.1;
    movenode_boxmin   = this.mins * 1.1;

    movenode_stepsize = pathlib_gridsize * 0.25;

    tile_check_size = pathlib_gridsize * 0.5;
    tile_check_up   = '0 0 2' * pathlib_gridsize;
    tile_check_up   = '0 0 128';
    tile_check_down = '0 0 3' * pathlib_gridsize;
    tile_check_down = '0 0 256';

    //movenode_stepup   = '0 0 128';
    movenode_stepup   = '0 0 36';
    movenode_maxdrop  = '0 0 512';
    //movenode_maxdrop  = '0 0 512';
    movenode_boxup    = '0 0 72';

    from.x = fsnap(from.x, pathlib_gridsize);
    from.y = fsnap(from.y, pathlib_gridsize);
    //from.z += 32;

    to.x = fsnap(to.x, pathlib_gridsize);
    to.y = fsnap(to.y, pathlib_gridsize);
    //to.z += 32;

    LOG_DEBUG("AStar init");
    entity path = pathlib_mknode(from, NULL);
    pathlib_close_node(path, to);
    if(pathlib_foundgoal)
    {
        LOG_DEBUG("AStar: Goal found on first node!");

        open           = new(path_end);
        open.owner     = open;
        setorigin(open, path.origin);

        pathlib_cleanup();

        return open;
    }

    if(pathlib_expandnode(path, from, to) <= 0)
    {
        LOG_TRACE("AStar path fail.");
        pathlib_cleanup();

        return NULL;
    }

    best_open_node = pathlib_getbestopen();
    entity n = best_open_node;
    pathlib_close_node(best_open_node, to);
    if(inwater(n.origin))
        pathlib_expandnode_box(n, from, to);
    else
        pathlib_expandnode_star(n, from, to);

    while(pathlib_open_cnt)
    {
        if((gettime(GETTIME_REALTIME) - pathlib_starttime) > pathlib_maxtime)
        {
            LOG_TRACE("Path took too long to compute!");
            LOG_TRACE("Nodes - created: ", ftos(pathlib_made_cnt));
            LOG_TRACE("Nodes -    open: ", ftos(pathlib_open_cnt));
            LOG_TRACE("Nodes -  merged: ", ftos(pathlib_merge_cnt));
            LOG_TRACE("Nodes -  closed: ", ftos(pathlib_closed_cnt));

            pathlib_cleanup();
            return NULL;
        }

        best_open_node = pathlib_getbestopen();
        n = best_open_node;
        pathlib_close_node(best_open_node,to);

        if(inwater(n.origin))
            pathlib_expandnode_box(n,from,to);
        else
            pathlib_expandnode(n,from,to);

        if(pathlib_foundgoal)
        {
            LOG_DEBUG("Target found. Rebuilding and filtering path...");
            float ftime = gettime(GETTIME_REALTIME);
            ptime = ftime - ptime;

            entity start = path_build(NULL,path.origin,NULL,NULL);
            entity end   = path_build(NULL,goal_node.origin,NULL,start);
            entity ln    = end;

            open = goal_node;
            for(open = goal_node; open.path_prev != path; open = open.path_prev)
            {
                n    = path_build(ln,open.origin,open.path_prev,start);
                ln.path_prev = n;
                ln = n;
            }
            start.path_next = n;
            n.path_prev = start;
            ftime = gettime(GETTIME_REALTIME) - ftime;

            float ctime = gettime(GETTIME_REALTIME);
            pathlib_cleanup();
            ctime = gettime(GETTIME_REALTIME) - ctime;


#if DEBUGPATHING
            pathlib_showpath2(start);

            LOG_TRACE("Time used -      pathfinding: ", ftos(ptime));
            LOG_TRACE("Time used - rebuild & filter: ", ftos(ftime));
            LOG_TRACE("Time used -          cleanup: ", ftos(ctime));
            LOG_TRACE("Time used -            total: ", ftos(ptime + ftime + ctime));
            LOG_TRACE("Time used -         # frames: ", ftos(ceil((ptime + ftime + ctime) / sys_frametime)));
            LOG_TRACE("Nodes -         created: ", ftos(pathlib_made_cnt));
            LOG_TRACE("Nodes -            open: ", ftos(pathlib_open_cnt));
            LOG_TRACE("Nodes -          merged: ", ftos(pathlib_merge_cnt));
            LOG_TRACE("Nodes -          closed: ", ftos(pathlib_closed_cnt));
            LOG_TRACE("Nodes -        searched: ", ftos(pathlib_searched_cnt));
            LOG_TRACE("Nodes bestopen searched: ", ftos(pathlib_bestopen_searched));
            LOG_TRACE("Nodes bestcash -   hits: ", ftos(pathlib_bestcash_hits));
            LOG_TRACE("Nodes bestcash -   save: ", ftos(pathlib_bestcash_saved));
            LOG_TRACE("AStar done.");
#endif
            return start;
        }
    }

    LOG_TRACE("A* Faild to find a path! Try a smaller gridsize.");

    pathlib_cleanup();

    return NULL;
}
