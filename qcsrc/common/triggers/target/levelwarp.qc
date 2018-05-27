#include "levelwarp.qh"

#ifdef SVQC
void target_levelwarp_use(entity this, entity actor, entity trigger)
{
	if(!autocvar_g_campaign)
		return; // only in campaign

	if(this.cnt)
		CampaignLevelWarp(this.cnt - 1); // specific level
	else
		CampaignLevelWarp(-1); // next level
}

spawnfunc(target_levelwarp)
{
	// this.cnt is index (starting from 1) of the campaign level to warp to
	// 0 means next level
	this.use = target_levelwarp_use;
}
#endif
