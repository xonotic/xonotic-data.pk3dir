#include "all.qh"

#include "markup.qh"
#include "rpn.qh"

#include "../mapinfo.qh"

#ifndef MENUQC
	#include "../notifications.qh"
#endif

#ifdef CSQC
	#include "../../client/commands/cl_cmd.qh"
#endif

#ifdef SVQC
	#include "../../server/command/banning.qh"
	#include "../../server/command/cmd.qh"
	#include "../../server/command/common.qh"
	#include "../../server/command/sv_cmd.qh"
	#include "../../common/turrets/config.qh"
	#include "../../common/weapons/config.qh"
#endif

// =========================================================
//  Generic program common command code, written by Samual
//  Last updated: February 19th, 2012
// =========================================================

// used by generic commands for better help/usage information
string GetProgramCommandPrefix(void)
{
	#ifdef SVQC
	return "sv_cmd";
	#endif
	#ifdef CSQC
	return "cl_cmd";
	#endif
	#ifdef MENUQC
	return "menu_cmd";
	#endif
}

// used by curl command
void Curl_URI_Get_Callback(int id, float status, string data)
{
	int i = id - URI_GET_CURL;
	float do_exec = curl_uri_get_exec[i];
	string do_cvar = curl_uri_get_cvar[i];
	if(status != 0)
	{
		LOG_TRACEF("error: status is %d\n", status);
		if(do_cvar)
			strunzone(do_cvar);
		return;
	}
	if(do_exec)
		localcmd(data);
	if(do_cvar)
	{
		cvar_set(do_cvar, data);
		strunzone(do_cvar);
	}
	if(!do_exec)
		if (!do_cvar)
			LOG_INFO(data);
}


// =======================
//  Command Sub-Functions
// =======================

void GenericCommand_addtolist(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc >= 2)
			{
				string original_cvar = argv(1);
				string tmp_string = argv(2);

				if(cvar_string(original_cvar) == "") // cvar was empty
				{
					cvar_set(original_cvar, tmp_string);
				}
				else // add it to the end of the list if the list doesn't already have it
				{
					argc = tokenizebyseparator(cvar_string(original_cvar), " ");
					int i;
					for(i = 0; i < argc; ++i)
						if(argv(i) == tmp_string)
							return; // already in list

					cvar_set(original_cvar, strcat(tmp_string, " ", cvar_string(original_cvar)));
				}
				return;
			}
		}

		default:
			LOG_INFO("Incorrect parameters for ^2addtolist^7\n");
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " addtolist variable value\n"));
			LOG_INFO("  Where 'variable' is what to add 'value' to.\n");
			LOG_INFO("See also: ^2removefromlist^7\n");
			return;
		}
	}
}

void GenericCommand_qc_curl(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			bool do_exec = false;
			string do_cvar = string_null;
			float key = -1;
			int i;
			for(i = 1; i+1 < argc; ++i)
			{
				if(argv(i) == "--cvar" && i+2 < argc)
				{
					++i;
					do_cvar = strzone(argv(i));
					continue;
				}
				if(argv(i) == "--exec")
				{
					do_exec = true;
					continue;
				}
				if(argv(i) == "--key" && i+2 < argc)
				{
					++i;
					key = stof(argv(i));
					continue;
				}
				break;
			}

			// now, argv(i) is the URL
			// following args may be POST parameters
			string url = argv(i);
			++i;
			float buf = buf_create();
			int j;
			for(j = 0; i+1 < argc; i += 2)
				bufstr_set(buf, ++j, sprintf("%s=%s", uri_escape(argv(i)), uri_escape(argv(i+1))));
			if(i < argc)
				bufstr_set(buf, ++j, sprintf("submit=%s", uri_escape(argv(i))));

			float r;
			if(j == 0) // no args: GET
				r = crypto_uri_postbuf(url, URI_GET_CURL + curl_uri_get_pos, string_null, string_null, -1, key);
			else // with args: POST
				r = crypto_uri_postbuf(url, URI_GET_CURL + curl_uri_get_pos, "application/x-www-form-urlencoded", "&", buf, key);

			if(r)
			{
				curl_uri_get_exec[curl_uri_get_pos] = do_exec;
				curl_uri_get_cvar[curl_uri_get_pos] = do_cvar;
				curl_uri_get_pos = (curl_uri_get_pos + 1) % (URI_GET_CURL_END - URI_GET_CURL + 1);
			}
			else
				LOG_INFO(_("error creating curl handle\n"));

			buf_del(buf);

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " qc_curl [--key N] [--cvar] [--exec] URL [postargs...]"));
			return;
		}
	}
}

GENERIC_COMMAND(dumpcommands, "Dump all commands on the program to *_cmd_dump.txt")
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float fh;
			string filename = strcat(GetProgramCommandPrefix(), "_dump.txt");
			fh = fopen(filename, FILE_WRITE);

			if(fh >= 0)
			{
				#ifdef SVQC
					CMD_Write("dump of server console commands:\n");
					GameCommand_macro_write_aliases(fh);

					CMD_Write("\ndump of networked client only commands:\n");
					ClientCommand_macro_write_aliases(fh);

					CMD_Write("\ndump of common commands:\n");
					CommonCommand_macro_write_aliases(fh);

					CMD_Write("\ndump of ban commands:\n");
					BanCommand_macro_write_aliases(fh);
				#endif

				#ifdef CSQC
					CMD_Write("dump of client commands:\n");
					LocalCommand_macro_write_aliases(fh);
				#endif

				CMD_Write("\ndump of generic commands:\n");
				GenericCommand_macro_write_aliases(fh);

				LOG_INFO("Completed dump of aliases in ^2data/data/", GetProgramCommandPrefix(), "_dump.txt^7.\n");

				fclose(fh);
			}
			else
			{
				LOG_INFO("^1Error: ^7Could not dump to file!\n");
			}
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " dumpcommands"));
			LOG_INFO("  No arguments required.\n");
			return;
		}
	}
}

void GenericCommand_maplist(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string tmp_string;
			float i;

			switch(argv(1))
			{
				case "add": // appends new maps to the maplist
				{
					if(argc == 3)
					{
						if (!fexists(strcat("maps/", argv(2), ".bsp")))
						{
							LOG_INFO("maplist: ERROR: ", argv(2), " does not exist!\n");
							break;
						}

						if(cvar_string("g_maplist") == "")
							cvar_set("g_maplist", argv(2));
						else
							cvar_set("g_maplist", strcat(argv(2), " ", cvar_string("g_maplist")));

						return;
					}
					break; // go to usage
				}

				case "cleanup": // scans maplist and only adds back the ones which are really usable
				{
					MapInfo_Enumerate();
					MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
					argc = tokenizebyseparator(cvar_string("g_maplist"), " ");

					tmp_string = "";
					for(i = 0; i < argc; ++i)
						if(MapInfo_CheckMap(argv(i)))
							tmp_string = strcat(tmp_string, " ", argv(i));

					tmp_string = substring(tmp_string, 1, strlen(tmp_string) - 1);
					cvar_set("g_maplist", tmp_string);

					return;
				}

				case "remove": // scans maplist and only adds back whatever maps were not provided in argv(2)
				{
					if(argc == 3)
					{
						argc = tokenizebyseparator(cvar_string("g_maplist"), " ");

						tmp_string = "";
						for(i = 0; i < argc; ++i)
							if(argv(i) != argv(2))
								tmp_string = strcat(tmp_string, " ", argv(i));

						tmp_string = substring(tmp_string, 1, strlen(tmp_string) - 1);
						cvar_set("g_maplist", tmp_string);

						return;
					}
					break; // go to usage
				}

				case "shuffle": // randomly shuffle the maplist
				{
					cvar_set("g_maplist", shufflewords(cvar_string("g_maplist")));
					return;
				}

				default: break;
			}
		}

		default:
			LOG_INFO("Incorrect parameters for ^2maplist^7\n");
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " maplist action [map]\n"));
			LOG_INFO("  Where 'action' is the command to complete,\n");
			LOG_INFO("  and 'map' is what it acts upon (if required).\n");
			LOG_INFO("  Full list of commands here: \"add, cleanup, remove, shuffle.\"\n");
			return;
		}
	}
}

void GenericCommand_nextframe(float request, float arguments, string command)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			queue_to_execute_next_frame(substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " nextframe command...\n"));
			LOG_INFO("  Where command will be executed next frame of this VM\n");
			return;
		}
	}
}

void GenericCommand_removefromlist(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc == 3)
			{
				float i;
				string original_cvar = argv(1);
				string removal = argv(2);
				string tmp_string;

				argc = tokenizebyseparator(cvar_string(original_cvar), " ");

				tmp_string = "";
				for(i = 0; i < argc; ++i)
					if(argv(i) != removal)
						tmp_string = strcat(tmp_string, " ", argv(i));

				tmp_string = substring(tmp_string, 1, strlen(tmp_string) - 1);
				cvar_set(original_cvar, tmp_string);

				return;
			}
		}

		default:
			LOG_INFO("Incorrect parameters for ^2removefromlist^7\n");
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " removefromlist variable value\n"));
			LOG_INFO("  Where 'variable' is what cvar to remove 'value' from.\n");
			LOG_INFO("See also: ^2addtolist^7\n");
			return;
		}
	}
}

void GenericCommand_restartnotifs(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			#ifndef MENUQC
			LOG_INFOF(
				strcat(
					"Restart_Notifications(): Restarting %d notifications... ",
					"Counts: MSG_ANNCE = %d, MSG_INFO = %d, MSG_CENTER = %d, MSG_MULTI = %d, MSG_CHOICE = %d\n"
				),
				(
					NOTIF_ANNCE_COUNT +
					NOTIF_INFO_COUNT +
					NOTIF_CENTER_COUNT +
					NOTIF_MULTI_COUNT +
					NOTIF_CHOICE_COUNT
				),
				NOTIF_ANNCE_COUNT,
				NOTIF_INFO_COUNT,
				NOTIF_CENTER_COUNT,
				NOTIF_MULTI_COUNT,
				NOTIF_CHOICE_COUNT
			);
			Destroy_All_Notifications();
			CALL_ACCUMULATED_FUNCTION(RegisterNotifications);
			#else
			LOG_INFO(_("Notification restart command only works with cl_cmd and sv_cmd.\n"));
			#endif
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " restartnotifs"));
			LOG_INFO("  No arguments required.\n");
			return;
		}
	}
}

void GenericCommand_settemp(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc >= 3)
			{
				float f = cvar_settemp(argv(1), argv(2));
				if(f == 1)
					LOG_TRACE("Creating new settemp tracker for ", argv(1), " and setting it to \"", argv(2), "\" temporarily.\n");
				else if(f == -1)
					LOG_TRACE("Already had a tracker for ", argv(1), ", updating it to \"", argv(2), "\".\n");
				// else cvar_settemp itself errors out

				return;
			}
		}

		default:
			LOG_INFO("Incorrect parameters for ^2settemp^7\n");
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " settemp \"cvar\" \"arguments\"\n"));
			LOG_INFO("  Where 'cvar' is the cvar you want to temporarily set with 'arguments'.\n");
			LOG_INFO("See also: ^2settemp_restore^7\n");
			return;
		}
	}
}

void GenericCommand_settemp_restore(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float i = cvar_settemp_restore();

			if(i)
				LOG_TRACE("Restored ", ftos(i), " temporary cvar settings to their original values.\n");
			else
				LOG_TRACE("Nothing to restore.\n");

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " settemp_restore\n"));
			LOG_INFO("  No arguments required.\n");
			LOG_INFO("See also: ^2settemp^7\n");
			return;
		}
	}
}

void GenericCommand_runtest(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc > 1)
			{
				float i;
				for(i = 1; i < argc; ++i)
					TEST_Run(argv(i));
			}
			else
				TEST_RunAll();
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_INFO(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " [function to run]"));
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void GenericCommand_(float request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			print(strcat("\nUsage:^3 ", GetProgramCommandPrefix(), " "));
			print("  No arguments required.\n");
			return;
		}
	}
}
*/

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
GENERIC_COMMAND(addtolist, "Add a string to a cvar") { GenericCommand_addtolist(request, arguments); }
GENERIC_COMMAND(maplist, "Automatic control of maplist") { GenericCommand_maplist(request, arguments); }
GENERIC_COMMAND(nextframe, "Execute the given command next frame of this VM") { GenericCommand_nextframe(request, arguments, command); }
GENERIC_COMMAND(qc_curl, "Queries a URL") { GenericCommand_qc_curl(request, arguments); }
GENERIC_COMMAND(removefromlist, "Remove a string from a cvar") { GenericCommand_removefromlist(request, arguments); }
GENERIC_COMMAND(restartnotifs, "Re-initialize all notifications") { GenericCommand_restartnotifs(request); }
GENERIC_COMMAND(rpn, "RPN calculator") { GenericCommand_rpn(request, arguments, command); }
GENERIC_COMMAND(settemp, "Temporarily set a value to a cvar which is restored later") { GenericCommand_settemp(request, arguments); }
GENERIC_COMMAND(settemp_restore, "Restore all cvars set by settemp command") { GenericCommand_settemp_restore(request, arguments); }
GENERIC_COMMAND(runtest, "Run unit tests") { GenericCommand_runtest(request, arguments); }

void GenericCommand_macro_help()
{
	FOREACH(GENERIC_COMMANDS, true, LAMBDA(LOG_INFOF("  ^2%s^7: %s\n", it.m_name, it.m_description)));
}

float GenericCommand_macro_command(float argc, string command)
{
	string c = strtolower(argv(0));
	FOREACH(GENERIC_COMMANDS, it.m_name == c, LAMBDA(
		it.m_invokecmd(CMD_REQUEST_COMMAND, argc, command);
		return true;
	));
	return false;
}

float GenericCommand_macro_usage(float argc)
{
	string c = strtolower(argv(1));
	FOREACH(GENERIC_COMMANDS, it.m_name == c, LAMBDA(
		it.m_invokecmd(CMD_REQUEST_USAGE, argc, "");
		return true;
	));
	return false;
}

void GenericCommand_macro_write_aliases(float fh)
{
	FOREACH(GENERIC_COMMANDS, true, LAMBDA(CMD_Write_Alias("qc_cmd_svmenu", it.m_name, it.m_description)));
}


// ===========================================
//  Main Common Function For Generic Commands
// ===========================================
// Commands spread out among all programs (menu, client, and server)

float GenericCommand(string command)
{
	float argc = tokenize_console(command);
	float n, j, f, i;
	string s, s2, c;
	vector rgb;

	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3
	// cmd     vote - master - login - password

	if(GenericCommand_macro_command(argc, command)) // continue as usual and scan for normal commands
	{
		return true; // handled by one of the above GenericCommand_* functions
	}
	else if(argc >= 3 && argv(0) == "red")
	{
		s = substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2));
		localcmd(strcat(argv(1), " ", GenericCommand_markup(s)));
		return true;
	}
	else if(argc >= 3 && crc16(0, argv(0)) == 38566 && crc16(0, strcat(argv(0), argv(0), argv(0))) == 59830)
	{
		// other test case
		s = strconv(2, 0, 0, substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2)));

		n = floor(random() * 6 + 2);

		s2 = "";
		for(i = 0; i < n; ++i)
		{
			s2 = strcat(s2, "AH");
		}

		if(random() < 0.1)
			s2 = strcat(substring(s2, 1, strlen(s2) - 1), "A");

		if(s == "")
			s = s2;
		else
			if(random() < 0.8)
				s = strcat(s, " ", s2);
			else
				s = strcat(s2, " ", s);

		s2 = substring(s, strlen(s) - 2, 2);
		if(s2 == "AH" || s2 == "AY")
			s = strcat(s, "))");
		else
			s = strcat(s, " ))");

		if(random() < 0.1)
			s = substring(s, 0, strlen(s) - 1);

		if(random() < 0.1)
			s = strconv(1, 0, 0, s);

		localcmd(strcat(argv(1), " ", s));

		return true;
	}
	else if(argc >= 3 && crc16(0, argv(0)) == 3826 && crc16(0, strcat(argv(0), argv(0), argv(0))) == 55790)
	{
		// test case for terencehill's color codes
		s = strdecolorize(substring(command, argv_start_index(2), argv_end_index(-1) - argv_start_index(2)));
		s2 = "";

		n = strlen(s);
		j = ((6 * max(1, floor(strlen(s)/32 + random() * 2 - 1))) / n) * (1 - 2 * (random() > 0.5));
		f = random() * 6;

		for(i = 0; i < n; ++i)
		{
			c = substring(s, i, 1);

			if(c == ";")
				c = ":";
			else if(c == "^")
			{
				c = "^^";
				if(substring(s, i+1, 1) == "^")
					++i;
			}

			if(c != " ")
			{
				rgb = hsl_to_rgb('1 0 0' * (j * i + f) + '0 1 .5');
				c = strcat(rgb_to_hexcolor(rgb), c);
			}
			s2 = strcat(s2, c);
		}

		localcmd(strcat(argv(1), " ", s2));

		return true;
	}

	return false;
}
