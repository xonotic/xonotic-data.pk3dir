#include "bot.qh"

#include <common/constants.qh>
#include <common/mapinfo.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/physics/player.qh>
#include <common/stats.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>
#include <server/antilag.qh>
#include <server/bot/default/aim.qh>
#include <server/bot/default/cvars.qh>
#include <server/bot/default/havocbot/havocbot.qh>
#include <server/bot/default/havocbot/scripting.qh>
#include <server/bot/default/navigation.qh>
#include <server/bot/default/scripting.qh>
#include <server/bot/default/waypoints.qh>
#include <server/campaign.qh>
#include <server/client.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/mutators/_mod.qh>
#include <server/race.qh>
#include <server/scores_rules.qh>
#include <server/teamplay.qh>
#include <server/weapons/accuracy.qh>
#include <server/weapons/selection.qh>
#include <server/world.qh>
#include <server/command/vote.qh>

STATIC_INIT(bot) { bot_calculate_stepheightvec(); }

// TODO: remove this function! its only purpose is to update these fields since bot_setnameandstuff is called before ClientState
void bot_setclientfields(entity this)
{
	CS_CVAR(this).cvar_cl_accuracy_data_share = 1;  // share the bots weapon accuracy data with the world
	CS_CVAR(this).cvar_cl_accuracy_data_receive = 0;  // don't receive any weapon accuracy data
}

entity bot_spawn()
{
	entity bot = spawnclient();
	if (bot)
	{
		setItemGroupCount();
		currentbots = currentbots + 1;
		bot_setnameandstuff(bot);
		ClientConnect(bot);
		bot_setclientfields(bot);
		PutClientInServer(bot);
		if (!teamplay)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_JOIN_PLAY, bot.netname);
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

	// if bot skill is high enough don't limit their think frequency
	if (SUPERBOT)
		this.bot_nextthink = max(time, this.bot_nextthink) + 0.005;
	else
		this.bot_nextthink = max(time, this.bot_nextthink) + max(0.01, autocvar_bot_ai_thinkinterval * min(14 / (skill + this.bot_aiskill + 14), 1));

	if (!IS_PLAYER(this) || (autocvar_g_campaign && !campaign_bots_may_start))
	{
		CS(this).movement = '0 0 0';
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

	// if bot skill is high enough don't assign latency to them
	if (SUPERBOT)
		CS(this).ping = 0;
	else
	{
		// calculate an aiming latency based on the skill setting
		// (simulated network latency + naturally delayed reflexes)
		//this.ping = 0.7 - bound(0, 0.05 * skill, 0.5); // moved the reflexes to bot_aimdir (under the name 'think')
		// minimum ping 20+10 random
		CS(this).ping = bound(0,0.07 - bound(0, (skill + this.bot_pingskill) * 0.005,0.05)+random()*0.01,0.65); // Now holds real lag to server, and higher skill players take a less laggy server
		// skill 10 = ping 0.2 (adrenaline)
		// skill 0 = ping 0.7 (slightly drunk)
	}

	// clear buttons
	PHYS_INPUT_BUTTON_ATCK(this) = false;
	// keep jump button pressed for a short while, useful with ramp jumps
	PHYS_INPUT_BUTTON_JUMP(this) = (!IS_DEAD(this) && time < this.bot_jump_time + 0.2);
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
		CS(this).movement = '0 0 0';
		return;
	}

	// if dead, just wait until we can respawn
	if (IS_DEAD(this) || IS_OBSERVER(this))
	{
		if (bot_waypoint_queue_owner == this)
			bot_waypoint_queue_owner = NULL;
		this.aistatus = 0;
		CS(this).movement = '0 0 0';
		if (IS_OBSERVER(this))
			return;
		if (IS_DEAD(this))
		{
			if (!navigation_goalrating_timeout(this))
				navigation_goalrating_timeout_force(this);
			// jump must not be pressed for at least one frame in order for
			// PlayerThink to detect the key down event
			if (this.deadflag == DEAD_DYING)
				PHYS_INPUT_BUTTON_JUMP(this) = false;
			else if (this.deadflag == DEAD_DEAD)
				PHYS_INPUT_BUTTON_JUMP(this) = true; // press jump to respawn
		}
	}
	else if(this.aistatus & AI_STATUS_STUCK)
		navigation_unstuck(this);

	if (warmup_stage && !this.ready)
	{
		this.ready = true;
		ReadyCount(); // this must be delayed until the bot has spawned
	}

	// now call the current bot AI (havocbot for example)
	this.bot_ai(this);
}

void bot_setnameandstuff(entity this)
{
	string readfile, s;
	int file, tokens, prio;

	file = fopen(autocvar_bot_config_file, FILE_READ);

	if(file < 0)
	{
		LOG_INFOF("Error: Can not open the bot configuration file '%s'", autocvar_bot_config_file);
		readfile = "";
	}
	else
	{
		entity balance = TeamBalance_CheckAllowedTeams(NULL);
		TeamBalance_GetTeamCounts(balance, NULL);
		int smallest_team = -1;
		int smallest_count = -1;
		if (teamplay)
		{
			for (int i = 1; i <= AVAILABLE_TEAMS; ++i)
			{
				// NOTE if (autocvar_g_campaign && autocvar_g_campaign_forceteam == i)
				// TeamBalance_GetNumberOfPlayers(balance, i); returns the number of players + 1
				// since it keeps a spot for the real player in the desired team
				int count = TeamBalance_GetNumberOfPlayers(balance, i);
				if (smallest_count < 0 || count < smallest_count)
				{
					smallest_team = i;
					smallest_count = count;
				}
			}
		}
		TeamBalance_Destroy(balance);
		RandomSelection_Init();
		while((readfile = fgets(file)))
		{
			if(substring(readfile, 0, 2) == "//")
				continue;
			if(substring(readfile, 0, 1) == "#")
				continue;
			// NOTE if the line is empty tokenizebyseparator(readfile, "\t")
			// will create 1 empty token because there's no separator (bug?)
			if (readfile == "")
				continue;
			tokens = tokenizebyseparator(readfile, "\t");
			if(tokens == 0)
				continue;
			s = argv(0);
			prio = 0;
			bool conflict = false;
			FOREACH_CLIENT(IS_BOT_CLIENT(it), {
				if (s == it.cleanname)
				{
					conflict = true;
					break;
				}
			});
			if (!conflict)
				prio += 1;
			if (teamplay && !(autocvar_bot_vs_human && AVAILABLE_TEAMS == 2))
			{
				int forced_team = stof(argv(5));
				if (!Team_IsValidIndex(forced_team))
					forced_team = 0;
				if (!forced_team || forced_team == smallest_team)
					prio += 2;
			}
			RandomSelection_AddString(readfile, 1, prio);
		}
		readfile = RandomSelection_chosen_string;
		fclose(file);
	}

	string bot_name, bot_model, bot_skin, bot_shirt, bot_pants;

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

	if (teamplay && !(autocvar_bot_vs_human && AVAILABLE_TEAMS == 2))
	{
		this.bot_forced_team = stof(argv(5));
		if (!Team_IsValidIndex(this.bot_forced_team))
			this.bot_forced_team = 0;
	}
	else
		this.bot_forced_team = 0;

	prio = 6;

	#define READSKILL(f, w, r) MACRO_BEGIN \
		if(argv(prio) != "") \
			this.f = stof(argv(prio)) * w; \
		else \
			this.f = (!autocvar_g_campaign) * (2 * random() - 1) * r * w; \
		prio++; \
	MACRO_END
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

	// if bot skill is high enough don't limit their skill
	if (SUPERBOT)
	{
		// commented out means they're meaningless with this high skill
		// no reason to set them, uncomment if this changes
		//this.havocbot_keyboardskill = 10;
		//this.bot_moveskill = 10; //midair modifier sets this to 0 to disable bhop
		//this.bot_dodgeskill = 10;
		//this.bot_pingskill = 10;
		//this.bot_weaponskill = 10;
		//this.bot_aggresskill = 10;
		this.bot_rangepreference = 1; // no range preference modification
		//this.bot_aimskill = 10;
		//this.bot_offsetskill = 10;
		//this.bot_mouseskill = 10;
		//this.bot_thinkskill = 10;
		//this.bot_aiskill = 10;
	}
	if (file >= 0 && argv(prio) != "")
		LOG_INFOF("^1Warning^7: too many parameters for bot %s, please check format of %s", bot_name, autocvar_bot_config_file);

	this.bot_config_loaded = true;

	setcolor(this, stof(bot_shirt) * 16 + stof(bot_pants));
	this.team = -1; // undo team change by setcolor
	// save clientcolors now because they may be overriden when joining a team
	this.bot_preferredcolors = this.clientcolors;

	string prefix = (autocvar_g_campaign ? "" : autocvar_bot_prefix);
	string suffix = (autocvar_g_campaign ? "" : autocvar_bot_suffix);
	string name = (autocvar_bot_usemodelnames ? bot_model : bot_name);

	if (name == "")
	{
		name = ftos(etof(this));
		this.netname = this.netname_freeme = strzone(strcat(prefix, name, suffix));
	}
	else
	{
		// number bots with identical names
		int j = 0;
		FOREACH_CLIENT(IS_BOT_CLIENT(it), {
			if(it.cleanname == name)
				++j;
		});
		if (j)
			this.netname = this.netname_freeme = strzone(strcat(prefix, name, "(", ftos(j), ")", suffix));
		else
			this.netname = this.netname_freeme = strzone(strcat(prefix, name, suffix));
	}
	this.cleanname = strzone(name);

	// pick the model and skin
	if(substring(bot_model, -4, 1) != ".")
		bot_model = strcat(bot_model, ".iqm");
	this.playermodel = this.playermodel_freeme = strzone(strcat("models/player/", bot_model));
	this.playerskin = this.playerskin_freeme = strzone(bot_skin);
}

void bot_custom_weapon_priority_setup()
{
	static string bot_priority_far_prev;
	static string bot_priority_mid_prev;
	static string bot_priority_close_prev;
	static string bot_priority_distances_prev;
	float tokens, i, w;

	bot_custom_weapon = false;

	if(	autocvar_bot_ai_custom_weapon_priority_far == "" ||
		autocvar_bot_ai_custom_weapon_priority_mid == "" ||
		autocvar_bot_ai_custom_weapon_priority_close == "" ||
		autocvar_bot_ai_custom_weapon_priority_distances == ""
	)
		return;

	if (bot_priority_distances_prev != autocvar_bot_ai_custom_weapon_priority_distances)
	{
		strcpy(bot_priority_distances_prev, autocvar_bot_ai_custom_weapon_priority_distances);
		tokens = tokenizebyseparator(autocvar_bot_ai_custom_weapon_priority_distances," ");

		if (tokens!=2)
			return;

		bot_distance_far = stof(argv(0));
		bot_distance_close = stof(argv(1));

		if(bot_distance_far < bot_distance_close){
			bot_distance_far = stof(argv(1));
			bot_distance_close = stof(argv(0));
		}
	}

	int c;

	#define PARSE_WEAPON_PRIORITIES(dist) MACRO_BEGIN \
		if (bot_priority_##dist##_prev != autocvar_bot_ai_custom_weapon_priority_##dist) { \
			strcpy(bot_priority_##dist##_prev, autocvar_bot_ai_custom_weapon_priority_##dist); \
			tokens = tokenizebyseparator(W_NumberWeaponOrder(autocvar_bot_ai_custom_weapon_priority_##dist)," "); \
			bot_weapons_##dist[0] = -1; \
			c = 0; \
			for(i = 0; i < tokens && c < REGISTRY_COUNT(Weapons); ++i) { \
				w = stof(argv(i)); \
				if (w >= WEP_FIRST && w <= WEP_LAST) { \
					bot_weapons_##dist[c] = w; \
					++c; \
				} \
			} \
			if (c < REGISTRY_COUNT(Weapons)) \
				bot_weapons_##dist[c] = -1; \
		} \
	MACRO_END

	PARSE_WEAPON_PRIORITIES(far);
	PARSE_WEAPON_PRIORITIES(mid);
	PARSE_WEAPON_PRIORITIES(close);

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
			if (!IS_OBSERVER(it) && !bot_ispaused(it))
			{
				if(prevbot)
					prevbot.nextbot = it;
				else
					bot_list = it;
				prevbot = it;
			}
			++currentbots;
		}
	});
	if(prevbot)
		prevbot.nextbot = NULL;
	bot_strategytoken = bot_list;
	bot_strategytoken_taken = true;
}

void bot_clientdisconnect(entity this)
{
	if (!IS_BOT_CLIENT(this))
		return;
	bot_clearqueue(this);
	strfree(this.cleanname);
	strfree(this.netname_freeme);
	strfree(this.playermodel_freeme);
	strfree(this.playerskin_freeme);
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
	this.isbot = true;
	this.createdtime = this.bot_nextthink;

	if(!this.bot_config_loaded) // This is needed so team overrider doesn't break between matches
	{
		bot_setnameandstuff(this);
		bot_setclientfields(this);
	}

	havocbot_setupbot(this);
}

void bot_removefromlargestteam()
{
	entity balance = TeamBalance_CheckAllowedTeams(NULL);
	TeamBalance_GetTeamCounts(balance, NULL);

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

		if (Team_IsValidTeam(it.team))
		{
			thiscount = TeamBalance_GetNumberOfPlayers(balance,
				Team_TeamToIndex(it.team));
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
	TeamBalance_Destroy(balance);
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
	int bestbot = -1;
	int bestplayer = -1;
	FOREACH_CLIENT(IS_PLAYER(it), {
		if(IS_REAL_CLIENT(it))
			bestplayer = max(bestplayer, it.totalfrags - it.totalfrags_lastcheck);
		else
			bestbot = max(bestbot, it.totalfrags - it.totalfrags_lastcheck);
	});

	string msg = strcat("autoskill: best player got ", ftos(bestplayer), ", ""best bot got ", ftos(bestbot), "; ");
	if(bestbot < 0 || bestplayer < 0)
	{
		msg = strcat(msg, "not doing anything");
		// don't return, let it reset all counters below
	}
	else if(bestbot <= bestplayer * factor - 2)
	{
		if(autocvar_skill < 17)
		{
			msg = strcat(msg, "2 frags difference, increasing skill");
			cvar_set("skill", ftos(autocvar_skill + 1));
			bprint("^2BOT SKILL UP!^7 Now at level ", ftos(autocvar_skill), "\n");
		}
	}
	else if(bestbot >= bestplayer * factor + 2)
	{
		if(autocvar_skill > 0)
		{
			msg = strcat(msg, "2 frags difference, decreasing skill");
			cvar_set("skill", ftos(autocvar_skill - 1));
			bprint("^1BOT SKILL DOWN!^7 Now at level ", ftos(autocvar_skill), "\n");
		}
	}
	else
	{
		msg = strcat(msg, "not doing anything");
		return;
		// don't reset counters, wait for them to accumulate
	}
	LOG_DEBUG(msg);

	FOREACH_CLIENT(IS_PLAYER(it), { it.totalfrags_lastcheck = it.totalfrags; });
}

void bot_calculate_stepheightvec()
{
	stepheightvec = autocvar_sv_stepheight * '0 0 1';
	jumpheight_vec = (autocvar_sv_jumpvelocity ** 2) / (2 * autocvar_sv_gravity) * '0 0 1';
	jumpstepheightvec = stepheightvec + jumpheight_vec * 0.85; // reduce it a bit to make the jumps easy
	jumpheight_time = autocvar_sv_jumpvelocity / autocvar_sv_gravity;
}

bool bot_fixcount(bool multiple_per_frame)
{
	int activerealplayers = 0;
	int realplayers = 0;
	if (MUTATOR_CALLHOOK(Bot_FixCount, activerealplayers, realplayers)) {
		activerealplayers = M_ARGV(0, int);
		realplayers = M_ARGV(1, int);
	} else {
		FOREACH_CLIENT(IS_REAL_CLIENT(it), {
			if(IS_PLAYER(it))
				++activerealplayers;
			++realplayers;
		});
	}

	int bots;
	// But don't remove bots immediately on level change, as the real players
	// usually haven't rejoined yet
	bots_would_leave = 0;
	if (autocvar_bot_vs_human && AVAILABLE_TEAMS == 2)
		bots = min(ceil(fabs(autocvar_bot_vs_human) * activerealplayers), maxclients - realplayers);
	else if ((realplayers || autocvar_bot_join_empty || (currentbots > 0 && time < 5)))
	{
		int minplayers = max(0, floor(autocvar_minplayers));
		if (teamplay)
			minplayers = max(0, floor(autocvar_minplayers_per_team) * AVAILABLE_TEAMS);
		int minbots = max(0, floor(autocvar_bot_number));

		// add bots to reach minplayers if needed
		bots = max(minbots, minplayers - activerealplayers);
		// cap bots to the max players allowed by the server
		int player_limit = GetPlayerLimit();
		if(player_limit)
			bots = min(bots, max(player_limit - activerealplayers, 0));
		bots = min(bots, maxclients - realplayers);

		bots_would_leave = max(0, bots - minbots);
	}
	else
	{
		// if there are no players, remove bots
		bots = 0;
	}

	// only add one bot per frame to avoid utter chaos
	if(time > botframe_nextthink)
	{
		while (currentbots < bots)
		{
			if (bot_spawn() == NULL)
			{
				bprint("Can not add bot, server full.\n");
				return false;
			}
			if (!multiple_per_frame)
			{
				break;
			}
		}
		while (currentbots > bots && bots >= 0)
			bot_removenewest();
	}

	return true;
}

void bot_serverframe()
{
	if (intermission_running && currentbots > 0)
	{
		// after the end of the match all bots stay unless all human players disconnect
		int realplayers = 0;
		FOREACH_CLIENT(IS_REAL_CLIENT(it), { ++realplayers; });
		if (!realplayers)
		{
			FOREACH_CLIENT(IS_BOT_CLIENT(it), { dropclient(it); });
			currentbots = 0;
		}
		return;
	}

	if (game_stopped)
		return;

	// Added 0.5 to avoid possible addition + immediate removal of bots that would make them appear as
	// spectators in the scoreboard and never go away. This issue happens at time 2 if map is changed
	// with the gotomap command, minplayers is > 1 and human clients join as players very soon
	// either intentionally or automatically (sv_spectate 0)
	// A working workaround for this bug was implemented in commit fbd145044, see entcs_attach
	if (time < 2.5)
	{
		currentbots = -1;
		return;
	}

	if (currentbots == -1)
	{
		// count bots already in the server from the previous match
		currentbots = 0;
		FOREACH_CLIENT(IS_BOT_CLIENT(it), { ++currentbots; });
	}

	if(autocvar_skill != skill)
	{
		float wpcost_update = false;
		if(skill >= autocvar_bot_ai_bunnyhop_skilloffset && autocvar_skill < autocvar_bot_ai_bunnyhop_skilloffset)
			wpcost_update = true;
		if(skill < autocvar_bot_ai_bunnyhop_skilloffset && autocvar_skill >= autocvar_bot_ai_bunnyhop_skilloffset)
			wpcost_update = true;

		skill = autocvar_skill;
		if (wpcost_update)
			waypoint_updatecost_foralllinks();
	}

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
		if(!bot_fixcount(false))
			botframe_nextthink = time + 10;
	}

	if(botframe_spawnedwaypoints)
	{
		if(autocvar_waypoint_benchmark)
			localcmd("quit\n");
	}

	if (currentbots > 0 || waypointeditor_enabled || autocvar_g_waypointeditor_auto)
	if (botframe_spawnedwaypoints)
	{
		if(botframe_cachedwaypointlinks)
		{
			if(!botframe_loadedforcedlinks)
				waypoint_load_hardwiredlinks();
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
		waypoint_load_links();
	}

	if (bot_list)
	{
		// cycle the goal token from one bot to the next each frame
		// (this prevents them from all doing spawnfunc_waypoint searches on the same
		//  frame, which causes choppy framerates)
		if (bot_strategytoken_taken)
		{
			// give goal token to the first bot without goals; if all bots don't have
			// any goal (or are dead/frozen) simply give it to the next one
			bot_strategytoken_taken = false;
			entity bot_strategytoken_save = bot_strategytoken;
			while (true)
			{
				if (bot_strategytoken)
					bot_strategytoken = bot_strategytoken.nextbot;
				if (!bot_strategytoken)
					bot_strategytoken = bot_list;

				if (!(IS_DEAD(bot_strategytoken) || STAT(FROZEN, bot_strategytoken))
					&& !bot_strategytoken.goalcurrent)
					break;

				if (!bot_strategytoken_save) // break loop if all the bots are dead or frozen
					break;
				if (bot_strategytoken == bot_strategytoken_save)
					bot_strategytoken_save = NULL; // looped through all the bots
			}
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

	if (waypointeditor_enabled)
		botframe_showwaypointlinks();

	if (autocvar_g_waypointeditor_auto)
		botframe_autowaypoints();

	if (currentbots > 0)
		bot_custom_weapon_priority_setup();
}
