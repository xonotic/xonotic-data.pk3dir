.entity list;

entity pathlib_wpp_goal;
entity pathlib_wpp_start;

void pathlib_wpp_close(entity wp)
{
    --pathlib_open_cnt;
    ++pathlib_closed_cnt;

    wp.list = closedlist;
    wp.colormod = '0 1 1';

    if(wp == best_open_node)
        best_open_node = world;

    if(wp == pathlib_wpp_goal)
        pathlib_foundgoal = TRUE;
}

float pathlib_wpp_open(entity wp, entity child, float cost)
{
    float g, h, f;

    if(child.list == closedlist)
        return FALSE;

    g = wp.pathlib_node_g + vlen(child.origin - wp.origin); //cost;
    h = vlen(child.origin - pathlib_wpp_goal.origin);
    f = g + h;


    child.colormod = '1 0 1';
    child.path_prev = wp;
    child.list = openlist;
    child.pathlib_node_g = g;
    child.pathlib_node_h = h;
    child.pathlib_node_f = f;

    ++pathlib_open_cnt;

    if(best_open_node.pathlib_node_f > f)
        best_open_node = child;

    return TRUE;
}

float pathlib_wpp_expand(entity wp)
{

    if(wp.wp00) pathlib_wpp_open(wp,wp.wp00,wp.wp00mincost); else return 0;
    if(wp.wp01) pathlib_wpp_open(wp,wp.wp01,wp.wp01mincost); else return 1;
    if(wp.wp02) pathlib_wpp_open(wp,wp.wp02,wp.wp02mincost); else return 2;
    if(wp.wp03) pathlib_wpp_open(wp,wp.wp03,wp.wp03mincost); else return 3;
    if(wp.wp04) pathlib_wpp_open(wp,wp.wp04,wp.wp04mincost); else return 4;
    if(wp.wp05) pathlib_wpp_open(wp,wp.wp05,wp.wp05mincost); else return 5;
    if(wp.wp06) pathlib_wpp_open(wp,wp.wp06,wp.wp06mincost); else return 6;
    if(wp.wp07) pathlib_wpp_open(wp,wp.wp07,wp.wp07mincost); else return 7;
    if(wp.wp08) pathlib_wpp_open(wp,wp.wp08,wp.wp08mincost); else return 8;
    if(wp.wp09) pathlib_wpp_open(wp,wp.wp09,wp.wp09mincost); else return 9;
    if(wp.wp10) pathlib_wpp_open(wp,wp.wp10,wp.wp10mincost); else return 10;
    if(wp.wp11) pathlib_wpp_open(wp,wp.wp11,wp.wp11mincost); else return 11;
    if(wp.wp12) pathlib_wpp_open(wp,wp.wp12,wp.wp12mincost); else return 12;
    if(wp.wp13) pathlib_wpp_open(wp,wp.wp13,wp.wp13mincost); else return 13;
    if(wp.wp14) pathlib_wpp_open(wp,wp.wp14,wp.wp14mincost); else return 14;
    if(wp.wp15) pathlib_wpp_open(wp,wp.wp15,wp.wp15mincost); else return 15;
    if(wp.wp16) pathlib_wpp_open(wp,wp.wp16,wp.wp16mincost); else return 16;
    if(wp.wp17) pathlib_wpp_open(wp,wp.wp17,wp.wp17mincost); else return 17;
    if(wp.wp18) pathlib_wpp_open(wp,wp.wp18,wp.wp18mincost); else return 18;
    if(wp.wp19) pathlib_wpp_open(wp,wp.wp19,wp.wp19mincost); else return 19;
    if(wp.wp20) pathlib_wpp_open(wp,wp.wp20,wp.wp20mincost); else return 20;
    if(wp.wp21) pathlib_wpp_open(wp,wp.wp21,wp.wp21mincost); else return 21;
    if(wp.wp22) pathlib_wpp_open(wp,wp.wp22,wp.wp22mincost); else return 22;
    if(wp.wp23) pathlib_wpp_open(wp,wp.wp23,wp.wp23mincost); else return 23;
    if(wp.wp24) pathlib_wpp_open(wp,wp.wp24,wp.wp24mincost); else return 24;
    if(wp.wp25) pathlib_wpp_open(wp,wp.wp25,wp.wp25mincost); else return 25;
    if(wp.wp26) pathlib_wpp_open(wp,wp.wp26,wp.wp26mincost); else return 26;
    if(wp.wp27) pathlib_wpp_open(wp,wp.wp27,wp.wp27mincost); else return 27;
    if(wp.wp28) pathlib_wpp_open(wp,wp.wp28,wp.wp28mincost); else return 28;
    if(wp.wp29) pathlib_wpp_open(wp,wp.wp29,wp.wp29mincost); else return 29;
    if(wp.wp30) pathlib_wpp_open(wp,wp.wp30,wp.wp30mincost); else return 30;
    if(wp.wp31) pathlib_wpp_open(wp,wp.wp31,wp.wp31mincost); else return 31;

}

entity pathlib_wpp_bestopen()
{
    entity n, best;

    if(best_open_node)
        return best_open_node;

    n = findchainentity(list, openlist);
    /*
    if not(n)
    {
        dprint("pathlib_waypointpath: No more open nodes, path fail.\n");
        return world;
    }
    */

    best = n;
    while(n)
    {
        if(n.pathlib_node_f < best.pathlib_node_f)
            best = n;

        n = n.chain;
    }

    return best;

}

entity pathlib_waypointpath(entity from, entity to)
{
    entity n;
    float ptime;


    ptime = gettime(GETTIME_REALTIME);
    pathlib_starttime = ptime;

    if not(openlist)
        openlist       = spawn();

    if not(closedlist)
        closedlist     = spawn();

    pathlib_closed_cnt       = 0;
    pathlib_open_cnt         = 0;
    pathlib_searched_cnt     = 0;

    pathlib_foundgoal      = FALSE;


    dprint("pathlib_waypointpath init\n");

    // Initialize waypoint grid
    n = findchainentity(owner, waypoint_master);
    while (n)
    {
        n.list = world;
        n.pathlib_node_g = 0;
        n.pathlib_node_f = 0;
        n.pathlib_node_h = 0;

        setmodel(n, "models/runematch/rune.mdl");
        n.effects = EF_LOWPRECISION;
        n.colormod = '0 0 0';
        n.scale = 1;

        n = n.chain;
    }

    pathlib_wpp_goal  = to;
    pathlib_wpp_start = from;

    from.list = closedlist;
    bprint("Expanding ",ftos(pathlib_wpp_expand(from))," links\n");
    if(pathlib_open_cnt <= 0)
    {
        dprint("pathlib_waypointpath: Start waypoint not linked! aborting.\n");
        return world;
    }

    return world;
}

entity pathlib_waypointpath_step()
{
    entity n;


    /*
    if((gettime(GETTIME_REALTIME) - pathlib_starttime) > pathlib_maxtime)
    {
        dprint("pathlib_waypointpath: Path took to long to compute!\n");
        return world;
    }
    */

    n = pathlib_wpp_bestopen();
    if(!n)
    {
        bprint("Cannot find best open node, abort.\n");
        return world;
    }
    pathlib_wpp_close(n);

    if(pathlib_foundgoal)
    {
        bprint("Target found. Rebuilding and filtering path...\n");
        // to-do rebuild (follow path_prev from n untill it hits from) and return path.

        n = pathlib_wpp_goal;
        while(n != pathlib_wpp_start)
        {
            n.scale = 3;
            n = n.path_prev;
        }
        pathlib_wpp_start.colormod = '0 0 1';
        pathlib_wpp_goal.colormod = '1 0 0';

        return n;
    }

    bprint("Expanding ",ftos(pathlib_wpp_expand(n))," links\n");


    return world;
}

void plas_think()
{
    pathlib_waypointpath_step();
    if(pathlib_foundgoal)
        return;
    self.nextthink = time + 0.1;
}

void pathlib_waypointpath_autostep()
{
    entity n;
    n = spawn();
    n.think = plas_think;
    n.nextthink = time + 0.1;
}

/*
entity pathlib_wpp_goal;
entity pathlib_wpp_start;
entity pathlib_waypointpath(entity from, entity to)
{
    entity path, start, end, open, n, ln;
    float ptime, ftime, ctime;


    ptime = gettime(GETTIME_REALTIME);
    pathlib_starttime = ptime;

    if not(openlist)
        openlist       = spawn();

    if not(closedlist)
        closedlist     = spawn();

    pathlib_closed_cnt       = 0;
    pathlib_open_cnt         = 0;
    pathlib_searched_cnt     = 0;

    pathlib_foundgoal      = FALSE;


    dprint("pathlib_waypointpath init\n");

    // Initialize waypoint grid
    n = findchainentity(owner, waypoint_master);
    while (n)
    {
        n.list = world;
        n.pathlib_node_g = 0;
        n.pathlib_node_f = 0;
        n.pathlib_node_h = 0;
        setmodel(n, "models/runematch/rune.mdl");
        n.effects = EF_LOWPRECISION;
        n.colormod = '1 1 1';
        n.scale = 1;
    }

    pathlib_wpp_goal = to;
    pathlib_wpp_start = from;

    from.list = closedlist;
    pathlib_wpp_expand(from);
    if(pathlib_open_cnt <= 0)
    {
        dprint("pathlib_waypointpath: Start waypoint not linked! aborting.\n");
        return world;
    }

    while(pathlib_open_cnt)
    {
        if((gettime(GETTIME_REALTIME) - pathlib_starttime) > pathlib_maxtime)
        {
            dprint("pathlib_waypointpath: Path took to long to compute!\n");
            return world;
        }

        n = findentity(world, list, openlist);
        if not(n)
        {
            dprint("pathlib_waypointpath: No more open nodes, path fail.\n");
            return world;
        }

        pathlib_wpp_close(n);
        pathlib_wpp_expand(n);

        if(pathlib_foundgoal)
        {
            dprint("Target found. Rebuilding and filtering path...\n");
            // to-do rebuild (follow path_prev from n untill it hits from) and return path.
            n = to;
            do
            {
                n.scale = 3;
                n = n.path_prev;
            }while(n != from);

            return world;
        }
    }

    return world;
}
*/
