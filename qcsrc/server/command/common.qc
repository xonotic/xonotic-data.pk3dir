#include "common.qh"

#include <common/command/_mod.qh>
#include <common/deathtypes/all.qh>
#include <common/monsters/_mod.qh>
#include <common/notifications/all.qh>
#include <common/stats.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <lib/warpzone/common.qh>
#include <server/campaign.qh>
#include <server/chat.qh>
#include <server/client.qh>
#include <server/command/common.qh>
#include <server/mutators/_mod.qh>
#include <server/scores.qh>
#include <server/world.qh>


// ====================================================
//  Shared code for server commands, written by Samual
//  Last updated: December 27th, 2011
// ====================================================

// select the proper prefix for usage and other messages
string GetCommandPrefix(entity caller)
{
	if (caller) return "cmd";
	else return "sv_cmd";
}

// if client return player nickname, or if server return admin nickname
string GetCallerName(entity caller)
{
	if (caller) return playername(caller.netname, caller.team, false);
	else return ((autocvar_sv_adminnick != "") ? autocvar_sv_adminnick : "SERVER ADMIN"); // autocvar_hostname
}

// verify that the client provided is acceptable for kicking
int VerifyKickableEntity(entity client)
{
	if (!IS_REAL_CLIENT(client)) return CLIENT_NOT_REAL;
	return CLIENT_ACCEPTABLE;
}

// verify that the client provided is acceptable for use
int VerifyClientEntity(entity client, bool must_be_real, bool must_be_bots)
{
	if (!IS_CLIENT(client)) return CLIENT_DOESNT_EXIST;
	else if (must_be_real && !IS_REAL_CLIENT(client)) return CLIENT_NOT_REAL;
	else if (must_be_bots && !IS_BOT_CLIENT(client)) return CLIENT_NOT_BOT;

	return CLIENT_ACCEPTABLE;
}

// if the client is not acceptable, return a string to be used for error messages
string GetClientErrorString_color(float clienterror, string original_input, string col)
{
	switch (clienterror)
	{
		case CLIENT_DOESNT_EXIST:
		{ return strcat(col, "Client '", original_input, col, "' doesn't exist");
		}
		case CLIENT_NOT_REAL:
		{ return strcat(col, "Client '", original_input, col, "' is not real");
		}
		case CLIENT_NOT_BOT:
		{ return strcat(col, "Client '", original_input, col, "' is not a bot");
		}
		default:
		{ return "Incorrect usage of GetClientErrorString";
		}
	}
}

// is this entity number even in the possible range of entities?
bool VerifyClientNumber(int num)
{
	return (num >= 1 && num <= maxclients);
}

entity GetIndexedEntity(int argc, int start_index)
{
	entity selection;
	int tmp_number, index;
	string tmp_string;

	next_token = -1;
	index = start_index;
	selection = NULL;

	if (argc > start_index)
	{
		if (substring(argv(index), 0, 1) == "#")
		{
			tmp_string = substring(argv(index), 1, -1);
			++index;

			if (tmp_string != "")  // is it all one token? like #1
			{
				tmp_number = stof(tmp_string);
			}
			else if (argc > index)  // no, it's two tokens? # 1
			{
				tmp_number = stof(argv(index));
				++index;
			}
			else
			{
				tmp_number = 0;
			}
		}
		else  // maybe it's ONLY a number?
		{
			tmp_number = stof(argv(index));
			++index;
		}

		if (VerifyClientNumber(tmp_number))
		{
			selection = edict_num(tmp_number);  // yes, it was a number
		}
		else  // no, maybe it's a name?
		{
			FOREACH_CLIENT(true, {
				if(strdecolorize(it.netname) == strdecolorize(argv(start_index)))
				{
					selection = it;
					break; // no reason to keep looking
				}
			});

			index = (start_index + 1);
		}
	}

	next_token = index;
	// print(strcat("start_index: ", ftos(start_index), ", next_token: ", ftos(next_token), ", edict: ", ftos(num_for_edict(selection)), ".\n"));
	return selection;
}

// find a player which matches the input string, and return their entity
entity GetFilteredEntity(string input)
{
	entity selection;
	int tmp_number;

	if (substring(input, 0, 1) == "#") tmp_number = stof(substring(input, 1, -1));
	else tmp_number = stof(input);

	if (VerifyClientNumber(tmp_number))
	{
		selection = edict_num(tmp_number);
	}
	else
	{
		selection = NULL;
		FOREACH_CLIENT(true, {
			if(strdecolorize(it.netname) == strdecolorize(input))
			{
				selection = it;
				break; // no reason to keep looking
			}
		});
	}

	return selection;
}

// switch between sprint and print depending on whether the receiver is the server or a player
void print_to(entity to, string input)
{
	if (to) sprint(to, strcat(input, "\n"));
	else print(input, "\n");
}

// ==========================================
//  Supporting functions for common commands
// ==========================================

// used by CommonCommand_timeout() and CommonCommand_timein() to handle game pausing and messaging and such.
void timeout_handler_reset(entity this)
{
	timeout_caller = NULL;
	timeout_time = 0;
	timeout_leadtime = 0;

	delete(this);

	// ReadyCount() does nothing when a timeout is active or pending
	// so check readiness now to support g_warmup_allow_timeout
	if (warmup_stage) ReadyCount();
}

void timeout_handler_think(entity this)
{
	switch (timeout_status)
	{
		case TIMEOUT_ACTIVE:
		{
			if (timeout_time > 0)  // countdown is still going
			{
				Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_TIMEOUT_ENDING, timeout_time);

				if (timeout_time == autocvar_sv_timeout_resumetime) // play a warning sound when only <sv_timeout_resumetime> seconds are left
					Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_PREPARE);

				this.nextthink = time + TIMEOUT_SLOWMO_VALUE;       // think again in one second
				timeout_time -= 1;                                  // decrease the time counter
			}
			else  // time to end the timeout
			{
				Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_TIMEIN);
				timeout_status = TIMEOUT_INACTIVE;

				// reset the slowmo value back to normal
				cvar_set("slowmo", ftos(orig_slowmo));

				// unlock the view for players so they can move around again
				FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), {
					it.fixangle = false;
				});

				timeout_handler_reset(this);
			}

			return;
		}

		case TIMEOUT_LEADTIME:
		{
			if (timeout_leadtime > 0)  // countdown is still going
			{
				Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_TIMEOUT_BEGINNING, timeout_leadtime);

				this.nextthink = time + 1; // think again in one second
				timeout_leadtime -= 1;     // decrease the time counter
			}
			else  // time to begin the timeout
			{
				timeout_status = TIMEOUT_ACTIVE;

				// set the slowmo value to the timeout default slowmo value
				cvar_set("slowmo", ftos(TIMEOUT_SLOWMO_VALUE));

				// copy .v_angle to .lastV_angle for every player in order to fix their view during pause (see PlayerPreThink)
				FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), {
					it.lastV_angle = it.v_angle;
				});

				this.nextthink = time;  // think again next frame to handle it under TIMEOUT_ACTIVE code
			}

			return;
		}


		case TIMEOUT_INACTIVE:
		default:
		{
			timeout_handler_reset(this);
			return;
		}
	}
}


// ===================================================
//  Common commands used in both sv_cmd.qc and cmd.qc
// ===================================================

void CommonCommand_cvar_changes(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, cvar_changes);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " cvar_changes"));
			print_to(caller, "  No arguments required.");
			print_to(caller, "See also: ^2cvar_purechanges^7");
			return;
		}
	}
}

void CommonCommand_cvar_purechanges(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, cvar_purechanges);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " cvar_purechanges"));
			print_to(caller, "  No arguments required.");
			print_to(caller, "See also: ^2cvar_changes^7");
			return;
		}
	}
}

void CommonCommand_editmob(int request, entity caller, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (autocvar_g_campaign) { print_to(caller, "Monster editing is disabled in singleplayer"); return; }
			// no checks for g_monsters here, as it may be toggled mid match which existing monsters

			if (caller)
			{
				makevectors(caller.v_angle);
				WarpZone_TraceLine(caller.origin + caller.view_ofs, caller.origin + caller.view_ofs + v_forward * 100, MOVE_NORMAL, caller);
			}

			entity mon = trace_ent;
			bool is_visible = IS_MONSTER(mon);
			string argument = argv(2);

			switch (argv(1))
			{
				case "name":
				{
					if (!caller) { print_to(caller, "Only players can edit monsters"); return; }
					if (!argument)   break;  // escape to usage
					if (!autocvar_g_monsters_edit) { print_to(caller, "Monster editing is disabled"); return; }
					if (mon.realowner != caller && autocvar_g_monsters_edit < 2) { print_to(caller, "This monster does not belong to you"); return; }
					if (!is_visible) { print_to(caller, "You must look at your monster to edit it"); return; }

					string mon_oldname = mon.m_name;

					mon.m_name = argument;
					if (mon.sprite)   WaypointSprite_UpdateSprites(mon.sprite, WP_Monster, WP_Null, WP_Null); // TODO: the new name is never actually sent to CSQC!
					print_to(caller, sprintf("Your pet '%s' is now known as '%s'", mon_oldname, mon.m_name));
					return;
				}
				case "spawn":
				{
					if (!caller) { print_to(caller, "Only players can spawn monsters"); return; }
					if (!argv(2))   break;  // escape to usage

					int moveflag, tmp_moncount = 0;
					string arg_lower = strtolower(argument);
					moveflag = (argv(3)) ? stof(argv(3)) : 1;  // follow owner if not defined

					if (arg_lower == "list") { print_to(caller, monsterlist_reply); return; }

					IL_EACH(g_monsters, it.realowner == caller,
					{
						++tmp_moncount;
					});

					if (!autocvar_g_monsters) { print_to(caller, "Monsters are disabled"); return; }
					if (autocvar_g_monsters_max <= 0 || autocvar_g_monsters_max_perplayer <= 0) { print_to(caller, "Monster spawning is disabled"); return; }
					if (!IS_PLAYER(caller)) { print_to(caller, "You must be playing to spawn a monster"); return; }
					if (MUTATOR_CALLHOOK(AllowMobSpawning, caller)) { print_to(caller, M_ARGV(1, string)); return; }
					if (caller.vehicle) { print_to(caller, "You can't spawn monsters while driving a vehicle"); return; }
					if (IS_DEAD(caller)) { print_to(caller, "You can't spawn monsters while dead"); return; }
					if (tmp_moncount >= autocvar_g_monsters_max) { print_to(caller, "The maximum monster count has been reached"); return; }
					if (tmp_moncount >= autocvar_g_monsters_max_perplayer) { print_to(caller, "You can't spawn any more monsters"); return; }

					bool found = false;
					FOREACH(Monsters, it != MON_Null && it.netname == arg_lower,
					{
						found = true;
						break;
					});

					if (!found && arg_lower != "random" && arg_lower != "anyrandom") { print_to(caller, "Invalid monster"); return; }

					totalspawned += 1;
					WarpZone_TraceBox(CENTER_OR_VIEWOFS(caller), caller.mins, caller.maxs, CENTER_OR_VIEWOFS(caller) + v_forward * 150, true, caller);
					mon = spawnmonster(spawn(), arg_lower, MON_Null, caller, caller, trace_endpos, false, false, moveflag);
					print_to(caller, strcat("Spawned ", mon.m_name));
					return;
				}
				case "kill":
				{
					if (!caller) { print_to(caller, "Only players can kill monsters"); return; }
					if (mon.realowner != caller && autocvar_g_monsters_edit < 2) { print_to(caller, "This monster does not belong to you"); return; }
					if (!is_visible) { print_to(caller, "You must look at your monster to edit it"); return; }

					Damage(mon, NULL, NULL, GetResource(mon, RES_HEALTH) + mon.max_health + 200, DEATH_KILL.m_id, DMG_NOWEP, mon.origin, '0 0 0');
					print_to(caller, strcat("Your pet '", mon.m_name, "' has been brutally mutilated"));
					return;
				}
				case "skin":
				{
					if (!caller) { print_to(caller, "Only players can edit monsters"); return; }
					if (!argument)   break;  // escape to usage
					if (!autocvar_g_monsters_edit) { print_to(caller, "Monster editing is disabled"); return; }
					if (!is_visible) { print_to(caller, "You must look at your monster to edit it"); return; }
					if (mon.realowner != caller && autocvar_g_monsters_edit < 2) { print_to(caller, "This monster does not belong to you"); return; }
					if (mon.monsterdef == MON_MAGE) { print_to(caller, "Mage skins can't be changed"); return; }  // TODO

					mon.skin = stof(argument);
					print_to(caller, strcat("Monster skin successfully changed to ", ftos(mon.skin)));
					return;
				}
				case "movetarget":
				{
					if (!caller) { print_to(caller, "Only players can edit monsters"); return; }
					if (!argument)   break;  // escape to usage
					if (!autocvar_g_monsters_edit) { print_to(caller, "Monster editing is disabled"); return; }
					if (!is_visible) { print_to(caller, "You must look at your monster to edit it"); return; }
					if (mon.realowner != caller && autocvar_g_monsters_edit < 2) { print_to(caller, "This monster does not belong to you"); return; }

					mon.monster_moveflags = stof(argument);
					print_to(caller, strcat("Monster move target successfully changed to ", ftos(mon.monster_moveflags)));
					return;
				}
				case "butcher":
				{
					if (caller) { print_to(caller, "This command is not available to players"); return; }
					if (MUTATOR_CALLHOOK(AllowMobButcher)) { LOG_INFO(M_ARGV(0, string)); return; }

					int tmp_remcount = 0;

					IL_EACH(g_monsters, true,
					{
						Monster_Remove(it);
						++tmp_remcount;
					});
					IL_CLEAR(g_monsters);

					monsters_total = monsters_killed = totalspawned = 0;

					print_to(caller, (tmp_remcount) ? sprintf("Killed %d monster%s", tmp_remcount, (tmp_remcount == 1) ? "" : "s") : "No monsters to kill");
					return;
				}
			}
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " editmob <command> [<arguments>]"));
			print_to(caller, "  Where <command> can be butcher spawn skin movetarget kill name");
			print_to(caller, "  spawn, skin, movetarget and name require <arguments>");
			print_to(caller, "  spawn also takes arguments list and random");
			print_to(caller, "  Monster will follow owner if third argument of spawn command is not defined");
			return;
		}
	}
}

void CommonCommand_info(int request, entity caller, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string command = cvar_string(strcat("sv_info_", argv(1)));

			if (command) wordwrap_sprint(caller, command, 1000);
			else print_to(caller, "ERROR: unsupported info command");

			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " info <request>"));
			print_to(caller, "  Where <request> is the suffixed string appended onto the request for cvar.");
			return;
		}
	}
}

void CommonCommand_ladder(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, ladder_reply);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " ladder"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_lsmaps(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, lsmaps_reply);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " lsmaps"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_printmaplist(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, maplist_reply);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " printmaplist"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_rankings(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, rankings_reply);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " rankings"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_records(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			int num = stoi(argv(1));
			if(num > 0 && num <= 10 && records_reply[num - 1] != "")
				print_to(caller, records_reply[num - 1]);
			else
			{
				for (int i = 0; i < 10; ++i)
					if (records_reply[i] != "") print_to(caller, records_reply[i]);
			}

			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " records [<pagenum>]"));
			print_to(caller, "  Without arguments it prints all records (all pages) for the current gametype,");
			print_to(caller, "  otherwise if there are multiple pages it only prints page <pagenum> (1..10),");
			return;
		}
	}
}

void CommonCommand_teamstatus(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			Score_NicePrint(caller);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " teamstatus"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_time(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			print_to(caller, strcat("time = ", ftos(time)));
			print_to(caller, strcat("frame start = ", ftos(gettime(GETTIME_FRAMESTART))));
			print_to(caller, strcat("realtime = ", ftos(gettime(GETTIME_REALTIME))));
			print_to(caller, strcat("hires = ", ftos(gettime(GETTIME_HIRES))));
			print_to(caller, strcat("uptime = ", ftos(gettime(GETTIME_UPTIME))));
			print_to(caller, strcat("localtime = ", strftime(true, "%a %b %d %H:%M:%S %Z %Y")));
			print_to(caller, strcat("gmtime = ", strftime(false, "%a %b %d %H:%M:%S %Z %Y")));
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " time"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_timein(int request, entity caller)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!caller || autocvar_sv_timeout)
			{
				if (!timeout_status) { print_to(caller, "^7Error: There is no active timeout called."); }
				else if (caller && (caller != timeout_caller))
				{
					print_to(caller, "^7Error: You are not allowed to stop the active timeout.");
				}

				else  // everything should be okay, continue aborting timeout
				{
					switch (timeout_status)
					{
						case TIMEOUT_LEADTIME:
						{
							timeout_status = TIMEOUT_INACTIVE;
							timeout_time = 0;
							timeout_handler.nextthink = time;  // timeout_handler has to take care of it immediately
							Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_TIMEOUT);
							bprint(strcat("^7The timeout was aborted by ", GetCallerName(caller), " !\n"));
							return;
						}

						case TIMEOUT_ACTIVE:
						{
							timeout_time = autocvar_sv_timeout_resumetime;
							timeout_handler.nextthink = time;  // timeout_handler has to take care of it immediately
							bprint(strcat("^1Attention: ^7", GetCallerName(caller), " resumed the game! Prepare for battle!\n"));
							return;
						}

						default: LOG_TRACE("timeout status was inactive, but this code was executed anyway?");
							return;
					}
				}
			}
			else { print_to(caller, "^1Timeins are not allowed to be called, enable them with sv_timeout 1.\n"); }

			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " timein"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_timeout(int request, entity caller)  // DEAR GOD THIS COMMAND IS TERRIBLE.
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!caller || autocvar_sv_timeout)
			{
				float last_possible_timeout = ((autocvar_timelimit * 60) - autocvar_sv_timeout_leadtime - 1);

				if (timeout_status) { print_to(caller, "^7Error: A timeout is already active."); }
				else if (vote_called)
				{
					print_to(caller, "^7Error: You can not call a timeout while a vote is active.");
				}
				else if (warmup_stage && !autocvar_g_warmup_allow_timeout)
				{
					print_to(caller, "^7Error: You can not call a timeout in warmup-stage.");
				}
				else if (time < game_starttime)
				{
					print_to(caller, "^7Error: You can not call a timeout while the map is being restarted.");
				}
				else if (caller && (CS(caller).allowed_timeouts < 1))
				{
					print_to(caller, "^7Error: You already used all your timeout calls for this map.");
				}
				else if (caller && !IS_PLAYER(caller))
				{
					print_to(caller, "^7Error: You must be a player to call a timeout.");
				}
				else if ((autocvar_timelimit) && (last_possible_timeout < time - game_starttime))
				{
					print_to(caller, "^7Error: It is too late to call a timeout now!");
				}

				else  // everything should be okay, proceed with starting the timeout
				{
					if (caller)   CS(caller).allowed_timeouts -= 1;
					// write a bprint who started the timeout (and how many they have left)
					bprint(GetCallerName(caller), " ^7called a timeout", (caller ? strcat(" (", ftos(CS(caller).allowed_timeouts), " timeout(s) left)") : ""), "!\n");

					timeout_status = TIMEOUT_LEADTIME;
					timeout_caller = caller;
					timeout_time = autocvar_sv_timeout_length;
					timeout_leadtime = autocvar_sv_timeout_leadtime;

					timeout_handler = new(timeout_handler);
					setthink(timeout_handler, timeout_handler_think);
					timeout_handler.nextthink = time;  // always let the entity think asap

					Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_TIMEOUT);
				}
			}
			else { print_to(caller, "^1Timeouts are not allowed to be called, enable them with sv_timeout 1.\n"); }

			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " timeout"));
			print_to(caller, "  No arguments required.");
			return;
		}
	}
}

void CommonCommand_who(int request, entity caller, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float total_listed_players, is_bot;

			float privacy = (caller && autocvar_sv_status_privacy);
			string separator = strreplace("%", " ", strcat((argv(1) ? argv(1) : " "), "^7"));
			string tmp_netaddress, tmp_crypto_idfp;

			print_to(caller, strcat("List of client information", (privacy ? " (some data is hidden for privacy)" : ""), ":"));
			print_to(caller, sprintf(strreplace(" ", separator, " %-4s %-20s %-5s %-3s %-9s %-16s %s "),
				"ent", "nickname", "ping", "pl", "time", "ip", "crypto_id"));

			total_listed_players = 0;
			FOREACH_CLIENT(true, {
				is_bot = (IS_BOT_CLIENT(it));

				if (is_bot)
				{
					tmp_netaddress = "null/botclient";
					tmp_crypto_idfp = "null/botclient";
				}
				else if (privacy)
				{
					tmp_netaddress = "hidden";
					tmp_crypto_idfp = "hidden";
				}
				else
				{
					tmp_netaddress = it.netaddress;
					tmp_crypto_idfp = it.crypto_idfp;
				}

				print_to(caller, sprintf(strreplace(" ", separator, " #%-3d %-20.20s %-5d %-3d %-9s %-16s %s "),
					etof(it),
					it.netname,
					CS(it).ping,
					CS(it).ping_packetloss,
					process_time(1, time - CS(it).jointime),
					tmp_netaddress,
					tmp_crypto_idfp));

				++total_listed_players;
			});

			print_to(caller, strcat("Finished listing ", ftos(total_listed_players), " client(s) out of ", ftos(maxclients), " slots."));

			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " who [<separator>]"));
			print_to(caller, "  Where <separator> is the optional string to separate the values with, default is a space.");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void CommonCommand_(int request, entity caller)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {

            return; // never fall through to usage
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            print_to(caller, strcat("\nUsage:^3 ", GetCommandPrefix(caller), " "));
            print_to(caller, "  No arguments required.");
            return;
        }
    }
}
*/
