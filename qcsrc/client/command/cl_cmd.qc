// ==============================================
//  CSQC client commands code, written by Samual
//  Last updated: December 16th, 2011
// ==============================================

float cvar_clientsettemp(string tmp_cvar, string value)
{
	float created_saved_value;
	entity e;
	
	if not(tmp_cvar || value)
	{
		dprint("Error: Invalid usage of cvar_clientsettemp(string, string); !\n");
		return FALSE;
	}
	
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		if(e.netname == tmp_cvar)
			goto saved; // skip creation
			
	// creating a new entity to keep track of this cvar
	e = spawn();
	e.classname = "saved_cvar_value";
	e.netname = strzone(tmp_cvar);
	e.message = strzone(cvar_string(tmp_cvar));
	created_saved_value = TRUE;
	
	// an entity for this cvar already exists
	:saved
	
	// update the cvar to the value given
	cvar_set(tmp_cvar, value);
	
	return created_saved_value;
}

float cvar_clientsettemp_restore()
{
	float i;
	entity e;
	
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		{ cvar_set(e.netname, e.message); ++i; } 
		
	return i;
}

void DrawDebugModel()
{
	if(time - floor(time) > 0.5)
	{
		PolyDrawModel(self);
		self.drawmask = 0;
	}
	else
	{
		self.renderflags = 0;
		self.drawmask = MASK_NORMAL;
	}
}


// =======================
//  Command Sub-Functions
// =======================

void GameCommand_blurtest(float request)
{
	// Simple command to work with postprocessing temporarily... possibly completely pointless, the glsl shader is used for a real feature now...
	// Anyway, to enable it, just compile the client with -DBLURTEST and then you can use the command.
	
	#ifdef BLURTEST
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			blurtest_time0 = time;
			blurtest_time1 = time + stof(argv(1));
			blurtest_radius = stof(argv(2));
			blurtest_power = stof(argv(3));
			print("Enabled blurtest\n");
			return; 
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd blurtest\n");
			print("  No arguments required.\n");
			return;
		}
	}
	#else
	if(request)
	{
		print("Blurtest is not enabled on this client.\n");
		return;
	}
	#endif
}

void GameCommand_debugmodel(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			string modelname = argv(1);
			entity debugmodel_entity;
			
			debugmodel_entity = spawn();
			precache_model(modelname);
			setmodel(debugmodel_entity, modelname);
			setorigin(debugmodel_entity, view_origin);
			debugmodel_entity.angles = view_angles;
			debugmodel_entity.draw = DrawDebugModel;
			debugmodel_entity.classname = "debugmodel";
			
			return; 
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd debugmodel model\n");
			print("  Where 'model' is a string of the model name to use for the debug model.\n");
			return;
		}
	}
}

void GameCommand_handlevote(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float vote_selection;
			string vote_string;
			
			switch(argv(1))
			{
				case "yes": vote_selection = 2; vote_string = "yes"; break;
				case "no": vote_selection = 1; vote_string = "no"; break;
				default: break;
			}
			
			if(vote_selection)
			{
				if(uid2name_dialog) // handled by "uid2name" option
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
			print("Incorrect parameters for ^2handlevote^7\n");
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd handlevote vote\n");
			print("  Where 'vote' is the selection for either the current poll or uid2name.\n");
			return;
		}
	}
}

void GameCommand_hud(float request, float argc) // TODO: Add aliases in commands.cfg
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			switch(argv(1))
			{
				case "configure":
				{
					cvar_set("_hud_configure", ftos(!autocvar__hud_configure));
					return;
				}
				
				case "save":
				{
					if(argv(2))
					{
						HUD_Panel_ExportCfg(argv(2));
						return;
					}
					else
					{
						break; // go to usage, we're missing the paramater needed here.
					}
				}
				
				case "radar":
				{
					if(argv(2))
						hud_panel_radar_maximized = (stof(argv(2)) != 0);
					else
						hud_panel_radar_maximized = !hud_panel_radar_maximized;
					
					return;
				}
				
				case "scoreboard_columns_set":
				{
					Cmd_HUD_SetFields(argc); // todo update this function
					
					return;
				}

				case "scoreboard_columns_help":
				{
					Cmd_HUD_Help(argc); // todo update this function
					
					return;
				}
			}
			return; 
		}
			
		default:
			print("Incorrect parameters for ^2hud^7\n");
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd hud action [configname | radartoggle]\n");
			print("  Where 'action' is the command to complete,\n");
			print("  'configname' is the name to save to for \"save\" action,\n");
			print("  and 'radartoggle' is to control hud_panel_radar_maximized for \"radar\" action.\n");
			print("  Full list of commands here: \"configure, save, radar.\"\n");
			return;
		}
	}
}

void GameCommand_mv_download(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			Cmd_MapVote_MapDownload(argc);
			
			return; 
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd mapvote_download mapid\n");
			print("  Where 'mapid' is the id number of the map to request an image of on the map vote selection menu.\n");
			return;
		}
	}
}

void GameCommand_sendcvar(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			// W_FixWeaponOrder will trash argv, so save what we need.
			string thiscvar = strzone(argv(1));
			string s = cvar_string(thiscvar);
			
			if(thiscvar == "cl_weaponpriority")
				s = W_FixWeaponOrder(W_NumberWeaponOrder(s), 1);
			else if(substring(thiscvar, 0, 17) == "cl_weaponpriority" && strlen(thiscvar) == 18)
				s = W_FixWeaponOrder(W_NumberWeaponOrder(s), 0);
				
			localcmd("cmd sentcvar ", thiscvar, " \"", s, "\"\n");
			strunzone(thiscvar);
			
			return; 
		}
			
		default:
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd sendcvar <cvar>\n");
			print("  Where 'cvar' is the cvar plus arguments to send to the server.\n");
			return;
		}
	}
}

void GameCommand_settemp(float request, float argc)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			if((argv(1) == "restore") && (argc == 2))
			{
				float i = cvar_clientsettemp_restore();
				
				if(i)
					dprint("Restored ", ftos(i), " temporary cvar settings to their original values.\n");
				else
					dprint("Nothing to restore.\n");
				
				return;
			}
			else if(argc >= 3)
			{
				if(cvar_clientsettemp(argv(1), argv(2)))
					dprint("Creating new settemp tracker for ", argv(1), " and setting it to \"", argv(2), "\" temporarily.\n"); 
				else
					dprint("Already had a tracker for ", argv(1), ", updating it to \"", argv(2), "\".\n");
			
				return;
			}
		}
			
		default:
			print("Incorrect parameters for ^2settemp^7\n");
		case CMD_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd settemp <cvar> | [restore]\n");
			print("  Where 'cvar' is the cvar plus arguments to send to the server,\n");
			print("  or 'restore' allows you to restore all of the original temporary cvar values.\n");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order.
void GameCommand_(float request)
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
			print("\nUsage:^3 cl_cmd \n");
			print("  No arguments required.\n");
			return;
		}
	}
}
*/


// ==================================
//  Macro system for client commands
// ==================================

// Do not hard code aliases for these, instead create them in commands.cfg... also: keep in alphabetical order, please ;)
#define CLIENT_COMMANDS(request,arguments) \
	CLIENT_COMMAND("blurtest", GameCommand_blurtest(request), "Feature for testing blur postprocessing") \
	CLIENT_COMMAND("debugmodel", GameCommand_debugmodel(request, arguments), "Spawn a debug model manually") \
	CLIENT_COMMAND("handlevote", GameCommand_handlevote(request, arguments), "System to handle selecting a vote or option") \
	CLIENT_COMMAND("hud", GameCommand_hud(request, arguments), "Commands regarding/controlling the HUD system") \
	CLIENT_COMMAND("mv_download", GameCommand_mv_download(request, arguments), "Retrieve mapshot picture from the server") \
	CLIENT_COMMAND("sendcvar", GameCommand_sendcvar(request, arguments), "Send a cvar to the server (like weaponpriority)") \
	CLIENT_COMMAND("settemp", GameCommand_settemp(request, arguments), "Temporarily set a value to a cvar which is restored by command or end of each match") \
	/* nothing */
	
void GameCommand_macro_help()
{
	#define CLIENT_COMMAND(name,function,description) \
		{ print("  ^2", name, "^7: ", description, "\n"); }
		
	CLIENT_COMMANDS(0, 0)
	#undef CLIENT_COMMAND
	
	return;
}

float GameCommand_macro_command(float argc)
{
	#define CLIENT_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(0))) { function; return TRUE; } }
		
	CLIENT_COMMANDS(CMD_REQUEST_COMMAND, argc)
	#undef CLIENT_COMMAND
	
	return FALSE;
}

float GameCommand_macro_usage(float argc)
{
	#define CLIENT_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(1))) { function; return TRUE; } }
		
	CLIENT_COMMANDS(CMD_REQUEST_USAGE, argc)
	#undef CLIENT_COMMAND
	
	return FALSE;
}


// =========================================
//  Main Function Called By Engine (cl_cmd)
// =========================================
// If this function exists, client code handles gamecommand instead of the engine code.

void GameCommand(string command)
{
	float argc = tokenize_console(command);

	if(strtolower(argv(0)) == "help") 
	{
		if(argc == 1) 
		{
			print("\nUsage:^3 cl_cmd COMMAND...^7, where possible commands are:\n");
			GameCommand_macro_help();
			GameCommand_Generic("help");
			print("For help about specific commands, type cl_cmd help COMMAND\n");
			return;
		} 
		else if(GameCommand_macro_usage(argc)) // Instead of trying to call a command, we're going to see detailed information about it
		{
			return;
		}
	} 
	else if(GameCommand_Generic(command)) 
	{
		return; // handled by common/gamecommand.qc
	}
	else if(GameCommand_macro_command(argc)) // continue as usual and scan for normal commands
	{
		return; // handled by one of the above GameCommand_* functions
	}
	
	// nothing above caught the command, must be invalid
	print("Unknown client command", ((command != "") ? strcat(" \"", command, "\"") : ""), ". For a list of supported commands, try cl_cmd help.\n");
	
	return;
}


// ===================================
//  Macro system for console commands
// ===================================

// These functions are here specifically to add special + - commands to the game, and are not really normal commands.
// Please add client commands to the function above this, as this is only for special reasons.
#define CONSOLE_COMMANDS_NORMAL \
	CONSOLE_COMMAND("+showscores", { scoreboard_showscores = TRUE; }) \
	CONSOLE_COMMAND("-showscores", { scoreboard_showscores = FALSE; }) \
	CONSOLE_COMMAND("+showaccuracy", { scoreboard_showaccuracy = TRUE; }) \
	CONSOLE_COMMAND("-showaccuracy", { scoreboard_showaccuracy = FALSE; }) \
	/* nothing */
	
#define CONSOLE_COMMANDS_MOVEMENT \
	CONSOLE_COMMAND("+forward", { ++camera_direction_x; }) \
	CONSOLE_COMMAND("-forward", { --camera_direction_x; }) \
	CONSOLE_COMMAND("+back", { --camera_direction_x; }) \
	CONSOLE_COMMAND("-back", { ++camera_direction_x; }) \
	CONSOLE_COMMAND("+moveup", { ++camera_direction_z; }) \
	CONSOLE_COMMAND("-moveup", { --camera_direction_z; }) \
	CONSOLE_COMMAND("+movedown", { --camera_direction_z; }) \
	CONSOLE_COMMAND("-movedown", { ++camera_direction_z; }) \
	CONSOLE_COMMAND("+moveright", { --camera_direction_y; }) \
	CONSOLE_COMMAND("-moveright", { ++camera_direction_y; }) \
	CONSOLE_COMMAND("+moveleft", { ++camera_direction_y; }) \
	CONSOLE_COMMAND("-moveleft", { --camera_direction_y; }) \
	CONSOLE_COMMAND("+roll_right", { ++camera_roll; }) \
	CONSOLE_COMMAND("-roll_right", { --camera_roll; }) \
	CONSOLE_COMMAND("+roll_left", { --camera_roll; }) \
	CONSOLE_COMMAND("-roll_left", { ++camera_roll; }) \
	/* nothing */

void ConsoleCommand_macro_init()
{
	// first init normal commands
	#define CONSOLE_COMMAND(name,execution) \
		{ registercommand(name); }

	CONSOLE_COMMANDS_NORMAL
	#undef CONSOLE_COMMAND
	
	// then init movement commands
	#ifndef CAMERATEST
	if(isdemo())
	{
	#endif
		#define CONSOLE_COMMAND(name,execution) \
			{ registercommand(name); }

		CONSOLE_COMMANDS_MOVEMENT
		#undef CONSOLE_COMMAND
	#ifndef CAMERATEST
	}
	#endif
	
	return;
}

float ConsoleCommand_macro_normal(float argc)
{
	#define CONSOLE_COMMAND(name,execution) \
		{ if(name == strtolower(argv(0))) { { execution } return TRUE; } }
		
	CONSOLE_COMMANDS_NORMAL
	#undef CONSOLE_COMMAND
	
	return FALSE;
}

float ConsoleCommand_macro_movement(float argc)
{
	if(camera_active)
	{
		#define CONSOLE_COMMAND(name,execution) \
			{ if(name == strtolower(argv(0))) { { execution } return TRUE; } }

		CONSOLE_COMMANDS_MOVEMENT
		#undef CONSOLE_COMMAND
	}
	
	return FALSE;
}


// ======================================================
//  Main Function Called By Engine (registered commands)
// ======================================================
// Used to parse commands in the console that have been registered with the "registercommand" function

float CSQC_ConsoleCommand(string command)
{
	float argc = tokenize_console(command);

	if(ConsoleCommand_macro_normal(argc))
	{
		return TRUE;
	}
	else if(ConsoleCommand_macro_movement(argc))
	{
		return TRUE;
	}
	
	// Return value should be 1 if CSQC handled the command, otherwise return 0 to have the engine handle it.

	return FALSE;
}