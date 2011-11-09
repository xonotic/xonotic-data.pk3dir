// ==============================================
//  CSQC client commands code, written by Samual
//  Last updated: November 8th, 2011
// ==============================================

#define GC_REQUEST_COMMAND 1
#define GC_REQUEST_USAGE 2

void Cmd_HUD_SetFields(float);
void Cmd_HUD_Help(float);

.vector view_ofs;
entity debug_shotorg;


// ============================
//  Misc. Supporting Functions
// ============================

void cvar_clientsettemp(string cv, string val)
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		if(e.netname == cv)
			goto saved;
	e = spawn();
	e.classname = "saved_cvar_value";
	e.netname = strzone(cv);
	e.message = strzone(cvar_string(cv));
	:saved
	cvar_set(cv, val);
}

void cvar_clientsettemp_restore()
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
			cvar_set(e.netname, e.message);
}
void ShotOrg_Draw()
{
	self.origin = view_origin + view_forward * self.view_ofs_x + view_right * self.view_ofs_y + view_up * self.view_ofs_z;
	self.angles = view_angles;
	self.angles_x = -self.angles_x;
	if not(self.cnt)
		self.drawmask = MASK_NORMAL;
	else
		self.drawmask = 0;
}
void ShotOrg_Draw2D()
{
	vector coord2d_topleft, coord2d_topright, coord2d;
	string s;
	vector fs;

	s = vtos(self.view_ofs);
	s = substring(s, 1, strlen(s) - 2);
	if(tokenize_console(s) == 3)
		s = strcat(argv(0), " ", argv(1), " ", argv(2));

	coord2d_topleft = project_3d_to_2d(self.origin + view_up * 4 - view_right * 4);
	coord2d_topright = project_3d_to_2d(self.origin + view_up * 4 + view_right * 4);

	fs = '1 1 0' * ((coord2d_topright_x - coord2d_topleft_x) / stringwidth(s, FALSE, '8 8 0'));

	coord2d = coord2d_topleft;
	if(fs_x < 8)
	{
		coord2d_x += (coord2d_topright_x - coord2d_topleft_x) * (1 - 8 / fs_x) * 0.5;
		fs = '8 8 0';
	}
	coord2d_y -= fs_y;
	coord2d_z = 0;
	drawstring(coord2d, s, fs, '1 1 1', 1, 0);
}

void ShotOrg_Spawn()
{
	debug_shotorg = spawn();
	debug_shotorg.draw = ShotOrg_Draw;
	debug_shotorg.draw2d = ShotOrg_Draw2D;
	debug_shotorg.renderflags = RF_VIEWMODEL;
	debug_shotorg.effects = EF_FULLBRIGHT;
	precache_model("models/shotorg_adjuster.md3");
	setmodel(debug_shotorg, "models/shotorg_adjuster.md3");
	debug_shotorg.scale = 2;
	debug_shotorg.view_ofs = '25 8 -8';
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
		case GC_REQUEST_COMMAND:
		{
			blurtest_time0 = time;
			blurtest_time1 = time + stof(argv(1));
			blurtest_radius = stof(argv(2));
			blurtest_power = stof(argv(3));
			print("Enabled blurtest\n");
			return; 
		}
			
		default:
		case GC_REQUEST_USAGE:
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

void GameCommand_hud(float request, float argc)
{
	switch(request)
	{
		case GC_REQUEST_COMMAND:
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
				}
			}
			return; 
		}
			
		default:
		case GC_REQUEST_USAGE:
		{
			print("\nUsage:^3 cl_cmd hud TODO\n");
			print("  No arguments required.\n");
			return;
		}
	}
}

/* use this when creating a new command, making sure to place it in alphabetical order.
void GameCommand_(float request)
{
	switch(request)
	{
		case GC_REQUEST_COMMAND:
		{
			
			return; 
		}
			
		default:
		case GC_REQUEST_USAGE:
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
	CLIENT_COMMAND("hud", GameCommand_hud(request, arguments), "Commands regarding/controlling the HUD system") \
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
		
	CLIENT_COMMANDS(GC_REQUEST_COMMAND, argc)
	#undef CLIENT_COMMAND
	
	return FALSE;
}

float GameCommand_macro_usage(float argc)
{
	#define CLIENT_COMMAND(name,function,description) \
		{ if(name == strtolower(argv(1))) { function; return TRUE; } }
		
	CLIENT_COMMANDS(GC_REQUEST_USAGE, argc)
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
	print("Invalid command. For a list of supported commands, try cl_cmd help.\n");
	
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
		{ registercmd(name); }

	CONSOLE_COMMANDS_NORMAL
	#undef CONSOLE_COMMAND
	
	// then init movement commands
	#ifndef CAMERATEST
	if(isdemo())
	{
	#endif
		#define CONSOLE_COMMAND(name,execution) \
			{ registercmd(name); }

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
// Used to parse commands in the console that have been registered with the "registercmd" function

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