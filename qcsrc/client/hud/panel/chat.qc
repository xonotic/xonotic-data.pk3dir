/** Handle chat as a panel (#12) */
void HUD_Chat()
{
	if(!autocvar__hud_configure)
	{
		if (!autocvar_hud_panel_chat)
		{
			if (!autocvar_con_chatrect)
				cvar_set("con_chatrect", "0");
			return;
		}
		if(autocvar__con_chat_maximized)
		{
			if(!hud_draw_maximized) return;
		}
		else if(chat_panel_modified)
		{
			panel.update_time = time; // forces reload of panel attributes
			chat_panel_modified = false;
		}
	}

	HUD_Panel_UpdateCvars();

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
			if(panel.current_panel_bg)
				strunzone(panel.current_panel_bg);
			panel.current_panel_bg = strzone(panel_bg);
			chat_panel_modified = true;
		}
		panel_bg_alpha = max(0.75, panel_bg_alpha); // force an theAlpha of at least 0.75
	}

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	if (!autocvar_con_chatrect)
		cvar_set("con_chatrect", "1");

	cvar_set("con_chatrect_x", ftos(pos.x/vid_conwidth));
	cvar_set("con_chatrect_y", ftos(pos.y/vid_conheight));

	cvar_set("con_chatwidth", ftos(mySize.x/vid_conwidth));
	cvar_set("con_chat", ftos(floor(mySize.y/autocvar_con_chatsize - 0.5)));

	if(autocvar__hud_configure)
	{
		vector chatsize;
		chatsize = '1 1 0' * autocvar_con_chatsize;
		cvar_set("con_chatrect_x", "9001"); // over 9000, we'll fake it instead for more control over theAlpha and such
		float i, a;
		for(i = 0; i < autocvar_con_chat; ++i)
		{
			if(i == autocvar_con_chat - 1)
				a = panel_fg_alpha;
			else
				a = panel_fg_alpha * floor(((i + 1) * 7 + autocvar_con_chattime)/45);
			drawcolorcodedstring(pos, textShortenToWidth(_("^3Player^7: This is the chat area."), mySize.x, chatsize, stringwidth_colors), chatsize, a, DRAWFLAG_NORMAL);
			pos.y += chatsize.y;
		}
	}
}
