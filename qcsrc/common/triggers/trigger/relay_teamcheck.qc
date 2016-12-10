#include "relay_teamcheck.qh"
#ifdef SVQC
void trigger_relay_teamcheck_use(entity this, entity actor, entity trigger)
{
	if(actor.team)
	{
		if(this.spawnflags & 2)
		{
			if(DIFF_TEAM(actor, this))
				SUB_UseTargets(this, actor, trigger);
		}
		else
		{
			if(SAME_TEAM(actor, this))
				SUB_UseTargets(this, actor, trigger);
		}
	}
	else
	{
		if(this.spawnflags & 1)
			SUB_UseTargets(this, actor, trigger);
	}
}

void trigger_relay_teamcheck_reset(entity this)
{
	this.team = this.team_saved;
}

spawnfunc(trigger_relay_teamcheck)
{
	this.team_saved = this.team;
	this.use = trigger_relay_teamcheck_use;
	this.reset = trigger_relay_teamcheck_reset;
}
#endif
