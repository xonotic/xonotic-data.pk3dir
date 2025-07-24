#include "hud_config.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <client/hud/panel/chat.qh>
#include <client/hud/panel/scoreboard.qh>
#include <client/view.qh>

// Save the config
void HUD_Panel_ExportCfg(string cfgname)
{
	float fh;
	string filename = strcat("hud_", autocvar_hud_skin, "_", cfgname, ".cfg");
	string str = "";
	fh = fopen(filename, FILE_WRITE);
	if(fh >= 0)
	{
		HUD_Write("//title \n");
		HUD_Write("//author \n");
		HUD_Write("\n");
		HUD_Write_Cvar("hud_skin");
		HUD_Write_Cvar("hud_panel_bg");
		HUD_Write_Cvar("hud_panel_bg_color");
		HUD_Write_Cvar("hud_panel_bg_color_team");
		HUD_Write_Cvar("hud_panel_bg_alpha");
		HUD_Write_Cvar("hud_panel_bg_border");
		HUD_Write_Cvar("hud_panel_bg_padding");
		HUD_Write_Cvar("hud_panel_fg_alpha");
		HUD_Write("\n");

		HUD_Write_Cvar("hud_dock");
		HUD_Write_Cvar("hud_dock_color");
		HUD_Write_Cvar("hud_dock_color_team");
		HUD_Write_Cvar("hud_dock_alpha");
		HUD_Write("\n");

		HUD_Write_Cvar("hud_progressbar_alpha");
		HUD_Write_Cvar("hud_progressbar_strength_color");
		HUD_Write_Cvar("hud_progressbar_superweapons_color");
		HUD_Write_Cvar("hud_progressbar_shield_color");
		HUD_Write_Cvar("hud_progressbar_health_color");
		HUD_Write_Cvar("hud_progressbar_armor_color");
		HUD_Write_Cvar("hud_progressbar_fuel_color");
		HUD_Write_Cvar("hud_progressbar_oxygen_color");
		HUD_Write_Cvar("hud_progressbar_nexball_color");
		HUD_Write_Cvar("hud_progressbar_speed_color");
		HUD_Write_Cvar("hud_progressbar_acceleration_color");
		HUD_Write_Cvar("hud_progressbar_acceleration_neg_color");
		HUD_Write_Cvar("hud_progressbar_vehicles_ammo1_color");
		HUD_Write_Cvar("hud_progressbar_vehicles_ammo2_color");
		HUD_Write("\n");

		HUD_Write_Cvar("_hud_panelorder");
		HUD_Write("\n");

		HUD_Write_Cvar("hud_configure_grid");
		HUD_Write_Cvar("hud_configure_grid_xsize");
		HUD_Write_Cvar("hud_configure_grid_ysize");
		HUD_Write("\n");

		// common cvars for all panels
		for (int i = 0; i < REGISTRY_COUNT(hud_panels); ++i)
		{
			panel = REGISTRY_GET(hud_panels, i);

			HUD_Write_PanelCvar("_pos");
			HUD_Write_PanelCvar("_size");
			HUD_Write_PanelCvar("_bg");
			HUD_Write_PanelCvar("_bg_color");
			HUD_Write_PanelCvar("_bg_color_team");
			HUD_Write_PanelCvar("_bg_alpha");
			HUD_Write_PanelCvar("_bg_border");
			HUD_Write_PanelCvar("_bg_padding");
			panel.panel_export(fh);
			HUD_Write("\n");
		}

		HUD_Write("menu_sync\n"); // force the menu to reread the cvars, so that the dialogs are updated

		LOG_INFOF(_("^2Successfully exported to %s! (Note: It's saved in data/data/)"), filename);
		fclose(fh);
	}
	else
		LOG_INFOF(_("^1Couldn't write to %s"), filename);
}

void HUD_Configure_Exit_Force()
{
	if (hud_configure_menu_open)
	{
		hud_configure_menu_open = 0;
		localcmd("togglemenu\n");
	}
	cursor_type = CURSOR_NORMAL;
	cvar_set("_hud_configure", "0");
}

// check if move will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckMove(vector myPos, vector mySize)
{
	vector myCenter, targCenter;
	vector myTarget = myPos;
	int i;
	for (i = 0; i < REGISTRY_COUNT(hud_panels); ++i) {
		panel = REGISTRY_GET(hud_panels, i);
		if(!(panel.panel_configflags & PANEL_CONFIG_MAIN)) continue;
		if(panel == highlightedPanel) continue;
		HUD_Panel_UpdatePosSize();
		if(!panel_enabled) continue;

		panel_pos -= '1 1 0' * panel_bg_border;
		panel_size += '2 2 0' * panel_bg_border;

		if(myPos.y + mySize.y < panel_pos.y)
			continue;
		if(myPos.y > panel_pos.y + panel_size.y)
			continue;

		if(myPos.x + mySize.x < panel_pos.x)
			continue;
		if(myPos.x > panel_pos.x + panel_size.x)
			continue;

		// OK, there IS a collision.

		myCenter.x = myPos.x + 0.5 * mySize.x;
		myCenter.y = myPos.y + 0.5 * mySize.y;

		targCenter.x = panel_pos.x + 0.5 * panel_size.x;
		targCenter.y = panel_pos.y + 0.5 * panel_size.y;

		if(myCenter.x < targCenter.x && myCenter.y < targCenter.y) // top left (of the target panel)
		{
			if(myPos.x + mySize.x - panel_pos.x < myPos.y + mySize.y - panel_pos.y) // push it to the side
				myTarget.x = panel_pos.x - mySize.x;
			else // push it upwards
				myTarget.y = panel_pos.y - mySize.y;
		}
		else if(myCenter.x > targCenter.x && myCenter.y < targCenter.y) // top right
		{
			if(panel_pos.x + panel_size.x - myPos.x < myPos.y + mySize.y - panel_pos.y) // push it to the side
				myTarget.x = panel_pos.x + panel_size.x;
			else // push it upwards
				myTarget.y = panel_pos.y - mySize.y;
		}
		else if(myCenter.x < targCenter.x && myCenter.y > targCenter.y) // bottom left
		{
			if(myPos.x + mySize.x - panel_pos.x < panel_pos.y + panel_size.y - myPos.y) // push it to the side
				myTarget.x = panel_pos.x - mySize.x;
			else // push it downwards
				myTarget.y = panel_pos.y + panel_size.y;
		}
		else if(myCenter.x > targCenter.x && myCenter.y > targCenter.y) // bottom right
		{
			if(panel_pos.x + panel_size.x - myPos.x < panel_pos.y + panel_size.y - myPos.y) // push it to the side
				myTarget.x = panel_pos.x + panel_size.x;
			else // push it downwards
				myTarget.y = panel_pos.y + panel_size.y;
		}
		//if(cvar("hud_configure_checkcollisions_debug"))
			//drawfill(panel_pos, panel_size, '1 1 0', .3, DRAWFLAG_NORMAL);
	}

	return myTarget;
}

void HUD_Panel_SetPos(vector pos)
{
	panel = highlightedPanel;
	HUD_Panel_UpdatePosSize();
	vector mySize;
	mySize = panel_size;

	//if(cvar("hud_configure_checkcollisions_debug"))
		//drawfill(pos, mySize, '1 1 1', .2, DRAWFLAG_NORMAL);

	if(autocvar_hud_configure_grid)
	{
		pos.x = floor((pos.x/vid_conwidth)/hud_configure_gridSize.x + 0.5) * hud_configure_realGridSize.x;
		pos.y = floor((pos.y/vid_conheight)/hud_configure_gridSize.y + 0.5) * hud_configure_realGridSize.y;
	}

	if(hud_configure_checkcollisions)
		pos = HUD_Panel_CheckMove(pos, mySize);

	pos.x = bound(0, pos.x, vid_conwidth - mySize.x);
	pos.y = bound(0, pos.y, vid_conheight - mySize.y);

	string s;
	s = strcat(ftos_mindecimals(pos.x/vid_conwidth), " ", ftos_mindecimals(pos.y/vid_conheight));

	cvar_set(strcat("hud_panel_", highlightedPanel.panel_name, "_pos"), s);
}

// check if resize will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckResize(vector mySize, vector resizeorigin) {
	vector targEndPos;
	vector dist;
	float ratio = mySize.x/mySize.y;
	int i;
	for (i = 0; i < REGISTRY_COUNT(hud_panels); ++i) {
		panel = REGISTRY_GET(hud_panels, i);
		if(!(panel.panel_configflags & PANEL_CONFIG_MAIN)) continue;
		if(panel == highlightedPanel) continue;
		HUD_Panel_UpdatePosSize();
		if(!panel_enabled) continue;

		panel_pos -= '1 1 0' * panel_bg_border;
		panel_size += '2 2 0' * panel_bg_border;

		targEndPos = panel_pos + panel_size;

		// resizeorigin is WITHIN target panel, just abort any collision testing against that particular panel to produce expected behaviour!
		if(resizeorigin.x > panel_pos.x && resizeorigin.x < targEndPos.x && resizeorigin.y > panel_pos.y && resizeorigin.y < targEndPos.y)
			continue;

		if (resizeCorner == 1)
		{
			// check if this panel is on our way
			if (resizeorigin.x <= panel_pos.x)
				continue;
			if (resizeorigin.y <= panel_pos.y)
				continue;
			if (targEndPos.x <= resizeorigin.x - mySize.x)
				continue;
			if (targEndPos.y <= resizeorigin.y - mySize.y)
				continue;

			// there is a collision:
			// detect which side of the panel we are facing is actually limiting the resizing
			// (which side the resize direction finds for first) and reduce the size up to there
			//
			// dist is the distance between resizeorigin and the "analogous" point of the panel
			// in this case between resizeorigin (bottom-right point) and the bottom-right point of the panel
			dist.x = resizeorigin.x - targEndPos.x;
			dist.y = resizeorigin.y - targEndPos.y;
			if (dist.y <= 0 || dist.x / dist.y > ratio)
				mySize.x = min(mySize.x, dist.x);
			else
				mySize.y = min(mySize.y, dist.y);
		}
		else if (resizeCorner == 2)
		{
			if (resizeorigin.x >= targEndPos.x)
				continue;
			if (resizeorigin.y <= panel_pos.y)
				continue;
			if (panel_pos.x >= resizeorigin.x + mySize.x)
				continue;
			if (targEndPos.y <= resizeorigin.y - mySize.y)
				continue;

			dist.x = panel_pos.x - resizeorigin.x;
			dist.y = resizeorigin.y - targEndPos.y;
			if (dist.y <= 0 || dist.x / dist.y > ratio)
				mySize.x = min(mySize.x, dist.x);
			else
				mySize.y = min(mySize.y, dist.y);
		}
		else if (resizeCorner == 3)
		{
			if (resizeorigin.x <= panel_pos.x)
				continue;
			if (resizeorigin.y >= targEndPos.y)
				continue;
			if (targEndPos.x <= resizeorigin.x - mySize.x)
				continue;
			if (panel_pos.y >= resizeorigin.y + mySize.y)
				continue;

			dist.x = resizeorigin.x - targEndPos.x;
			dist.y = panel_pos.y - resizeorigin.y;
			if (dist.y <= 0 || dist.x / dist.y > ratio)
				mySize.x = min(mySize.x, dist.x);
			else
				mySize.y = min(mySize.y, dist.y);
		}
		else if (resizeCorner == 4)
		{
			if (resizeorigin.x >= targEndPos.x)
				continue;
			if (resizeorigin.y >= targEndPos.y)
				continue;
			if (panel_pos.x >= resizeorigin.x + mySize.x)
				continue;
			if (panel_pos.y >= resizeorigin.y + mySize.y)
				continue;

			dist.x = panel_pos.x - resizeorigin.x;
			dist.y = panel_pos.y - resizeorigin.y;
			if (dist.y <= 0 || dist.x / dist.y > ratio)
				mySize.x = min(mySize.x, dist.x);
			else
				mySize.y = min(mySize.y, dist.y);
		}
		//if(cvar("hud_configure_checkcollisions_debug"))
			//drawfill(panel_pos, panel_size, '1 1 0', .3, DRAWFLAG_NORMAL);
	}

	return mySize;
}

void HUD_Panel_SetPosSize(vector mySize)
{
	panel = highlightedPanel;
	HUD_Panel_UpdatePosSize();
	vector resizeorigin = panel_click_resizeorigin;
	vector myPos;

	// minimum panel size cap
	mySize.x = max(0.025 * vid_conwidth, mySize.x);
	mySize.y = max(0.025 * vid_conheight, mySize.y);

	if(highlightedPanel == HUD_PANEL(CHAT)) // some panels have their own restrictions, like the chat panel (which actually only moves the engine chat print around). Looks bad if it's too small.
	{
		mySize.x = max(17 * autocvar_con_chatsize, mySize.x);
		mySize.y = max(2 * autocvar_con_chatsize + 2 * panel_bg_padding, mySize.y);
	}

	// collision testing|
	// -----------------+

	// we need to know pos at this stage, but it might still change later if we hit a screen edge/other panel (?)
	if(resizeCorner == 1) {
		myPos.x = resizeorigin.x - mySize.x;
		myPos.y = resizeorigin.y - mySize.y;
	} else if(resizeCorner == 2) {
		myPos.x = resizeorigin.x;
		myPos.y = resizeorigin.y - mySize.y;
	} else if(resizeCorner == 3) {
		myPos.x = resizeorigin.x - mySize.x;
		myPos.y = resizeorigin.y;
	} else { // resizeCorner == 4
		myPos.x = resizeorigin.x;
		myPos.y = resizeorigin.y;
	}

	// left/top screen edges
	if(myPos.x < 0)
		mySize.x = mySize.x + myPos.x;
	if(myPos.y < 0)
		mySize.y = mySize.y + myPos.y;

	// bottom/right screen edges
	if(myPos.x + mySize.x > vid_conwidth)
		mySize.x = vid_conwidth - myPos.x;
	if(myPos.y + mySize.y > vid_conheight)
		mySize.y = vid_conheight - myPos.y;

	//if(cvar("hud_configure_checkcollisions_debug"))
		//drawfill(myPos, mySize, '1 1 1', .2, DRAWFLAG_NORMAL);

	// before checkresize, otherwise panel can be snapped partially inside another panel or panel aspect ratio can be broken
	if(autocvar_hud_configure_grid)
	{
		mySize.x = floor((mySize.x/vid_conwidth)/hud_configure_gridSize.x + 0.5) * hud_configure_realGridSize.x;
		mySize.y = floor((mySize.y/vid_conheight)/hud_configure_gridSize.y + 0.5) * hud_configure_realGridSize.y;
	}

	if(hud_configure_checkcollisions)
		mySize = HUD_Panel_CheckResize(mySize, resizeorigin);

	// minimum panel size cap, do this once more so we NEVER EVER EVER have a panel smaller than this, JUST IN CASE above code still makes the panel eg negative (impossible to resize back without changing cvars manually then)
	mySize.x = max(0.025 * vid_conwidth, mySize.x);
	mySize.y = max(0.025 * vid_conheight, mySize.y);

	// do another pos check, as size might have changed by now
	if(resizeCorner == 1) {
		myPos.x = resizeorigin.x - mySize.x;
		myPos.y = resizeorigin.y - mySize.y;
	} else if(resizeCorner == 2) {
		myPos.x = resizeorigin.x;
		myPos.y = resizeorigin.y - mySize.y;
	} else if(resizeCorner == 3) {
		myPos.x = resizeorigin.x - mySize.x;
		myPos.y = resizeorigin.y;
	} else { // resizeCorner == 4
		myPos.x = resizeorigin.x;
		myPos.y = resizeorigin.y;
	}

	//if(cvar("hud_configure_checkcollisions_debug"))
		//drawfill(myPos, mySize, '0 1 0', .3, DRAWFLAG_NORMAL);

	string s;
	s = strcat(ftos_mindecimals(mySize.x/vid_conwidth), " ", ftos_mindecimals(mySize.y/vid_conheight));
	cvar_set(strcat("hud_panel_", highlightedPanel.panel_name, "_size"), s);

	s = strcat(ftos_mindecimals(myPos.x/vid_conwidth), " ", ftos_mindecimals(myPos.y/vid_conheight));
	cvar_set(strcat("hud_panel_", highlightedPanel.panel_name, "_pos"), s);
}

float pressed_key_time;
vector highlightedPanel_initial_pos, highlightedPanel_initial_size;
void HUD_Panel_Arrow_Action(float nPrimary)
{
	if(!highlightedPanel)
		return;

	hud_configure_checkcollisions = (!(hudShiftState & S_CTRL) && autocvar_hud_configure_checkcollisions);

	float step;
	if(autocvar_hud_configure_grid)
	{
		if (nPrimary == K_UPARROW || nPrimary == K_DOWNARROW)
		{
			if (hudShiftState & S_SHIFT)
				step = hud_configure_realGridSize.y;
			else
				step = 2 * hud_configure_realGridSize.y;
		}
		else
		{
			if (hudShiftState & S_SHIFT)
				step = hud_configure_realGridSize.x;
			else
				step = 2 * hud_configure_realGridSize.x;
		}
	}
	else
	{
		if (nPrimary == K_UPARROW || nPrimary == K_DOWNARROW)
			step = vid_conheight;
		else
			step = vid_conwidth;
		if (hudShiftState & S_SHIFT)
			step = (step / 256); // more precision
		else
			step = (step / 64) * (1 + 2 * (time - pressed_key_time));
	}

	panel = highlightedPanel;
	HUD_Panel_UpdatePosSize();

	highlightedPanel_initial_pos = panel_pos;
	highlightedPanel_initial_size = panel_size;

	if (hudShiftState & S_ALT) // resize
	{
		if(nPrimary == K_UPARROW)
			resizeCorner = 1;
		else if(nPrimary == K_RIGHTARROW)
			resizeCorner = 2;
		else if(nPrimary == K_LEFTARROW)
			resizeCorner = 3;
		else // if(nPrimary == K_DOWNARROW)
			resizeCorner = 4;

		// ctrl+arrow reduces the size, instead of increasing it
		// Note that ctrl disables collisions check too, but it's fine
		// since we don't collide with anything reducing the size
		if (hudShiftState & S_CTRL) {
			step = -step;
			resizeCorner = 5 - resizeCorner;
		}

		vector mySize;
		mySize = panel_size;
		panel_click_resizeorigin = panel_pos;
		if(resizeCorner == 1) {
			panel_click_resizeorigin += mySize;
			mySize.y += step;
		} else if(resizeCorner == 2) {
			panel_click_resizeorigin.y += mySize.y;
			mySize.x += step;
		} else if(resizeCorner == 3) {
			panel_click_resizeorigin.x += mySize.x;
			mySize.x += step;
		} else { // resizeCorner == 4
			mySize.y += step;
		}
		HUD_Panel_SetPosSize(mySize);
	}
	else // move
	{
		vector pos;
		pos = panel_pos;
		if(nPrimary == K_UPARROW)
			pos.y -= step;
		else if(nPrimary == K_DOWNARROW)
			pos.y += step;
		else if(nPrimary == K_LEFTARROW)
			pos.x -= step;
		else // if(nPrimary == K_RIGHTARROW)
			pos.x += step;

		HUD_Panel_SetPos(pos);
	}

	panel = highlightedPanel;
	HUD_Panel_UpdatePosSize();

	if (highlightedPanel_initial_pos != panel_pos || highlightedPanel_initial_size != panel_size)
	{
		// backup!
		panel_pos_backup = highlightedPanel_initial_pos;
		panel_size_backup = highlightedPanel_initial_size;
		highlightedPanel_backup = highlightedPanel;
		hud_configure_centerline_time = time + 1;
	}
}

entity tab_panels[REGISTRY_MAX(hud_panels)];
entity tab_panel;
vector tab_panel_pos;
float tab_backward;
void reset_tab_panels()
{
	for (int i = 0; i < REGISTRY_COUNT(hud_panels); ++i)
		tab_panels[i] = NULL;
}
float HUD_Panel_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	string s;

	if(!autocvar__hud_configure)
		return false;

	if(bInputType == 3)
	{
		mousepos.x = nPrimary;
		mousepos.y = nSecondary;
		return true;
	}

	if(bInputType == 2)
		return false;

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	// block any input while a menu dialog is fading
	// don't block mousepos read as it leads to cursor jumps in the interaction with the menu
	if(autocvar__menu_alpha)
	{
		hudShiftState = 0;
		mouseClicked = 0;
		return true;
	}

	int hudShiftState_prev = hudShiftState;
	int mouseClicked_prev = mouseClicked;
	if(key_pressed) {
		if(nPrimary == K_ALT) hudShiftState |= S_ALT;
		if(nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
		if(nPrimary == K_MOUSE1) mouseClicked |= S_MOUSE1;
		if(nPrimary == K_MOUSE2) mouseClicked |= S_MOUSE2;
	}
	else {
		if(nPrimary == K_ALT) hudShiftState &= ~S_ALT;
		if(nPrimary == K_CTRL) hudShiftState &= ~S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState &= ~S_SHIFT;
		if(nPrimary == K_MOUSE1) mouseClicked &= ~S_MOUSE1;
		if(nPrimary == K_MOUSE2) mouseClicked &= ~S_MOUSE2;
	}

	if(nPrimary == K_CTRL)
	{
		if (!key_pressed) //ctrl has been released
		{
			if (tab_panel)
			{
				//switch to selected panel
				highlightedPanel = tab_panel;
				highlightedAction = 0;
				HUD_Panel_FirstInDrawQ(highlightedPanel.panel_id);
			}
			tab_panel = NULL;
			reset_tab_panels();
		}
	}

	if(nPrimary == K_ESCAPE)
	{
		if (!key_pressed)
			return true;
		hud_configure_menu_open = 1;
		localcmd("menu_showhudexit\n");
	}
	else if(nPrimary == K_BACKSPACE && hudShiftState & S_CTRL)
	{
		if (!key_pressed)
			return true;
		if (!hud_configure_menu_open)
			HUD_Configure_Exit_Force();
	}
	else if(nPrimary == K_TAB && hudShiftState & S_CTRL) // switch panel
	{
		if (!key_pressed || mouseClicked)
			return true;

		// FIXME minor bug: if a panel is highlighted, has the same pos_x and
		// lays in the same level of another panel then the next consecutive
		// CTRL TAB presses will reselect once more the highlighted panel

		entity starting_panel;
		entity old_tab_panel = tab_panel;
		if (!tab_panel) //first press of TAB
		{
			if (highlightedPanel)
			{
				panel = highlightedPanel;
				HUD_Panel_UpdatePosSize();
			}
			else
				panel_pos = '0 0 0';
			starting_panel = highlightedPanel;
			tab_panel_pos = panel_pos; //to compute level
		}
		else
		{
			if ( ((!tab_backward) && (hudShiftState & S_SHIFT)) || (tab_backward && !(hudShiftState & S_SHIFT)) ) //tab direction changed?
				reset_tab_panels();
			starting_panel = tab_panel;
		}
		tab_backward = (hudShiftState & S_SHIFT);

		float k, level = 0, start_posX;
		vector candidate_pos = '0 0 0';
		const float LEVELS_NUM = 4;
		float level_height = vid_conheight / LEVELS_NUM;
		LABEL(find_tab_panel)
		level = floor(tab_panel_pos.y / level_height) * level_height; //starting level
		candidate_pos.x = (!tab_backward) ? vid_conwidth : 0;
		start_posX = tab_panel_pos.x;
		tab_panel = NULL;
		k=0;
		while(++k)
		{
			for(int i = 0; i < REGISTRY_COUNT(hud_panels); ++i)
			{
				panel = REGISTRY_GET(hud_panels, i);
				if(!(panel.panel_configflags & PANEL_CONFIG_MAIN))
					continue;
				if (panel == tab_panels[i] || panel == starting_panel)
					continue;
				HUD_Panel_UpdatePosSize();
				if (panel_pos.y >= level && (panel_pos.y - level) < level_height)
				if (  ( !tab_backward && panel_pos.x >= start_posX && (panel_pos.x < candidate_pos.x || (panel_pos.x == candidate_pos.x && panel_pos.y <= candidate_pos.y)) )
					|| ( tab_backward && panel_pos.x <= start_posX && (panel_pos.x > candidate_pos.x || (panel_pos.x == candidate_pos.x && panel_pos.y >= candidate_pos.y)) )  )
				{
					tab_panel = panel;
					tab_panel_pos = candidate_pos = panel_pos;
				}
			}
			if (tab_panel)
				break;
			if (k == LEVELS_NUM) //tab_panel not found
			{
				reset_tab_panels();
				if (!old_tab_panel)
				{
					tab_panel = NULL;
					return true;
				}
				starting_panel = old_tab_panel;
				old_tab_panel = NULL;
				goto find_tab_panel; //u must find tab_panel!
			}
			if (!tab_backward)
			{
				level = (level + level_height) % vid_conheight;
				start_posX = 0;
				candidate_pos.x = vid_conwidth;
			}
			else
			{
				level = (level - level_height) % vid_conheight;
				start_posX = vid_conwidth;
				candidate_pos.x = 0;
			}
		}

		tab_panels[tab_panel.panel_id] = tab_panel;
	}
	else if(nPrimary == K_SPACE && hudShiftState & S_CTRL) // enable/disable highlighted panel or dock
	{
		if (!key_pressed || mouseClicked)
			return true;

		if (highlightedPanel)
		{
			if(panel.panel_configflags & PANEL_CONFIG_CANBEOFF)
				cvar_set(strcat("hud_panel_", highlightedPanel.panel_name), ftos(!cvar(strcat("hud_panel_", highlightedPanel.panel_name))));
		}
		else
			cvar_set(strcat("hud_dock"), (autocvar_hud_dock == "") ? "dock" : "");
	}
	else if(nPrimary == 'c' && hudShiftState & S_CTRL) // copy highlighted panel size
	{
		if (!key_pressed || mouseClicked)
			return true;

		if (highlightedPanel)
		{
			panel = highlightedPanel;
			HUD_Panel_UpdatePosSize();
			panel_size_copied = panel_size;
		}
	}
	else if(nPrimary == 'v' && hudShiftState & S_CTRL) // past copied size on the highlighted panel
	{
		if (!key_pressed || mouseClicked)
			return true;

		if (panel_size_copied == '0 0 0' || !highlightedPanel)
			return true;

		panel = highlightedPanel;
		HUD_Panel_UpdatePosSize();

		// reduce size if it'd go beyond screen boundaries
		vector tmp_size = panel_size_copied;
		if (panel_pos.x + panel_size_copied.x > vid_conwidth)
			tmp_size.x = vid_conwidth - panel_pos.x;
		if (panel_pos.y + panel_size_copied.y > vid_conheight)
			tmp_size.y = vid_conheight - panel_pos.y;

		if (panel_size == tmp_size)
			return true;

		// backup first!
		panel_pos_backup = panel_pos;
		panel_size_backup = panel_size;
		highlightedPanel_backup = highlightedPanel;

		s = strcat(ftos_mindecimals(tmp_size.x/vid_conwidth), " ", ftos_mindecimals(tmp_size.y/vid_conheight));
		cvar_set(strcat("hud_panel_", highlightedPanel.panel_name, "_size"), s);
	}
	else if(nPrimary == 'z' && hudShiftState & S_CTRL) // undo last action
	{
		if (!key_pressed || mouseClicked)
			return true;
		//restore previous values
		if (highlightedPanel_backup)
		{
			s = strcat(ftos_mindecimals(panel_pos_backup.x/vid_conwidth), " ", ftos_mindecimals(panel_pos_backup.y/vid_conheight));
			cvar_set(strcat("hud_panel_", highlightedPanel_backup.panel_name, "_pos"), s);
			s = strcat(ftos_mindecimals(panel_size_backup.x/vid_conwidth), " ", ftos_mindecimals(panel_size_backup.y/vid_conheight));
			cvar_set(strcat("hud_panel_", highlightedPanel_backup.panel_name, "_size"), s);
			highlightedPanel_backup = NULL;
		}
	}
	else if(nPrimary == 's' && hudShiftState & S_CTRL) // save config
	{
		if (!key_pressed || mouseClicked)
			return true;
		localcmd("hud save myconfig\n");
	}
	else if(nPrimary == K_UPARROW || nPrimary == K_DOWNARROW || nPrimary == K_LEFTARROW || nPrimary == K_RIGHTARROW)
	{
		if (!key_pressed)
		{
			pressed_key_time = 0;
			return true;
		}
		else if (pressed_key_time == 0)
			pressed_key_time = time;

		if (!mouseClicked)
			HUD_Panel_Arrow_Action(nPrimary); //move or resize panel
	}
	else if(nPrimary == K_ENTER || nPrimary == K_SPACE || nPrimary == K_KP_ENTER)
	{
		if (bInputType == 1)
			return true;
		if (highlightedPanel)
			HUD_Panel_EnableMenu();
	}
	else if(nPrimary == K_PAUSE)
		return false;
	else if (hudShiftState_prev == hudShiftState && mouseClicked_prev == mouseClicked)
	{
		// allow console bind to work
		string con_keys = findkeysforcommand("toggleconsole", 0);
		int keys = tokenize(con_keys); // findkeysforcommand returns data for this
		for (int i = 0; i < keys; ++i)
		{
			if(nPrimary == stof(argv(i)))
				return false; // hit console bind
		}
	}

	return true;
}

int HUD_Panel_Check_Mouse_Pos(bool allow_move)
{
	int i, j = 0;
	while(j < REGISTRY_COUNT(hud_panels))
	{
		i = panel_order[j];
		j += 1;

		panel = REGISTRY_GET(hud_panels, i);
		if(!(panel.panel_configflags & PANEL_CONFIG_MAIN)) continue;
		HUD_Panel_UpdatePosSize();

		float border = max(8, panel_bg_border); // FORCED border so a small border size doesn't mean you can't resize

		// move
		if(allow_move && mousepos.x > panel_pos.x && mousepos.y > panel_pos.y && mousepos.x < panel_pos.x + panel_size.x && mousepos.y < panel_pos.y + panel_size.y)
		{
			return CURSOR_MOVE;
		}
		// resize from topleft border
		else if(mousepos.x >= panel_pos.x - border && mousepos.y >= panel_pos.y - border && mousepos.x <= panel_pos.x + 0.5 * panel_size.x && mousepos.y <= panel_pos.y + 0.5 * panel_size.y)
		{
			return CURSOR_RESIZE;
		}
		// resize from topright border
		else if(mousepos.x >= panel_pos.x + 0.5 * panel_size.x && mousepos.y >= panel_pos.y - border && mousepos.x <= panel_pos.x + panel_size.x + border && mousepos.y <= panel_pos.y + 0.5 * panel_size.y)
		{
			return CURSOR_RESIZE2;
		}
		// resize from bottomleft border
		else if(mousepos.x >= panel_pos.x - border && mousepos.y >= panel_pos.y + 0.5 * panel_size.y && mousepos.x <= panel_pos.x + 0.5 * panel_size.x && mousepos.y <= panel_pos.y + panel_size.y + border)
		{
			return CURSOR_RESIZE2;
		}
		// resize from bottomright border
		else if(mousepos.x >= panel_pos.x + 0.5 * panel_size.x && mousepos.y >= panel_pos.y + 0.5 * panel_size.y && mousepos.x <= panel_pos.x + panel_size.x + border && mousepos.y <= panel_pos.y + panel_size.y + border)
		{
			return CURSOR_RESIZE;
		}
	}
	return CURSOR_NORMAL;
}

// move a panel to the beginning of the panel order array (which means it gets drawn last, on top of everything else)
void HUD_Panel_FirstInDrawQ(float id)
{
	int i;
	int place = -1;
	// find out where in the array our current id is, save into place
	for(i = 0; i < REGISTRY_COUNT(hud_panels); ++i)
	{
		if(panel_order[i] == id)
		{
			place = i;
			break;
		}
	}
	// place last if we didn't find a place for it yet (probably new panel, or screwed up cvar)
	if(place == -1)
		place = REGISTRY_COUNT(hud_panels) - 1;

	// move all ids up by one step in the array until "place"
	for(i = place; i > 0; --i)
	{
		panel_order[i] = panel_order[i-1];
	}
	// now save the new top id
	panel_order[0] = id;

	// let's save them into the cvar by some strcat trickery
	string s = "";
	for(i = 0; i < REGISTRY_COUNT(hud_panels); ++i)
	{
		s = strcat(s, ftos(panel_order[i]), " ");
	}
	cvar_set("_hud_panelorder", s);
	strcpy(hud_panelorder_prev, autocvar__hud_panelorder); // prevent HUD_Main from doing useless update, we already updated here
}

void HUD_Panel_Highlight(float allow_move)
{
	int i, j = 0;

	while(j < REGISTRY_COUNT(hud_panels))
	{
		i = panel_order[j];
		j += 1;

		panel = REGISTRY_GET(hud_panels, i);
		if(!(panel.panel_configflags & PANEL_CONFIG_MAIN))
			continue;
		HUD_Panel_UpdatePosSize();

		float border = max(8, panel_bg_border); // FORCED border so a small border size doesn't mean you can't resize

		// move
		if(allow_move && mousepos.x > panel_pos.x && mousepos.y > panel_pos.y && mousepos.x < panel_pos.x + panel_size.x && mousepos.y < panel_pos.y + panel_size.y)
		{
			highlightedPanel = REGISTRY_GET(hud_panels, i);
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 1;
			panel_click_distance = mousepos - panel_pos;
			return;
		}
		// resize from topleft border
		else if(mousepos.x >= panel_pos.x - border && mousepos.y >= panel_pos.y - border && mousepos.x <= panel_pos.x + 0.5 * panel_size.x && mousepos.y <= panel_pos.y + 0.5 * panel_size.y)
		{
			highlightedPanel = REGISTRY_GET(hud_panels, i);
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 1;
			panel_click_distance = mousepos - panel_pos;
			panel_click_resizeorigin = panel_pos + panel_size;
			return;
		}
		// resize from topright border
		else if(mousepos.x >= panel_pos.x + 0.5 * panel_size.x && mousepos.y >= panel_pos.y - border && mousepos.x <= panel_pos.x + panel_size.x + border && mousepos.y <= panel_pos.y + 0.5 * panel_size.y)
		{
			highlightedPanel = REGISTRY_GET(hud_panels, i);
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 2;
			panel_click_distance.x = panel_size.x - mousepos.x + panel_pos.x;
			panel_click_distance.y = mousepos.y - panel_pos.y;
			panel_click_resizeorigin = panel_pos + eY * panel_size.y;
			return;
		}
		// resize from bottomleft border
		else if(mousepos.x >= panel_pos.x - border && mousepos.y >= panel_pos.y + 0.5 * panel_size.y && mousepos.x <= panel_pos.x + 0.5 * panel_size.x && mousepos.y <= panel_pos.y + panel_size.y + border)
		{
			highlightedPanel = REGISTRY_GET(hud_panels, i);
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 3;
			panel_click_distance.x = mousepos.x - panel_pos.x;
			panel_click_distance.y = panel_size.y - mousepos.y + panel_pos.y;
			panel_click_resizeorigin = panel_pos + eX * panel_size.x;
			return;
		}
		// resize from bottomright border
		else if(mousepos.x >= panel_pos.x + 0.5 * panel_size.x && mousepos.y >= panel_pos.y + 0.5 * panel_size.y && mousepos.x <= panel_pos.x + panel_size.x + border && mousepos.y <= panel_pos.y + panel_size.y + border)
		{
			highlightedPanel = REGISTRY_GET(hud_panels, i);
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 4;
			panel_click_distance = panel_size - mousepos + panel_pos;
			panel_click_resizeorigin = panel_pos;
			return;
		}
	}
	highlightedPanel = NULL;
	highlightedAction = 0;
}

void HUD_Panel_EnableMenu()
{
	hud_configure_menu_open = 2;
	localcmd("menu_showhudoptions ", highlightedPanel.panel_name, "\n");
}

void HUD_Panel_Mouse()
{
	if(autocvar__menu_alpha == 1)
		return;

	if(mouseClicked)
	{
		if(prevMouseClicked == 0)
		{
			if (tab_panel)
			{
				//stop ctrl-tab selection
				tab_panel = NULL;
				reset_tab_panels();
			}
			HUD_Panel_Highlight(mouseClicked & S_MOUSE1); // sets highlightedPanel, highlightedAction, panel_click_distance, panel_click_resizeorigin
									// and calls HUD_Panel_UpdatePosSize() for the highlighted panel
			if (highlightedPanel)
			{
				highlightedPanel_initial_pos = panel_pos;
				highlightedPanel_initial_size = panel_size;
			}
			// doubleclick check
			if ((mouseClicked & S_MOUSE1) && time - prevMouseClickedTime < 0.4 && highlightedPanel && prevMouseClickedPos == mousepos)
			{
				mouseClicked = 0; // to prevent spam, I guess.
				HUD_Panel_EnableMenu();
			}
			else
			{
				if (mouseClicked & S_MOUSE1)
				{
					prevMouseClickedTime = time;
					prevMouseClickedPos = mousepos;
				}
				cursor_type = HUD_Panel_Check_Mouse_Pos(mouseClicked & S_MOUSE1);
			}
		}
		else
		{
			panel = highlightedPanel;
			HUD_Panel_UpdatePosSize();
		}

		if (highlightedPanel)
		{
			drawfill(panel_pos - '1 1 0' * panel_bg_border, panel_size + '2 2 0' * panel_bg_border, '1 1 1', .1, DRAWFLAG_NORMAL);
			if (highlightedPanel_initial_pos != panel_pos || highlightedPanel_initial_size != panel_size)
			{
				hud_configure_checkcollisions = (!(hudShiftState & S_CTRL) && autocvar_hud_configure_checkcollisions);
				// backup!
				panel_pos_backup = highlightedPanel_initial_pos;
				panel_size_backup = highlightedPanel_initial_size;
				highlightedPanel_backup = highlightedPanel;
			}
			else
				// in case the clicked panel is inside another panel and we aren't
				// moving it, avoid the immediate "fix" of its position/size
				// (often unwanted and hateful) by disabling collisions check
				hud_configure_checkcollisions = false;

			if (time - prevMouseClickedTime > 0.25) // avoid showing the center line immediately on mouse click
				hud_configure_centerline_time = time + 0.5;
		}

		if(highlightedAction == 1)
			HUD_Panel_SetPos(mousepos - panel_click_distance);
		else if(highlightedAction == 2)
		{
			vector mySize = '0 0 0';
			if(resizeCorner == 1) {
				mySize.x = panel_click_resizeorigin.x - (mousepos.x - panel_click_distance.x);
				mySize.y = panel_click_resizeorigin.y - (mousepos.y - panel_click_distance.y);
			} else if(resizeCorner == 2) {
				mySize.x = mousepos.x + panel_click_distance.x - panel_click_resizeorigin.x;
				mySize.y = panel_click_distance.y + panel_click_resizeorigin.y - mousepos.y;
			} else if(resizeCorner == 3) {
				mySize.x = panel_click_resizeorigin.x + panel_click_distance.x - mousepos.x;
				mySize.y = mousepos.y + panel_click_distance.y - panel_click_resizeorigin.y;
			} else { // resizeCorner == 4
				mySize.x = mousepos.x - (panel_click_resizeorigin.x - panel_click_distance.x);
				mySize.y = mousepos.y - (panel_click_resizeorigin.y - panel_click_distance.y);
			}
			HUD_Panel_SetPosSize(mySize);
		}
	}
	else
	{
		if(prevMouseClicked)
			highlightedAction = 0;
		if(hud_configure_menu_open == 2)
			cursor_type = CURSOR_NORMAL;
		else
			cursor_type = HUD_Panel_Check_Mouse_Pos(true);
		if (cursor_type != CURSOR_NORMAL && !tab_panel) // mouse over a panel?
			drawfill(panel_pos - '1 1 0' * panel_bg_border, panel_size + '2 2 0' * panel_bg_border, '1 1 1', .1, DRAWFLAG_NORMAL);
	}
}
void HUD_Configure_DrawGrid()
{
	int i;
	if(autocvar_hud_configure_grid && autocvar_hud_configure_grid_alpha)
	{
		hud_configure_gridSize.x = bound(0.005, cvar("hud_configure_grid_xsize"), 0.2);
		hud_configure_gridSize.y = bound(0.005, cvar("hud_configure_grid_ysize"), 0.2);
		hud_configure_realGridSize.x = hud_configure_gridSize.x * vid_conwidth;
		hud_configure_realGridSize.y = hud_configure_gridSize.y * vid_conheight;
		vector s;
		// vertical center line, wider than vertical grid lines so that it's more visible
		// NOTE: depending on grid size the vertical center line may not overlap any vertical grid line
		int n = tokenize(autocvar_hud_configure_vertical_lines);
		for (i = 0; i < n; ++i)
		{
			float xpos_rel = stof(argv(i));
			drawfill(eX * (xpos_rel * vid_conwidth - 1), vec2(3, vid_conheight), '0.5 0.5 0.5', autocvar_hud_configure_grid_alpha, DRAWFLAG_NORMAL);
		}
		// x-axis
		s = vec2(1, vid_conheight);
		for(i = 1; i < 1/hud_configure_gridSize.x; ++i)
			drawfill(eX * i * hud_configure_realGridSize.x, s, '0.5 0.5 0.5', autocvar_hud_configure_grid_alpha, DRAWFLAG_NORMAL);
		// y-axis
		s = vec2(vid_conwidth, 1);
		for(i = 1; i < 1/hud_configure_gridSize.y; ++i)
			drawfill(eY * i * hud_configure_realGridSize.y, s, '0.5 0.5 0.5', autocvar_hud_configure_grid_alpha, DRAWFLAG_NORMAL);
	}
}

float _menu_alpha_prev;
void HUD_Configure_Frame()
{
	int i;
	if(autocvar__hud_configure)
	{
		if(isdemo() || intermission == 2 || scoreboard_active)
		{
			HUD_Configure_Exit_Force();
			return;
		}

		if(!hud_configure_prev)
		{
			hudShiftState = 0;
			for(i = REGISTRY_COUNT(hud_panels) - 1; i >= 0; --i)
				REGISTRY_GET(hud_panels, panel_order[i]).update_time = time;
		}

		// NOTE this check is necessary because _menu_alpha isn't updated the frame the menu gets enabled
		if(autocvar__menu_alpha != _menu_alpha_prev)
		{
			if(autocvar__menu_alpha == 0)
				hud_configure_menu_open = 0;
			_menu_alpha_prev = autocvar__menu_alpha;
		}

		HUD_Configure_DrawGrid();
	}
	else if(hud_configure_prev)
	{
		if(hud_configure_menu_open)
			hud_configure_menu_open = 0;
		hud_dynamic_shake_factor = -1;
	}
}

const float hlBorderSize = 2;
const string hlBorder = "gfx/hud/default/border_highlighted";
const string hlBorder2 = "gfx/hud/default/border_highlighted2";
void HUD_Panel_HlBorder(float myBorder, vector color, float theAlpha)
{
	vector pos = panel_pos - vec2(myBorder, myBorder);
	drawfill(pos, panel_size + '2 2 0' * myBorder, '0 0.5 1', .5 * theAlpha, DRAWFLAG_NORMAL);
	drawpic_tiled(pos, hlBorder, '8 1 0' * hlBorderSize, vec2(panel_size.x + 2 * myBorder, hlBorderSize), color, theAlpha, DRAWFLAG_NORMAL);
	drawpic_tiled(pos + eY * (panel_size.y + 2 * myBorder - hlBorderSize), hlBorder, '8 1 0' * hlBorderSize, vec2(panel_size.x + 2 * myBorder, hlBorderSize), color, theAlpha, DRAWFLAG_NORMAL);
	pos.y += hlBorderSize;
	drawpic_tiled(pos, hlBorder2, '1 8 0' * hlBorderSize, vec2(hlBorderSize, panel_size.y + 2 * myBorder - 2 * hlBorderSize), color, theAlpha, DRAWFLAG_NORMAL);
	drawpic_tiled(pos + eX * (panel_size.x + 2 * myBorder - hlBorderSize), hlBorder2, '1 8 0' * hlBorderSize, vec2(hlBorderSize, panel_size.y + 2 * myBorder - 2 * hlBorderSize), color, theAlpha, DRAWFLAG_NORMAL);
}

void HUD_Panel_HlCenterLine(float myBorder)
{
	if (time > hud_configure_centerline_time)
		return;
	float panel_centerpos_x = (panel_pos.x + panel_size.x * 0.5);
	int n = tokenize(autocvar_hud_configure_vertical_lines);
	for (int i = 0; i < n; ++i)
	{
		float xpos_rel = stof(argv(i));
		if (xpos_rel <= 0 || xpos_rel >= 1)
			continue;
		float ofs = fabs(panel_centerpos_x / vid_conwidth - xpos_rel);
		if (ofs < 0.02) // don't bother showing the center line if it's evident that the panel is not centered
		{
			float f = map_bound_ranges(ofs, 0.001, 0.01, 0, 1);
			vector col = '1 0 0' * f + '0 1 0' * (1 - f); // from red (far) to green (close)
			float theAlpha = 0.3 + 0.1 * sin(6 * time); // blink
			theAlpha *= (1 - autocvar__menu_alpha) * bound(0, hud_configure_centerline_time - time, 0.5) * 2; // fade
			vector pos = vec2(panel_centerpos_x - 1, panel_pos.y - myBorder);
			drawfill(pos, vec2(3, panel_size.y + 2 * myBorder), col, theAlpha, DRAWFLAG_NORMAL);
		}
	}
}

void HUD_Configure_PostDraw()
{
	if(autocvar__hud_configure)
	{
		if(tab_panel)
		{
			panel = tab_panel;
			HUD_Panel_UpdatePosSize();
			drawfill(panel_pos - '1 1 0' * panel_bg_border, panel_size + '2 2 0' * panel_bg_border, '1 1 1', .2, DRAWFLAG_NORMAL);
		}
		if(highlightedPanel)
		{
			panel = highlightedPanel;
			HUD_Panel_UpdatePosSize();
			HUD_Panel_HlBorder(panel_bg_border * hlBorderSize, '0 0.5 1', 0.4 * (1 - autocvar__menu_alpha));
			HUD_Panel_HlCenterLine(panel_bg_border * hlBorderSize);
		}
	}
}
