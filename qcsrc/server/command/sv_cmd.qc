#include "sv_cmd.qh"

#include <common/constants.qh>
#include <common/effects/all.qh>
#include <common/gametypes/_mod.qh>
#include <common/mapinfo.qh>
#include <common/monsters/sv_monsters.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <server/anticheat.qh>
#include <server/bot/api.qh>
#include <server/campaign.qh>
#include <server/client.qh>
#include <server/command/_mod.qh>
#include <server/command/banning.qh>
#include <server/command/cmd.qh>
#include <server/command/common.qh>
#include <server/command/getreplies.qh>
#include <server/command/radarmap.qh>
#include <server/intermission.qh>
#include <server/ipban.qh>
#include <server/mapvoting.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/scores_rules.qh>
#include <server/teamplay.qh>
#include <server/world.qh>

//  used by GameCommand_make_mapinfo()
void make_mapinfo_Think(entity this)
{
	if (_MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 0, 1))
	{
		LOG_INFO("Done rebuiling mapinfos.");
		MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		delete(this);
	}
	else
	{
		setthink(this, make_mapinfo_Think);
		this.nextthink = time;
	}
}

//  used by GameCommand_extendmatchtime() and GameCommand_reducematchtime()
void changematchtime(float delta, float mi, float ma)
{
	float cur;
	float update;
	float lim;

	if (delta == 0) return;
	if (autocvar_timelimit < 0) return;

	if (mi <= 10) mi = 10;  // at least ten sec in the future
	cur = time - game_starttime;
	if (cur > 0) mi += cur; // from current time!

	lim = autocvar_timelimit * 60;

	if (delta > 0)
	{
		if (lim == 0) return; // cannot increase any further
		else if (lim < ma) update = min(ma, lim + delta);
		else                  // already above maximum: FAIL
			return;
	}
	else
	{
		if (lim == 0)      // infinite: try reducing to max, if we are allowed to
			update = max(mi, ma);
		else if (lim > mi) // above minimum: decrease
			update = max(mi, lim + delta);
		else               // already below minimum: FAIL
			return;
	}

	cvar_set("timelimit", ftos(update / 60));
}


// =======================
//  Command Sub-Functions
// =======================

void GameCommand_adminmsg(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			entity client;
			float accepted;

			string targets = strreplace(",", " ", argv(1));
			string original_targets = strreplace(" ", ", ", targets);
			string admin_message = argv(2);
			float infobartime = stof(argv(3));

			string successful, t;
			successful = string_null;

			if ((targets) && (admin_message))
			{
				for ( ; targets; )
				{
					t = car(targets);
					targets = cdr(targets);

					// Check to see if the player is a valid target
					client = GetFilteredEntity(t);
					accepted = VerifyClientEntity(client, true, false);

					if (accepted <= 0)
					{
						LOG_INFO("adminmsg: ", GetClientErrorString(accepted, t), (targets ? ", skipping to next player.\n" : "."));
						continue;
					}

					// send the centerprint/console print or infomessage
					if (infobartime)
					{
						stuffcmd(client, sprintf("\ninfobar %f \"%s\"\n", infobartime, MakeConsoleSafe(admin_message)));
					}
					else
					{
						centerprint(client, strcat("^3", GetCallerName(NULL), ":\n^7", admin_message));
						sprint(client, strcat("\{1}\{13}^3", GetCallerName(NULL), "^7: ", admin_message, "\n"));
					}

					successful = strcat(successful, (successful ? ", " : ""), playername(client.netname, client.team, false));
					LOG_TRACE("Message sent to ", playername(client.netname, client.team, false));
					continue;
				}

				if (successful) bprint("Successfully sent message '", admin_message, "' to ", successful, ".\n");
				else LOG_INFO("No players given (", original_targets, ") could receive the message.");

				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd adminmsg <clients> \"<message>\" [<infobartime>]");
			LOG_HELP("  <clients> is a list (separated by commas) of player entity ID's or nicknames");
			LOG_HELP("  If <infobartime> is provided, the message will be sent to infobar.");
			LOG_HELP("  Otherwise, it will just be sent as a centerprint message.");
			LOG_HELP("Examples: adminmsg 2,4 \"this infomessage will last for ten seconds\" 10");
			LOG_HELP("          adminmsg 2,5 \"this message will be a centerprint\"");
			return;
		}
	}
}

void GameCommand_allready(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			if(warmup_stage)
			{
				ReadyRestart(true);
			}
			else
				LOG_INFO("Not in warmup.");

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd allready");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}

void GameCommand_allspec(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			string reason = argv(1);
			int n = 0;
			FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), {
				PutObserverInServer(it, true, true);
				++n;
			});
			if (n)   bprint(strcat("Successfully forced all (", ftos(n), ") players to spectate", (reason ? strcat(" for reason: '", reason, "'") : ""), ".\n"));
			else   LOG_INFO("No players found to spectate.");
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd allspec [<reason>]");
			LOG_HELP("  Where <reason> is an optional argument for explanation of allspec command.");
			LOG_HELP("See also: ^2moveplayer, shuffleteams^7");
			return;
		}
	}
}

void GameCommand_anticheat(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			entity client = GetIndexedEntity(argc, 1);
			float accepted = VerifyClientEntity(client, false, false);

			if (accepted > 0)
			{
				anticheat_report_to_eventlog(client);
				return;
			}
			else
			{
				LOG_INFO("anticheat: ", GetClientErrorString(accepted, argv(1)), ".");
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd anticheat <client>");
			LOG_HELP("  <client> is the entity number or name of the player.");
			return;
		}
	}
}

void GameCommand_bbox(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			vector size_min = '0 0 0';
			vector size_max = '0 0 0';
			tracebox('1 0 0' * world.absmin.x,
				'0 1 0' * world.absmin.y + '0 0 1' * world.absmin.z,
				'0 1 0' * world.absmax.y + '0 0 1' * world.absmax.z,
				'1 0 0' * world.absmax.x,
				MOVE_WORLDONLY,
				NULL);
			size_min.x = (trace_startsolid) ? world.absmin.x : trace_endpos.x;

			tracebox('0 1 0' * world.absmin.y,
				'1 0 0' * world.absmin.x + '0 0 1' * world.absmin.z,
				'1 0 0' * world.absmax.x + '0 0 1' * world.absmax.z,
				'0 1 0' * world.absmax.y,
				MOVE_WORLDONLY,
				NULL);
			size_min.y = (trace_startsolid) ? world.absmin.y : trace_endpos.y;

			tracebox('0 0 1' * world.absmin.z,
				'1 0 0' * world.absmin.x + '0 1 0' * world.absmin.y,
				'1 0 0' * world.absmax.x + '0 1 0' * world.absmax.y,
				'0 0 1' * world.absmax.z,
				MOVE_WORLDONLY,
				NULL);
			size_min.z = (trace_startsolid) ? world.absmin.z : trace_endpos.z;

			tracebox('1 0 0' * world.absmax.x,
				'0 1 0' * world.absmin.y + '0 0 1' * world.absmin.z,
				'0 1 0' * world.absmax.y + '0 0 1' * world.absmax.z,
				'1 0 0' * world.absmin.x,
				MOVE_WORLDONLY,
				NULL);
			size_max.x = (trace_startsolid) ? world.absmax.x : trace_endpos.x;

			tracebox('0 1 0' * world.absmax.y,
				'1 0 0' * world.absmin.x + '0 0 1' * world.absmin.z,
				'1 0 0' * world.absmax.x + '0 0 1' * world.absmax.z,
				'0 1 0' * world.absmin.y,
				MOVE_WORLDONLY,
				NULL);
			size_max.y = (trace_startsolid) ? world.absmax.y : trace_endpos.y;

			tracebox('0 0 1' * world.absmax.z,
				'1 0 0' * world.absmin.x + '0 1 0' * world.absmin.y,
				'1 0 0' * world.absmax.x + '0 1 0' * world.absmax.y,
				'0 0 1' * world.absmin.z,
				MOVE_WORLDONLY,
				NULL);
			size_max.z = (trace_startsolid) ? world.absmax.z : trace_endpos.z;

			LOG_INFOF("Original size: %v %v", world.absmin, world.absmax);
			LOG_INFOF("Currently set size: %v %v", world.mins, world.maxs);
			LOG_INFOF("Solid bounding box size: %v %v", size_min, size_max);
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd bbox");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2gettaginfo, trace^7");
			return;
		}
	}
}

void GameCommand_bot_cmd(int request, int argc, string command)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			entity bot;

			if (argv(1) == "reset")
			{
				bot_resetqueues();
				return;
			}
			else if (argv(1) == "setbots")
			{
				cvar_settemp("bot_vs_human", "0");
				cvar_settemp("minplayers", "0");
				cvar_settemp("minplayers_per_team", "0");
				cvar_settemp("bot_number", "0");
				bot_fixcount(false);  // Kill all bots.
				cvar_settemp("bot_number", argv(2));
				if (!bot_fixcount(true)) LOG_INFO("Sorry, could not set requested bot count");
				return;
			}
			else if (argv(1) == "load" && argc == 3)
			{
				float fh, i;
				string s;
				fh = fopen(argv(2), FILE_READ);
				if (fh < 0)
				{
					LOG_INFO("cannot open the file");
					return;
				}

				i = 0;
				while ((s = fgets(fh)))
				{
					argc = tokenize_console(s);

					if (argc >= 3 && argv(0) == "sv_cmd" && argv(1) == "bot_cmd")
					{
						if (argv(2) == "reset")
						{
							bot_resetqueues();
						}
						else if (argv(2) == "setbots")
						{
							cvar_settemp("bot_vs_human", "0");
							cvar_settemp("minplayers", "0");
							cvar_settemp("minplayers_per_team", "0");
							cvar_settemp("bot_number", "0");
							bot_fixcount(false);  // Kill all bots.
							cvar_settemp("bot_number", argv(3));
							if (!bot_fixcount(true)) LOG_INFO("Sorry, could not set requested bot count");
						}
						else
						{
							if(argv(2) == "*" || argv(2) == "all")
								FOREACH_CLIENT(IS_BOT_CLIENT(it), {
									bot_queuecommand(it, substring(s, argv_start_index(3), -1));
								});
							else
							{
								bot = find_bot_by_number(stof(argv(2)));
								if (bot == NULL) bot = find_bot_by_name(argv(2));
								if (bot) bot_queuecommand(bot, substring(s, argv_start_index(3), -1));
							}
						}
					}
					else
					{
						localcmd(strcat(s, "\n"));
					}

					++i;
				}
				LOG_INFO(ftos(i), " commands read");
				fclose(fh);
				return;
			}
			else if (argv(1) == "help")
			{
				if (argv(2)) bot_cmdhelp(argv(2));
				else bot_list_commands();
				return;
			}
			else if (argc >= 3)  // this comes last
			{
				if(argv(1) == "*" || argv(1) == "all")
				{
					int bot_num = 0;
					FOREACH_CLIENT(IS_BOT_CLIENT(it), {
						bot_queuecommand(it, substring(command, argv_start_index(2), -1));
						bot_num++;
					});
					if(bot_num)
						LOG_INFO("Command '", substring(command, argv_start_index(2), -1), "' sent to all bots (", ftos(bot_num), ")");
					return;
				}
				else
				{
					bot = find_bot_by_number(stof(argv(1)));
					if (bot == NULL) bot = find_bot_by_name(argv(1));
					if (bot)
					{
						LOG_INFO("Command '", substring(command, argv_start_index(2), -1), "' sent to bot ", bot.netname);
						bot_queuecommand(bot, substring(command, argv_start_index(2), -1));
						return;
					}
					else
					{
						LOG_INFO("Error: Can't find bot with the name or id '", argv(1), "' - Did you mistype the command?");  // don't return so that usage is shown
					}
				}
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd bot_cmd <client> <command> [<arguments>]");
			LOG_HELP("  <client> can be either the name of the bot or a progressive number (not the entity number!)");
			LOG_HELP("           can also be '*' or 'all' to allow sending the command to all the bots");
			LOG_HELP("  For full list of commands, see bot_cmd help [<command>].");
			LOG_HELP("Examples: sv_cmd bot_cmd 1 cc say something");
			LOG_HELP("          sv_cmd bot_cmd 1 presskey jump");
			LOG_HELP("          sv_cmd bot_cmd * pause");
			return;
		}
	}
}

void GameCommand_cointoss(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			string result1 = (argv(2) ? strcat("^7", argv(1)) : "^1HEADS");
			string result2 = (argv(2) ? strcat("^7", argv(2)) : "^4TAILS");
			string choice = ((random() > 0.5) ? result1 : result2);

			Send_Notification(NOTIF_ALL, NULL, MSG_MULTI, MULTI_COINTOSS, choice);
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd cointoss [<result1> <result2>]");
			LOG_HELP("  Where <result1> and <result2> are user created options.");
			return;
		}
	}
}

void GameCommand_database(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc == 3)
			{
				if (argv(1) == "save")
				{
					db_save(ServerProgsDB, argv(2));
					LOG_INFO("Copied serverprogs database to '", argv(2), "' in the data directory.");
					return;
				}
				else if (argv(1) == "dump")
				{
					db_dump(ServerProgsDB, argv(2));
					LOG_INFO("DB dumped.");  // wtf does this do?
					return;
				}
				else if (argv(1) == "load")
				{
					db_close(ServerProgsDB);
					ServerProgsDB = db_load(argv(2));
					LOG_INFO("Loaded '", argv(2), "' as new serverprogs database.");
					return;
				}
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd database <action> <filename>");
			LOG_HELP("  Where <action> is the command to complete,");
			LOG_HELP("  and <filename> is what it acts upon.");
			LOG_HELP("  Full list of commands here: save, dump, load.");
			return;
		}
	}
}

void GameCommand_defer_clear(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			entity client;
			float accepted;

			if (argc >= 2)
			{
				client = GetIndexedEntity(argc, 1);
				accepted = VerifyClientEntity(client, true, false);

				if (accepted > 0)
				{
					stuffcmd(client, "defer clear\n");
					LOG_INFO("defer clear stuffed to ", playername(client.netname, client.team, false));
				}
				else { LOG_INFO("defer_clear: ", GetClientErrorString(accepted, argv(1)), "."); }

				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd defer_clear <client>");
			LOG_HELP("  <client> is the entity number or name of the player.");
			LOG_HELP("See also: ^2defer_clear_all^7");
			return;
		}
	}
}

void GameCommand_defer_clear_all(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			int n = 0;
			int argc;

			FOREACH_CLIENT(true, {
				argc = tokenize_console(strcat("defer_clear ", ftos(etof(it))));
				GameCommand_defer_clear(CMD_REQUEST_COMMAND, argc);
				++n;
			});
			if (n)   LOG_INFO("Successfully stuffed defer clear to all clients (", ftos(n), ")");  // should a message be added if no players were found?
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd defer_clear_all");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2defer_clear^7");
			return;
		}
	}
}

void GameCommand_delrec(int request, int argc)  // perhaps merge later with records and printstats and such?
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1))
			{
				if (argv(2)) race_deleteTime(argv(2), stof(argv(1)));
				else race_deleteTime(GetMapname(), stof(argv(1)));
				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd delrec <ranking> [<map>]");
			LOG_HELP("  <ranking> is which ranking level to clear up to, ");
			LOG_HELP("  it will clear all records up to nth place.");
			LOG_HELP("  if <map> is not provided it will use current map.");
			return;
		}
	}
}

void print_Effect_Index(int d, string effect_name)
{ 
	// this is inside a function to avoid expanding it on compilation everytime
	LOG_INFO("effect ", effect_name, " is ", ftos(_particleeffectnum(effect_name)), "\n");
	db_put(d, effect_name, "1");
}

void GameCommand_effectindexdump(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float fh, d;
			string s;

			d = db_create();
			LOG_INFO("begin of effects list");

			print_Effect_Index(d, "TE_GUNSHOT");
			print_Effect_Index(d, "TE_GUNSHOTQUAD");
			print_Effect_Index(d, "TE_SPIKE");
			print_Effect_Index(d, "TE_SPIKEQUAD");
			print_Effect_Index(d, "TE_SUPERSPIKE");
			print_Effect_Index(d, "TE_SUPERSPIKEQUAD");
			print_Effect_Index(d, "TE_WIZSPIKE");
			print_Effect_Index(d, "TE_KNIGHTSPIKE");
			print_Effect_Index(d, "TE_EXPLOSION");
			print_Effect_Index(d, "TE_EXPLOSIONQUAD");
			print_Effect_Index(d, "TE_TAREXPLOSION");
			print_Effect_Index(d, "TE_TELEPORT");
			print_Effect_Index(d, "TE_LAVASPLASH");
			print_Effect_Index(d, "TE_SMALLFLASH");
			print_Effect_Index(d, "TE_FLAMEJET");
			print_Effect_Index(d, "EF_FLAME");
			print_Effect_Index(d, "TE_BLOOD");
			print_Effect_Index(d, "TE_SPARK");
			print_Effect_Index(d, "TE_PLASMABURN");
			print_Effect_Index(d, "TE_TEI_G3");
			print_Effect_Index(d, "TE_TEI_SMOKE");
			print_Effect_Index(d, "TE_TEI_BIGEXPLOSION");
			print_Effect_Index(d, "TE_TEI_PLASMAHIT");
			print_Effect_Index(d, "EF_STARDUST");
			print_Effect_Index(d, "TR_ROCKET");
			print_Effect_Index(d, "TR_GRENADE");
			print_Effect_Index(d, "TR_BLOOD");
			print_Effect_Index(d, "TR_WIZSPIKE");
			print_Effect_Index(d, "TR_SLIGHTBLOOD");
			print_Effect_Index(d, "TR_KNIGHTSPIKE");
			print_Effect_Index(d, "TR_VORESPIKE");
			print_Effect_Index(d, "TR_NEHAHRASMOKE");
			print_Effect_Index(d, "TR_NEXUIZPLASMA");
			print_Effect_Index(d, "TR_GLOWTRAIL");
			print_Effect_Index(d, "TR_SEEKER");
			print_Effect_Index(d, "SVC_PARTICLE");

			fh = fopen("effectinfo.txt", FILE_READ);
			while ((s = fgets(fh)))
			{
				tokenize_console(s);
				if (argv(0) == "effect")
				{
					if (db_get(d, argv(1)) != "1")
					{
						int i = _particleeffectnum(argv(1));
						if (i >= 0) LOG_INFO("effect ", argv(1), " is ", ftos(i));
						db_put(d, argv(1), "1");
					}
				}
			}
			LOG_INFO("end of effects list");

			db_close(d);
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd effectindexdump");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}

void GameCommand_extendmatchtime(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			changematchtime(autocvar_timelimit_increment * 60, autocvar_timelimit_min * 60, autocvar_timelimit_max * 60);
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd extendmatchtime");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2reducematchtime^7");
			return;
		}
	}
}

void GameCommand_gametype(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			if (argv(1) != "")
			{
				string s = argv(1);
				Gametype t = MapInfo_Type_FromString(s, false, false);

				if (t)
				{
					// don't execute gametype hooks because they can change active
					// gametype rules if executed during the game
					GameTypeVote_SetGametype(t, "", false);
				}
				else
					bprint("Failed to switch to ", s, ": this gametype does not exist!\n");

				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd gametype <mode>");
			LOG_HELP("  Where <mode> is the gametype mode to switch to.");
			LOG_HELP("See also: ^2gotomap^7");
			return;
		}
	}
}

void GameCommand_gettaginfo(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			entity tmp_entity;
			float i;
			vector v;

			if (argc >= 4)
			{
				tmp_entity = spawn();
				if (argv(1) == "w")
				{
					.entity weaponentity = weaponentities[0];
					_setmodel(tmp_entity, (nextent(NULL)).(weaponentity).model);
				}
				else
				{
					precache_model(argv(1));
					_setmodel(tmp_entity, argv(1));
				}
				tmp_entity.frame = stof(argv(2));
				if (substring(argv(3), 0, 1) == "#") i = stof(substring(argv(3), 1, -1));
				else i = gettagindex(tmp_entity, argv(3));
				if (i)
				{
					v = gettaginfo(tmp_entity, i);
					LOG_HELPF("model %s frame %s tag %s index %s parent %s",
						tmp_entity.model, ftos(tmp_entity.frame), gettaginfo_name, ftos(i), ftos(gettaginfo_parent)
					);
					LOG_HELPF(" vector = %s %s %s", ftos(v.x), ftos(v.y), ftos(v.z));
					LOG_HELPF(" offset = %s %s %s", ftos(gettaginfo_offset.x), ftos(gettaginfo_offset.y), ftos(gettaginfo_offset.z));
					LOG_HELPF(" forward = %s %s %s", ftos(gettaginfo_forward.x), ftos(gettaginfo_forward.y), ftos(gettaginfo_forward.z));
					LOG_HELPF(" right = %s %s %s", ftos(gettaginfo_right.x), ftos(gettaginfo_right.y), ftos(gettaginfo_right.z));
					LOG_HELPF(" up = %s %s %s", ftos(gettaginfo_up.x), ftos(gettaginfo_up.y), ftos(gettaginfo_up.z));
					if (argc >= 6)
					{
						v.y = -v.y;
						localcmd(strcat(argv(4), vtos(v), argv(5), "\n"));
					}
				}
				else
				{
					LOG_INFO("bone not found");
				}

				delete(tmp_entity);
				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd gettaginfo <model> <frame> <index> [<command1>] [<command2>]");
			LOG_HELP("See also: ^2bbox, trace^7");
			return;
		}
	}
}

void GameCommand_animbench(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			entity tmp_entity;

			if (argc >= 4)
			{
				tmp_entity = spawn();
				if (argv(1) == "w")
				{
					.entity weaponentity = weaponentities[0];
					_setmodel(tmp_entity, (nextent(NULL)).(weaponentity).model);
				}
				else
				{
					precache_model(argv(1));
					_setmodel(tmp_entity, argv(1));
				}
				float f1 = stof(argv(2));
				float f2 = stof(argv(3));
				float t0;
				float t1 = 0;
				float t2 = 0;
				float n = 0;

				while (t1 + t2 < 1)
				{
					tmp_entity.frame = f1;
					t0 = gettime(GETTIME_HIRES);
					getsurfacepoint(tmp_entity, 0, 0);
					t1 += gettime(GETTIME_HIRES) - t0;
					tmp_entity.frame = f2;
					t0 = gettime(GETTIME_HIRES);
					getsurfacepoint(tmp_entity, 0, 0);
					t2 += gettime(GETTIME_HIRES) - t0;
					n += 1;
				}
				LOG_INFO("model ", tmp_entity.model, " frame ", ftos(f1), " animtime ", ftos(n / t1), "/s");
				LOG_INFO("model ", tmp_entity.model, " frame ", ftos(f2), " animtime ", ftos(n / t2), "/s");

				delete(tmp_entity);
				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd animbench <model> <frame1> <frame2>");
			LOG_HELP("See also: ^2bbox, trace^7");
			return;
		}
	}
}

void GameCommand_gotomap(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			if (argv(1))
			{
				LOG_INFO(GotoMap(argv(1)));
				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd gotomap <map>");
			LOG_HELP("  Where <map> is the *.bsp file to change to.");
			LOG_HELP("See also: ^2gametype^7");
			return;
		}
	}
}

void GameCommand_lockteams(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			if (teamplay)
			{
				lockteams = 1;
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_TEAMS_LOCKED);
				// nobody can join or change teams now so remove everyone from the queue
				FOREACH_CLIENT(it.wants_join, it.wants_join = it.team_selected = 0);
			}
			else
			{
				bprint("lockteams command can only be used in a team-based gametype.\n");
			}
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd lockteams");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2unlockteams^7");
			return;
		}
	}
}

void GameCommand_make_mapinfo(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			entity tmp_entity;

			tmp_entity = new(make_mapinfo);
			setthink(tmp_entity, make_mapinfo_Think);
			tmp_entity.nextthink = time;
			MapInfo_Enumerate();
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd make_mapinfo");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2radarmap^7");
			return;
		}
	}
}

void GameCommand_moveplayer(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			float accepted;
			entity client;

			string targets = strreplace(",", " ", argv(1));
			string original_targets = strreplace(" ", ", ", targets);
			string destination = argv(2);
			if (destination == "spec")
				destination = "spectator";

			if ((targets) && (destination))
			{
				string successful = string_null;
				string t;
				for ( ; targets; )
				{
					t = car(targets);
					targets = cdr(targets);

					// Check to see if the player is a valid target
					client = GetFilteredEntity(t);
					accepted = VerifyClientEntity(client, false, false);
					string client_num_str = ftos(etof(client));

					if (accepted <= 0)
					{
						LOG_INFO("moveplayer: ", GetClientErrorString(accepted, t), ".");
					}
					else if (destination == "spectator")
					{
						string pl_name = playername(client.netname, client.team, false);
						if (!(IS_SPEC(client) || IS_OBSERVER(client)) || INGAME(client))
						{
							PutObserverInServer(client, true, true);

							successful = strcat(successful, (successful ? ", " : ""), pl_name);
						}
						else
						{
							LOG_INFO("Player #", client_num_str, " (", pl_name, ") is already spectating.");
						}
					}
					else
					{
						if (!teamplay)
						{
							LOG_INFO("Can't change teams when currently not playing a team game.");
							return;
						}

						string pl_name = playername(client.netname, client.team, false);
						if (IS_SPEC(client) || IS_OBSERVER(client))
						{
							// well technically we could, but should we allow that? :P
							LOG_INFO("Player #", client_num_str, " (", pl_name, ") is not in the game.");
							continue;
						}

						// set up
						int save = Player_GetForcedTeamIndex(client);
						Player_SetForcedTeamIndex(client, TEAM_FORCE_DEFAULT);

						// find the team to move the player to
						int team_num = Team_ColorToTeam(destination);
						entity balance;
						if (team_num == client.team)  // already on the destination team
						{
							// keep the forcing undone
							LOG_INFO("Player #", client_num_str, " (", pl_name, ") is already on the ",
								Team_ColoredFullName(team_num), ".");
							continue;
						}
						else if (team_num == 0)  // auto team
						{
							balance = TeamBalance_CheckAllowedTeams(client);
							team_num = Team_IndexToTeam(TeamBalance_FindBestTeam(balance, client, false));
						}
						else
						{
							balance = TeamBalance_CheckAllowedTeams(client);
						}
						Player_SetForcedTeamIndex(client, save);

						// Check to see if the destination team is even available
						int team_id = Team_TeamToIndex(team_num);
						if (team_id == -1)
						{
							LOG_INFO("Can't move player to ", destination, " team because it doesn't exist.");
							TeamBalance_Destroy(balance);
							return;
						}
						if (!IsTeamAvailable(team_num))
						{
							LOG_INFO("Can't move player to ", destination, " team because it isn't available.");
							TeamBalance_Destroy(balance);
							return;
						}
						if (!TeamBalance_IsTeamAllowed(balance, team_id))
						{
							LOG_INFO("Player #", client_num_str, " (", pl_name, ") is not allowed to join the ",
								Team_ColoredFullName(team_num), ".");
							TeamBalance_Destroy(balance);
							continue;
						}
						TeamBalance_Destroy(balance);

						// If so, lets continue and finally move the player
						Player_SetForcedTeamIndex(client, TEAM_FORCE_DEFAULT);
						if (MoveToTeam(client, team_id, 6))
						{
							successful = strcat(successful, (successful ? ", " : ""), pl_name);
							LOG_INFO("Player #", client_num_str, " (", pl_name, ") has been moved to the ",
								Team_ColoredFullName(team_num), ".");
						}
						else
						{
							LOG_INFO("Unable to move player #", client_num_str, " (", pl_name, ")");
						}
					}
				} // loop end

				if (successful) bprint("Successfully moved players ", successful, " to destination ", destination, ".\n");
				else LOG_INFO("No players given (", original_targets, ") are able to move.");

				return;  // still correct parameters so return to avoid usage print
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd moveplayer <clients> <destination>");
			LOG_HELP("  <clients> is a list (separated by commas) of player entity ID's or nicknames");
			LOG_HELP("  <destination> is what to send the player to, be it team or spectating");
			LOG_HELP("  Full list of destinations here: spec, spectator, red, blue, yellow, pink, auto.");
			LOG_HELP("Examples: sv_cmd moveplayer 1,3,5 red");
			LOG_HELP("          sv_cmd moveplayer 2 spec");
			LOG_HELP("See also: ^2allspec, shuffleteams^7");
			return;
		}
	}
}

void GameCommand_nextmap(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc >= 2) // nextmap with mapname arg
			{
				if (argc > 2)
					LOG_HELP("Warning: nextmap only takes 1 argument");

				string map = ValidateMap(argv(1), NULL);
				if (map != "" && map != get_nextmap())
					Set_NextMap(map);
			}
			else // nextmap without args
			{
				if (get_nextmap() != "")
					LOG_HELP(get_nextmap());
				else
					LOG_HELP("none");
			}
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd nextmap [<mapname>]");
			LOG_HELP("  Without arguments it prints current nextmap if one is set");
			LOG_HELP("  With arguments it attempts to set nextmap");
			return;
		}
	}
}

void GameCommand_nospectators(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			cvar_settemp("sv_spectate", "0");
			// if sv_spectate was enabled PlayerFrame() sends SPECTATE_WARNING notifications
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd nospectators");
			LOG_HELP("  No arguments required.");
			LOG_HELP("Temporarily disables the ^3sv_spectate ^7cvar.");
			return;
		}
	}
}

void GameCommand_printstats(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			DumpStats(false);
			LOG_INFO("stats dumped.");
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd printstats");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}

void GameCommand_radarmap(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (RadarMap_Make(argc)) return;
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd radarmap [--force] [--loop] [--quit] [--block | --trace | --sample | --lineblock] [--sharpen N] [--res W H] [--qual Q]");
			LOG_HELP("  The quality factor Q is roughly proportional to the time taken.");
			LOG_HELP("  trace supports no quality factor; its result should look like --block with infinite quality factor.");
			LOG_HELP("See also: ^2make_mapinfo^7");
			return;
		}
	}
}

void GameCommand_reducematchtime(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			changematchtime(autocvar_timelimit_decrement * -60, autocvar_timelimit_min * 60, autocvar_timelimit_max * 60);
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd reducematchtime");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2extendmatchtime^7");
			return;
		}
	}
}

void GameCommand_setbots(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc >= 2)
			{
				cvar_settemp("minplayers", "0");
				cvar_settemp("minplayers_per_team", "0");
				cvar_settemp("bot_number", argv(1));
				bot_fixcount(true);
				return;
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd setbots <botnumber>");
			LOG_HELP("  Where <botnumber> is the amount of bots to set bot_number cvar to.");
			LOG_HELP("See also: ^2bot_cmd^7");
			return;
		}
	}
}

void shuffleteams()
{
	if (!teamplay)
	{
		LOG_INFO("Can't shuffle teams when currently not playing a team game.");
		return;
	}

	FOREACH_CLIENT(IS_PLAYER(it) || INGAME(it), {
		if (Player_HasRealForcedTeam(it)) {
			// we could theoretically assign forced players to their teams
			// and shuffle the rest to fill the empty spots but in practise
			// either all players or none are gonna have forced teams
			LOG_INFO("Can't shuffle teams because at least one player has a forced team.");
			return;
		}
	});

	int number_of_teams = 0;
	entity balance = TeamBalance_CheckAllowedTeams(NULL);
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (TeamBalance_IsTeamAllowed(balance, i))
		{
			number_of_teams = max(i, number_of_teams);
		}
	}
	TeamBalance_Destroy(balance);

	int team_index = 0;
	FOREACH_CLIENT_RANDOM(IS_PLAYER(it) || INGAME(it), {
		int target_team_index = team_index + 1;
		if (Entity_GetTeamIndex(it) != target_team_index)
		{
			MoveToTeam(it, target_team_index, 6);
		}
		team_index = (team_index + 1) % number_of_teams;
	});

	bprint("Successfully shuffled the players around randomly.\n");
}

void GameCommand_shuffleteams(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			if (shuffleteams_on_reset_map)
			{
				bprint("Players will be shuffled when this round is over.\n");
				shuffleteams_on_reset_map = true;
			}
			else
				shuffleteams();
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd shuffleteams");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2moveplayer, allspec^7");
			return;
		}
	}
}

void GameCommand_resetmatch(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			ReadyRestart(false);
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd resetmatch");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}

void GameCommand_stuffto(int request, int argc)
{
	// This... is a fairly dangerous and powerful command... - It allows any arguments to be sent to a client via rcon.
	// Because of this, it is disabled by default and must be enabled by the server owner when doing compilation. That way,
	// we can be certain they understand the risks of it... So to enable, compile server with -DSTUFFTO_ENABLED argument.

#ifdef STUFFTO_ENABLED
		switch (request)
		{
			case CMD_REQUEST_COMMAND:
			{
				if (!world_initialized)
				{
					LOG_HELPF("This command works only when the server is running.");
					return;
				}
				if (argv(2))
				{
					entity client = GetIndexedEntity(argc, 1);
					float accepted = VerifyClientEntity(client, true, false);

					if (accepted > 0)
					{
						stuffcmd(client, strcat("\n", argv(next_token), "\n"));
						LOG_INFO("Command: \"", argv(next_token), "\" sent to ", GetCallerName(client), " (", argv(1), ").");
					}
					else
					{
						LOG_INFO("stuffto: ", GetClientErrorString(accepted, argv(1)), ".");
					}

					return;
				}
			}

			default:
				LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
			case CMD_REQUEST_USAGE:
			{
				LOG_HELP("Usage:^3 sv_cmd stuffto <client> \"<command>\"");
				LOG_HELP("  <client> is the entity number or name of the player,");
				LOG_HELP("  and <command> is the command to be sent to that player.");
				return;
			}
		}
#else
		if (request)
		{
			LOG_HELP("stuffto command is not enabled on this server.");
			return;
		}
#endif
}

void GameCommand_trace(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			entity e;
			vector org, delta, start, end, p, q, q0, pos, vv, dv;
			float i, f, safe, unsafe, dq, dqf;

			switch (argv(1))
			{
				case "debug":
				{
					float hitcount = 0;
					LOG_INFO("TEST CASE. If this returns the runaway loop counter error, possibly everything is oaky.");
					float worst_endpos_bug = 0;
					for ( ; ; )
					{
						org = world.mins;
						delta = world.maxs - world.mins;

						start.x = org.x + random() * delta.x;
						start.y = org.y + random() * delta.y;
						start.z = org.z + random() * delta.z;

						end.x = org.x + random() * delta.x;
						end.y = org.y + random() * delta.y;
						end.z = org.z + random() * delta.z;

						start = stov(vtos(start));
						end = stov(vtos(end));

						tracebox(start, PL_MIN_CONST, PL_MAX_CONST, end, MOVE_NOMONSTERS, NULL);
						if (!trace_startsolid && trace_fraction < 1)
						{
							p = trace_endpos;
							tracebox(p, PL_MIN_CONST, PL_MAX_CONST, p, MOVE_NOMONSTERS, NULL);
							if (trace_startsolid)
							{
								rint(42);  // do an engine breakpoint on VM_rint so you can get the trace that errnoeously returns startsolid
								tracebox(start, PL_MIN_CONST, PL_MAX_CONST, end, MOVE_NOMONSTERS, NULL);

								// how much do we need to back off?
								safe = 1;
								unsafe = 0;
								for ( ; ; )
								{
									pos = p * (1 - (safe + unsafe) * 0.5) + start * ((safe + unsafe) * 0.5);
									tracebox(pos, PL_MIN_CONST, PL_MAX_CONST, pos, MOVE_NOMONSTERS, NULL);
									if (trace_startsolid)
									{
										if ((safe + unsafe) * 0.5 == unsafe) break;
										unsafe = (safe + unsafe) * 0.5;
									}
									else
									{
										if ((safe + unsafe) * 0.5 == safe) break;
										safe = (safe + unsafe) * 0.5;
									}
								}

								LOG_INFO("safe distance to back off: ", ftos(safe * vlen(p - start)), "qu");
								LOG_INFO("unsafe distance to back off: ", ftos(unsafe * vlen(p - start)), "qu");

								tracebox(p, PL_MIN_CONST + '0.1 0.1 0.1', PL_MAX_CONST - '0.1 0.1 0.1', p, MOVE_NOMONSTERS, NULL);
								if (trace_startsolid) LOG_INFO("trace_endpos much in solid when tracing from ", vtos(start), " to ", vtos(end), " endpos ", vtos(p));
								else LOG_INFO("trace_endpos just in solid when tracing from ", vtos(start), " to ", vtos(end), " endpos ", vtos(p));
								if (++hitcount >= 10) break;
							}
							else
							{
								q0 = p;
								dq = 0;
								dqf = 1;
								for ( ; ; )
								{
									q = p + normalize(end - p) * (dq + dqf);
									if (q == q0) break;
									tracebox(p, PL_MIN_CONST, PL_MAX_CONST, q, MOVE_NOMONSTERS, NULL);
									if (trace_startsolid) error("THIS ONE cannot happen");
									if (trace_fraction > 0) dq += dqf * trace_fraction;
									dqf *= 0.5;
									q0 = q;
								}
								if (dq > worst_endpos_bug)
								{
									worst_endpos_bug = dq;
									LOG_INFO("trace_endpos still before solid when tracing from ", vtos(start), " to ", vtos(end), " endpos ", vtos(p));
									LOG_INFO("could go ", ftos(dq), " units further to ", vtos(q));
									if (++hitcount >= 10) break;
								}
							}
						}
					}
					return;
				}

				case "debug2":
				{
					e = nextent(NULL);
					tracebox(e.origin + '0 0 32', e.mins, e.maxs, e.origin + '0 0 -1024', MOVE_NORMAL, e);
					vv = trace_endpos;
					if (trace_fraction == 1)
					{
						LOG_INFO("not above ground, aborting");
						return;
					}
					f = 0;
					for (i = 0; i < 100000; ++i)
					{
						dv = randomvec();
						if (dv.z > 0) dv = -1 * dv;
						tracebox(vv, e.mins, e.maxs, vv + dv, MOVE_NORMAL, e);
						if (trace_startsolid) LOG_INFO("bug 1");
						if (trace_fraction == 1)
						{
							if (dv.z < f)
							{
								LOG_INFO("bug 2: ", ftos(dv.x), " ", ftos(dv.y), " ", ftos(dv.z));
								LOG_INFO(" (", ftos(asin(dv.z / vlen(dv)) * 180 / M_PI), " degrees)");
								f = dv.z;
							}
						}
					}
					LOG_INFO("highest possible dist: ", ftos(f));
					return;
				}

				case "walk":
				{
					if (argc == 4 || argc == 5)
					{
						e = nextent(NULL);
						int dphitcontentsmask_save = e.dphitcontentsmask;
						e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
						if (tracewalk(e, stov(argv(2)), e.mins, e.maxs, stov(argv(3)), stof(argv(4)), MOVE_NORMAL))
							LOG_INFO("can walk");
						else
							LOG_INFO("cannot walk");
						e.dphitcontentsmask = dphitcontentsmask_save;
						return;
					}
				}

				case "showline":
				{
					if (argc == 4)
					{
						vv = stov(argv(2));
						dv = stov(argv(3));
						traceline(vv, dv, MOVE_NORMAL, NULL);
						__trailparticles(NULL, particleeffectnum(EFFECT_TR_NEXUIZPLASMA), vv, trace_endpos);
						__trailparticles(NULL, particleeffectnum(EFFECT_TR_CRYLINKPLASMA), trace_endpos, dv);
						return;
					}
				}

				// no default case, just go straight to invalid
			}
		}

		default:
			LOG_HELPF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd trace <command> [<startpos> <endpos>] [<endpos_height>]");
			LOG_HELP("  Where <startpos> and <endpos> are parameters for the 'walk' and 'showline' commands,");
			LOG_HELP("  <endpos_height> is an optional parameter for the 'walk' command,");
			LOG_HELP("  Full list of commands here: debug, debug2, walk, showline.");
			LOG_HELP("See also: ^2bbox, gettaginfo^7");
			return;
		}
	}
}

void GameCommand_unlockteams(int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			if (teamplay)
			{
				lockteams = 0;
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_TEAMS_UNLOCKED);
			}
			else
			{
				bprint("unlockteams command can only be used in a team-based gametype.\n");
			}
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd unlockteams");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2lockteams^7");
			return;
		}
	}
}

void GameCommand_warp(int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!world_initialized)
			{
				LOG_HELPF("This command works only when the server is running.");
				return;
			}
			if (autocvar_g_campaign)
			{
				if (argc >= 2)
				{
					CampaignLevelWarp(stof(argv(1)));
					LOG_INFO("Successfully warped to campaign level ", argv(1), ".");
				}
				else
				{
					CampaignLevelWarp(-1);
					LOG_INFO("Successfully warped to next campaign level.");
				}
			}
			else
			{
				LOG_INFO("Not in campaign, can't level warp");
			}
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 sv_cmd warp [<level>]");
			LOG_HELP("  <level> is the level to change campaign mode to.");
			LOG_HELP("  if <level> is not provided it will change to the next level.");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void GameCommand_(int request)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
		    if (!world_initialized)
		    {
		        LOG_HELPF("This command works only when the server is running.");
		        return;
		    }

            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            LOG_HELP("Usage:^3 sv_cmd ");
            LOG_HELP("  No arguments required.");
            return;
        }
    }
}
*/


// ==================================
//  Macro system for server commands
// ==================================

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
SERVER_COMMAND(adminmsg, "Send an admin message to a client directly") { GameCommand_adminmsg(request, arguments); }
SERVER_COMMAND(allready, "Ends warmup and starts the match") { GameCommand_allready(request); }
SERVER_COMMAND(allspec, "Force all players to spectate") { GameCommand_allspec(request, arguments); }
SERVER_COMMAND(anticheat, "Create an anticheat report for a client") { GameCommand_anticheat(request, arguments); }
SERVER_COMMAND(animbench, "Benchmark model animation (LAGS)") { GameCommand_animbench(request, arguments); }
SERVER_COMMAND(bbox, "Print detailed information about world size") { GameCommand_bbox(request); }
SERVER_COMMAND(bot_cmd, "Control and send commands to bots") { GameCommand_bot_cmd(request, arguments, command); }
SERVER_COMMAND(cointoss, "Flip a virtual coin and give random result") { GameCommand_cointoss(request, arguments); }
SERVER_COMMAND(database, "Extra controls of the serverprogs database") { GameCommand_database(request, arguments); }
SERVER_COMMAND(defer_clear, "Clear all queued defer commands for a specific client") { GameCommand_defer_clear(request, arguments); }
SERVER_COMMAND(defer_clear_all, "Clear all queued defer commands for all clients") { GameCommand_defer_clear_all(request); }
SERVER_COMMAND(delrec, "Delete race time record for a map") { GameCommand_delrec(request, arguments); }
SERVER_COMMAND(effectindexdump, "Dump list of effects from code and effectinfo.txt") { GameCommand_effectindexdump(request); }
SERVER_COMMAND(extendmatchtime, "Increase the timelimit value incrementally") { GameCommand_extendmatchtime(request); }
SERVER_COMMAND(gametype, "Simple command to change the active gametype") { GameCommand_gametype(request, arguments); }
SERVER_COMMAND(gettaginfo, "Get specific information about a weapon model") { GameCommand_gettaginfo(request, arguments); }
SERVER_COMMAND(gotomap, "Simple command to switch to another map") { GameCommand_gotomap(request, arguments); }
SERVER_COMMAND(lockteams, "Disable the ability for players to switch or enter teams") { GameCommand_lockteams(request); }
SERVER_COMMAND(make_mapinfo, "Automatically rebuild mapinfo files") { GameCommand_make_mapinfo(request); }
SERVER_COMMAND(moveplayer, "Change the team/status of a player") { GameCommand_moveplayer(request, arguments); }
SERVER_COMMAND(nextmap, "Set/Query the next map") { GameCommand_nextmap(request, arguments); }
SERVER_COMMAND(nospectators, "Automatically remove spectators from a match") { GameCommand_nospectators(request); }
SERVER_COMMAND(printstats, "Dump eventlog player stats and other score information") { GameCommand_printstats(request); }
SERVER_COMMAND(radarmap, "Generate a radar image of the map") { GameCommand_radarmap(request, arguments); }
SERVER_COMMAND(reducematchtime, "Decrease the timelimit value incrementally") { GameCommand_reducematchtime(request); }
SERVER_COMMAND(resetmatch, "Soft restart the game without changing teams; goes back to warmup if enabled") { GameCommand_resetmatch(request); }
SERVER_COMMAND(setbots, "Adjust how many bots are in the match") { GameCommand_setbots(request, arguments); }
SERVER_COMMAND(shuffleteams, "Randomly move players to different teams") { GameCommand_shuffleteams(request); }
SERVER_COMMAND(stuffto, "Send a command to be executed on a client") { GameCommand_stuffto(request, arguments); }
SERVER_COMMAND(trace, "Various debugging tools with tracing") { GameCommand_trace(request, arguments); }
SERVER_COMMAND(unlockteams, "Enable the ability for players to switch or enter teams") { GameCommand_unlockteams(request); }
SERVER_COMMAND(warp, "Choose different level in campaign") { GameCommand_warp(request, arguments); }

void GameCommand_macro_help()
{
	FOREACH(SERVER_COMMANDS, true, { LOG_HELPF("  ^2%s^7: %s", it.m_name, it.m_description); });
}

float GameCommand_macro_command(int argc, string command)
{
	string c = strtolower(argv(0));
	FOREACH(SERVER_COMMANDS, it.m_name == c, {
		it.m_invokecmd(it, CMD_REQUEST_COMMAND, NULL, argc, command);
		return true;
	});
	return false;
}

float GameCommand_macro_usage(int argc)
{
	string c = strtolower(argv(1));
	FOREACH(SERVER_COMMANDS, it.m_name == c, {
		it.m_invokecmd(it, CMD_REQUEST_USAGE, NULL, argc, "");
		return true;
	});
	return false;
}

void GameCommand_macro_write_aliases(float fh)
{
	FOREACH(SERVER_COMMANDS, true, { CMD_Write_Alias("qc_cmd_sv", it.m_name, it.m_description); });
}


// =========================================
//  Main Function Called By Engine (sv_cmd)
// =========================================
// If this function exists, game code handles gamecommand instead of the engine code.

void GameCommand(string command)
{
	int argc = tokenize_console(command);

	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3
	// cmd     vote - master - login - password

	if (strtolower(argv(0)) == "help")
	{
		if (argc == 1)
		{
			LOG_HELP("Server console commands:");
			GameCommand_macro_help();

			LOG_HELP("\nBanning commands:");
			BanCommand_macro_help();

			LOG_HELP("\nCommon networked commands:");
			CommonCommand_macro_help(NULL);

			LOG_HELP("\nGeneric commands shared by all programs:");
			GenericCommand_macro_help();

			LOG_HELP("\nUsage:^3 sv_cmd <command>^7, where possible commands are listed above.\n"
				"For help about a specific command, type sv_cmd help <command>");

			return;
		}
		else if (BanCommand_macro_usage(argc))  // Instead of trying to call a command, we're going to see detailed information about it
		{
			return;
		}
		else if (CommonCommand_macro_usage(argc, NULL))  // same here, but for common commands instead
		{
			return;
		}
		else if (GenericCommand_macro_usage(argc))  // same here, but for generic commands instead
		{
			return;
		}
		else if (GameCommand_macro_usage(argc))  // finally try for normal commands too
		{
			return;
		}
	}
	else if (MUTATOR_CALLHOOK(SV_ParseServerCommand, strtolower(argv(0)), argc, command))
	{
		return;  // handled by a mutator
	}
	else if (BanCommand(command))
	{
		return;  // handled by server/command/ipban.qc
	}
	else if (CommonCommand_macro_command(argc, NULL, command))
	{
		return;  // handled by server/command/common.qc
	}
	else if (GenericCommand(command))
	{
		return;                                        // handled by common/command/generic.qc
	}
	else if (GameCommand_macro_command(argc, command)) // continue as usual and scan for normal commands
	{
		return;                                        // handled by one of the above GameCommand_* functions
	}

	// nothing above caught the command, must be invalid
	LOG_INFO(((command != "") ? strcat("Unknown server command \"", command, "\"") : "No command provided"), ". For a list of supported commands, try sv_cmd help.");
}
