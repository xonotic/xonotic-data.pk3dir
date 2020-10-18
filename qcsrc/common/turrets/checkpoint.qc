#include "checkpoint.qh"

#ifdef SVQC

/*QUAKED turret_checkpoint (1 0 1) (-32 -32 -32) (32 32 32)
-----------KEYS------------
target: .targetname of next waypoint in chain.
wait:   Pause at this point # seconds.
-----------SPAWNFLAGS-----------
---------NOTES----------
If a loop is of targets are formed, any unit entering this loop will patrol it indefinitly.
If the checkpoint chain is not looped, the unit will go "Roaming" when the last point is reached.
*/
void turret_checkpoint_init(entity this)
{
    traceline(this.origin + '0 0 16', this.origin - '0 0 1024', MOVE_WORLDONLY, this);
    setorigin(this, trace_endpos + '0 0 32');

    if(this.target && this.target != "")
    {
        this.enemy = find(NULL, targetname, this.target);
        if(!this.enemy)
            LOG_TRACE("A turret_checkpoint failed to find its target!");
    }
}

spawnfunc(turret_checkpoint)
{
    setorigin(this, this.origin);
    InitializeEntity(this, turret_checkpoint_init, INITPRIO_FINDTARGET);
}

// Compat.
spawnfunc(walker_checkpoint)
{
    spawnfunc_turret_checkpoint(this);
}

#endif
