#include "hud.qh"

#include <client/defs.qh>
#include <client/miscfunctions.qh>
#include <client/view.qh>
#include "panel/scoreboard.qh"
#include "hud_config.qh"
#include "../mapvoting.qh"
#include "../teamradar.qh"
#include <common/minigames/cl_minigames.qh>
#include <common/t_items.qh>
#include <common/deathtypes/all.qh>
#include <common/ent_cs.qh>
#include <common/items/_mod.qh>
#include <common/mapinfo.qh>
#include <common/vehicles/all.qh>
#include <common/vehicles/vehicle/bumblebee.qh>
#include <common/mutators/mutator/waypoints/all.qh>
#include <common/stats.qh>
#include <lib/csqcmodel/cl_player.qh>
#include <lib/csqcmodel/cl_model.qh>
#include <common/gamemodes/_mod.qh>


/*
==================
Misc HUD functions
==================
*/

vector HUD_Get_Num_Color (float hp, float maxvalue)
{
	float blinkingamt;
	vector color;
	if(hp >= maxvalue) {
		color.x = sin(2*M_PI*time);
		color.y = 1;
		color.z = sin(2*M_PI*time);
	}
	else if(hp > maxvalue * 0.75) {
		color.x = 0.4 - (hp-150)*0.02 * 0.4; //red value between 0.4 -> 0
		color.y = 0.9 + (hp-150)*0.02 * 0.1; // green value between 0.9 -> 1
		color.z = 0;
	}
	else if(hp > maxvalue * 0.5) {
		color.x = 1 - (hp-100)*0.02 * 0.6; //red value between 1 -> 0.4
		color.y = 1 - (hp-100)*0.02 * 0.1; // green value between 1 -> 0.9
		color.z = 1 - (hp-100)*0.02; // blue value between 1 -> 0
	}
	else if(hp > maxvalue * 0.25) {
		color.x = 1;
		color.y = 1;
		color.z = 0.2 + (hp-50)*0.02 * 0.8; // blue value between 0.2 -> 1
	}
	else if(hp > maxvalue * 0.1) {
		color.x = 1;
		color.y = (hp-20)*90/27/100; // green value between 0 -> 1
		color.z = (hp-20)*90/27/100 * 0.2; // blue value between 0 -> 0.2
	}
	else {
		color.x = 1;
		color.y = 0;
		color.z = 0;
	}

	blinkingamt = (1 - hp/maxvalue/0.25);
	if(blinkingamt > 0)
	{
		color.x = color.x - color.x * blinkingamt * sin(2*M_PI*time);
		color.y = color.y - color.y * blinkingamt * sin(2*M_PI*time);
		color.z = color.z - color.z * blinkingamt * sin(2*M_PI*time);
	}
	return color;
}

float HUD_GetRowCount(int item_count, vector size, float item_aspect)
{
	TC(int, item_count);
	float aspect = size_y / size_x;
	return bound(1, floor((sqrt(4 * item_aspect * aspect * item_count + aspect * aspect) + aspect + 0.5) / 2), item_count);
}

vector HUD_GetTableSize_BestItemAR(int item_count, vector psize, float item_aspect)
{
	TC(int, item_count);
	float columns, rows;
	float ratio, best_ratio = 0;
	float best_columns = 1, best_rows = 1;
	bool vertical = (psize.x / psize.y >= item_aspect);
	if(vertical)
	{
		psize = eX * psize.y + eY * psize.x;
		item_aspect = 1 / item_aspect;
	}

	rows = ceil(sqrt(item_count));
	columns = ceil(item_count/rows);
	while(columns >= 1)
	{
		ratio = (psize.x/columns) / (psize.y/rows);
		if(ratio > item_aspect)
			ratio = item_aspect * item_aspect / ratio;

		if(ratio <= best_ratio)
			break; // ratio starts decreasing by now, skip next configurations

		best_columns = columns;
		best_rows = rows;
		best_ratio = ratio;

		if(columns == 1)
			break;

		--columns;
		rows = ceil(item_count/columns);
	}

	return (vertical) ? vec2(best_rows, best_columns) : vec2(best_columns, best_rows);
}

/*
==================
HUD panels
==================
*/

void HUD_Panel_LoadCvars()
{
	// NOTE: in hud_configure mode cvars must be reloaded every frame
	if (panel.update_time <= time)
	{
		panel_pos = stov(cvar_string(strcat("hud_panel_", panel.panel_name, "_pos")));
		panel_size = stov(cvar_string(strcat("hud_panel_", panel.panel_name, "_size")));
		HUD_Panel_ScalePosSize();
		panel_bg_str = cvar_string(strcat("hud_panel_", panel.panel_name, "_bg"));
		panel_bg_color_str = cvar_string(strcat("hud_panel_", panel.panel_name, "_bg_color"));
		panel_bg_color_team_str = cvar_string(strcat("hud_panel_", panel.panel_name, "_bg_color_team"));
		panel_bg_alpha_str = cvar_string(strcat("hud_panel_", panel.panel_name, "_bg_alpha"));
		panel_bg_border_str = cvar_string(strcat("hud_panel_", panel.panel_name, "_bg_border"));
		panel_bg_padding_str = cvar_string(strcat("hud_panel_", panel.panel_name, "_bg_padding"));
		HUD_Panel_GetBg();
		if (panel.current_panel_bg != "0")
		{
			HUD_Panel_GetBgAlpha();
			HUD_Panel_GetBorder();
		}
		HUD_Panel_GetColorTeam();
		HUD_Panel_GetColor();
		HUD_Panel_GetFgAlpha();
		HUD_Panel_GetPadding();
		panel.current_panel_bg_alpha = panel_bg_alpha;
		panel.current_panel_fg_alpha = panel_fg_alpha;
		if (hud_configure_menu_open == 2 && panel == highlightedPanel)
			HUD_Panel_UpdatePosSize_ForMenu();
		else
		{
			panel_bg_alpha *= hud_fade_alpha * panel_fade_alpha;
			panel_fg_alpha *= hud_fade_alpha * panel_fade_alpha;
		}
		panel.current_panel_pos = panel_pos;
		panel.current_panel_size = panel_size;
		panel.current_panel_bg_border = panel_bg_border;
		panel.current_panel_bg_color = panel_bg_color;
		panel.current_panel_bg_color_team = panel_bg_color_team;
		panel.current_panel_bg_padding = panel_bg_padding;
		panel.update_time = (autocvar__hud_configure) ? time : time + autocvar_hud_panel_update_interval;
		return;
	}

	panel_pos = panel.current_panel_pos;
	panel_size = panel.current_panel_size;
	panel_bg_alpha = panel.current_panel_bg_alpha * hud_fade_alpha * panel_fade_alpha;
	panel_bg_border = panel.current_panel_bg_border;
	panel_bg_color = panel.current_panel_bg_color;
	panel_bg_color_team = panel.current_panel_bg_color_team;
	panel_bg_padding = panel.current_panel_bg_padding;
	panel_fg_alpha = panel.current_panel_fg_alpha * hud_fade_alpha * panel_fade_alpha;
}

//basically the same code of draw_ButtonPicture and draw_VertButtonPicture for the menu
void HUD_Panel_DrawProgressBar(vector theOrigin, vector theSize, string pic, float length_ratio, bool vertical, float baralign, vector theColor, float theAlpha, int drawflag)
{
	TC(bool, vertical); TC(int, drawflag);
	if(!length_ratio || !theAlpha)
		return;
	if(length_ratio > 1)
		length_ratio = 1;
	if (baralign == 3)
	{
		if(length_ratio < -1)
			length_ratio = -1;
	}
	else if(length_ratio < 0)
		return;

	theOrigin = HUD_Shift(theOrigin);
	theSize = HUD_Scale(theSize);

	vector square;
	vector width, height;
	if(vertical) {
		pic = strcat(hud_skin_path, "/", pic, "_vertical");
		if(precache_pic(pic) == "") {
			pic = "gfx/hud/default/progressbar_vertical";
		}

        if (baralign == 1) // bottom align
			theOrigin.y += (1 - length_ratio) * theSize.y;
        else if (baralign == 2) // center align
            theOrigin.y += 0.5 * (1 - length_ratio) * theSize.y;
        else if (baralign == 3) // center align, positive values down, negative up
		{
			theSize.y *= 0.5;
			if (length_ratio > 0)
				theOrigin.y += theSize.y;
			else
			{
				theOrigin.y += (1 + length_ratio) * theSize.y;
				length_ratio = -length_ratio;
			}
		}
		theSize.y *= length_ratio;

		vector bH;
		width = eX * theSize.x;
		height = eY * theSize.y;
		if(theSize.y <= theSize.x * 2)
		{
			// button not high enough
			// draw just upper and lower part then
			square = eY * theSize.y * 0.5;
			bH = eY * (0.25 * theSize.y / (theSize.x * 2));
			drawsubpic(theOrigin,          square + width, pic, '0 0 0', eX + bH, theColor, theAlpha, drawflag);
			drawsubpic(theOrigin + square, square + width, pic, eY - bH, eX + bH, theColor, theAlpha, drawflag);
		}
		else
		{
			square = eY * theSize.x;
			drawsubpic(theOrigin,                   width   +     square, pic, '0 0    0', '1 0.25 0', theColor, theAlpha, drawflag);
			drawsubpic(theOrigin +          square, theSize - 2 * square, pic, '0 0.25 0', '1 0.5  0', theColor, theAlpha, drawflag);
			drawsubpic(theOrigin + height - square, width   +     square, pic, '0 0.75 0', '1 0.25 0', theColor, theAlpha, drawflag);
		}
	} else {
		pic = strcat(hud_skin_path, "/", pic);
		if(precache_pic(pic) == "") {
			pic = "gfx/hud/default/progressbar";
		}

		if (baralign == 1) // right align
			theOrigin.x += (1 - length_ratio) * theSize.x;
        else if (baralign == 2) // center align
            theOrigin.x += 0.5 * (1 - length_ratio) * theSize.x;
        else if (baralign == 3) // center align, positive values on the right, negative on the left
		{
			theSize.x *= 0.5;
			if (length_ratio > 0)
				theOrigin.x += theSize.x;
			else
			{
				theOrigin.x += (1 + length_ratio) * theSize.x;
				length_ratio = -length_ratio;
			}
		}
		theSize.x *= length_ratio;

		vector bW;
		width = eX * theSize.x;
		height = eY * theSize.y;
		if(theSize.x <= theSize.y * 2)
		{
			// button not wide enough
			// draw just left and right part then
			square = eX * theSize.x * 0.5;
			bW = eX * (0.25 * theSize.x / (theSize.y * 2));
			drawsubpic(theOrigin,          square + height, pic, '0 0 0', eY + bW, theColor, theAlpha, drawflag);
			drawsubpic(theOrigin + square, square + height, pic, eX - bW, eY + bW, theColor, theAlpha, drawflag);
		}
		else
		{
			square = eX * theSize.y;
			drawsubpic(theOrigin,                  height  +     square, pic, '0    0 0', '0.25 1 0', theColor, theAlpha, drawflag);
			drawsubpic(theOrigin +         square, theSize - 2 * square, pic, '0.25 0 0', '0.5  1 0', theColor, theAlpha, drawflag);
			drawsubpic(theOrigin + width - square, height  +     square, pic, '0.75 0 0', '0.25 1 0', theColor, theAlpha, drawflag);
		}
	}
}

void HUD_Panel_DrawHighlight(vector pos, vector mySize, vector color, float theAlpha, int drawflag)
{
	TC(int, drawflag);
	if(!theAlpha)
		return;

	pos = HUD_Shift(pos);
	mySize = HUD_Scale(mySize);

	string pic;
	pic = strcat(hud_skin_path, "/num_leading");
	if(precache_pic(pic) == "") {
		pic = "gfx/hud/default/num_leading";
	}

	drawsubpic(pos, eX * min(mySize.x * 0.5, mySize.y) + eY * mySize.y, pic, '0 0 0', '0.25 1 0', color, theAlpha, drawflag);
	if(mySize.x/mySize.y > 2)
		drawsubpic(pos + eX * mySize.y, eX * (mySize.x - 2 * mySize.y) + eY * mySize.y, pic, '0.25 0 0', '0.5 1 0', color, theAlpha, drawflag);
	drawsubpic(pos + eX * mySize.x - eX * min(mySize.x * 0.5, mySize.y), eX * min(mySize.x * 0.5, mySize.y) + eY * mySize.y, pic, '0.75 0 0', '0.25 1 0', color, theAlpha, drawflag);
}

void DrawNumIcon_expanding(vector myPos, vector mySize, float theTime, string icon, bool vertical, int icon_right_align, vector color, float theAlpha, float fadelerp)
{
	TC(bool, vertical); TC(int, icon_right_align);
	vector newPos = '0 0 0', newSize = '0 0 0';
	vector picpos, numpos;

	if (vertical)
	{
		if(mySize.y/mySize.x > 2)
		{
			newSize.y = 2 * mySize.x;
			newSize.x = mySize.x;

			newPos.y = myPos.y + (mySize.y - newSize.y) / 2;
			newPos.x = myPos.x;
		}
		else
		{
			newSize.x = 1/2 * mySize.y;
			newSize.y = mySize.y;

			newPos.x = myPos.x + (mySize.x - newSize.x) / 2;
			newPos.y = myPos.y;
		}

		if(icon_right_align)
		{
			numpos = newPos;
			picpos = newPos + eY * newSize.x;
		}
		else
		{
			picpos = newPos;
			numpos = newPos + eY * newSize.x;
		}

		newSize.y /= 2;
		drawpic_aspect_skin(picpos, icon, newSize, '1 1 1', panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
		// make number smaller than icon, it looks better
		// reduce only y to draw numbers with different number of digits with the same y size
		numpos.y += newSize.y * ((1 - 0.7) / 2);
		newSize.y *= 0.7;
		drawstring_aspect(numpos, ftos(theTime), newSize, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
		return;
	}

	if(mySize.x/mySize.y > 3)
	{
		newSize.x = 3 * mySize.y;
		newSize.y = mySize.y;

		newPos.x = myPos.x + (mySize.x - newSize.x) / 2;
		newPos.y = myPos.y;
	}
	else
	{
		newSize.y = 1/3 * mySize.x;
		newSize.x = mySize.x;

		newPos.y = myPos.y + (mySize.y - newSize.y) / 2;
		newPos.x = myPos.x;
	}

	if(icon_right_align) // right align
	{
		numpos = newPos;
		picpos = newPos + eX * 2 * newSize.y;
	}
	else // left align
	{
		numpos = newPos + eX * newSize.y;
		picpos = newPos;
	}

	// NOTE: newSize_x is always equal to 3 * mySize_y so we can use
	// '2 1 0' * newSize_y instead of eX * (2/3) * newSize_x + eY * newSize_y
	drawstring_aspect_expanding(numpos, ftos(theTime), '2 1 0' * newSize.y, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL, fadelerp);
	drawpic_aspect_skin_expanding(picpos, icon, '1 1 0' * newSize.y, '1 1 1', panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL, fadelerp);
}

void DrawNumIcon(vector myPos, vector mySize, float theTime, string icon, bool vertical, int icon_right_align, vector color, float theAlpha)
{
	TC(bool, vertical); TC(int, icon_right_align);
	DrawNumIcon_expanding(myPos, mySize, theTime, icon, vertical, icon_right_align, color, theAlpha, 0);
}

/*
==================
Main HUD system
==================
*/

void HUD_Vehicle()
{
	if(autocvar__hud_configure) return;
	if(intermission == 2) return;

	if(hud == HUD_BUMBLEBEE_GUN)
		CSQC_BUMBLE_GUN_HUD();
	else {
		Vehicle info = Vehicles_from(hud);
		info.vr_hud(info);
	}
}

void HUD_Panel_Draw(entity panent)
{
	panel = panent;
	if (autocvar__hud_configure)
	{
		if (!(panel.panel_configflags & PANEL_CONFIG_MAIN))
			return;
		panel_fade_alpha = 1;
		Hud_Panel_GetPanelEnabled();
		panel.panel_draw();
		return;
	}

	bool draw_allowed = false;
	if (active_minigame && HUD_MinigameMenu_IsOpened())
	{
		if (panel.panel_showflags & PANEL_SHOW_MINIGAME)
			draw_allowed = true;
	}
	else if(intermission == 2)
	{
		if(panel.panel_showflags & PANEL_SHOW_MAPVOTE)
			draw_allowed = true;
	}
	else if (panel.panel_showflags & PANEL_SHOW_MAINGAME)
		draw_allowed = true;

	if (draw_allowed)
	{
		if (panel.panel_showflags & PANEL_SHOW_WITH_SB)
			panel_fade_alpha = 1;
		else
		{
			panel_fade_alpha = 1 - scoreboard_fade_alpha;
			if(!panel_fade_alpha)
				return;
		}
		panel.panel_draw();
	}
}

void HUD_Reset()
{
	// reset gametype specific icons
	if(gametype.m_modicons_reset)
		gametype.m_modicons_reset();
}

float autocvar_hud_dynamic_shake = 1;
float autocvar_hud_dynamic_shake_damage_max = 130;
float autocvar_hud_dynamic_shake_damage_min = 10;
float autocvar_hud_dynamic_shake_scale = 0.2;
float hud_dynamic_shake_x[10] = {0,    1, -0.7,  0.5, -0.3,  0.2, -0.1,  0.1,  0.0, 0};
float hud_dynamic_shake_y[10] = {0,  0.4,  0.8, -0.2, -0.6,  0.0,  0.3,  0.1, -0.1, 0};
bool Hud_Shake_Update()
{
	if(time - hud_dynamic_shake_time < 0)
		return false;

	float anim_speed = 17 + 9 * hud_dynamic_shake_factor;
	float elapsed_time = (time - hud_dynamic_shake_time) * anim_speed;
	int i = floor(elapsed_time);
	if(i >= 9)
		return false;

	float f = elapsed_time - i;
	hud_dynamic_shake_realofs.x = (1 - f) * hud_dynamic_shake_x[i] + f * hud_dynamic_shake_x[i+1];
	hud_dynamic_shake_realofs.y = (1 - f) * hud_dynamic_shake_y[i] + f * hud_dynamic_shake_y[i+1];
	hud_dynamic_shake_realofs.z = 0;
	hud_dynamic_shake_realofs *= hud_dynamic_shake_factor * autocvar_hud_dynamic_shake_scale;
	hud_dynamic_shake_realofs.x = bound(-0.1, hud_dynamic_shake_realofs.x, 0.1) * vid_conwidth;
	hud_dynamic_shake_realofs.y = bound(-0.1, hud_dynamic_shake_realofs.y, 0.1) * vid_conheight;
	return true;
}

void Hud_Dynamic_Frame()
{
	vector ofs = '0 0 0';
	hud_scale_current = '1 1 0';
	hud_shift_current = '0 0 0';

	if (autocvar_hud_dynamic_follow)
	{
		entity view = CSQCModel_server2csqc(player_localentnum - 1);
		calc_followmodel_ofs(view);
		ofs = -cl_followmodel_ofs * autocvar_hud_dynamic_follow_scale;
		ofs.x *= autocvar_hud_dynamic_follow_scale_xyz.z;
		ofs.y *= autocvar_hud_dynamic_follow_scale_xyz.x;
		ofs.z *= autocvar_hud_dynamic_follow_scale_xyz.y;

		if (fabs(ofs.x) < 0.001) ofs.x = 0;
		if (fabs(ofs.y) < 0.001) ofs.y = 0;
		if (fabs(ofs.z) < 0.001) ofs.z = 0;
		ofs.x = bound(-0.1, ofs.x, 0.1);
		ofs.y = bound(-0.1, ofs.y, 0.1);
		ofs.z = bound(-0.1, ofs.z, 0.1);

		hud_shift_current.x = ofs.y * vid_conwidth;
		hud_shift_current.y = ofs.z * vid_conheight;
		hud_shift_current.z = ofs.x;

		hud_scale_current.x = (1 + hud_shift_current.z);
		hud_scale_current.y = hud_scale_current.x;
	}

	if(autocvar_hud_dynamic_shake > 0)
	{
		static float old_health = 0;
		float health = max(-1, STAT(HEALTH));
		if(hud_dynamic_shake_factor == -1) // don't allow the effect for this frame
		{
			hud_dynamic_shake_factor = 0;
			old_health = health;
		}
		else
		{
			float new_hud_dynamic_shake_factor = 0;
			if (old_health - health >= autocvar_hud_dynamic_shake_damage_min
				&& autocvar_hud_dynamic_shake_damage_max > autocvar_hud_dynamic_shake_damage_min
				&& old_health > 0 && !intermission)
			{
				float m = max(autocvar_hud_dynamic_shake_damage_min, 1);
				new_hud_dynamic_shake_factor = (old_health - health - m) / (autocvar_hud_dynamic_shake_damage_max - m);
				if(new_hud_dynamic_shake_factor >= 1)
					new_hud_dynamic_shake_factor = 1;
				if(new_hud_dynamic_shake_factor >= hud_dynamic_shake_factor)
				{
					hud_dynamic_shake_factor = new_hud_dynamic_shake_factor;
					hud_dynamic_shake_time = time;
				}
			}
			old_health = health;
			if(hud_dynamic_shake_factor)
				if(!Hud_Shake_Update())
					hud_dynamic_shake_factor = 0;
		}

		if(hud_dynamic_shake_factor > 0)
		{
			hud_shift_current.x += hud_dynamic_shake_realofs.x;
			hud_shift_current.y += hud_dynamic_shake_realofs.y;
		}
	}

	hud_scale_center.x = 0.5 * vid_conwidth;
	hud_scale_center.y = 0.5 * vid_conheight;

	HUD_Scale_Disable();
}

bool HUD_WouldShowCursor()
{
	if(autocvar__hud_configure)
		return true;
	if(mv_active)
		return true;
	//entity local_player = ((csqcplayer) ? csqcplayer : CSQCModel_server2csqc(player_localentnum - 1)); // TODO: doesn't use regular cursor handling
	//if(local_player.viewloc && (local_player.viewloc.spawnflags & VIEWLOC_FREEAIM))
		//return true;
	if(HUD_Radar_Clickable())
		return true;
	if(HUD_MinigameMenu_IsOpened())
		return true;
	if(QuickMenu_IsOpened())
		return true;
	return false;
}

void HUD_Main()
{
	int i;
	if(hud_configure_menu_open == 1)
		hud_fade_alpha = 1;
	else
		hud_fade_alpha = 1 - autocvar__menu_alpha;

	HUD_Configure_Frame();

	if(scoreboard_fade_alpha == 1)
		if(autocvar__menu_alpha == 1)
			return;

	// Drawing stuff
	if (hud_skin_prev != autocvar_hud_skin)
	{
		strcpy(hud_skin_path, strcat("gfx/hud/", autocvar_hud_skin));
		strcpy(hud_skin_prev, autocvar_hud_skin);
	}

	// draw the dock
	if(autocvar_hud_dock != "" && autocvar_hud_dock != "0")
	{
		int f;
		vector color;
		float hud_dock_color_team = autocvar_hud_dock_color_team;
		if((teamplay) && hud_dock_color_team) {
			if(autocvar__hud_configure && myteam == NUM_SPECTATOR)
				color = '1 0 0' * hud_dock_color_team;
			else
				color = myteamcolors * hud_dock_color_team;
		}
		else if(autocvar_hud_configure_teamcolorforced && autocvar__hud_configure && hud_dock_color_team) {
			color = '1 0 0' * hud_dock_color_team;
		}
		else
		{
			string hud_dock_color = autocvar_hud_dock_color;
			if(hud_dock_color == "shirt") {
				f = entcs_GetClientColors(current_player);
				color = colormapPaletteColor(floor(f / 16), 0);
			}
			else if(hud_dock_color == "pants") {
				f = entcs_GetClientColors(current_player);
				color = colormapPaletteColor(f % 16, 1);
			}
			else
				color = stov(hud_dock_color);
		}

		string pic;
		pic = strcat(hud_skin_path, "/", autocvar_hud_dock);
		if(precache_pic(pic) == "") {
			pic = strcat(hud_skin_path, "/dock_medium");
			if(precache_pic(pic) == "") {
				pic = "gfx/hud/default/dock_medium";
			}
		}
		drawpic('0 0 0', pic, eX * vid_conwidth + eY * vid_conheight, color, autocvar_hud_dock_alpha * hud_fade_alpha, DRAWFLAG_NORMAL); // no aspect ratio forcing on dock...
	}

	// cache the panel order into the panel_order array
	if(autocvar__hud_panelorder != hud_panelorder_prev) {
		for(i = 0; i < hud_panels_COUNT; ++i)
			panel_order[i] = -1;
		string s = "";
		int p_num;
		bool warning = false;
		int argc = tokenize_console(autocvar__hud_panelorder);
		if (argc > hud_panels_COUNT)
			warning = true;
		//first detect wrong/missing panel numbers
		for(i = 0; i < hud_panels_COUNT; ++i) {
			p_num = stoi(argv(i));
			if (p_num >= 0 && p_num < hud_panels_COUNT) { //correct panel number?
				if (panel_order[p_num] == -1) //found for the first time?
					s = strcat(s, ftos(p_num), " ");
				panel_order[p_num] = 1; //mark as found
			}
			else
				warning = true;
		}
		for(i = 0; i < hud_panels_COUNT; ++i) {
			if (panel_order[i] == -1) {
				warning = true;
				s = strcat(s, ftos(i), " "); //add missing panel number
			}
		}
		if (warning)
			LOG_TRACE("Automatically fixed wrong/missing panel numbers in _hud_panelorder");

		cvar_set("_hud_panelorder", s);
		strcpy(hud_panelorder_prev, s);

		//now properly set panel_order
		tokenize_console(s);
		for(i = 0; i < hud_panels_COUNT; ++i) {
			panel_order[i] = stof(argv(i));
		}
	}

	hud_draw_maximized = 0;
	// draw panels in the order specified by panel_order array
	for(i = hud_panels_COUNT - 1; i >= 0; --i)
		HUD_Panel_Draw(hud_panels_from(panel_order[i]));

	HUD_Vehicle();

	hud_draw_maximized = 1; // panels that may be maximized must check this var
	// draw maximized panels on top
	if(hud_panel_radar_maximized)
		HUD_Panel_Draw(HUD_PANEL(RADAR));
	if(autocvar__con_chat_maximized)
		HUD_Panel_Draw(HUD_PANEL(CHAT));
	if (QuickMenu_IsOpened())
		HUD_Panel_Draw(HUD_PANEL(QUICKMENU));
	HUD_Panel_Draw(HUD_PANEL(SCOREBOARD));

	int cursor_active_prev = cursor_active;
	cursor_active = HUD_WouldShowCursor();
	if (cursor_active_prev != cursor_active && autocvar_hud_cursormode)
	{
		setcursormode(cursor_active);
		// cursor inactive this frame, will be set to 1 the next frame
		if (cursor_active)
			cursor_active = -1;
	}

	if (intermission == 2)
		HUD_Reset();

	HUD_Configure_PostDraw();

	hud_configure_prev = autocvar__hud_configure;
}
