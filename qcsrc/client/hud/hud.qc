#include "hud.qh"

#include <client/draw.qh>
#include <client/hud/hud_config.qh>
#include <client/hud/panel/chat.qh>
#include <client/hud/panel/scoreboard.qh>
#include <client/items/items.qh>
#include <client/mapvoting.qh>
#include <client/teamradar.qh>
#include <client/view.qh>
#include <common/deathtypes/all.qh>
#include <common/ent_cs.qh>
#include <common/gametypes/_mod.qh>
#include <common/items/_mod.qh>
#include <common/mapinfo.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/mutators/mutator/waypoints/all.qh>
#include <common/stats.qh>
#include <common/vehicles/all.qh>
#include <common/vehicles/vehicle/bumblebee.qh>
#include <lib/csqcmodel/cl_model.qh>
#include <lib/csqcmodel/cl_player.qh>


/*
==================
Misc HUD functions
==================
*/

void draw_cursor(vector pos, vector ofs, string img, vector col, float a)
{
	ofs = vec2(ofs.x * SIZE_CURSOR.x, ofs.y * SIZE_CURSOR.y);
	drawpic(pos - ofs, strcat(draw_currentSkin, img), SIZE_CURSOR, col, a, DRAWFLAG_NORMAL);
}

void draw_cursor_normal(vector pos, vector col, float a)
{
	draw_cursor(pos, OFFSET_CURSOR, "/cursor", col, a);
}

void LoadMenuSkinValues()
{
	int fh = -1;
	if(cvar_string("menu_skin") != "")
	{
		draw_currentSkin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
	if(fh < 0 && cvar_defstring("menu_skin") != "")
	{
		cvar_set("menu_skin", cvar_defstring("menu_skin"));
		draw_currentSkin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
	if(fh < 0)
	{
		draw_currentSkin = "gfx/menu/wickedx"; // default menu skin
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}

	draw_currentSkin = strzone(draw_currentSkin);

	if(fh >= 0)
	{
		string s;
		while((s = fgets(fh)))
		{
			int n = tokenize_console(s);
			if (n < 2)
				continue;
			if(substring(argv(0), 0, 2) == "//")
				continue;
			if(argv(0) == "SIZE_CURSOR")
				SIZE_CURSOR = stov(substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
			else if(argv(0) == "OFFSET_CURSOR")
				OFFSET_CURSOR = stov(substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
		}
		fclose(fh);
	}
}

void HUD_Scale_Disable()
{
	hud_scale = '1 1 0';
	hud_shift = '0 0 0';
	drawfontscale = hud_scale;
}

void HUD_Scale_Enable()
{
	hud_scale = hud_scale_current;
	hud_shift = hud_shift_current;
	drawfontscale = hud_scale;
}

vector HUD_Scale(vector v)
{
	v.x = HUD_ScaleX(v.x);
	v.y = HUD_ScaleY(v.y);
	return v;
}

vector HUD_Shift(vector v)
{
	v.x = HUD_ShiftX(v.x);
	v.y = HUD_ShiftY(v.y);
	return v;
}

vector HUD_GetFontsize(string cvarname)
{
	vector v;
	v = stov(cvar_string(cvarname));
	if(v.x == 0)
		v = '8 8 0';
	if(v.y == 0)
		v.y = v.x;
	v.z = 0;
	return v;
}

vector HUD_Get_Num_Color(float hp, float maxvalue, bool blink)
{
	const vector COLOR100 = '0 1 0'; // green
	const vector COLOR75 = '0.4 0.9 0'; // lightgreen
	const vector COLOR50 = '1 1 1'; // white
	const vector COLOR25 = '1 1 0.2'; // lightyellow
	const vector COLOR10 = '1 0 0'; // red
	vector color;

	float hp_percent = hp / maxvalue * 100;
	#define CASE_COLOR_BETWEEN(min, max) \
		if(hp_percent > min) \
			color = COLOR##min + (COLOR##max - COLOR##min) * ((hp_percent - min) / (max - min))

	if(hp_percent > 100) color = COLOR100;
	else CASE_COLOR_BETWEEN(75, 100);
	else CASE_COLOR_BETWEEN(50, 75);
	else CASE_COLOR_BETWEEN(25, 50);
	else CASE_COLOR_BETWEEN(10, 25);
	else color = COLOR10;

	#undef CASE_COLOR_BETWEEN

	if (blink)
	{
		if(hp_percent >= 100)
		{
			float f = sin(2*M_PI*time);
			if (color.x == 0) color.x = f;
			if (color.y == 0) color.y = f;
			if (color.z == 0) color.z = f;
		}
		else if(hp_percent < 25)
		{
			float f = (1 - hp_percent / 25) * sin(2*M_PI*time);
			color -= color * f;
		}
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

void DrawNumIcon_expanding(vector myPos, vector mySize, float theTime, string icon, bool vertical, bool isInfinite, int icon_right_align, vector color, float theAlpha, float fadelerp)
{
	TC(bool, vertical); TC(int, icon_right_align);
	vector newPos = '0 0 0', newSize = '0 0 0';
	vector picpos, numpos;
	string text = isInfinite ? "\xE2\x88\x9E" : ftos(theTime); // Use infinity symbol (U+221E)

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
		drawstring_aspect(numpos, text, newSize, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
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
	drawstring_aspect_expanding(numpos, text, '2 1 0' * newSize.y, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL, fadelerp);
	drawpic_aspect_skin_expanding(picpos, icon, '1 1 0' * newSize.y, '1 1 1', panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL, fadelerp);
}

void DrawNumIcon(vector myPos, vector mySize, float theTime, string icon, bool vertical, bool isInfinite, int icon_right_align, vector color, float theAlpha)
{
	TC(bool, vertical); TC(int, icon_right_align);
	DrawNumIcon_expanding(myPos, mySize, theTime, icon, vertical, isInfinite, icon_right_align, color, theAlpha, 0);
}

/*
==================
Main HUD system
==================
*/

float lasthud;
float vh_notice_time;
void HUD_Vehicle()
{
	if(autocvar__hud_configure) return;
	if(intermission == 2) return;

	if(hud == HUD_BUMBLEBEE_GUN)
		CSQC_BUMBLE_GUN_HUD();
	else {
		Vehicle info = REGISTRY_GET(Vehicles, hud);
		info.vr_hud(info);
	}

	if(hud != HUD_NORMAL && lasthud == HUD_NORMAL)
		vh_notice_time = time + autocvar_cl_vehicles_notify_time;

	lasthud = hud;
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
	if (scoreboard_fade_alpha && panel.panel_showflags & PANEL_SHOW_WITH_SB)
	{
		draw_allowed = true;
	}
	else if (active_minigame && HUD_MinigameMenu_IsOpened())
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
		{
			if (scoreboard_fade_alpha && intermission == 2 && !(panel.panel_showflags & PANEL_SHOW_MAPVOTE))
				panel_fade_alpha = scoreboard_fade_alpha;
			else
				panel_fade_alpha = 1;
		}
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
	if(mv_active && !isdemo())
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

float prev_myteam;
void HUD_Main()
{
	int i;
	if(hud_configure_menu_open == 1)
		hud_fade_alpha = 1;
	else
		hud_fade_alpha = 1 - autocvar__menu_alpha;

	if(myteam != prev_myteam)
	{
		myteamcolors = colormapPaletteColor(myteam, 1);
		FOREACH(hud_panels, true, it.update_time = time);
		prev_myteam = myteam;
	}

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
		for(i = 0; i < REGISTRY_COUNT(hud_panels); ++i)
			panel_order[i] = -1;
		string s = "";
		int p_num;
		bool warning = false;
		int argc = tokenize_console(autocvar__hud_panelorder);
		if (argc > REGISTRY_COUNT(hud_panels))
			warning = true;
		//first detect wrong/missing panel numbers
		for(i = 0; i < REGISTRY_COUNT(hud_panels); ++i) {
			p_num = stoi(argv(i));
			if (p_num >= 0 && p_num < REGISTRY_COUNT(hud_panels)) { //correct panel number?
				if (panel_order[p_num] == -1) //found for the first time?
					s = strcat(s, ftos(p_num), " ");
				panel_order[p_num] = 1; //mark as found
			}
			else
				warning = true;
		}
		for(i = 0; i < REGISTRY_COUNT(hud_panels); ++i) {
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
		for(i = 0; i < REGISTRY_COUNT(hud_panels); ++i) {
			panel_order[i] = stof(argv(i));
		}
	}

	hud_draw_maximized = 0;
	// draw panels in the order specified by panel_order array
	for(i = REGISTRY_COUNT(hud_panels) - 1; i >= 0; --i)
		HUD_Panel_Draw(REGISTRY_GET(hud_panels, panel_order[i]));

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
