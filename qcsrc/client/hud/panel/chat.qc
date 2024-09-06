#include "chat.qh"

#include <client/draw.qh>

// Chat (#12)

void HUD_Chat_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

float chat_maximized_scroll_ofs;
float chat_maximized_reset_scroll_time;
float HUD_Panel_Chat_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	if(!autocvar__con_chat_maximized)
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

	if(nPrimary == K_MWHEELUP)
	{
		if (!key_pressed)
			return true;
		chat_maximized_scroll_ofs += 5 * cvar("con_chatsize");
		return true;
	}
	else if(nPrimary == K_MWHEELDOWN)
	{
		if (!key_pressed)
			return true;
		chat_maximized_scroll_ofs -= 5 * cvar("con_chatsize");
		if (chat_maximized_scroll_ofs < 0)
			chat_maximized_scroll_ofs = 0;
		return true;
	}
	else if(nPrimary == K_PGUP)
	{
		if (!key_pressed)
			return true;
		chat_maximized_scroll_ofs += vid_conheight / 2;
		return true;
	}
	else if(nPrimary == K_PGDN)
	{
		if (!key_pressed)
			return true;
		chat_maximized_scroll_ofs -= vid_conheight / 2;
		if (chat_maximized_scroll_ofs < 0)
			chat_maximized_scroll_ofs = 0;
		return true;
	}

	return false;
}

void HUD_Chat()
{
	if(!autocvar__hud_configure)
	{
		if (!autocvar_hud_panel_chat && !autocvar__con_chat_maximized)
		{
			if (autocvar_con_chatrect)
				cvar_set("con_chatrect", "0");
			if (autocvar_con_chat != -1)
				cvar_set("con_chat", "-1");
			return;
		}

		if(autocvar__con_chat_maximized)
		{
			if(!hud_draw_maximized) return;

			chat_maximized_reset_scroll_time = time + 3;
		}
		else
		{
			if(chat_panel_modified)
			{
				panel.update_time = time; // forces reload of panel attributes
				chat_panel_modified = false;
			}
			if (time > chat_maximized_reset_scroll_time)
				chat_maximized_scroll_ofs = 0;
		}
	}
	else
		chat_maximized_scroll_ofs = 0;

	HUD_Panel_LoadCvars();

	if(intermission == 2)
	{
		// reserve some more space to the mapvote panel
		// by resizing and moving chat panel to the bottom
		panel_size.y = min(panel_size.y, vid_conheight * 0.2);
		panel_pos.y = vid_conheight - panel_size.y - panel_bg_border * 2;
		chat_posy = panel_pos.y;
		chat_sizey = panel_size.y;
	}
	if(autocvar__con_chat_maximized && !autocvar__hud_configure) // draw at full screen height if maximized
	{
		panel_pos.y = panel_bg_border;
		panel_size.y = vid_conheight - panel_bg_border * 2;
		if(panel.current_panel_bg == "0") // force a border when maximized
		{
			string panel_bg;
			panel_bg = strcat(hud_skin_path, "/border_default");
			if(precache_pic(panel_bg) == "")
				panel_bg = "gfx/hud/default/border_default";
			strcpy(panel.current_panel_bg, panel_bg);
			chat_panel_modified = true;
		}
		panel_bg_alpha = max(0.75, panel_bg_alpha);
		panel_size.y += chat_maximized_scroll_ofs;
	}

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	// chat messages don't scale properly since they are displayed directly by the engine
	HUD_Scale_Disable();
	HUD_Panel_DrawBg();

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	if (!autocvar_con_chatrect)
		cvar_set("con_chatrect", "1");

	// can't use a name ending with _x, _y and _z for a float autocvar as for autocvar specs
	// it prevents ambiguity with component names of vector autocvars
	if (cvar_string("con_chatrect_x") != ftos(pos.x / vid_conwidth))
		cvar_set("con_chatrect_x", ftos(pos.x / vid_conwidth));
	if (cvar_string("con_chatrect_y") != ftos(pos.y / vid_conheight))
		cvar_set("con_chatrect_y", ftos(pos.y / vid_conheight));
	// can't use direct comparison here, it would always returns true even if
	// both arguments are equal because con_chatwidth is saved with cvar_set
	//if (autocvar_con_chatwidth != mySize.x / vid_conwidth)
	if (fabs(autocvar_con_chatwidth - mySize.x / vid_conwidth) > 0.00001)
		cvar_set("con_chatwidth", ftos(mySize.x / vid_conwidth));
	if (autocvar_con_chat != floor(mySize.y / autocvar_con_chatsize - 0.5))
		cvar_set("con_chat", ftos(floor(mySize.y / autocvar_con_chatsize - 0.5)));

	if(autocvar__hud_configure)
	{
		float alpha = 1; // engine can display chat only at full alpha
		if (hud_configure_menu_open == 2 && highlightedPanel != panel)
			alpha = hud_fade_alpha; // fade only when the settings menu of another panel is open
		vector chatsize = '1 1 0' * autocvar_con_chatsize;
		if (cvar_string("con_chatrect_x") != "9001")
			cvar_set("con_chatrect_x", "9001"); // over 9000, we'll fake it instead for more control over alpha and such
		string str = textShortenToWidth(_("^3Player^7: This is the chat area."), mySize.x, chatsize, stringwidth_colors);
		for(int i = 0; i < autocvar_con_chat; ++i)
		{
			drawcolorcodedstring(pos, str, chatsize, alpha, DRAWFLAG_NORMAL);
			pos.y += chatsize.y;
		}
	}
}
