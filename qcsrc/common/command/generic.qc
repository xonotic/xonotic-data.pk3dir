#include "generic.qh"

#if defined(CSQC)
	#include <client/command/cl_cmd.qh>
	#include <common/command/_mod.qh>
	#include <common/command/markup.qh>
	#include <common/command/reg.qh>
	#include <common/command/rpn.qh>
	#include <common/mapinfo.qh>
	#include <common/notifications/all.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/command/_mod.qh>
	#include <common/command/markup.qh>
	#include <common/command/reg.qh>
	#include <common/command/rpn.qh>
	#include <common/mapinfo.qh>
	#include <common/notifications/all.qh>
	#include <common/turrets/config.qh>
	#include <common/weapons/config.qh>
	#include <server/command/_mod.qh>
#endif

// =========================================================
//  Generic program common command code, written by Samual
//  Last updated: February 19th, 2012
// =========================================================


// used by curl command
void Curl_URI_Get_Callback(int id, float status, string data)
{
	int i = id - URI_GET_CURL;
	float do_exec = curl_uri_get_exec[i];
	string do_cvar = curl_uri_get_cvar[i];
	if(status != 0)
	{
		LOG_TRACEF("error: status is %d", status);
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

void GenericCommand_addtolist(int request, int argc)
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
					FOREACH_WORD(cvar_string(original_cvar), it == tmp_string,
					{
						return; // already in the list
					});

					cvar_set(original_cvar, cons(cvar_string(original_cvar), tmp_string));
				}
				return;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " addtolist <cvar> <value>");
			LOG_HELP("  Where <cvar> is the cvar to add <value> to.");
			LOG_HELP("See also: ^2removefromlist^7");
			return;
		}
	}
}

void GenericCommand_qc_curl(int request, int argc)
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
				LOG_INFO(_("error creating curl handle"));

			buf_del(buf);

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " qc_curl [--key <n>] [--cvar] [--exec] <url> [<postargs>]");
			return;
		}
	}
}

GENERIC_COMMAND(dumpcommands, "Dump all commands on the program to <program>_cmd_dump.txt", false)
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
					CMD_Write("\n");

					CMD_Write("dump of networked client only commands:\n");
					ClientCommand_macro_write_aliases(fh);
					CMD_Write("\n");

					CMD_Write("dump of common commands:\n");
					CommonCommand_macro_write_aliases(fh);
					CMD_Write("\n");

					CMD_Write("dump of ban commands:\n");
					BanCommand_macro_write_aliases(fh);
					CMD_Write("\n");
				#endif

				#ifdef CSQC
					CMD_Write("dump of client commands:\n");
					LocalCommand_macro_write_aliases(fh);
					CMD_Write("\n");
				#endif

				CMD_Write("dump of generic commands:\n");
				GenericCommand_macro_write_aliases(fh);

				LOG_INFO("Completed dump of aliases in ^2data/data/", GetProgramCommandPrefix(), "_dump.txt^7.");

				fclose(fh);
			}
			else
			{
				LOG_INFO("^1Error: ^7Could not dump to file!");
			}
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " dumpcommands");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}

string maplist_shuffle(string input)
{
	int buf = buf_create();

	int _cnt = 0;
	FOREACH_WORD(input, true,
	{
		int _j = floor(random() * (_cnt + 1));
		if(_j != _cnt)
			bufstr_set(buf, _cnt, bufstr_get(buf, _j));
		bufstr_set(buf, _j, it);
		++_cnt;
	});

	string output = buf_implode(buf, " ");
	buf_del(buf);
	return substring(output, 1, -1);
}

void GenericCommand_maplist(int request, int argc)
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
							LOG_INFO("maplist: ERROR: ", argv(2), " does not exist!");
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
					string filtered = "";
					FOREACH_WORD(cvar_string("g_maplist"), MapInfo_CheckMap(it), filtered = cons(filtered, it));
					cvar_set("g_maplist", filtered);
					return;
				}

				case "remove": // scans maplist and only adds back whatever maps were not provided in argv(2)
				{
					if(argc == 3)
					{
						// save argv(2) from being overridden by tokenize engine call
						string del_map_name = argv(2);
						argc = tokenizebyseparator(cvar_string("g_maplist"), " ");

						tmp_string = "";
						for(i = 0; i < argc; ++i)
							if(argv(i) != del_map_name)
								tmp_string = strcat(tmp_string, " ", argv(i));

						tmp_string = substring(tmp_string, 1, strlen(tmp_string) - 1);
						cvar_set("g_maplist", tmp_string);

						return;
					}
					break; // go to usage
				}

				case "shuffle": // randomly shuffle the maplist
				{
					cvar_set("g_maplist", maplist_shuffle(cvar_string("g_maplist")));
					return;
				}

				default: break;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " maplist <action> [<map>]");
			LOG_HELP("  Where <action> is the command to complete,");
			LOG_HELP("  and <map> is what it acts upon (for the 'add' and 'remove' actions).");
			LOG_HELP("  Full list of commands here: add, cleanup, remove, shuffle.");
			return;
		}
	}
}

void GenericCommand_nextframe(int request, string command)
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
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " nextframe <command>");
			LOG_HELP("  Where <command> will be executed next frame of this VM");
			return;
		}
	}
}

void GenericCommand_removefromlist(int request, int argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc == 3)
			{
				string original_cvar = argv(1);
				string removal = argv(2);

				string tmp_string = "";
				FOREACH_WORD(cvar_string(original_cvar), it != removal,
				{
					tmp_string = cons(tmp_string, it);
				});

				cvar_set(original_cvar, tmp_string);

				return;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " removefromlist <cvar> <value>");
			LOG_HELP("  Where <cvar> is the cvar to remove <value> from.");
			LOG_HELP("See also: ^2addtolist^7");
			return;
		}
	}
}

void GenericCommand_restartnotifs(int request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			#ifdef GAMEQC
			int NOTIF_ANNCE_COUNT = 0;
			int NOTIF_INFO_COUNT = 0;
			int NOTIF_CENTER_COUNT = 0;
			int NOTIF_MULTI_COUNT = 0;
			int NOTIF_CHOICE_COUNT = 0;
			FOREACH(Notifications, true, {
				switch (it.nent_type)
				{
					case MSG_ANNCE: ++NOTIF_ANNCE_COUNT; break;
					case MSG_INFO: ++NOTIF_INFO_COUNT; break;
					case MSG_CENTER: ++NOTIF_CENTER_COUNT; break;
					case MSG_MULTI: ++NOTIF_MULTI_COUNT; break;
					case MSG_CHOICE: ++NOTIF_CHOICE_COUNT; break;
				}
			});

			LOG_INFOF(
				"Restart_Notifications(): Restarting %d notifications... "
				"Counts: MSG_ANNCE = %d, MSG_INFO = %d, MSG_CENTER = %d, MSG_MULTI = %d, MSG_CHOICE = %d",
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
			LOG_INFO("Notification restart command only works with cl_cmd and sv_cmd.");
			#endif
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " restartnotifs");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}

void GenericCommand_settemp(int request, int argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(argc >= 3)
			{
				float f = cvar_settemp(argv(1), argv(2));
				if(f == 1)
					LOG_TRACE("Creating new settemp tracker for ", argv(1), " and setting it to \"", argv(2), "\" temporarily.");
				else if(f == -1)
					LOG_TRACE("Already had a tracker for ", argv(1), ", updating it to \"", argv(2), "\".");
				// else cvar_settemp itself errors out

				return;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " settemp <cvar> \"<arguments>\"");
			LOG_HELP("  Where <cvar> is the cvar you want to temporarily set with <arguments>.");
			LOG_HELP("See also: ^2settemp_restore^7");
			return;
		}
	}
}

void GenericCommand_settemp_restore(int request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float i = cvar_settemp_restore();

			if(i)
				LOG_TRACE("Restored ", ftos(i), " temporary cvar settings to their original values.");
			else
				LOG_TRACE("Nothing to restore.");

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " settemp_restore");
			LOG_HELP("  No arguments required.");
			LOG_HELP("See also: ^2settemp^7");
			return;
		}
	}
}

void GenericCommand_runtest(int request, int argc)
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
				RUN_ALL_TESTS();
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " <function>");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void GenericCommand_(int request)
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
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " ");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}
*/

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
GENERIC_COMMAND(addtolist, "Add a string to a cvar", true) { GenericCommand_addtolist(request, arguments); }
GENERIC_COMMAND(maplist, "Automatic control of maplist", true) { GenericCommand_maplist(request, arguments); }
GENERIC_COMMAND(nextframe, "Execute the given command next frame of this VM", true) { GenericCommand_nextframe(request, command); }
GENERIC_COMMAND(qc_curl, "Queries a URL", true) { GenericCommand_qc_curl(request, arguments); }
GENERIC_COMMAND(removefromlist, "Remove a string from a cvar", true) { GenericCommand_removefromlist(request, arguments); }
GENERIC_COMMAND(restartnotifs, "Re-initialize all notifications", false) { GenericCommand_restartnotifs(request); }
GENERIC_COMMAND(rpn, "RPN calculator", true) { GenericCommand_rpn(request, arguments, command); }
GENERIC_COMMAND(settemp, "Temporarily set a value to a cvar which is restored later", false) { GenericCommand_settemp(request, arguments); }
GENERIC_COMMAND(settemp_restore, "Restore all cvars set by settemp command", false) { GenericCommand_settemp_restore(request); }
GENERIC_COMMAND(runtest, "Run unit tests", false) { GenericCommand_runtest(request, arguments); }

void GenericCommand_macro_help()
{
	FOREACH(GENERIC_COMMANDS, true, LOG_HELPF("  ^2%s^7: %s", it.m_name, it.m_description));
}

float GenericCommand_macro_command(int argc, string command)
{
	string c = strtolower(argv(0));
	FOREACH(GENERIC_COMMANDS, it.m_name == c, {
		it.m_invokecmd(it, CMD_REQUEST_COMMAND, NULL, argc, command);
		return true;
	});
	return false;
}

float GenericCommand_macro_usage(int argc)
{
	string c = strtolower(argv(1));
	FOREACH(GENERIC_COMMANDS, it.m_name == c, {
		it.m_invokecmd(it, CMD_REQUEST_USAGE, NULL, argc, "");
		return true;
	});
	return false;
}

void GenericCommand_macro_write_aliases(float fh)
{
	FOREACH(GENERIC_COMMANDS, true, CMD_Write_Alias("qc_cmd_svmenu", it.m_name, it.m_description));
}


// ===========================================
//  Main Common Function For Generic Commands
// ===========================================
// Commands spread out among all programs (menu, client, and server)

float GenericCommand(string command)
{
	int argc = tokenize_console(command);
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
