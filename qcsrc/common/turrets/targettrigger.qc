#include "targettrigger.qh"

#ifdef SVQC

spawnfunc(turret_targettrigger);
void turret_targettrigger_touch(entity this, entity toucher);

void turret_targettrigger_touch(entity this, entity toucher)
{
    if (this.cnt > time) return;
    IL_EACH(g_turrets, it.targetname == this.target,
    {
        if (!(it.turret_flags & TUR_FLAG_RECIEVETARGETS)) continue;
        if (!it.turret_addtarget) continue;
        it.turret_addtarget(it, toucher, this);
    });
    this.cnt = time + 0.5;
}

/*QUAKED turret_targettrigger (.5 .5 .5) ?
*/
spawnfunc(turret_targettrigger)
{
    if(!autocvar_g_turrets) { delete(this); return; }

    InitTrigger(this);

    settouch(this, turret_targettrigger_touch);
}

#endif
