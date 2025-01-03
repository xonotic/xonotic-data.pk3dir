#include "changelevel.qh"
#ifdef SVQC
.string chmap, gametype;
.entity chlevel_targ;

void target_changelevel_use(entity this, entity actor, entity trigger)
{
	if(game_stopped)
		return;
	if(this.active != ACTIVE_ACTIVE)
		return;

	if(this.spawnflags & CHANGELEVEL_MULTIPLAYER)
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
		MapInfo_SwitchGameType(MapInfo_Type_FromString(this.gametype, false, false));

	if (this.chmap == "")
	{
		if(IS_REAL_CLIENT(actor) && autocvar_g_campaign) // only count it as a win if the player touched (TODO: bots ending stage/vehicles?)
			campaign_forcewin = true; // this counts as beating the map in a campaign stage!
		NextLevel();
	}
	else
		changelevel(this.chmap);
}

void target_changelevel_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
}

/*target_changelevel
Target to change/end level
KEYS:
chmap: map to switch to, leave empty for endmatch
gametype: gametype for the next map
count: fraction of real players that need to trigger this entity for levelchange
SPAWNFLAGS:
CHANGELEVEL_MULTIPLAYER: multiplayer support
*/

spawnfunc(target_changelevel)
{
	this.use = target_changelevel_use;
	this.active = ACTIVE_ACTIVE;
	this.reset = target_changelevel_reset;

	if(!this.count)
	{
		this.count = 0.7;
	}
}
#endif
