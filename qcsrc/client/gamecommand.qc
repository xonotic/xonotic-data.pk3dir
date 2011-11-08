// --------------------------------------------------------------------------
// BEGIN REQUIRED CSQC FUNCTIONS
//include "main.qh"

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

.vector view_ofs;
entity debug_shotorg;
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
void Cmd_HUD_SetFields(float);
void Cmd_HUD_Help(float);
void GameCommand(string msg)
{
	string s;
	float argc;
	entity e;
	argc = tokenize_console(msg);

	if(argv(0) == "help" || argc == 0)
	{
		print(_("Usage: cl_cmd COMMAND..., where possible commands are:\n"));
		print(_("  settemp cvar value\n"));
		print(_("  scoreboard_columns_set ...\n"));
		print(_("  scoreboard_columns_help\n"));
		GameCommand_Generic("help");
		return;
	}

	if(GameCommand_Generic(msg))
		return;

	if(strCmd == "hud_configure") { // config hud
		cvar_set("_hud_configure", ftos(!autocvar__hud_configure));
		return true;
	} else if(strCmd == "hud_save") { // save hud config
		if(argv(1) == "" || argv(2)) {
			print(_("Usage:\n"));
			print(_("hud_save configname   (saves to hud_skinname_configname.cfg)\n"));
		}
		else
			HUD_Panel_ExportCfg(argv(1));
		return true;

	string cmd;
	cmd = argv(0);
	if(cmd == "mv_download") {
		Cmd_MapVote_MapDownload(argc);
	}
	else if(cmd == "hud_panel_radar_maximized")
	{
		if(argc == 1)
			hud_panel_radar_maximized = !hud_panel_radar_maximized;
		else
			hud_panel_radar_maximized = (stof(argv(1)) != 0);
	}
	else if(cmd == "settemp") {
		cvar_clientsettemp(argv(1), argv(2));
	}
	else if(cmd == "scoreboard_columns_set") {
		Cmd_HUD_SetFields(argc);
	}
	else if(cmd == "scoreboard_columns_help") {
		Cmd_HUD_Help(argc);
	}
#ifdef BLURTEST
	else if(cmd == "blurtest") {
		blurtest_time0 = time;
		blurtest_time1 = time + stof(argv(1));
		blurtest_radius = stof(argv(2));
		blurtest_power = stof(argv(3));
	}
#endif
	else if(cmd == "shotorg_move") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs + stov(argv(1));
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_movez") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs + stof(argv(1)) * (debug_shotorg.view_ofs * (1 / debug_shotorg.view_ofs_x)); // closer/farther, same xy pos
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_set") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = stov(argv(1));
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_setz") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs * (stof(argv(1)) / debug_shotorg.view_ofs_x); // closer/farther, same xy pos
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_toggle_hide") {
		if(debug_shotorg)
		{
			debug_shotorg.cnt = !debug_shotorg.cnt;
		}
	}
	else if(cmd == "shotorg_end") {
		if(debug_shotorg)
		{
			print(vtos(debug_shotorg.view_ofs), "\n");
			remove(debug_shotorg);
			debug_shotorg = world;
		}
		localcmd("sv_cmd debug_shotorg\n");
	}
	else if(cmd == "sendcvar") {
		// W_FixWeaponOrder will trash argv, so save what we need.
		string thiscvar;
		thiscvar = strzone(argv(1));
		s = cvar_string(thiscvar);
		if(thiscvar == "cl_weaponpriority")
			s = W_FixWeaponOrder(W_NumberWeaponOrder(s), 1);
		else if(substring(thiscvar, 0, 17) == "cl_weaponpriority" && strlen(thiscvar) == 18)
			s = W_FixWeaponOrder(W_NumberWeaponOrder(s), 0);
		localcmd("cmd sentcvar ", thiscvar, " \"", s, "\"\n");
		strunzone(thiscvar);
	}
	else if(cmd == "spawn") {
		s = argv(1);
		e = spawn();
		precache_model(s);
		setmodel(e, s);
		setorigin(e, view_origin);
		e.angles = view_angles;
		e.draw = DrawDebugModel;
		e.classname = "debugmodel";
	}
    else if(cmd == "vyes")
    {
        if(uid2name_dialog)
        {
            vote_active = 0; // force the panel to disappear right as we have selected the value (to prevent it from fading out in the normal vote panel pos)
            vote_prev = 0;
            localcmd("setreport cl_allow_uid2name 1\n");
            vote_change = -9999;
			uid2name_dialog = 0;
        }
        else
        {
            localcmd("cmd vote yes\n");
        }
    }
    else if(cmd == "vno")
    {
        if(uid2name_dialog)
        {
            vote_active = 0;
            vote_prev = 0;
            localcmd("setreport cl_allow_uid2name 0\n");
            vote_change = -9999;
			uid2name_dialog = 0;
        }
        else
        {
            localcmd("cmd vote no\n");
        }
    }

	else
	{
		print("Invalid command. For a list of supported commands, try cl_cmd help.\n");
	}

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
		{ if(name == strtolower(argv(0))) { execution; return TRUE; } }
		
	CONSOLE_COMMANDS_NORMAL
	#undef CONSOLE_COMMAND
	
	return FALSE;
}

float ConsoleCommand_macro_movement(float argc)
{
	if(camera_active)
	{
		#define CONSOLE_COMMAND(name,execution) \
			{ if(name == strtolower(argv(0))) { execution; return TRUE; } }

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