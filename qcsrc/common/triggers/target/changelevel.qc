#include "changelevel.qh"
#ifdef SVQC
.string chmap, gametype;
.entity chlevel_targ;

void target_changelevel_use(entity this, entity actor, entity trigger)
{
	if(this.spawnflags & 2)
	{
		// simply don't react if a non-player triggers it
		if(!IS_PLAYER(actor)) { return; }

		actor.chlevel_targ = this;

		int plnum = 0;
		int realplnum = 0;
		// let's not count bots
		FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), {
			++realplnum;
			if(it.chlevel_targ == this)
				++plnum;
		});
		if(plnum < ceil(realplnum * min(1, this.count))) // 70% of players
			return;
	}

	if(this.gametype != "")
		MapInfo_SwitchGameType(MapInfo_Type_FromString(this.gametype));

	if (this.chmap == "")
		localcmd("endmatch\n");
	else
		localcmd(strcat("changelevel ", this.chmap, "\n"));
}

spawnfunc(target_changelevel)
{
	this.use = target_changelevel_use;

	if(!this.count) { this.count = 0.7; }
}
#endif
