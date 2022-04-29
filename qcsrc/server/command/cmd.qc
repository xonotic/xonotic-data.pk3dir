#include "cmd.qh"

#include <common/command/_mod.qh>
#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/effects/all.qh>
#include <common/gamemodes/_mod.qh>
#include <common/mapinfo.qh>
#include <common/mapobjects/triggers.qh>
#include <common/minigames/sv_minigames.qh>
#include <common/monsters/_mod.qh>
#include <common/monsters/sv_monsters.qh>
#include <common/monsters/sv_spawn.qh>
#include <common/notifications/all.qh>
#include <common/physics/player.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/vehicles/all.qh>
#include <lib/warpzone/common.qh>
#include <server/bot/api.qh>
#include <server/bot/default/waypoints.qh>
#include <server/campaign.qh>
#include <server/chat.qh>
#include <server/cheats.qh>
#include <server/client.qh>
#include <server/clientkill.qh>
#include <server/command/common.qh>
#include <server/command/getreplies.qh>
#include <server/command/vote.qh>
#include <server/ipban.qh>
#include <server/mapvoting.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/scores.qh>
#include <server/teamplay.qh>
#include <server/world.qh>

// =========================================================
//  Server side networked commands code, reworked by Samual
//  Last updated: December 28th, 2011
// =========================================================

bool SV_ParseClientCommand_floodcheck(entity this)
{
	entity store = IS_CLIENT(this) ? CS(this) : this; // unfortunately, we need to store these on the client initially

	if (!timeout_status)  // not while paused
	{
		if (time <= (store.cmd_floodtime + autocvar_sv_clientcommand_antispam_time))
		{
			store.cmd_floodcount += 1;
			if (store.cmd_floodcount > autocvar_sv_clientcommand_antispam_count)   return false;  // too much spam, halt
		}
		else
		{
			store.cmd_floodtime = time;
			store.cmd_floodcount = 1;
		}
	}
	return true;  // continue, as we're not flooding yet
}


// =======================
//  Command Sub-Functions
// =======================

void ClientCommand_autoswitch(entity caller, int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1) != "")
			{
				CS_CVAR(caller).cvar_cl_autoswitch = InterpretBoolean(argv(1));
				sprint(caller, strcat("^1autoswitch is currently turned ", (CS_CVAR(caller).cvar_cl_autoswitch ? "on" : "off"), ".\n"));
				return;
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd autoswitch <selection>\n");
			sprint(caller, "  Where <selection> controls if autoswitch is on or off.\n");
			return;
		}
	}
}

void ClientCommand_clientversion(entity caller, int request, int argc)  // internal command, used only by code
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1) != "")
			{
				if (IS_CLIENT(caller))
				{
					CS(caller).version = ((argv(1) == "$gameversion") ? 1 : stof(argv(1)));

					if (CS(caller).version < autocvar_gameversion_min || CS(caller).version > autocvar_gameversion_max)
					{
						CS(caller).version_mismatch = true;
						ClientKill_TeamChange(caller, -2);  // observe
					}
					else if (autocvar_g_campaign || autocvar_g_balance_teams)
					{
						// JoinBestTeam(caller, false, true);
					}
					else if (teamplay && !autocvar_sv_spectate && !(Player_GetForcedTeamIndex(caller) > 0))
					{
						TRANSMUTE(Observer, caller);  // really?
						stuffcmd(caller, "menu_showteamselect\n");
					}
				}

				return;
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd clientversion <version>\n");
			sprint(caller, "  Where <version> is the game version reported by caller.\n");
			return;
		}
	}
}

void ClientCommand_mv_getpicture(entity caller, int request, int argc)  // internal command, used only by code
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1) != "")
			{
				if (intermission_running) MapVote_SendPicture(caller, stof(argv(1)));

				return;
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd mv_getpicture <mapid>\n");
			sprint(caller, "  Where <mapid> is the id number of the map to request an image of on the map vote selection menu.\n");
			return;
		}
	}
}

void ClientCommand_wpeditor(entity caller, int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!waypointeditor_enabled)
			{
				sprint(caller, "ERROR: this command works only if the waypoint editor is on\n");
				return;
			}

			if (argv(1) != "")
			{
				if (argv(1) == "spawn")
				{
					string s = argv(2);
					if (!IS_PLAYER(caller))
						sprint(caller, "ERROR: this command works only if you are player\n");
					else
						waypoint_spawn_fromeditor(caller, (s == "crosshair"), (s == "jump"), (s == "crouch"), (s == "support"));
					return;
				}
				else if (argv(1) == "remove")
				{
					if (!IS_PLAYER(caller))
						sprint(caller, "ERROR: this command works only if you are player\n");
					else
						waypoint_remove_fromeditor(caller);
					return;
				}
				else if (argv(1) == "hardwire")
				{
					string s = argv(2);
					waypoint_start_hardwiredlink(caller, (s == "crosshair"));
					return;
				}
				else if (argv(1) == "lock")
				{
					waypoint_lock(caller);
					return;
				}
				else if (argv(1) == "unreachable")
				{
					if (!IS_PLAYER(caller))
						sprint(caller, "ERROR: this command works only if you are player\n");
					else
						waypoint_unreachable(caller);
					return;
				}
				else if (argv(1) == "saveall")
				{
					waypoint_saveall();
					return;
				}
				else if (argv(1) == "relinkall")
				{
					waypoint_schedulerelinkall();
					return;
				}
				else if (argv(1) == "symaxis")
				{
					if (argv(2) == "set" || argv(2) == "get")
					{
						waypoint_getSymmetricalAxis_cmd(caller, (argv(2) == "set"), 3);
						return;
					}
				}
				else if (argv(1) == "symorigin")
				{
					if (argv(2) == "set" || argv(2) == "get")
					{
						waypoint_getSymmetricalOrigin_cmd(caller, (argv(2) == "set"), 3);
						return;
					}
				}
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd wpeditor <action>\n");
			sprint(caller, "  Where <action> can be:\n");
			sprint(caller, "   ^2spawn^7: spawns a waypoint at player's position\n");
			sprint(caller, "   ^2remove^7: removes player's nearest waypoint\n");
			sprint(caller, "   ^2unreachable^7: reveals waypoints and items unreachable from the current position and spawnpoints without a nearest waypoint\n");
			sprint(caller, "   ^2saveall^7: saves all waypoints and links to file\n");
			sprint(caller, "   ^2relinkall^7: relinks all waypoints as if they were respawned\n");
			sprint(caller, "   ^2spawn crosshair^7: spawns a waypoint at crosshair's position\n");
			sprint(caller, "   ^7 in general useful to create special and hardwired links with ease from existing waypoints\n");
			sprint(caller, "   ^7 in particular it's the only way to create custom jumppad waypoints (spawn another waypoint to create destination))\n");
			sprint(caller, "   ^2spawn jump^7: spawns a jump waypoint (place it at least 60 qu before jump start, spawn another waypoint to create destination)\n");
			sprint(caller, "   ^2spawn crouch^7: spawns a crouch waypoint (it links only to very close waypoints)\n");
			sprint(caller, "   ^2spawn support^7: spawns a support waypoint (spawn another waypoint to create destination from which all incoming links are removed)\n");
			sprint(caller, "   ^7 useful to replace links to problematic jumppad/teleport waypoints\n");
			sprint(caller, "   ^2hardwire^7: marks the nearest waypoint as origin of a new hardwired link (spawn another waypoint over an existing one to create destination)\n");
			sprint(caller, "   ^2hardwire crosshair^7: marks the waypoint at crosshair instead of the nearest waypoint\n");
			sprint(caller, "   ^2lock^7: locks link display of the aimed waypoint (unlocks if no waypoint is found at crosshair's position)\n");
			sprint(caller, "   ^2symorigin get|set\n");
			sprint(caller, "   ^2symorigin get|set <p1> <p2> ... <pX>\n");
			sprint(caller, "   ^2symaxis get|set <p1> <p2>\n");
			sprint(caller, "   ^7 where <p1> <p2> ... <pX> are positions (\"x y z\", z can be omitted) that you know are perfectly symmetrical"
								" so you can determine origin/axis of symmetry of maps without ctf flags or where flags aren't perfectly symmetrical\n");
			sprint(caller, "  See ^5wpeditor_menu^7 for a selectable list of various commands and useful settings to edit waypoints.\n");
			return;
		}
	}
}

void ClientCommand_join(entity caller, int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!game_stopped && IS_CLIENT(caller) && !IS_PLAYER(caller))
			{
				if (joinAllowed(caller))
					Join(caller);
				else if(time < CS(caller).jointime + MIN_SPEC_TIME)
					CS(caller).autojoin_checked = -1;
			}

			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd join\n");
			sprint(caller, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_kill(entity caller, int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(IS_SPEC(caller) || IS_OBSERVER(caller))
				return; // no point warning about this, command does nothing

			if(GetResource(caller, RES_HEALTH) <= 0)
			{
				sprint(caller, "Can't die - you are already dead!\n");
				return;
			}

			ClientKill(caller);

			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd kill\n");
			sprint(caller, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_physics(entity caller, int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string command = strtolower(argv(1));

			if (!autocvar_g_physics_clientselect)
			{
				sprint(caller, "Client physics selection is currently disabled.\n");
				return;
			}

			if (command == "list" || command == "help")
			{
				sprint(caller, strcat("Available physics sets: \n\n", autocvar_g_physics_clientselect_options, " default\n"));
				return;
			}

			if (Physics_Valid(command) || command == "default")
			{
				stuffcmd(caller, strcat("\nseta cl_physics ", command, "\n"));
				sprint(caller, strcat("^2Physics set successfully changed to ^3", command, "\n"));
				return;
			}
		}

		default:
			sprint(caller, strcat("Current physics set: ^3", CS_CVAR(caller).cvar_cl_physics, "\n"));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd physics <physics>\n");
			sprint(caller, "  See 'cmd physics list' for available physics sets.\n");
			sprint(caller, "  Argument 'default' resets to standard physics.\n");
			return;
		}
	}
}

void ClientCommand_ready(entity caller, int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (IS_CLIENT(caller) && caller.last_ready < time - 3)
			{
				if (warmup_stage || g_race_qualifying == 2)
				{
					if (time < game_starttime) // game is already restarting
						return;
					if (caller.ready)            // toggle
					{
						caller.ready = false;
						if (IS_PLAYER(caller) || INGAME_JOINED(caller))
							bprint(playername(caller.netname, caller.team, false), "^2 is ^1NOT^2 ready\n");
					}
					else
					{
						caller.ready = true;
						if (IS_PLAYER(caller) || INGAME_JOINED(caller))
							bprint(playername(caller.netname, caller.team, false), "^2 is ready\n");
					}

					caller.last_ready = time;

					// cannot reset the game while a timeout is active!
					if (!timeout_status) ReadyCount();
				}
			}
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd ready\n");
			sprint(caller, "  No arguments required.\n");
			return;
		}
	}
}

void ClientCommand_say(entity caller, int request, int argc, string command)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc >= 2)   Say(caller, false, NULL, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd say <message>\n");
			sprint(caller, "  Where <message> is the string of text to say.\n");
			return;
		}
	}
}

void ClientCommand_say_team(entity caller, int request, int argc, string command)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc >= 2)
				Say(caller, true, NULL, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)), 1);
			return;  // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd say_team <message>\n");
			sprint(caller, "  Where <message> is the string of text to say.\n");
			return;
		}
	}
}

.bool team_selected;
void ClientCommand_selectteam(entity caller, int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1) == "")
			{
				return;
			}
			if (!IS_CLIENT(caller))
			{
				return;
			}
			if (!teamplay)
			{
				sprint(caller, "^7selectteam can only be used in teamgames\n");
				return;
			}
			if (Player_GetForcedTeamIndex(caller) > 0)
			{
				sprint(caller, "^7selectteam can not be used as your team is forced\n");
				return;
			}
			if (lockteams)
			{
				sprint(caller, "^7The game has already begun, you must wait until the next map to be able to join a team.\n");
				return;
			}

			float team_num = Team_ColorToTeam(argv(1));
			if (team_num == -1) // invalid
				return;
			if (caller.team == team_num && team_num && !IS_DEAD(caller))
			{
				sprint(caller, "^7You already are on that team.\n");
				return;
			}
			if (CS(caller).wasplayer && autocvar_g_changeteam_banned)
			{
				sprint(caller, "^1You cannot change team, forbidden by the server.\n");
				return;
			}
			if (team_num && autocvar_g_balance_teams && autocvar_g_balance_teams_prevent_imbalance)
			{
				entity balance = TeamBalance_CheckAllowedTeams(caller);
				TeamBalance_GetTeamCounts(balance, caller);
				if ((Team_IndexToBit(Team_TeamToIndex(team_num)) &
					TeamBalance_FindBestTeams(balance, caller, false)) == 0)
				{
					Send_Notification(NOTIF_ONE, caller, MSG_INFO, INFO_TEAMCHANGE_LARGERTEAM);
					TeamBalance_Destroy(balance);
					return;
				}
				TeamBalance_Destroy(balance);
			}
			if (team_num)
				ClientKill_TeamChange(caller, team_num);
			else // auto
				ClientKill_TeamChange(caller, -1);

			if (!IS_PLAYER(caller))
			{
				caller.team_selected = true; // avoids asking again for team selection on join
			}
			return;
		}
		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd selectteam <team>\n");
			sprint(caller, "  Where <team> is the prefered team to try and join.\n");
			sprint(caller, "  Full list of options here: red, blue, yellow, pink, auto.\n");
			return;
		}
	}
}

void ClientCommand_selfstuff(entity caller, int request, string command)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1) != "")
			{
				stuffcmd(caller, substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
				return;
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd selfstuff <command>\n");
			sprint(caller, "  Where <command> is the string to be stuffed to your client.\n");
			return;
		}
	}
}

void ClientCommand_sentcvar(entity caller, int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc >= 3)
			{
			// NOTE: client-side settings do not exist on the server, this functionality has been deprecated
			#if 0
				if (argc == 2)  // undefined cvar: use the default value on the server then
				{
					string s = strcat(substring(command, argv_start_index(0), argv_end_index(1) - argv_start_index(0)), " \"", cvar_defstring(argv(1)), "\"");
					tokenize_console(s);
				}
			#endif

				GetCvars(caller, CS_CVAR(caller), 1);

				return;
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd sentcvar <cvar> <arguments>\n");
			sprint(caller, "  Where <cvar> is the cvar plus arguments to send to the server.\n");
			return;
		}
	}
}

void ClientCommand_spectate(entity caller, int request)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (!intermission_running && IS_CLIENT(caller))
			{
				if(argv(1) != "")
				{
					if(IS_SPEC(caller) || IS_OBSERVER(caller))
					{
						entity client = GetFilteredEntity(argv(1));
						int spec_accepted = VerifyClientEntity(client, false, false);
						if(spec_accepted > 0 && IS_PLAYER(client))
						{
							bool caller_is_observer = (IS_OBSERVER(caller));
							Spectate(caller, client);
							if (caller_is_observer)
								TRANSMUTE(Spectator, caller);
						}
						else
							sprint(caller, "Can't spectate ", argv(1), "^7\n");
					}
					else
						sprint(caller, "cmd spectate <client> only works when you are spectator/observer\n");
					return;
				}

				int mutator_returnvalue = MUTATOR_CALLHOOK(ClientCommand_Spectate, caller);

				if (mutator_returnvalue == MUT_SPECCMD_RETURN) return;

				if ((IS_PLAYER(caller) || mutator_returnvalue == MUT_SPECCMD_FORCE))
				if (autocvar_sv_spectate == 1)
					ClientKill_TeamChange(caller, -2); // observe
			}
			return; // never fall through to usage
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd spectate [<client>]\n");
			sprint(caller, "  Where <client> can be the player to spectate.\n");
			return;
		}
	}
}

void ClientCommand_suggestmap(entity caller, int request, int argc)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1) != "")
			{
				sprint(caller, strcat(MapVote_Suggest(caller, argv(1)), "\n"));
				return;
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd suggestmap <map>\n");
			sprint(caller, "  Where <map> is the name of the map to suggest.\n");
			return;
		}
	}
}

void ClientCommand_tell(entity caller, int request, int argc, string command)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc >= 3)
			{
				if(!IS_CLIENT(caller) && IS_REAL_CLIENT(caller)) // connecting
				{
					print_to(caller, "You can't ^2tell^7 a message while connecting.");
					return;
				}

				entity tell_to = GetIndexedEntity(argc, 1);
				float tell_accepted = VerifyClientEntity(tell_to, true, false);

				if (tell_accepted > 0)   // the target is a real client
				{
					if (tell_to != caller) // and we're allowed to send to them :D
					{
						// workaround for argv indexes indexing ascii chars instead of utf8 chars
						// In this case when the player name contains utf8 chars
						// the message gets partially trimmed in the beginning.
						// Potentially this bug affects any substring call that uses
						// argv_start_index and argv_end_index.

						string utf8_enable_save = cvar_string("utf8_enable");
						cvar_set("utf8_enable", "0");
						string msg = substring(command, argv_start_index(next_token), argv_end_index(-1) - argv_start_index(next_token));
						cvar_set("utf8_enable", utf8_enable_save);

						Say(caller, false, tell_to, msg, true);
						return;
					}
					else { print_to(caller, "You can't ^2tell^7 a message to yourself."); return; }
				}
				else if (argv(1) == "#0")
				{
					trigger_magicear_processmessage_forallears(caller, -1, NULL, substring(command, argv_start_index(next_token), argv_end_index(-1) - argv_start_index(next_token)));
					return;
				}
				else { print_to(caller, strcat("tell: ", GetClientErrorString(tell_accepted, argv(1)), ".")); return; }
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd tell <client> <message>\n");
			sprint(caller, "  Where <client> is the entity number or name of the player to send <message> to.\n");
			return;
		}
	}
}

void ClientCommand_voice(entity caller, int request, int argc, string command)
{
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1) != "")
			{
				entity e = GetVoiceMessage(argv(1));
				if (!e)
				{
					sprint(caller, sprintf("Invalid voice. Use one of: %s\n", allvoicesamples));
					return;
				}
				if (IS_DEAD(caller))
				{
					// don't warn the caller when trying to taunt while dead, just don't play any sounds!
					// we still allow them to see warnings if it's invalid, so a dead player can find out the sounds in peace
					return;
				}
				if (IS_SPEC(caller) || IS_OBSERVER(caller))
				{
					// observers/spectators have no player model of their own to play taunts from
					// again, allow them to see warnings
					return;
				}
				string msg = "";
				if (argc >= 3)
					msg = substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2));
				VoiceMessage(caller, e, msg);

				return;
			}
		}

		default:
			sprint(caller, sprintf("Incorrect parameters for ^2%s^7\n", argv(0)));
		case CMD_REQUEST_USAGE:
		{
			sprint(caller, "\nUsage:^3 cmd voice <voicetype> [<message>]\n");
			sprint(caller, "  <voicetype> is the type of voice message, it can be one of these:\n");
			sprint(caller, sprintf("   %s\n", allvoicesamples));
			sprint(caller, "  and <message> is the text message to send.\n");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void ClientCommand_(entity caller, int request)
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
            sprint(caller, "\nUsage:^3 cmd \n");
            sprint(caller, "  No arguments required.\n");
            return;
        }
    }
}
*/


// =====================================
//  Macro system for networked commands
// =====================================

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
#define CLIENT_COMMANDS(ent, request, arguments, command) \
	CLIENT_COMMAND("autoswitch", ClientCommand_autoswitch(ent, request, arguments), "Whether or not to switch automatically when getting a better weapon") \
	CLIENT_COMMAND("clientversion", ClientCommand_clientversion(ent, request, arguments), "Release version of the game") \
	CLIENT_COMMAND("join", ClientCommand_join(ent, request), "Become a player in the game") \
	CLIENT_COMMAND("kill", ClientCommand_kill(ent, request), "Become a member of the dead") \
	CLIENT_COMMAND("minigame", ClientCommand_minigame(ent, request, arguments, command), "Start a minigame") \
	CLIENT_COMMAND("mv_getpicture", ClientCommand_mv_getpicture(ent, request, arguments), "Retrieve mapshot picture from the server") \
	CLIENT_COMMAND("physics", ClientCommand_physics(ent, request, arguments), "Change physics set") \
	CLIENT_COMMAND("ready", ClientCommand_ready(ent, request), "Qualify as ready to end warmup stage (or restart server if allowed)") \
	CLIENT_COMMAND("say", ClientCommand_say(ent, request, arguments, command), "Print a message to chat to all players") \
	CLIENT_COMMAND("say_team", ClientCommand_say_team(ent, request, arguments, command), "Print a message to chat to all team mates") \
	CLIENT_COMMAND("selectteam", ClientCommand_selectteam(ent, request, arguments), "Attempt to choose a team to join into") \
	CLIENT_COMMAND("selfstuff", ClientCommand_selfstuff(ent, request, command), "Stuffcmd a command to your own client") \
	CLIENT_COMMAND("sentcvar", ClientCommand_sentcvar(ent, request, arguments), "New system for sending a client cvar to the server") \
	CLIENT_COMMAND("spectate", ClientCommand_spectate(ent, request), "Become an observer") \
	CLIENT_COMMAND("suggestmap", ClientCommand_suggestmap(ent, request, arguments), "Suggest a map to the mapvote at match end") \
	CLIENT_COMMAND("tell", ClientCommand_tell(ent, request, arguments, command), "Send a message directly to a player") \
	CLIENT_COMMAND("voice", ClientCommand_voice(ent, request, arguments, command), "Send voice message via sound") \
	CLIENT_COMMAND("wpeditor", ClientCommand_wpeditor(ent, request, arguments), "Waypoint editor commands") \
	/* nothing */

void ClientCommand_macro_help(entity caller)
{
	#define CLIENT_COMMAND(name, function, description) \
		{ sprint(caller, "  ^2", name, "^7: ", description, "\n"); }

	CLIENT_COMMANDS(NULL, 0, 0, "");
#undef CLIENT_COMMAND
}

float ClientCommand_macro_command(int argc, entity caller, string command)
{
	#define CLIENT_COMMAND(name, function, description) \
		{ if (name == strtolower(argv(0))) { function; return true; } }

	CLIENT_COMMANDS(caller, CMD_REQUEST_COMMAND, argc, command);
#undef CLIENT_COMMAND

	return false;
}

float ClientCommand_macro_usage(int argc, entity caller)
{
	#define CLIENT_COMMAND(name, function, description) \
		{ if (name == strtolower(argv(1))) { function; return true; } }

	CLIENT_COMMANDS(caller, CMD_REQUEST_USAGE, argc, "");
#undef CLIENT_COMMAND

	return false;
}

void ClientCommand_macro_write_aliases(float fh)
{
	#define CLIENT_COMMAND(name, function, description) \
		{ CMD_Write_Alias("qc_cmd_cmd", name, description); }

	CLIENT_COMMANDS(NULL, 0, 0, "");
#undef CLIENT_COMMAND
}

// ======================================
//  Main Function Called By Engine (cmd)
// ======================================
// If this function exists, server game code parses clientcommand before the engine code gets it.

void SV_ParseClientCommand(entity this, string command)
{
	// If invalid UTF-8, don't even parse it
	string command2 = "";
	float len = strlen(command);
	float i;
	for (i = 0; i < len; ++i)
		command2 = strcat(command2, chr2str(str2chr(command, i)));
	if (command != command2) return;

	// if we're banned, don't even parse the command
	if (Ban_MaybeEnforceBanOnce(this)) return;

	int argc = tokenize_console(command);

	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3
	// cmd     vote - master - login - password

	// for floodcheck
	switch (strtolower(argv(0)))
	{
		// exempt commands which are not subject to floodcheck
		case "begin": break;                               // handled by engine in host_cmd.c
		case "download": break;                            // handled by engine in cl_parse.c
		case "mv_getpicture": break;                       // handled by server in this file
		case "wpeditor": break;                            // handled by server in this file
		case "pause": break;                               // handled by engine in host_cmd.c
		case "prespawn": break;                            // handled by engine in host_cmd.c
		case "sentcvar": break;                            // handled by server in this file
		case "spawn": break;                               // handled by engine in host_cmd.c
		case "color": case "topcolor": case "bottomcolor": // handled by engine in host_cmd.c
			if(!IS_CLIENT(this)) // on connection
			{
				// since gamecode doesn't have any calls earlier than this, do the connecting message here
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_CONNECTING, this.netname);
			}
			if(teamplay)
				return;
			break;
		case "c2s": Net_ClientCommand(this, command); return; // handled by net.qh

		default:
			if (SV_ParseClientCommand_floodcheck(this)) break; // "true": continue, as we're not flooding yet
			else return;                                   // "false": not allowed to continue, halt // print("^1ERROR: ^7ANTISPAM CAUGHT: ", command, ".\n");
	}

	/* NOTE: should this be disabled? It can be spammy perhaps, but hopefully it's okay for now */
	if (argv(0) == "help")
	{
		if (argc == 1)
		{
			sprint(this, "\nClient networked commands:\n");
			ClientCommand_macro_help(this);

			sprint(this, "\nCommon networked commands:\n");
			CommonCommand_macro_help(this);

			sprint(this, "\nUsage:^3 cmd <command>^7, where possible commands are listed above.\n");
			sprint(this, "For help about a specific command, type cmd help <command>\n");
			return;
		}
		else if (CommonCommand_macro_usage(argc, this))  // Instead of trying to call a command, we're going to see detailed information about it
		{
			return;
		}
		else if (ClientCommand_macro_usage(argc, this))  // same, but for normal commands now
		{
			return;
		}
	}
	else if (MUTATOR_CALLHOOK(SV_ParseClientCommand, this, strtolower(argv(0)), argc, command))
	{
		return;  // handled by a mutator
	}
	else if (CheatCommand(this, argc))
	{
		return;  // handled by server/cheats.qc
	}
	else if (CommonCommand_macro_command(argc, this, command))
	{
		return;                                          // handled by server/command/common.qc
	}
	else if (ClientCommand_macro_command(argc, this, command)) // continue as usual and scan for normal commands
	{
		return;                                          // handled by one of the above ClientCommand_* functions
	}
	else
	{
		clientcommand(this, command);
	}
}
