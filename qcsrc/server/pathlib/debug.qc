#include "debug.qh"

#if DEBUGPATHING

MODEL(SQUARE,       "models/pathlib/square.md3");
MODEL(SQUARE_GOOD,  "models/pathlib/goodsquare.md3");
MODEL(SQUARE_BAD,   "models/pathlib/badsquare.md3");
MODEL(EDGE,         "models/pathlib/edge.md3");

#ifdef TURRET_DEBUG
#include <common/turrets/util.qh>
#endif

void pathlib_showpath(entity start)
{
    entity e;
    e = start;
    while(e.path_next)
    {
        te_lightning1(e,e.origin,e.path_next.origin);
        e = e.path_next;
    }
}

void path_dbg_think(entity this)
{
    pathlib_showpath(this);
    this.nextthink = time + 1;
}

void __showpath2_think(entity this)
{
    #ifdef TURRET_DEBUG
	mark_info(this.origin,1);
	#endif
    if(this.path_next)
    {
        setthink(this.path_next, __showpath2_think);
        this.path_next.nextthink = time + 0.15;
    }
    else
    {
        setthink(this.owner, __showpath2_think);
        this.owner.nextthink = time + 0.15;
    }
}

void pathlib_showpath2(entity path)
{
    setthink(path, __showpath2_think);
    path.nextthink = time;
}

void pathlib_showsquare2(entity node ,vector ncolor,float align)
{

    node.alpha     = 0.25;
    node.scale     = pathlib_gridsize / 512.001;
    node.solid     = SOLID_NOT;

    setmodel(node, MDL_SQUARE);
    setorigin(node, node.origin);
    node.colormod = ncolor;

    if(align)
    {
        traceline(node.origin + '0 0 32', node.origin - '0 0 128', MOVE_WORLDONLY, node);
        node.angles = vectoangles(trace_plane_normal);
        node.angles_x -= 90;
    }
}

void pathlib_showsquare(vector where,float goodsquare,float _lifetime)
{
    entity s;

    if(!_lifetime)
        _lifetime = time + 30;
    else
        _lifetime += time;

    s           = spawn();
    s.alpha     = 0.25;
    setthink(s, SUB_Remove);
    s.nextthink = _lifetime;
    s.scale     = pathlib_gridsize / 512.001;
    s.solid     = SOLID_NOT;

    setmodel(s, goodsquare ? MDL_SQUARE_GOOD : MDL_SQUARE_BAD);

    traceline(where + '0 0 32',where - '0 0 128',MOVE_WORLDONLY,s);

    s.angles = vectoangles(trace_plane_normal);
    s.angles_x -= 90;
    setorigin(s, where);
}

void pathlib_showedge(vector where,float _lifetime,float rot)
{
    entity e;

    if(!_lifetime)
        _lifetime = time + 30;
    else
        _lifetime += time;

    e           = spawn();
    e.alpha     = 0.25;
    setthink(e, SUB_Remove);
    e.nextthink = _lifetime;
    e.scale     = pathlib_gridsize / 512;
    e.solid     = SOLID_NOT;
    setorigin(e, where);
    setmodel(e, MDL_EDGE);
    //traceline(where + '0 0 32',where - '0 0 128',MOVE_WORLDONLY,e);
    //e.angles = vectoangles(trace_plane_normal);
    e.angles_y = rot;
    //e.angles_x += 90;

}

#endif
