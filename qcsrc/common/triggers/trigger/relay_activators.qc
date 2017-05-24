#include "relay_activators.qh"
#ifdef SVQC
void relay_activators_use(entity this, entity actor, entity trigger)
{
	for(entity trg = NULL; (trg = find(trg, targetname, this.target)); )
	{
		if (trg.setactive)
			trg.setactive(trg, this.cnt);
		else
		{
			//bprint("Not using setactive\n");
			if(this.cnt == ACTIVE_TOGGLE)
				if(trg.active == ACTIVE_ACTIVE)
					trg.active = ACTIVE_NOT;
				else
					trg.active = ACTIVE_ACTIVE;
			else
				trg.active = this.cnt;
		}
	}
}

spawnfunc(relay_activate)
{
	this.cnt = ACTIVE_ACTIVE;
	this.use = relay_activators_use;
}

spawnfunc(relay_deactivate)
{
	this.cnt = ACTIVE_NOT;
	this.use = relay_activators_use;
}

spawnfunc(relay_activatetoggle)
{
	this.cnt = ACTIVE_TOGGLE;
	this.use = relay_activators_use;
}
#endif
