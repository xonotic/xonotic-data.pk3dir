#include "campaign.qh"

#include <common/campaign_common.qh>
#include <common/mapinfo.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <server/cheats.qh>
#include <server/intermission.qh>
#include <server/world.qh>

// campaign cvars:
//   _campaign_index: index of CURRENT map
//   _campaign_name: name of the current campaign
//   g_campaign(name)_index: index of current LAST map (saved)
//   g_campaign_skill: bot skill offset

float campaign_level;
float campaign_won;
string campaign_index_var;
//float checkrules_equality;

float CampaignBailout(string s)
{
	cvar_set("g_campaign", "0");
	LOG_INFO("^4campaign initialization failed: ", s);
	if(autocvar__campaign_testrun)
		error("CAMPAIGN FAIL AHAHAHAHAHAHAHAHAH))");
	return 1;
}

float Campaign_Invalid()
{
	string thismapname, wantedmapname;
	thismapname = GetMapname();
	wantedmapname = campaign_gametype[0];
	if(MapInfo_CurrentGametype() != MapInfo_Type_FromString(wantedmapname, false, false))
		return CampaignBailout("wrong gametype!");
	wantedmapname = campaign_mapname[0];
	if(wantedmapname != thismapname)
		return CampaignBailout(strcat("wrong map: ", wantedmapname, " != ", thismapname));
	return 0;
}

int Campaign_GetLevelNum()
{
	return campaign_level + 1;
}

void CampaignPreInit()
{
	float baseskill;
	campaign_level = autocvar__campaign_index;
	campaign_name = strzone(autocvar__campaign_name);
	campaign_index_var = strzone(strcat("g_campaign", campaign_name, "_index"));
	CampaignFile_Load(campaign_level, 2);

	if(campaign_entries < 1)
	{
		CampaignBailout("unknown map");
		return;
	}

	if(autocvar_sv_cheats)
	{
		MapInfo_SwitchGameType(MapInfo_Type_FromString(campaign_gametype[0], false, false));
		CampaignFile_Unload();
		CampaignBailout("JOLLY CHEATS AHAHAHAHAHAHAH))");
		return;
	}

	baseskill = max(0, autocvar_g_campaign_skill + campaign_botskill[0]);
	campaign_forcewin = false;

	cvar_set("sv_public", "0");
	cvar_set("pausable", "1");

	string cvar_campaignwrapper_list = strcat("; ", campaign_mutators[0], "; ");
	int argc = tokenizebyseparator(cvar_campaignwrapper_list, "; ");
	if(argc > 0)
	{
		for(int j = 0; j < argc; ++j)
		{
			string arg = argv(j);
			if(arg == "") continue;
			_MapInfo_Parse_Settemp(mapname, MAPINFO_SETTEMP_ACL_USER, 0, arg, 1);
		}
	}

	cvar_settemp("g_campaign", "1");
	cvar_settemp("g_dm", "0");
	cvar_settemp("skill", ftos(baseskill));
	cvar_settemp("bot_number", ftos(campaign_bots[0]));

	MapInfo_SwitchGameType(MapInfo_Type_FromString(campaign_gametype[0], false, false));

	if(Campaign_Invalid())
		return;
}

void CampaignPostInit()
{
	// now some sanity checks
	if(Campaign_Invalid())
		return;
	if(autocvar__campaign_testrun)
	{
		cvar_set("fraglimit", "0");
		cvar_set("leadlimit", "0");
		cvar_set("timelimit", "0.01");
	}
	else
	{
		// "default" uses implicit values, "" or "0" means no limit
		tokenizebyseparator(campaign_fraglimit[0], "+");
		if(argv(0) != "default") {
			cvar_set("fraglimit", argv(0));
		}
		if(argv(1) != "default") {
			cvar_set("leadlimit", argv(1));
		}
		if(campaign_timelimit[0] != "default") {
			cvar_set("timelimit", campaign_timelimit[0]);
		}
	}
}

void CampaignSaveCvar(string cvarname, float value)
{
	float fh;
	float len;
	string contents;
	string l;

	registercvar(cvarname, ftos(value));
	cvar_set(cvarname, ftos(value));
	// note: cvarname must be remembered

	fh = fopen("campaign.cfg", FILE_READ);
	contents = "";
	if(fh >= 0)
	{
		while((l = fgets(fh)))
		{
			len = tokenize_console(l);
			if(len != 3)
				continue;
			if(argv(0) != "set")
				continue;
			if(argv(1) == cvarname)
				continue;
			contents = strcat(contents, "set ", argv(1), " ", argv(2), "\n");
		}
		fclose(fh);
	}
	contents = strcat(contents, "set ", cvarname,  " ", ftos(value), "\n");
	fh = fopen("campaign.cfg", FILE_WRITE);
	if(fh >= 0)
	{
		fputs(fh, contents);
	}
	else
	{
		error("Cannot write to campaign file");
	}
}

void CampaignPreIntermission()
{
	int won = 0;
	int lost = 0;
	string savevar;

	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), {
		if(it.winning)
			won += 1;
		else
			lost += 1;
	});

	if(autocvar__campaign_testrun)
	{
		campaign_won = 1;
		bprint("Campaign test run, advancing level.\n");
	}
	else if(campaign_forcewin)
	{
		campaign_won = 1;
		bprint("The current level has been WON.\n");
	}
	else if(won == 1 && lost == 0 && checkrules_equality == 0)
	{
		if(autocvar_timelimit != 0 && autocvar_fraglimit != 0 && time > autocvar_timelimit * 60) // checks if the timelimit has expired.
		{
			campaign_won = 0;
			bprint("Time's up! The current level has been LOST.\n");
			// sound!
		}
		else
		{
			campaign_won = 1;
			bprint("The current level has been WON.\n");
			// sound!
		}
	}
	else if(autocvar_timelimit != 0 && time > autocvar_timelimit * 60)
	{
		campaign_won = 0;
		bprint("Time's up! The current level has been LOST.\n");
		// sound!
	}
	else
	{
		campaign_won = 0;
		bprint("The current level has been LOST.\n");
		// sound!
	}

	if(campaign_won && cheatcount_total == 0 && !autocvar__campaign_testrun)
	{
		if(campaign_level == cvar(campaign_index_var))
		{
			if(campaign_entries < 2)
			{
				// I have won
				savevar = strcat("g_campaign", campaign_name, "_won");
				CampaignSaveCvar(savevar, 1);
				// advance level (for menu to show it right)
				CampaignSaveCvar(campaign_index_var, campaign_level + 1);
			}
			else
			{
				// advance level
				CampaignSaveCvar(campaign_index_var, campaign_level + 1);
			}
		}
	}
}

void CampaignPostIntermission()
{
	// NOTE: campaign_won is 0 or 1, that is, points to the next level

	if(campaign_won && campaign_entries < 2)
	{
		// last map won!
		LOG_DEBUG("^2test run: campaign looks GOOD");
		localcmd("togglemenu 1\n");
		CampaignFile_Unload();
		return;
	}

	CampaignSetup(campaign_won);
	CampaignFile_Unload();
	strunzone(campaign_index_var);
	strunzone(campaign_name);
	campaign_name = "";
}



void CampaignLevelWarp(float n)
{
	if(n < 0)
		n = campaign_level + 1;
	CampaignFile_Unload();
	CampaignFile_Load(n, 1);
	if(campaign_entries)
		CampaignSetup(0);
	else
		error("Sorry, cheater. You are NOT WELCOME.");
	CampaignFile_Unload();
}

