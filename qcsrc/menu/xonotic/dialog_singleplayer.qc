#include "dialog_singleplayer.qh"

#include <common/gametypes/_mod.qh>
#include "bigbutton.qh"
#include "leavematchbutton.qh"
#include "radiobutton.qh"
#include "textlabel.qh"
#include "mainwindow.qh"
#include "campaign.qh"

void InstantAction_LoadMap(entity btn, entity dummy)
{
	float pmin = 2, pmax = 16, pstep = 1;

	cvar_set("timelimit_override", "10");

	bool check_probability_distribution = true;
	float r = 1;

	LABEL(doit);
	if (!check_probability_distribution)
		r = random();

	if((r -= 0.30) < 0)
	{
		MapInfo_SwitchGameType(MAPINFO_TYPE_DEATHMATCH);
		pmin = 2;
		pmax = 8;
		pstep = 1;
	}
	else if((r -= 0.25) < 0)
	{
		MapInfo_SwitchGameType(MAPINFO_TYPE_CTF);
		pmin = 4;
		pmax = 12;
		pstep = 2;
	}
	else if((r -= 0.15) < 0)
	{
		MapInfo_SwitchGameType(MAPINFO_TYPE_TEAM_DEATHMATCH);
		pmin = 4;
		pmax = 8;
		pstep = 2;
	}
	else if((r -= 0.10) < 0)
	{
		MapInfo_SwitchGameType(MAPINFO_TYPE_CA);
		pmin = 4;
		pmax = 8;
		pstep = 2;
	}
	else if((r -= 0.10) < 0)
	{
		MapInfo_SwitchGameType(MAPINFO_TYPE_FREEZETAG);
		pmin = 4;
		pmax = 8;
		pstep = 2;
	}
	else if((r -= 0.05) < 0)
	{
		MapInfo_SwitchGameType(MAPINFO_TYPE_KEYHUNT);
		pmin = 6;
		pmax = 6;
		pstep = 6; // works both for 2 and 3 teams
		// TODO find team count of map, set pstep=2 or 3, and use 2v2(v2) games at least
	}
	else
	{
		r -= 0.05;
		if (check_probability_distribution)
		{
			if(fabs(r) > 0.001)
				error("Incorrect probability distribution.");
			check_probability_distribution = false;
			goto doit;
		}
		r = floor(random() * 4);
		switch(r)
		{
			default:
			case 0:
				MapInfo_SwitchGameType(MAPINFO_TYPE_LMS);
				pmin = 2;
				pmax = 6;
				pstep = 1;
				cvar_set("timelimit_override", "-1");
				break;
			case 1:
				MapInfo_SwitchGameType(MAPINFO_TYPE_DOMINATION);
				pmin = 2;
				pmax = 8;
				pstep = 2;
				break;
			case 2:
				MapInfo_SwitchGameType(MAPINFO_TYPE_ONSLAUGHT);
				pmin = 6;
				pmax = 16;
				pstep = 2;
				break;
			case 3:
				MapInfo_SwitchGameType(MAPINFO_TYPE_ASSAULT);
				pmin = 4;
				pmax = 16;
				pstep = 2;
				break;
		}
	}

	// find random map
	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	string s;
	do
	{
		float m;
		m = floor(random() * MapInfo_count);
		s = MapInfo_BSPName_ByID(m);
	}
	while(!fexists(sprintf("maps/%s.waypoints", s)));

	// these commands are also executed when starting a map from Multiplayer / Create
	// in the menu_loadmap_prepare alias
	localcmd("disconnect\n");
	localcmd("g_campaign 0\n");

	makeServerSingleplayer();

	MapInfo_LoadMap(s, 1);

	// configure bots
	float p;
	pmin = pstep * ceil(pmin / pstep);
	pmax = pstep * floor(pmax / pstep);
	p = pmin + pstep * floor(random() * ((pmax - pmin) / pstep + 1));

	// cvar_set doesn't always work starting an InstantAction game while playing the campaign
	//cvar_set("bot_number", ftos(p - 1));
	localcmd(strcat("bot_number ", ftos(p - 1), "\n"));

	// make sure we go back to menu
	cvar_set("lastlevel", "1");
}

void XonoticSingleplayerDialog_fill(entity me)
{
	entity e, btnPrev, btnNext, lblTitle;

	me.TR(me);
		me.TDempty(me, (me.columns - 3) * 0.5);
		me.TD(me, 2, 3, e = makeXonoticBigButton(_("Instant action with bots!"), '0 0 0'));
			e.onClick = InstantAction_LoadMap;
			e.onClickEntity = NULL;
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, btnPrev = makeXonoticButton("<<", '0 0 0'));
		me.TD(me, 1, me.columns - 2, lblTitle = makeXonoticHeaderLabel("???"));
		me.TD(me, 1, 1, btnNext = makeXonoticButton(">>", '0 0 0'));
	me.TR(me);
		me.TD(me, me.rows - 6, me.columns, me.campaignBox = makeXonoticCampaignList());
			btnPrev.onClick = MultiCampaign_Prev;
			btnPrev.onClickEntity = me.campaignBox;
			btnNext.onClick = MultiCampaign_Next;
			btnNext.onClickEntity = me.campaignBox;
			me.campaignBox.buttonNext = btnNext;
			me.campaignBox.buttonPrev = btnPrev;
			me.campaignBox.labelTitle = lblTitle;

	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Campaign Difficulty:")));
		me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "g_campaign_skill", "-2", ZCTX(_("CSKL^Easy"))));
		me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "g_campaign_skill", "0", ZCTX(_("CSKL^Medium"))));
		me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "g_campaign_skill", "2", ZCTX(_("CSKL^Hard"))));
	me.TR(me);
		me.TDempty(me, me.columns * 1/13);
		me.TD(me, 1, me.columns * 5/13, e = makeXonoticLeaveMatchButton('0 0 0', 0));
		me.TDempty(me, me.columns * 1/13);
		me.TD(me, 1, me.columns * 5/13, e = makeXonoticButton(_("Play campaign!"), '0 0 0'));
			e.onClick = CampaignList_LoadMap;
			e.onClickEntity = me.campaignBox;
}
