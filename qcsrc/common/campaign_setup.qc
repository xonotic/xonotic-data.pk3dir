#include "campaign_setup.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/campaign_common.qh>
	#include <common/mapinfo.qh>
#endif

void CampaignSetup(int n)
{
	localcmd("set g_campaign 1\n");
	localcmd("set _campaign_name \"");
		localcmd(campaign_name);
		localcmd("\"\n");
	localcmd("set _campaign_index ");
		localcmd(ftos(campaign_offset + n));
		localcmd("\n");
	localcmd("disconnect\nmaxplayers 16\n");
	MapInfo_LoadMap(campaign_mapname[n], 1);
	#ifdef MENUQC
	makeServerSingleplayer();
	#endif
}
