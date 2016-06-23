spawnfunc(turret_targettrigger);
void turret_targettrigger_touch(entity this);

void turret_targettrigger_touch(entity this)
{
    if (this.cnt > time) return;
    FOREACH_ENTITY_STRING_ORDERED(targetname, this.target, {
        if (!(it.turret_flags & TUR_FLAG_RECIEVETARGETS)) continue;
        if (!it.turret_addtarget) continue;
        it.turret_addtarget(it, other, this);
    });
    this.cnt = time + 0.5;
}

/*QUAKED turret_targettrigger (.5 .5 .5) ?
*/
spawnfunc(turret_targettrigger)
{
    if(!autocvar_g_turrets) { remove(this); return; }

    InitTrigger(this);

    settouch(this, turret_targettrigger_touch);
}
