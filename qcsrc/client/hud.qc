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

// draw HUD element with image from gfx/hud/hud_skin/foo.tga if it exists, otherwise gfx/hud/default/foo.tga
void drawpic_skin(vector pos, string pic, vector sz, vector color, float alpha, float drawflag) {
	drawpic(pos, strcat("gfx/hud/", cvar_string("hud_skin"), "/", pic), sz, color, alpha, drawflag);
}

void drawpic_skin_expanding(vector pos, string pic, vector sz, vector rgb, float alpha, float flag, float fadelerp) {
	drawpic_expanding(pos, strcat("gfx/hud/", cvar_string("hud_skin"), "/", pic), sz, rgb, alpha, flag, fadelerp);
}

void drawpic_skin_expanding_two(vector pos, string pic, vector sz, vector rgb, float alpha, float flag, float fadelerp) {
	drawpic_expanding_two(pos, strcat("gfx/hud/", cvar_string("hud_skin"), "/", pic), sz, rgb, alpha, flag, fadelerp);
}

// return HUD background color
vector HUD_GetBgColor()
{
	vector color;
	if (teamplay)
		GetTeamRGB(myteam) * hud_color_bg_team;
	else {
		// allow custom HUD colors in non-teamgames
		color_x = cvar("hud_color_bg_r");
		color_y = cvar("hud_color_bg_g");
		color_z = cvar("hud_color_bg_b");
	}
	return color;
}

// return accuracy text color
vector HUD_AccuracyColor(float accuracy)
{
	vector rgb;
	float yellow_accuracy = cvar("hud_weaponicons_accuracy_yellow"); // value at which this function returns yellow
	if(accuracy >= 100) {
		rgb_x = 0;
		rgb_y = 1;
	}
	else if(accuracy > yellow_accuracy) {
		rgb_x = 1 - (accuracy-yellow_accuracy)/(100-yellow_accuracy); // red value between 1 -> 0
		rgb_y = 1;
	}
	else {
		rgb_x = 1;
		rgb_y = accuracy/yellow_accuracy; // green value between 0 -> 1
	}
	rgb_z = 0;
	return rgb;
}

// draw number in the XSCALE font
void HUD_DrawXNum (vector pos, float num, float digits, float showsign, float lettersize, vector rgb, float highlighted, float stroke, float alpha, float dflags)
{
	float l, i;
	string str, tmp, l_length;
	float minus, plus;
	vector vsize, num_color;

	vsize_x = vsize_y = lettersize;
	vsize_z = 0;

	// showsign 1: always prefix with minus sign (useful in race distribution display)
	// showsign 2: always prefix with plus sign (useful in race distribution display)
	// showsign 3: prefix with minus sign if negative, plus sign if positive (useful in score distribution display)

	if((showsign == 2 && num >= 0) || (num > 0 && showsign == 3))
	{
		plus = true;
		pos_x -= lettersize;
	} else
		plus = false;

	if(num < 0 || (num < 0 && showsign == 3) || (showsign == 1 && num <= 0))
	{
		minus = true;
		num = -num;
		pos_x -= lettersize;
	} else
		minus = false;

	if(digits < 0)
	{
		tmp = ftos(num);
		digits = -digits;
		str = strcat(substring("0000000000", 0, digits - strlen(tmp)), tmp);
	} else
		str = ftos(num);

	l = strlen(str);
	l_length = ftos(l);

	if(l > digits)
	{
		str = substring(str, l-digits, 999);
		l = strlen(str);
	} else if(l < digits)
		pos_x += (digits-l) * lettersize;

	if (highlighted == 1) {
		vector hl_size;
		hl_size_x = vsize_x * l + vsize_x * 0.2;
		hl_size_y = vsize_y * 1.1;
		hl_size_z = 0;
		if(minus)
			hl_size_x = hl_size_x + vsize_x;

		vector hl_pos;
		hl_pos_x = pos_x - lettersize/10;
		hl_pos_y = pos_y - lettersize/20;
		hl_pos_z = 0;

		drawpic_skin(hl_pos, strcat("num_leading_", l_length), hl_size, '1 1 1', alpha, dflags);
	}

	if (stroke == 1)
		num_color = '1 1 1';
	else
		num_color = rgb;

	if(minus)
	{
		if (stroke == 1)
			drawpic_skin(pos, "num_minus_stroke", vsize, rgb, alpha, dflags);
		drawpic_skin(pos, "num_minus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	} else if(plus)
	{
		if (stroke == 1)
			drawpic_skin(pos, "num_plus_stroke", vsize, rgb, alpha, dflags);
		drawpic_skin(pos, "num_plus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}

	for(i = 0; i < l; ++i)
	{
		tmp = substring(str, i, 1);
		if (stroke == 1)
			drawpic_skin(pos, strcat("num_", tmp, "_stroke"), vsize, rgb, alpha, dflags);
		drawpic_skin(pos, strcat("num_", tmp), vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}
}

// color the number differently based on how big it is (used in the health/armor panel)
void HUD_DrawXNum_Colored (vector pos, float x, float digits, float lettersize, float alpha)
{
	vector color;
	if(x > 200) {
		color_x = 0;
		color_y = 1;
		color_z = 0;
	}
	else if(x > 150) {
		color_x = 0.4 - (x-150)*0.02 * 0.4; //red value between 0.4 -> 0
		color_y = 0.9 + (x-150)*0.02 * 0.1; // green value between 0.9 -> 1
		color_z = 0;
	}
	else if(x > 100) {
		color_x = 1 - (x-100)*0.02 * 0.6; //red value between 1 -> 0.4
		color_y = 1 - (x-100)*0.02 * 0.1; // green value between 1 -> 0.9
		color_z = 1 - (x-100)*0.02; // blue value between 1 -> 0
	}
	else if(x > 50) {
		color_x = 1;
		color_y = 1;
		color_z = 0.2 + (x-50)*0.02 * 0.8; // blue value between 0.2 -> 1
	}
	else if(x > 20) {
		color_x = 1;
		color_y = (x-20)*90/27/100; // green value between 0 -> 1
		color_z = (x-20)*90/27/100 * 0.2; // blue value between 0 -> 0.2
	}
	else {
		color_x = 1;
		color_y = 0;
		color_z = 0;
	}
	HUD_DrawXNum(pos, x, digits, 0, lettersize, color, 0, 0, alpha, DRAWFLAG_NORMAL);
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
vector centerprint_start;
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

	if(cvar("scr_centertime") <= 0)
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
	if(cvar("con_chatpos") < 0)
		havail -= (-cvar("con_chatpos") + cvar("con_chat")) * cvar("con_chatsize"); // avoid overlapping chat
	if(havail > vid_conheight - 70)
		havail = vid_conheight - 70; // avoid overlapping HUD

	centerprint_start_x = 0;

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
	centerprint_start_y =
		min(
			max(
				max(scoreboard_bottom, vid_conheight * 0.5 + 16),
				(havail - h)/2
			),
			havail - h
		);
#endif

	centerprint_num = i;
	centerprint_expire = time + cvar("scr_centertime");
}

void HUD_DrawCenterPrint (void)
{
	float i;
	vector pos;
	string ts;
	float a;

	//if(time > centerprint_expire)
	//	return;

	//a = bound(0, 1 - 2 * (time - centerprint_expire), 1);
	a = bound(0, 1 - 4 * (time - centerprint_expire), 1);
	//sz = 1.2 / (a + 0.2);

	if(a <= 0)
		return;

	pos = centerprint_start;
	for (i=0; i<centerprint_num; i = i + 1)
	{
		pos_x = (vid_conwidth - centerprint_width[i]) * 0.5;
		ts = centerprint_messages[i];
		if (ts != "")
		{
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			drawcolorcodedstring(pos, ts, centerprint_fontsize, a, DRAWFLAG_NORMAL);
			//  - '0 0.5 0' * (sz - 1) * centerprint_fontsize_x - '0.5 0 0' * (sz - 1) * centerprint_width[i] * centerprint_fontsize_y, centerprint_fontsize * sz
			pos_y = pos_y + centerprint_fontsize_y;
		}
		else
			// half height for empty lines looks better
			pos_y = pos_y + centerprint_fontsize_y * 0.5;
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

// Save the config
void HUD_Panel_ExportCfg(string cfgname)
{
	float fh;
	fh = fopen(strcat("hud_", cvar_string("hud_skin"), "_", cfgname, ".cfg"), FILE_WRITE);
	if(fh >= 0)
	{
		fputs(fh, strcat("seta hud_skin \"", cvar_string("hud_skin"), "\"", "\n"));
		fputs(fh, strcat("seta hud_bg \"", cvar_string("hud_bg"), "\"", "\n"));
		fputs(fh, strcat("seta hud_bg_color \"", cvar_string("hud_bg_color"), "\"", "\n"));
		fputs(fh, strcat("seta hud_bg_color_team \"", cvar_string("hud_bg_color_team"), "\"", "\n"));
		fputs(fh, strcat("seta hud_bg_alpha \"", cvar_string("hud_bg_alpha"), "\"", "\n"));
		fputs(fh, strcat("seta hud_bg_border \"", cvar_string("hud_bg_border"), "\"", "\n"));
		fputs(fh, strcat("seta hud_bg_padding \"", cvar_string("hud_bg_padding"), "\"", "\n"));
		fputs(fh, strcat("seta hud_fg_alpha) \"", cvar_string("hud_fg_alpha"), "\"", "\n"));
		fputs(fh, "\n");

		fputs(fh, strcat("seta hud_dock \"", cvar_string("hud_dock"), "\"", "\n"));
		fputs(fh, strcat("seta hud_dock_color \"", cvar_string("hud_dock_color"), "\"", "\n"));
		fputs(fh, strcat("seta hud_dock_color_team \"", cvar_string("hud_dock_color_team"), "\"", "\n"));
		fputs(fh, strcat("seta hud_dock_alpha \"", ftos(cvar("hud_dock_alpha")), "\"", "\n"));
		fputs(fh, "\n");

		fputs(fh, strcat("seta hud_progressbar_alpha ", ftos(cvar("hud_progressbar_alpha")), "\n"));
		fputs(fh, strcat("seta hud_progressbar_strength_color \"", cvar_string("hud_progressbar_strength_color"), "\"", "\n"));
		fputs(fh, strcat("seta hud_progressbar_shield_color \"", cvar_string("hud_progressbar_shield_color"), "\"", "\n"));
		fputs(fh, strcat("seta hud_progressbar_health_color \"", cvar_string("hud_progressbar_health_color"), "\"", "\n"));
		fputs(fh, strcat("seta hud_progressbar_armor_color \"", cvar_string("hud_progressbar_armor_color"), "\"", "\n"));
		fputs(fh, strcat("seta hud_progressbar_fuel_color \"", cvar_string("hud_progressbar_fuel_color"), "\"", "\n"));
		fputs(fh, strcat("seta hud_progressbar_nexball_color \"", cvar_string("hud_progressbar_nexball_color"), "\"", "\n"));
		fputs(fh, "\n");

		// common cvars for all panels
		float i;
		for (i = 0; i < HUD_PANEL_NUM; ++i)
		{
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), " ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i)))), "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_pos \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_pos")), "\"", "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_size \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_size")), "\"", "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_bg \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_bg")), "\"", "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_bg_color \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_bg_color")), "\"", "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_bg_color_team \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_bg_color_team")), "\"", "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_bg_alpha \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_bg_alpha")), "\"", "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_bg_border \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_bg_border")), "\"", "\n"));
			fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_bg_padding \"", cvar_string(strcat("hud_", HUD_Panel_GetName(i), "_bg_padding")), "\"", "\n"));
			switch(i) {
				case 0:
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_accuracy_height ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_accuracy_height"))), "\n"));
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_accuracy_yellow ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_accuracy_yellow"))), "\n"));
					break;
				case 1:
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_onlycurrent ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_onlycurrent"))), "\n"));
					break;
				case 2:
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_flip ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_flip"))), "\n"));
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_mirror ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_mirror"))), "\n"));
					break;
				case 3:
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_flip ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_flip"))), "\n"));
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_mirror ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_mirror"))), "\n"));
					break;
				case 4:
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_flip ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_flip"))), "\n"));
					break;
				case 9:
					fputs(fh, strcat("seta hud_", HUD_Panel_GetName(i), "_alreadyvoted_alpha ", ftos(cvar(strcat("hud_", HUD_Panel_GetName(i), "_alreadyvoted_alpha"))), "\n"));
					break;
			}
			fputs(fh, "\n");
		}

		print("^2Successfully exported to hud_", cvar_string("hud_skin"), "_", cfgname, ".cfg! (Note: It's saved in data/data/)\n");
	}
	fclose(fh);
}

vector HUD_Panel_GetMinSize(float id)
{
	vector mySize;
	// note: please only set mySize_y on aspect ratio forced panels
	switch(id) {
		case 0: 
			mySize_x = 1/10; // at least 1/10 * height
			mySize_y = 1/26; // at least 1/26 * width
			break;
		case 1: 
			if(cvar("hud_inventory_onlycurrent"))
				mySize_y = 2/5; //  2/5 width
			else
				mySize_x = 0.7; // at least 0.7 * height
			break;
		case 3: 
			if(cvar("hud_healtharmor") == 2)
				mySize_y = 0.23; // 0.23 * width, trial and error...
			break;
		case 4: 
			mySize_x = 1.2; // 12/10 * height, as panel cant support more than 10 entries...
			mySize_y = 1/12; // 1/12 * width
			break;
		case 5: 
			mySize_y = 1/4.1; // 1/4.1 * width, trial and error...
			break;
		case 7: 
			mySize_y = 1/4; // 1/4 * width
			break;
		case 8: 
			mySize_y = 1/4; // 1/4 * width
			break;
		case 9: 
			mySize_y = 1/4; // 1/4 * width
			break;
		case 10: 
			mySize_y = 1/2; // 1/2 * width
			break;
		case 11: 
			mySize_y = 0.5898; // 0.5898 * width, reason: bg has weird dimensions...
			break;
	}
	if(!mySize_x)
		mySize_x = 1/mySize_y;
	return mySize;
}

// return active status of panel
float HUD_Panel_CheckActive(float id)
{
	if (cvar_or(strcat("hud_", HUD_Panel_GetName(id)), 1))
		return 1;
	return 0;
}

// return size of given panel
vector HUD_Panel_GetSize(float id)
{
	vector mySize;
	mySize = stov(cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_size")));

	mySize = eX * mySize_x * vid_conwidth + eY * mySize_y * vid_conheight;

	if(disable_menu_alphacheck == 2 && id == highlightedPanel)
	{
		vector menu_enable_maxsize, menu_enable_size;
		menu_enable_maxsize = '0 0 0'; // shut up FTEQCC
		menu_enable_maxsize_x = 0.3 * vid_conwidth;
		menu_enable_maxsize_y = 0.18 * vid_conheight;
		if(mySize_x > mySize_y)
		{
			if(mySize_y > menu_enable_maxsize_y)
			{
				menu_enable_size_y = menu_enable_maxsize_y;
				menu_enable_size_x = mySize_x * (menu_enable_maxsize_y/mySize_y);
				mySize = (1 - cvar("_menu_alpha")) * mySize + (cvar("_menu_alpha")) * menu_enable_size;
			}
		}
		else
		{
			if(mySize_x > menu_enable_maxsize_x)
			{
				menu_enable_size_x = menu_enable_maxsize_x;
				menu_enable_size_y = mySize_y * (menu_enable_maxsize_x/mySize_x);
				mySize = (1 - cvar("_menu_alpha")) * mySize + (cvar("_menu_alpha")) * menu_enable_size;
			}
		}
	}
	return mySize;
}

// return pos of given panel
vector HUD_Panel_GetPos(float id)
{
	vector pos;
	pos = stov(cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_pos")));

	pos = eX * pos_x * vid_conwidth + eY * pos_y * vid_conheight;

	if (pos_x < 0)
		pos_x = vid_conwidth + pos_x;
	if (pos_y < 0)
		pos_y = vid_conheight + pos_y;

	if(disable_menu_alphacheck == 2 && id == highlightedPanel)
	{
		vector mySize, menu_enable_panelpos;
		mySize = HUD_Panel_GetSize(id);
		if(mySize_x > mySize_y)
			menu_enable_panelpos = eX * 0.5 * vid_conwidth - eX * 0.5 * mySize_x + eY * 0.82 * vid_conheight;
		else
			menu_enable_panelpos = eY * 0.5 * vid_conheight - eY * 0.5 * mySize_y + eX * 0.7 * vid_conwidth;
		pos = (1 - cvar("_menu_alpha")) * pos + (cvar("_menu_alpha")) * menu_enable_panelpos;
	}
	return pos;
}

float HUD_Panel_GetBorder(float id)
{
	string border;
	border = cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_bg_border"));
	if(border == "")
		border = cvar_string("hud_bg_border");
	return stof(border);
}

vector HUD_Panel_GetColor(float id)
{
	float f;
	vector color_vec;
	string color;

	// fetch per-panel color
	if(teamplay && cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_bg_color_team")) != "") {
		f = stof(getplayerkey(self.sv_entnum, "colors"));
		color = vtos(colormapPaletteColor(mod(f, 16), 1) * cvar(strcat("hud_", HUD_Panel_GetName(id), "_bg_color_team")));
	}
	else
		color = cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_bg_color"));
	color_vec = stov(color);

	if(color == "") { // fetch default color
		color = cvar_string("hud_bg_color");
		color_vec = stov(color);
		if(teamplay && cvar(strcat("hud_bg_color_team"))) {
			f = stof(getplayerkey(self.sv_entnum, "colors"));
			color_vec = colormapPaletteColor(mod(f, 16), 1) * cvar("hud_bg_color_team");
		}
		else if(color == "shirt") {
			f = stof(getplayerkey(self.sv_entnum, "colors"));
			color_vec = colormapPaletteColor(floor(f / 16), 0);
		}
		else if(color == "pants") {
			f = stof(getplayerkey(self.sv_entnum, "colors"));
			color_vec = colormapPaletteColor(mod(f, 16), 1);
		}
	}
	else if(color == "shirt") {
		f = stof(getplayerkey(self.sv_entnum, "colors"));
		color_vec = colormapPaletteColor(floor(f / 16), 0);
	}
	else if(color == "pants") {
		f = stof(getplayerkey(self.sv_entnum, "colors"));
		color_vec = colormapPaletteColor(mod(f, 16), 1);
	}
	return color_vec;
}

vector HUD_Panel_Dock_GetColor(void)
{
	float f;
	vector color_vec;
	string color;
	color = cvar_string("hud_dock_color");
	color_vec = stov(color);
	if(teamplay && cvar(strcat("hud_dock_color_team"))) {
		f = stof(getplayerkey(self.sv_entnum, "colors"));
		color_vec = colormapPaletteColor(mod(f, 16), 1) * cvar("hud_dock_color_team");
	}
	else if(color == "shirt") {
		f = stof(getplayerkey(self.sv_entnum, "colors"));
		color_vec = colormapPaletteColor(floor(f / 16), 0);
	}
	else if(color == "pants") {
		f = stof(getplayerkey(self.sv_entnum, "colors"));
		color_vec = colormapPaletteColor(mod(f, 16), 1);
	}
	return color_vec;
}

float HUD_Panel_GetBgAlpha(float id)
{
	string alpha;
	alpha = cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_bg_alpha"));
	if(alpha == "")
		alpha = cvar_string("hud_bg_alpha");

	if(hud_configure)
		alpha = ftos(max(cvar("hud_configure_bg_minalpha"), stof(alpha)));

	if(hud_configure && !cvar(strcat("hud_", HUD_Panel_GetName(id)))) // ALWAYS show disabled panels at 0.25 alpha when in config mode
		return 0.25;

	if(disable_menu_alphacheck == 2 && highlightedPanel == id) // don't fade this panel when showing the panel-specific menu dialog
		return stof(alpha);
	else
		return stof(alpha) * menu_fade_alpha;
}

float HUD_Panel_GetFgAlpha(float id)
{
	float alpha;
	alpha = hud_fg_alpha;

	if(hud_configure && !cvar(strcat("hud_", HUD_Panel_GetName(id)))) // ALWAYS show disabled panels at 0.25 alpha when in config mode
		return 0.25;

	if(disable_menu_alphacheck == 2 && highlightedPanel == id) // don't fade this panel when showing the panel-specific menu dialog
		return alpha;
	else
		return alpha * menu_fade_alpha;
}

float HUD_Panel_GetPadding(float id)
{
	string padding;
	padding = cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_bg_padding"));
	if(padding == "")
		padding = cvar_string("hud_bg_padding");

	vector mySize;
	mySize = HUD_Panel_GetSize(id);
	float smallestsize;
	smallestsize = min(mySize_x, mySize_y);
	return min(smallestsize/2 - 5, stof(padding));
}

// draw the background/borders
void HUD_Panel_DrawBg(float id, vector pos, vector mySize, float alpha)
{
	if(!hud_configure && cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_bg")) == "0")
		return;

	string bg;
	bg = cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_bg"));
	if(bg == "")
		bg = cvar_string("hud_bg");

	if(bg == "0" && hud_configure) {
		bg = "border"; // we probably want to see a background in config mode at all times...
	}

	if(bg != "0")
	{
		float border;
		border = max(0.0000001, HUD_Panel_GetBorder(id)); // draw_BorderPicture does not like border = 0

		vector color;
		color = HUD_Panel_GetColor(id);

		if(alpha)
			alpha = HUD_Panel_GetBgAlpha(id) * alpha; // allow panels to fade in/out by passing an alpha value
		else
			alpha = HUD_Panel_GetBgAlpha(id);

		draw_BorderPicture(pos - '1 1 0' * border, strcat("gfx/hud/", cvar_string("hud_skin"), "/", bg), mySize + '1 1 0' * 2 * border, color, alpha, '1 1 0' * (border/BORDER_MULTIPLIER));
	}
}

void HUD_Panel_DrawProgressBar(vector pos, float vertical, vector mySize, vector color, float alpha, float drawflag)
{
//float	drawsubpic(vector position, vector size, string pic, vector srcPosition, vector srcSize, vector rgb, float alpha, float flag) = #328;
	string pic;
	pic = strcat("gfx/hud/", cvar_string("hud_skin"), "/");
	if(vertical) {
		drawsubpic(pos, eY * min(mySize_y * 0.5, mySize_x) + eX * mySize_x, strcat(pic, "statusbar_vertical"), '0 0 0', '1 0.25 0', color, alpha, drawflag);
		if(mySize_y/mySize_x > 2)
			drawsubpic(pos + eY * mySize_x, eY * (mySize_y - 2 * mySize_x) + eX * mySize_x, strcat(pic, "statusbar_vertical"), '0 0.25 0', '1 0.5 0', color, alpha, drawflag);
		drawsubpic(pos + eY * mySize_y - eY * min(mySize_y * 0.5, mySize_x), eY * min(mySize_y * 0.5, mySize_x) + eX * mySize_x, strcat(pic, "statusbar_vertical"), '0 0.75 0', '1 0.25 0', color, alpha, drawflag);
	} else {
		drawsubpic(pos, eX * min(mySize_x * 0.5, mySize_y) + eY * mySize_y, strcat(pic, "statusbar"), '0 0 0', '0.25 1 0', color, alpha, drawflag);
		if(mySize_x/mySize_y > 2)
			drawsubpic(pos + eX * mySize_y, eX * (mySize_x - 2 * mySize_y) + eY * mySize_y, strcat(pic, "statusbar"), '0.25 0 0', '0.5 1 0', color, alpha, drawflag);
		drawsubpic(pos + eX * mySize_x - eX * min(mySize_x * 0.5, mySize_y), eX * min(mySize_x * 0.5, mySize_y) + eY * mySize_y, strcat(pic, "statusbar"), '0.75 0 0', '0.25 1 0', color, alpha, drawflag);
	}
}

vector HUD_Panel_GetProgressBarColor(string item)
{
	return stov(cvar_string(strcat("hud_progressbar_", item, "_color")));
}

// check if move will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckMove(float id, vector myPos, vector mySize)
{
	float i;

	vector myTarget;
	myTarget = myPos;

	vector targPos;
	vector targSize;
	vector myCenter;
	vector targCenter;
	myCenter = '0 0 0'; // shut up fteqcc, there IS a reference
	targCenter = '0 0 0'; // shut up fteqcc, there IS a reference

	for (i = 0; i < HUD_PANEL_NUM; ++i) {
		if(i == id || !HUD_Panel_CheckActive(i))
			continue;

		targPos = HUD_Panel_GetPos(i) - '1 1 0' * HUD_Panel_GetBorder(id);
		targSize = HUD_Panel_GetSize(i) + '2 2 0' * HUD_Panel_GetBorder(id);

		if(myPos_y + mySize_y < targPos_y)
			continue;
		if(myPos_y > targPos_y + targSize_y)
			continue;

		if(myPos_x + mySize_x < targPos_x)
			continue;
		if(myPos_x > targPos_x + targSize_x)
			continue;

		// OK, there IS a collision.

		myCenter_x = myPos_x + 0.5 * mySize_x;
		myCenter_y = myPos_y + 0.5 * mySize_y;

		targCenter_x = targPos_x + 0.5 * targSize_x;
		targCenter_y = targPos_y + 0.5 * targSize_y;

		if(myCenter_x < targCenter_x && myCenter_y < targCenter_y) // top left (of the target panel)
		{
			if(myPos_x + mySize_x - targPos_x < myPos_y + mySize_y - targPos_y) // push it to the side
				myTarget_x = targPos_x - mySize_x;
			else // push it upwards
				myTarget_y = targPos_y - mySize_y;
		}
		else if(myCenter_x > targCenter_x && myCenter_y < targCenter_y) // top right
		{
			if(targPos_x + targSize_x - myPos_x < myPos_y + mySize_y - targPos_y) // push it to the side
				myTarget_x = targPos_x + targSize_x;
			else // push it upwards
				myTarget_y = targPos_y - mySize_y;
		}
		else if(myCenter_x < targCenter_x && myCenter_y > targCenter_y) // bottom left
		{
			if(myPos_x + mySize_x - targPos_x < targPos_y + targSize_y - myPos_y) // push it to the side
				myTarget_x = targPos_x - mySize_x;
			else // push it downwards
				myTarget_y = targPos_y + targSize_y;
		}
		else if(myCenter_x > targCenter_x && myCenter_y > targCenter_y) // bottom right
		{
			if(targPos_x + targSize_x - myPos_x < targPos_y + targSize_y - myPos_y) // push it to the side
				myTarget_x = targPos_x + targSize_x;
			else // push it downwards
				myTarget_y = targPos_y + targSize_y;
		}
	}

	return myTarget;
}

void HUD_Panel_SetPos(float id, vector pos)
{
	vector oldPos;
	oldPos = HUD_Panel_GetPos(id);

	vector mySize;
	mySize = HUD_Panel_GetSize(id);

	if(cvar("hud_configure_checkcollisions"))
		pos = HUD_Panel_CheckMove(id, pos, mySize);

	pos_x = bound(0, pos_x, vid_conwidth - mySize_x);
	pos_y = bound(0, pos_y, vid_conheight - mySize_y);

	if(cvar("hud_configure_grid"))
	{
		pos_x = floor(pos_x/cvar("hud_configure_grid_x") + 0.5) * cvar("hud_configure_grid_x");
		pos_y = floor(pos_y/cvar("hud_configure_grid_y") + 0.5) * cvar("hud_configure_grid_y");
	}

	if (pos_x + 0.5 * mySize_x > 0.5 * vid_conwidth)
		pos_x = pos_x - vid_conwidth;
	if (pos_y + 0.5 * mySize_y > 0.5 * vid_conheight)
		pos_y = pos_y - vid_conheight;

	string s;
	s = strcat(ftos(pos_x/vid_conwidth), " ", ftos(pos_y/vid_conheight));

	cvar_set(strcat("hud_", HUD_Panel_GetName(id), "_pos"), s);
}

// check if resize will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckResize(float id, vector myPos, vector mySize)
{
	float i;

	vector myTarget;
	myTarget = mySize;

	vector targPos;
	vector targSize;
	vector myCenter;
	vector targCenter;
	myCenter = '0 0 0'; // shut up fteqcc, there IS a reference
	targCenter = '0 0 0'; // shut up fteqcc, there IS a reference

	for (i = 0; i < HUD_PANEL_NUM; ++i) {
		if(i == id || !HUD_Panel_CheckActive(i))
			continue;

		targPos = HUD_Panel_GetPos(i);
		targSize = HUD_Panel_GetSize(i);

		targPos = HUD_Panel_GetPos(i) - '1 1 0' * HUD_Panel_GetBorder(id);
		targSize = HUD_Panel_GetSize(i) + '2 2 0' * HUD_Panel_GetBorder(id);

		if(myPos_y + mySize_y < targPos_y)
			continue;
		if(myPos_y > targPos_y + targSize_y)
			continue;

		if(myPos_x + mySize_x < targPos_x)
			continue;
		if(myPos_x > targPos_x + targSize_x)
			continue;

		// OK, there IS a collision.

		myCenter_x = myPos_x + 0.5 * mySize_x;
		myCenter_y = myPos_y + 0.5 * mySize_y;

		targCenter_x = targPos_x + 0.5 * targSize_x;
		targCenter_y = targPos_y + 0.5 * targSize_y;

		if(myCenter_x < targCenter_x && myCenter_y < targCenter_y) // top left (of target panel)
		{
			if(myPos_x + mySize_x - targPos_x < myPos_y + mySize_y - targPos_y) // push it to the side
				myTarget_x = targPos_x - myPos_x;
			else // push it upwards
				myTarget_y = targPos_y - myPos_y;
		}
		else if(myCenter_x > targCenter_x && myCenter_y < targCenter_y) // top right
		{
			if(targPos_x + targSize_x - myPos_x < myPos_y + mySize_y - targPos_y) // push it to the side
				myTarget_x = targPos_x + targSize_x;
			else // push it upwards
				myTarget_y = targPos_y - myPos_y;
		}
		else if(myCenter_x < targCenter_x && myCenter_y > targCenter_y) // bottom left
		{
			if(myPos_x + mySize_x - targPos_x < targPos_y + targSize_y - myPos_y) // push it to the side
				myTarget_x = targPos_x - myPos_x;
			else // push it downwards
				myTarget_y = targPos_y + targSize_y;
		}
		else if(myCenter_x > targCenter_x && myCenter_y > targCenter_y) // bottom right
		{
			if(targPos_x + targSize_x - myPos_x < targPos_y + targSize_y - myPos_y) // push it to the side
				myTarget_x = targPos_x + targSize_x;
			else // push it downwards
				myTarget_y = targPos_y + targSize_y;
		}
	}

	return myTarget;
}

void HUD_Panel_SetPosSize(float id, vector resizeorigin)
{
	vector mySize, myPos;
	vector oldPos;

	if(resizeCorner == 1) {
		mySize_x = resizeorigin_x - (mousepos_x - panel_click_distance_x);
		mySize_y = resizeorigin_y - (mousepos_y - panel_click_distance_y);
	} else if(resizeCorner == 2) {		
		mySize_x = mousepos_x + panel_click_distance_x - resizeorigin_x;
		mySize_y = panel_click_distance_y + resizeorigin_y - mousepos_y;
	} else if(resizeCorner == 3) {
		mySize_x = resizeorigin_x + panel_click_distance_x - mousepos_x;
		mySize_y = mousepos_y + panel_click_distance_y - resizeorigin_y;
	} else { // resizeCorner == 4
		mySize_x = mousepos_x - (resizeorigin_x - panel_click_distance_x);
		mySize_y = mousepos_y - (resizeorigin_y - panel_click_distance_y);
	}

	// minimum panel size cap
	mySize_x = max(0.025 * vid_conwidth, mySize_x);
	mySize_y = max(0.025 * vid_conheight, mySize_y);

	if(id == 12) // some panels have their own restrictions, like the chat panel (which actually only moves the engine chat print around). Looks bad if it's too small.
	{
		mySize_x = max(15 * cvar("con_chatsize"), mySize_x);
		mySize_y = max(2 * cvar("con_chatsize") + 2 * HUD_Panel_GetPadding(id), mySize_y);
	}

	// cap against panel's own limits
	vector minSize;
	minSize = HUD_Panel_GetMinSize(id); // mySize_x at least minSize_x * mySize_y, and vice versa

	mySize_x = max(minSize_x * mySize_y, mySize_x);
	mySize_y = max(minSize_y * mySize_x, mySize_y);

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
	mySize_x = min(myPos_x + mySize_x, mySize_x);
	mySize_y = min(myPos_y + mySize_y, mySize_y);

	// bottom/right screen edges
	mySize_x = min(vid_conwidth - myPos_x, mySize_x); 
	mySize_y = min(vid_conheight - myPos_y, mySize_y); 

	if(cvar("hud_configure_checkcollisions")) {
		oldPos = myPos;
		mySize = HUD_Panel_CheckResize(id, myPos, mySize);
		myPos = HUD_Panel_CheckMove(id, myPos, mySize); // touching myPos won't do anything... unless we make it change mySize somehow, see next line
		mySize = mySize - myPos + oldPos; // TODO: this is still borked in some situations :(
	}

	if(cvar("hud_configure_grid"))
	{
		mySize_x = floor(mySize_x/cvar("hud_configure_grid_x") + 0.5) * cvar("hud_configure_grid_x");
		mySize_y = floor(mySize_y/cvar("hud_configure_grid_y") + 0.5) * cvar("hud_configure_grid_y");
	}

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

	string s;
	s = strcat(ftos(mySize_x/vid_conwidth), " ", ftos(mySize_y/vid_conheight));
	cvar_set(strcat("hud_", HUD_Panel_GetName(id), "_size"), s);

	s = strcat(ftos(myPos_x/vid_conwidth), " ", ftos(myPos_y/vid_conheight));
	cvar_set(strcat("hud_", HUD_Panel_GetName(id), "_pos"), s);
}

float mouseClicked;
float prevMouseClicked; // previous state
float prevMouseClickedTime; // time during previous mouse click, to check for doubleclicks
vector prevMouseClickedPos; // pos during previous mouse click, to check for doubleclicks

float menu_enabled;
float menu_enabled_time;
float HUD_Panel_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	if(!hud_configure)
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
		disable_menu_alphacheck = 1;
		menu_enabled = 1;
		menu_enabled_time = time;
		localcmd("menu_showhudexit\n");
	}

	else if(hit_con_bind)
		return false;

	return true; // Suppress ALL other input
}

void HUD_Panel_Mouse()
{
	// TODO: needs better check... is there any float that contains the current state of the menu? _menu_alpha isn't apparently updated the frame the menu gets enabled
	if (menu_enabled == 0) // menu dialog closed, enable normal alpha stuff again
		disable_menu_alphacheck = 0;
	if (cvar("_menu_alpha") == 0 && time - menu_enabled_time > 0.5)
		menu_enabled = 0;

	/*
	print("Disable menu_alphacheck: ", ftos(disable_menu_alphacheck), "\n");
	print("Highlighted: ", ftos(highlightedPanel), "\n");
	print("Menu alpha: ", cvar_string("_menu_alpha"), "\n");
	*/

	if(mouseClicked == 0 && disable_menu_alphacheck != 2) { // don't reset these variables in disable_menu_alphacheck mode 2!
		highlightedPanel = -1;
		highlightedAction = 0;
	}

	mousepos = mousepos + getmousepos();

	mousepos_x = bound(0, mousepos_x, vid_conwidth);
	mousepos_y = bound(0, mousepos_y, vid_conheight);

	drawpic(mousepos, strcat("gfx/menu/", cvar_string("menu_skin"), "/cursor.tga"), '32 32 0', '1 1 1', 1, DRAWFLAG_NORMAL);

	if(mouseClicked)
	{
		float i, border;
		vector panelPos;
		vector panelSize;

		for(i = 0; i < HUD_PANEL_NUM; ++i)
		{
			panelPos = HUD_Panel_GetPos(i);
			panelSize = HUD_Panel_GetSize(i);
			border = HUD_Panel_GetBorder(i);
			if(prevMouseClicked == 0) {
				// move
				if(mousepos_x >= panelPos_x && mousepos_y >= panelPos_y && mousepos_x <= panelPos_x + panelSize_x && mousepos_y <= panelPos_y + panelSize_y)
				{
					highlightedPanel = i;
					highlightedAction = 1;
				}
				// resize from topleft border
				else if(mousepos_x >= panelPos_x - border && mousepos_y >= panelPos_y - border && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 1;
				}
				// resize from topright border
				else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y - border && mousepos_x <= panelPos_x + panelSize_x + border && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 2;
				}
				// resize from bottomleft border
				else if(mousepos_x >= panelPos_x - border && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + panelSize_y + border)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 3;
				}
				// resize from bottomright border
				else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + panelSize_x + border && mousepos_y <= panelPos_y + panelSize_y + border)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 4;
				}
			}

			if(highlightedPanel == i)
			{
				if(prevMouseClicked == 0)
				{
					if(highlightedAction == 1)
						panel_click_distance = mousepos - panelPos;
					else if(highlightedAction == 2)
					{
						if(resizeCorner == 1) {
							panel_click_distance = mousepos - panelPos;
							panel_click_resizeorigin = panelPos + panelSize;
						} else if(resizeCorner == 2) {
							panel_click_distance_x = panelSize_x - mousepos_x + panelPos_x;
							panel_click_distance_y = mousepos_y - panelPos_y;
							panel_click_resizeorigin = panelPos + eY * panelSize_y;
						} else if(resizeCorner == 3) {
							panel_click_distance_x = mousepos_x - panelPos_x;
							panel_click_distance_y = panelSize_y - mousepos_y + panelPos_y;
							panel_click_resizeorigin = panelPos + eX * panelSize_x;
						} else if(resizeCorner == 4) {
							panel_click_distance = panelSize - mousepos + panelPos;
							panel_click_resizeorigin = panelPos;
						}
					}	
				}

				if(highlightedAction == 1)
					HUD_Panel_SetPos(i, mousepos - panel_click_distance);
				else if(highlightedAction == 2)
					HUD_Panel_SetPosSize(i, panel_click_resizeorigin);
			}
		}

		// doubleclick check
		if(time - prevMouseClickedTime < 0.4 && prevMouseClicked == 0 && prevMouseClickedPos == mousepos && highlightedPanel >= 0)
		{
			mouseClicked = 0; // to prevent spam, I guess.
			disable_menu_alphacheck = 2;
			menu_enabled = 1;
			menu_enabled_time = time;
			localcmd("menu_showhudoptions ", ftos(highlightedPanel), "\n");
			return;
		}
		if(prevMouseClicked == 0)
		{
			prevMouseClickedTime = time;
			prevMouseClickedPos = mousepos;
		}
	}
	prevMouseClicked = mouseClicked;
}

// Weapon icons (#0)
//
float weaponspace[10];
void HUD_WeaponIcons_Clear()
{
	float idx;
	for(idx = 0; idx < 10; ++idx)
		weaponspace[idx] = 0;
}

entity weaponorder[WEP_MAXCOUNT];

void weaponorder_swap(float i, float j, entity pass)
{
	entity h;
	h = weaponorder[i];
	weaponorder[i] = weaponorder[j];
	weaponorder[j] = h;
}

float weaponorder_cmp(float i, float j, entity pass)
{
	float d;
	d = mod(weaponorder[i].impulse + 9, 10) - mod(weaponorder[j].impulse + 9, 10);
	if(d)
		return d;
	d = weaponorder[i].weapon - weaponorder[j].weapon;
	return d;
}

void HUD_WeaponIcons(void)
{
	float id = HUD_PANEL_WEAPONICONS;
	float alpha, stat_weapons; // "constants"
	vector pos, mySize, accuracy_color;
	float i, weapid, fade, weapon_stats, weapon_hit, weapon_damage, weapon_cnt; // variables

	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	stat_weapons = getstati(STAT_WEAPONS);
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		self = get_weaponinfo(i);
		if(self.weapons && (self.impulse >= 0) && (stat_weapons & self.weapons) || hud_configure)
		{
			weaponorder[weapon_cnt] = self;
			++weapon_cnt;
		}
	}
	heapsort(weapon_cnt, weaponorder_swap, weaponorder_cmp, world);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	// hits
	weapon_stats = getstati(STAT_DAMAGE_HITS);
	weapon_number = weapon_stats & 63;
	weapon_hits[weapon_number-WEP_FIRST] = floor(weapon_stats / 64);
	// fired
	weapon_stats = getstati(STAT_DAMAGE_FIRED);
	weapon_number = weapon_stats & 63;
	weapon_fired[weapon_number-WEP_FIRST] = floor(weapon_stats / 64);

	if(cvar_or("hud_weaponicons_fade", 1))
	{
		fade = 3.2 - 2 * (time - weapontime);
		fade = bound(0.7, fade, 1);
	}
	else
		fade = 1;

	HUD_WeaponIcons_Clear();

	float rows, columns;
	rows = mySize_y/mySize_x;
	rows = bound(1, floor((sqrt(4 * (2/1) * rows * WEP_COUNT + rows * rows) + rows + 0.5) / 2), WEP_COUNT);
	//                               ^^^ weapon icon aspect goes here

	columns = ceil(WEP_COUNT/rows);
	float row, column;
	for(i = 0; i < weapon_cnt; ++i)
	{
		self = weaponorder[i];
		if((self.weapons && (self.impulse >= 0) && (stat_weapons & self.weapons)) || hud_configure)
		{
			weapid = self.impulse;

			alpha = (self.weapon == activeweapon) ? 1 : 0.6;

			weapon_hit = weapon_hits[self.weapon-WEP_FIRST];
			weapon_damage = weapon_fired[self.weapon-WEP_FIRST];

			// draw background behind currently selected weapon
			if(self.weapon == activeweapon)
				drawpic_skin(pos + eX * column * mySize_x*(1/columns) + eY * row * mySize_y*(1/rows), "weapon_current_bg", eX * mySize_x*(1/columns) + eY * mySize_y*(1/rows), '1 1 1', fade * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

			// draw the weapon accuracy on the HUD
			if(hud_accuracy_hud && !(gametype == GAME_RACE || gametype == GAME_CTS))
			{
				if(weapon_damage)
					weapon_stats = floor(100 * weapon_hit / weapon_damage);

				accuracy_color = HUD_AccuracyColor(weapon_stats);
				if(weapon_damage)
					drawpic_skin(pos + eX * column * mySize_x*(1/columns) + eY * row * mySize_y*(1/rows), "weapon_accuracy", eX * mySize_x*(1/columns) + eY * mySize_y*(1/rows), accuracy_color, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			}

			// draw the weapon icon
			drawpic_skin(pos + eX * column * mySize_x*(1/columns) + eY * row * mySize_y*(1/rows), strcat("weapon", self.netname), eX * mySize_x*(1/columns) + eY * mySize_y*(1/rows), '1 1 1', fade * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

			if(cvar_or("hud_weaponicons_number", 1))
				drawstring(pos + eX * column * mySize_x*(1/columns) + eY * row * mySize_y*(1/rows), ftos(weapid), '1 1 0' * 0.5 * mySize_y*(1/rows), '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}

}

// Inventory (#1)
//
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

void HUD_Inventory(void)
{
	float id = HUD_PANEL_INVENTORY;
	float i;
	float stat_items;

	vector pos, mySize, mysize, mypos;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	// ammo
	stat_items = getstati(STAT_ITEMS);
	for (i = 0; i < 4; ++i) {
		float a;
		a = getstati(GetAmmoStat(i)); // how much ammo do we have of type i?
		if(hud_configure)
			a = 100;

		if(cvar("hud_inventory_onlycurrent")) {
			if(hud_configure)
				i = 2;
			if (stat_items & GetAmmoItemCode(i) || hud_configure) {
				drawpic_skin(pos, GetAmmoPicture(i), '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				if(a < 10)
					HUD_DrawXNum(pos + eX * mySize_y + eY * 0.25 * mySize_y, a, strlen(ftos(a)), 0, 0.5 * mySize_y, '0.7 0 0', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				else
					HUD_DrawXNum(pos + eX * mySize_y + eY * 0.25 * mySize_y, a, strlen(ftos(a)), 0, 0.5 * mySize_y, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			}
			if(hud_configure)
				break;
		} else {
			if (a > 0) {
				if(mySize_x/mySize_y >= 10) { // arrange horizontally
					switch (i) {
						case 0: mypos_x = pos_x; 			mypos_y = pos_y; 			break; // shells
						case 1: mypos_x = pos_x + 0.25 * mySize_x;	mypos_y = pos_y; 			break; // bullets
						case 2: mypos_x = pos_x + 0.5  * mySize_x; 	mypos_y = pos_y; 			break; // rockets
						case 3: mypos_x = pos_x + 0.75 * mySize_x; 	mypos_y = pos_y;			break; // cells
					}
					mysize_x = 0.25 * mySize_x;
					mysize_y = mySize_y;
				} else if(mySize_x/mySize_y >= 2.5) { // arrange in a 2x2 grid
					switch (i) {
						case 0: mypos_x = pos_x + 0.5 * mySize_x; 	mypos_y = pos_y + 0.5 * mySize_y; 	break; // shells
						case 1: mypos_x = pos_x + 0.5 * mySize_x;	mypos_y = pos_y; 			break; // bullets
						case 2: mypos_x = pos_x; 			mypos_y = pos_y + 0.5 * mySize_y; 	break; // rockets
						case 3: mypos_x = pos_x; 			mypos_y = pos_y; 			break; // cells
					}
					mysize_x = 0.5 * mySize_x;
					mysize_y = 0.5 * mySize_y;
				} else { // arrange vertically
					switch (i) {
						case 0: mypos_x = pos_x; 			mypos_y = pos_y; 			break; // shells
						case 1: mypos_x = pos_x;			mypos_y = pos_y + 0.25 * mySize_y; 	break; // bullets
						case 2: mypos_x = pos_x; 			mypos_y = pos_y + 0.5  * mySize_y; 	break; // rockets
						case 3: mypos_x = pos_x; 			mypos_y = pos_y + 0.75 * mySize_y; 	break; // cells
					}
					mysize_x = mySize_x;
					mysize_y = 0.25 * mySize_y;
				}

				if (stat_items & GetAmmoItemCode(i))
					drawpic_skin(mypos, "ammo_current_bg", mysize, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawpic_skin(mypos + eY * 0.05 * mysize_y, GetAmmoPicture(i), '1 1 0' * 0.8 * mysize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				if (a < 10) {
					if(stat_items & GetAmmoItemCode(i))
						HUD_DrawXNum(mypos + eX * 0.8 * mysize_y + eY * 0.25 * mysize_y, a, strlen(ftos(a)), 0, 0.5 * mysize_y, '0.7 0 0', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
					else
						HUD_DrawXNum(mypos + eX * 0.8 * mysize_y + eY * 0.25 * mysize_y, a, strlen(ftos(a)), 0, 0.5 * mysize_y, '0.7 0 0', 0, 0, HUD_Panel_GetFgAlpha(id) * 0.7, DRAWFLAG_NORMAL);
				} else {
					if(stat_items & GetAmmoItemCode(i))
						HUD_DrawXNum(mypos + eX * 0.8 * mysize_y + eY * 0.25 * mysize_y, a, strlen(ftos(a)), 0, 0.5 * mysize_y, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
					else
						HUD_DrawXNum(mypos + eX * 0.8 * mysize_y + eY * 0.25 * mysize_y, a, strlen(ftos(a)), 0, 0.5 * mysize_y, '0.7 0.7 0.7', 0, 0, HUD_Panel_GetFgAlpha(id) * 0.7, DRAWFLAG_NORMAL);
				}
			}
		}
	}
}


// Powerups (#2)
//
void HUD_Powerups(void) {
	float id = HUD_PANEL_POWERUPS;
	float stat_items;
	stat_items = getstati(STAT_ITEMS);

	if(!hud_configure)
	{
		if not(stat_items & IT_STRENGTH)
			if not(stat_items & IT_INVINCIBLE)
				return;

		if (getstati(STAT_HEALTH) <= 0)
			return;
	}

	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	float strength_time, shield_time;

	strength_time = bound(0, getstatf(STAT_STRENGTH_FINISHED) - time, 99);
	shield_time = bound(0, getstatf(STAT_INVINCIBLE_FINISHED) - time, 99);

	if(hud_configure)
	{
		strength_time = 15;
		shield_time = 27;
	}

	float len;

	vector barpos, barsize;
	vector picpos;
	vector numpos;

	string leftname, rightname;
	float leftcnt, rightcnt;
	float leftexact, rightexact;
	float leftalpha, rightalpha;
	if (cvar(strcat("hud_", HUD_Panel_GetName(id), "_flip"))) {
		leftname = "strength";
		leftcnt = ceil(strength_time);
		leftexact = strength_time;

		rightname = "shield";
		rightcnt = ceil(shield_time);
		rightexact = shield_time;
	} else {
		leftname = "shield";
		leftcnt = ceil(shield_time);
		leftexact = shield_time;

		rightname = "strength";
		rightcnt = ceil(strength_time);
		rightexact = strength_time;
	}
	leftalpha = bound(0, leftexact, 1);
	rightalpha = bound(0, rightexact, 1);

	if (mySize_x/mySize_y > 4)
	{
		if(leftcnt)
		{
			len = strlen(ftos(leftcnt));

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos + eX * 0.5 * mySize_x - eX * 0.5 * mySize_x * min(1, leftcnt/30);
				barsize = eX * 0.5 * mySize_x * min(1, leftcnt/30) + eY * mySize_y;
				picpos = pos + eX * 0.5 * mySize_x - eX * mySize_y;
				numpos = picpos - eX * 2 * 0.5 * mySize_y + eX * (2-len) * 0.5 * mySize_y + eY * 0.25 * mySize_y;
			} else {
				barpos = pos;
				barsize = eX * 0.5 * mySize_x * min(1, leftcnt/30) + eY * mySize_y;
				picpos = pos;
				numpos = picpos + eX * mySize_y - eX * (2-len) * 0.5 * mySize_y + eY * 0.25 * mySize_y;
			}

			HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(leftname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			if(leftcnt <= 5)
				drawpic_skin_expanding_two(picpos, leftname, '1 1 0' * mySize_y, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE, bound(0, (leftcnt - leftexact) / 0.5, 1));
			else
				drawpic_skin(picpos, leftname, '1 1 0' * mySize_y, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			HUD_DrawXNum(numpos, leftcnt, 2, 0, 0.5 * mySize_y, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}

		if(rightcnt)
		{
			len = strlen(ftos(rightcnt));

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos + eX * 0.5 * mySize_x;
				barsize = eX * 0.5 * mySize_x * min(1, rightcnt/30) + eY * mySize_y;
				picpos = pos + eX * 0.5 * mySize_x;
				numpos = picpos + eX * mySize_y - eX * (2-len) * 0.5 * mySize_y + eY * 0.25 * mySize_y;
			} else {
				barpos = pos + eX * mySize_x - eX * 0.5 * mySize_x * min(1, rightcnt/30);
				barsize = eX * 0.5 * mySize_x * min(1, rightcnt/30) + eY * mySize_y;
				picpos = pos + eX * mySize_x - eX * mySize_y;
				numpos = picpos - eX * mySize_y + eY * 0.25 * mySize_y;
			}

			HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(rightname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			if(rightcnt <= 5)
				drawpic_skin_expanding_two(picpos, rightname, '1 1 0' * mySize_y, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE, bound(0, (rightcnt - rightexact) / 0.5, 1));
			else
				drawpic_skin(picpos, rightname, '1 1 0' * mySize_y, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			HUD_DrawXNum(numpos, rightcnt, 2, 0, 0.5 * mySize_y, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}
	}
	else if (mySize_x/mySize_y > 1.5)
	{
		if(leftcnt)
		{
			len = strlen(ftos(leftcnt));

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos + eX * mySize_x - eX * mySize_x * min(1, leftcnt/30);
				barsize = eX * mySize_x * min(1, leftcnt/30) + eY * 0.5 * mySize_y;
				picpos = pos + eX * mySize_x - eX * 0.5 * mySize_y;
				numpos = picpos - eX * len * 0.5 * mySize_y;
			} else {
				barpos = pos;
				barsize = eX * mySize_x * min(1, leftcnt/30) + eY * 0.5 * mySize_y;
				picpos = pos;
				numpos = picpos + eX * 0.5 * mySize_y;
			}

			HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(leftname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			if(leftcnt <= 5)
				drawpic_skin_expanding_two(picpos, leftname, '0.5 0.5 0' * mySize_y, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE, bound(0, (leftcnt - leftexact) / 0.5, 1));
			else
				drawpic_skin(picpos, leftname, '0.5 0.5 0' * mySize_y, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			HUD_DrawXNum(numpos, leftcnt, len, 0, 0.5 * mySize_y, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}

		if(rightcnt)
		{
			len = strlen(ftos(rightcnt));

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos + eX * mySize_x - eX * mySize_x * min(1, rightcnt/30) + eY * 0.5 * mySize_y;
				barsize = eX * mySize_x * min(1, rightcnt/30) + eY * 0.5 * mySize_y;
				picpos = pos + eX * mySize_x - eX * 0.5 * mySize_y + eY * 0.5 * mySize_y;
				numpos = picpos - eX * len * 0.5 * mySize_y;
			} else {
				barpos = pos + eY * 0.5 * mySize_y;
				barsize = eX * mySize_x * min(1, rightcnt/30) + eY * 0.5 * mySize_y;
				picpos = pos + eY * 0.5 * mySize_y;
				numpos = picpos + eX * 0.5 * mySize_y;
			}

			HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(rightname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			if(rightcnt <= 5)
				drawpic_skin_expanding_two(picpos, rightname, '0.5 0.5 0' * mySize_y, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE, bound(0, (rightcnt - rightexact) / 0.5, 1));
			else
				drawpic_skin(picpos, rightname, '0.5 0.5 0' * mySize_y, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			HUD_DrawXNum(numpos, rightcnt, len, 0, 0.5 * mySize_y, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}
	}
	else
	{
		if(leftcnt)
		{
			len = strlen(ftos(leftcnt));

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos;
				barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, leftcnt/30);
				picpos = pos + eX * 0.05 * mySize_x;
				numpos = pos + eX * ((2-len)/2) * 0.25 * mySize_x + eY * 0.4 * mySize_x;
			} else {
				barpos = pos + eY * mySize_y - eY * mySize_y * min(1, leftcnt/30);
				barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, leftcnt/30);
				picpos = pos + eX * 0.05 * mySize_x + eY * mySize_y - eY * 0.65 * mySize_x;
				numpos = pos + eX * ((2-len)/2) * 0.25 * mySize_x + eY * mySize_y - eY * 0.25 * mySize_x;
			}

			HUD_Panel_DrawProgressBar(barpos, 1, barsize, HUD_Panel_GetProgressBarColor(leftname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			if(leftcnt <= 5)
				drawpic_skin_expanding_two(picpos, leftname, '0.4 0.4 0' * mySize_x, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE, bound(0, (leftcnt - leftexact) / 0.5, 1));
			else
				drawpic_skin(picpos, leftname, '0.4 0.4 0' * mySize_x, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			HUD_DrawXNum(numpos, leftcnt, len, 0, 0.25 * mySize_x, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}

		if(rightcnt)
		{
			len = strlen(ftos(rightcnt));

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos + eX * 0.5 * mySize_x;
				barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, rightcnt/30);
				picpos = pos + eX * 0.05 * mySize_x + eX * 0.5 * mySize_x;
				numpos = pos + eX * ((2-len)/2) * 0.25 * mySize_x + eY * 0.4 * mySize_x + eX * 0.5 * mySize_x;
			} else {
				barpos = pos + eY * mySize_y - eY * mySize_y * min(1, rightcnt/30) + eX * 0.5 * mySize_x;
				barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, rightcnt/30);
				picpos = pos + eX * 0.05 * mySize_x + eY * mySize_y - eY * 0.65 * mySize_x + eX * 0.5 * mySize_x;
				numpos = pos + eX * ((2-len)/2) * 0.25 * mySize_x + eY * mySize_y - eY * 0.25 * mySize_x + eX * 0.5 * mySize_x;
			}

			HUD_Panel_DrawProgressBar(barpos, 1, barsize, HUD_Panel_GetProgressBarColor(rightname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			if(rightcnt <= 5)
				drawpic_skin_expanding_two(picpos, rightname, '0.4 0.4 0' * mySize_x, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE, bound(0, (rightcnt - rightexact) / 0.5, 1));
			else
				drawpic_skin(picpos, rightname, '0.4 0.4 0' * mySize_x, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			HUD_DrawXNum(numpos, rightcnt, len, 0, 0.25 * mySize_x, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}
	}
}

// Health/armor (#3)
//
void HUD_HealthArmor(void)
{
	float id = HUD_PANEL_HEALTHARMOR;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	float armor, health;
	armor = getstati(STAT_ARMOR);
	health = getstati(STAT_HEALTH);

	float fuel;
	fuel = getstati(GetAmmoStat(4)); // how much fuel do we have?

	if(hud_configure)
	{
		armor = 150;
		health = 100;
		fuel = 70;
	}

	if(health <= 0)
		return;

	float len;
	vector barpos, barsize;
	vector picpos;
	vector numpos;

	if(cvar("hud_healtharmor") == 2) // combined health and armor display
	{
		vector v;
		v = healtharmor_maxdamage(health, armor, armorblockpercent);

		float x;
		x = floor(v_x + 1);

		if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
			barpos = pos + eX * mySize_x - eX * mySize_x * min(1, x/400);
			barsize = eX * mySize_x * min(1, x/400) + eY * mySize_y;
			picpos = pos;
			numpos = picpos + eX * 1.5 * mySize_y;
		} else {
			barpos = pos;
			barsize = eX * mySize_x * min(1, x/400) + eY * mySize_y;
			picpos = pos + eX * 3 * mySize_y;
			numpos = pos;
		}

		if(v_z) // NOT fully armored
		{
			HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor("health"), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			drawpic_skin(picpos, "health", '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			if(armor)
				drawpic_skin(picpos + eX * mySize_y, "armor", '0.5 0.5 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id) * armor / health, DRAWFLAG_NORMAL);
		}
		else
		{
			HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor("armor"), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			drawpic_skin(picpos + eX * mySize_y, "health", '0.5 0.5 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id) * health / armor, DRAWFLAG_NORMAL);
			if(armor)
				drawpic_skin(picpos, "armor", '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		}
		HUD_DrawXNum_Colored(numpos, x, 3, mySize_y, HUD_Panel_GetFgAlpha(id)); // draw the combined health and armor
	}

	else
	{
		string leftname, rightname;
		float leftcnt, rightcnt;
		float leftactive, rightactive;
		float leftalpha, rightalpha;
		if (cvar(strcat("hud_", HUD_Panel_GetName(id), "_flip"))) { // old style layout with armor left/top of health
			leftname = "armor";
			leftcnt = armor;
			if(leftcnt)
				leftactive = 1;
			leftalpha = min((armor+10)/55, 1);

			rightname = "health";
			rightcnt = health;
			rightactive = 1;
			rightalpha = 1;
		} else {
			leftname = "health";
			leftcnt = health;
			leftactive = 1;
			leftalpha = 1;

			rightname = "armor";
			rightcnt = armor;
			if(rightcnt)
				rightactive = 1;
			rightalpha = min((armor+10)/55, 1);
		}

		if (mySize_x/mySize_y > 5)
		{
			if(leftactive)
			{
				len = strlen(ftos(leftcnt));

				if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
					barpos = pos + eX * 0.5 * mySize_x - eX * 0.5 * mySize_x * min(1, leftcnt/200);
					barsize = eX * 0.5 * mySize_x * min(1, leftcnt/200) + eY * mySize_y;
					picpos = pos + eX * 0.5 * mySize_x - eX * mySize_y;
					numpos = picpos - eX * 3 * 0.5 * mySize_y + eX * (3-len) * 0.5 * mySize_y + eY * 0.25 * mySize_y;
				} else {
					barpos = pos;
					barsize = eX * 0.5 * mySize_x * min(1, leftcnt/200) + eY * mySize_y;
					picpos = pos;
					numpos = picpos + eX * mySize_y + eY * 0.25 * mySize_y;
				}

				HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(leftname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawpic_skin(picpos, leftname, '1 1 0' * mySize_y, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum_Colored(numpos, leftcnt, len, 0.5 * mySize_y, HUD_Panel_GetFgAlpha(id));
			}

			if(rightactive)
			{
				len = strlen(ftos(rightcnt));

				if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
					barpos = pos + eX * 0.5 * mySize_x;
					barsize = eX * 0.5 * mySize_x * min(1, rightcnt/200) + eY * mySize_y;
					picpos = pos + eX * 0.5 * mySize_x;
					numpos = picpos + eX * mySize_y - eX * (3-len) * 0.5 * mySize_y + eY * 0.25 * mySize_y;
				} else {
					barpos = pos + eX * mySize_x - eX * 0.5 * mySize_x * min(1, rightcnt/200);
					barsize = eX * 0.5 * mySize_x * min(1, rightcnt/200) + eY * mySize_y;
					picpos = pos + eX * mySize_x - eX * mySize_y;
					numpos = picpos - eX * 1.5 * mySize_y + eY * 0.25 * mySize_y;
				}

				HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(rightname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawpic_skin(picpos, rightname, '1 1 0' * mySize_y, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum_Colored(numpos, rightcnt, 3, 0.5 * mySize_y, HUD_Panel_GetFgAlpha(id));
			}

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos + eX * mySize_x - eX * mySize_x * min(1, fuel/100);
				barsize = eX * mySize_x * min(1, fuel/100) + eY * 0.2 * mySize_y;
			} else {
				barpos = pos;
				barsize = eX * mySize_x * min(1, fuel/100) + eY * 0.2 * mySize_y;
			}
			if(fuel)
				HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor("fuel"), HUD_Panel_GetFgAlpha(id) * 0.8, DRAWFLAG_NORMAL);
		}
		else if (mySize_x/mySize_y > 2)
		{
			if(leftactive)
			{
				len = strlen(ftos(leftcnt));

				if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
					barpos = pos + eX * mySize_x - eX * mySize_x * min(1, leftcnt/200);
					barsize = eX * mySize_x * min(1, leftcnt/200) + eY * 0.5 * mySize_y;
					picpos = pos + eX * mySize_x - eX * 0.5 * mySize_y;
					numpos = picpos - eX * len * 0.5 * mySize_y;
				} else {
					barpos = pos;
					barsize = eX * mySize_x * min(1, leftcnt/200) + eY * 0.5 * mySize_y;
					picpos = pos;
					numpos = picpos + eX * 0.5 * mySize_y;
				}

				HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(leftname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawpic_skin(picpos, leftname, '0.5 0.5 0' * mySize_y, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum_Colored(numpos, leftcnt, len, 0.5 * mySize_y, HUD_Panel_GetFgAlpha(id));
			}

			if(rightactive)
			{
				len = strlen(ftos(rightcnt));

				if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
					barpos = pos + eX * mySize_x - eX * mySize_x * min(1, rightcnt/200) + eY * 0.5 * mySize_y;
					barsize = eX * mySize_x * min(1, rightcnt/200) + eY * 0.5 * mySize_y;
					picpos = pos + eX * mySize_x - eX * 0.5 * mySize_y + eY * 0.5 * mySize_y;
					numpos = picpos - eX * len * 0.5 * mySize_y;
				} else {
					barpos = pos + eY * 0.5 * mySize_y;
					barsize = eX * mySize_x * min(1, rightcnt/200) + eY * 0.5 * mySize_y;
					picpos = pos + eY * 0.5 * mySize_y;
					numpos = picpos + eX * 0.5 * mySize_y;
				}

				HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor(rightname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawpic_skin(picpos, rightname, '0.5 0.5 0' * mySize_y, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum_Colored(numpos, rightcnt, len, 0.5 * mySize_y, HUD_Panel_GetFgAlpha(id));
			}

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos + eX * mySize_x - eX * mySize_x * min(1, fuel/100);
				barsize = eX * mySize_x * min(1, fuel/100) + eY * 0.1 * mySize_y;
			} else {
				barpos = pos;
				barsize = eX * mySize_x * min(1, fuel/100) + eY * 0.1 * mySize_y;
			}
			if(fuel)
				HUD_Panel_DrawProgressBar(barpos, 0, barsize, HUD_Panel_GetProgressBarColor("fuel"), HUD_Panel_GetFgAlpha(id) * 0.8, DRAWFLAG_NORMAL);
		}
		else
		{
			if(leftactive)
			{
				len = strlen(ftos(leftcnt));

				if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
					barpos = pos;
					barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, leftcnt/200);
					picpos = pos + eX * 0.05 * mySize_x;
					numpos = pos + eX * ((3-len)/2) * 0.25 * mySize_x + eY * 0.4 * mySize_x;
				} else {
					barpos = pos + eY * mySize_y - eY * mySize_y * min(1, leftcnt/200);
					barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, leftcnt/200);
					picpos = pos + eX * 0.05 * mySize_x + eY * mySize_y - eY * 0.566 * mySize_x;
					numpos = pos + eX * ((3-len)/2) * 0.25 * mySize_x + eY * mySize_y - eY * 0.166 * mySize_x;
				}

				HUD_Panel_DrawProgressBar(barpos, 1, barsize, HUD_Panel_GetProgressBarColor(leftname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawpic_skin(picpos, leftname, '0.4 0.4 0' * mySize_x, '1 1 1', leftalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum_Colored(numpos, leftcnt, len, 0.166 * mySize_x, HUD_Panel_GetFgAlpha(id));
			}

			if(rightactive)
			{
				len = strlen(ftos(rightcnt));

				if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
					barpos = pos + eX * 0.5 * mySize_x;
					barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, rightcnt/200);
					picpos = pos + eX * 0.05 * mySize_x + eX * 0.5 * mySize_x;
					numpos = pos + eX * ((3-len)/2) * 0.25 * mySize_x + eY * 0.4 * mySize_x + eX * 0.5 * mySize_x;
				} else {
					barpos = pos + eY * mySize_y - eY * mySize_y * min(1, rightcnt/200) + eX * 0.5 * mySize_x;
					barsize = eX * 0.5 * mySize_x + eY * mySize_y * min(1, rightcnt/200);
					picpos = pos + eX * 0.05 * mySize_x + eY * mySize_y - eY * 0.566 * mySize_x + eX * 0.5 * mySize_x;
					numpos = pos + eX * ((3-len)/2) * 0.25 * mySize_x + eY * mySize_y - eY * 0.166 * mySize_x + eX * 0.5 * mySize_x;
				}

				HUD_Panel_DrawProgressBar(barpos, 1, barsize, HUD_Panel_GetProgressBarColor(rightname), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawpic_skin(picpos, rightname, '0.4 0.4 0' * mySize_x, '1 1 1', rightalpha * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum_Colored(numpos, rightcnt, len, 0.166 * mySize_x, HUD_Panel_GetFgAlpha(id));
			}

			if(cvar(strcat("hud_", HUD_Panel_GetName(id), "_mirror"))) {
				barpos = pos;
				barsize = eX * 0.05 * mySize_x + eY * mySize_y * min(1, fuel/100);
			} else {
				barpos = pos + eY * mySize_y - eY * mySize_y * min(1, fuel/100);
				barsize = eX * 0.05 * mySize_x + eY * mySize_y * min(1, fuel/100);
			}
			if(fuel)
				HUD_Panel_DrawProgressBar(barpos, 1, barsize, HUD_Panel_GetProgressBarColor("fuel"), HUD_Panel_GetFgAlpha(id) * 0.8, DRAWFLAG_NORMAL);
		}
	}
}

// ___TODO___ !!!
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

float killnotify_times[10];
float killnotify_deathtype[10];
string killnotify_attackers[10];
string killnotify_victims[10];
void HUD_KillNotify_Push(string attacker, string victim, float wpn)
{
	float i;
	for (i = 9; i > 0; --i) {
		killnotify_times[i] = killnotify_times[i-1];
		killnotify_deathtype[i] = killnotify_deathtype[i-1];
		if(killnotify_attackers[i])
			strunzone(killnotify_attackers[i]);
		killnotify_attackers[i] = strzone(killnotify_attackers[i-1]);
		if(killnotify_victims[i])
			strunzone(killnotify_victims[i]);
		killnotify_victims[i] = strzone(killnotify_victims[i-1]);
	}
	killnotify_times[0] = time;
	killnotify_deathtype[0] = wpn;
	if(killnotify_attackers[0])
		strunzone(killnotify_attackers[0]);
	killnotify_attackers[0] = strzone(attacker);
	if(killnotify_victims[0])
		strunzone(killnotify_victims[0]);
	killnotify_victims[0] = strzone(victim);
}

void HUD_KillNotify(string s1, string s2, string s3, float type, float msg)
{
	float w;
	if(msg == MSG_SUICIDE) {
		HUD_KillNotify_Push(s1, "", DEATH_KILL);

		// TODO: cl_gentle
		w = DEATH_WEAPONOF(type);
		if(WEP_VALID(w)) {
			if (!HUD_Panel_CheckActive(4) || cvar("hud_notify_print"))
				print("^1", s1, "^1 ", Weapon_SuicideMessage(type), "\n");
		}
		else if (type == DEATH_KILL)
			print ("^1",s1, "^1 couldn't take it anymore\n");
		else if (type == DEATH_ROT)
			print ("^1",s1, "^1 died\n");
		else if (type == DEATH_NOAMMO)
			print ("^7",s1, "^7 committed suicide. What's the point of living without ammo?\n");
		else if (type == DEATH_CAMP)
			print ("^1",s1, "^1 thought they found a nice camping ground\n");
		else if (type == DEATH_MIRRORDAMAGE)
			print ("^1",s1, "^1 didn't become friends with the Lord of Teamplay\n");
		else if (type == DEATH_CHEAT)
			print ("^1",s1, "^1 unfairly eliminated themself\n");
		else if (type == DEATH_FIRE)
			print ("^1",s1, "^1 burned to death\n");
		else if (type != DEATH_TEAMCHANGE && type != DEATH_QUIET)
			print ("^1",s1, "^1 couldn't resist the urge to self-destruct\n");
		if (stof(s2) > 2) // killcount > 2
			print ("^1",s1,"^1 ended it all after a ",s2," kill spree\n");
	} else if(msg == MSG_KILL) {
		w = DEATH_WEAPONOF(type);
		if(WEP_VALID(w)) {
			HUD_KillNotify_Push(s2, s1, w);
			if (!HUD_Panel_CheckActive(4) || cvar("hud_notify_print"))
				print("^1", s1, "^1 ", Weapon_KillMessage(type), "\n");
		}
		else if(type == KILL_TEAM || type == KILL_TEAM_SPREE) {
				if(cvar("cl_gentle")) {
					print ("^1", s1, "^1 took action against a team mate\n");
				} else {
					print ("^1", s1, "^1 mows down a team mate\n");
				}
				if (stof(s2) > 2 && type == KILL_TEAM_SPREE) {
					if(cvar("cl_gentle"))
						print ("^1",s1,"^1 ended a ",s2," scoring spree by going against a team mate\n");
					else
						print ("^1",s1,"^1 ended a ",s2," kill spree by killing a team mate\n");
				}
				else if (stof(s2) > 2) {
					if(cvar("cl_gentle"))
						print ("^1",s1,"'s ^1",s2," scoring spree was ended by a team mate!\n");
					else
						print ("^1",s1,"'s ^1",s2," kill spree was ended by a team mate!\n");
				}
		}
		else if(type == KILL_FIRST_BLOOD)
			print("^1",s1, "^1 drew first blood", "\n");
		else if (type == DEATH_TELEFRAG)
			print ("^1",s1, "^1 was telefragged by ", s2, "\n");
		else if (type == DEATH_DROWN) {
			HUD_KillNotify_Push(s2, s1, DEATH_FALL);
			print ("^1",s1, "^1 was drowned by ", s2, "\n");
		}
		else if (type == DEATH_SLIME) {
			HUD_KillNotify_Push(s2, s1, DEATH_FALL);
			print ("^1",s1, "^1 was slimed by ", s2, "\n");
		}
		else if (type == DEATH_LAVA) {
			HUD_KillNotify_Push(s2, s1, DEATH_FALL);
			print ("^1",s1, "^1 was cooked by ", s2, "\n");
		}
		else if (type == DEATH_FALL) {
			HUD_KillNotify_Push(s2, s1, DEATH_FALL);
			print ("^1",s1, "^1 was grounded by ", s2, "\n");
		}
		else if (type == DEATH_SHOOTING_STAR) {
			HUD_KillNotify_Push(s2, s1, DEATH_FALL);
			print ("^1",s1, "^1 was shot into space by ", s2, "\n");
		}
		else if (type == DEATH_SWAMP) {
			HUD_KillNotify_Push(s2, s1, DEATH_FALL);
			print ("^1",s1, "^1 was conserved by ", s2, "\n");
		}
		else if (type == DEATH_HURTTRIGGER && s3 != "")
		{
			HUD_KillNotify_Push(s2, s1, DEATH_FALL);
			// p ?!?! :o
			//if(p < 0)
				print("^1", s1, "^1 ", s3, " ", s2, "\n");
			//else
			//	bprint("^1", s1, "^1 ", substring(s3, 0, p), s2, "^1", substring(s3, p+1, strlen(s3) - (p+1)), "\n");
		}
		else if(type == DEATH_SBCRUSH)
			print ("^1",s1, "^1 was crushed by ^1", s2, "\n");
		else if(type == DEATH_SBMINIGUN)
			print ("^1",s1, "^1 got shredded by ^1", s2, "\n");
		else if(type == DEATH_SBROCKET)
			print ("^1",s1, "^1 was blased to bits by ^1", s2, "\n");
		else if(type == DEATH_SBBLOWUP)
			print ("^1",s1, "^1 got cought in the destruction of ^1", s2, "'s vehicle\n");

		else if(type == DEATH_WAKIGUN)
			print ("^1",s1, "^1 was bolted down by ^1", s2, "\n");
		else if(type == DEATH_WAKIROCKET)
			print ("^1",s1, "^1 could find no shelter from ^1", s2, "'s rockets\n");
		else if(type == DEATH_WAKIBLOWUP)
			print ("^1",s1, "^1 dies when ^1", s2, "'s wakizashi dies.\n");

		else if(type == DEATH_TURRET)
			print ("^1",s1, "^1 was pushed into the line of fire by ^1", s2, "\n");
		else if(type == DEATH_TOUCHEXPLODE)
			print ("^1",s1, "^1 was pushed into an accident by ^1", s2, "\n");
		else if(type == DEATH_CHEAT)
			print ("^1",s1, "^1 was unfairly eliminated by ^1", s2, "\n");
		else if (type == DEATH_FIRE)
			print ("^1",s1, "^1 was burnt to death by ^1", s2, "\n");
		else if (type == DEATH_CUSTOM)
			print ("^1",s1, "^1 ", s2, "\n");
		else
			print ("^1",s1, "^1 was fragged by ", s2, "\n");
	} else if(msg == MSG_SPREE) {
		if(type == KILL_END_SPREE) {
			if(cvar("cl_gentle"))
				print ("^1",s1,"'s ^1", s2, " scoring spree was ended by ", s3, "\n");
			else
				print ("^1",s1,"'s ^1", s2, " kill spree was ended by ", s3, "\n");
		} else if(type == KILL_SPREE) {
			if(cvar("cl_gentle"))
				print ("^1",s1,"^1 made ",s2," scores in a row\n");
			else
				print ("^1",s1,"^1 has ",s2," frags in a row\n");
		} else if(type == KILL_SPREE_3) {
			if(cvar("cl_gentle"))
				print (s1,"^7 made a ^1TRIPLE SCORE\n");
			else
				print (s1,"^7 made a ^1TRIPLE FRAG\n");
		} else if(type == KILL_SPREE_5) {
			if(cvar("cl_gentle"))
				print (s1,"^7 unleashes ^1SCORING RAGE\n");
			else
				print (s1,"^7 unleashes ^1RAGE\n");
		} else if(type == KILL_SPREE_10) {
			if(cvar("cl_gentle"))
				print (s1,"^7 made ^1TEN SCORES IN A ROW!\n");
			else
				print (s1,"^7 starts the ^1MASSACRE!\n");
		} else if(type == KILL_SPREE_15) {
			if(cvar("cl_gentle"))
				print (s1,"^7 made ^1FIFTEEN SCORES IN A ROW!\n");
			else
				print (s1,"^7 executes ^1MAYHEM!\n");
		} else if(type == KILL_SPREE_20) {
			if(cvar("cl_gentle"))
				print (s1,"^7 made ^1TWENTY SCORES IN A ROW!\n");
			else
				print (s1,"^7 is a ^1BERSERKER!\n");
		} else if(type == KILL_SPREE_25) {
			if(cvar("cl_gentle"))
				print (s1,"^7 made ^1TWENTY FIFE SCORES IN A ROW!\n");
			else
				print (s1,"^7 inflicts ^1CARNAGE!\n");
		} else if(type == KILL_SPREE_30) {
			if(cvar("cl_gentle"))
				print (s1,"^7 made ^1THIRTY SCORES IN A ROW!\n");
			else
				print (s1,"^7 unleashes ^1ARMAGEDDON!\n");
		}
	} else if(msg == MSG_KILL_ACTION) { // wtf is this? isnt it basically the same as MSG_SUICIDE?
		HUD_KillNotify_Push(s1, "", DEATH_KILL);
		if (type == DEATH_DROWN) {
			if(cvar("cl_gentle"))
				print ("^1",s1, "^1 was in the water for too long\n");
			else
				print ("^1",s1, "^1 drowned\n");
		}
		else if (type == DEATH_SLIME)
			print ("^1",s1, "^1 was slimed\n");
		else if (type == DEATH_LAVA) {
			if(cvar("cl_gentle"))
				print ("^1",s1, "^1 found a hot place\n");
			else
				print ("^1",s1, "^1 turned into hot slag\n");
		}
		else if (type == DEATH_FALL) {
			if(cvar("cl_gentle"))
				print ("^1",s1, "^1 tested gravity (and it worked)\n");
			else
				print ("^1",s1, "^1 hit the ground with a crunch\n");
		}
		else if (type == DEATH_SHOOTING_STAR)
			print ("^1",s1, "^1 became a shooting star\n");
		else if (type == DEATH_SWAMP) {
			if(cvar("cl_gentle"))
				print ("^1",s1, "^1 discovered a swamp\n");
			else
				print ("^1",s1, "^1 is now conserved for centuries to come\n");
		}
		else if(type == DEATH_TURRET)
			print ("^1",s1, "^1 was mowed down by a turret \n");
		else if (type == DEATH_CUSTOM)
			print ("^1",s1, "^1 ", s2, "\n");
		else if(type == DEATH_TOUCHEXPLODE)
			print ("^1",s1, "^1 died in an accident\n");
		else if(type == DEATH_CHEAT)
			print ("^1",s1, "^1 was unfairly eliminated\n");
		else if(type == DEATH_FIRE) {
			if(cvar("cl_gentle"))
				print ("^1",s1, "^1 felt a little hot\n");
			else
				print ("^1",s1, "^1 burnt to death\n");
		}
		else {
			if(cvar("cl_gentle"))
				print ("^1",s1, "^1 needs a restart\n");
			else
				print ("^1",s1, "^1 died\n");
		}
	} else if(msg == MSG_KILL_ACTION_SPREE) {
		HUD_KillNotify_Push(s1, "", DEATH_KILL);
		if(cvar("cl_gentle"))
			print ("^1",s1,"^1 needs a restart after a ",s2," scoring spree\n");
		else
			print ("^1",s1,"^1 died with a ",s2," kill spree\n");
	} else if(msg == MSG_INFO) {
		if(type == INFO_GOTFLAG) {
			HUD_KillNotify_Push(s1, s2, INFO_GOTFLAG);
			print(s1, "^7 got the ", s2, "\n");
		} else if(type == INFO_LOSTFLAG) {
			HUD_KillNotify_Push(s1, s2, INFO_LOSTFLAG);
			print(s1, "^7 lost the ", s2, "\n");
		} else if(type == INFO_PICKUPFLAG) {
			HUD_KillNotify_Push(s1, s2, INFO_GOTFLAG);
			print(s1, "^7 picked up the ", s2, "\n");
		} else if(type == INFO_RETURNFLAG) {
			HUD_KillNotify_Push(s1, s2, INFO_RETURNFLAG);
			print(s1, "^7 returned the ", s2, "\n");
		}
	}

}

#define DAMAGE_CENTERPRINT_SPACER NEWLINES

void HUD_Centerprint(string s1, float type, float msg)
{
	if(msg == MSG_SUICIDE) {
		if (type == DEATH_TEAMCHANGE) {
			centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "You are now on: ", s1));
		} else if (type == DEATH_AUTOTEAMCHANGE) {
			centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "You have been moved into a different team to improve team balance\nYou are now on: ", s1));
		} else if (type == DEATH_CAMP) {
			if(cvar("cl_gentle"))
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Reconsider your tactics, camper!"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Die camper!"));
		} else if (type == DEATH_NOAMMO) {
			if(cvar("cl_gentle"))
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You are reinserted into the game for running out of ammo..."));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were killed for running out of ammo..."));
		} else if (type == DEATH_ROT) {
			if(cvar("cl_gentle"))
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You need to preserve your health"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You grew too old without taking your medicine"));
		} else if (type == DEATH_MIRRORDAMAGE) {
			if(cvar("cl_gentle"))
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't go against team mates!"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't shoot your team mates!"));
		} else if (type == DEATH_QUIET) {
			// do nothing
		} else if (type == DEATH_KILL) {
			if(cvar("cl_gentle"))
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You need to be more careful!"));
			else
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You killed your own dumb self!"));
		}
	} else if(msg == MSG_KILL) {
		if (type == KILL_TEAM) {
			if(cvar("cl_gentle")) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You went against a team mate!"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You fragged ", s1, ", a team mate!"));
			}
		} else if (type == KILL_FIRST_BLOOD) {
			if(cvar("cl_gentle")) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First score"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First blood"));
			}
		} else if (type == KILL_FIRST_VICTIM) {
			if(cvar("cl_gentle")) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First casualty"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1First victim"));
			}
		} else if (type == KILL_TYPEFRAG) {
			if(cvar("cl_gentle")) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You scored against ^7", s1, "^7 who was typing!"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You typefragged ^7", s1));
			}
		} else if (type == KILL_TYPEFRAGGED) {
			if(cvar("cl_gentle")) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were scored against by ^7", s1, "^7 while you were typing!"));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were typefragged by ^7", s1));
			}
		} else if (type == KILL_FRAG) {
			if(cvar("cl_gentle")) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^4You scored against ^7", s1));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^4You fragged ^7", s1));
			}
		} else if (type == KILL_FRAGGED) {
			if(cvar("cl_gentle")) {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^4You were scored against by ^7", s1));
			} else {
				centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^4You were fragged by ^7", s1));
			}
		}
	} else if(msg == MSG_KILL_ACTION) {
		// TODO: invent more centerprints here?
		centerprint(strcat(DAMAGE_CENTERPRINT_SPACER, "^1Watch your step!", s1));
	}
}

void HUD_Notify (void)
{
	float id = HUD_PANEL_NOTIFY;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	float entries, height;
	entries = bound(1, floor(12 * mySize_y/mySize_x), 10);
	height = mySize_y/entries;
	
	vector fontsize;
	fontsize = '0.5 0.5 0' * height;

	float a;
	float when;
	when = cvar("hud_notify_time");
	float fadetime;
	fadetime = cvar("hud_notify_fadetime");

	string s;

	vector pos_attacker, pos_victim;
	vector weap_pos;
	float width_attacker, width_victim;
	string attacker, victim;

	float i, j;
	for(j = 0; j < entries; ++j)
	{
		if(cvar("hud_notify_flip"))
			i = j;
		else // rather nasty hack for ordering items from the bottom up
			i = entries - j - 1;

		if(fadetime)
		{
			if(killnotify_times[j] + when > time)
				a = 1;
			else
				a = bound(0, (killnotify_times[j] + when + fadetime - time) / fadetime, 1);
		}
		else
		{
			if(killnotify_times[j] + when > time)
				a = 1;
			else
				a = 0;
		}

		// TODO: maybe print in team colors?
		// TODO: maybe this could be cleaned up somehow...
		//
		// X [did action to] Y
		if(hud_configure || WEP_VALID(killnotify_deathtype[j]) || killnotify_deathtype[j] == DEATH_FALL)
		{
			if(hud_configure)
			{
				attacker = textShortenToWidth("Player1", 0.5 * mySize_x - height, fontsize, stringwidth_colors);
				victim = textShortenToWidth("Player2", 0.5 * mySize_x - height, fontsize, stringwidth_colors);
			}
			else
			{
				attacker = textShortenToWidth(killnotify_attackers[j], 0.5 * mySize_x - height, fontsize, stringwidth_colors);
				victim = textShortenToWidth(killnotify_victims[j], 0.5 * mySize_x - height, fontsize, stringwidth_colors);
			}
			width_attacker = stringwidth(attacker, TRUE, fontsize);
			width_victim = stringwidth(victim, TRUE, fontsize);
			pos_attacker = pos + eX * 0.5 * ((0.5 * mySize_x - height) - width_attacker) + eY * 0.5 * fontsize_y + eY * i * height;
			pos_victim = pos + eX * 0.5 * ((0.5 * mySize_x - height) - width_victim) + eY * 0.5 * fontsize_y + eX * 0.5 * mySize_x + eX * height + eY * i * height;
			weap_pos = pos + eX * 0.5 * mySize_x - eX * height + eY * i * height;

			if(hud_configure) // example actions for config mode
			{
				drawpic_skin(weap_pos, strcat("weapon", "electro"), '2 1 0' * height, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_victim, victim, fontsize, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			}
			else if(WEP_VALID(killnotify_deathtype[j]))
			{
				self = get_weaponinfo(killnotify_deathtype[j]);
				drawpic_skin(weap_pos, strcat("weapon", self.netname), '2 1 0' * height, '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_victim, victim, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			}
			else if(killnotify_deathtype[j] == DEATH_FALL)
			{
				drawpic_skin(weap_pos, "notify_pushoffedge", '2 1 0' * height, '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_victim, victim, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			}
		}

		// Y [used by] X
		else
		{
			attacker = textShortenToWidth(killnotify_attackers[j], mySize_x - 2 * height, fontsize, stringwidth_colors);

			width_attacker = stringwidth(attacker, TRUE, fontsize);
			pos_attacker = pos + eX * 0.5 * (mySize_x - width_attacker + 2 * height) + eY * 0.5 * fontsize_y + eY * i * height;

			weap_pos = pos + eX * 0.5 * (mySize_x - width_attacker) - eX * height + eY * i * height;
			if(killnotify_deathtype[j] == DEATH_KILL)
			{
				drawpic_skin(weap_pos, "notify_selfkill", '2 1 0' * height, '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			}
			else if(killnotify_deathtype[j] == INFO_GOTFLAG)
			{
				if(killnotify_victims[j] == "^1RED^7 flag")
					s = "red";
				else
					s = "blue";
				drawpic_skin(weap_pos, strcat("flag_", s, "_carrying"), '1 1 0' * height, '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			}
			else if(killnotify_deathtype[j] == INFO_RETURNFLAG)
			{
				if(killnotify_victims[j] == "^1RED^7 flag")
					s = "red";
				else
					s = "blue";
				drawpic_skin(weap_pos, strcat("flag_", s, "_taken"), '1 1 0' * height, '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			}
			else if(killnotify_deathtype[j] == INFO_LOSTFLAG)
			{
				if(killnotify_victims[j] == "^1RED^7 flag")
					s = "red";
				else
					s = "blue";
				drawpic_skin(weap_pos, strcat("flag_", s, "_lost"), '1 1 0' * height, '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos_attacker, attacker, fontsize, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			}
		}
	}
	/* This will come later.
	string s;
	entity tm;
	if(spectatee_status && !intermission)
	{
		drawfont = hud_bigfont;
		if(spectatee_status == -1)
			s = "^1Observing";
		else
			s = GetPlayerName(spectatee_status - 1);
		// spectated player name between HUD and chat area, aligned to the left
		pos_x = 0;
		pos_y = - 50 - hud_fontsize_spec_y;
		s = textShortenToWidth(s, vid_conwidth/2.5, hud_fontsize_spec, stringwidth_colors);
		drawcolorcodedstring(pos, s, hud_fontsize_spec, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		drawfont = hud_font;

		// spectator text in the upper right corner
		if(spectatee_status == -1)
			s = strcat("^1Press ^3", getcommandkey("primary fire", "+attack"), "^1 to spectate");
		else
			s = strcat("^1Press ^3", getcommandkey("primary fire", "+attack"), "^1 for another player");

		if(spectatee_status == -1)
			s = strcat("^1Use ^3", getcommandkey("next weapon", "weapnext"), "^1 or ^3", getcommandkey("previous weapon", "weapprev"), "^1 to change the speed");
		else
			s = strcat("^1Press ^3", getcommandkey("secondary fire", "+attack2"), "^1 to observe");

		s = strcat("^1Press ^3", getcommandkey("server info", "+show_info"), "^1 for gamemode info");

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

		//show restart countdown:
		if (time < getstatf(STAT_GAMESTARTTIME)) {
			float countdown;
			//we need to ceil, otherwise the countdown would be off by .5 when using round()
			countdown = ceil(getstatf(STAT_GAMESTARTTIME) - time);
			s = strcat("^1Game starts in ^3", ftos(countdown), "^1 seconds");
		}
	}
	if(warmup_stage && !intermission)
	{
		s = "^2Currently in ^1warmup^2 stage!";
	}

	// move more important stuff more to the middle so its more visible

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
	}
	else if(warmup_stage && !intermission && !spectatee_status)
	{
		s = strcat("^2Press ^3", getcommandkey("ready", "ready"), "^2 to end warmup");
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

			}
		}
	}
	*/
}

// Timer (#5)
//
void HUD_Timer(void)
{
	float id = HUD_PANEL_TIMER;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	float timelimit, elapsedTime, minutes, seconds, timeleft, minutesLeft, secondsLeft;

	timelimit = getstatf(STAT_TIMELIMIT);

	timeleft = max(0, timelimit * 60 + getstatf(STAT_GAMESTARTTIME) - time);
	timeleft = ceil(timeleft);
	minutesLeft = floor(timeleft / 60);
	secondsLeft = timeleft - minutesLeft*60;

	vector timer_color;
	if(minutesLeft >= 5 || warmup_stage || timelimit == 0) //don't use red or yellow in warmup or when there is no timelimit
		timer_color = '1 1 1'; //white
	else if(minutesLeft >= 1)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red

	if (cvar("hud_timer_increment") || timelimit == 0 || warmup_stage) {
		if (time < getstatf(STAT_GAMESTARTTIME)) {
			//while restart is still active, show 00:00
			minutes = seconds = 0;
		} else {
			elapsedTime = floor(time - getstatf(STAT_GAMESTARTTIME)); //127
			minutes = floor(elapsedTime / 60);
			seconds = elapsedTime - minutes*60;
		}
	} else {
		minutes = minutesLeft;
		seconds = secondsLeft;
	}

	if(minutes > 999)
		seconds = 99;
	minutes = min(minutes, 999);
	if(minutesLeft >= 1 || cvar("hud_timer_increment") || timelimit == 0 || warmup_stage) {
		HUD_DrawXNum(pos + eX * mySize_x - eX * 5.1 * mySize_y, minutes, 3, 0, mySize_y, timer_color, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		drawpic_skin(pos + eX * mySize_x - eX * 2.57 * mySize_y, "num_colon", '1 1 0' * mySize_y, timer_color, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	}
	HUD_DrawXNum(pos + eX * mySize_x - eX * 2 * mySize_y, seconds, -2, 0, mySize_y, timer_color, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
}

// Radar (#6)
//
void HUD_Radar(void)
{
	float id = HUD_PANEL_RADAR;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
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

	switch(hud_radar_zoommode)
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

	switch(hud_radar_rotation)
	{
		case 0:
			teamradar_angle = view_angles_y - 90;
			break;
		default:
			teamradar_angle = 90 * hud_radar_rotation;
			break;
	}

	scale2d = vlen_maxnorm2d(mi_picmax - mi_picmin);
	teamradar_size2d = mySize;

	teamradar_extraclip_mins = teamradar_extraclip_maxs = '0 0 0'; // we always center

	// pixels per world qu to match the teamradar_size2d_x range in the longest dimension
	if(hud_radar_rotation == 0)
	{
		// max-min distance must fit the radar in any rotation
		bigsize = vlen_minnorm2d(teamradar_size2d) * scale2d / (1.05 * vlen2d(mi_max - mi_min));
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

	normalsize = vlen_maxnorm2d(teamradar_size2d) * scale2d / hud_radar_scale;
	if(bigsize > normalsize)
		normalsize = bigsize;

	teamradar_size =
		  f * bigsize
		+ (1 - f) * normalsize;
	teamradar_origin3d_in_texcoord = teamradar_3dcoord_to_texcoord(
		  f * (mi_min + mi_max) * 0.5
		+ (1 - f) * view_origin);

	color1 = GetPlayerColor(player_localentnum-1);
	rgb = GetTeamRGB(color1);

	drawsetcliparea(
		pos_x,
		pos_y,
		mySize_x,
		mySize_y
	);

	draw_teamradar_background(hud_radar_background_alpha, hud_radar_foreground_alpha);

	for(tm = world; (tm = find(tm, classname, "radarlink")); )
		draw_teamradar_link(tm.origin, tm.velocity, tm.team);
	for(tm = world; (tm = findflags(tm, teamradar_icon, 0xFFFFFF)); )
		draw_teamradar_icon(tm.origin, tm.teamradar_icon, tm, tm.teamradar_color, HUD_Panel_GetFgAlpha(id));
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
	float id = HUD_PANEL_SCORE;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	float score, distribution, leader;
	float score_len, distr_len;
	vector distribution_color;
	entity tm, pl, me;
	me = (spectatee_status > 0) ? playerslots[spectatee_status - 1] : playerslots[player_localentnum - 1];

	// TODO... this (race part) still uses constant coordinates :/
	if((scores_flags[ps_primary] & SFL_TIME) && !teamplay) { // race/cts record display on HUD
		/*pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;
		if(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)
			if(pl.scores[ps_primary] == 0)
				pl = world;

		score = me.(scores[ps_primary]);

		float racemin, racesec, racemsec;
		float distsec, distmsec, minusplus;

		racemin = floor(score/(60 * TIME_FACTOR));
		racesec = floor((score - racemin*(60 * TIME_FACTOR))/TIME_FACTOR);
		racemsec = score - racemin*60*TIME_FACTOR - racesec*TIME_FACTOR;

		if (pl && ((!(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)) || score)) {
			// distribution display
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);

			if (distribution < TIME_FACTOR && distribution > -TIME_FACTOR)
				distmsec = fabs(distribution);
			else {
				distsec = floor(fabs(distribution)/TIME_FACTOR);
				distmsec = fabs(distribution) - distsec*TIME_FACTOR;
				if (distribution < 0)
					distsec = -distsec;
			}

			if (distribution <= 0) {
				distribution_color = eY;
				minusplus = 1; // minusplus 1: always prefix with minus sign
			}
			else {
				distribution_color = eX;
				minusplus = 2; // minusplus 1: always prefix with plus sign
			}
			HUD_DrawXNum(bottomright - '0 48 0' - '16 0 0' * TIME_DECIMALS, distmsec, -TIME_DECIMALS, 0, 16, distribution_color, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			HUD_DrawXNum(bottomright - '68 48 0' - '16 0 0' * TIME_DECIMALS, distsec, 4, minusplus, 16, distribution_color, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			drawpic_skin(bottomright - '10 48 0' - '16 0 0' * TIME_DECIMALS, "num_dot", '16 16 0', distribution_color, HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE);
		}
		// race record display
		if (distribution <= 0 || distribution == score) // draw the highlight background behind the timer if we have the lead
			drawpic_skin(bottomright - '0 32 0' - '32 0 0' * (4 + TIME_DECIMALS), "num_leading_4", '0 28 0' + '32 0 0' * (4 + TIME_DECIMALS), '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

		HUD_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0', racemsec, -TIME_DECIMALS, 0, 30, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		HUD_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0'  - '66 0 0', racesec, -2, 0, 30, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		drawpic_skin(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '18 0 0', "num_dot", '30 30 0', '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE);

		HUD_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '132 0 0', racemin, -2, 0, 30, '1 1 1', 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		drawpic_skin(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '84 0 0', "num_colon", '30 30 0', '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_ADDITIVE);
		*/
	} else if (!teamplay) { // non-teamgames
		// me vector := [team/connected frags id]
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;

		if(hud_configure)
			distribution = 42;
		else if(pl)
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);
		else
			distribution = 0;

		score = me.(scores[ps_primary]);
		if(hud_configure)
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

		score_len = strlen(ftos(score));
		distr_len = strlen(ftos(distribution));

		HUD_DrawXNum(pos + eX * mySize_x - eX * 3 * 0.33 * mySize_y, distribution, 3, 3, 0.33 * mySize_y, distribution_color, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		if (leader)
			drawpic_skin(pos + eX * mySize_x - eX * score_len * mySize_y - eX * 3 * 0.33 * mySize_y, strcat("num_leading_", ftos(score_len)), eX * score_len * mySize_y + eY * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		HUD_DrawXNum(pos + eX * mySize_x - eX * 3 * mySize_y - eX * 3 * 0.33 * mySize_y, score, 3, 0, mySize_y, distribution_color, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	} else { // teamgames
		float max_fragcount;
		max_fragcount = -99;

		float teamnum;
		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == COLOR_SPECTATOR || (!tm.team_size && !hud_configure)) // no players? don't display
				continue;
			score = tm.(teamscores[ts_primary]);
			if(hud_configure)
				score = 123;
			leader = 0;
			
			score_len = strlen(ftos(score));

			if (score > max_fragcount)
				max_fragcount = score;

			if(tm.team == myteam) {
				if (max_fragcount == score)
					leader = 1;
				if (leader)
					drawpic_skin(pos + eX * mySize_x - eX * score_len * mySize_y - eX * 3 * 0.33 * mySize_y, strcat("num_leading_", ftos(score_len)), eX * score_len * mySize_y + eY * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum(pos + eX * mySize_x - eX * 3 * mySize_y - eX * 3 * 0.33 * mySize_y, score, 3, 0, mySize_y, GetTeamRGB(tm.team) * 0.8, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
			} else {
				if (max_fragcount == score)
					leader = 1;
				if (leader)
					drawpic_skin(pos + eX * mySize_x - eX * 0.33 * score_len * mySize_y + eY * 0.33 * mySize_y * teamnum, strcat("num_leading_", ftos(score_len)), eX * 0.33 * score_len * mySize_y + eY * 0.33 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				HUD_DrawXNum(pos + eX * mySize_x - eX * 3 * 0.33 * mySize_y + eY * 0.33 * mySize_y * teamnum, score, 3, 0, 0.33 * mySize_y, GetTeamRGB(tm.team) * 0.8, 0, 0, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
				teamnum += 1;
			}
		}
	}
}

// Race timer (#8)
//
void HUD_RaceTimer (void) {
	float id = HUD_PANEL_RACETIMER;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	drawfont = hud_bigfont;
	float a, t;
	string s, forcetime;

	if(hud_configure)
	{
		s = "0:13:37";
		drawstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, FALSE, '0.75 0.75 0' * mySize_y), s, '0.75 0.75 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
		s = "^1Intermediate 1 (+15.42)";
		drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.25 * mySize_y) + eY * 0.75 * mySize_y, s, '1 1 0' * 0.25 * mySize_y, HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
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
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			//drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.25 * mySize_y) + eY * 0.75 * mySize_y, s, '1 1 0' * 0.25 * mySize_y, HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
		}

		// ___ TODO!!!___
		if(race_penaltytime)
		{
			a = bound(0, 2 - (time - race_penaltyeventtime), 1);
			if(a > 0)
			{
				s = strcat("^1PENALTY: ", ftos_decimals(race_penaltytime * 0.1, 1), " (", race_penaltyreason, ")");
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				//drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos - '0 32 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			}
		}

		if(forcetime != "")
		{
			a = bound(0, (time - race_checkpointtime) / 0.5, 1);
			//drawstring_expanding(m - '16 0 0' * stringwidth(forcetime, FALSE), forcetime, '32 32 0', '1 1 1', HUD_Panel_GetFgAlpha(id), 0, a);
			drawstring_expanding(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(forcetime, FALSE, '1 1 0' * 0.75 * mySize_y), forcetime, '1 1 0' * 0.75 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), 0, a);
		}
		else
			a = 1;

		if(race_laptime && race_checkpoint != 255)
		{
			s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime));
			//drawstring(m - '16 0 0' * stringwidth(s, FALSE), s, '32 32 0', '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			drawstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, FALSE, '0.75 0.75 0' * mySize_y), s, '0.75 0.75 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
		}
	}
	else
	{
		if(race_mycheckpointtime)
		{
			a = bound(0, 2 - (time - race_mycheckpointtime), 1);
			s = MakeRaceString(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -!race_mycheckpointenemy, race_mycheckpointlapsdelta, race_mycheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			//drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			drawcolorcodedstring(pos - '0 16 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
		}
		if(race_othercheckpointtime && race_othercheckpointenemy != "")
		{
			a = bound(0, 2 - (time - race_othercheckpointtime), 1);
			s = MakeRaceString(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -!race_othercheckpointenemy, race_othercheckpointlapsdelta, race_othercheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			//drawcolorcodedstring(m - '0 0 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
			drawcolorcodedstring(pos - '0 0 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
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
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				//drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos - '0 32 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', HUD_Panel_GetFgAlpha(id) * a, DRAWFLAG_NORMAL);
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
	float id = HUD_PANEL_VOTE;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	string s;
	float a;
	if(vote_active != vote_prev) {
		vote_change = time;
		vote_prev = vote_active;
	}

	if(vote_active || hud_configure)
		vote_alpha = bound(0, (time - vote_change) * 2, 1);
	else
		vote_alpha = bound(0, 1 - (time - vote_change) * 2, 1);

	if(hud_configure)
	{
		vote_yescount = 3;
		vote_nocount = 2;
		vote_needed = 4;
	}

	if(!vote_alpha)
		return;

	a = vote_alpha * bound(cvar_or("hud_vote_alreadyvoted_alpha", 0.75), 1 - vote_highlighted, 1);

	HUD_Panel_DrawBg(id, pos, mySize, a);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	drawpic_skin(pos, "voteprogress_back", mySize, '1 1 1', a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

	s = "A vote has been called for: ";
	drawstring(pos + '0.5 0 0' * mySize_x + '0 0.1 0' * mySize_y - eX * stringwidth(s, FALSE, '1 1 0' * 0.5 * mySize_y*(1/5)), s, '1 1 0' * mySize_y*(1/5), '1 1 1', a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	s = textShortenToWidth(vote_called_vote, mySize_x * 0.96, '1 1 0' * mySize_y*(1/5), stringwidth_colors); // TODO: broken?
	if(hud_configure)
		s = "Configure the HUD";
	drawcolorcodedstring(pos + '0.52 0 0' * mySize_x + '0 0.3 0' * mySize_y - eX * stringwidth(s, FALSE, '1 1 0' * 0.5 * mySize_y*(1/6)), s, '1 1 0' * mySize_y*(1/6), a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

	// print the yes/no counts
	s = strcat("Yes: ", ftos(vote_yescount));
	drawstring(pos + '0 0.6 0' * mySize_y + '0.02 0 0' * mySize_x, s, '1 1 0' * mySize_y*(1/6) , eY, a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	s = strcat("No: ", ftos(vote_nocount));
	drawstring(pos + '0 0.6 0' * mySize_y + '0.98 0 0' * mySize_x - eX * stringwidth(s, FALSE, '1 1 0' * mySize_y*(1/6)), s, '1 1 0' * mySize_y*(1/6), eX, a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

	// draw the progress bars
	drawsetcliparea(pos_x, pos_y, mySize_x * 0.5 * (vote_yescount/vote_needed), mySize_y);
	drawpic_skin(pos, "voteprogress_prog", mySize, eY, a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

	drawsetcliparea(pos_x + mySize_x - mySize_x * 0.5 * (vote_nocount/vote_needed), pos_y, mySize_x * 0.5, mySize_y);
	drawpic_skin(pos, "voteprogress_prog", mySize, eX, a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);

	// draw the highlights
	if(vote_highlighted == 1) {
		drawsetcliparea(pos_x, pos_y, mySize_x * 0.5, mySize_y);
		drawpic_skin(pos, "voteprogress_voted", mySize, eY, a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	}
	else if(vote_highlighted == 2) {
		drawsetcliparea(pos_x + 0.5 * mySize_x, pos_y, mySize_x * 0.5, mySize_y);
		drawpic_skin(pos, "voteprogress_voted", mySize, eX, a * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	}

	drawresetcliparea();

	if(!vote_active) {
		vote_highlighted = 0;
	}
}

// Mod icons panel (#10)
//

float mod_active; // is there any active mod icon?

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

	if(hud_configure)
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

	if (myteam == COLOR_TEAM1) { // always draw own flag on left
		redflag_pos = pos;
		blueflag_pos = pos + eX * mySize_y;
	} else {
		blueflag_pos = pos;
		redflag_pos = pos + eX * mySize_y;
	}

	f = bound(0, redflag_statuschange_elapsedtime*2, 1);
	if(red_icon_prevstatus && f < 1)
		drawpic_skin_expanding(redflag_pos, red_icon_prevstatus, '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * red_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(red_icon)
		drawpic_skin(redflag_pos, red_icon, '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * red_alpha * f, DRAWFLAG_NORMAL);

	f = bound(0, blueflag_statuschange_elapsedtime*2, 1);
	if(blue_icon_prevstatus && f < 1)
		drawpic_skin_expanding(blueflag_pos, blue_icon_prevstatus, '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * blue_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(blue_icon)
		drawpic_skin(blueflag_pos, blue_icon, '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * blue_alpha * f, DRAWFLAG_NORMAL);
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

	p_x = pos_x;
	p_y = pos_y + 0.25 * mySize_y;

	kh_keys = getstati(STAT_KH_KEYS);

	kh_size_x = mySize_x * 0.25;
	kh_size_y = 0.75 * mySize_y;

	pa = p - eY * 0.25 * mySize_y;

	kh_asize_x = mySize_x * 0.25;
	kh_asize_y = mySize_y * 0.25;

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
		a = a * HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS);
		aa = aa * HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS);
		if(a > 0)
		{
			switch(keyteam)
			{
				case COLOR_TEAM1:
					drawpic_skin(pa, "kh_redarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM2:
					drawpic_skin(pa, "kh_bluearrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM3:
					drawpic_skin(pa, "kh_yellowarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM4:
					drawpic_skin(pa, "kh_pinkarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				default:
					break;
			}
			switch(i) // YAY! switch(i) inside a for loop for i. DailyWTF, here we come!
			{
				case 0:
					drawpic_skin(p, "kh_red", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 1:
					drawpic_skin(p, "kh_blue", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 2:
					drawpic_skin(p, "kh_yellow", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 3:
					drawpic_skin(p, "kh_pink", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
			}
		}
		p_x += 0.25 * mySize_x;
		pa_x += 0.25 * mySize_x;
	}
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
		HUD_Panel_DrawProgressBar(pos, 0, eX * p * mySize_x + eY * mySize_y, HUD_Panel_GetProgressBarColor("nexball"), cvar("hud_progressbar_alpha") * HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
	}

	pos_x += 0.5 * mySize_x - 0.5 * mySize_y; //horizontal margin to the picture

	if (stat_items & IT_KEY1)
		drawpic_skin(pos, "nexball_carrying", '1 1 0' * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
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
		if(cvar("cl_autodemo_delete_keeprecords"))
		{
			f = cvar("cl_autodemo_delete");
			f &~= 1;
			cvar_set("cl_autodemo_delete", ftos(f)); // don't delete demo with new record!
		}
	}

	if(t != crecordtime_prev) {
		crecordtime_prev = t;
		crecordtime_change_time = time;
	}
	f = time - crecordtime_change_time;

	if (f > 1) {
		drawstring(pos, "Personal best ", '1 1 0' * 0.15 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
		drawstring(pos + eY * 0.2 * mySize_y, TIME_ENCODED_TOSTRING(t), '1 1 0' * 0.2 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
	} else {
		drawstring(pos, "Personal best ", '1 1 0' * 0.15 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
		drawstring(pos + eY * 0.2 * mySize_y, TIME_ENCODED_TOSTRING(t), '1 1 0' * 0.2 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
		drawstring_expanding(pos, "Personal best ", '1 1 0' * 0.15 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL, f);
		drawstring_expanding(pos + eY * 0.2 * mySize_y, TIME_ENCODED_TOSTRING(t), '1 1 0' * 0.2 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL, f);
	}

	// server record
	t = race_server_record;
	if(t != srecordtime_prev) {
		srecordtime_prev = t;
		srecordtime_change_time = time;
	}
	f = time - srecordtime_change_time;

	if (f > 1) {
		drawstring(pos + eY * 0.5 * mySize_y, "Server best ", '1 1 0' * 0.15 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
		drawstring(pos + eY * 0.5 * mySize_y + eY * 0.2 * mySize_y, TIME_ENCODED_TOSTRING(t),'1 1 0' * 0.2 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
	} else {
		drawstring(pos + eY * 0.5 * mySize_y, "Server best ", '1 1 0' * 0.15 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
		drawstring(pos + eY * 0.5 * mySize_y + eY * 0.2 * mySize_y, TIME_ENCODED_TOSTRING(t),'1 1 0' * 0.2 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL);
		drawstring_expanding(pos + eY * 0.5 * mySize_y, "Server best ", '1 1 0' * 0.15 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL, f);
		drawstring_expanding(pos + eY * 0.5 * mySize_y + eY * 0.2 * mySize_y, TIME_ENCODED_TOSTRING(t),'1 1 0' * 0.2 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS), DRAWFLAG_NORMAL, f);
	}

	if (race_status != race_status_prev || race_status_name != race_status_name_prev) {
		race_status_time = time + 5;
		race_status_prev = race_status;
		if (race_status_name_prev)
			strunzone(race_status_name_prev);
		race_status_name_prev = strzone(race_status_name);
	}

	pos_x += mySize_x/2;
	// race "awards"
	float a;
	a = bound(0, race_status_time - time, 1);

	string s;
	s = textShortenToWidth(race_status_name, 120, '10 10 0', stringwidth_colors);

	float rank;
	if(race_status > 0)
		rank = race_CheckName(race_status_name);
	string rankname;
	rankname = race_PlaceName(rank);

	if(race_status == 0)
		drawpic_skin(pos, "race_newfail", '80 80 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
	else if(race_status == 1) {
		drawpic_skin(pos, "race_newtime", '80 80 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '40 80 0' - eX * stringwidth(s, TRUE, '5 0 0'), s, '10 10 0', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
		drawstring(pos + '40 20 0' - eX * stringwidth(rankname, TRUE, '7 0 0'), rankname, '14 14 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
	} else if(race_status == 2) {
		if(race_status_name == GetPlayerName(player_localentnum -1) || !race_myrank || race_myrank < rank)
			drawpic_skin(pos, "race_newrankgreen", '80 80 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
		else
			drawpic_skin(pos, "race_newrankyellow", '80 80 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '40 80 0' - eX * stringwidth(s, TRUE, '5 0 0'), s, '10 10 0', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
		drawstring(pos + '40 20 0' - eX * stringwidth(rankname, TRUE, '7 0 0'), rankname, '14 14 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
	} else if(race_status == 3) {
		drawpic_skin(pos, "race_newrecordserver", '80 80 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '40 80 0' - eX * stringwidth(s, TRUE, '5 0 0'), s, '10 10 0', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
		drawstring(pos + '40 20 0' - eX * stringwidth(rankname, TRUE, '7 0 0'), rankname, '14 14 0', '1 1 1', HUD_Panel_GetFgAlpha(HUD_PANEL_MODICONS) * a, DRAWFLAG_NORMAL);
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
	if (gametype != GAME_KEYHUNT && gametype != GAME_CTF && gametype != GAME_NEXBALL && gametype != GAME_CTS && gametype != GAME_RACE && !hud_configure)
		return;

	float id = HUD_PANEL_MODICONS;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	if(mod_active != mod_prev) {
		mod_change = time;
		mod_prev = mod_active;
	}

	if(mod_active || hud_configure)
		mod_alpha = bound(0, (time - mod_change) * 2, 1);
	else
		mod_alpha = bound(0, 1 - (time - mod_change) * 2, 1);

	if(mod_alpha)
		HUD_Panel_DrawBg(id, pos, mySize, mod_alpha);

	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	// these MUST be ran in order to update mod_active
	if(gametype == GAME_KEYHUNT)
		HUD_Mod_KH(pos, mySize);
	else if(gametype == GAME_CTF || hud_configure)
		HUD_Mod_CTF(pos, mySize); // forcealpha only needed for ctf icons, as only they are shown in config mode
	else if(gametype == GAME_NEXBALL)
		HUD_Mod_NexBall(pos, mySize);
	else if(gametype == GAME_CTS || gametype == GAME_RACE)
		HUD_Mod_Race(pos, mySize);
}

// Draw pressed keys (#11)
//
void HUD_DrawPressedKeys(void)
{
	float id = HUD_PANEL_PRESSEDKEYS;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	float pressedkeys;

	pressedkeys = getstatf(STAT_PRESSED_KEYS);
	drawpic_skin(pos, "key_bg.tga",           mySize, '1 1 1', 0.1 * HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	drawpic_skin(pos + eX * mySize_x - eX * 0.22 * mySize_x +       eY * 0.195 * mySize_y, ((pressedkeys & KEY_CROUCH) ? "key_crouch_inv.tga" : "key_crouch.tga"),        '1 1 0' * (1/3) * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	drawpic_skin(pos + eX * 0.5 * mySize_x - eX * 0.23 * mySize_y + eY * 0.040 * mySize_y, ((pressedkeys & KEY_FORWARD) ? "key_forward_inv.tga" : "key_forward.tga"),     '1 1 0' * 0.46 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	drawpic_skin(pos + eX * 0.023 * mySize_x +                      eY * 0.195 * mySize_y, ((pressedkeys & KEY_JUMP) ? "key_jump_inv.tga" : "key_jump.tga"),              '1 1 0' * (1/3) * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	drawpic_skin(pos + eX * 0.1 * mySize_x +                        eY * 0.486 * mySize_y, ((pressedkeys & KEY_LEFT) ? "key_left_inv.tga" : "key_left.tga"),              '1 1 0' * 0.46 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	drawpic_skin(pos + eX * 0.5 * mySize_x - eX * 0.23 * mySize_y + eY * 0.486 * mySize_y, ((pressedkeys & KEY_BACKWARD) ? "key_backward_inv.tga" : "key_backward.tga"),  '1 1 0' * 0.46 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
	drawpic_skin(pos + eX * mySize_x - eX * 0.372 * mySize_x +      eY * 0.486 * mySize_y, ((pressedkeys & KEY_RIGHT) ? "key_right_inv.tga" : "key_right.tga"),           '1 1 0' * 0.46 * mySize_y, '1 1 1', HUD_Panel_GetFgAlpha(id), DRAWFLAG_NORMAL);
}

// Handle chat as a panel (#12)
//
float chat_prevtime;
void HUD_Chat(void)
{
	float id = HUD_PANEL_CHAT;
	vector pos, mySize;
	pos = HUD_Panel_GetPos(id);
	mySize = HUD_Panel_GetSize(id);

	HUD_Panel_DrawBg(id, pos, mySize, 0);
	float padding;
	padding = HUD_Panel_GetPadding(id);
	if(padding)
	{
		pos += '1 1 0' * padding;
		mySize -= '2 2 0' * padding;
	}

	cvar_set("con_csqcpositioning", "1");

	cvar_set("con_chatrect_x", ftos(pos_x/vid_conwidth));
	cvar_set("con_chatrect_y", ftos(pos_y/vid_conheight));

	cvar_set("con_chatwidth", ftos(mySize_x/vid_conwidth));
	cvar_set("con_chat", ftos(floor(mySize_y/cvar("con_chatsize") - 0.5)));

	if(hud_configure)
	{
		if(chat_prevtime != floor(time/5))
		{
			chat_prevtime = floor(time/5);

			float sound_prev;
			sound_prev = cvar("con_chatsound");

			// disable chat bleep
			cvar_set("con_chatsound", "0");
			print("\x01Player^7: This is the chat area\n");
			cvar_set("con_chatsound", ftos(sound_prev));
		}
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

	switch(cvar("cl_showspeed_unit"))
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

	numsize_x = numsize_y = cvar("cl_showspeed_size");
	pos = (vid_conheight - numsize_y) * cvar("cl_showspeed_position");

	drawfont = hud_bigfont;
	drawstringcenter(eX + pos * eY, speed, numsize, '1 1 1', hud_fg_alpha, DRAWFLAG_NORMAL);

	if (cvar("cl_showspeed_z") == 1) {
		zspeed = strcat(ftos(fabs(floor( pmove_vel_z * conversion_factor + 0.5 ))), unit);
		drawstringcenter(eX + pos * eY + numsize_y * eY, zspeed, numsize * 0.5, '1 1 1', hud_fg_alpha, DRAWFLAG_NORMAL);
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
	if(cvar("cl_showacceleration_z"))
		acceleration = (vlen(pmove_vel) - vlen(acc_prevspeed)) * (1 / f);
	else
		acceleration = (vlen(pmove_vel - '0 0 1' * pmove_vel_z) - vlen(acc_prevspeed - '0 0 1' * acc_prevspeed_z)) * (1 / f);
	acc_prevspeed = pmove_vel;
	acc_prevtime = time;

	f = bound(0, f * 10, 1);
	acc_avg = acc_avg * (1 - f) + acceleration * f;
	acceleration = acc_avg / getstatf(STAT_MOVEVARS_MAXSPEED);

	pos = top - sz/2 * eY + (cvar("cl_showacceleration_position") * vid_conheight) * eY;

	sz = cvar("cl_showacceleration_size");
	scale = cvar("cl_showacceleration_scale");
	alpha = cvar("cl_showacceleration_alpha");
	if (cvar("cl_showacceleration_color_custom"))
		rgb = stov(cvar_string("cl_showacceleration_color"));
	else {
		rgb = '1 1 1';
		if (acceleration < 0) {
			rgb = '1 .5 .5' - '0 .5 .5' * bound(0, -acceleration * 0.2, 1);
		} else if (acceleration > 0) {
			rgb = '.5 1 .5' - '.5 0 .5' * bound(0, +acceleration * 0.2, 1);
		}
	}

	if (acceleration > 0)
		HUD_Panel_DrawProgressBar(pos, 0, acceleration * scale * '40 0 0' + sz * eY, rgb, alpha * hud_fg_alpha, DRAWFLAG_NORMAL);
	else if (acceleration < 0)
		HUD_Panel_DrawProgressBar(pos + acceleration * scale * '40 0 0', 0, -acceleration * scale * '40 0 0' + sz * eY, rgb, alpha * hud_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_Reset (void)
{
	// reset gametype specific icons
	if(gametype == GAME_KEYHUNT)
		HUD_Mod_KH_Reset();
	else if(gametype == GAME_CTF)
		HUD_Mod_CTF_Reset();
}

void HUD_Main (void)
{
	if(disable_menu_alphacheck == 1)
		menu_fade_alpha = 1;
	else
		menu_fade_alpha = (1 - cvar("_menu_alpha"));
	hud_fg_alpha = cvar("hud_fg_alpha");

	hud_border_thickness = bound(0, cvar("hud_border_thickness"), 5);
	hud_accuracy_border_thickness = bound(0, cvar_or("hud_accuracy_border_thickness", 1), 5);
	hud_color_bg_team = cvar("hud_color_bg_team");

	hud_fontsize = HUD_GetFontsize("hud_fontsize");
	hud_fontsize_spec = HUD_GetFontsize("hud_fontsize_spec");

	hud_configure = cvar("_hud_configure");

	// Drawing stuff

	// HUD configure visible grid
	if(hud_configure && cvar("hud_configure_grid") && cvar("hud_configure_grid_alpha"))
	{
		float i;
		// x-axis
		for(i = 0; i < vid_conwidth/max(2, cvar("hud_configure_grid_x")); ++i)
		{
			drawfill(eX * i * max(2, cvar("hud_configure_grid_x")), eX + eY * vid_conheight, '0.5 0.5 0.5', cvar("hud_configure_grid_alpha"), DRAWFLAG_NORMAL);
		}
		// y-axis
		for(i = 0; i < vid_conheight/max(2, cvar("hud_configure_grid_y")); ++i)
		{
			drawfill(eY * i * max(2, cvar("hud_configure_grid_y")), eY + eX * vid_conwidth, '0.5 0.5 0.5', cvar("hud_configure_grid_alpha"), DRAWFLAG_NORMAL);
		}
	}

	if(cvar_string("hud_dock") != "")
		drawpic_skin('0 0 0', cvar_string("hud_dock"), eX * vid_conwidth + eY * vid_conheight, HUD_Panel_Dock_GetColor(), cvar("hud_dock_alpha") * menu_fade_alpha, DRAWFLAG_NORMAL);

	if(HUD_Panel_CheckActive(HUD_PANEL_WEAPONICONS) || hud_configure)
		HUD_WeaponIcons();
	if(HUD_Panel_CheckActive(HUD_PANEL_INVENTORY) || hud_configure)
		HUD_Inventory();
	if(HUD_Panel_CheckActive(HUD_PANEL_POWERUPS) || hud_configure)
		HUD_Powerups();
	if(HUD_Panel_CheckActive(HUD_PANEL_HEALTHARMOR) || hud_configure)
		HUD_HealthArmor();
	if(HUD_Panel_CheckActive(HUD_PANEL_NOTIFY) || hud_configure)
		HUD_Notify();
	if(HUD_Panel_CheckActive(HUD_PANEL_TIMER) || hud_configure)
		HUD_Timer();
	// TODO hud'ify
	if(HUD_Panel_CheckActive(HUD_PANEL_RADAR) || hud_configure)
		if(cvar_string("hud_radar") != "0" && (cvar("hud_radar") == 2 || teamplay))
			HUD_Radar();
	if(HUD_Panel_CheckActive(HUD_PANEL_SCORE) || hud_configure)
		HUD_Score();
	if(HUD_Panel_CheckActive(HUD_PANEL_RACETIMER) || hud_configure)
		if(gametype == GAME_RACE || gametype == GAME_CTS || hud_configure)
			HUD_RaceTimer();
	if(HUD_Panel_CheckActive(HUD_PANEL_VOTE) || hud_configure)
		HUD_VoteWindow();
	if(HUD_Panel_CheckActive(HUD_PANEL_MODICONS) || hud_configure)
		HUD_ModIcons();
	// TODO hud'ify
	if(HUD_Panel_CheckActive(HUD_PANEL_PRESSEDKEYS) || hud_configure)
		if(spectatee_status > 0 || cvar("hud_pressedkeys") >= 2 || hud_configure)
			HUD_DrawPressedKeys();
	if(HUD_Panel_CheckActive(HUD_PANEL_CHAT) || hud_configure)
		HUD_Chat();
	else
		cvar_set("con_csqcpositioning", "0");

	// TODO hud_'ify these
	if (cvar("cl_showspeed"))
		HUD_ShowSpeed();
	if (cvar("cl_showacceleration"))
		HUD_ShowAcceleration();

	if (hud_configure && spectatee_status) // try to join if we are in hud_configure mode, but still spectating (in order to get rid of motd and such)
		localcmd("cmd selectteam auto; cmd join\n");

	if (!hud_configure) // hud config mode disabled, enable normal alpha stuff again
		disable_menu_alphacheck = 0;
}
