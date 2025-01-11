#include "levelwarp.qh"

#ifdef SVQC
void target_levelwarp_use(entity this, entity actor, entity trigger)
{
	if(!autocvar_g_campaign)
		return; // only in campaign
	if(this.active != ACTIVE_ACTIVE)
		return;

	if(this.cnt)
		CampaignLevelWarp(this.cnt - 1); // specific level
	else
		CampaignLevelWarp(-1); // next level
}

void target_levelwarp_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
}

spawnfunc(target_levelwarp)
{
	// this.cnt is index (starting from 1) of the campaign level to warp to
	// 0 means next level
	this.use = target_levelwarp_use;
	this.active = ACTIVE_ACTIVE;
	this.reset = target_levelwarp_reset;
}
#endif
