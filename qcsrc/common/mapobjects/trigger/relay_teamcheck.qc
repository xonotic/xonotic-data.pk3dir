#include "relay_teamcheck.qh"

#ifdef SVQC
void trigger_relay_teamcheck_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	if(actor.team)
	{
		if(this.spawnflags & RELAYTEAMCHECK_INVERT)
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
		if(this.spawnflags & RELAYTEAMCHECK_NOTEAM)
			SUB_UseTargets(this, actor, trigger);
	}
}

void trigger_relay_teamcheck_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
	this.team = this.team_saved;
}

spawnfunc(trigger_relay_teamcheck)
{
	this.active = ACTIVE_ACTIVE;
	this.team_saved = this.team;
	IL_PUSH(g_saved_team, this);
	this.use = trigger_relay_teamcheck_use;
	this.reset = trigger_relay_teamcheck_reset;
}
#endif
