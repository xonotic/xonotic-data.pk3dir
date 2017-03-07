#include "bot.qh"

#include "cvars.qh"

#include "aim.qh"
#include "navigation.qh"
#include "scripting.qh"
#include "waypoints.qh"

#include "havocbot/havocbot.qh"
#include "havocbot/scripting.qh"

#include "../../teamplay.qh"

#include "../../antilag.qh"
#include "../../autocvars.qh"
#include "../../campaign.qh"
#include "../../client.qh"
#include "../../constants.qh"
#include "../../defs.qh"
#include "../../race.qh"
#include <common/t_items.qh>

#include "../../mutators/_mod.qh"

#include "../../weapons/accuracy.qh"

#include <common/physics/player.qh>
#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/mapinfo.qh>
#include <common/teams.qh>
#include <common/util.qh>

#include <server/scores_rules.qh>

#include <common/weapons/_all.qh>

#include <lib/csqcmodel/sv_model.qh>

#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>

entity bot_spawn()
{
	entity bot = spawnclient();
	if (bot)
	{
		setItemGroupCount();
		currentbots = currentbots + 1;
		bot_setnameandstuff(bot);
		ClientConnect(bot);
		PutClientInServer(bot);
	}
	return bot;
}

void bot_think(entity this)
{
	if (this.bot_nextthink > time)
		return;

	this.flags &= ~FL_GODMODE;
	if(autocvar_bot_god)
		this.flags |= FL_GODMODE;

	this.bot_nextthink = max(time, this.bot_nextthink) + max(0.01, autocvar_bot_ai_thinkinterval * (0.5 ** this.bot_aiskill) * min(14 / (skill + 14), 1));

	//if (this.bot_painintensity > 0)
	//	this.bot_painintensity = this.bot_painintensity - (skill + 1) * 40 * frametime;

	//this.bot_painintensity = this.bot_painintensity + this.bot_oldhealth - this.health;
	//this.bot_painintensity = bound(0, this.bot_painintensity, 100);

	if (!IS_PLAYER(this) || (autocvar_g_campaign && !campaign_bots_may_start))
	{
		this.movement = '0 0 0';
		this.bot_nextthink = time + 0.5;
		return;
	}

	if (this.fixangle)
	{
		this.v_angle = this.angles;
		this.v_angle_z = 0;
		this.fixangle = false;
	}

	this.dmg_take = 0;
	this.dmg_save = 0;
	this.dmg_inflictor = NULL;

	// calculate an aiming latency based on the skill setting
	// (simulated network latency + naturally delayed reflexes)
	//this.ping = 0.7 - bound(0, 0.05 * skill, 0.5); // moved the reflexes to bot_aimdir (under the name 'think')
	// minimum ping 20+10 random
	this.ping = bound(0,0.07 - bound(0, (skill + this.bot_pingskill) * 0.005,0.05)+random()*0.01,0.65); // Now holds real lag to server, and higer skill players take a less laggy server
	// skill 10 = ping 0.2 (adrenaline)
	// skill 0 = ping 0.7 (slightly drunk)

	// clear buttons
	PHYS_INPUT_BUTTON_ATCK(this) = false;
	PHYS_INPUT_BUTTON_JUMP(this) = false;
	PHYS_INPUT_BUTTON_ATCK2(this) = false;
	PHYS_INPUT_BUTTON_ZOOM(this) = false;
	PHYS_INPUT_BUTTON_CROUCH(this) = false;
	PHYS_INPUT_BUTTON_HOOK(this) = false;
	PHYS_INPUT_BUTTON_INFO(this) = false;
	PHYS_INPUT_BUTTON_DRAG(this) = false;
	PHYS_INPUT_BUTTON_CHAT(this) = false;
	PHYS_INPUT_BUTTON_USE(this) = false;

	if (time < game_starttime)
	{
		// block the bot during the countdown to game start
		this.movement = '0 0 0';
		this.bot_nextthink = game_starttime;
		return;
	}

	// if dead, just wait until we can respawn
	if (IS_DEAD(this))
	{
		this.movement = '0 0 0';
		if (this.deadflag == DEAD_DEAD)
		{
			PHYS_INPUT_BUTTON_JUMP(this) = true; // press jump to respawn
			this.bot_strategytime = 0;
		}
	}
	else if(this.aistatus & AI_STATUS_STUCK)
		navigation_unstuck(this);

	// now call the current bot AI (havocbot for example)
	this.bot_ai(this);
}

void bot_setnameandstuff(entity this)
{
	string readfile, s;
	float file, tokens, prio;

	string bot_name, bot_model, bot_skin, bot_shirt, bot_pants;
	string name, prefix, suffix;

 	if(autocvar_g_campaign)
	{
		prefix = "";
		suffix = "";
	}
	else
	{
		prefix = autocvar_bot_prefix;
		suffix = autocvar_bot_suffix;
	}

	file = fopen(autocvar_bot_config_file, FILE_READ);

	if(file < 0)
	{
		LOG_INFO(strcat("Error: Can not open the bot configuration file '",autocvar_bot_config_file,"'\n"));
		readfile = "";
	}
	else
	{
		RandomSelection_Init();
		while((readfile = fgets(file)))
		{
			if(substring(readfile, 0, 2) == "//")
				continue;
			if(substring(readfile, 0, 1) == "#")
				continue;
			tokens = tokenizebyseparator(readfile, "\t");
			if(tokens == 0)
				continue;
			s = argv(0);
			prio = 1;
			FOREACH_CLIENT(IS_BOT_CLIENT(it), LAMBDA(
				if(s == it.cleanname)
				{
					prio = 0;
					break;
				}
			));
			RandomSelection_AddString(readfile, 1, prio);
		}
		readfile = RandomSelection_chosen_string;
		fclose(file);
	}

	tokens = tokenizebyseparator(readfile, "\t");
	if(argv(0) != "") bot_name = argv(0);
	else bot_name = "Bot";

	if(argv(1) != "") bot_model = argv(1);
	else bot_model = "";

	if(argv(2) != "") bot_skin = argv(2);
	else bot_skin = "0";

	if(argv(3) != "" && stof(argv(3)) >= 0) bot_shirt = argv(3);
	else bot_shirt = ftos(floor(random() * 15));

	if(argv(4) != "" && stof(argv(4)) >= 0) bot_pants = argv(4);
	else bot_pants = ftos(floor(random() * 15));

	this.bot_forced_team = stof(argv(5));

	prio = 6;

	#define READSKILL(f, w, r) MACRO_BEGIN { \
		if(argv(prio) != "") \
			this.f = stof(argv(prio)) * w; \
		else \
			this.f = (!autocvar_g_campaign) * (2 * random() - 1) * r * w; \
		prio++; \
	} MACRO_END
	//print(bot_name, ": ping=", argv(9), "\n");

	READSKILL(havocbot_keyboardskill, 0.5, 0.5); // keyboard skill
	READSKILL(bot_moveskill, 2, 0); // move skill
	READSKILL(bot_dodgeskill, 2, 0); // dodge skill

	READSKILL(bot_pingskill, 0.5, 0); // ping skill

	READSKILL(bot_weaponskill, 2, 0); // weapon skill
	READSKILL(bot_aggresskill, 1, 0); // aggre skill
	READSKILL(bot_rangepreference, 1, 0); // read skill

	READSKILL(bot_aimskill, 2, 0); // aim skill
	READSKILL(bot_offsetskill, 2, 0.5); // offset skill
	READSKILL(bot_mouseskill, 1, 0.5); // mouse skill

	READSKILL(bot_thinkskill, 1, 0.5); // think skill
	READSKILL(bot_aiskill, 2, 0); // "ai" skill

	this.bot_config_loaded = true;

	// this is really only a default, JoinBestTeam is called later
	setcolor(this, stof(bot_shirt) * 16 + stof(bot_pants));
	this.bot_preferredcolors = this.clientcolors;

	// pick the name
	if (autocvar_bot_usemodelnames)
		name = bot_model;
	else
		name = bot_name;

	// number bots with identical names
	int j = 0;
	FOREACH_CLIENT(IS_BOT_CLIENT(it), LAMBDA(
		if(it.cleanname == name)
			++j;
	));
	if (j)
		this.netname = this.netname_freeme = strzone(strcat(prefix, name, "(", ftos(j), ")", suffix));
	else
		this.netname = this.netname_freeme = strzone(strcat(prefix, name, suffix));

	this.cleanname = strzone(name);

	// pick the model and skin
	if(substring(bot_model, -4, 1) != ".")
		bot_model = strcat(bot_model, ".iqm");
	this.playermodel = this.playermodel_freeme = strzone(strcat("models/player/", bot_model));
	this.playerskin = this.playerskin_freeme = strzone(bot_skin);

	this.cvar_cl_accuracy_data_share = 1;  // share the bots weapon accuracy data with the NULL
	this.cvar_cl_accuracy_data_receive = 0;  // don't receive any weapon accuracy data
}

void bot_custom_weapon_priority_setup()
{
	float tokens, i, w;

	bot_custom_weapon = false;

	if(	autocvar_bot_ai_custom_weapon_priority_far == "" ||
		autocvar_bot_ai_custom_weapon_priority_mid == "" ||
		autocvar_bot_ai_custom_weapon_priority_close == "" ||
 		autocvar_bot_ai_custom_weapon_priority_distances == ""
	)
		return;

	// Parse distances
	tokens = tokenizebyseparator(autocvar_bot_ai_custom_weapon_priority_distances," ");

	if (tokens!=2)
		return;

	bot_distance_far = stof(argv(0));
	bot_distance_close = stof(argv(1));

	if(bot_distance_far < bot_distance_close){
		bot_distance_far = stof(argv(1));
		bot_distance_close = stof(argv(0));
	}

	// Initialize list of weapons
	bot_weapons_far[0] = -1;
	bot_weapons_mid[0] = -1;
	bot_weapons_close[0] = -1;

	// Parse far distance weapon priorities
	tokens = tokenizebyseparator(W_NumberWeaponOrder(autocvar_bot_ai_custom_weapon_priority_far)," ");

	int c = 0;
	for(i=0; i < tokens && c < Weapons_COUNT; ++i){
		w = stof(argv(i));
		if ( w >= WEP_FIRST && w <= WEP_LAST) {
			bot_weapons_far[c] = w;
			++c;
		}
	}
	if(c < Weapons_COUNT)
		bot_weapons_far[c] = -1;

	// Parse mid distance weapon priorities
	tokens = tokenizebyseparator(W_NumberWeaponOrder(autocvar_bot_ai_custom_weapon_priority_mid)," ");

	c = 0;
	for(i=0; i < tokens && c < Weapons_COUNT; ++i){
		w = stof(argv(i));
		if ( w >= WEP_FIRST && w <= WEP_LAST) {
			bot_weapons_mid[c] = w;
			++c;
		}
	}
	if(c < Weapons_COUNT)
		bot_weapons_mid[c] = -1;

	// Parse close distance weapon priorities
	tokens = tokenizebyseparator(W_NumberWeaponOrder(autocvar_bot_ai_custom_weapon_priority_close)," ");

	c = 0;
	for(i=0; i < tokens && i < Weapons_COUNT; ++i){
		w = stof(argv(i));
		if ( w >= WEP_FIRST && w <= WEP_LAST) {
			bot_weapons_close[c] = w;
			++c;
		}
	}
	if(c < Weapons_COUNT)
		bot_weapons_close[c] = -1;

	bot_custom_weapon = true;
}

void bot_endgame()
{
	bot_relinkplayerlist();
	entity e = bot_list;
	while (e)
	{
		setcolor(e, e.bot_preferredcolors);
		e = e.nextbot;
	}
	// if dynamic waypoints are ever implemented, save them here
}

void bot_relinkplayerlist()
{
	player_count = 0;
	currentbots = 0;
	bot_list = NULL;

	entity prevbot = NULL;
	FOREACH_CLIENT(true,
	{
		++player_count;

		if(IS_BOT_CLIENT(it))
		{
			if(prevbot)
				prevbot.nextbot = it;
			else
				bot_list = it;
			prevbot = it;
			++currentbots;
		}
	});
	if(prevbot)
		prevbot.nextbot = NULL;
	LOG_TRACE("relink: ", ftos(currentbots), " bots seen.");
	bot_strategytoken = bot_list;
	bot_strategytoken_taken = true;
}

void bot_clientdisconnect(entity this)
{
	if (!IS_BOT_CLIENT(this))
		return;
	bot_clearqueue(this);
	if(this.cleanname)
		strunzone(this.cleanname);
	if(this.netname_freeme)
		strunzone(this.netname_freeme);
	if(this.playermodel_freeme)
		strunzone(this.playermodel_freeme);
	if(this.playerskin_freeme)
		strunzone(this.playerskin_freeme);
	this.cleanname = string_null;
	this.netname_freeme = string_null;
	this.playermodel_freeme = string_null;
	this.playerskin_freeme = string_null;
	if(this.bot_cmd_current)
		delete(this.bot_cmd_current);
	if(bot_waypoint_queue_owner == this)
		bot_waypoint_queue_owner = NULL;
}

void bot_clientconnect(entity this)
{
	if (!IS_BOT_CLIENT(this)) return;
	this.bot_preferredcolors = this.clientcolors;
	this.bot_nextthink = time - random();
	this.lag_func = bot_lagfunc;
	this.isbot = true;
	this.createdtime = this.bot_nextthink;

	if(!this.bot_config_loaded) // This is needed so team overrider doesn't break between matches
		bot_setnameandstuff(this);

	if(this.bot_forced_team==1)
		this.team = NUM_TEAM_1;
	else if(this.bot_forced_team==2)
		this.team = NUM_TEAM_2;
	else if(this.bot_forced_team==3)
		this.team = NUM_TEAM_3;
	else if(this.bot_forced_team==4)
		this.team = NUM_TEAM_4;
	else
		JoinBestTeam(this, false, true);

	havocbot_setupbot(this);
}

void bot_removefromlargestteam()
{
	CheckAllowedTeams(NULL);
	GetTeamCounts(NULL);

	entity best = NULL;
	float besttime = 0;
	int bestcount = 0;

	int bcount = 0;
	FOREACH_CLIENT(it.isbot,
	{
		++bcount;

		if(!best)
		{
			best = it;
			besttime = it.createdtime;
		}

		int thiscount = 0;

		switch(it.team)
		{
			case NUM_TEAM_1: thiscount = c1; break;
			case NUM_TEAM_2: thiscount = c2; break;
			case NUM_TEAM_3: thiscount = c3; break;
			case NUM_TEAM_4: thiscount = c4; break;
		}

		if(thiscount > bestcount)
		{
			bestcount = thiscount;
			besttime = it.createdtime;
			best = it;
		}
		else if(thiscount == bestcount && besttime < it.createdtime)
		{
			besttime = it.createdtime;
			best = it;
		}
	});
	if(!bcount)
		return; // no bots to remove
	currentbots = currentbots - 1;
	dropclient(best);
}

void bot_removenewest()
{
	if(teamplay)
	{
		bot_removefromlargestteam();
		return;
	}

	float besttime = 0;
	entity best = NULL;
	int bcount = 0;

	FOREACH_CLIENT(it.isbot,
	{
		++bcount;

		if(!best)
		{
			best = it;
			besttime = it.createdtime;
		}

		if(besttime < it.createdtime)
		{
			besttime = it.createdtime;
			best = it;
		}
	});

	if(!bcount)
		return; // no bots to remove

	currentbots = currentbots - 1;
	dropclient(best);
}

void autoskill(float factor)
{
	float bestbot;
	float bestplayer;

	bestbot = -1;
	bestplayer = -1;
	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(
		if(IS_REAL_CLIENT(it))
			bestplayer = max(bestplayer, it.totalfrags - it.totalfrags_lastcheck);
		else
			bestbot = max(bestbot, it.totalfrags - it.totalfrags_lastcheck);
	));

	LOG_TRACE("autoskill: best player got ", ftos(bestplayer), ", ");
	LOG_TRACE("best bot got ", ftos(bestbot), "; ");
	if(bestbot < 0 || bestplayer < 0)
	{
		LOG_TRACE("not doing anything");
		// don't return, let it reset all counters below
	}
	else if(bestbot <= bestplayer * factor - 2)
	{
		if(autocvar_skill < 17)
		{
			LOG_TRACE("2 frags difference, increasing skill");
			cvar_set("skill", ftos(autocvar_skill + 1));
			bprint("^2SKILL UP!^7 Now at level ", ftos(autocvar_skill), "\n");
		}
	}
	else if(bestbot >= bestplayer * factor + 2)
	{
		if(autocvar_skill > 0)
		{
			LOG_TRACE("2 frags difference, decreasing skill");
			cvar_set("skill", ftos(autocvar_skill - 1));
			bprint("^1SKILL DOWN!^7 Now at level ", ftos(autocvar_skill), "\n");
		}
	}
	else
	{
		LOG_TRACE("not doing anything");
		return;
		// don't reset counters, wait for them to accumulate
	}

	FOREACH_CLIENT(IS_PLAYER(it), LAMBDA(it.totalfrags_lastcheck = it.totalfrags));
}

void bot_calculate_stepheightvec()
{
	stepheightvec = autocvar_sv_stepheight * '0 0 1';
	jumpstepheightvec = stepheightvec +
		((autocvar_sv_jumpvelocity * autocvar_sv_jumpvelocity) / (2 * autocvar_sv_gravity)) * '0 0 0.85';
		// 0.75 factor is for safety to make the jumps easy
}

float bot_fixcount()
{
	int activerealplayers = 0;
	int realplayers = 0;
	if (MUTATOR_CALLHOOK(Bot_FixCount, activerealplayers, realplayers)) {
		activerealplayers = M_ARGV(0, int);
		realplayers = M_ARGV(1, int);
	} else {
		FOREACH_CLIENT(IS_REAL_CLIENT(it), LAMBDA(
			if(IS_PLAYER(it))
				++activerealplayers;
			++realplayers;
		));
	}

	int bots;
	// add/remove bots if needed to make sure there are at least
	// minplayers+bot_number, or remove all bots if no one is playing
	// But don't remove bots immediately on level change, as the real players
	// usually haven't rejoined yet
	bots_would_leave = false;
	if (teamplay && autocvar_bot_vs_human && AvailableTeams() == 2)
		bots = min(ceil(fabs(autocvar_bot_vs_human) * activerealplayers), maxclients - realplayers);
	else if ((realplayers || autocvar_bot_join_empty || (currentbots > 0 && time < 5)))
	{
		float realminplayers, minplayers;
		realminplayers = autocvar_minplayers;
		minplayers = max(0, floor(realminplayers));

		float realminbots, minbots;
		realminbots = autocvar_bot_number;
		minbots = max(0, floor(realminbots));

		bots = min(max(minbots, minplayers - activerealplayers), maxclients - realplayers);
		if(bots > minbots)
			bots_would_leave = true;
	}
	else
	{
		// if there are no players, remove bots
		bots = 0;
	}

	// only add one bot per frame to avoid utter chaos
	if(time > botframe_nextthink)
	{
		//dprint(ftos(bots), " ? ", ftos(currentbots), "\n");
		while (currentbots < bots)
		{
			if (bot_spawn() == NULL)
			{
				bprint("Can not add bot, server full.\n");
				return false;
			}
		}
		while (currentbots > bots)
			bot_removenewest();
	}

	return true;
}

void bot_remove_from_bot_list(entity this)
{
	entity e = bot_list;
	entity prev_bot = NULL;
	while (e)
	{
		if(e == this)
		{
			if(!prev_bot)
				bot_list = this.nextbot;
			else
				prev_bot.nextbot = this.nextbot;
			if(bot_strategytoken == this)
			{
				bot_strategytoken = this.nextbot;
				bot_strategytoken_taken = true;
			}
			this.nextbot = NULL;
			break;
		}
		prev_bot = e;
		e = e.nextbot;
	}
}

void bot_clear(entity this)
{
	bot_remove_from_bot_list(this);
	if(bot_waypoint_queue_owner == this)
		bot_waypoint_queue_owner = NULL;
	this.aistatus &= ~AI_STATUS_STUCK; // otherwise bot_waypoint_queue_owner will be set again to this by navigation_unstuck
}

void bot_serverframe()
{
	if (game_stopped)
		return;

	if (time < 2)
		return;

	bot_calculate_stepheightvec();
	bot_navigation_movemode = ((autocvar_bot_navigation_ignoreplayers) ? MOVE_NOMONSTERS : MOVE_NORMAL);

	if(time > autoskill_nextthink)
	{
		float a;
		a = autocvar_skill_auto;
		if(a)
			autoskill(a);
		autoskill_nextthink = time + 5;
	}

	if(time > botframe_nextthink)
	{
		if(!bot_fixcount())
			botframe_nextthink = time + 10;
	}

	bot_ignore_bots = autocvar_bot_ignore_bots;

	if(botframe_spawnedwaypoints)
	{
		if(autocvar_waypoint_benchmark)
			localcmd("quit\n");
	}

	if (currentbots > 0 || autocvar_g_waypointeditor || autocvar_g_waypointeditor_auto)
	if (botframe_spawnedwaypoints)
	{
		if(botframe_cachedwaypointlinks)
		{
			if(!botframe_loadedforcedlinks)
				waypoint_load_links_hardwired();
		}
		else
		{
			// TODO: Make this check cleaner
			IL_EACH(g_waypoints, time - it.nextthink > 10,
			{
				waypoint_save_links();
				break;
			});
		}
	}
	else
	{
		botframe_spawnedwaypoints = true;
		waypoint_loadall();
		if(!waypoint_load_links())
			waypoint_schedulerelinkall();
	}

	if (bot_list)
	{
		// cycle the goal token from one bot to the next each frame
		// (this prevents them from all doing spawnfunc_waypoint searches on the same
		//  frame, which causes choppy framerates)
		if (bot_strategytoken_taken)
		{
			bot_strategytoken_taken = false;
			if (bot_strategytoken)
				bot_strategytoken = bot_strategytoken.nextbot;
			if (!bot_strategytoken)
				bot_strategytoken = bot_list;
		}

		if (botframe_nextdangertime < time)
		{
			float interval;
			interval = autocvar_bot_ai_dangerdetectioninterval;
			if (botframe_nextdangertime < time - interval * 1.5)
				botframe_nextdangertime = time;
			botframe_nextdangertime = botframe_nextdangertime + interval;
			botframe_updatedangerousobjects(autocvar_bot_ai_dangerdetectionupdates);
		}
	}

	if (autocvar_g_waypointeditor)
		botframe_showwaypointlinks();

	if (autocvar_g_waypointeditor_auto)
		botframe_autowaypoints();

	if(time > bot_cvar_nextthink)
	{
		if(currentbots>0)
			bot_custom_weapon_priority_setup();
		bot_cvar_nextthink = time + 5;
	}
}
