#include "hud.qh"

#include "hud_config.qh"
#include "mapvoting.qh"
#include "scoreboard.qh"
#include "teamradar.qh"
#include "t_items.qh"
#include "../common/deathtypes/all.qh"
#include "../common/items/all.qc"
#include "../common/mapinfo.qh"
#include "../common/mutators/mutator/waypoints/all.qh"
#include "../common/stats.qh"
#include "../lib/csqcmodel/cl_player.qh"
// TODO: remove
#include "../server/mutators/mutator/gamemode_ctf.qc"


/*
==================
Misc HUD functions
==================
*/

vector HUD_Get_Num_Color (float x, float maxvalue)
{
	float blinkingamt;
	vector color;
	if(x >= maxvalue) {
		color.x = sin(2*M_PI*time);
		color.y = 1;
		color.z = sin(2*M_PI*time);
	}
	else if(x > maxvalue * 0.75) {
		color.x = 0.4 - (x-150)*0.02 * 0.4; //red value between 0.4 -> 0
		color.y = 0.9 + (x-150)*0.02 * 0.1; // green value between 0.9 -> 1
		color.z = 0;
	}
	else if(x > maxvalue * 0.5) {
		color.x = 1 - (x-100)*0.02 * 0.6; //red value between 1 -> 0.4
		color.y = 1 - (x-100)*0.02 * 0.1; // green value between 1 -> 0.9
		color.z = 1 - (x-100)*0.02; // blue value between 1 -> 0
	}
	else if(x > maxvalue * 0.25) {
		color.x = 1;
		color.y = 1;
		color.z = 0.2 + (x-50)*0.02 * 0.8; // blue value between 0.2 -> 1
	}
	else if(x > maxvalue * 0.1) {
		color.x = 1;
		color.y = (x-20)*90/27/100; // green value between 0 -> 1
		color.z = (x-20)*90/27/100 * 0.2; // blue value between 0 -> 0.2
	}
	else {
		color.x = 1;
		color.y = 0;
		color.z = 0;
	}

	blinkingamt = (1 - x/maxvalue/0.25);
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
	float aspect = size_y / size_x;
	return bound(1, floor((sqrt(4 * item_aspect * aspect * item_count + aspect * aspect) + aspect + 0.5) / 2), item_count);
}

vector HUD_GetTableSize_BestItemAR(int item_count, vector psize, float item_aspect)
{
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

	if(vertical)
		return eX * best_rows + eY * best_columns;
	else
		return eX * best_columns + eY * best_rows;
}

// return the string of the onscreen race timer
string MakeRaceString(int cp, float mytime, float theirtime, float lapdelta, string theirname)
{
	string col;
	string timestr;
	string cpname;
	string lapstr;
	lapstr = "";

	if(theirtime == 0) // goal hit
	{
		if(mytime > 0)
		{
			timestr = strcat("+", ftos_decimals(+mytime, TIME_DECIMALS));
			col = "^1";
		}
		else if(mytime == 0)
		{
			timestr = "+0.0";
			col = "^3";
		}
		else
		{
			timestr = strcat("-", ftos_decimals(-mytime, TIME_DECIMALS));
			col = "^2";
		}

		if(lapdelta > 0)
		{
			lapstr = sprintf(_(" (-%dL)"), lapdelta);
			col = "^2";
		}
		else if(lapdelta < 0)
		{
			lapstr = sprintf(_(" (+%dL)"), -lapdelta);
			col = "^1";
		}
	}
	else if(theirtime > 0) // anticipation
	{
		if(mytime >= theirtime)
			timestr = strcat("+", ftos_decimals(mytime - theirtime, TIME_DECIMALS));
		else
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(theirtime));
		col = "^3";
	}
	else
	{
		col = "^7";
		timestr = "";
	}

	if(cp == 254)
		cpname = _("Start line");
	else if(cp == 255)
		cpname = _("Finish line");
	else if(cp)
		cpname = sprintf(_("Intermediate %d"), cp);
	else
		cpname = _("Finish line");

	if(theirtime < 0)
		return strcat(col, cpname);
	else if(theirname == "")
		return strcat(col, sprintf("%s (%s)", cpname, timestr));
	else
		return strcat(col, sprintf("%s (%s %s)", cpname, timestr, strcat(theirname, col, lapstr)));
}

// Check if the given name already exist in race rankings? In that case, where? (otherwise return 0)
int race_CheckName(string net_name)
{
	int i;
	for (i=RANKINGS_CNT-1;i>=0;--i)
		if(grecordholder[i] == net_name)
			return i+1;
	return 0;
}

/*
==================
HUD panels
==================
*/

//basically the same code of draw_ButtonPicture and draw_VertButtonPicture for the menu
void HUD_Panel_DrawProgressBar(vector theOrigin, vector theSize, string pic, float length_ratio, bool vertical, float baralign, vector theColor, float theAlpha, int drawflag)
{
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
	if(!theAlpha)
		return;

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

void DrawNumIcon_expanding(vector myPos, vector mySize, float x, string icon, bool vertical, bool icon_right_align, vector color, float theAlpha, float fadelerp)
{
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
		drawstring_aspect(numpos, ftos(x), newSize, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
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
	drawstring_aspect_expanding(numpos, ftos(x), '2 1 0' * newSize.y, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL, fadelerp);
	drawpic_aspect_skin_expanding(picpos, icon, '1 1 0' * newSize.y, '1 1 1', panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL, fadelerp);
}

void DrawNumIcon(vector myPos, vector mySize, float x, string icon, bool vertical, bool icon_right_align, vector color, float theAlpha)
{
	DrawNumIcon_expanding(myPos, mySize, x, icon, vertical, icon_right_align, color, theAlpha, 0);
}

#include "all.inc"

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
		Vehicle info = get_vehicleinfo(hud);
		info.vr_hud(info);
	}
}

bool HUD_Panel_CheckFlags(int showflags)
{
	if ( HUD_Minigame_Showpanels() )
		return showflags & PANEL_SHOW_MINIGAME;
	if(intermission == 2)
		return showflags & PANEL_SHOW_MAPVOTE;
	return showflags & PANEL_SHOW_MAINGAME;
}

void HUD_Panel_Draw(entity panent)
{
	panel = panent;
	if(autocvar__hud_configure)
	{
		if(panel.panel_configflags & PANEL_CONFIG_MAIN)
			panel.panel_draw();
	}
	else if(HUD_Panel_CheckFlags(panel.panel_showflags))
		panel.panel_draw();
}

void HUD_Reset()
{
	// reset gametype specific icons
	if(gametype == MAPINFO_TYPE_CTF)
		HUD_Mod_CTF_Reset();
}

void HUD_Main()
{
	int i;
	// global hud theAlpha fade
	if(menu_enabled == 1)
		hud_fade_alpha = 1;
	else
		hud_fade_alpha = (1 - autocvar__menu_alpha);

	if(scoreboard_fade_alpha)
		hud_fade_alpha = (1 - scoreboard_fade_alpha);

	HUD_Configure_Frame();

	// panels that we want to be active together with the scoreboard
	// they must fade only when the menu does
	if(scoreboard_fade_alpha == 1)
	{
		HUD_Panel_Draw(HUD_PANEL(CENTERPRINT));
		return;
	}

	if(!autocvar__hud_configure && !hud_fade_alpha)
	{
		hud_fade_alpha = 1;
		HUD_Panel_Draw(HUD_PANEL(VOTE));
		hud_fade_alpha = 0;
		return;
	}

	// Drawing stuff
	if (hud_skin_prev != autocvar_hud_skin)
	{
		if (hud_skin_path)
			strunzone(hud_skin_path);
		hud_skin_path = strzone(strcat("gfx/hud/", autocvar_hud_skin));
		if (hud_skin_prev)
			strunzone(hud_skin_prev);
		hud_skin_prev = strzone(autocvar_hud_skin);
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
				f = stof(getplayerkeyvalue(current_player, "colors"));
				color = colormapPaletteColor(floor(f / 16), 0);
			}
			else if(hud_dock_color == "pants") {
				f = stof(getplayerkeyvalue(current_player, "colors"));
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
			LOG_TRACE("Automatically fixed wrong/missing panel numbers in _hud_panelorder\n");

		cvar_set("_hud_panelorder", s);
		if(hud_panelorder_prev)
			strunzone(hud_panelorder_prev);
		hud_panelorder_prev = strzone(s);

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
	if(hud_panel_quickmenu)
		HUD_Panel_Draw(HUD_PANEL(QUICKMENU));

	if (scoreboard_active || intermission == 2)
		HUD_Reset();

	HUD_Configure_PostDraw();

	hud_configure_prev = autocvar__hud_configure;
}
