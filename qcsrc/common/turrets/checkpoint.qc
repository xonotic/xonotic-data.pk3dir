#include "checkpoint.qh"
/**
    turret_checkpoint
**/


//.entity checkpoint_target;

/*
#define checkpoint_cache_who  flagcarried
#define checkpoint_cache_from lastrocket
#define checkpoint_cache_to   selected_player
*/

.entity pathgoal;

/*
entity path_makeorcache(entity forwho,entity start, entity end)
{
    entity pth;

    //pth = pathlib_makepath(forwho, start.origin,end.origin,PFL_GROUNDSNAP,500,1.5,PT_QUICKSTAR);

    return pth;
}
*/

void turret_checkpoint_use()
{
}

#if 0
void turret_checkpoint_think(entity this)
{
    if(this.enemy)
        te_lightning1(this,this.origin, this.enemy.origin);

    this.nextthink = time + 0.25;
}
#endif
/*QUAKED turret_checkpoint (1 0 1) (-32 -32 -32) (32 32 32)
-----------KEYS------------
target: .targetname of next waypoint in chain.
wait:   Pause at this point # seconds.
-----------SPAWNFLAGS-----------
---------NOTES----------
If a loop is of targets are formed, any unit entering this loop will patrol it indefinitly.
If the checkpoint chain in not looped, the unit will go "Roaming" when the last point is reached.
*/
//float tc_acum;
void turret_checkpoint_init(entity this)
{
    traceline(this.origin + '0 0 16', this.origin - '0 0 1024', MOVE_WORLDONLY, this);
    setorigin(this, trace_endpos + '0 0 32');

    if(this.target != "")
    {
        this.enemy = find(NULL, targetname, this.target);
        if(this.enemy == NULL)
            LOG_TRACE("A turret_checkpoint faild to find its target!");
    }
    //setthink(this, turret_checkpoint_think);
    //this.nextthink = time + tc_acum + 0.25;
    //tc_acum += 0.25;
}

spawnfunc(turret_checkpoint)
{
    setorigin(this, this.origin);
    setthink(this, turret_checkpoint_init);
    this.nextthink = time + 0.2;
}

// Compat.
spawnfunc(walker_checkpoint)
{
    this.classname = "turret_checkpoint";
    spawnfunc_turret_checkpoint(this);
}
