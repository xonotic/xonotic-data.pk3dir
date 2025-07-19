#include "cl_cmd.qh"

// ==============================================
//  CSQC client commands code, written by Samual
//  Last updated: December 28th, 2011
// ==============================================

#include <client/draw.qh>
#include <client/hud/_mod.qh>
#include <client/hud/panel/quickmenu.qh>
#include <client/hud/panel/radar.qh>
#include <client/hud/panel/scoreboard.qh>
#include <client/hud/panel/vote.qh>
#include <client/mapvoting.qh>
#include <client/mutators/_mod.qh>
#include <client/view.qh>
#include <common/command/_mod.qh>
#include <common/mapinfo.qh>
#include <common/minigames/cl_minigames_hud.qh>

void DrawDebugModel(entity this)
{
	if (time - floor(time) > 0.5)
	{
		PolyDrawModel(this);
		this.drawmask = 0;
	}
	else
	{
		this.renderflags = 0;
		this.drawmask = MASK_NORMAL;
	}
}


// =======================
//  Command Sub-Functions
// =======================

void LocalCommand_blurtest(int request)
{
	TC(int, request);
	// Simple command to work with postprocessing temporarily... possibly completely pointless, the glsl shader is used for a real feature now...
	// Anyway, to enable it, just compile the client with -DBLURTEST and then you can use the command.

	#ifdef BLURTEST
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			blurtest_time0 = time;
			blurtest_time1 = time + stof(argv(1));
			blurtest_radius = stof(argv(2));
			blurtest_power = stof(argv(3));
			LOG_INFO("Enabled blurtest");
			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd blurtest");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
	#else
	if (request)
	{
		LOG_INFO("Blurtest is not enabled on this client.");
		return;
	}
	#endif
}

void LocalCommand_boxparticles(int request, int argc)
{
	TC(int, request); TC(int, argc);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argc == 9)
			{
				int effect = _particleeffectnum(argv(1));
				if (effect >= 0)
				{
					int index = stoi(argv(2));
					entity own;
					if (index <= 0)
						own = entitybyindex(-index);
					else
						own = findfloat(NULL, entnum, index);
					vector org_from = stov(argv(3));
					vector org_to = stov(argv(4));
					vector dir_from = stov(argv(5));
					vector dir_to = stov(argv(6));
					int countmultiplier = stoi(argv(7));
					int flags = stoi(argv(8));
					boxparticles(effect, own, org_from, org_to, dir_from, dir_to, countmultiplier, flags);
					return;
				}
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP(
				"Usage:^3 cl_cmd boxparticles <effectname> <owner> <org_from> <org_to> <dir_from> <dir_to> <countmultiplier> <flags>\n"
				"  <effectname> is the name of a particle effect in effectinfo.txt\n"
				"  <owner> is the entity number of the owner (negative for csqc ent, positive for svqc ent)\n"
				"  <org_from> is the starting origin of the box\n"
				"  <org_to> is the ending origin of the box\n"
				"  <dir_from> is the minimum velocity\n"
				"  <dir_to> is the maximum velocity\n"
				"  <countmultiplier> defines a multiplier for the particle count (affects count only, not countabsolute or trailspacing)\n"
				"  <flags> can contain:\n"
				"    1 to respect globals particles_alphamin, particles_alphamax (set right before via prvm_globalset client)\n"
				"    2 to respect globals particles_colormin, particles_colormax (set right before via prvm_globalset client)\n"
				"    4 to respect globals particles_fade (set right before via prvm_globalset client)\n"
				"    128 to draw a trail, not a box"
			);
			return;
		}
	}
}

void LocalCommand_create_scrshot_ent(int request)
{
	TC(int, request);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string path = ((argv(1) == "") ? "" : strcat(argv(1), "/"));
			string filename = strcat(path, MapInfo_Map_bspname, "_scrshot_ent.txt");
			int fh = fopen(filename, FILE_APPEND);

			if (fh >= 0)
			{
				fputs(fh, "{\n");
				fputs(fh, strcat("\"classname\" \"info_autoscreenshot\"\n"));
				fputs(fh, strcat("\"origin\" \"", strcat(ftos(view_origin.x), " ", ftos(view_origin.y), " ", ftos(view_origin.z)), "\"\n"));
				fputs(fh, strcat("\"angles\" \"", strcat(ftos(view_angles.x), " ", ftos(view_angles.y), " ", ftos(view_angles.z)), "\"\n"));
				fputs(fh, "}\n");

				LOG_INFO("Completed screenshot entity dump in ^2data/data/", path, MapInfo_Map_bspname, "_scrshot_ent.txt^7.");

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
			LOG_HELP("Usage:^3 cl_cmd create_scrshot_ent [<path>]");
			LOG_HELP("  Where <path> can be the subdirectory of data/data in which the file is saved.");
			return;
		}
	}
}

void LocalCommand_debugmodel(int request, int argc)
{
	TC(int, request); TC(int, argc);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string modelname = argv(1);

			if (modelname != "")
			{
				entity debugmodel_entity = new(debugmodel);
				precache_model(modelname);
				_setmodel(debugmodel_entity, modelname);
				setorigin(debugmodel_entity, view_origin);
				debugmodel_entity.angles = view_angles;
				debugmodel_entity.draw = DrawDebugModel;
				IL_PUSH(g_drawables, debugmodel_entity);
				return;
			}
			// fall through
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd debugmodel <model>");
			LOG_HELP("  Where <model> is a string of the model name to use for the debug model.");
			return;
		}
	}
}

void LocalCommand_handlevote(int request, int argc)
{
	TC(int, request); TC(int, argc);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			int vote_selection;
			string vote_string;

			if (InterpretBoolean(argv(1)))
			{
				vote_selection = 2;
				vote_string = "yes";
			}
			else
			{
				vote_selection = 1;
				vote_string = "no";
			}

			if (vote_selection)
			{
				if (uid2name_dialog)  // handled by "uid2name" option
				{
					vote_active = 0;
					vote_prev = 0;
					vote_change = -9999;
					localcmd(strcat("setreport cl_allow_uid2name ", ftos(vote_selection - 1), "\n"));
					uid2name_dialog = 0;
				}
				else { localcmd(strcat("cmd vote ", vote_string, "\n")); }

				return;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd handlevote <vote>");
			LOG_HELP("  Where <vote> is the selection for either the current poll or uid2name.");
			return;
		}
	}
}

void LocalCommand_hud(int request, int argc)
{
	TC(int, request); TC(int, argc);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if(MUTATOR_CALLHOOK(HUD_Command, argc))
				return;

			switch (argv(1))
			{
				case "configure":
				{
					cvar_set("_hud_configure", ftos(!autocvar__hud_configure));
					return;
				}

				case "quickmenu":
				{
					if (argv(2) == "help")
					{
						LOG_HELP(" quickmenu [[default | file | \"\"] <submenu> <filename>]");
						LOG_HELP("Called without options (or with \"\") loads either the default quickmenu or a quickmenu file if hud_panel_quickmenu_file is set to a valid filename.");
						LOG_HELP("A submenu name can be given to open the quickmenu directly in a submenu; it requires to specify 'default', 'file' or '\"\"' option.");
						LOG_HELP("A file name can also be given to open a different quickmenu");
						return;
					}
					string file = ((argv(4) == "") ? autocvar_hud_panel_quickmenu_file : argv(4));
					if (QuickMenu_IsOpened())
						QuickMenu_Close();
					else
						QuickMenu_Open(argv(2), argv(3), file);  // mode, submenu
					return;
				}

				case "save":
				{
					if (argv(2))
					{
						HUD_Panel_ExportCfg(argv(2));
						return;
					}
					else
					{
						break;  // go to usage, we're missing the paramater needed here.
					}
				}

				case "scoreboard_columns_set":
				{
					Cmd_Scoreboard_SetFields(argc);
					return;
				}

				case "scoreboard_columns_help":
				{
					Cmd_Scoreboard_Help();
					return;
				}

				case "radar":
				{
					if (argv(2))
						HUD_Radar_Show_Maximized(InterpretBoolean(argv(2)), 0);
					else
						HUD_Radar_Show_Maximized(!hud_panel_radar_maximized, 0);
					return;
				}

				case "clickradar":
				{
					if(!isdemo())
						HUD_Radar_Show_Maximized(!hud_panel_radar_mouse, 1);
					return;
				}
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd hud <action> [<configname> | <radartoggle> | <layout>]");
			LOG_HELP("  Where <action> is the command to complete,");
			LOG_HELP("  <configname> is the name to save to for 'save' action,");
			LOG_HELP("  <radartoggle> is to maximize/minimize radar for 'radar' action,");
			LOG_HELP("  and <layout> is how to organize the scoreboard columns for 'scoreboard_columns_set' action.");
			LOG_HELP("  Full list of commands here: configure, quickmenu, minigame, save, scoreboard_columns_help, scoreboard_columns_set, radar.");
			return;
		}
	}
}

void LocalCommand_localprint(int request, int argc)
{
	TC(int, request); TC(int, argc);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1))
			{
				centerprint_AddStandard(argv(1));
				return;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd localprint \"<message>\"");
			LOG_HELP("  <message> is the centerprint message to send to yourself.");
			return;
		}
	}
}

void LocalCommand_mv_download(int request, int argc)
{
	TC(int, request); TC(int, argc);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1))
			{
				Cmd_MapVote_MapDownload(argc);
				return;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd mv_download <mapid>");
			LOG_HELP("  Where <mapid> is the id number of the map to request an image of on the map vote selection menu.");
			return;
		}
	}
}

void LocalCommand_sendcvar(int request, int argc)
{
	TC(int, request); TC(int, argc);
	switch (request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if (argv(1))
			{
				// W_FixWeaponOrder will trash argv, so save what we need.
				string thiscvar = string_null; strcpy(thiscvar, argv(1));
				string s = cvar_string(thiscvar);

				if (thiscvar == "cl_weaponpriority")
					s = W_FixWeaponOrder(W_NumberWeaponOrder(s), 1);
				else if (substring(thiscvar, 0, 17) == "cl_weaponpriority" && strlen(thiscvar) == 18)
					s = W_FixWeaponOrder(W_NumberWeaponOrder(s), 0);

				localcmd("cmd sentcvar ", thiscvar, " \"", s, "\"\n");
				strfree(thiscvar);
				return;
			}
		}

		default:
			LOG_INFOF("Incorrect parameters for ^2%s^7", argv(0));
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd sendcvar <cvar>");
			LOG_HELP("  Where <cvar> is the cvar to send to the server.");
			return;
		}
	}
}

void LocalCommand_print_cptimes(int request)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			LOG_HELP(_("Checkpoint times:"));
			for (int i = 0; i <= 255; ++i)
			{
				if (race_checkpoint_splits[i])
					LOG_HELP(race_checkpoint_splits[i]);
			}
			return;
		}
		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 cl_cmd print_cptimes");
			LOG_HELP("  No arguments required, will show current or last run checkpoint times.");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order... also,
** ADD ALL NEW COMMANDS TO commands.cfg WITH PROPER ALIASES IN THE SAME FASHION!
void LocalCommand_(int request)
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
			LOG_HELP("Usage:^3 cl_cmd ");
			LOG_HELP("  No arguments required.");
			return;
		}
	}
}
*/


// ==================================
//  Macro system for client commands
// ==================================

// Normally do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
CLIENT_COMMAND(blurtest, "Feature for testing blur postprocessing") { LocalCommand_blurtest(request); }
CLIENT_COMMAND(boxparticles, "Spawn particles manually") { LocalCommand_boxparticles(request, arguments); }
CLIENT_COMMAND(create_scrshot_ent, "Create an entity at this location for automatic screenshots") { LocalCommand_create_scrshot_ent(request); }
CLIENT_COMMAND(debugmodel, "Spawn a debug model manually") { LocalCommand_debugmodel(request, arguments); }
CLIENT_COMMAND(handlevote, "System to handle selecting a vote or option") { LocalCommand_handlevote(request, arguments); }
CLIENT_COMMAND(hud, "Commands regarding/controlling the HUD system") { LocalCommand_hud(request, arguments); }
CLIENT_COMMAND(localprint, "Create your own centerprint sent to yourself") { LocalCommand_localprint(request, arguments); }
CLIENT_COMMAND(mv_download, "Retrieve mapshot picture from the server") { LocalCommand_mv_download(request, arguments); }
CLIENT_COMMAND(print_cptimes, "Print the stored checkpoint times for current or last run") { LocalCommand_print_cptimes(request); }
CLIENT_COMMAND(sendcvar, "Send a cvar to the server (like cl_weaponpriority)") { LocalCommand_sendcvar(request, arguments); }

void LocalCommand_macro_help()
{
	FOREACH(CLIENT_COMMANDS, true, LOG_HELPF("  ^2%s^7: %s", it.m_name, it.m_description));
}

bool LocalCommand_macro_command(int argc, string command)
{
	string c = strtolower(argv(0));
	FOREACH(CLIENT_COMMANDS, it.m_name == c, {
		it.m_invokecmd(it, CMD_REQUEST_COMMAND, NULL, argc, command);
		return true;
	});
	return false;
}

bool LocalCommand_macro_usage(int argc)
{
	string c = strtolower(argv(1));
	FOREACH(CLIENT_COMMANDS, it.m_name == c, {
		it.m_invokecmd(it, CMD_REQUEST_USAGE, NULL, argc, "");
		return true;
	});
	return false;
}

void LocalCommand_macro_write_aliases(int fh)
{
	FOREACH(CLIENT_COMMANDS, true, CMD_Write_Alias("qc_cmd_cl", it.m_name, it.m_description));
}


// =========================================
//  Main Function Called By Engine (cl_cmd)
// =========================================
// If this function exists, client code handles gamecommand instead of the engine code.

void GameCommand(string command)
{
	int argc = tokenize_console(command);

	// Guide for working with argc arguments by example:
	// argc:   1    - 2      - 3     - 4
	// argv:   0    - 1      - 2     - 3
	// cmd     vote - master - login - password
	string s = strtolower(argv(0));
	if (s == "help")
	{
		if (argc == 1)
		{
			LOG_HELP("Client console commands:");
			LocalCommand_macro_help();

			LOG_HELP("\nGeneric commands shared by all programs:");
			GenericCommand_macro_help();

			LOG_HELP("\nUsage:^3 cl_cmd <command>^7, where possible commands are listed above.");
			LOG_HELP("For help about a specific command, type cl_cmd help <command>");

			return;
		}
		else if (GenericCommand_macro_usage(argc))  // Instead of trying to call a command, we're going to see detailed information about it
		{
			return;
		}
		else if (LocalCommand_macro_usage(argc))  // now try for normal commands too
		{
			return;
		}
	}
	// continue as usual and scan for normal commands
	if (GenericCommand(command)                                    // handled by common/command/generic.qc
	    || LocalCommand_macro_command(argc, command)               // handled by one of the above LocalCommand_* functions
	    || MUTATOR_CALLHOOK(CSQC_ConsoleCommand, s, argc, command) // handled by a mutator
	   ) return;

	// nothing above caught the command, must be invalid
	LOG_INFO(((command != "") ? strcat("Unknown client command \"", command, "\"") : "No command provided"), ". For a list of supported commands, try cl_cmd help.");
}


// ===================================
//  Macro system for console commands
// ===================================

// These functions are here specifically to add special + - commands to the game, and are not really normal commands.
// Please add client commands to the function above this, as this is only for special reasons.
// NOTE: showaccuracy is kept as legacy command
#define CONSOLE_COMMANDS_NORMAL() \
	CONSOLE_COMMAND("+showaccuracy", { }) \
	CONSOLE_COMMAND("-showaccuracy", { }) \
	/* nothing */

#define CONSOLE_COMMANDS_MOVEMENT() \
	CONSOLE_COMMAND("+forward", { ++camera_direction.x; }) \
	CONSOLE_COMMAND("-forward", { --camera_direction.x; }) \
	CONSOLE_COMMAND("+back", { --camera_direction.x; }) \
	CONSOLE_COMMAND("-back", { ++camera_direction.x; }) \
	CONSOLE_COMMAND("+moveup", { ++camera_direction.z; }) \
	CONSOLE_COMMAND("-moveup", { --camera_direction.z; }) \
	CONSOLE_COMMAND("+movedown", { --camera_direction.z; }) \
	CONSOLE_COMMAND("-movedown", { ++camera_direction.z; }) \
	CONSOLE_COMMAND("+moveright", { --camera_direction.y; }) \
	CONSOLE_COMMAND("-moveright", { ++camera_direction.y; }) \
	CONSOLE_COMMAND("+moveleft", { ++camera_direction.y; }) \
	CONSOLE_COMMAND("-moveleft", { --camera_direction.y; }) \
	CONSOLE_COMMAND("+roll_right", { ++camera_roll; }) \
	CONSOLE_COMMAND("-roll_right", { --camera_roll; }) \
	CONSOLE_COMMAND("+roll_left", { --camera_roll; }) \
	CONSOLE_COMMAND("-roll_left", { ++camera_roll; }) \
	/* nothing */

void ConsoleCommand_macro_init()
{
	// first init normal commands
	#define CONSOLE_COMMAND(name, execution) \
		{ registercommand(name); }

	CONSOLE_COMMANDS_NORMAL();
	#undef CONSOLE_COMMAND

	// then init movement commands
	#ifndef CAMERATEST
	if (isdemo())
	{
	#endif
	#define CONSOLE_COMMAND(name, execution) \
		registercommand(name);

	CONSOLE_COMMANDS_MOVEMENT();
		#undef CONSOLE_COMMAND
	#ifndef CAMERATEST
}
	#endif
}

bool ConsoleCommand_macro_normal(string s, int argc)
{
	#define CONSOLE_COMMAND(name, execution) \
		{ if (name == s) { { execution } return true; } }

	CONSOLE_COMMANDS_NORMAL();
	#undef CONSOLE_COMMAND

	return false;
}

bool ConsoleCommand_macro_movement(string s, int argc)
{
	if (camera_active)
	{
		#define CONSOLE_COMMAND(name, execution) \
			{ if (name == s) { { execution } return true; } }

		CONSOLE_COMMANDS_MOVEMENT();
		#undef CONSOLE_COMMAND
	}

	return false;
}


// ======================================================
//  Main Function Called By Engine (registered commands)
// ======================================================
// Used to parse commands in the console that have been registered with the "registercommand" function

bool CSQC_ConsoleCommand(string command)
{
	int argc = tokenize_console(command);
	string s = strtolower(argv(0));
	// Return value should be true if CSQC handled the command, otherwise return false to have the engine handle it.
	return ConsoleCommand_macro_normal(s, argc)
	       || ConsoleCommand_macro_movement(s, argc)
	;
}
