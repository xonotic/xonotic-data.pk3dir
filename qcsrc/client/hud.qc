/*
==================
Misc HUD functions
==================
*/

// a border picture is a texture containing nine parts:
//   1/4 width: left part
//   1/2 width: middle part (stretched)
//   1/4 width: right part
// divided into
//   1/4 height: top part
//   1/2 height: middle part (stretched)
//   1/4 height: bottom part
void draw_BorderPicture(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha, vector theBorderSize)
{
    if (theBorderSize_x < 0 && theBorderSize_y < 0) // draw whole image as it is
    {
		drawpic(theOrigin, pic, theSize, theColor, theAlpha, 0);
		return;
    }
	if (theBorderSize_x == 0 && theBorderSize_y == 0) // no border
	{
		// draw only the central part
		drawsubpic(theOrigin, theSize, pic, '0.25 0.25 0', '0.5 0.5 0', theColor, theAlpha, 0);
		return;
	}

	vector dX, dY;
	vector width, height;
	vector bW, bH;
	//pic = draw_UseSkinFor(pic);
	width = eX * theSize_x;
	height = eY * theSize_y;
	if(theSize_x <= theBorderSize_x * 2)
	{
		// not wide enough... draw just left and right then
		bW = eX * (0.25 * theSize_x / (theBorderSize_x * 2));
		if(theSize_y <= theBorderSize_y * 2)
		{
			// not high enough... draw just corners
			bH = eY * (0.25 * theSize_y / (theBorderSize_y * 2));
			drawsubpic(theOrigin,                 width * 0.5 + height * 0.5, pic, '0 0 0',           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width   * 0.5, width * 0.5 + height * 0.5, pic, eX - bW,           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + height  * 0.5, width * 0.5 + height * 0.5, pic, eY - bH,           bW + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + theSize * 0.5, width * 0.5 + height * 0.5, pic, eX + eY - bW - bH, bW + bH, theColor, theAlpha, 0);
		}
		else
		{
			dY = theBorderSize_x * eY;
			drawsubpic(theOrigin,                             width * 0.5          +     dY, pic, '0 0    0',           '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5,               width * 0.5          +     dY, pic, '0 0    0' + eX - bW, '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin                        + dY, width * 0.5 + height - 2 * dY, pic, '0 0.25 0',           '0 0.5  0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5          + dY, width * 0.5 + height - 2 * dY, pic, '0 0.25 0' + eX - bW, '0 0.5  0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin               + height - dY, width * 0.5          +     dY, pic, '0 0.75 0',           '0 0.25 0' + bW, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width * 0.5 + height - dY, width * 0.5          +     dY, pic, '0 0.75 0' + eX - bW, '0 0.25 0' + bW, theColor, theAlpha, 0);
		}
	}
	else
	{
		if(theSize_y <= theBorderSize_y * 2)
		{
			// not high enough... draw just top and bottom then
			bH = eY * (0.25 * theSize_y / (theBorderSize_y * 2));
			dX = theBorderSize_x * eX;
			drawsubpic(theOrigin,                                         dX + height * 0.5, pic, '0    0 0',           '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + dX,                        width - 2 * dX + height * 0.5, pic, '0.25 0 0',           '0.5  0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width - dX,                            dX + height * 0.5, pic, '0.75 0 0',           '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin              + height * 0.5,             dX + height * 0.5, pic, '0    0 0' + eY - bH, '0.25 0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + dX         + height * 0.5, width - 2 * dX + height * 0.5, pic, '0.25 0 0' + eY - bH, '0.5  0 0' + bH, theColor, theAlpha, 0);
			drawsubpic(theOrigin + width - dX + height * 0.5,             dX + height * 0.5, pic, '0.75 0 0' + eY - bH, '0.25 0 0' + bH, theColor, theAlpha, 0);
		}
		else
		{
			dX = theBorderSize_x * eX;
			dY = theBorderSize_x * eY;
			drawsubpic(theOrigin,                                        dX          +     dY, pic, '0    0    0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin                  + dX,      width - 2 * dX          +     dY, pic, '0.25 0    0', '0.5  0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + width - dX,                  dX          +     dY, pic, '0.75 0    0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY,                          dX + height - 2 * dY, pic, '0    0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY         + dX, width - 2 * dX + height - 2 * dY, pic, '0.25 0.25 0', '0.5  0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin          + dY + width - dX,             dX + height - 2 * dY, pic, '0.75 0.25 0', '0.25 0.5  0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY,                          dX          +     dY, pic, '0    0.75 0', '0.25 0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY         + dX, width - 2 * dX          +     dY, pic, '0.25 0.75 0', '0.5  0.25 0', theColor, theAlpha, 0);
			drawsubpic(theOrigin + height - dY + width - dX,             dX          +     dY, pic, '0.75 0.75 0', '0.25 0.25 0', theColor, theAlpha, 0);
		}
	}
}

vector HUD_Get_Num_Color (float x, float maxvalue)
{
	vector color;
	if(x > maxvalue) {
		color_x = 0;
		color_y = 1;
		color_z = 0;
	}
	else if(x > maxvalue * 0.75) {
		color_x = 0.4 - (x-150)*0.02 * 0.4; //red value between 0.4 -> 0
		color_y = 0.9 + (x-150)*0.02 * 0.1; // green value between 0.9 -> 1
		color_z = 0;
	}
	else if(x > maxvalue * 0.5) {
		color_x = 1 - (x-100)*0.02 * 0.6; //red value between 1 -> 0.4
		color_y = 1 - (x-100)*0.02 * 0.1; // green value between 1 -> 0.9
		color_z = 1 - (x-100)*0.02; // blue value between 1 -> 0
	}
	else if(x > maxvalue * 0.25) {
		color_x = 1;
		color_y = 1;
		color_z = 0.2 + (x-50)*0.02 * 0.8; // blue value between 0.2 -> 1
	}
	else if(x > maxvalue * 0.1) {
		color_x = 1;
		color_y = (x-20)*90/27/100; // green value between 0 -> 1
		color_z = (x-20)*90/27/100 * 0.2; // blue value between 0 -> 0.2
	}
	else {
		color_x = 1;
		color_y = 0;
		color_z = 0;
	}
	return color;
}

float stringwidth_colors(string s, vector theSize)
{
	return stringwidth(s, TRUE, theSize);
}

float stringwidth_nocolors(string s, vector theSize)
{
	return stringwidth(s, FALSE, theSize);
}

#define CENTERPRINT_MAX_LINES 30
string centerprint_messages[CENTERPRINT_MAX_LINES];
float centerprint_width[CENTERPRINT_MAX_LINES];
float centerprint_time;
float centerprint_expire;
float centerprint_num;
float centerprint_offset_hint;
vector centerprint_fontsize;

void centerprint(string strMessage)
{
	float i, j, n, hcount;
	string s;

	centerprint_fontsize = HUD_GetFontsize("scr_centersize");

	centerprint_expire = min(centerprint_expire, time); // if any of the returns happens, this message will fade out

	if(autocvar_scr_centertime <= 0)
		return;

	if(strMessage == "")
		return;

	// strip trailing newlines
	j = strlen(strMessage) - 1;
	while(substring(strMessage, j, 1) == "\n" && j >= 0)
		j = j - 1;
	strMessage = substring(strMessage, 0, j + 1);

	if(strMessage == "")
		return;

	// strip leading newlines and remember them, they are a hint that the message should be lower on the screen
	j = 0;
	while(substring(strMessage, j, 1) == "\n" && j < strlen(strMessage))
		j = j + 1;
	strMessage = substring(strMessage, j, strlen(strMessage) - j);
	centerprint_offset_hint = j;

	if(strMessage == "")
		return;

	// if we get here, we have a message. Initialize its height.
	centerprint_num = 0;

	n = tokenizebyseparator(strMessage, "\n");
	i = hcount = 0;
	for(j = 0; j < n; ++j)
	{
		getWrappedLine_remaining = argv(j);
		while(getWrappedLine_remaining)
		{
			s = getWrappedLine(vid_conwidth * 0.75, centerprint_fontsize, stringwidth_colors);
			if(centerprint_messages[i] != s) // don't fade the same message in, looks stupid
				centerprint_time = time;
			if(centerprint_messages[i])
				strunzone(centerprint_messages[i]);
			centerprint_messages[i] = strzone(s);
			centerprint_width[i] = stringwidth(s, TRUE, centerprint_fontsize);
			++i;

			// half height for empty lines looks better
			if(s == "")
				hcount += 0.5;
			else
				hcount += 1;

			if(i >= CENTERPRINT_MAX_LINES)
				break;
		}
	}

	float h, havail;
	h = centerprint_fontsize_y*hcount;

	havail = vid_conheight;
	if(autocvar_con_chatpos < 0)
		havail -= (-autocvar_con_chatpos + autocvar_con_chat) * autocvar_con_chatsize; // avoid overlapping chat
	if(havail > vid_conheight - 70)
		havail = vid_conheight - 70; // avoid overlapping HUD

#if 0
	float forbiddenmin, forbiddenmax, allowedmin, allowedmax, preferred;

	// here, the centerprint would cover the crosshair. REALLY BAD.
	forbiddenmin = vid_conheight * 0.5 - h - 16;
	forbiddenmax = vid_conheight * 0.5 + 16;

	allowedmin = scoreboard_bottom;
	allowedmax = havail - h;
	preferred = (havail - h)/2;


	// possible orderings (total: 4! / 4 = 6)
	//  allowedmin allowedmax forbiddenmin forbiddenmax
	//  forbiddenmin forbiddenmax allowedmin allowedmax
	if(allowedmax < forbiddenmin || allowedmin > forbiddenmax)
	{
		// forbidden doesn't matter in this case
		centerprint_start_y = bound(allowedmin, preferred, allowedmax);
	}
	//  allowedmin forbiddenmin allowedmax forbiddenmax
	else if(allowedmin < forbiddenmin && allowedmax < forbiddenmax)
	{
		centerprint_start_y = bound(allowedmin, preferred, forbiddenmin);
	}
	//  allowedmin forbiddenmin forbiddenmax allowedmax
	else if(allowedmin < forbiddenmin)
	{
		// make sure the forbidden zone is not covered
		if(preferred > (forbiddenmin + forbiddenmax) * 0.5)
			centerprint_start_y = bound(allowedmin, preferred, forbiddenmin);
		else
			centerprint_start_y = bound(forbiddenmax, preferred, allowedmin);
	}
	//  forbiddenmin allowedmin allowedmax forbiddenmax
	else if(allowedmax < forbiddenmax)
	{
		// it's better to leave the allowed zone (overlap with scoreboard) than
		// to cover the forbidden zone (crosshair)
		if(preferred > (forbiddenmin + forbiddenmax) * 0.5)
			centerprint_start_y = forbiddenmax;
		else
			centerprint_start_y = forbiddenmin;
	}
	//  forbiddenmin allowedmin forbiddenmax allowedmax
	else
	{
		centerprint_start_y = bound(forbiddenmax, preferred, allowedmax);
	}
#else
#endif

	centerprint_num = i;

	centerprint_expire = time + autocvar_scr_centertime;
}

void HUD_DrawCenterPrint (void)
{
	float i;
	vector pos;
	string ts;
	float a, sz;

	if(time - centerprint_time < 0.25)
		a = (time - centerprint_time) / 0.25;
	else
		a = bound(0, 1 - 4 * (time - centerprint_expire), 1);

	if(a <= 0)
		return;

	sz = 0.8 + (a / 5);

	if(centerprint_num * autocvar_scr_centersize > 24 && scoreboard_active) // 24 = height of Scoreboard text
		centerprint_start_y = scoreboard_bottom + centerprint_fontsize_y;

	pos = centerprint_start;
	for (i=0; i<centerprint_num; i = i + 1)
	{
		ts = centerprint_messages[i];
		drawfontscale = sz * '1 1 0';
		drawfont = hud_bigfont;
		pos_x = (vid_conwidth - stringwidth(ts, TRUE, centerprint_fontsize)) * 0.5;
		if (ts != "")
		{
			drawcolorcodedstring(pos + '0 1 0' * (1 - sz) * 0.5 *centerprint_fontsize_y, ts, centerprint_fontsize, a, DRAWFLAG_NORMAL);
			pos_y = pos_y + centerprint_fontsize_y;
		}
		else
			// half height for empty lines looks better
			pos_y = pos_y + sz * centerprint_fontsize_y * 0.5;
		drawfontscale = '1 1 0';
		drawfont = hud_font;
	}
}

void drawstringright(vector position, string text, vector scale, vector rgb, float alpha, float flag)
{
	position_x -= 2 / 3 * strlen(text) * scale_x;
	drawstring(position, text, scale, rgb, alpha, flag);
}

void drawstringcenter(vector position, string text, vector scale, vector rgb, float alpha, float flag)
{
	position_x = 0.5 * (vid_conwidth - 0.6025 * strlen(text) * scale_x);
	drawstring(position, text, scale, rgb, alpha, flag);
}

// return the string of the given race place
string race_PlaceName(float pos) {
	if(pos == 1)
		return "1st";
	else if(pos == 2)
		return "2nd";
	else if(pos == 3)
		return "3rd";
	else
		return strcat(ftos(pos), "th");
}

// return the string of the onscreen race timer
string MakeRaceString(float cp, float mytime, float histime, float lapdelta, string hisname)
{
	string col;
	string timestr;
	string cpname;
	string lapstr;
	lapstr = "";

	if(histime == 0) // goal hit
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
			lapstr = strcat(" (-", ftos(lapdelta), "L)");
			col = "^2";
		}
		else if(lapdelta < 0)
		{
			lapstr = strcat(" (+", ftos(-lapdelta), "L)");
			col = "^1";
		}
	}
	else if(histime > 0) // anticipation
	{
		if(mytime >= histime)
			timestr = strcat("+", ftos_decimals(mytime - histime, TIME_DECIMALS));
		else
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(histime));
		col = "^3";
	}
	else
		col = "^7";

	if(cp == 254)
		cpname = "Start line";
	else if(cp == 255)
		cpname = "Finish line";
	else if(cp)
		cpname = strcat("Intermediate ", ftos(cp));
	else
		cpname = "Finish line";

	if(histime < 0)
		return strcat(col, cpname);
	else if(hisname == "")
		return strcat(col, cpname, " (", timestr, ")");
	else
		return strcat(col, cpname, " (", timestr, " ", strcat(hisname, col, lapstr), ")");
}

// Check if the given name already exist in race rankings? In that case, where? (otherwise return 0)
float race_CheckName(string net_name) {
	float i;
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

#define HUD_Write(s) fputs(fh, s)
// q: quoted, n: not quoted
#define HUD_Write_Cvar_n(cvar) HUD_Write(strcat("seta ", cvar, " ", cvar_string(cvar), "\n"))
#define HUD_Write_Cvar_q(cvar) HUD_Write(strcat("seta ", cvar, " \"", cvar_string(cvar), "\"\n"))
#define HUD_Write_PanelCvar_n(cvar_suf) HUD_Write_Cvar_n(strcat("hud_panel_", panel_name, cvar_suf))
#define HUD_Write_PanelCvar_q(cvar_suf) HUD_Write_Cvar_q(strcat("hud_panel_", panel_name, cvar_suf))
// Save the config
void HUD_Panel_ExportCfg(string cfgname)
{
	float fh;
	string filename = strcat("hud_", autocvar_hud_skin, "_", cfgname, ".cfg");
	fh = fopen(filename, FILE_WRITE);
	if(fh >= 0)
	{
		HUD_Write_Cvar_q("hud_skin");
		HUD_Write_Cvar_q("hud_panel_bg");
		HUD_Write_Cvar_q("hud_panel_bg_color");
		HUD_Write_Cvar_q("hud_panel_bg_color_team");
		HUD_Write_Cvar_q("hud_panel_bg_alpha");
		HUD_Write_Cvar_q("hud_panel_bg_border");
		HUD_Write_Cvar_q("hud_panel_bg_padding");
		HUD_Write_Cvar_q("hud_panel_fg_alpha");
		HUD_Write("\n");

		HUD_Write_Cvar_q("hud_dock");
		HUD_Write_Cvar_q("hud_dock_color");
		HUD_Write_Cvar_q("hud_dock_color_team");
		HUD_Write_Cvar_q("hud_dock_alpha");
		HUD_Write("\n");

		HUD_Write_Cvar_q("hud_progressbar_alpha");
		HUD_Write_Cvar_q("hud_progressbar_strength_color");
		HUD_Write_Cvar_q("hud_progressbar_shield_color");
		HUD_Write_Cvar_q("hud_progressbar_health_color");
		HUD_Write_Cvar_q("hud_progressbar_armor_color");
		HUD_Write_Cvar_q("hud_progressbar_fuel_color");
		HUD_Write_Cvar_q("hud_progressbar_nexball_color");
		HUD_Write("\n");

		HUD_Write_Cvar_q("_hud_panelorder");
		HUD_Write("\n");

		HUD_Write_Cvar_q("hud_configure_grid");
		HUD_Write_Cvar_q("hud_configure_grid_xsize");
		HUD_Write_Cvar_q("hud_configure_grid_ysize");
		HUD_Write("\n");

		HUD_Write_Cvar_q("scr_centerpos");
		HUD_Write("\n");

		// common cvars for all panels
		float i;
		for (i = 0; i < HUD_PANEL_NUM; ++i)
		{
			HUD_Panel_GetName(i);

			HUD_Write_PanelCvar_n("");
			HUD_Write_PanelCvar_q("_pos");
			HUD_Write_PanelCvar_q("_size");
			HUD_Write_PanelCvar_q("_bg");
			HUD_Write_PanelCvar_q("_bg_color");
			HUD_Write_PanelCvar_q("_bg_color_team");
			HUD_Write_PanelCvar_q("_bg_alpha");
			HUD_Write_PanelCvar_q("_bg_border");
			HUD_Write_PanelCvar_q("_bg_padding");
			switch(i) {
				case HUD_PANEL_WEAPONS:
					HUD_Write_PanelCvar_q("_complainbubble");
					HUD_Write_PanelCvar_q("_complainbubble_padding");
					HUD_Write_PanelCvar_q("_complainbubble_color_outofammo");
					HUD_Write_PanelCvar_q("_complainbubble_color_donthave");
					HUD_Write_PanelCvar_q("_complainbubble_color_unavailable");
					HUD_Write_PanelCvar_q("_ammo_color");
					HUD_Write_PanelCvar_q("_ammo_alpha");
					HUD_Write_PanelCvar_q("_aspect");
					break;
				case HUD_PANEL_AMMO:
					HUD_Write_PanelCvar_q("_onlycurrent");
					HUD_Write_PanelCvar_q("_iconalign");
					HUD_Write_PanelCvar_q("_progressbar");
					HUD_Write_PanelCvar_q("_progressbar_name");
					HUD_Write_PanelCvar_q("_text");
					break;
				case HUD_PANEL_POWERUPS:
					HUD_Write_PanelCvar_q("_flip");
					HUD_Write_PanelCvar_q("_iconalign");
					HUD_Write_PanelCvar_q("_baralign");
					HUD_Write_PanelCvar_q("_progressbar");
					HUD_Write_PanelCvar_q("_progressbar_strength");
					HUD_Write_PanelCvar_q("_progressbar_shield");
					break;
				case HUD_PANEL_HEALTHARMOR:
					HUD_Write_PanelCvar_q("_flip");
					HUD_Write_PanelCvar_q("_iconalign");
					HUD_Write_PanelCvar_q("_baralign");
					HUD_Write_PanelCvar_q("_progressbar");
					HUD_Write_PanelCvar_q("_progressbar_health");
					HUD_Write_PanelCvar_q("_progressbar_armor");
					HUD_Write_PanelCvar_q("_text");
					break;
				case HUD_PANEL_NOTIFY:
					HUD_Write_PanelCvar_q("_flip");
					HUD_Write_PanelCvar_q("_print");
					break;
				case HUD_PANEL_RADAR:
					HUD_Write_PanelCvar_q("_foreground_alpha");
					break;
				case HUD_PANEL_VOTE:
					HUD_Write_PanelCvar_q("_alreadyvoted_alpha");
					break;
				case HUD_PANEL_PRESSEDKEYS:
					HUD_Write_PanelCvar_q("_aspect");
					break;
				case HUD_PANEL_INFOMESSAGES:
					HUD_Write_PanelCvar_q("_flip");
					break;
			}
			HUD_Write("\n");
		}
		HUD_Write("menu_sync\n"); // force the menu to reread the cvars, so that the dialogs are updated

		print("^2Successfully exported to ", filename, "! (Note: It's saved in data/data/)\n");
		fclose(fh);
	}
	else
		print("^1Couldn't write to ", filename, "\n");
}

const float hlBorderSize = 4;
const string hlBorder = "gfx/hud/default/border_highlighted";
const string hlBorder2 = "gfx/hud/default/border_highlighted2";
void HUD_Panel_HlBorder(float myBorder, vector color, float alpha)
{
	drawfill(panel_pos - '1 1 0' * myBorder, panel_size + '2 2 0' * myBorder, '0 0.5 1', .5 * alpha, DRAWFLAG_NORMAL);
	drawpic_tiled(panel_pos - '1 1 0' * myBorder, hlBorder, '8 1 0' * hlBorderSize, eX * (panel_size_x + 2 * myBorder) + eY * hlBorderSize, color, alpha, DRAWFLAG_NORMAL);
	drawpic_tiled(panel_pos - '1 1 0' * myBorder + eY * (panel_size_y + 2 * myBorder - hlBorderSize), hlBorder, '8 1 0' * hlBorderSize, eX * (panel_size_x + 2 * myBorder) + eY * hlBorderSize, color, alpha, DRAWFLAG_NORMAL);
	drawpic_tiled(panel_pos - '1 1 0' * myBorder + eY * hlBorderSize, hlBorder2, '1 8 0' * hlBorderSize, eY * (panel_size_y + 2 * myBorder - 2 * hlBorderSize) + eX * hlBorderSize, color, alpha, DRAWFLAG_NORMAL);
	drawpic_tiled(panel_pos - '1 1 0' * myBorder + eY * hlBorderSize + eX * (panel_size_x + 2 * myBorder - hlBorderSize), hlBorder2, '1 8 0' * hlBorderSize, eY * (panel_size_y + 2 * myBorder - 2 * hlBorderSize) + eX * hlBorderSize, color, alpha, DRAWFLAG_NORMAL);
}

// draw the background/borders
#define HUD_Panel_DrawBg(alpha)\
if(panel_bg != "0")\
	draw_BorderPicture(panel_pos - '1 1 0' * panel_bg_border, panel_bg, panel_size + '1 1 0' * 2 * panel_bg_border, panel_bg_color, panel_bg_alpha * alpha, '1 1 0' * (panel_bg_border/BORDER_MULTIPLIER));\
if(highlightedPanel_prev == active_panel && autocvar__hud_configure)\
{\
	HUD_Panel_HlBorder(panel_bg_border + 1.5 * hlBorderSize, '0 0.5 1', 0.25 * (1 - autocvar__menu_alpha) * alpha);\
} ENDS_WITH_CURLY_BRACE

void HUD_Panel_DrawProgressBar(vector pos, vector mySize, string pic, float vertical, float barflip, float x, vector color, float alpha, float drawflag)
{
	if(!alpha || x == 0)
		return;

    x = bound(0, x, 1);

	if(vertical) {
		pic = strcat(hud_skin_path, "/", pic, "_vertical");
		if(precache_pic(pic) == "") {
			pic = "gfx/hud/default/statusbar_vertical";
		}

        if(barflip)
            drawsetcliparea(pos_x, pos_y + mySize_y * (1 - x), mySize_x, mySize_y * x);
        else
            drawsetcliparea(pos_x, pos_y, mySize_x, mySize_y * x);
	} else {
		pic = strcat(hud_skin_path, "/", pic);
		if(precache_pic(pic) == "") {
			pic = "gfx/hud/default/statusbar";
		}

        if(barflip)
            drawsetcliparea(pos_x + mySize_x * (1 - x), pos_y, mySize_x * x, mySize_y);
        else
            drawsetcliparea(pos_x, pos_y, mySize_x * x, mySize_y);
	}

    drawpic(pos, pic, mySize, color, alpha, drawflag);
    drawresetcliparea();
}

void HUD_Panel_DrawHighlight(vector pos, vector mySize, vector color, float alpha, float drawflag)
{
	if(!alpha)
		return;

	string pic;
	pic = strcat(hud_skin_path, "/num_leading");
	if(precache_pic(pic) == "") {
		pic = "gfx/hud/default/num_leading";
	}

	drawsubpic(pos, eX * min(mySize_x * 0.5, mySize_y) + eY * mySize_y, pic, '0 0 0', '0.25 1 0', color, alpha, drawflag);
	if(mySize_x/mySize_y > 2)
		drawsubpic(pos + eX * mySize_y, eX * (mySize_x - 2 * mySize_y) + eY * mySize_y, pic, '0.25 0 0', '0.5 1 0', color, alpha, drawflag);
	drawsubpic(pos + eX * mySize_x - eX * min(mySize_x * 0.5, mySize_y), eX * min(mySize_x * 0.5, mySize_y) + eY * mySize_y, pic, '0.75 0 0', '0.25 1 0', color, alpha, drawflag);
}

// check if move will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckMove(vector myPos, vector mySize)
{
	float i;

	vector myTarget;
	myTarget = myPos;

	vector myCenter;
	vector targCenter;
	myCenter = '0 0 0'; // shut up fteqcc, there IS a reference
	targCenter = '0 0 0'; // shut up fteqcc, there IS a reference

	for (i = 0; i < HUD_PANEL_NUM; ++i) {
		if(i == highlightedPanel || !panel_enabled)
			continue;

		HUD_Panel_UpdatePosSizeForId(i);

		panel_pos -= '1 1 0' * panel_bg_border;
		panel_size += '2 2 0' * panel_bg_border;

		if(myPos_y + mySize_y < panel_pos_y)
			continue;
		if(myPos_y > panel_pos_y + panel_size_y)
			continue;

		if(myPos_x + mySize_x < panel_pos_x)
			continue;
		if(myPos_x > panel_pos_x + panel_size_x)
			continue;

		// OK, there IS a collision.

		myCenter_x = myPos_x + 0.5 * mySize_x;
		myCenter_y = myPos_y + 0.5 * mySize_y;

		targCenter_x = panel_pos_x + 0.5 * panel_size_x;
		targCenter_y = panel_pos_y + 0.5 * panel_size_y;

		if(myCenter_x < targCenter_x && myCenter_y < targCenter_y) // top left (of the target panel)
		{
			if(myPos_x + mySize_x - panel_pos_x < myPos_y + mySize_y - panel_pos_y) // push it to the side
				myTarget_x = panel_pos_x - mySize_x;
			else // push it upwards
				myTarget_y = panel_pos_y - mySize_y;
		}
		else if(myCenter_x > targCenter_x && myCenter_y < targCenter_y) // top right
		{
			if(panel_pos_x + panel_size_x - myPos_x < myPos_y + mySize_y - panel_pos_y) // push it to the side
				myTarget_x = panel_pos_x + panel_size_x;
			else // push it upwards
				myTarget_y = panel_pos_y - mySize_y;
		}
		else if(myCenter_x < targCenter_x && myCenter_y > targCenter_y) // bottom left
		{
			if(myPos_x + mySize_x - panel_pos_x < panel_pos_y + panel_size_y - myPos_y) // push it to the side
				myTarget_x = panel_pos_x - mySize_x;
			else // push it downwards
				myTarget_y = panel_pos_y + panel_size_y;
		}
		else if(myCenter_x > targCenter_x && myCenter_y > targCenter_y) // bottom right
		{
			if(panel_pos_x + panel_size_x - myPos_x < panel_pos_y + panel_size_y - myPos_y) // push it to the side
				myTarget_x = panel_pos_x + panel_size_x;
			else // push it downwards
				myTarget_y = panel_pos_y + panel_size_y;
		}
		//if(cvar("hud_configure_checkcollisions_debug"))
			//drawfill(panel_pos, panel_size, '1 1 0', .3, DRAWFLAG_NORMAL);
	}

	return myTarget;
}

void HUD_Panel_SetPos(vector pos)
{
	HUD_Panel_UpdatePosSizeForId(highlightedPanel);
	vector mySize;
	mySize = panel_size;

	//if(cvar("hud_configure_checkcollisions_debug"))
		//drawfill(pos, mySize, '1 1 1', .2, DRAWFLAG_NORMAL);

	if(autocvar_hud_configure_grid)
	{
		pos_x = floor((pos_x/vid_conwidth)/bound(0.005, autocvar_hud_configure_grid_xsize, 0.2) + 0.5) * bound(0.005, autocvar_hud_configure_grid_xsize, 0.2) * vid_conwidth;
		pos_y = floor((pos_y/vid_conheight)/bound(0.005, autocvar_hud_configure_grid_ysize, 0.2) + 0.5) * bound(0.005, autocvar_hud_configure_grid_ysize, 0.2) * vid_conheight;
	}

	if(hud_configure_checkcollisions)
		pos = HUD_Panel_CheckMove(pos, mySize);

	pos_x = bound(0, pos_x, vid_conwidth - mySize_x);
	pos_y = bound(0, pos_y, vid_conheight - mySize_y);

	string s;
	s = strcat(ftos(pos_x/vid_conwidth), " ", ftos(pos_y/vid_conheight));

	HUD_Panel_GetName(highlightedPanel);
	cvar_set(strcat("hud_panel_", panel_name, "_pos"), s);
}

// check if resize will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckResize(vector mySize, vector resizeorigin) {
	float i;

	vector targEndPos;

	float dist_x, dist_y;
	float ratio;
	ratio = mySize_x/mySize_y;

	for (i = 0; i < HUD_PANEL_NUM; ++i) {
		if(i == highlightedPanel || !panel_enabled)
			continue;

		HUD_Panel_UpdatePosSizeForId(i);

		panel_pos -= '1 1 0' * panel_bg_border;
		panel_size += '2 2 0' * panel_bg_border;

		targEndPos = panel_pos + panel_size;

		// resizeorigin is WITHIN target panel, just abort any collision testing against that particular panel to produce expected behaviour!
		if(resizeorigin_x > panel_pos_x && resizeorigin_x < targEndPos_x && resizeorigin_y > panel_pos_y && resizeorigin_y < targEndPos_y)
			continue;

		if (resizeCorner == 1)
		{
			// check if this panel is on our way
			if (resizeorigin_x <= panel_pos_x)
				continue;
			if (resizeorigin_y <= panel_pos_y)
				continue;
			if (targEndPos_x <= resizeorigin_x - mySize_x)
				continue;
			if (targEndPos_y <= resizeorigin_y - mySize_y)
				continue;

			// there is a collision:
			// detect which side of the panel we are facing is actually limiting the resizing
			// (which side the resize direction finds for first) and reduce the size up to there
			//
			// dist is the distance between resizeorigin and the "analogous" point of the panel
			// in this case resizeorigin (bottom-right point) and the bottom-right point of the panel
			dist_x = resizeorigin_x - targEndPos_x;
			dist_y = resizeorigin_y - targEndPos_y;
			if (dist_y <= 0 || dist_x / dist_y > ratio)
				mySize_x = min(mySize_x, dist_x);
			else
				mySize_y = min(mySize_y, dist_y);
		}
		else if (resizeCorner == 2)
		{
			if (resizeorigin_x >= targEndPos_x)
				continue;
			if (resizeorigin_y <= panel_pos_y)
				continue;
			if (panel_pos_x >= resizeorigin_x + mySize_x)
				continue;
			if (targEndPos_y <= resizeorigin_y - mySize_y)
				continue;

			dist_x = panel_pos_x - resizeorigin_x;
			dist_y = resizeorigin_y - targEndPos_y;
			if (dist_y <= 0 || dist_x / dist_y > ratio)
				mySize_x = min(mySize_x, dist_x);
			else
				mySize_y = min(mySize_y, dist_y);
		}
		else if (resizeCorner == 3)
		{
			if (resizeorigin_x <= panel_pos_x)
				continue;
			if (resizeorigin_y >= targEndPos_y)
				continue;
			if (targEndPos_x <= resizeorigin_x - mySize_x)
				continue;
			if (panel_pos_y >= resizeorigin_y + mySize_y)
				continue;

			dist_x = resizeorigin_x - targEndPos_x;
			dist_y = panel_pos_y - resizeorigin_y;
			if (dist_y <= 0 || dist_x / dist_y > ratio)
				mySize_x = min(mySize_x, dist_x);
			else
				mySize_y = min(mySize_y, dist_y);
		}
		else if (resizeCorner == 4)
		{
			if (resizeorigin_x >= targEndPos_x)
				continue;
			if (resizeorigin_y >= targEndPos_y)
				continue;
			if (panel_pos_x >= resizeorigin_x + mySize_x)
				continue;
			if (panel_pos_y >= resizeorigin_y + mySize_y)
				continue;

			dist_x = panel_pos_x - resizeorigin_x;
			dist_y = panel_pos_y - resizeorigin_y;
			if (dist_y <= 0 || dist_x / dist_y > ratio)
				mySize_x = min(mySize_x, dist_x);
			else
				mySize_y = min(mySize_y, dist_y);
		}
		//if(cvar("hud_configure_checkcollisions_debug"))
			//drawfill(panel_pos, panel_size, '1 1 0', .3, DRAWFLAG_NORMAL);
	}

	return mySize;
}

void HUD_Panel_SetPosSize(vector mySize)
{
	HUD_Panel_UpdatePosSizeForId(highlightedPanel);
	vector resizeorigin;
	resizeorigin = panel_click_resizeorigin;
	vector myPos;

	// minimum panel size cap
	mySize_x = max(0.025 * vid_conwidth, mySize_x);
	mySize_y = max(0.025 * vid_conheight, mySize_y);

	if(highlightedPanel == HUD_PANEL_CHAT) // some panels have their own restrictions, like the chat panel (which actually only moves the engine chat print around). Looks bad if it's too small.
	{
		mySize_x = max(17 * autocvar_con_chatsize, mySize_x);
		mySize_y = max(2 * autocvar_con_chatsize + 2 * panel_bg_padding, mySize_y);
	}

	// collision testing|
	// -----------------+

	// we need to know pos at this stage, but it might still change later if we hit a screen edge/other panel (?)
	if(resizeCorner == 1) {
		myPos_x = resizeorigin_x - mySize_x;
		myPos_y = resizeorigin_y - mySize_y;
	} else if(resizeCorner == 2) {
		myPos_x = resizeorigin_x;
		myPos_y = resizeorigin_y - mySize_y;
	} else if(resizeCorner == 3) {
		myPos_x = resizeorigin_x - mySize_x;
		myPos_y = resizeorigin_y;
	} else { // resizeCorner == 4
		myPos_x = resizeorigin_x;
		myPos_y = resizeorigin_y;
	}

	// left/top screen edges
	if(myPos_x < 0)
		mySize_x = mySize_x + myPos_x;
	if(myPos_y < 0)
		mySize_y = mySize_y + myPos_y;

	// bottom/right screen edges
	if(myPos_x + mySize_x > vid_conwidth)
		mySize_x = vid_conwidth - myPos_x;
	if(myPos_y + mySize_y > vid_conheight)
		mySize_y = vid_conheight - myPos_y;

	//if(cvar("hud_configure_checkcollisions_debug"))
		//drawfill(myPos, mySize, '1 1 1', .2, DRAWFLAG_NORMAL);

	// before checkresize, otherwise panel can be snapped partially inside another panel or panel aspect ratio can be broken
	if(autocvar_hud_configure_grid)
	{
		mySize_x = floor((mySize_x/vid_conwidth)/bound(0.005, autocvar_hud_configure_grid_xsize, 0.2) + 0.5) * bound(0.005, autocvar_hud_configure_grid_xsize, 0.2) * vid_conwidth;
		mySize_y = floor((mySize_y/vid_conheight)/bound(0.005, autocvar_hud_configure_grid_ysize, 0.2) + 0.5) * bound(0.005, autocvar_hud_configure_grid_ysize, 0.2) * vid_conheight;
	}

	if(hud_configure_checkcollisions)
		mySize = HUD_Panel_CheckResize(mySize, resizeorigin);

	// minimum panel size cap, do this once more so we NEVER EVER EVER have a panel smaller than this, JUST IN CASE above code still makes the panel eg negative (impossible to resize back without changing cvars manually then)
	mySize_x = max(0.025 * vid_conwidth, mySize_x);
	mySize_y = max(0.025 * vid_conheight, mySize_y);

	// do another pos check, as size might have changed by now
	if(resizeCorner == 1) {
		myPos_x = resizeorigin_x - mySize_x;
		myPos_y = resizeorigin_y - mySize_y;
	} else if(resizeCorner == 2) {
		myPos_x = resizeorigin_x;
		myPos_y = resizeorigin_y - mySize_y;
	} else if(resizeCorner == 3) {
		myPos_x = resizeorigin_x - mySize_x;
		myPos_y = resizeorigin_y;
	} else { // resizeCorner == 4
		myPos_x = resizeorigin_x;
		myPos_y = resizeorigin_y;
	}

	//if(cvar("hud_configure_checkcollisions_debug"))
		//drawfill(myPos, mySize, '0 1 0', .3, DRAWFLAG_NORMAL);

	HUD_Panel_GetName(highlightedPanel);
	string s;
	s = strcat(ftos(mySize_x/vid_conwidth), " ", ftos(mySize_y/vid_conheight));
	cvar_set(strcat("hud_panel_", panel_name, "_size"), s);

	s = strcat(ftos(myPos_x/vid_conwidth), " ", ftos(myPos_y/vid_conheight));
	cvar_set(strcat("hud_panel_", panel_name, "_pos"), s);
}

float mouseClicked;
float prevMouseClicked; // previous state
float prevMouseClickedTime; // time during previous mouse click, to check for doubleclicks
vector prevMouseClickedPos; // pos during previous mouse click, to check for doubleclicks

float pressed_key_time;
void HUD_Panel_Arrow_Action(float nPrimary)
{
	if (highlightedPanel_prev == -1 || mouseClicked)
		return;

	hud_configure_checkcollisions = (!(hudShiftState & S_CTRL) && autocvar_hud_configure_checkcollisions);

	float step;
	if(autocvar_hud_configure_grid)
	{
		if (nPrimary == K_UPARROW || nPrimary == K_DOWNARROW)
		{
			if (hudShiftState & S_SHIFT)
				step = bound(0.005, autocvar_hud_configure_grid_ysize, 0.2) * vid_conheight;
			else
				step = 2 * bound(0.005, autocvar_hud_configure_grid_ysize, 0.2) * vid_conheight;
		}
		else
		{
			if (hudShiftState & S_SHIFT)
				step = bound(0.005, autocvar_hud_configure_grid_xsize, 0.2) * vid_conwidth;
			else
				step = 2 * bound(0.005, autocvar_hud_configure_grid_xsize, 0.2) * vid_conwidth;
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

	highlightedPanel = highlightedPanel_prev;

	HUD_Panel_UpdatePosSizeForId(highlightedPanel);

	vector prev_pos, prev_size;
	prev_pos = panel_pos;
	prev_size = panel_size;

	if (hudShiftState & S_ALT) // resize
	{
		highlightedAction = 1;
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
			mySize_y += step;
		} else if(resizeCorner == 2) {
			panel_click_resizeorigin_y += mySize_y;
			mySize_x += step;
		} else if(resizeCorner == 3) {
			panel_click_resizeorigin_x += mySize_x;
			mySize_x += step;
		} else { // resizeCorner == 4
			mySize_y += step;
		}
		HUD_Panel_SetPosSize(mySize);
	}
	else // move
	{
		highlightedAction = 2;
		vector pos;
		pos = panel_pos;
		if(nPrimary == K_UPARROW)
			pos_y -= step;
		else if(nPrimary == K_DOWNARROW)
			pos_y += step;
		else if(nPrimary == K_LEFTARROW)
			pos_x -= step;
		else // if(nPrimary == K_RIGHTARROW)
			pos_x += step;

		HUD_Panel_SetPos(pos);
	}

	HUD_Panel_UpdatePosSizeForId(highlightedPanel);

	if (prev_pos != panel_pos || prev_size != panel_size)
	{
		// backup!
		panel_pos_backup = prev_pos;
		panel_size_backup = prev_size;
		highlightedPanel_backup = highlightedPanel;
	}
}

float HUD_Panel_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	string s;

	if(!autocvar__hud_configure)
		return false;

	// allow console bind to work
	string con_keys;
	float keys;
	con_keys = findkeysforcommand("toggleconsole");
	keys = tokenize(con_keys);

	float hit_con_bind, i;
	for (i = 0; i < keys; ++i)
	{
		if(nPrimary == stof(argv(i)))
			hit_con_bind = 1;
	}

	if(bInputType == 0) {
		if(nPrimary == K_ALT) hudShiftState |= S_ALT;
		if(nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
	}
	else if(bInputType == 1) {
		if(nPrimary == K_ALT) hudShiftState -= (hudShiftState & S_ALT);
		if(nPrimary == K_CTRL) hudShiftState -= (hudShiftState & S_CTRL);
		if(nPrimary == K_SHIFT) hudShiftState -= (hudShiftState & S_SHIFT);
	}

	if(nPrimary == K_MOUSE1)
	{
		if(bInputType == 0) { // key pressed
			mouseClicked = 1;
			return true;
		}
		else if(bInputType == 1) {// key released
			mouseClicked = 0;
			return true;
		}
	}
	else if(nPrimary == K_ESCAPE)
	{
		if (bInputType == 1)
			return true;
		menu_enabled = 1;
		menu_enabled_time = time;
		localcmd("menu_showhudexit\n");
	}
	else if(hudShiftState & S_CTRL)
	{
		if (mouseClicked)
			return true;

		if(nPrimary == K_SPACE) // enable/disable highlighted panel or dock
		{
			if (bInputType == 1)
				return true;

			if (highlightedPanel_prev != -1)
				cvar_set(strcat("hud_panel_", panel_name), ftos(!(panel_enabled)));
			else
				cvar_set(strcat("hud_dock"), (autocvar_hud_dock == "") ? "dock" : "");
		}
		if(nPrimary == 'c') // copy highlighted panel size
		{
			if (bInputType == 1)
				return true;

			if (highlightedPanel_prev != -1)
			{
				panel_size_copied = panel_size;
				highlightedPanel_copied = highlightedPanel_prev;
			}
		}
		else if(nPrimary == 'v') // past copied size on the highlighted panel
		{
			if (bInputType == 1)
				return true;

			if (highlightedPanel_copied == -1 || highlightedPanel_prev == -1)
				return true;

			HUD_Panel_UpdatePosSizeForId(highlightedPanel_prev);

			// reduce size if it'd go beyond screen boundaries
			vector tmp_size = panel_size_copied;
			if (panel_pos_x + panel_size_copied_x > vid_conwidth)
				tmp_size_x = vid_conwidth - panel_pos_x;
			if (panel_pos_y + panel_size_copied_y > vid_conheight)
				tmp_size_y = vid_conheight - panel_pos_y;

			if (panel_size == tmp_size)
				return true;

			// backup first!
			panel_pos_backup = panel_pos;
			panel_size_backup = panel_size;
			highlightedPanel_backup = highlightedPanel_prev;

			s = strcat(ftos(tmp_size_x/vid_conwidth), " ", ftos(tmp_size_y/vid_conheight));
			cvar_set(strcat("hud_panel_", panel_name, "_size"), s);
		}
		else if(nPrimary == 'z') // undo last action
		{
			if (bInputType == 1)
				return true;
			//restore previous values
			if (highlightedPanel_backup != -1)
			{
				HUD_Panel_GetName(highlightedPanel_backup);
				s = strcat(ftos(panel_pos_backup_x/vid_conwidth), " ", ftos(panel_pos_backup_y/vid_conheight));
				cvar_set(strcat("hud_panel_", panel_name, "_pos"), s);
				s = strcat(ftos(panel_size_backup_x/vid_conwidth), " ", ftos(panel_size_backup_y/vid_conheight));
				cvar_set(strcat("hud_panel_", panel_name, "_size"), s);
				highlightedPanel_backup = -1;
			}
		}
	}
	else if(nPrimary == K_UPARROW || nPrimary == K_DOWNARROW || nPrimary == K_LEFTARROW || nPrimary == K_RIGHTARROW)
	{
		if (bInputType == 1)
		{
			pressed_key_time = 0;
			return true;
		}
		else if (pressed_key_time == 0)
			pressed_key_time = time;

		HUD_Panel_Arrow_Action(nPrimary); //move or resize panel
	}
	else if(hit_con_bind)
		return false;

	return true; // Suppress ALL other input
}

float HUD_Panel_HighlightCheck()
{
	float i, j, border;
	vector panelPos;
	vector panelSize;

	while(j <= HUD_PANEL_NUM)
	{
		i = panel_order[j];
		j += 1;

		HUD_Panel_UpdatePosSizeForId(i);

		panelPos = panel_pos;
		panelSize = panel_size;
		border = max(8, panel_bg_border); // FORCED border so a small border size doesn't mean you can't resize

		// move
		if(mousepos_x >= panelPos_x && mousepos_y >= panelPos_y && mousepos_x <= panelPos_x + panelSize_x && mousepos_y <= panelPos_y + panelSize_y)
		{
			return 1;
		}
		// resize from topleft border
		else if(mousepos_x >= panelPos_x - border && mousepos_y >= panelPos_y - border && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
		{
			return 2;
		}
		// resize from topright border
		else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y - border && mousepos_x <= panelPos_x + panelSize_x + border && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
		{
			return 3;
		}
		// resize from bottomleft border
		else if(mousepos_x >= panelPos_x - border && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + panelSize_y + border)
		{
			return 3;
		}
		// resize from bottomright border
		else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + panelSize_x + border && mousepos_y <= panelPos_y + panelSize_y + border)
		{
			return 2;
		}
	}
	return 0;
}

// move a panel to the beginning of the panel order array (which means it gets drawn last, on top of everything else)
void HUD_Panel_FirstInDrawQ(float id)
{
	float i;
	var float place = -1;
	// find out where in the array our current id is, save into place
	for(i = 0; i < HUD_PANEL_NUM; ++i)
	{
		if(panel_order[i] == id)
		{
			place = i;
			break;
		}
	}
	// place last if we didn't find a place for it yet (probably new panel, or screwed up cvar)
	if(place == -1)
		place = HUD_PANEL_NUM - 1;

	// move all ids up by one step in the array until "place"
	for(i = place; i > 0; --i)
	{
		panel_order[i] = panel_order[i-1];
	}
	// now save the new top id
	panel_order[0] = id;
	
	// let's save them into the cvar by some strcat trickery
	string s;
	for(i = 0; i < HUD_PANEL_NUM; ++i)
	{
		s = strcat(s, ftos(panel_order[i]), " ");
	}
	cvar_set("_hud_panelorder", s);
	if(hud_panelorder_prev)
		strunzone(hud_panelorder_prev);
	hud_panelorder_prev = strzone(autocvar__hud_panelorder); // prevent HUD_Main from doing useless update, we already updated here
}

void HUD_Panel_Highlight()
{
	float i, j, border;
	vector panelPos;
	vector panelSize;

	while(j <= HUD_PANEL_NUM)
	{
		i = panel_order[j];
		j += 1;

		HUD_Panel_UpdatePosSizeForId(i);

		panelPos = panel_pos;
		panelSize = panel_size;
		border = max(8, panel_bg_border); // FORCED border so a small border size doesn't mean you can't resize

		// move
		if(mousepos_x >= panelPos_x && mousepos_y >= panelPos_y && mousepos_x <= panelPos_x + panelSize_x && mousepos_y <= panelPos_y + panelSize_y)
		{
			highlightedPanel = i;
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 1;
			panel_click_distance = mousepos - panelPos;
			return;
		}
		// resize from topleft border
		else if(mousepos_x >= panelPos_x - border && mousepos_y >= panelPos_y - border && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
		{
			highlightedPanel = i;
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 1;
			panel_click_distance = mousepos - panelPos;
			panel_click_resizeorigin = panelPos + panelSize;
			return;
		}
		// resize from topright border
		else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y - border && mousepos_x <= panelPos_x + panelSize_x + border && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
		{
			highlightedPanel = i;
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 2;
			panel_click_distance_x = panelSize_x - mousepos_x + panelPos_x;
			panel_click_distance_y = mousepos_y - panelPos_y;
			panel_click_resizeorigin = panelPos + eY * panelSize_y;
			return;
		}
		// resize from bottomleft border
		else if(mousepos_x >= panelPos_x - border && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + panelSize_y + border)
		{
			highlightedPanel = i;
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 3;
			panel_click_distance_x = mousepos_x - panelPos_x;
			panel_click_distance_y = panelSize_y - mousepos_y + panelPos_y;
			panel_click_resizeorigin = panelPos + eX * panelSize_x;
			return;
		}
		// resize from bottomright border
		else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + panelSize_x + border && mousepos_y <= panelPos_y + panelSize_y + border)
		{
			highlightedPanel = i;
			HUD_Panel_FirstInDrawQ(i);
			highlightedAction = 2;
			resizeCorner = 4;
			panel_click_distance = panelSize - mousepos + panelPos;
			panel_click_resizeorigin = panelPos;
			return;
		}
		else
		{
			highlightedPanel_prev = -1;
		}
	}
}

float highlightcheck;
vector prev_pos, prev_size;
void HUD_Panel_Mouse()
{
	// TODO: needs better check... is there any float that contains the current state of the menu? _menu_alpha isn't apparently updated the frame the menu gets enabled
	if (autocvar__menu_alpha == 0 && time - menu_enabled_time > 0.5)
		menu_enabled = 0;

	/*
	print("menu_enabled: ", ftos(menu_enabled), "\n");
	print("Highlighted: ", ftos(highlightedPanel), "\n");
	print("Menu alpha: ", ftos(autocvar__menu_alpha), "\n");
	*/

	// instantly hide the editor cursor if we open the HUDExit dialog
	// as hud_fade_alpha doesn't decrease to 0 in this case
	// TODO: find a way to fade the cursor out even in this case
	if(menu_enabled == 1 || (menu_enabled == 2 && !hud_fade_alpha))
		return;

	if(mouseClicked == 0 && menu_enabled != 2 && highlightedPanel >= 0) { // don't reset these variables in menu_enabled mode 2!
		highlightedPanel = -1;
		highlightedAction = 0;
	}
	if(highlightedPanel != -1)
		highlightedPanel_prev = highlightedPanel;

	mousepos = mousepos + getmousepos() * autocvar_menu_mouse_speed;

	mousepos_x = bound(0, mousepos_x, vid_conwidth);
	mousepos_y = bound(0, mousepos_y, vid_conheight);

	if(mouseClicked)
	{
		if(prevMouseClicked == 0)
		{
			HUD_Panel_Highlight(); // sets highlightedPanel, highlightedAction, panel_click_distance, panel_click_resizeorigin
									// and calls HUD_Panel_UpdatePosSizeForId() for the highlighted panel
			prev_pos = panel_pos;
			prev_size = panel_size;
		}
		else
			HUD_Panel_UpdatePosSizeForId(highlightedPanel);

		if (prev_pos != panel_pos || prev_size != panel_size)
		{
			hud_configure_checkcollisions = (!(hudShiftState & S_CTRL) && autocvar_hud_configure_checkcollisions);
			// backup!
			panel_pos_backup = prev_pos;
			panel_size_backup = prev_size;
			highlightedPanel_backup = highlightedPanel;
		}
		else
			// in case the clicked panel is inside another panel and we aren't
			// moving it, avoid the immediate "fix" of its position/size
			// (often unwanted and hateful) by disabling collisions check
			hud_configure_checkcollisions = false;

		if(highlightedAction == 1)
			HUD_Panel_SetPos(mousepos - panel_click_distance);
		else if(highlightedAction == 2)
		{
			vector mySize;
			if(resizeCorner == 1) {
				mySize_x = panel_click_resizeorigin_x - (mousepos_x - panel_click_distance_x);
				mySize_y = panel_click_resizeorigin_y - (mousepos_y - panel_click_distance_y);
			} else if(resizeCorner == 2) {
				mySize_x = mousepos_x + panel_click_distance_x - panel_click_resizeorigin_x;
				mySize_y = panel_click_distance_y + panel_click_resizeorigin_y - mousepos_y;
			} else if(resizeCorner == 3) {
				mySize_x = panel_click_resizeorigin_x + panel_click_distance_x - mousepos_x;
				mySize_y = mousepos_y + panel_click_distance_y - panel_click_resizeorigin_y;
			} else { // resizeCorner == 4
				mySize_x = mousepos_x - (panel_click_resizeorigin_x - panel_click_distance_x);
				mySize_y = mousepos_y - (panel_click_resizeorigin_y - panel_click_distance_y);
			}
			HUD_Panel_SetPosSize(mySize);
		}

		// doubleclick check
		if(time - prevMouseClickedTime < 0.4 && prevMouseClicked == 0 && prevMouseClickedPos == mousepos && highlightedPanel >= 0)
		{
			mouseClicked = 0; // to prevent spam, I guess.
			menu_enabled = 2;
			menu_enabled_time = time;
			HUD_Panel_GetName(highlightedPanel);
			localcmd("menu_showhudoptions ", panel_name, "\n");
			return;
		}
		if(prevMouseClicked == 0)
		{
			prevMouseClickedTime = time;
			prevMouseClickedPos = mousepos;
		}
	}
	else
	{
		highlightcheck = HUD_Panel_HighlightCheck();
	}
	// draw cursor after performing move/resize to have the panel pos/size updated before highlightcheck
	vector cursorsize;
	cursorsize = '32 32 0';

	if(highlightcheck == 0)
		drawpic(mousepos, strcat("gfx/menu/", autocvar_menu_skin, "/cursor.tga"), '32 32 0', '1 1 1', hud_fade_alpha, DRAWFLAG_NORMAL);
	else if(highlightcheck == 1)
		drawpic(mousepos - cursorsize * 0.5, strcat("gfx/menu/", autocvar_menu_skin, "/cursor_move.tga"), '32 32 0', '1 1 1', hud_fade_alpha, DRAWFLAG_NORMAL);
	else if(highlightcheck == 2)
		drawpic(mousepos - cursorsize * 0.5, strcat("gfx/menu/", autocvar_menu_skin, "/cursor_resize.tga"), '32 32 0', '1 1 1', hud_fade_alpha, DRAWFLAG_NORMAL);
	else
		drawpic(mousepos - cursorsize * 0.5, strcat("gfx/menu/", autocvar_menu_skin, "/cursor_resize2.tga"), '32 32 0', '1 1 1', hud_fade_alpha, DRAWFLAG_NORMAL);

	prevMouseClicked = mouseClicked;
}

// Weapon icons (#0)
//
float weaponspace[10];
#define HUD_Weapons_Clear()\
	float idx;\
	for(idx = 0; idx < 10; ++idx)\
		weaponspace[idx] = 0

entity weaponorder[WEP_MAXCOUNT];
void weaponorder_swap(float i, float j, entity pass)
{
	entity h;
	h = weaponorder[i];
	weaponorder[i] = weaponorder[j];
	weaponorder[j] = h;
}

string weaponorder_cmp_str;
float weaponorder_cmp(float i, float j, entity pass)
{
	float ai, aj;
	ai = strstrofs(weaponorder_cmp_str, sprintf(" %d ", weaponorder[i].weapon), 0);
	aj = strstrofs(weaponorder_cmp_str, sprintf(" %d ", weaponorder[j].weapon), 0);
	return aj - ai; // the string is in REVERSE order (higher prio at the right is what we want, but higher prio first is the string)
}

float GetAmmoStat(float i)
{
	switch(i)
	{
		case 0: return STAT_SHELLS;
		case 1: return STAT_NAILS;
		case 2: return STAT_ROCKETS;
		case 3: return STAT_CELLS;
		case 4: return STAT_FUEL;
		default: return -1;
	}
}

float GetAmmoTypeForWep(float i)
{
	switch(i)
	{
		case WEP_SHOTGUN: return 0;
		case WEP_UZI: return 1;
		case WEP_GRENADE_LAUNCHER: return 2;
		case WEP_MINE_LAYER: return 2;
		case WEP_ELECTRO: return 3;
		case WEP_CRYLINK: return 3;
		case WEP_HLAC: return 3;
		case WEP_MINSTANEX: return 3;
		case WEP_NEX: return 3;
		case WEP_CAMPINGRIFLE: return 1;
		case WEP_HAGAR: return 2;
		case WEP_ROCKET_LAUNCHER: return 2;
		case WEP_SEEKER: return 2;
		case WEP_FIREBALL: return 4;
		case WEP_HOOK: return 3;
		default: return -1;
	}
}

void HUD_Weapons(void)
{
	float f, screen_ar;
	float center_x, center_y;

	if(!autocvar_hud_panel_weapons && !autocvar__hud_configure)
		return;

	float timeout = autocvar_hud_panel_weapons_timeout;
	float timeout_effect_length, timein_effect_length;
	if (autocvar_hud_panel_weapons_timeout_effect == 0)
	{
		timeout_effect_length = 0;
		timein_effect_length = 0;
	}
	else
	{
		timeout_effect_length = 0.75;
		timein_effect_length = 0.375;
	}

	if (timeout && time >= weapontime + timeout + timeout_effect_length && !autocvar__hud_configure)
	{
		weaponprevtime = time;
		return;
	}

	active_panel = HUD_PANEL_WEAPONS;
	HUD_Panel_UpdateCvars(weapons);

	if (timeout && time >= weapontime + timeout && !autocvar__hud_configure)
	{
		f = (time - (weapontime + timeout)) / timeout_effect_length;
		if (autocvar_hud_panel_weapons_timeout_effect)
		{
			panel_bg_alpha *= (1 - f);
			panel_fg_alpha *= (1 - f);
		}
		if (autocvar_hud_panel_weapons_timeout_effect == 1)
		{
			f *= f; // for a cooler movement
			center_x = panel_pos_x + panel_size_x/2;
			center_y = panel_pos_y + panel_size_y/2;
			screen_ar = vid_conwidth/vid_conheight;
			if (center_x/center_y < screen_ar) //bottom left
			{
				if ((vid_conwidth - center_x)/center_y < screen_ar) //bottom
					panel_pos_y += f * (vid_conheight - panel_pos_y);
				else //left
					panel_pos_x -= f * (panel_pos_x + panel_size_x);
			}
			else //top right
			{
				if ((vid_conwidth - center_x)/center_y < screen_ar) //right
					panel_pos_x += f * (vid_conwidth - panel_pos_x);
				else //top
					panel_pos_y -= f * (panel_pos_y + panel_size_y);
			}
		}
		weaponprevtime = time - (1 - f) * timein_effect_length;
	}
	else if (timeout && time < weaponprevtime + timein_effect_length && !autocvar__hud_configure)
	{
		f = (time - weaponprevtime) / timein_effect_length;
		if (autocvar_hud_panel_weapons_timeout_effect)
		{
			panel_bg_alpha *= (f);
			panel_fg_alpha *= (f);
		}
		if (autocvar_hud_panel_weapons_timeout_effect == 1)
		{
			f *= f; // for a cooler movement
			f = 1 - f;
			center_x = panel_pos_x + panel_size_x/2;
			center_y = panel_pos_y + panel_size_y/2;
			screen_ar = vid_conwidth/vid_conheight;
			if (center_x/center_y < screen_ar) //bottom left
			{
				if ((vid_conwidth - center_x)/center_y < screen_ar) //bottom
					panel_pos_y += f * (vid_conheight - panel_pos_y);
				else //left
					panel_pos_x -= f * (panel_pos_x + panel_size_x);
			}
			else //top right
			{
				if ((vid_conwidth - center_x)/center_y < screen_ar) //right
					panel_pos_x += f * (vid_conwidth - panel_pos_x);
				else //top
					panel_pos_y -= f * (panel_pos_y + panel_size_y);
			}
		}
	}

	float i, weapid, wpnalpha, weapon_cnt;
	weapon_cnt = 0;
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		self = get_weaponinfo(i);
		if(self.impulse >= 0)
			++weapon_cnt;
	}

	// TODO make this configurable
	if(weaponorder_bypriority != autocvar_cl_weaponpriority)
	{
		if(weaponorder_bypriority)
			strunzone(weaponorder_bypriority);
		if(weaponorder_byimpulse)
			strunzone(weaponorder_byimpulse);

		weaponorder_bypriority = strzone(autocvar_cl_weaponpriority);
		weaponorder_byimpulse = strzone(W_FixWeaponOrder_BuildImpulseList(W_FixWeaponOrder_ForceComplete(W_NumberWeaponOrder(weaponorder_bypriority))));
		weaponorder_cmp_str = strcat(" ", weaponorder_byimpulse, " ");

		weapon_cnt = 0;
		for(i = WEP_FIRST; i <= WEP_LAST; ++i)
		{
			self = get_weaponinfo(i);
			if(self.impulse >= 0)
			{
				weaponorder[weapon_cnt] = self;
				++weapon_cnt;
			}
		}
		heapsort(weapon_cnt, weaponorder_swap, weaponorder_cmp, world);

		weaponorder_cmp_str = string_null;
	}

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	if(autocvar_hud_panel_weapons_fade)
	{
		wpnalpha = 3.2 - 2 * (time - weapontime);
		wpnalpha = bound(0.7, wpnalpha, 1) * panel_fg_alpha;
	}
	else
		wpnalpha = panel_fg_alpha;

	HUD_Weapons_Clear();

	float rows, columns;
	float aspect = autocvar_hud_panel_weapons_aspect;
	rows = panel_size_y/panel_size_x;
	rows = bound(1, floor((sqrt(4 * aspect * rows * WEP_COUNT + rows * rows) + rows + 0.5) / 2), WEP_COUNT);

	columns = ceil(WEP_COUNT/rows);
	float row, column;

	float a, type, fullammo;
	float when;
	when = autocvar_hud_panel_weapons_complainbubble_time;
	float fadetime;
	fadetime = autocvar_hud_panel_weapons_complainbubble_fadetime;

	vector color;
	vector wpnpos;
	vector wpnsize;
	
	float fullammo_shells, fullammo_nails, fullammo_rockets, fullammo_cells, fullammo_fuel;
	vector ammo_color;
	float ammo_alpha;
	wpnsize = eX * panel_size_x*(1/columns) + eY * panel_size_y*(1/rows);
	float barsize_x, barsize_y, baroffset_x, baroffset_y;
	float show_ammo = autocvar_hud_panel_weapons_ammo;
	if (show_ammo)
	{
		fullammo_shells = autocvar_hud_panel_weapons_ammo_full_shells;
		fullammo_nails = autocvar_hud_panel_weapons_ammo_full_nails;
		fullammo_rockets = autocvar_hud_panel_weapons_ammo_full_rockets;
		fullammo_cells = autocvar_hud_panel_weapons_ammo_full_cells;
		fullammo_fuel = autocvar_hud_panel_weapons_ammo_full_fuel;
		ammo_color = stov(autocvar_hud_panel_weapons_ammo_color);
		ammo_alpha = panel_fg_alpha * autocvar_hud_panel_weapons_ammo_alpha;


		if(wpnsize_x/wpnsize_y > aspect)
		{
			barsize_x = aspect * wpnsize_y;
			barsize_y = wpnsize_y;
			baroffset_x = (wpnsize_x - barsize_x) / 2;
		}
		else
		{
			barsize_y = 1/aspect * wpnsize_x;
			barsize_x = wpnsize_x;
			baroffset_y = (wpnsize_y - barsize_y) / 2;
		}
	}

	float show_accuracy;
	float weapon_stats;
	if(autocvar_hud_panel_weapons_accuracy && acc_levels)
	{
		show_accuracy = true;
		if (acc_col_x[0] == -1)
			for (i = 0; i < acc_levels; ++i)
				acc_col[i] = stov(cvar_string(strcat("accuracy_color", ftos(i))));
	}

	float weapons_st = getstati(STAT_WEAPONS);
	float label = autocvar_hud_panel_weapons_label;

	for(i = 0; i < weapon_cnt; ++i)
	{
		wpnpos = panel_pos + eX * column * wpnsize_x + eY * row * wpnsize_y;

		self = weaponorder[i];
		weapid = self.impulse;

		// draw background behind currently selected weapon
		if(self.weapon == activeweapon)
			drawpic_aspect_skin(wpnpos, "weapon_current_bg", wpnsize, '1 1 1', wpnalpha, DRAWFLAG_NORMAL);

		// draw the weapon accuracy
		if(show_accuracy)
		{
			weapon_stats = weapon_accuracy[self.weapon-WEP_FIRST];
			if(weapon_stats >= 0)
			{
				// find the max level lower than weapon_stats
				float j;
				j = acc_levels-1;
				while ( j && weapon_stats < acc_lev[j] )
					--j;

				// inject color j+1 in color j, how much depending on how much weapon_stats is higher than level j
				float factor;
				factor = (weapon_stats - acc_lev[j]) / (acc_lev[j+1] - acc_lev[j]);
				color = acc_col[j];
				color = color + factor * (acc_col[j+1] - color);

				drawpic_aspect_skin(wpnpos, "weapon_accuracy", wpnsize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
		}

		// draw the weapon icon
		if((weapid >= 0) && (weapons_st & self.weapons))
		{
			drawpic_aspect_skin(wpnpos, strcat("weapon", self.netname), wpnsize, '1 1 1', wpnalpha, DRAWFLAG_NORMAL);

			if(label == 1) // weapon number
				drawstring(wpnpos, ftos(weapid), '1 1 0' * 0.5 * wpnsize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
			else if(label == 2) // bind
				drawstring(wpnpos, getcommandkey(ftos(weapid), strcat("impulse ", ftos(weapid))), '1 1 0' * 0.5 * wpnsize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			// draw ammo status bar
			if(show_ammo && weapid != WEP_TUBA && weapid != WEP_LASER && weapid != WEP_PORTO)
			{
				a = 0;
				type = GetAmmoTypeForWep(weapid);
				if(type != -1)
					a = getstati(GetAmmoStat(type)); // how much ammo do we have?

				if(a > 0)
				{
					switch(type) {
						case 0: fullammo = fullammo_shells; break;
						case 1: fullammo = fullammo_nails; break;
						case 2: fullammo = fullammo_rockets; break;
						case 3: fullammo = fullammo_cells; break;
						case 4: fullammo = fullammo_fuel; break;
						default: fullammo = 60;
					}

					drawsetcliparea(
						wpnpos_x + baroffset_x,
						wpnpos_y + baroffset_y,
						barsize_x * bound(0, a/fullammo, 1),
						barsize_y);
					drawpic_aspect_skin(wpnpos, "weapon_ammo", wpnsize, ammo_color, ammo_alpha, DRAWFLAG_NORMAL);
					drawresetcliparea();
				}
			}
		}

		// draw a "ghost weapon icon" if you don't have the weapon
		else
		{
			drawpic_aspect_skin(wpnpos, strcat("weapon", self.netname), wpnsize, '0 0 0', panel_fg_alpha * 0.5, DRAWFLAG_NORMAL);
		}

		// draw the complain message
		if(time - complain_weapon_time < when + fadetime && self.weapon == complain_weapon && autocvar_hud_panel_weapons_complainbubble)
		{
			if(fadetime)
			{
				if(complain_weapon_time + when > time)
					a = 1;
				else
					a = bound(0, (complain_weapon_time + when + fadetime - time) / fadetime, 1);
			}
			else
			{
				if(complain_weapon_time + when > time)
					a = 1;
				else
					a = 0;
			}

			string s;
			if(complain_weapon_type == 0) {
				s = "Out of ammo";
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_outofammo);
			}
			else if(complain_weapon_type == 1) {
				s = "Don't have";
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_donthave);
			}
			else {
				s = "Unavailable";
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_unavailable);
			}
			float padding = autocvar_hud_panel_weapons_complainbubble_padding;
			drawpic_aspect_skin(wpnpos + '1 1 0' * padding, "weapon_complainbubble", wpnsize - '2 2 0' * padding, color, a * panel_fg_alpha, DRAWFLAG_NORMAL);
			drawstring_aspect(wpnpos + '1 1 0' * padding, s, wpnsize - '2 2 0' * padding, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}

}

// Ammo (#1)
//
// TODO: macro
float GetAmmoItemCode(float i)
{
	switch(i)
	{
		case 0: return IT_SHELLS;
		case 1: return IT_NAILS;
		case 2: return IT_ROCKETS;
		case 3: return IT_CELLS;
		case 4: return IT_FUEL;
		default: return -1;
	}
}

string GetAmmoPicture(float i)
{
	switch(i)
	{
		case 0: return "ammo_shells";
		case 1: return "ammo_bullets";
		case 2: return "ammo_rockets";
		case 3: return "ammo_cells";
		case 4: return "ammo_fuel";
		default: return "";
	}
}

void DrawAmmoItem(vector myPos, vector mySize, float itemcode, float currently_selected)
{
	float a;
	if(autocvar__hud_configure)
	{
		currently_selected = (itemcode == 2); //rockets always selected
		a = 100;
	}
	else
		a = getstati(GetAmmoStat(itemcode)); // how much ammo do we have of type itemcode?

	vector color;
	if(a < 10)
		color = '0.7 0 0';
	else
		color = '1 1 1';

	float alpha;
	if(currently_selected)
		alpha = 1;
	else
		alpha = 0.7;

	vector picpos, numpos;
	if(autocvar_hud_panel_ammo_iconalign)
	{
		numpos = myPos;
		picpos = myPos + eX * 2 * mySize_y;
	}
	else
	{
		numpos = myPos + eX * mySize_y;
		picpos = myPos;
	}

	if (currently_selected)
		drawpic_aspect_skin(myPos, "ammo_current_bg", mySize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

    if(a > 0 && autocvar_hud_panel_ammo_progressbar)
        HUD_Panel_DrawProgressBar(myPos + eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize_x, mySize - eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize_x, autocvar_hud_panel_ammo_progressbar_name, 0, 0, min(1, a/autocvar_hud_panel_ammo_maxammo), color, autocvar_hud_progressbar_alpha * panel_fg_alpha * alpha, DRAWFLAG_NORMAL);

    if(autocvar_hud_panel_ammo_text)
    {
        if(a > 0)
            drawstring_aspect(numpos, ftos(a), eX * (2/3) * mySize_x + eY * mySize_y, color, panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
        else // "ghost" ammo count
            drawstring_aspect(numpos, ftos(a), eX * (2/3) * mySize_x + eY * mySize_y, '0 0 0', panel_fg_alpha * alpha * 0.5, DRAWFLAG_NORMAL);
    }
	if(a > 0)
		drawpic_aspect_skin(picpos, GetAmmoPicture(itemcode), '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
	else // "ghost" ammo icon
		drawpic_aspect_skin(picpos, GetAmmoPicture(itemcode), '1 1 0' * mySize_y, '0 0 0', panel_fg_alpha * alpha * 0.5, DRAWFLAG_NORMAL);
}

void HUD_Ammo(void)
{
	if(!autocvar_hud_panel_ammo && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_AMMO;
	HUD_Panel_UpdateCvars(ammo);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float rows, columns, row, column;
	vector ammo_size;
	if (autocvar_hud_panel_ammo_onlycurrent)
		ammo_size = mySize;
	else
	{
		rows = mySize_y/mySize_x;
		rows = bound(1, floor((sqrt(4 * (3/1) * rows * AMMO_COUNT + rows * rows) + rows + 0.5) / 2), AMMO_COUNT);
		//                               ^^^ ammo item aspect goes here

		columns = ceil(AMMO_COUNT/rows);

		ammo_size = eX * mySize_x*(1/columns) + eY * mySize_y*(1/rows);
	}

	vector offset;
	float newSize;
	if(ammo_size_x/ammo_size_y > 3)
	{
		newSize = 3 * ammo_size_y;
		offset_x = ammo_size_x - newSize;
		pos_x += offset_x/2;
		ammo_size_x = newSize;
	}
	else
	{
		newSize = 1/3 * ammo_size_x;
		offset_y = ammo_size_y - newSize;
		pos_y += offset_y/2;
		ammo_size_y = newSize;
	}

	drawfont = hud_bigfont;
	float i, stat_items, currently_selected;
	if (autocvar_hud_panel_ammo_onlycurrent)
	{
		if(autocvar__hud_configure)
		{
			DrawAmmoItem(pos, ammo_size, 2, true); //show rockets
			return;
		}
		stat_items = getstati(STAT_ITEMS);
		for (i = 0; i < AMMO_COUNT; ++i) {
			currently_selected = stat_items & GetAmmoItemCode(i);
			if (currently_selected)
			{
				DrawAmmoItem(pos, ammo_size, i, true);
				return;
			}
		}
		return; // nothing to display
	}

	stat_items = getstati(STAT_ITEMS);
	for (i = 0; i < AMMO_COUNT; ++i) {
		currently_selected = stat_items & GetAmmoItemCode(i);
		DrawAmmoItem(pos + eX * column * (ammo_size_x + offset_x) + eY * row * (ammo_size_y + offset_y), ammo_size, i, currently_selected);
		++row;
		if(row >= rows)
		{
			row = 0;
			column = column + 1;
		}
	}
	drawfont = hud_font;
}

void DrawNumIcon(float iconalign, vector myPos, vector mySize, float x, string icon, float left, vector color, float alpha)
{
	vector newPos;
	float newSize_x, newSize_y;
	if(mySize_x/mySize_y > 3)
	{
		newSize_x = 3 * mySize_y;
		newSize_y = mySize_y;

		newPos_x = myPos_x + (mySize_x - newSize_x) / 2;
		newPos_y = myPos_y;
	}
	else
	{
		newSize_y = 1/3 * mySize_x;
		newSize_x = mySize_x;

		newPos_y = myPos_y + (mySize_y - newSize_y) / 2;
		newPos_x = myPos_x;
	}

	vector picpos, numpos;
	if(left)
	{
		if(iconalign == 1 || iconalign == 3) // right align
		{
			numpos = newPos;
			picpos = newPos + eX * 2 * newSize_y;
		}
		else // left align
		{
			numpos = newPos + eX * newSize_y;
			picpos = newPos;
		}
	}
	else
	{
		if(iconalign == 0 || iconalign == 3) // left align
		{
			numpos = newPos + eX * newSize_y;
			picpos = newPos;
		} 
		else // right align
		{
			numpos = newPos;
			picpos = newPos + eX * 2 * newSize_y;
		}
	}

	drawfont = hud_bigfont;
	drawstring_aspect(numpos, ftos(x), eX * (2/3) * newSize_x + eY * newSize_y, color, panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
	drawfont = hud_font;
	drawpic_aspect_skin(picpos, icon, '1 1 0' * newSize_y, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
}

void DrawNumIcon_expanding(float iconalign, vector myPos, vector mySize, float x, string icon, float left, vector color, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	DrawNumIcon(iconalign, myPos + expandingbox_resize_centered_box_offset(sz, mySize, 1), mySize * sz, x, icon, left, color, (1 - fadelerp));
}

// Powerups (#2)
//
void HUD_Powerups(void) {
	if(!autocvar_hud_panel_powerups && !autocvar__hud_configure)
		return;

	if(!autocvar__hud_configure)
	{
		if not(getstati(STAT_ITEMS) & (IT_STRENGTH | IT_INVINCIBLE))
			return;

		if (getstati(STAT_HEALTH) <= 0)
			return;
	}

	active_panel = HUD_PANEL_POWERUPS;
	HUD_Panel_UpdateCvars(powerups);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

 	float strength_time, shield_time;
	if(autocvar__hud_configure)
	{
		strength_time = 15;
		shield_time = 27;
	}
	else
	{
		strength_time = bound(0, getstatf(STAT_STRENGTH_FINISHED) - time, 99);
		shield_time = bound(0, getstatf(STAT_INVINCIBLE_FINISHED) - time, 99);
	}

	HUD_Panel_DrawBg(bound(0, max(strength_time, shield_time), 1));
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	vector barpos, barsize;
	vector picpos;
	vector numpos;

	string leftname, rightname;
    string leftprogressname, rightprogressname;
	float leftcnt, rightcnt;
	float leftexact, rightexact;
	float flip = autocvar_hud_panel_powerups_flip;
	if (flip) {
		leftname = "strength";
        leftprogressname = autocvar_hud_panel_powerups_progressbar_strength;
		leftcnt = ceil(strength_time);
		leftexact = strength_time;

		rightname = "shield";
        rightprogressname = autocvar_hud_panel_powerups_progressbar_shield;
		rightcnt = ceil(shield_time);
		rightexact = shield_time;
	} else {
		leftname = "shield";
        leftprogressname = autocvar_hud_panel_powerups_progressbar_shield;
		leftcnt = ceil(shield_time);
		leftexact = shield_time;

		rightname = "strength";
        rightprogressname = autocvar_hud_panel_powerups_progressbar_strength;
		rightcnt = ceil(strength_time);
		rightexact = strength_time;
	}

	drawfont = hud_bigfont;
	float baralign = autocvar_hud_panel_powerups_baralign;
    float barflip;
	float iconalign = autocvar_hud_panel_powerups_iconalign;
	float progressbar = autocvar_hud_panel_powerups_progressbar;
	if (mySize_x/mySize_y > 4)
	{
        barsize = eX * 0.5 * mySize_x + eY * mySize_y;
		if(leftcnt)
		{
			if(baralign == 1 || baralign == 3) { // right align
                barpos = pos + eX * 0.5 * mySize_x;
                barflip = 1;
			} else { // left align
                barpos = pos;
                barflip = 0;
			}

			if(progressbar)
			{
				HUD_Panel_GetProgressBarColorForString(leftname);
				HUD_Panel_DrawProgressBar(barpos, barsize, leftprogressname, 0, barflip, min(1, leftcnt/30), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * bound(0, max(strength_time, shield_time), 1), DRAWFLAG_NORMAL);
			}
            if(autocvar_hud_panel_powerups_text)
            {
                if(leftcnt > 1)
                    DrawNumIcon(iconalign, pos, eX * 0.5 * mySize_x + eY * mySize_y, leftcnt, leftname, 1, '1 1 1', 1);
                if(leftcnt <= 5)
                    DrawNumIcon_expanding(iconalign, pos, eX * 0.5 * mySize_x + eY * mySize_y, leftcnt, leftname, 1, '1 1 1', bound(0, (leftcnt - leftexact) / 0.5, 1));
            }
		}

		if(rightcnt)
		{
			if(baralign == 0 || baralign == 3) { // left align
                barpos = pos;
                barflip = 0;
			} else { // right align
                barpos = pos + eX * 0.5 * mySize_x;
                barflip = 1;
			}

			if(progressbar)
			{
				HUD_Panel_GetProgressBarColorForString(rightname);
				HUD_Panel_DrawProgressBar(barpos, barsize, rightprogressname, 0, barflip, min(1, rightcnt/30), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * bound(0, max(strength_time, shield_time), 1), DRAWFLAG_NORMAL);
			}
            if(autocvar_hud_panel_powerups_text)
            {
                if(rightcnt > 1)
                    DrawNumIcon(iconalign, pos + eX * 0.5 * mySize_x, eX * 0.5 * mySize_x + eY * mySize_y, rightcnt, rightname, 0, '1 1 1', 1);
                if(rightcnt <= 5)
                    DrawNumIcon_expanding(iconalign, pos + eX * 0.5 * mySize_x, eX * 0.5 * mySize_x + eY * mySize_y, rightcnt, rightname, 0, '1 1 1', bound(0, (rightcnt - rightexact) / 0.5, 1));
            }
		}
	}
	else if (mySize_x/mySize_y > 1.5)
	{
        barsize = eX * mySize_x + eY * 0.5 * mySize_y;
		if(leftcnt)
		{
            barpos = pos;
			if(baralign == 1 || baralign == 3) { // right/down align
                barflip = 1;
			} else { // left/up align
                barflip = 0;
			}

			if(progressbar)
			{
				HUD_Panel_GetProgressBarColorForString(leftname);
				HUD_Panel_DrawProgressBar(barpos, barsize, leftprogressname, 0, barflip, min(1, leftcnt/30), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * bound(0, max(strength_time, shield_time), 1), DRAWFLAG_NORMAL);
			}
            if(autocvar_hud_panel_powerups_text)
            {
                if(leftcnt > 1)
                    DrawNumIcon(iconalign, pos, eX * mySize_x + eY * 0.5 * mySize_y, leftcnt, leftname, 1, '1 1 1', 1);
                if(leftcnt <= 5)
                    DrawNumIcon_expanding(iconalign, pos, eX * mySize_x + eY * 0.5 * mySize_y, leftcnt, leftname, 1, '1 1 1', bound(0, (leftcnt - leftexact) / 0.5, 1));
            }
		}

		if(rightcnt)
		{
            barpos = pos + eY * 0.5 * mySize_y;
			if(baralign == 0 || baralign == 3) { // left align
                barflip = 0;
			} else { // right align
                barflip = 1;
			}

			if(progressbar)
			{
				HUD_Panel_GetProgressBarColorForString(rightname);
				HUD_Panel_DrawProgressBar(barpos, barsize, rightprogressname, 0, barflip, min(1, rightcnt/30), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * bound(0, max(strength_time, shield_time), 1), DRAWFLAG_NORMAL);
			}
            if(autocvar_hud_panel_powerups_text)
            {
                if(rightcnt > 1)
                    DrawNumIcon(iconalign, pos + eY * 0.5 * mySize_y, eX * mySize_x + eY * 0.5 * mySize_y, rightcnt, rightname, 0, '1 1 1', 1);
                if(rightcnt <= 5)
                    DrawNumIcon_expanding(iconalign, pos + eY * 0.5 * mySize_y, eX * mySize_x + eY * 0.5 * mySize_y, rightcnt, rightname, 0, '1 1 1', bound(0, (rightcnt - rightexact) / 0.5, 1));
            }
		}
	}
	else
	{
        barsize = eX * 0.5 * mySize_x + eY * mySize_y;
		if(leftcnt)
		{
            barpos = pos;
			if(baralign == 1 || baralign == 3) { // down align
                barflip = 1;
			} else { // up align
                barflip = 0;
			}

			if(iconalign == 1 || iconalign == 3) { // down align
				picpos = pos + eX * 0.05 * mySize_x + eY * (mySize_y - 0.65 * mySize_x);
				numpos = pos + eY * mySize_y - eY * 0.25 * mySize_x;
			} else { // up align
				picpos = pos + eX * 0.05 * mySize_x;
				numpos = pos + eY * 0.4 * mySize_x;
			}

			if(progressbar)
			{
				HUD_Panel_GetProgressBarColorForString(leftname);
				HUD_Panel_DrawProgressBar(barpos, barsize, leftprogressname, 1, barflip, min(1, leftcnt/30), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * bound(0, max(strength_time, shield_time), 1), DRAWFLAG_NORMAL);
			}
            if(autocvar_hud_panel_powerups_text)
            {
                if(leftcnt <= 5)
                    drawpic_aspect_skin_expanding(picpos, leftname, '0.4 0.4 0' * mySize_x, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, bound(0, (leftcnt - leftexact) / 0.5, 1));
                if(leftcnt > 1)
                    drawpic_aspect_skin(picpos, leftname, '0.4 0.4 0' * mySize_x, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
                drawstring_aspect(numpos, ftos(leftcnt), eX * 0.5 * mySize_x + eY * 0.25 * mySize_x, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
            }
		}

		if(rightcnt)
		{
            barpos = pos + eX * 0.5 * mySize_x;
			if(baralign == 0 || baralign == 3) { // down align
                barflip = 1;
			} else { // up align
                barflip = 0;
			}

			if(iconalign == 0 || iconalign == 3) { // up align
				picpos = pos + eX * 0.05 * mySize_x + eX * 0.5 * mySize_x;
				numpos = pos + eY * 0.4 * mySize_x + eX * 0.5 * mySize_x;
			} else { // down align
				picpos = pos + eX * 0.05 * mySize_x + eY * (mySize_y - 0.65 * mySize_x) + eX * 0.5 * mySize_x;
				numpos = pos + eY * mySize_y - eY * 0.25 * mySize_x + eX * 0.5 * mySize_x;
			}

			if(progressbar)
			{
				HUD_Panel_GetProgressBarColorForString(rightname);
				HUD_Panel_DrawProgressBar(barpos, barsize, rightprogressname, 1, barflip, min(1, rightcnt/30), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * bound(0, max(strength_time, shield_time), 1), DRAWFLAG_NORMAL);
			}
            if(autocvar_hud_panel_powerups_text)
            {
                if(rightcnt <= 5)
                    drawpic_aspect_skin_expanding(picpos, rightname, '0.4 0.4 0' * mySize_x, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, bound(0, (rightcnt - rightexact) / 0.5, 1));
                if(rightcnt > 1)
                    drawpic_aspect_skin(picpos, rightname, '0.4 0.4 0' * mySize_x, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
                drawstring_aspect(numpos, ftos(rightcnt), eX * 0.5 * mySize_x + eY * 0.25 * mySize_x, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
            }
		}
	}
	drawfont = hud_font;
}

// Health/armor (#3)
//
void HUD_HealthArmor(void)
{
	if(!autocvar_hud_panel_healtharmor && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_HEALTHARMOR;
	HUD_Panel_UpdateCvars(healtharmor);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float armor, health, fuel;
	armor = getstati(STAT_ARMOR);
	health = getstati(STAT_HEALTH);
	fuel = getstati(STAT_FUEL);

	if(autocvar__hud_configure)
	{
		armor = 75;
		health = 150;
		fuel = 20;
	}

	if(health <= 0)
		return;

	vector barpos, barsize;
	vector picpos;
	vector numpos;

	drawfont = hud_bigfont;
	float baralign = autocvar_hud_panel_healtharmor_baralign;
	float iconalign = autocvar_hud_panel_healtharmor_iconalign;
	float progressbar = autocvar_hud_panel_healtharmor_progressbar;

    float maxhealth = autocvar_hud_panel_healtharmor_maxhealth;
    float maxarmor = autocvar_hud_panel_healtharmor_maxarmor;
	if(autocvar_hud_panel_healtharmor == 2) // combined health and armor display
	{
		vector v;
		v = healtharmor_maxdamage(health, armor, armorblockpercent);

		float x;
		x = floor(v_x + 1);

        float maxtotal = maxhealth + maxarmor;

        barpos = pos;
        barsize = mySize;

		string biggercount;
		if(v_z) // NOT fully armored
		{
			biggercount = "health";
			if(progressbar)
			{
				HUD_Panel_GetProgressBarColor(health);
				HUD_Panel_DrawProgressBar(barpos, barsize, autocvar_hud_panel_healtharmor_progressbar_health, 0, mod(baralign, 2), x/maxtotal, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			if(armor)
            if(autocvar_hud_panel_healtharmor_text)
				drawpic_aspect_skin(pos + eX * mySize_x - eX * 0.5 * mySize_y, "armor", '0.5 0.5 0' * mySize_y, '1 1 1', panel_fg_alpha * armor / health, DRAWFLAG_NORMAL);
		}
		else
		{
			biggercount = "armor";
			if(progressbar)
			{
				HUD_Panel_GetProgressBarColor(armor);
				HUD_Panel_DrawProgressBar(barpos, barsize, autocvar_hud_panel_healtharmor_progressbar_armor, 0, mod(baralign, 2), x/maxtotal, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			if(health)
            if(autocvar_hud_panel_healtharmor_text)
				drawpic_aspect_skin(pos + eX * mySize_x - eX * 0.5 * mySize_y, "health", '0.5 0.5 0' * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
        if(autocvar_hud_panel_healtharmor_text)
            DrawNumIcon(iconalign, pos, mySize, x, biggercount, 1, HUD_Get_Num_Color(x, maxtotal), 1);

		// fuel
		if(fuel)
		{
            barpos = pos;
            barsize = eX * mySize_x + eY * 0.2 * mySize_y;
			HUD_Panel_GetProgressBarColor(fuel);
            HUD_Panel_DrawProgressBar(barpos, barsize, "progressbar", 0, mod(baralign, 2), min(1, fuel/100), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
		}
	}
	else
	{
		string leftname, rightname;
        string leftprogressname, rightprogressname;
		float leftcnt, rightcnt;
		float leftmax, rightmax;
		float leftactive, rightactive;
		float leftalpha, rightalpha;
		float flip = autocvar_hud_panel_healtharmor_flip;
        float barflip;
		if (flip) { // old style layout with armor left/top of health
			leftname = "armor";
            leftprogressname = autocvar_hud_panel_healtharmor_progressbar_armor;
			leftcnt = armor;
			if(leftcnt)
				leftactive = 1;
			leftalpha = min((armor+10)/55, 1);
            leftmax = maxarmor;

			rightname = "health";
            rightprogressname = autocvar_hud_panel_healtharmor_progressbar_health;
			rightcnt = health;
			rightactive = 1;
			rightalpha = 1;
            rightmax = maxhealth;
		} else {
			leftname = "health";
            leftprogressname = autocvar_hud_panel_healtharmor_progressbar_health;
			leftcnt = health;
			leftactive = 1;
			leftalpha = 1;
            leftmax = maxhealth;

			rightname = "armor";
            rightprogressname = autocvar_hud_panel_healtharmor_progressbar_armor;
			rightcnt = armor;
			if(rightcnt)
				rightactive = 1;
			rightalpha = min((armor+10)/55, 1);
            rightmax = maxarmor;
		}

		if (mySize_x/mySize_y > 4)
		{
            barsize = eX * 0.5 * mySize_x + eY * mySize_y;
			if(leftactive)
			{
                barpos = pos;
				if(baralign == 1 || baralign == 3) { // right align
                    barflip = 1;
				} else { // left align
                    barflip = 0;
				}

				if(progressbar)
				{
					HUD_Panel_GetProgressBarColorForString(leftname);
                    HUD_Panel_DrawProgressBar(barpos, barsize, leftprogressname, 0, barflip, min(1, leftcnt/leftmax), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
                if(autocvar_hud_panel_healtharmor_text)
                    DrawNumIcon(iconalign, pos, eX * 0.5 * mySize_x + eY * mySize_y, leftcnt, leftname, 1, HUD_Get_Num_Color(leftcnt, leftmax), 1);
			}

			if(rightactive)
			{
                barpos = pos + eX * 0.5 * mySize_x;
				if(baralign == 0 || baralign == 3) { // left align
                    barflip = 0;
				} else { // right align
                    barflip = 1;
				}

				if(progressbar)
				{
					HUD_Panel_GetProgressBarColorForString(rightname);
                    HUD_Panel_DrawProgressBar(barpos, barsize, rightprogressname, 0, barflip, min(1, rightcnt/rightmax), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
                if(autocvar_hud_panel_healtharmor_text)
                    DrawNumIcon(iconalign, pos + eX * 0.5 * mySize_x, eX * 0.5 * mySize_x + eY * mySize_y, rightcnt, rightname, 0, HUD_Get_Num_Color(rightcnt, rightmax), 1);
			}

			if(fuel)
			{
                barpos = pos;
                barsize = eX * mySize_x + eY * 0.2 * mySize_y;
                HUD_Panel_GetProgressBarColor(fuel);
                HUD_Panel_DrawProgressBar(barpos, barsize, "progressbar", 0, mod(baralign, 2), min(1, fuel/100), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
			}
		}
		else if (mySize_x/mySize_y > 1.5)
		{
            barsize = eX * mySize_x + eY * 0.5 * mySize_y;
			if(leftactive)
			{
                barpos = pos;
				if(baralign == 1 || baralign == 3) { // right align
                    barflip = 1;
				} else { // left align
                    barflip = 0;
				}

				if(progressbar)
				{
					HUD_Panel_GetProgressBarColorForString(leftname);
                    HUD_Panel_DrawProgressBar(barpos, barsize, leftprogressname, 0, barflip, min(1, leftcnt/leftmax), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
                if(autocvar_hud_panel_healtharmor_text)
                    DrawNumIcon(iconalign, pos, eX * mySize_x + eY * 0.5 * mySize_y, leftcnt, leftname, 1, HUD_Get_Num_Color(leftcnt, leftmax), 1);
			}

			if(rightactive)
			{
                barpos = pos + eY * 0.5 * mySize_y;
				if(baralign == 0 || baralign == 3) { // left align
                    barflip = 0;
				} else { // right align
                    barflip = 1;
				}

				if(progressbar)
				{
					HUD_Panel_GetProgressBarColorForString(rightname);
                    HUD_Panel_DrawProgressBar(barpos, barsize, rightprogressname, 0, barflip, min(1, rightcnt/rightmax), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
                if(autocvar_hud_panel_healtharmor_text)
                    DrawNumIcon(iconalign, pos + eY * 0.5 * mySize_y, eX * mySize_x + eY * 0.5 * mySize_y, rightcnt, rightname, 0, HUD_Get_Num_Color(rightcnt, rightmax), 1);
			}

			if(fuel)
			{
                barpos = pos;
                barsize = eX * mySize_x + eY * 0.2 * mySize_y;
                HUD_Panel_GetProgressBarColor(fuel);
                HUD_Panel_DrawProgressBar(barpos, barsize, "progressbar", 0, mod(baralign, 2), min(1, fuel/100), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
			}
		}
		else
		{
            barsize = eX * 0.5 * mySize_x + eY * mySize_y;
			if(leftactive)
			{
                barpos = pos;
				if(baralign == 1 || baralign == 3) { // right align
                    barflip = 1;
				} else { // left align
                    barflip = 0;
				}

				if(iconalign == 1 || iconalign == 3) { // down align
					picpos = pos + eX * 0.05 * mySize_x + eY * (mySize_y - 0.65 * mySize_x);
					numpos = pos + eY * mySize_y - eY * 0.25 * mySize_x;
				} else { // up align
					picpos = pos + eX * 0.05 * mySize_x;
					numpos = pos + eY * 0.4 * mySize_x;
				}

				if(progressbar)
				{
					HUD_Panel_GetProgressBarColorForString(leftname);
                    HUD_Panel_DrawProgressBar(barpos, barsize, leftprogressname, 1, barflip, min(1, leftcnt/leftmax), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
                if(autocvar_hud_panel_healtharmor_text)
                {
                    drawpic_aspect_skin(picpos, leftname, '0.4 0.4 0' * mySize_x, '1 1 1', leftalpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawstring_aspect(numpos, ftos(leftcnt), eX * 0.5 * mySize_x + eY * 0.25 * mySize_x, HUD_Get_Num_Color(leftcnt, leftmax), panel_fg_alpha, DRAWFLAG_NORMAL);
                }
			}

			if(rightactive)
			{
                barpos = pos + eX * 0.5 * mySize_x;
				if(baralign == 0 || baralign == 3) { // left align
                    barflip = 0;
				} else { // right align
                    barflip = 1;
				}

				if(iconalign == 0 || iconalign == 3) { // up align
					picpos = pos + eX * 0.05 * mySize_x + eX * 0.5 * mySize_x;
					numpos = pos + eY * 0.4 * mySize_x + eX * 0.5 * mySize_x;
				} else { // down align
					picpos = pos + eX * 0.05 * mySize_x + eY * (mySize_y - 0.65 * mySize_x) + eX * 0.5 * mySize_x;
					numpos = pos + eY * mySize_y - eY * 0.25 * mySize_x + eX * 0.5 * mySize_x;
				}

				if(progressbar)
				{
					HUD_Panel_GetProgressBarColorForString(rightname);
                    HUD_Panel_DrawProgressBar(barpos, barsize, rightprogressname, 1, barflip, min(1, rightcnt/rightmax), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				}
                if(autocvar_hud_panel_healtharmor_text)
                {
                    drawpic_aspect_skin(picpos, rightname, '0.4 0.4 0' * mySize_x, '1 1 1', rightalpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawstring_aspect(numpos, ftos(rightcnt), eX * 0.5 * mySize_x + eY * 0.25 * mySize_x, HUD_Get_Num_Color(rightcnt, rightmax), panel_fg_alpha, DRAWFLAG_NORMAL);
                }
			}

			if(fuel)
			{
                barpos = pos;
                barsize = eX * 0.05 * mySize_x + eY * mySize_y;
                HUD_Panel_GetProgressBarColor(fuel);
                HUD_Panel_DrawProgressBar(barpos, barsize, "progressbar", 1, mod(baralign, 2), min(1, fuel/100), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
			}
		}
	}
	drawfont = hud_font;
}

// Notification area (#4)
//

string Weapon_SuicideMessage(float deathtype)
{
	w_deathtype = deathtype;
	get_weaponinfo(DEATH_WEAPONOF(deathtype)).weapon_func(WR_SUICIDEMESSAGE);
	return w_deathtypestring;
}

string Weapon_KillMessage(float deathtype)
{
	w_deathtype = deathtype;
	get_weaponinfo(DEATH_WEAPONOF(deathtype)).weapon_func(WR_KILLMESSAGE);
	return w_deathtypestring;
}

#define KN_MAX_ENTRIES 10
float kn_index;
float killnotify_times[KN_MAX_ENTRIES];
float killnotify_deathtype[KN_MAX_ENTRIES];
float killnotify_actiontype[KN_MAX_ENTRIES]; // 0 = "Y [used by] X", 1 = "X [did action to] Y"
string killnotify_attackers[KN_MAX_ENTRIES];
string killnotify_victims[KN_MAX_ENTRIES];
void HUD_KillNotify_Push(string attacker, string victim, float actiontype, float wpn)
{
	--kn_index;
	if (kn_index == -1)
		kn_index = KN_MAX_ENTRIES-1;
	killnotify_times[kn_index] = time;
	killnotify_deathtype[kn_index] = wpn;
	killnotify_actiontype[kn_index] = actiontype;
	if(killnotify_attackers[kn_index])
		strunzone(killnotify_attackers[kn_index]);
	killnotify_attackers[kn_index] = strzone(attacker);
	if(killnotify_victims[kn_index])
		strunzone(killnotify_victims[kn_index]);
	killnotify_victims[kn_index] = strzone(victim);
}

void HUD_KillNotify(string s1, string s2, string s3, float type, float msg) // s1 = attacker, s2 = victim
{
	float w;
	float alsoprint, gentle;
	alsoprint = (autocvar_hud_panel_notify_print || !panel_enabled); // print message to console if: notify panel disabled, or cvar to do so enabled
	gentle = (autocvar_cl_gentle || autocvar_cl_gentle_messages);
	
	if ((msg == MSG_SUICIDE || msg == MSG_KILL || msg == MSG_KILL_ACTION) && gametype == GAME_CTS) // selfkill isn't interesting in CTS and only spams up the notify panel
		return;

	if(msg == MSG_SUICIDE) {
		w = DEATH_WEAPONOF(type);
		if(WEP_VALID(w)) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print("^1", sprintf(Weapon_SuicideMessage(type), strcat(s1, "^1")), "\n");
		} else if (type == DEATH_KILL) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_KILL);
			if (alsoprint)
				print ("^1",s1, "^1 couldn't take it anymore\n");
		} else if (type == DEATH_ROT) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print ("^1",s1, "^1 died\n");
		} else if (type == DEATH_NOAMMO) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_NOAMMO);
			if (alsoprint)
				print ("^7",s1, "^7 committed suicide. What's the point of living without ammo?\n");
		} else if (type == DEATH_CAMP) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_CAMP);
			if (alsoprint)
				print ("^1",s1, "^1 thought they found a nice camping ground\n");
		} else if (type == KILL_TEAM_RED || type == KILL_TEAM_BLUE) {
			HUD_KillNotify_Push(s1, "", 0, type);
			if (alsoprint)
				print ("^1",s1, "^1 didn't become friends with the Lord of Teamplay\n");
		} else if (type == DEATH_CHEAT) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print ("^1",s1, "^1 unfairly eliminated themself\n");
		} else if (type == DEATH_FIRE) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print ("^1",s1, "^1 burned to death\n");
		} else if (type != DEATH_TEAMCHANGE && type != DEATH_QUIET) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print ("^1",s1, "^1 couldn't resist the urge to self-destruct\n");
		} 
		
		if (stof(s2) > 2) // killcount > 2
			print ("^1",s1,"^1 ended it all after a ",s2," kill spree\n");
	} else if(msg == MSG_KILL) {
		w = DEATH_WEAPONOF(type);
		if(WEP_VALID(w)) {
			if((w == WEP_CAMPINGRIFLE || w == WEP_MINSTANEX) && type & HITTYPE_HEADSHOT) // all headshot weapons go here
				HUD_KillNotify_Push(s1, s2, 1, DEATH_HEADSHOT);
			else
				HUD_KillNotify_Push(s1, s2, 1, type);

			if (alsoprint)
				print("^1", sprintf(Weapon_KillMessage(type), strcat(s2, "^1"), strcat(s1, "^1")), "\n"); // default order: victim, killer
		}
		else if(type == KILL_TEAM_RED || type == KILL_TEAM_BLUE || type == KILL_TEAM_SPREE) {
			HUD_KillNotify_Push(s1, s2, 1, type);
			if(alsoprint)
			{
				if(gentle) {
					print ("^1", s1, "^1 took action against a team mate\n");
				} else {
					print ("^1", s1, "^1 mows down a team mate\n");
				}
			}
			if (stof(s2) > 2 && type == KILL_TEAM_SPREE) {
				if(gentle)
					print ("^1",s1,"^1 ended a ",s3," scoring spree by going against a team mate\n");
				else
					print ("^1",s1,"^1 ended a ",s3," kill spree by killing a team mate\n");
			}
			else if (stof(s2) > 2) {
				if(gentle)
					print ("^1",s1,"'s ^1",s3," scoring spree was ended by a team mate!\n");
				else
					print ("^1",s1,"'s ^1",s3," kill spree was ended by a team mate!\n");
			}
		}
		else if(type == KILL_FIRST_BLOOD)
			print("^1",s1, "^1 drew first blood", "\n");
		else if (type == DEATH_TELEFRAG) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_TELEFRAG);
			if(gentle)
				print ("^1",s2, "^1 tried to occupy ", s1, "^1's teleport destination space\n");
			else
				print ("^1",s2, "^1 was telefragged by ", s1, "\n");
		}
		else if (type == DEATH_DROWN) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_DROWN);
			if(alsoprint)
				print ("^1",s2, "^1 was drowned by ", s1, "\n");
		}
		else if (type == DEATH_SLIME) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_SLIME);
			if(alsoprint)
				print ("^1",s2, "^1 was slimed by ", s1, "\n");
		}
		else if (type == DEATH_LAVA) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_LAVA);
			if(alsoprint)
				print ("^1",s2, "^1 was cooked by ", s1, "\n");
		}
		else if (type == DEATH_FALL) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_FALL);
			if(alsoprint)
				print ("^1",s2, "^1 was grounded by ", s1, "\n");
		}
		else if (type == DEATH_SHOOTING_STAR) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_SHOOTING_STAR);
			if(alsoprint)
				print ("^1",s2, "^1 was shot into space by ", s1, "\n");
		}
		else if (type == DEATH_SWAMP) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was conserved by ", s1, "\n");
		}
		else if (type == DEATH_HURTTRIGGER)
		{
			HUD_KillNotify_Push(s1, s2, 1, DEATH_HURTTRIGGER);
			if(alsoprint)
				print("^1",s2, "^1 was thrown into a world of hurt by ", s1, "\n");
		} else if(type == DEATH_SBCRUSH) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was crushed by ^1", s1, "\n");
		} else if(type == DEATH_SBMINIGUN) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 got shredded by ^1", s1, "\n");
		} else if(type == DEATH_SBROCKET) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was blased to bits by ^1", s1, "\n");
		} else if(type == DEATH_SBBLOWUP) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 got caught in the destruction of ^1", s1, "'s vehicle\n");
		} else if(type == DEATH_WAKIGUN) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was bolted down by ^1", s1, "\n");
		} else if(type == DEATH_WAKIROCKET) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 could find no shelter from ^1", s1, "'s rockets\n");
		} else if(type == DEATH_WAKIBLOWUP) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 dies when ^1", s1, "'s wakizashi dies.\n");
		} else if(type == DEATH_TURRET) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was pushed into the line of fire by ^1", s1, "\n");
		} else if(type == DEATH_TOUCHEXPLODE) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was pushed into an accident by ^1", s1, "\n");
		} else if(type == DEATH_CHEAT) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was unfairly eliminated by ^1", s1, "\n");
		} else if (type == DEATH_FIRE) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was burnt to death by ^1", s1, "\n");
		} else if (type == DEATH_CUSTOM) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_CUSTOM);
			if(alsoprint)
				print("^1", sprintf(s3, strcat(s2, "^1"), strcat(s1, "^1")), "\n");
		} else if (type == DEATH_HURTTRIGGER) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_HURTTRIGGER);
			if(alsoprint)
				print("^1", sprintf(s3, strcat(s2, "^1"), strcat(s1, "^1")), "\n");
		} else {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s2, "^1 was fragged by ", s1, "\n");
		}
	} else if(msg == MSG_SPREE) {
		if(type == KILL_END_SPREE) {
			if(gentle)
				print ("^1",s1,"'s ^1", s2, " scoring spree was ended by ", s3, "\n");
			else
				print ("^1",s1,"'s ^1", s2, " kill spree was ended by ", s3, "\n");
		} else if(type == KILL_SPREE) {
			if(gentle)
				print ("^1",s1,"^1 made ",s2," scores in a row\n");
			else
				print ("^1",s1,"^1 has ",s2," frags in a row\n");
		} else if(type == KILL_SPREE_3) {
			if(gentle)
				print (s1,"^7 made a ^1TRIPLE SCORE\n");
			else
				print (s1,"^7 made a ^1TRIPLE FRAG\n");
		} else if(type == KILL_SPREE_5) {
			if(gentle)
				print (s1,"^7 unleashes ^1SCORING RAGE\n");
			else
				print (s1,"^7 unleashes ^1RAGE\n");
		} else if(type == KILL_SPREE_10) {
			if(gentle)
				print (s1,"^7 made ^1TEN SCORES IN A ROW!\n");
			else
				print (s1,"^7 starts the ^1MASSACRE!\n");
		} else if(type == KILL_SPREE_15) {
			if(gentle)
				print (s1,"^7 made ^1FIFTEEN SCORES IN A ROW!\n");
			else
				print (s1,"^7 executes ^1MAYHEM!\n");
		} else if(type == KILL_SPREE_20) {
			if(gentle)
				print (s1,"^7 made ^1TWENTY SCORES IN A ROW!\n");
			else
				print (s1,"^7 is a ^1BERSERKER!\n");
		} else if(type == KILL_SPREE_25) {
			if(gentle)
				print (s1,"^7 made ^1TWENTY FIFE SCORES IN A ROW!\n");
			else
				print (s1,"^7 inflicts ^1CARNAGE!\n");
		} else if(type == KILL_SPREE_30) {
			if(gentle)
				print (s1,"^7 made ^1THIRTY SCORES IN A ROW!\n");
			else
				print (s1,"^7 unleashes ^1ARMAGEDDON!\n");
		}
	} else if(msg == MSG_KILL_ACTION) { // wtf is this? isnt it basically the same as MSG_SUICIDE?
		if (type == DEATH_DROWN) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_DROWN);
			if(alsoprint)
			{
				if(gentle)
					print ("^1",s1, "^1 was in the water for too long\n");
				else
					print ("^1",s1, "^1 drowned\n");
			}
		} else if (type == DEATH_SLIME) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_SLIME);
			if(alsoprint)
				print ("^1",s1, "^1 was slimed\n");
		} else if (type == DEATH_LAVA) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_LAVA);
			if(alsoprint)
			{
				if(gentle)
					print ("^1",s1, "^1 found a hot place\n");
				else
					print ("^1",s1, "^1 turned into hot slag\n");
			}
		} else if (type == DEATH_FALL) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print ("^1",s1, "^1 tested gravity (and it worked)\n");
				else
					print ("^1",s1, "^1 hit the ground with a crunch\n");
			}
		} else if (type == DEATH_SHOOTING_STAR) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_SHOOTING_STAR);
			if(alsoprint)
				print ("^1",s1, "^1 became a shooting star\n");
		} else if (type == DEATH_SWAMP) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print ("^1",s1, "^1 discovered a swamp\n");
				else
					print ("^1",s1, "^1 is now conserved for centuries to come\n");
			}
		} else if(type == DEATH_TURRET) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s1, "^1 was mowed down by a turret \n");
		} else if (type == DEATH_CUSTOM) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_CUSTOM);
			if(alsoprint)
				print("^1", sprintf(s2, strcat(s1, "^1")), "\n");
		} else if (type == DEATH_HURTTRIGGER) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_HURTTRIGGER);
			if(alsoprint)
				print("^1", sprintf(s2, strcat(s1, "^1")), "\n");
		} else if(type == DEATH_TOUCHEXPLODE) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s1, "^1 died in an accident\n");
		} else if(type == DEATH_CHEAT) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
				print ("^1",s1, "^1 was unfairly eliminated\n");
		} else if(type == DEATH_FIRE) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print ("^1",s1, "^1 felt a little hot\n");
				else
					print ("^1",s1, "^1 burnt to death\n");
				}
		} else {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print ("^1",s1, "^1 needs a restart\n");
				else
					print ("^1",s1, "^1 died\n");
			}
		}
	} else if(msg == MSG_KILL_ACTION_SPREE) {
		if(gentle)
			print ("^1",s1,"^1 needs a restart after a ",s2," scoring spree\n");
		else
			print ("^1",s1,"^1 died with a ",s2," kill spree\n");
	} else if(msg == MSG_INFO) {
		if(type == INFO_GOTFLAG) { // here, s2 is the flag name
			HUD_KillNotify_Push(s1, s2, 0, INFO_GOTFLAG);
			print(s1, "^7 got the ", s2, "\n");
		} else if(type == INFO_LOSTFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_LOSTFLAG);
			print(s1, "^7 lost the ", s2, "\n");
		} else if(type == INFO_PICKUPFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_GOTFLAG);
			print(s1, "^7 picked up the ", s2, "\n");
		} else if(type == INFO_RETURNFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_RETURNFLAG);
			print(s1, "^7 returned the ", s2, "\n");
		} else if(type == INFO_CAPTUREFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_CAPTUREFLAG);
			print(s1, "^7 captured the ", s2, s3, "\n");
		}
	} else if(msg == MSG_RACE) {
		if(type == RACE_SERVER_RECORD) {
			HUD_KillNotify_Push(s1, s2, 1, RACE_SERVER_RECORD);
		}
		else if(type == RACE_NEW_RANK) {
			HUD_KillNotify_Push(s1, s2, 1, RACE_NEW_RANK);
		}
		else if(type == RACE_NEW_TIME) {
			HUD_KillNotify_Push(s1, s2, 1, RACE_NEW_TIME);
		}
		else if(type == RACE_FAIL) {
			HUD_KillNotify_Push(s1, s2, 1, RACE_FAIL);
		}
	} else if(msg == MSG_KA) {
		if(type == KA_PICKUPBALL) {
			HUD_KillNotify_Push(s1, s2, 0, KA_PICKUPBALL);
			if(alsoprint)
				print (s1, "^7 has picked up the ball!\n");
		}
		else if(type == KA_DROPBALL) {
			HUD_KillNotify_Push(s1, s2, 0, KA_DROPBALL);
			if(alsoprint)
				print(s1, "^7 has dropped the ball!\n");
		}
	}
}

#define DAMAGE_CENTERPRINT_SPACER NEWLINES

void HUD_Centerprint(string s1, string s2, float type, float msg)
{
	float gentle;
	gentle = (autocvar_cl_gentle || autocvar_cl_gentle_messages);
	if(msg == MSG_SUICIDE) {
		if (type == DEATH_TEAMCHANGE) {
			centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "You are now on: ", s1));
		} else if (type == DEATH_AUTOTEAMCHANGE) {
			centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "You have been moved into a different team to improve team balance\nYou are now on: ", s1));
		} else if (type == DEATH_CAMP) {
			if(gentle)
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Reconsider your tactics, camper!"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Die camper!"));
		} else if (type == DEATH_NOAMMO) {
			if(gentle)
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You are reinserted into the game for running out of ammo..."));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were killed for running out of ammo..."));
		} else if (type == DEATH_ROT) {
			if(gentle)
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You need to preserve your health"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You grew too old without taking your medicine"));
		} else if (type == KILL_TEAM_RED || type == KILL_TEAM_BLUE) {
			if(gentle)
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't go against team mates!"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't shoot your team mates!"));
		} else if (type == DEATH_QUIET) {
			// do nothing
		} else { // generic message
			if(gentle)
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You need to be more careful!"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You killed your own dumb self!"));
		}
	} else if(msg == MSG_KILL) {
		if (type == KILL_TEAM_RED || type == KILL_TEAM_BLUE) {
			if(gentle) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You went against", s1, ",a team mate!"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You fragged ", s1, ", a team mate!"));
			}
		} else if (type == KILL_FIRST_BLOOD) {
			if(gentle) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First score"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First blood"));
			}
		} else if (type == KILL_FIRST_VICTIM) {
			if(gentle) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First casualty"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First victim"));
			}
		} else if (type == KILL_TYPEFRAG) { // s2 contains "advanced kill messages" such as ping, handicap...
			if(gentle) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You scored against ^7", s1, "^1 who was typing!", s2));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You typefragged ^7", s1, s2));
			}
		} else if (type == KILL_TYPEFRAGGED) {
			if(gentle) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were scored against by ^7", s1, "^1 while you were typing!", s2));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were typefragged by ^7", s1, s2));
			}
		} else if (type == KILL_FRAG) {
			if(gentle) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^4You scored against ^7", s1, s2));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^4You fragged ^7", s1, s2));
			}
		} else { // generic message
			if(gentle) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were scored against by ^7", s1, s2));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were fragged by ^7", s1, s2));
			}
		}
	} else if(msg == MSG_KILL_ACTION) {
		// TODO: invent more centerprints here?
		centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Watch your step!"));
	}
}

void HUD_Notify (void)
{
	if(!autocvar_hud_panel_notify && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_NOTIFY;
	HUD_Panel_UpdateCvars(notify);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float entries, height;
	entries = bound(1, floor(KN_MAX_ENTRIES * mySize_y/mySize_x), KN_MAX_ENTRIES);
	height = mySize_y/entries;
	
	vector fontsize;
	fontsize = '0.5 0.5 0' * height;

	float a;
	float when;
	when = autocvar_hud_panel_notify_time;
	float fadetime;
	fadetime = autocvar_hud_panel_notify_fadetime;

	string s;

	vector pos_attacker, pos_victim;
	vector weap_pos;
	float width_attacker;
	string attacker, victim;

	float i, j, w, step, limit;
	if(autocvar_hud_panel_notify_flip) //order items from the top down
	{
		i = 0;
		step = +1;
		limit = entries;
	}
	else //order items from the bottom up
	{
		i = entries - 1;
		step = -1;
		limit = -1;
	}

	for(j = kn_index;  i != limit;  i += step, ++j)
	{
		if(autocvar__hud_configure)
		{
			if (step == +1)
				a = i;
			else // inverse order
				a = entries - 1 - i;
			attacker = textShortenToWidth(strcat("Player", ftos(a+1)), 0.48 * mySize_x - height, fontsize, stringwidth_colors);
			victim = textShortenToWidth(strcat("Player", ftos(a+2)), 0.48 * mySize_x - height, fontsize, stringwidth_colors);
			s = strcat("weapon", get_weaponinfo(WEP_FIRST + mod(floor(a*2.4), WEP_LAST)).netname);
			a = bound(0, (when - a) / 4, 1);
			goto hud_config_notifyprint;
		}

		if (j == KN_MAX_ENTRIES)
			j = 0;

		if(killnotify_times[j] + when > time)
			a = 1;
		else if(fadetime)
		{
			a = bound(0, (killnotify_times[j] + when + fadetime - time) / fadetime, 1);
			if(!a)
			{
				break;
			}
		}
		else
		{
			break;
		}

		s = "";

		w = -1;
		w = DEATH_WEAPONOF(killnotify_deathtype[j]);

		// TODO: maybe print in team colors?
		//
		// Y [used by] X
		if(killnotify_actiontype[j] == 0) 
		{
			if(killnotify_deathtype[j] == DEATH_GENERIC)
			{
				s = "notify_death";
			}
			else if(killnotify_deathtype[j] == DEATH_NOAMMO)
			{
				s = "notify_outofammo";
			}
			else if(killnotify_deathtype[j] == DEATH_KILL)
			{
				s = "notify_selfkill";
			}
			else if(killnotify_deathtype[j] == DEATH_CAMP)
			{
				s = "notify_camping";
			}
			else if(killnotify_deathtype[j] == KILL_TEAM_RED)
			{
				s = "notify_teamkill_red";
			}
			else if(killnotify_deathtype[j] == KILL_TEAM_BLUE)
			{
				s = "notify_teamkill_blue";
			}
			else if(killnotify_deathtype[j] == DEATH_DROWN)
			{
				s = "notify_water";
			}
			else if(killnotify_deathtype[j] == DEATH_SLIME)
			{
				s = "notify_slime";
			}
			else if(killnotify_deathtype[j] == DEATH_LAVA)
			{
				s = "notify_lava";
			}
			else if(killnotify_deathtype[j] == DEATH_FALL)
			{
				s = "notify_fall";
			}
			else if(killnotify_deathtype[j] == DEATH_SHOOTING_STAR)
			{
				s = "notify_shootingstar";
			}
			else if(killnotify_deathtype[j] == DEATH_HURTTRIGGER || killnotify_deathtype[j] == DEATH_CUSTOM)
			{
				s = "notify_death";
			}
			else if(killnotify_deathtype[j] == INFO_GOTFLAG)
			{
				if(killnotify_victims[j] == "^1RED^7 flag")
				{
					s = "notify_red_taken";
				}
				else
				{
					s = "notify_blue_taken";
				}
			}
			else if(killnotify_deathtype[j] == INFO_RETURNFLAG)
			{
				if(killnotify_victims[j] == "^1RED^7 flag")
				{
					s = "notify_red_returned";
				}
				else
				{
					s = "notify_blue_returned";
				}
			}
			else if(killnotify_deathtype[j] == INFO_LOSTFLAG)
			{
				if(killnotify_victims[j] == "^1RED^7 flag")
				{
					s = "notify_red_lost";
				}
				else
				{
					s = "notify_blue_lost";
				}
			}
			else if(killnotify_deathtype[j] == INFO_CAPTUREFLAG)
			{
				if(killnotify_victims[j] == "^1RED^7 flag")
				{
					s = "notify_red_captured";
				}
				else
				{
					s = "notify_blue_captured";
				}
			}
			else if(killnotify_deathtype[j] == KA_DROPBALL)
			{
				s = "notify_balldropped";
			}
			else if(killnotify_deathtype[j] == KA_PICKUPBALL)
			{
				s = "notify_ballpickedup";
			}
			
			attacker = textShortenToWidth(killnotify_attackers[j], 0.48 * mySize_x - height, fontsize, stringwidth_colors);
			pos_attacker = pos + eX * (0.52 * mySize_x + height) + eY * (0.5 * fontsize_y + i * height);
			weap_pos = pos + eX * 0.5 * mySize_x - eX * height + eY * i * height;

			if(s != "")
			{
				drawpic_aspect_skin(weap_pos, s, '2 1 0' * height, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}
		// X [did action to] Y
		else
		{
			if(killnotify_deathtype[j] & HITTYPE_SECONDARY && w == WEP_LASER)
			{
				s = "notify_melee_laser";
			}
			else if(killnotify_deathtype[j] & HITTYPE_SECONDARY && w == WEP_SHOTGUN)
			{
				s = "notify_melee_shotgun";
			}
			else if(WEP_VALID(w))
			{
				self = get_weaponinfo(w);
				s = strcat("weapon", self.netname);
			}
			else if(killnotify_deathtype[j] == KILL_TEAM_RED)
			{
				s = "notify_teamkill_red";
			}
			else if(killnotify_deathtype[j] == KILL_TEAM_BLUE)
			{
				s = "notify_teamkill_red";
			}
			else if(killnotify_deathtype[j] == DEATH_TELEFRAG)
			{
				s = "notify_telefrag";
			}
			else if(killnotify_deathtype[j] == DEATH_DROWN)
			{
				s = "notify_water";
			}
			else if(killnotify_deathtype[j] == DEATH_SLIME)
			{
				s = "notify_slime";
			}
			else if(killnotify_deathtype[j] == DEATH_LAVA)
			{
				s = "notify_lava";
			}
			else if(killnotify_deathtype[j] == DEATH_FALL)
			{
				s = "notify_fall";
			}
			else if(killnotify_deathtype[j] == DEATH_SHOOTING_STAR)
			{
				s = "notify_shootingstar";
			}
			else if(killnotify_deathtype[j] == DEATH_HURTTRIGGER || killnotify_deathtype[j] == DEATH_CUSTOM) // DEATH_CUSTOM is also void, right?
			{
				s = "notify_void";
			}
			else if(killnotify_deathtype[j] == DEATH_HEADSHOT)
			{
				s = "notify_headshot";
			}
			else if(killnotify_deathtype[j] == RACE_SERVER_RECORD)
			{
				s = "race_newrecordserver";
			}
			else if(killnotify_deathtype[j] == RACE_NEW_RANK)
			{
				s = "race_newrankyellow";
			}
			else if(killnotify_deathtype[j] == RACE_NEW_TIME)
			{
				s = "race_newtime";
			}
			else if(killnotify_deathtype[j] == RACE_FAIL)
			{
				s = "race_newfail";
			}

			attacker = textShortenToWidth(killnotify_attackers[j], 0.48 * mySize_x - height, fontsize, stringwidth_colors);
			victim = textShortenToWidth(killnotify_victims[j], 0.48 * mySize_x - height, fontsize, stringwidth_colors);
:hud_config_notifyprint
			width_attacker = stringwidth(attacker, TRUE, fontsize);
			pos_attacker = pos + eX * (0.48 * mySize_x - height - width_attacker) + eY * (0.5 * fontsize_y + i * height);
			pos_victim = pos + eX * (0.52 * mySize_x + height) + eY * (0.5 * fontsize_y + i * height);
			weap_pos = pos + eX * 0.5 * mySize_x - eX * height + eY * i * height;

			if(s != "")
			{
				drawpic_aspect_skin(weap_pos, s, '2 1 0' * height, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_victim, victim, fontsize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}
	}
}

// Timer (#5)
//
// TODO: macro
string seconds_tostring(float sec)
{
	float minutes;
	minutes = floor(sec / 60);

	sec -= minutes * 60;

	string s;
	s = ftos(100 + sec);

	return strcat(ftos(minutes), ":", substring(s, 1, 3));
}

void HUD_Timer(void)
{
	if(!autocvar_hud_panel_timer && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_TIMER;
	HUD_Panel_UpdateCvars(timer);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	string timer;
	float timelimit, elapsedTime, timeleft, minutesLeft;

	timelimit = getstatf(STAT_TIMELIMIT);

	timeleft = max(0, timelimit * 60 + getstatf(STAT_GAMESTARTTIME) - time);
	timeleft = ceil(timeleft);

	minutesLeft = floor(timeleft / 60);

	vector timer_color;
	if(minutesLeft >= 5 || warmup_stage || timelimit == 0) //don't use red or yellow in warmup or when there is no timelimit
		timer_color = '1 1 1'; //white
	else if(minutesLeft >= 1)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red

	if (autocvar_hud_panel_timer_increment || timelimit == 0 || warmup_stage) {
		if (time < getstatf(STAT_GAMESTARTTIME)) {
			//while restart is still active, show 00:00
			timer = seconds_tostring(0);
		} else {
			elapsedTime = floor(time - getstatf(STAT_GAMESTARTTIME)); //127
			timer = seconds_tostring(elapsedTime);
		}
	} else {
		timer = seconds_tostring(timeleft);
	}

	drawfont = hud_bigfont;
	drawstring_aspect(pos, timer, mySize, timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	drawfont = hud_font;
}

// Radar (#6)
//
void HUD_Radar(void)
{
	if ((autocvar_hud_panel_radar == 0 || (autocvar_hud_panel_radar != 2 && !teamplay)) && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_RADAR;
	HUD_Panel_UpdateCvars(radar);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	local float color1, color2; // color already declared as a global in hud.qc
	local vector rgb;
	local entity tm;
	float scale2d, normalsize, bigsize;
	float f;

	teamradar_origin2d = pos + 0.5 * mySize;
	teamradar_size2d = mySize;

	if(minimapname == "")
		return;

	teamradar_loadcvars();

	switch(hud_panel_radar_zoommode)
	{
		default:
		case 0:
			f = current_zoomfraction;
			break;
		case 1:
			f = 1 - current_zoomfraction;
			break;
		case 2:
			f = 0;
			break;
		case 3:
			f = 1;
			break;
	}

	switch(hud_panel_radar_rotation)
	{
		case 0:
			teamradar_angle = view_angles_y - 90;
			break;
		default:
			teamradar_angle = 90 * hud_panel_radar_rotation;
			break;
	}

	scale2d = vlen_maxnorm2d(mi_picmax - mi_picmin);
	teamradar_size2d = mySize;

	teamradar_extraclip_mins = teamradar_extraclip_maxs = '0 0 0'; // we always center

	// pixels per world qu to match the teamradar_size2d_x range in the longest dimension
	if(hud_panel_radar_rotation == 0)
	{
		// max-min distance must fit the radar in any rotation
		bigsize = vlen_minnorm2d(teamradar_size2d) * scale2d / (1.05 * vlen2d(mi_scale));
	}
	else
	{
		vector c0, c1, c2, c3, span;
		c0 = rotate(mi_min, teamradar_angle * DEG2RAD);
		c1 = rotate(mi_max, teamradar_angle * DEG2RAD);
		c2 = rotate('1 0 0' * mi_min_x + '0 1 0' * mi_max_y, teamradar_angle * DEG2RAD);
		c3 = rotate('1 0 0' * mi_max_x + '0 1 0' * mi_min_y, teamradar_angle * DEG2RAD);
		span = '0 0 0';
		span_x = max4(c0_x, c1_x, c2_x, c3_x) - min4(c0_x, c1_x, c2_x, c3_x);
		span_y = max4(c0_y, c1_y, c2_y, c3_y) - min4(c0_y, c1_y, c2_y, c3_y);

		// max-min distance must fit the radar in x=x, y=y
		bigsize = min(
			teamradar_size2d_x * scale2d / (1.05 * span_x),
			teamradar_size2d_y * scale2d / (1.05 * span_y)
		);
	}

	normalsize = vlen_maxnorm2d(teamradar_size2d) * scale2d / hud_panel_radar_scale;
	if(bigsize > normalsize)
		normalsize = bigsize;

	teamradar_size =
		  f * bigsize
		+ (1 - f) * normalsize;
	teamradar_origin3d_in_texcoord = teamradar_3dcoord_to_texcoord(
		  f * mi_center
		+ (1 - f) * view_origin);

	color1 = GetPlayerColor(player_localentnum-1);
	rgb = GetTeamRGB(color1);

	drawsetcliparea(
		pos_x,
		pos_y,
		mySize_x,
		mySize_y
	);

	draw_teamradar_background(hud_panel_radar_foreground_alpha);

	for(tm = world; (tm = find(tm, classname, "radarlink")); )
		draw_teamradar_link(tm.origin, tm.velocity, tm.team);
	for(tm = world; (tm = findflags(tm, teamradar_icon, 0xFFFFFF)); )
		draw_teamradar_icon(tm.origin, tm.teamradar_icon, tm, tm.teamradar_color, panel_fg_alpha);
	for(tm = world; (tm = find(tm, classname, "entcs_receiver")); )
	{
		color2 = GetPlayerColor(tm.sv_entnum);
		//if(color == COLOR_SPECTATOR || color == color2)
			draw_teamradar_player(tm.origin, tm.angles, GetTeamRGB(color2));
	}
	draw_teamradar_player(view_origin, view_angles, '1 1 1');

	drawresetcliparea();
};

// Score (#7)
//
void HUD_Score(void)
{
	if(!autocvar_hud_panel_score && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_SCORE;
	HUD_Panel_UpdateCvars(score);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float score, distribution, leader;
	string sign;
	vector distribution_color;
	entity tm, pl, me;
	me = (spectatee_status > 0) ? playerslots[spectatee_status - 1] : playerslots[player_localentnum - 1];

	if((scores_flags[ps_primary] & SFL_TIME) && !teamplay) { // race/cts record display on HUD
		string timer, distrtimer;

		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;
		if(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)
			if(pl.scores[ps_primary] == 0)
				pl = world;

		score = me.(scores[ps_primary]);
		timer = TIME_ENCODED_TOSTRING(score);

		if (pl && ((!(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)) || score)) {
			// distribution display
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);

			distrtimer = ftos_decimals(fabs(distribution/pow(10, TIME_DECIMALS)), TIME_DECIMALS);

			if (distribution <= 0) {
				distribution_color = '0 1 0';
				sign = "-";
			}
			else {
				distribution_color = '1 0 0';
				sign = "+";
			}
			drawstring_aspect(pos + eX * 0.75 * mySize_x, strcat(sign, distrtimer), eX * 0.25 * mySize_x + eY * (1/3) * mySize_y, distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		// race record display
		if (distribution <= 0)
			HUD_Panel_DrawHighlight(pos, eX * 0.75 * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawfont = hud_bigfont;
		drawstring_aspect(pos, timer, eX * 0.75 * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawfont = hud_font;
	} else if (!teamplay) { // non-teamgames
		// me vector := [team/connected frags id]
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;

		if(autocvar__hud_configure)
			distribution = 42;
		else if(pl)
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);
		else
			distribution = 0;

		score = me.(scores[ps_primary]);
		if(autocvar__hud_configure)
			score = 123;

		if(distribution >= 5) {
			distribution_color = eY;
			leader = 1;
		} else if(distribution >= 0) {
			distribution_color = '1 1 1';
			leader = 1;
		} else if(distribution >= -5)
			distribution_color = '1 1 0';
		else
			distribution_color = eX;

		drawstring_aspect(pos + eX * 0.75 * mySize_x, ftos(distribution), eX * 0.25 * mySize_x + eY * (1/3) * mySize_y, distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		if (leader)
			HUD_Panel_DrawHighlight(pos, eX * 0.75 * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawfont = hud_bigfont;
		drawstring_aspect(pos, ftos(score), eX * 0.75 * mySize_x + eY * mySize_y, distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		drawfont = hud_font;
	} else { // teamgames
		float max_fragcount;
		max_fragcount = -99;

		float teamnum;
		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == COLOR_SPECTATOR || (!tm.team_size && !autocvar__hud_configure)) // no players? don't display
				continue;
			score = tm.(teamscores[ts_primary]);
			if(autocvar__hud_configure)
				score = 123;
			leader = 0;
			
			if (score > max_fragcount)
				max_fragcount = score;

			if(tm.team == myteam) {
				if (max_fragcount == score)
					leader = 1;
				if (leader)
					HUD_Panel_DrawHighlight(pos, eX * 0.75 * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawfont = hud_bigfont;
				drawstring_aspect(pos, ftos(score), eX * 0.75 * mySize_x + eY * mySize_y, GetTeamRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
				drawfont = hud_font;
			} else {
				if (max_fragcount == score)
					leader = 1;
				if (leader)
					HUD_Panel_DrawHighlight(pos + eX * 0.75 * mySize_x + eY * (1/3) * teamnum * mySize_y, eX * 0.25 * mySize_x + eY * (1/3) * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(pos + eX * 0.75 * mySize_x + eY * (1/3) * teamnum * mySize_y, ftos(score), eX * 0.25 * mySize_x + eY * (1/3) * mySize_y, GetTeamRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
				teamnum += 1;
			}
		}
	}
}

// Race timer (#8)
//
void HUD_RaceTimer (void) {
	if(!autocvar_hud_panel_racetimer && !(gametype == GAME_RACE || gametype == GAME_CTS) && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_RACETIMER;
	HUD_Panel_UpdateCvars(racetimer);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// always force 4:1 aspect
	vector newSize;
	if(mySize_x/mySize_y > 4)
	{
		newSize_x = 4 * mySize_y;
		newSize_y = mySize_y;

		pos_x = pos_x + (mySize_x - newSize_x) / 2;
	}
	else
	{
		newSize_y = 1/4 * mySize_x;
		newSize_x = mySize_x;

		pos_y = pos_y + (mySize_y - newSize_y) / 2;
	}
	mySize = newSize;

	drawfont = hud_bigfont;
	float a, t;
	string s, forcetime;

	if(autocvar__hud_configure)
	{
		s = "0:13:37";
		drawstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, FALSE, '0.60 0.60 0' * mySize_y), s, '0.60 0.60 0' * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		s = "^1Intermediate 1 (+15.42)";
		drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.20 * mySize_y) + eY * 0.60 * mySize_y, s, '1 1 0' * 0.20 * mySize_y, panel_fg_alpha, DRAWFLAG_NORMAL);
		s = strcat("^1PENALTY: ", ftos_decimals(20 * 0.1, 1), " (missing a checkpoint)");
		drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.20 * mySize_y) + eY * 0.80 * mySize_y, s, '1 1 0' * 0.20 * mySize_y, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else if(race_checkpointtime)
	{
		a = bound(0, 2 - (time - race_checkpointtime), 1);
		s = "";
		forcetime = "";
		if(a > 0) // just hit a checkpoint?
		{
			if(race_checkpoint != 254)
			{
				if(race_time && race_previousbesttime)
					s = MakeRaceString(race_checkpoint, TIME_DECODE(race_time) - TIME_DECODE(race_previousbesttime), 0, 0, race_previousbestname);
				else
					s = MakeRaceString(race_checkpoint, 0, -1, 0, race_previousbestname);
				if(race_time)
					forcetime = TIME_ENCODED_TOSTRING(race_time);
			}
		}
		else
		{
			if(race_laptime && race_nextbesttime && race_nextcheckpoint != 254)
			{
				a = bound(0, 2 - ((race_laptime + TIME_DECODE(race_nextbesttime)) - (time + TIME_DECODE(race_penaltyaccumulator))), 1);
				if(a > 0) // next one?
				{
					s = MakeRaceString(race_nextcheckpoint, (time + TIME_DECODE(race_penaltyaccumulator)) - race_laptime, TIME_DECODE(race_nextbesttime), 0, race_nextbestname);
				}
			}
		}

		if(s != "" && a > 0)
		{
			drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.2 * mySize_y) + eY * 0.6 * mySize_y, s, '1 1 0' * 0.2 * mySize_y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		if(race_penaltytime)
		{
			a = bound(0, 2 - (time - race_penaltyeventtime), 1);
			if(a > 0)
			{
				s = strcat("^1PENALTY: ", ftos_decimals(race_penaltytime * 0.1, 1), " (", race_penaltyreason, ")");
				drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.2 * mySize_y) + eY * 0.8 * mySize_y, s, '1 1 0' * 0.2 * mySize_y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}

		if(forcetime != "")
		{
			a = bound(0, (time - race_checkpointtime) / 0.5, 1);
			drawstring_expanding(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(forcetime, FALSE, '1 1 0' * 0.6 * mySize_y), forcetime, '1 1 0' * 0.6 * mySize_y, '1 1 1', panel_fg_alpha, 0, a);
		}
		else
			a = 1;

		if(race_laptime && race_checkpoint != 255)
		{
			s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime));
			drawstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, FALSE, '0.6 0.6 0' * mySize_y), s, '0.6 0.6 0' * mySize_y, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}
	}
	else
	{
		if(race_mycheckpointtime)
		{
			a = bound(0, 2 - (time - race_mycheckpointtime), 1);
			s = MakeRaceString(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -!race_mycheckpointenemy, race_mycheckpointlapsdelta, race_mycheckpointenemy);
			drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.2 * mySize_y) + eY * 0.6 * mySize_y, s, '1 1 0' * 0.2 * mySize_y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}
		if(race_othercheckpointtime && race_othercheckpointenemy != "")
		{
			a = bound(0, 2 - (time - race_othercheckpointtime), 1);
			s = MakeRaceString(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -!race_othercheckpointenemy, race_othercheckpointlapsdelta, race_othercheckpointenemy);
			drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.2 * mySize_y) + eY * 0.6 * mySize_y, s, '1 1 0' * 0.2 * mySize_y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		if(race_penaltytime && !race_penaltyaccumulator)
		{
			t = race_penaltytime * 0.1 + race_penaltyeventtime;
			a = bound(0, (1 + t - time), 1);
			if(a > 0)
			{
				if(time < t)
					s = strcat("^1PENALTY: ", ftos_decimals(t - time, 1), " (", race_penaltyreason, ")");
				else
					s = strcat("^2PENALTY: 0.0 (", race_penaltyreason, ")");
				drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.2 * mySize_y) + eY * 0.6 * mySize_y, s, '1 1 0' * 0.2 * mySize_y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}
	}

	drawfont = hud_font;
}

// Vote window (#9)
//
float vote_yescount;
float vote_nocount;
float vote_needed;
float vote_highlighted; // currently selected vote

float vote_active; // is there an active vote?
float vote_prev; // previous state of vote_active to check for a change
float vote_alpha;
float vote_change; // "time" when vote_active changed

void HUD_VoteWindow(void) 
{
    uid2name_dialog = 0;
	if(autocvar_cl_allow_uid2name == -1 && (gametype == GAME_CTS || gametype == GAME_RACE))
	{
		vote_active = 1;
		vote_called_vote = strzone(strcat("^2Name ^7instead of \"^1Unregistered player\"", " ^7in stats"));
        uid2name_dialog = 1;
	}

	if(!autocvar_hud_panel_vote && !autocvar__hud_configure)
		return;

	if(!autocvar__hud_configure)
	{
		panel_fg_alpha = autocvar_hud_panel_fg_alpha;
		panel_bg_alpha_str = autocvar_hud_panel_vote_bg_alpha;

		if(panel_bg_alpha_str == "") {
			panel_bg_alpha_str = ftos(autocvar_hud_panel_bg_alpha);
		}
		panel_bg_alpha = stof(panel_bg_alpha_str);
	}

	string s;
	float a;
	if(vote_active != vote_prev) {
		vote_change = time;
		vote_prev = vote_active;
	}

	if(vote_active || autocvar__hud_configure)
		vote_alpha = bound(0, (time - vote_change) * 2, 1);
	else
		vote_alpha = bound(0, 1 - (time - vote_change) * 2, 1);

	if(autocvar__hud_configure)
	{
		vote_yescount = 3;
		vote_nocount = 2;
		vote_needed = 4;
	}

	if(!vote_alpha)
		return;

	active_panel = HUD_PANEL_VOTE;
	HUD_Panel_UpdateCvars(vote);

	if(uid2name_dialog)
	{
		panel_pos = eX * 0.3 * vid_conwidth + eY * 0.1 * vid_conheight;
		panel_size = eX * 0.4 * vid_conwidth + eY * 0.3 * vid_conheight;
	}

    // these must be below above block
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	a = vote_alpha * bound(autocvar_hud_panel_vote_alreadyvoted_alpha, 1 - vote_highlighted, 1);
	HUD_Panel_DrawBg(a);
	a = panel_fg_alpha * a;

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// always force 3:1 aspect
	vector newSize;
	if(mySize_x/mySize_y > 3)
	{
		newSize_x = 3 * mySize_y;
		newSize_y = mySize_y;

		pos_x = pos_x + (mySize_x - newSize_x) / 2;
	}
	else
	{
		newSize_y = 1/3 * mySize_x;
		newSize_x = mySize_x;

		pos_y = pos_y + (mySize_y - newSize_y) / 2;
	}
	mySize = newSize;

	s = "A vote has been called for:";
	if(uid2name_dialog)
		s = "Allow servers to store and display your name?";
	drawstring_aspect(pos, s, eX * mySize_x + eY * (2/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);
	s = textShortenToWidth(vote_called_vote, mySize_x, '1 1 0' * mySize_y * (1/8), stringwidth_colors);
	if(autocvar__hud_configure)
		s = "^1Configure the HUD";
	drawcolorcodedstring_aspect(pos + eY * (2/8) * mySize_y, s, eX * mySize_x + eY * (1.75/8) * mySize_y, a, DRAWFLAG_NORMAL);

	// print the yes/no counts
    s = strcat("Yes (", getcommandkey("vyes", "vyes"), "): ", ftos(vote_yescount));
	drawstring_aspect(pos + eY * (4/8) * mySize_y, s, eX * 0.5 * mySize_x + eY * (1.5/8) * mySize_y, '0 1 0', a, DRAWFLAG_NORMAL);
    s = strcat("No (", getcommandkey("vno", "vno"), "): ", ftos(vote_nocount));
	drawstring_aspect(pos + eX * 0.5 * mySize_x + eY * (4/8) * mySize_y, s, eX * 0.5 * mySize_x + eY * (1.5/8) * mySize_y, '1 0 0', a, DRAWFLAG_NORMAL);

	// draw the progress bar backgrounds
	drawpic_skin(pos + eY * (5/8) * mySize_y, "voteprogress_back", eX * mySize_x + eY * (3/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);

	// draw the highlights
	if(vote_highlighted == 1) {
		drawsetcliparea(pos_x, pos_y, mySize_x * 0.5, mySize_y);
		drawpic_skin(pos + eY * (5/8) * mySize_y, "voteprogress_voted", eX * mySize_x + eY * (3/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);
	}
	else if(vote_highlighted == 2) {
		drawsetcliparea(pos_x + 0.5 * mySize_x, pos_y, mySize_x * 0.5, mySize_y);
		drawpic_skin(pos + eY * (5/8) * mySize_y, "voteprogress_voted", eX * mySize_x + eY * (3/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);
	}

	// draw the progress bars
	if(vote_yescount && vote_needed)
	{
		drawsetcliparea(pos_x, pos_y, mySize_x * 0.5 * (vote_yescount/vote_needed), mySize_y);
		drawpic_skin(pos + eY * (5/8) * mySize_y, "voteprogress_prog", eX * mySize_x + eY * (3/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);
	}

	if(vote_nocount && vote_needed)
	{
		drawsetcliparea(pos_x + mySize_x - mySize_x * 0.5 * (vote_nocount/vote_needed), pos_y, mySize_x * 0.5, mySize_y);
		drawpic_skin(pos + eY * (5/8) * mySize_y, "voteprogress_prog", eX * mySize_x + eY * (3/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);
	}

	drawresetcliparea();

	if(!vote_active) {
		vote_highlighted = 0;
	}
}

// Mod icons panel (#10)
//

float mod_active; // is there any active mod icon?

// Clan Arena HUD modicons
void HUD_Mod_CA(vector pos, vector mySize)
{
	mod_active = 1; // CA should never hide the mod icons panel
	float redalive, bluealive;
	redalive = getstati(STAT_REDALIVE);
	bluealive = getstati(STAT_BLUEALIVE);

	drawfont = hud_bigfont;
	vector redpos, bluepos;
	if(mySize_x > mySize_y)
	{
		redpos = pos;
		bluepos = pos + eY * 0.5 * mySize_y;
		drawpic_aspect_skin(redpos, "player_red.tga", 0.5 * mySize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(redpos + eX * 0.5 * mySize_x, ftos(redalive), 0.5 * mySize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawpic_aspect_skin(bluepos, "player_blue.tga", 0.5 * mySize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(bluepos + eX * 0.5 * mySize_x, ftos(bluealive), 0.5 * mySize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else
	{
		redpos = pos;
		bluepos = pos + eY * 0.5 * mySize_y;
		drawpic_aspect_skin(redpos, "player_red.tga", eX * mySize_x + eY * 0.3 * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(redpos + eY * 0.3 * mySize_y, ftos(redalive), eX * mySize_x + eY * 0.2 * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawpic_aspect_skin(bluepos, "player_blue.tga", eX * mySize_x + eY * 0.3 * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(bluepos + eY * 0.3 * mySize_y, ftos(bluealive), eX * mySize_x + eY * 0.2 * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	drawfont = hud_font;
}

// CTF HUD modicon section
float redflag_prevframe, blueflag_prevframe; // status during previous frame
float redflag_prevstatus, blueflag_prevstatus; // last remembered status
float redflag_statuschange_time, blueflag_statuschange_time; // time when the status changed

void HUD_Mod_CTF_Reset(void)
{
	redflag_prevstatus = blueflag_prevstatus = redflag_prevframe = blueflag_prevframe = redflag_statuschange_time = blueflag_statuschange_time = 0;
}

void HUD_Mod_CTF(vector pos, vector mySize)
{
	vector redflag_pos, blueflag_pos;
	vector flag_size;
	float f; // every function should have that

	float redflag, blueflag; // current status
	float redflag_statuschange_elapsedtime, blueflag_statuschange_elapsedtime; // time since the status changed
	float stat_items;

	stat_items = getstati(STAT_ITEMS);
	redflag = (stat_items/IT_RED_FLAG_TAKEN) & 3;
	blueflag = (stat_items/IT_BLUE_FLAG_TAKEN) & 3;
	
	if(redflag || blueflag)
		mod_active = 1;
	else
		mod_active = 0;

	if(autocvar__hud_configure)
	{
		redflag = 1;
		blueflag = 2;
	}

	// when status CHANGES, set old status into prevstatus and current status into status
	if (redflag != redflag_prevframe)
	{
		redflag_statuschange_time = time;
		redflag_prevstatus = redflag_prevframe;
		redflag_prevframe = redflag;
	}

	if (blueflag != blueflag_prevframe)
	{
		blueflag_statuschange_time = time;
		blueflag_prevstatus = blueflag_prevframe;
		blueflag_prevframe = blueflag;
	}

	redflag_statuschange_elapsedtime = time - redflag_statuschange_time;
	blueflag_statuschange_elapsedtime = time - blueflag_statuschange_time;

	float BLINK_FACTOR = 0.15;
	float BLINK_BASE = 0.85;
	// note:
	//   RMS = sqrt(BLINK_BASE^2 + 0.5 * BLINK_FACTOR^2)
	// thus
	//   BLINK_BASE = sqrt(RMS^2 - 0.5 * BLINK_FACTOR^2)
	// ensure RMS == 1
	float BLINK_FREQ = 5; // circle frequency, = 2*pi*frequency in hertz

	string red_icon, red_icon_prevstatus;
	float red_alpha, red_alpha_prevstatus;
	red_alpha = red_alpha_prevstatus = 1;
	switch(redflag) {
		case 1: red_icon = "flag_red_taken"; break;
		case 2: red_icon = "flag_red_lost"; break;
		case 3: red_icon = "flag_red_carrying"; red_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon = "flag_red_shielded";
			else
				red_icon = string_null;
			break;
	}
	switch(redflag_prevstatus) {
		case 1: red_icon_prevstatus = "flag_red_taken"; break;
		case 2: red_icon_prevstatus = "flag_red_lost"; break;
		case 3: red_icon_prevstatus = "flag_red_carrying"; red_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(redflag == 3)
				red_icon_prevstatus = "flag_red_carrying"; // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon_prevstatus = "flag_red_shielded";
			else
				red_icon_prevstatus = string_null;
			break;
	}

	string blue_icon, blue_icon_prevstatus;
	float blue_alpha, blue_alpha_prevstatus;
	blue_alpha = blue_alpha_prevstatus = 1;
	switch(blueflag) {
		case 1: blue_icon = "flag_blue_taken"; break;
		case 2: blue_icon = "flag_blue_lost"; break;
		case 3: blue_icon = "flag_blue_carrying"; blue_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon = "flag_blue_shielded";
			else
				blue_icon = string_null;
			break;
	}
	switch(blueflag_prevstatus) {
		case 1: blue_icon_prevstatus = "flag_blue_taken"; break;
		case 2: blue_icon_prevstatus = "flag_blue_lost"; break;
		case 3: blue_icon_prevstatus = "flag_blue_carrying"; blue_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(blueflag == 3)
				blue_icon_prevstatus = "flag_blue_carrying"; // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon_prevstatus = "flag_blue_shielded";
			else
				blue_icon_prevstatus = string_null;
			break;
	}

	if(mySize_x > mySize_y) {
		if (myteam == COLOR_TEAM1) { // always draw own flag on left
			redflag_pos = pos;
			blueflag_pos = pos + eX * 0.5 * mySize_x;
		} else {
			blueflag_pos = pos;
			redflag_pos = pos + eX * 0.5 * mySize_x;
		}
		flag_size = eX * 0.5 * mySize_x + eY * mySize_y;
	} else {
		if (myteam == COLOR_TEAM1) { // always draw own flag on left
			redflag_pos = pos;
			blueflag_pos = pos + eY * 0.5 * mySize_y;
		} else {
			blueflag_pos = pos;
			redflag_pos = pos + eY * 0.5 * mySize_y;
		}
		flag_size = eY * 0.5 * mySize_y + eX * mySize_x;
	}

	f = bound(0, redflag_statuschange_elapsedtime*2, 1);
	if(red_icon_prevstatus && f < 1)
		drawpic_aspect_skin_expanding(redflag_pos, red_icon_prevstatus, flag_size, '1 1 1', panel_fg_alpha * red_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(red_icon)
		drawpic_aspect_skin(redflag_pos, red_icon, flag_size, '1 1 1', panel_fg_alpha * red_alpha * f, DRAWFLAG_NORMAL);

	f = bound(0, blueflag_statuschange_elapsedtime*2, 1);
	if(blue_icon_prevstatus && f < 1)
		drawpic_aspect_skin_expanding(blueflag_pos, blue_icon_prevstatus, flag_size, '1 1 1', panel_fg_alpha * blue_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(blue_icon)
		drawpic_aspect_skin(blueflag_pos, blue_icon, flag_size, '1 1 1', panel_fg_alpha * blue_alpha * f, DRAWFLAG_NORMAL);
}

// Keyhunt HUD modicon section
float kh_runheretime;

void HUD_Mod_KH_Reset(void)
{
	kh_runheretime = 0;
}

void HUD_Mod_KH(vector pos, vector mySize)
{
	mod_active = 1; // keyhunt should never hide the mod icons panel
	float kh_keys;
	float keyteam;
	float a, aa;
	vector p, pa, kh_size, kh_asize;

	kh_keys = getstati(STAT_KH_KEYS);

	p_x = pos_x;
	if(mySize_x > mySize_y)
	{
		p_y = pos_y + 0.25 * mySize_y;
		pa = p - eY * 0.25 * mySize_y;

		kh_size_x = mySize_x * 0.25;
		kh_size_y = 0.75 * mySize_y;
		kh_asize_x = mySize_x * 0.25;
		kh_asize_y = mySize_y * 0.25;
	}
	else
	{
		p_y = pos_y + 0.125 * mySize_y;
		pa = p - eY * 0.125 * mySize_y;

		kh_size_x = mySize_x * 0.5;
		kh_size_y = 0.375 * mySize_y;
		kh_asize_x = mySize_x * 0.5;
		kh_asize_y = mySize_y * 0.125;
	}

	float i, key;

	float keycount;
	keycount = 0;
	for(i = 0; i < 4; ++i)
	{
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		if(keyteam == 30 && keycount <= 4)
			keycount += 4;
		if(keyteam == myteam || keyteam == -1 || keyteam == 30)
			keycount += 1;
	}

	// this yields 8 exactly if "RUN HERE" shows

	if(keycount == 8)
	{
		if(!kh_runheretime)
			kh_runheretime = time;
		pa_y -= fabs(sin((time - kh_runheretime) * 3.5)) * 6; // make the arrows jump in case of RUN HERE
	}
	else
		kh_runheretime = 0;

	for(i = 0; i < 4; ++i)
	{
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		switch(keyteam)
		{
			case 30: // my key
				keyteam = myteam;
				a = 1;
				aa = 1;
				break;
			case -1: // no key
				a = 0;
				aa = 0;
				break;
			default: // owned or dropped
				a = 0.2;
				aa = 0.5;
				break;
		}
		a = a * panel_fg_alpha;
		aa = aa * panel_fg_alpha;
		if(a > 0)
		{
			switch(keyteam)
			{
				case COLOR_TEAM1:
					drawpic_aspect_skin(pa, "kh_redarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM2:
					drawpic_aspect_skin(pa, "kh_bluearrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM3:
					drawpic_aspect_skin(pa, "kh_yellowarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM4:
					drawpic_aspect_skin(pa, "kh_pinkarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				default:
					break;
			}
			switch(i) // YAY! switch(i) inside a for loop for i. DailyWTF, here we come!
			{
				case 0:
					drawpic_aspect_skin(p, "kh_red", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 1:
					drawpic_aspect_skin(p, "kh_blue", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 2:
					drawpic_aspect_skin(p, "kh_yellow", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 3:
					drawpic_aspect_skin(p, "kh_pink", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
			}
		}
		if(mySize_x > mySize_y)
		{
			p_x += 0.25 * mySize_x;
			pa_x += 0.25 * mySize_x;
		}
		else
		{
			if(i == 1)
			{
				p_y = pos_y + 0.625 * mySize_y;
				pa_y = pos_y + 0.5 * mySize_y;
				p_x = pos_x;
				pa_x = pos_x;
			}
			else
			{
				p_x += 0.5 * mySize_x;
				pa_x += 0.5 * mySize_x;
			}
		}
	}
}

// Keepaway HUD mod icon
float kaball_prevstatus; // last remembered status
float kaball_statuschange_time; // time when the status changed

// we don't need to reset for keepaway since it immediately 
// autocorrects prevstatus as to if the player has the ball or not

void HUD_Mod_Keepaway(vector pos, vector mySize)
{
	mod_active = 1; // keepaway should always show the mod HUD
	
	float BLINK_FACTOR = 0.15;
	float BLINK_BASE = 0.85;
	float BLINK_FREQ = 5; 
	float kaball_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ);
	
	float stat_items = getstati(STAT_ITEMS);
	float kaball = (stat_items/IT_KEY1) & 1;
	
	if(kaball != kaball_prevstatus)
	{
		kaball_statuschange_time = time;
		kaball_prevstatus = kaball;
	}
	
	// todo: Fix the sizing with the expanding image
	
	float kaball_statuschange_elapsedtime = time - kaball_statuschange_time;
	float f = bound(0, kaball_statuschange_elapsedtime*2, 1);
	
	if(kaball_prevstatus && f < 1)
		drawpic_aspect_skin_expanding(pos + eY * 0.25 * mySize_y, "keepawayball_carrying", eX * mySize_x + eY * mySize_y * 0.5, '1 1 1', panel_fg_alpha * kaball_alpha, DRAWFLAG_NORMAL, f);
	
	if(kaball)
		drawpic_aspect_skin(pos, "keepawayball_carrying", eX * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha * kaball_alpha * f, DRAWFLAG_NORMAL);
}


// Nexball HUD mod icon
void HUD_Mod_NexBall(vector pos, vector mySize)
{
	float stat_items, nb_pb_starttime, dt, p;

	stat_items = getstati(STAT_ITEMS);
	nb_pb_starttime = getstatf(STAT_NB_METERSTART);

	if (stat_items & IT_KEY1)
		mod_active = 1;
	else
		mod_active = 0;

	//Manage the progress bar if any
	if (nb_pb_starttime > 0)
	{
		dt = mod(time - nb_pb_starttime, nb_pb_period);
		// one period of positive triangle
		p = 2 * dt / nb_pb_period;
		if (p > 1)
			p = 2 - p;

		//Draw the filling
		float vertical;
		if(mySize_x > mySize_y)
		{
			vertical = 0;
		}
		else
		{
			vertical = 1;
		}
		HUD_Panel_GetProgressBarColor(nexball);
        HUD_Panel_DrawProgressBar(pos, mySize, "statusbar", vertical, 0, p, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if (stat_items & IT_KEY1)
		drawpic_aspect_skin(pos, "nexball_carrying", eX * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Race/CTS HUD mod icons
float crecordtime_prev; // last remembered crecordtime
float crecordtime_change_time; // time when crecordtime last changed
float srecordtime_prev; // last remembered srecordtime
float srecordtime_change_time; // time when srecordtime last changed

float race_status_time;
float race_status_prev;
string race_status_name_prev;
void HUD_Mod_Race(vector pos, vector mySize)
{
	mod_active = 1; // race should never hide the mod icons panel
	entity me;
	me = playerslots[player_localentnum - 1];
	float t, score;
	float f; // yet another function has this
	score = me.(scores[ps_primary]);

	if not((scores_flags[ps_primary] & SFL_TIME) && !teamplay) // race/cts record display on HUD
		return; // no records in the actual race

	drawfont = hud_bigfont;

	// clientside personal record
	string rr;
	if(gametype == GAME_CTS)
		rr = CTS_RECORD;
	else
		rr = RACE_RECORD;
	t = stof(db_get(ClientProgsDB, strcat(shortmapname, rr, "time")));

	if(score && (score < t || !t)) {
		db_put(ClientProgsDB, strcat(shortmapname, rr, "time"), ftos(score));
		if(autocvar_cl_autodemo_delete_keeprecords)
		{
			f = autocvar_cl_autodemo_delete;
			f &~= 1;
			cvar_set("cl_autodemo_delete", ftos(f)); // don't delete demo with new record!
		}
	}

	if(t != crecordtime_prev) {
		crecordtime_prev = t;
		crecordtime_change_time = time;
	}

	vector textPos, medalPos;
	float squareSize;
	if(mySize_x > mySize_y) {
		// text on left side
		squareSize = min(mySize_y, mySize_x/2);
		textPos = pos + eX * 0.5 * max(0, mySize_x/2 - squareSize) + eY * 0.5 * (mySize_y - squareSize);
		medalPos = pos + eX * 0.5 * max(0, mySize_x/2 - squareSize) + eX * 0.5 * mySize_x + eY * 0.5 * (mySize_y - squareSize);
	} else {
		// text on top
		squareSize = min(mySize_x, mySize_y/2);
		textPos = pos + eY * 0.5 * max(0, mySize_y/2 - squareSize) + eX * 0.5 * (mySize_x - squareSize);
		medalPos = pos + eY * 0.5 * max(0, mySize_y/2 - squareSize) + eY * 0.5 * mySize_y + eX * 0.5 * (mySize_x - squareSize);
	}

	f = time - crecordtime_change_time;

	if (f > 1) {
		drawstring_aspect(textPos, "Personal best", eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	} else {
		drawstring_aspect(textPos, "Personal best", eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect_expanding(pos, "Personal best", eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
		drawstring_aspect_expanding(pos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}

	// server record
	t = race_server_record;
	if(t != srecordtime_prev) {
		srecordtime_prev = t;
		srecordtime_change_time = time;
	}
	f = time - srecordtime_change_time;

	if (f > 1) {
		drawstring_aspect(textPos + eY * 0.5 * squareSize, "Server best", eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	} else {
		drawstring_aspect(textPos + eY * 0.5 * squareSize, "Server best", eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect_expanding(textPos + eY * 0.5 * squareSize, "Server best", eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
		drawstring_aspect_expanding(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}

	if (race_status != race_status_prev || race_status_name != race_status_name_prev) {
		race_status_time = time + 5;
		race_status_prev = race_status;
		if (race_status_name_prev)
			strunzone(race_status_name_prev);
		race_status_name_prev = strzone(race_status_name);
	}

	// race "awards"
	float a;
	a = bound(0, race_status_time - time, 1);

	string s;
	s = textShortenToWidth(race_status_name, squareSize, '1 1 0' * 0.1 * squareSize, stringwidth_colors);

	float rank;
	if(race_status > 0)
		rank = race_CheckName(race_status_name);
	string rankname;
	rankname = race_PlaceName(rank);

	vector namepos;
	namepos = medalPos + '0 0.8 0' * squareSize;
	vector rankpos;
	rankpos = medalPos + '0 0.15 0' * squareSize;

	if(race_status == 0)
		drawpic_aspect_skin(medalPos, "race_newfail", '1 1 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	else if(race_status == 1) {
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newtime", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	} else if(race_status == 2) {
		if(race_status_name == GetPlayerName(player_localentnum -1) || !race_myrank || race_myrank < rank)
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankgreen", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		else
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankyellow", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	} else if(race_status == 3) {
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrecordserver", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}

	if (race_status_time - time <= 0) {
		race_status_prev = -1;
		race_status = -1;
		if(race_status_name)
			strunzone(race_status_name);
		race_status_name = string_null;
		if(race_status_name_prev)
			strunzone(race_status_name_prev);
		race_status_name_prev = string_null;
	}
	drawfont = hud_font;
}

float mod_prev; // previous state of mod_active to check for a change
float mod_alpha;
float mod_change; // "time" when mod_active changed

void HUD_ModIcons(void)
{
	if(!autocvar_hud_panel_modicons && !autocvar__hud_configure)
		return;

	if (gametype != GAME_KEYHUNT && gametype != GAME_CTF && gametype != GAME_NEXBALL && gametype != GAME_CTS && gametype != GAME_RACE && gametype != GAME_CA && gametype != GAME_FREEZETAG && gametype != GAME_KEEPAWAY && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_MODICONS;
	HUD_Panel_UpdateCvars(modicons);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if(mod_active != mod_prev) {
		mod_change = time;
		mod_prev = mod_active;
	}

	if(mod_active || autocvar__hud_configure)
		mod_alpha = bound(0, (time - mod_change) * 2, 1);
	else
		mod_alpha = bound(0, 1 - (time - mod_change) * 2, 1);

	if(mod_alpha)
		HUD_Panel_DrawBg(mod_alpha);

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// these MUST be ran in order to update mod_active
	if(gametype == GAME_KEYHUNT)
		HUD_Mod_KH(pos, mySize);
	else if(gametype == GAME_CTF || autocvar__hud_configure)
		HUD_Mod_CTF(pos, mySize); // forcealpha only needed for ctf icons, as only they are shown in config mode
	else if(gametype == GAME_NEXBALL)
		HUD_Mod_NexBall(pos, mySize);
	else if(gametype == GAME_CTS || gametype == GAME_RACE)
		HUD_Mod_Race(pos, mySize);
	else if(gametype == GAME_CA || gametype == GAME_FREEZETAG)
		HUD_Mod_CA(pos, mySize);
	else if(gametype == GAME_KEEPAWAY)
		HUD_Mod_Keepaway(pos, mySize);
}

// Draw pressed keys (#11)
//
void HUD_DrawPressedKeys(void)
{
	if(!autocvar_hud_panel_pressedkeys && !autocvar__hud_configure)
		return;

	if(!(spectatee_status > 0 || autocvar_hud_panel_pressedkeys >= 2 || autocvar__hud_configure))
		return;

	active_panel = HUD_PANEL_PRESSEDKEYS;
	HUD_Panel_UpdateCvars(pressedkeys);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// force custom aspect
	float aspect = autocvar_hud_panel_pressedkeys_aspect;
	if(aspect)
	{
		vector newSize;
		if(mySize_x/mySize_y > aspect)
		{
			newSize_x = aspect * mySize_y;
			newSize_y = mySize_y;

			pos_x = pos_x + (mySize_x - newSize_x) / 2;
		}
		else
		{
			newSize_y = 1/aspect * mySize_x;
			newSize_x = mySize_x;

			pos_y = pos_y + (mySize_y - newSize_y) / 2;
		}
		mySize = newSize;
	}

	vector keysize;
	keysize = eX * mySize_x * (1/3) + eY * mySize_y * 0.5;
	float pressedkeys;

	pressedkeys = getstatf(STAT_PRESSED_KEYS);
	drawpic_aspect_skin(pos, ((pressedkeys & KEY_CROUCH) ? "key_crouch_inv.tga" : "key_crouch.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * mySize_x * (1/3), ((pressedkeys & KEY_FORWARD) ? "key_forward_inv.tga" : "key_forward.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * mySize_x * (2/3), ((pressedkeys & KEY_JUMP) ? "key_jump_inv.tga" : "key_jump.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eY * 0.5 * mySize_y, ((pressedkeys & KEY_LEFT) ? "key_left_inv.tga" : "key_left.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eY * 0.5 * mySize_y + eX * mySize_x * (1/3), ((pressedkeys & KEY_BACKWARD) ? "key_backward_inv.tga" : "key_backward.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eY * 0.5 * mySize_y + eX * mySize_x * (2/3), ((pressedkeys & KEY_RIGHT) ? "key_right_inv.tga" : "key_right.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Handle chat as a panel (#12)
//
void HUD_Chat(void)
{
	if(!autocvar_hud_panel_chat && !autocvar__hud_configure)
	{
		cvar_set("con_chatrect", "0");
		return;
	}

	active_panel = HUD_PANEL_CHAT;
	HUD_Panel_UpdateCvars(chat);

	if(autocvar__con_chat_maximized && !autocvar__hud_configure) // draw at full screen height if maximized
	{
		panel_pos_y = panel_bg_border;
		panel_size_y = vid_conheight - panel_bg_border * 2;
		if(panel_bg == "0") // force a border when maximized
		{
			if(precache_pic(panel_bg) == "") {
				panel_bg = strcat(hud_skin_path, "/border_default");
				if(precache_pic(panel_bg) == "") {
					panel_bg = "gfx/hud/default/border_default";
				}
			}
		}
		panel_bg_alpha = max(0.75, panel_bg_alpha); // force an alpha of at least 0.75
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

	cvar_set("con_chatrect", "1");

	cvar_set("con_chatrect_x", ftos(pos_x/vid_conwidth));
	cvar_set("con_chatrect_y", ftos(pos_y/vid_conheight));

	cvar_set("con_chatwidth", ftos(mySize_x/vid_conwidth));
	cvar_set("con_chat", ftos(floor(mySize_y/autocvar_con_chatsize - 0.5)));

	if(autocvar__hud_configure)
	{
		float chatsize;
		chatsize = autocvar_con_chatsize;
		cvar_set("con_chatrect_x", "9001"); // over 9000, we'll fake it instead for more control over alpha and such
		float i, a;
		for(i = 0; i < autocvar_con_chat; ++i)
		{
			if(i == autocvar_con_chat - 1)
				a = panel_fg_alpha;
			else
				a = panel_fg_alpha * floor(((i + 1) * 7 + autocvar_con_chattime)/45);
			drawcolorcodedstring(pos + eY * i * chatsize, textShortenToWidth("^3Player^7: This is the chat area.", mySize_x, '1 1 0' * chatsize, stringwidth_colors), '1 1 0' * chatsize, a, DRAWFLAG_NORMAL);
		}
	}
}

// Engine info panel (#13)
//
float prevfps;
float prevfps_time;
float framecounter;

float frametimeavg;
float frametimeavg1; // 1 frame ago
float frametimeavg2; // 2 frames ago
void HUD_EngineInfo(void)
{
	if(!autocvar_hud_panel_engineinfo && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_ENGINEINFO;
	HUD_Panel_UpdateCvars(engineinfo);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float currentTime = gettime(GETTIME_REALTIME);
	if(cvar("hud_panel_engineinfo_framecounter_exponentialmovingaverage"))
	{
		float currentframetime = currentTime - prevfps_time;
		frametimeavg = (frametimeavg + frametimeavg1 + frametimeavg2 + currentframetime)/4; // average three frametimes into framecounter for slightly more stable fps readings :P
		frametimeavg2 = frametimeavg1;
		frametimeavg1 = frametimeavg;
		
		float weight;
		weight = cvar("hud_panel_engineinfo_framecounter_exponentialmovingaverage_new_weight");
		if(currentframetime > 0.0001) // filter out insane values which sometimes seem to occur and throw off the average? If you are getting 10,000 fps or more, then you don't need a framerate counter.
		{
			if(fabs(prevfps - (1/frametimeavg)) > prevfps * cvar("hud_panel_engineinfo_framecounter_exponentialmovingaverage_instantupdate_change_threshold")) // if there was a big jump in fps, just force prevfps at current (1/currentframetime) to make big updates instant
				prevfps = (1/currentframetime);
			prevfps = (1 - weight) * prevfps + weight * (1/frametimeavg); // framecounter just used so there's no need for a new variable, think of it as "frametime average"
		}
		prevfps_time = currentTime;
	}
	else
	{
		framecounter += 1;
		if(currentTime - prevfps_time > autocvar_hud_panel_engineinfo_framecounter_time)
		{
			prevfps = framecounter/(currentTime - prevfps_time);
			framecounter = 0;
			prevfps_time = currentTime;
		}
	}

	vector color;
	color = HUD_Get_Num_Color (prevfps, 100);
	drawfont = hud_bigfont;
	drawstring_aspect(pos, strcat("FPS: ", ftos_decimals(prevfps, autocvar_hud_panel_engineinfo_framecounter_decimals)), mySize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
	drawfont = hud_font;
}

// Info messages panel (#14)
//
#define drawInfoMessage(s)\
	if(autocvar_hud_panel_infomessages_flip)\
		o_x = pos_x + mySize_x - stringwidth(s, TRUE, fontsize);\
	drawcolorcodedstring(o, s, fontsize, a, DRAWFLAG_NORMAL);\
	o_y += fontsize_y;
void HUD_InfoMessages(void)
{
	if(!autocvar_hud_panel_infomessages && !autocvar__hud_configure)
		return;

	active_panel = HUD_PANEL_INFOMESSAGES;
	HUD_Panel_UpdateCvars(infomessages);
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// always force 5:1 aspect
	vector newSize;
	if(mySize_x/mySize_y > 5)
	{
		newSize_x = 5 * mySize_y;
		newSize_y = mySize_y;

		pos_x = pos_x + (mySize_x - newSize_x) / 2;
	}
	else
	{
		newSize_y = 1/5 * mySize_x;
		newSize_x = mySize_x;

		pos_y = pos_y + (mySize_y - newSize_y) / 2;
	}

	mySize = newSize;
	entity tm;
	vector o;
	o = pos;

	vector fontsize;
	fontsize = '0.20 0.20 0' * mySize_y;
	
	float a;
	if(spectatee_status != 0)
		a = 1;
	else
		a = panel_fg_alpha;

	string s;
	if(!autocvar__hud_configure)
	{
		if(spectatee_status && !intermission)
		{
			if(spectatee_status == -1)
				s = "^1Observing";
			else
				s = strcat("^1Spectating: ^7", GetPlayerName(spectatee_status - 1));
			drawInfoMessage(s)

			if(spectatee_status == -1)
				s = strcat("^1Press ^3", getcommandkey("primary fire", "+fire"), "^1 to spectate");
			else
				s = strcat("^1Press ^3", getcommandkey("primary fire", "+fire"), "^1 for another player");
			drawInfoMessage(s)

			if(spectatee_status == -1)
				s = strcat("^1Use ^3", getcommandkey("next weapon", "weapnext"), "^1 or ^3", getcommandkey("previous weapon", "weapprev"), "^1 to change the speed");
			else
				s = strcat("^1Press ^3", getcommandkey("secondary fire", "+fire2"), "^1 to observe");
			drawInfoMessage(s)

			s = strcat("^1Press ^3", getcommandkey("server info", "+show_info"), "^1 for gamemode info");
			drawInfoMessage(s)

			if(gametype == GAME_ARENA)
				s = "^1Wait for your turn to join";
			else if(gametype == GAME_LMS)
			{
				entity sk;
				sk = playerslots[player_localentnum - 1];
				if(sk.(scores[ps_primary]) >= 666)
					s = "^1Match has already begun";
				else if(sk.(scores[ps_primary]) > 0)
					s = "^1You have no more lives left";
				else
					s = strcat("^1Press ^3", getcommandkey("jump", "+jump"), "^1 to join");
			}
			else
				s = strcat("^1Press ^3", getcommandkey("jump", "+jump"), "^1 to join");
			drawInfoMessage(s)

			//show restart countdown:
			if (time < getstatf(STAT_GAMESTARTTIME)) {
				float countdown;
				//we need to ceil, otherwise the countdown would be off by .5 when using round()
				countdown = ceil(getstatf(STAT_GAMESTARTTIME) - time);
				s = strcat("^1Game starts in ^3", ftos(countdown), "^1 seconds");
				drawcolorcodedstring(o, s, fontsize, a, DRAWFLAG_NORMAL);
				o_y += fontsize_y;
			}
		}
		if(warmup_stage && !intermission)
		{
			s = "^2Currently in ^1warmup^2 stage!";
			drawInfoMessage(s)
		}

		string blinkcolor;
		if(mod(time, 1) >= 0.5)
			blinkcolor = "^1";
		else
			blinkcolor = "^3";

		if(ready_waiting && !intermission && !spectatee_status)
		{
			if(ready_waiting_for_me)
			{
				if(warmup_stage)
					s = strcat(blinkcolor, "Press ^3", getcommandkey("ready", "ready"), blinkcolor, " to end warmup");
				else
					s = strcat(blinkcolor, "Press ^3", getcommandkey("ready", "ready"), blinkcolor, " once you are ready");
			}
			else
			{
				if(warmup_stage)
					s = strcat("^2Waiting for others to ready up to end warmup...");
				else
					s = strcat("^2Waiting for others to ready up...");
			}
			drawInfoMessage(s)
		}
		else if(warmup_stage && !intermission && !spectatee_status)
		{
			s = strcat("^2Press ^3", getcommandkey("ready", "ready"), "^2 to end warmup");
			drawInfoMessage(s)
		}

		if(teamplay && !intermission && !spectatee_status && gametype != GAME_CA && teamnagger)
		{
			float ts_min, ts_max;
			tm = teams.sort_next;
			if (tm)
			{
				for(; tm.sort_next; tm = tm.sort_next)
				{
					if(!tm.team_size || tm.team == COLOR_SPECTATOR)
						continue;
					if(!ts_min) ts_min = tm.team_size;
					else ts_min = min(ts_min, tm.team_size);
					if(!ts_max) ts_max = tm.team_size;
					else ts_max = max(ts_max, tm.team_size);
				}
				if ((ts_max - ts_min) > 1)
				{
					s = strcat(blinkcolor, "Teamnumbers are unbalanced!");
					tm = GetTeam(myteam, false);
					if (tm)
					if (tm.team != COLOR_SPECTATOR)
					if (tm.team_size == ts_max)
						s = strcat(s, " Press ^3", getcommandkey("team menu", "menu_showteamselect"), blinkcolor, " to adjust");
					drawInfoMessage(s)
				}
			}
		}
	}
	else 
	{
		s = "^7Press ^3ESC ^7to show HUD options.";
		drawInfoMessage(s)
		s = "^3Doubleclick ^7a panel for panel-specific options.";
		drawInfoMessage(s)
		s = "^3CTRL ^7to disable collision testing, ^3SHIFT ^7and";
		drawInfoMessage(s)
		s = "^3ALT ^7+ ^3ARROW KEYS ^7for fine adjustments.";
		drawInfoMessage(s)
	}
}

/*
==================
Main HUD system
==================
*/

void HUD_ShowSpeed(void)
{
	vector numsize;
	float pos, conversion_factor;
	string speed, zspeed, unit;

	switch(autocvar_cl_showspeed_unit)
	{
		default:
		case 0:
			unit = "";
			conversion_factor = 1.0;
			break;
		case 1:
			unit = " qu/s";
			conversion_factor = 1.0;
			break;
		case 2:
			unit = " m/s";
			conversion_factor = 0.0254;
			break;
		case 3:
			unit = " km/h";
			conversion_factor = 0.0254 * 3.6;
			break;
		case 4:
			unit = " mph";
			conversion_factor = 0.0254 * 3.6 * 0.6213711922;
			break;
		case 5:
			unit = " knots";
			conversion_factor = 0.0254 * 1.943844492; // 1 m/s = 1.943844492 knots, because 1 knot = 1.852 km/h
			break;
	}

	speed = strcat(ftos(floor( vlen(pmove_vel - pmove_vel_z * '0 0 1') * conversion_factor + 0.5 )), unit);

	numsize_x = numsize_y = autocvar_cl_showspeed_size;
	pos = (vid_conheight - numsize_y) * autocvar_cl_showspeed_position;

	drawfont = hud_bigfont;
	drawstringcenter(eX + pos * eY, speed, numsize, '1 1 1', autocvar_hud_panel_fg_alpha * hud_fade_alpha, DRAWFLAG_NORMAL);

	if (autocvar_cl_showspeed_z == 1) {
		zspeed = strcat(ftos(fabs(floor( pmove_vel_z * conversion_factor + 0.5 ))), unit);
		drawstringcenter(eX + pos * eY + numsize_y * eY, zspeed, numsize * 0.5, '1 1 1', autocvar_hud_panel_fg_alpha * hud_fade_alpha, DRAWFLAG_NORMAL);
	}

	drawfont = hud_font;
}

vector acc_prevspeed;
float acc_prevtime;
float acc_avg;

void HUD_ShowAcceleration(void)
{
	float acceleration, sz, scale, alpha, f;
	vector pos, top, rgb;
	top_x = vid_conwidth/2;
	top_y = 0;

	f = time - acc_prevtime;
	if(autocvar_cl_showacceleration_z)
		acceleration = (vlen(pmove_vel) - vlen(acc_prevspeed)) * (1 / f);
	else
		acceleration = (vlen(pmove_vel - '0 0 1' * pmove_vel_z) - vlen(acc_prevspeed - '0 0 1' * acc_prevspeed_z)) * (1 / f);
	acc_prevspeed = pmove_vel;
	acc_prevtime = time;

	f = bound(0, f * 10, 1);
	acc_avg = acc_avg * (1 - f) + acceleration * f;
	acceleration = acc_avg / getstatf(STAT_MOVEVARS_MAXSPEED);
	if (acceleration == 0)
		return;

	pos = top - sz/2 * eY + (autocvar_cl_showacceleration_position * vid_conheight) * eY;

	sz = autocvar_cl_showacceleration_size;
	scale = autocvar_cl_showacceleration_scale;
	alpha = autocvar_cl_showacceleration_alpha;
	if (autocvar_cl_showacceleration_color_custom)
		rgb = stov(autocvar_cl_showacceleration_color);
	else {
		if (acceleration < 0)
			rgb = '1 .5 .5' - '0 .5 .5' * bound(0, -acceleration * 0.2, 1);
		else
			rgb = '.5 1 .5' - '.5 0 .5' * bound(0, +acceleration * 0.2, 1);
	}

	if (acceleration > 0)
        HUD_Panel_DrawProgressBar(pos, eX * (vid_conwidth - pos_x) + eY * sz, "statusbar", 0, 0, acceleration * scale, rgb, alpha * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	else
        HUD_Panel_DrawProgressBar(eY * pos_y, eX * pos_x + eY * sz, "statusbar", 0, 1, -acceleration * scale, rgb, alpha * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_Reset (void)
{
	// reset gametype specific icons
	if(gametype == GAME_KEYHUNT)
		HUD_Mod_KH_Reset();
	else if(gametype == GAME_CTF)
		HUD_Mod_CTF_Reset();
}

#define HUD_DrawPanel(id)\
switch (id) {\
	case (HUD_PANEL_RADAR):\
		HUD_Radar(); break;\
	case (HUD_PANEL_WEAPONS):\
		HUD_Weapons(); break;\
	case (HUD_PANEL_AMMO):\
		HUD_Ammo(); break;\
	case (HUD_PANEL_POWERUPS):\
		HUD_Powerups(); break;\
	case (HUD_PANEL_HEALTHARMOR):\
		HUD_HealthArmor(); break;\
	case (HUD_PANEL_NOTIFY):\
		HUD_Notify(); break;\
	case (HUD_PANEL_TIMER):\
		HUD_Timer(); break;\
	case (HUD_PANEL_SCORE):\
		HUD_Score(); break;\
	case (HUD_PANEL_RACETIMER):\
		HUD_RaceTimer(); break;\
	case (HUD_PANEL_VOTE):\
		HUD_VoteWindow(); break;\
	case (HUD_PANEL_MODICONS):\
		HUD_ModIcons(); break;\
	case (HUD_PANEL_PRESSEDKEYS):\
		HUD_DrawPressedKeys(); break;\
	case (HUD_PANEL_CHAT):\
		HUD_Chat(); break;\
	case (HUD_PANEL_ENGINEINFO):\
		HUD_EngineInfo(); break;\
	case (HUD_PANEL_INFOMESSAGES):\
		 HUD_InfoMessages(); break;\
} ENDS_WITH_CURLY_BRACE

void HUD_Main (void)
{
	float i;
	// global hud alpha fade
	if(menu_enabled == 1)
		hud_fade_alpha = 1;
	else
		hud_fade_alpha = (1 - autocvar__menu_alpha);

	if(scoreboard_fade_alpha)
		hud_fade_alpha = (1 - scoreboard_fade_alpha);

	if(intermission == 2) // no hud during mapvote
		hud_fade_alpha = 0;
	else if(autocvar__menu_alpha == 0 && scoreboard_fade_alpha == 0)
		hud_fade_alpha = 1;

	hud_fontsize = HUD_GetFontsize("hud_fontsize");

	if(!autocvar__hud_configure && !hud_fade_alpha)
		return;

	// Drawing stuff
	if (hud_skin_path != autocvar_hud_skin)
	{
		if (hud_skin_path)
			strunzone(hud_skin_path);
		hud_skin_path = strzone(strcat("gfx/hud/", autocvar_hud_skin));
	}

	// HUD configure visible grid
	if(autocvar__hud_configure && autocvar_hud_configure_grid && autocvar_hud_configure_grid_alpha)
	{
		// x-axis
		for(i = 0; i < 1/bound(0.005, autocvar_hud_configure_grid_xsize, 0.2); ++i)
		{
			drawfill(eX * i * vid_conwidth * bound(0.005, autocvar_hud_configure_grid_xsize, 0.2), eX + eY * vid_conheight, '0.5 0.5 0.5', autocvar_hud_configure_grid_alpha, DRAWFLAG_NORMAL);
		}
		// y-axis
		for(i = 0; i < 1/bound(0.005, autocvar_hud_configure_grid_ysize, 0.2); ++i)
		{
			drawfill(eY * i * vid_conheight * bound(0.005, autocvar_hud_configure_grid_ysize, 0.2), eY + eX * vid_conwidth, '0.5 0.5 0.5', autocvar_hud_configure_grid_alpha, DRAWFLAG_NORMAL);
		}
	}

	// draw the dock
	if(autocvar_hud_dock != "" && autocvar_hud_dock != "0")
	{
		float f;
		vector color;
		float hud_dock_color_team = autocvar_hud_dock_color_team;
		if((teamplay) && hud_dock_color_team) {
			f = stof(getplayerkey(player_localentnum - 1, "colors"));
			color = colormapPaletteColor(mod(f, 16), 1) * hud_dock_color_team;
		}
		else if(autocvar_hud_configure_teamcolorforced && autocvar__hud_configure && hud_dock_color_team) {
			color = '1 0 0' * hud_dock_color_team;
		}
		else
		{
			string hud_dock_color = autocvar_hud_dock_color;
			if(hud_dock_color == "shirt") {
				f = stof(getplayerkey(player_localentnum - 1, "colors"));
				color = colormapPaletteColor(floor(f / 16), 0);
			}
			else if(hud_dock_color == "pants") {
				f = stof(getplayerkey(player_localentnum - 1, "colors"));
				color = colormapPaletteColor(mod(f, 16), 1);
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
		if(hud_panelorder_prev)
			strunzone(hud_panelorder_prev);
		hud_panelorder_prev = strzone(autocvar__hud_panelorder);
		tokenize_console(autocvar__hud_panelorder);
		for(i = 0; i < HUD_PANEL_NUM; ++i) {
			panel_order[i] = stof(argv(i));
		}
	}
	// draw panels in order specified by panel_order array
	for(i = HUD_PANEL_NUM - 1; i >= 0; --i) {
		if(i != HUD_PANEL_CHAT || !autocvar__con_chat_maximized) // don't draw maximized chat panel twice!
			HUD_DrawPanel(panel_order[i]);
	}

	// draw chat panel on top if it is maximized
	if(autocvar__con_chat_maximized)
		HUD_Chat(); // HUD_DrawPanel(HUD_PANEL_CHAT);

	// TODO hud_'ify these
	if (autocvar_cl_showspeed)
		HUD_ShowSpeed();
	if (autocvar_cl_showacceleration)
		HUD_ShowAcceleration();

	if (autocvar__hud_configure && spectatee_status && hud_configure_prev == -1) // try to join if we are in hud_configure mode, but still spectating, and in the first frame (in order to get rid of motd when launching a server via the menu "HUD Setup" button)
		localcmd("cmd selectteam auto; cmd join\n");

	hud_configure_prev = autocvar__hud_configure;

	if (!autocvar__hud_configure) // hud config mode disabled, enable normal alpha stuff again
		if (menu_enabled)
			menu_enabled = 0;
}
