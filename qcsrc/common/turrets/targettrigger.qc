spawnfunc(turret_targettrigger);
void turret_targettrigger_touch();

void turret_targettrigger_touch()
{SELFPARAM();
    entity e;
    if (self.cnt > time) return;
    entity oldself = this;

    e = find(world, targetname, self.target);
    while (e)
    {
        if (e.turret_flags & TUR_FLAG_RECIEVETARGETS)
        {
            setself(e);
            if(e.turret_addtarget)
                e.turret_addtarget(other,oldself);
        }

        e = find(e, targetname, oldself.target);
    }

    oldself.cnt = time + 0.5;

    setself(this);
}

/*QUAKED turret_targettrigger (.5 .5 .5) ?
*/
spawnfunc(turret_targettrigger)
{
    if(!autocvar_g_turrets) { remove(self); return; }

    InitTrigger ();

    self.touch = turret_targettrigger_touch;
}
