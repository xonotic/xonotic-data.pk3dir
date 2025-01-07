#include "radar.qh"

#include <client/draw.qh>
#include <client/hud/panel/scoreboard.qh>
#include <client/mapvoting.qh>
#include <client/teamradar.qh>
#include <common/ent_cs.qh>
#include <common/mutators/mutator/waypoints/all.qh>
#include <common/resources/cl_resources.qh>

// Radar (#6)

void HUD_Radar_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_radar_foreground_alpha");
	HUD_Write_Cvar("hud_panel_radar_rotation");
	HUD_Write_Cvar("hud_panel_radar_zoommode");
	HUD_Write_Cvar("hud_panel_radar_scale");
	HUD_Write_Cvar("hud_panel_radar_maximized_scale");
	HUD_Write_Cvar("hud_panel_radar_maximized_size");
	HUD_Write_Cvar("hud_panel_radar_maximized_rotation");
	HUD_Write_Cvar("hud_panel_radar_maximized_zoommode");
}

bool HUD_Radar_Clickable()
{
	return hud_panel_radar_mouse && !hud_panel_radar_temp_hidden;
}

void HUD_Radar_Show_Maximized(bool doshow, bool clickable)
{
	TC(bool, doshow);
	hud_panel_radar_maximized = doshow;
	hud_panel_radar_temp_hidden = 0;

	if ( doshow )
	{
		if (clickable)
		{
			hud_panel_radar_mouse = 1;

			Release_Common_Keys();
		}
	}
	else if ( hud_panel_radar_mouse )
	{
		hud_panel_radar_mouse = 0;
		mouseClicked = 0;
	}
}
void HUD_Radar_Hide_Maximized()
{
	HUD_Radar_Show_Maximized(false,false);
}


float HUD_Radar_InputEvent(int bInputType, float nPrimary, float nSecondary)
{
	TC(int, bInputType);
	if(!hud_panel_radar_maximized || !hud_panel_radar_mouse || autocvar__hud_configure || mv_active)
		return false;

	if(bInputType == 3)
	{
		mousepos_x = nPrimary;
		mousepos_y = nSecondary;
		return true;
	}

	if (bInputType == 2)
		return false;

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	if(nPrimary == K_MOUSE1)
	{
		if(key_pressed)
			mouseClicked |= S_MOUSE1;
		else
			mouseClicked &= ~S_MOUSE1;
	}
	else if(nPrimary == K_MOUSE2)
	{
		if(key_pressed)
			mouseClicked |= S_MOUSE2;
		else
			mouseClicked &= ~S_MOUSE2;
	}
	else if (nPrimary == K_ESCAPE && key_pressed)
	{
		HUD_Radar_Hide_Maximized();
	}
	else
	{
		// allow console/use binds to work without hiding the map
		string con_keys = strcat(findkeysforcommand("toggleconsole", 0), " ", findkeysforcommand("+use", 0)) ;
		int keys = tokenize(con_keys); // findkeysforcommand returns data for this
		int i;
		for (i = 0; i < keys; ++i)
		{
			if(nPrimary == stof(argv(i)))
				return false;
		}

		if ( STAT(HEALTH) <= 0 )
		{
			// Show scoreboard
			con_keys = findkeysforcommand("+showscores", 0);
			keys = tokenize(con_keys);
			for (i = 0; i < keys; ++i)
			{
				if ( nPrimary == stof(argv(i)) )
				{
					hud_panel_radar_temp_hidden = key_pressed;
					return false;
				}
			}
		}
		else if (key_pressed)
			HUD_Radar_Hide_Maximized();

		return false;
	}

	return true;
}

void HUD_Radar_Mouse()
{
	if ( !hud_panel_radar_mouse ) return;
	if(mv_active) return;

	if (intermission || scoreboard_ui_enabled || (mouseClicked & S_MOUSE2))
	{
		HUD_Radar_Hide_Maximized();
		return;
	}

	panel = HUD_PANEL(RADAR);
	HUD_Panel_LoadCvars();


	panel_size = autocvar_hud_panel_radar_maximized_size;
	panel_size_x = bound(0.2, panel_size_x, 1) * vid_conwidth;
	panel_size_y = bound(0.2, panel_size_y, 1) * vid_conheight;
	panel_pos_x = (vid_conwidth - panel_size_x) / 2;
	panel_pos_y = (vid_conheight - panel_size_y) / 2;

	if(mouseClicked & S_MOUSE1)
	{
		// click outside
		if ( mousepos_x < panel_pos_x || mousepos_x > panel_pos_x + panel_size_x ||
			 mousepos_y < panel_pos_y || mousepos_y > panel_pos_y + panel_size_y )
		{
			HUD_Radar_Hide_Maximized();
			return;
		}
		vector pos = teamradar_texcoord_to_3dcoord(teamradar_2dcoord_to_texcoord(mousepos),view_origin_z);
		localcmd(sprintf("cmd ons_spawn %f %f %f",pos_x,pos_y,pos_z));

		HUD_Radar_Hide_Maximized();
		return;
	}
}

float HUD_Radar_GetZoomFactor(int zoommode)
{
	switch(zoommode)
	{
		case 1: return 1 - current_zoomfraction;
		case 2: return 0;
		case 3: return 1;
	}
	return current_zoomfraction;
}

float HUD_Radar_GetAngle(int rotation)
{
	if (rotation)
		return 90 * rotation;
	return view_angles.y - 90;
}

void HUD_Radar()
{
	if (!autocvar__hud_configure)
	{
		if (hud_panel_radar_maximized)
		{
			if (!hud_draw_maximized) return;
		}
		else
		{
			if (autocvar_hud_panel_radar == 0) return;
			if (autocvar_hud_panel_radar != 2 && !teamplay) return;
			if(radar_panel_modified)
			{
				panel.update_time = time; // forces reload of panel attributes
				radar_panel_modified = false;
			}
		}
	}

	if ( hud_panel_radar_temp_hidden )
		return;

	HUD_Panel_LoadCvars();

	float zoom_factor = 0;

	if (hud_panel_radar_maximized && !autocvar__hud_configure)
	{
		panel_size = autocvar_hud_panel_radar_maximized_size;
		panel_size.x = bound(0.2, panel_size.x, 1) * vid_conwidth;
		panel_size.y = bound(0.2, panel_size.y, 1) * vid_conheight;
		panel_pos.x = (vid_conwidth - panel_size.x) / 2;
		panel_pos.y = (vid_conheight - panel_size.y) / 2;

		string panel_bg;
		panel_bg = strcat(hud_skin_path, "/border_default"); // always use the default border when maximized
		if(precache_pic(panel_bg) == "")
			panel_bg = "gfx/hud/default/border_default"; // fallback
		if(!radar_panel_modified && panel_bg != panel.current_panel_bg)
			radar_panel_modified = true;
		strcpy(panel.current_panel_bg, panel_bg);

		zoom_factor = HUD_Radar_GetZoomFactor(hud_panel_radar_maximized_zoommode);
		teamradar_angle = HUD_Radar_GetAngle(hud_panel_radar_maximized_rotation);
	}

	if (!hud_panel_radar_maximized && !autocvar__hud_configure)
	{
		zoom_factor = HUD_Radar_GetZoomFactor(hud_panel_radar_zoommode);
		teamradar_angle = HUD_Radar_GetAngle(hud_panel_radar_rotation);
	}

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_radar_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	int color2;
	float scale2d, normalsize, bigsize;

	teamradar_origin2d = HUD_Shift(pos + 0.5 * mySize);
	teamradar_size2d = mySize;

	if(minimapname == "")
		return;

	teamradar_loadcvars();

	scale2d = vlen_maxnorm2d(mi_picmax - mi_picmin);
	teamradar_size2d = HUD_Scale(mySize);

	teamradar_extraclip_mins = teamradar_extraclip_maxs = '0 0 0'; // we always center

	// pixels per world qu to match the teamradar_size2d_x range in the longest dimension
	if((hud_panel_radar_rotation == 0 && !hud_panel_radar_maximized) || (hud_panel_radar_maximized_rotation == 0 && hud_panel_radar_maximized))
	{
		// max-min distance must fit the radar in any rotation
		bigsize = vlen_minnorm2d(teamradar_size2d) * scale2d / (1.05 * vlen(vec2(mi_scale)));
	}
	else
	{
		vector c0, c1, c2, c3, span;
		c0 = Rotate(mi_min, teamradar_angle * DEG2RAD);
		c1 = Rotate(mi_max, teamradar_angle * DEG2RAD);
		c2 = Rotate('1 0 0' * mi_min.x + '0 1 0' * mi_max.y, teamradar_angle * DEG2RAD);
		c3 = Rotate('1 0 0' * mi_max.x + '0 1 0' * mi_min.y, teamradar_angle * DEG2RAD);
		span = '0 0 0';
		span.x = max(c0_x, c1_x, c2_x, c3_x) - min(c0_x, c1_x, c2_x, c3_x);
		span.y = max(c0_y, c1_y, c2_y, c3_y) - min(c0_y, c1_y, c2_y, c3_y);

		// max-min distance must fit the radar in x=x, y=y
		bigsize = min(
			teamradar_size2d.x * scale2d / (1.05 * span.x),
			teamradar_size2d.y * scale2d / (1.05 * span.y)
		);
	}

	normalsize = vlen_maxnorm2d(teamradar_size2d) * scale2d / hud_panel_radar_scale;
	if(bigsize > normalsize)
		normalsize = bigsize;

	teamradar_size = zoom_factor * bigsize + (1 - zoom_factor) * normalsize;
	teamradar_origin3d_in_texcoord = teamradar_3dcoord_to_texcoord(zoom_factor * mi_center + (1 - zoom_factor) * view_origin);

	drawsetcliparea(pos.x, pos.y, mySize.x, mySize.y);

	draw_teamradar_background(hud_panel_radar_foreground_alpha);

	IL_EACH(g_radarlinks, true, draw_teamradar_link(it.origin, it.velocity, it.team));

	bool mutator_returnvalue = MUTATOR_CALLHOOK(TeamRadar_Draw); // TODO: allow players to show on the radar as well!

	IL_EACH(g_radaricons, it.teamradar_icon, {
		if ( hud_panel_radar_mouse )
		if ( GetResource(it, RES_HEALTH) >= 0 )
		if ( it.team == myteam + 1 || mutator_returnvalue || !teamplay )
		{
			vector coord = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(it.origin));
			if(vdist((mousepos - coord), <, 8))
			{
				vector brightcolor;
				brightcolor_x = min(1,it.teamradar_color_x*1.5);
				brightcolor_y = min(1,it.teamradar_color_y*1.5);
				brightcolor_z = min(1,it.teamradar_color_z*1.5);
				drawpic(coord - '8 8 0', "gfx/teamradar_icon_glow", '16 16 0', brightcolor, panel_fg_alpha, 0);
			}
		}
		entity icon = REGISTRY_GET(RadarIcons, it.teamradar_icon);
		draw_teamradar_icon(it.origin, icon, it, spritelookupcolor(it, icon.netname, it.teamradar_color), panel_fg_alpha);
	});
	AL_EACH(_entcs, e, it != NULL, {
		if (!it.m_entcs_private) continue;
		if (it.sv_entnum == current_player) continue;
		color2 = entcs_GetTeam(it.sv_entnum);
		draw_teamradar_player(it.origin, it.angles, Team_ColorRGB(color2));
	});
	draw_teamradar_player(entcs_receiver(current_player).origin, view_angles, '1 1 1');

	drawresetcliparea();

	if ( hud_panel_radar_mouse )
	{
		string message = _("Click to select teleport destination");

		if ( STAT(HEALTH) <= 0 )
		{
			message = _("Click to select spawn location");
		}

		drawcolorcodedstring(pos + '0.5 0 0' * (mySize_x - stringwidth(message, true, hud_fontsize)) - '0 1 0' * hud_fontsize_y * 2,
							 message, hud_fontsize, hud_panel_radar_foreground_alpha, DRAWFLAG_NORMAL);

		hud_panel_radar_bottom = pos_y + mySize_y + hud_fontsize_y;
	}
}
