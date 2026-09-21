#include "campaign_setup.qh"

#ifdef SVQC
	#include <common/campaign_common.qh>
	#include <common/mapinfo.qh>
#endif

void CampaignSetup(int n)
{
	localcmd("set g_campaign 1\n");
	localcmd(strcat("set _campaign_name \"", campaign_name, "\"\n"));
	localcmd(strcat("set _campaign_index ", ftos(campaign_offset + n), "\n"));
	localcmd("disconnect\nmaxplayers 16\n");
	MapInfo_LoadMap(campaign_mapname[n], true);
#ifdef MENUQC
	makeServerSingleplayer();
#endif
}
