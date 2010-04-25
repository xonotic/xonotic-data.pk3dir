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
	float yellow_accuracy = cvar("hud_accuracy_yellow"); // value at which this function returns yellow
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

		drawpic(hl_pos, strcat("gfx/hud/sb_highlight_", l_length), hl_size, '1 1 1', alpha, dflags);
	}

	if (stroke == 1)
		num_color = '1 1 1';
	else
		num_color = rgb;

	if(minus)
	{
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_minus_stroke", vsize, rgb, alpha, dflags);
		drawpic(pos, "gfx/hud/num_minus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	} else if(plus)
	{
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_plus_stroke", vsize, rgb, alpha, dflags);
		drawpic(pos, "gfx/hud/num_plus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}

	for(i = 0; i < l; ++i)
	{
		tmp = substring(str, i, 1);
		if (stroke == 1)
			drawpic(pos, strcat("gfx/hud/num_", tmp, "_stroke"), vsize, rgb, alpha, dflags);
		drawpic(pos, strcat("gfx/hud/num_", tmp), vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}
}

// color the number differently based on how big it is (used in the health/armor panel)
void HUD_DrawXNum_Colored (vector pos, float x, float lettersize, float alpha)
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
	HUD_DrawXNum(pos, x, 3, 0, lettersize, color, 0, 0, alpha, DRAWFLAG_NORMAL);
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

	centerprint_fontsize = Sbar_GetFontsize("scr_centersize");

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

string HUD_Panel_GetName(float id)
{
	switch(id) {
		case 0: return "weaponicons"; break;
		case 1: return "inventory"; break;
		case 2: return "powerups"; break;
		case 3: return "healtharmor"; break;
		case 4: return "notify"; break;
		case 5: return "timer"; break;
		case 6: return "radar"; break;
		case 7: return "score"; break;
		case 8: return "racetimer"; break;
		default: return "";
	}
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
	return stov(cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_size")));
}

// return pos of given panel
vector HUD_Panel_GetPos(float id)
{
	vector pos;
	pos = stov(cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_pos")));

	if (pos_x < 0)
		pos_x = vid_conwidth + pos_x;
	if (pos_y < 0)
		pos_y = vid_conheight + pos_y;
	return pos;
}

float HUD_Panel_GetMarigin(float id)
{
	return bound(1, MARIGIN_MULTIPLIER * cvar_or(strcat("hud_", HUD_Panel_GetName(id), "_marigin"), 30), 200);
}

vector HUD_Panel_GetColor(float id)
{
	if(cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_color")) != "")
		return stov(cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_color")));
	else
		return stov(cvar_string("hud_color"));
}

float HUD_Panel_GetBgActive(float id)
{
	if(cvar("_hud_configure"))
		return 1;

	return cvar_or(strcat("hud_", HUD_Panel_GetName(id), "_bg"), 1);
}

// check if resize will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckResize(float id, vector myPos, vector mySize)
{
	float i;

	vector myTarget;
	myTarget = mySize;

	myPos = myPos - '1 1 0' * HUD_Panel_GetMarigin(id);
	mySize = mySize + '1 1 0' * HUD_Panel_GetMarigin(id);

	vector targPos;
	vector targSize;
	vector myCenter;
	vector targCenter;

	for (i = 0; i < panel_cnt; ++i) {
		if(i == id || !HUD_Panel_CheckActive(i))
			continue;

		targPos = HUD_Panel_GetPos(i);
		targSize = HUD_Panel_GetSize(i);

		if(myPos_y + mySize_y < targPos_y)
			continue;
		if(myPos_y > targPos_y + targSize_y)
			continue;

		if(myPos_x + mySize_x < targPos_x)
			continue;
		if(myPos_x > targPos_x + targSize_x)
			continue;

		myCenter_x = myPos_x + 0.5 * mySize_x;
		myCenter_y = myPos_y + 0.5 * mySize_y;

		targCenter_x = targPos_x + 0.5 * targSize_x;
		targCenter_y = targPos_y + 0.5 * targSize_y;

		float k, y;
		k = (targCenter_y - targPos_y) / (targPos_x + targSize_x - targCenter_x);
		y = k * (targCenter_x - myCenter_x) + targCenter_y;
		if(y > myCenter_y)
		{
			y = k * (myCenter_x - targCenter_x) + targCenter_y;
			if(y < myCenter_y)
			{
				myTarget_x = targPos_x - myPos_x;
			}
			else
			{
				myTarget_y = targPos_y - myPos_y;
			}
		}
		else
		{
			y = k * (myCenter_x - targCenter_x) + targCenter_y;
			if(y < myCenter_y)
			{
				myTarget_y = targPos_y + targSize_y;
			}
			else
			{
				myTarget_x = targPos_x + targSize_x;
			}
		}
	}

	return myTarget;
}

// TODO: checkResize
float HUD_Panel_SetSize(float id, vector mySize)
{
	float didntresize;

	vector oldSize;
	oldSize = stov(cvar_string(strcat("hud_", HUD_Panel_GetName(id), "_size")));

	mySize_x = bound(0.025 * vid_conwidth, mySize_x, vid_conwidth);
	mySize_y = bound(0.025 * vid_conheight, mySize_y, vid_conheight);

	mySize = HUD_Panel_CheckResize(id, HUD_Panel_GetPos(id), mySize);

	mySize_x = bound(0.025 * vid_conwidth, mySize_x, vid_conwidth);
	mySize_y = bound(0.025 * vid_conheight, mySize_y, vid_conheight);

	// this is to check if (and how) SetPos should be called
	if(mySize_x == oldSize_x && mySize_y == oldSize_y)
		didntresize = 3; // didnt resize either
	else if(mySize_x == oldSize_x && mySize_y != oldSize_y)
		didntresize = 2; // resized Y
	else if(mySize_y == oldSize_y && mySize_x != oldSize_x)
		didntresize = 1; // resized X

	string s;
	s = strcat(ftos(mySize_x), " ", ftos(mySize_y));
	cvar_set(strcat("hud_", HUD_Panel_GetName(id), "_size"), s);
	return didntresize;
}

// check if move will result in panel being moved into another panel. If so, return snapped vector, otherwise return the given vector
vector HUD_Panel_CheckMove(float id, vector myPos, vector mySize)
{
	float i;

	vector myTarget;
	myTarget = myPos;

	myPos = myPos - '1 1 ' * HUD_Panel_GetMarigin(id);
	mySize = mySize + '1 1 0' * HUD_Panel_GetMarigin(id);

	vector targPos;
	vector targSize;
	vector myCenter;
	vector targCenter;

	for (i = 0; i < panel_cnt; ++i) {
		if(i == id || !HUD_Panel_CheckActive(i))
			continue;

		targPos = HUD_Panel_GetPos(i);
		targSize = HUD_Panel_GetSize(i);

		if(myPos_y + mySize_y < targPos_y)
			continue;
		if(myPos_y > targPos_y + targSize_y)
			continue;

		if(myPos_x + mySize_x < targPos_x)
			continue;
		if(myPos_x > targPos_x + targSize_x)
			continue;

		myCenter_x = myPos_x + 0.5 * mySize_x;
		myCenter_y = myPos_y + 0.5 * mySize_y;

		targCenter_x = targPos_x + 0.5 * targSize_x;
		targCenter_y = targPos_y + 0.5 * targSize_y;

		float k, y;
		k = (targCenter_y - targPos_y) / (targPos_x + targSize_x - targCenter_x);
		y = k * (targCenter_x - myCenter_x) + targCenter_y;
		if(y > myCenter_y)
		{
			y = k * (myCenter_x - targCenter_x) + targCenter_y;
			if(y < myCenter_y)
			{
				myTarget_x = targPos_x - mySize_x;
			}
			else
			{
				myTarget_y = targPos_y - mySize_y ;
			}
		}
		else
		{
			y = k * (myCenter_x - targCenter_x) + targCenter_y;
			if(y < myCenter_y)
			{
				myTarget_y = targPos_y + targSize_y + '1 0 0' * HUD_Panel_GetMarigin(id);
			}
			else
			{
				myTarget_x = targPos_x + targSize_x + '1 0 0' * HUD_Panel_GetMarigin(id);
			}
		}
	}

	return myTarget;
}

void HUD_Panel_SetPos(float id, vector pos, float didntresize)
{
	vector oldPos;
	oldPos = HUD_Panel_GetPos(id);
	if(didntresize == 2)
		pos_x = oldPos_x;
	else if(didntresize == 1)
		pos_y = oldPos_y;
	else if(didntresize == 3)
		return;

	vector mySize;
	mySize = HUD_Panel_GetSize(id);

	pos = HUD_Panel_CheckMove(id, pos, mySize);

	pos_x = bound(0, pos_x, vid_conwidth - mySize_x);
	pos_y = bound(0, pos_y, vid_conheight - mySize_y);

	if (pos_x + 0.5 * mySize_x > 0.5 * vid_conwidth)
		pos_x = pos_x - vid_conwidth;
	if (pos_y + 0.5 * mySize_y > 0.5 * vid_conheight)
		pos_y = pos_y - vid_conheight;

	string s;
	s = strcat(ftos(pos_x), " ", ftos(pos_y));

	cvar_set(strcat("hud_", HUD_Panel_GetName(id), "_pos"), s);
}

float mouseClicked;
float prevMouseClicked; // previous state
float HUD_Panel_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	prevMouseClicked = mouseClicked;
	if(nPrimary == K_MOUSE1)
	{
		if(bInputType == 0) { // key pressed
			mouseClicked = 1;
			return true;
		}
		if(bInputType == 1) {// key released
			mouseClicked = 0;
			return true;
		}
	}
	return false;
}

vector mousepos, mouseprevpos;
vector mouseToPanelDistance;
float highlightedPanel;
float highlightedAction; // 0 = nothing, 1 = move, 2 = resize
float resizeCorner; // 1 = topleft, 2 = topright, 3 = bottomleft, 4 = bottomright
void HUD_Panel_Mouse()
{
	if(mouseClicked == 0) {
		highlightedPanel = -1;
		highlightedAction = 0;
	}

	mousepos = mousepos + getmousepos();

	mousepos_x = bound(0, mousepos_x, vid_conwidth);
	mousepos_y = bound(0, mousepos_y, vid_conheight);

	drawpic(mousepos, "gfx/menu/default/cursor.tga", '32 32 0', '1 1 1', 1, hud_alpha_fg);

	if(mouseClicked)
	{
		float i, marigin;
		vector panelPos;
		vector panelSize;

		for(i = 0; i <= panel_cnt; i++)
		{
			panelPos = HUD_Panel_GetPos(i);
			panelSize = HUD_Panel_GetSize(i);
			marigin = HUD_Panel_GetMarigin(i);
			if(prevMouseClicked == 0) {
				// move
				if(mousepos_x >= panelPos_x && mousepos_y >= panelPos_y && mousepos_x <= panelPos_x + panelSize_x && mousepos_y <= panelPos_y + panelSize_y)
				{
					highlightedPanel = i;
					highlightedAction = 1;
				}
				// resize from topleft border
				else if(mousepos_x >= panelPos_x - eX * marigin && mousepos_y >= panelPos_y - eX * marigin && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 1;
				}
				// resize from topright border
				else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y - eX * marigin && mousepos_x <= panelPos_x + panelSize_x + eX * marigin && mousepos_y <= panelPos_y + 0.5 * panelSize_y)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 2;
				}
				// resize from bottomleft border
				else if(mousepos_x >= panelPos_x - eX * marigin && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + 0.5 * panelSize_x && mousepos_y <= panelPos_y + panelSize_y + eY * marigin)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 3;
				}
				// resize from bottomright border
				else if(mousepos_x >= panelPos_x + 0.5 * panelSize_x && mousepos_y >= panelPos_y + 0.5 * panelSize_y && mousepos_x <= panelPos_x + panelSize_x + eX * marigin && mousepos_y <= panelPos_y + panelSize_y + eY * marigin)
				{
					highlightedPanel = i;
					highlightedAction = 2;
					resizeCorner = 4;
				}
			}

			if(highlightedPanel == i)
			{
				if(prevMouseClicked == 0)
					mouseToPanelDistance = mousepos - panelPos;

				if(highlightedAction == 1)
					HUD_Panel_SetPos(i, mousepos - mouseToPanelDistance, 0);
				else if(highlightedAction == 2)
				{
					float didntresize; // panel too big/too small, dont resize (also has to affect moving)
					if(resizeCorner == 1) {
						didntresize = HUD_Panel_SetSize(i, panelSize + mouseprevpos - mousepos);
						HUD_Panel_SetPos(i, mousepos - mouseToPanelDistance, didntresize);
					}
					if(resizeCorner == 2) {
						didntresize = HUD_Panel_SetSize(i, panelSize + eX * (mousepos_x - mouseprevpos_x) + eY * (mouseprevpos_y - mousepos_y));
						HUD_Panel_SetPos(i, eX * panelPos_x + eY * (mousepos_y - mouseToPanelDistance_y), didntresize);
					}
					if(resizeCorner == 3) {
						didntresize = HUD_Panel_SetSize(i, panelSize + eX * (mouseprevpos_x - mousepos_x) + eY * (mousepos_y - mouseprevpos_y));
						HUD_Panel_SetPos(i, eX * (mousepos_x - mouseToPanelDistance_x) + eY * panelPos_y, didntresize);
					}
					if(resizeCorner == 4) {
						HUD_Panel_SetSize(i, panelSize + mousepos - mouseprevpos);
					}
				}
			}
		}
	}
	mouseprevpos = mousepos;
	prevMouseClicked = mouseClicked;
}

/*void HUD_DrawDockEdge(float id, vector p1, vector p2, float target)
{
	vector pos;
	vector size;

	pos =
*/ // maybe one day, since this will be quite complicated

// Weapon icons (#0)
//

float weaponspace[10];
void HUD_WeaponIcons_Clear()
{
	float idx;
	for(idx = 0; idx < 10; ++idx)
		weaponspace[idx] = 0;
}

void HUD_WeaponIcons()
{
	float alpha, height, marigin, accuracybar_height, stat_weapons; // "constants"
	vector pos, color, accuracy_color;
	float i, id, fade, weapon_stats, weapon_hit, weapon_damage, weapon_cnt; // variables

	pos = HUD_Panel_GetPos(0);
	height = cvar_or("hud_weaponicons_height", 12);
	marigin = HUD_Panel_GetMarigin(0);
	accuracybar_height = cvar_or("hud_weaponicons_accuracybar_height", 3);
	color = HUD_Panel_GetColor(0);

	stat_weapons = getstati(STAT_WEAPONS);
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		self = get_weaponinfo(i);
		if(self.weapons && self.impulse >= 0 && stat_weapons & self.weapons)
			++weapon_cnt;
	}

	if(HUD_Panel_GetBgActive(0) && weapon_cnt)
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", eX * (height * 2 * weapon_cnt + 2 * marigin) + eY * (height + 2 * marigin), color, hud_alpha_bg, '1 1 0' * (1/marigin));

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

	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		self = get_weaponinfo(i);
		if(self.weapons && self.impulse >= 0 && stat_weapons & self.weapons)
		{
			id = self.impulse;

			alpha = (id == activeweapon) ? 1 : 0.6;

			weapon_hit = weapon_hits[self.weapon-WEP_FIRST];
			weapon_damage = weapon_fired[self.weapon-WEP_FIRST];
			if(id == 0) // porto and hook should be last
				id = 9;
			else
				id = --id;

			if(id+1 == activeweapon)
				drawpic(pos, "gfx/hud/sb_ammobg", eX * (2 * height) + eY * height, color, fade * hud_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(pos, strcat("gfx/hud/inv_weapon", self.netname), eX * 2 * height + eY * height, '1 1 1', fade * hud_alpha_fg, DRAWFLAG_NORMAL);
			//pos_y += size * 1/6; TODO: support for vertical mode
			if(cvar_or("hud_weaponicons_number", 1))
				drawstring(pos, ftos(id+1), '1 1 0' * 0.5 * height, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);

			// draw the weapon accuracy on the HUD
			if(hud_accuracy_hud && !(gametype == GAME_RACE || gametype == GAME_CTS))
			{
				if(weapon_damage)
					weapon_stats = floor(100 * weapon_hit / weapon_damage);

				accuracy_color = HUD_AccuracyColor(weapon_stats);
				if(weapon_damage)
					drawpic(pos - '2 0 0' + eY * (height - accuracybar_height), "gfx/hud/sb_accuracy_bar.tga", eX * 2 * height + eY * accuracybar_height, accuracy_color, hud_alpha_fg, DRAWFLAG_NORMAL);
			}
			pos_x += height * 2;
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
		case 0: return "gfx/hud/sb_shells";
		case 1: return "gfx/hud/sb_bullets";
		case 2: return "gfx/hud/sb_rocket";
		case 3: return "gfx/hud/sb_cells";
		case 4: return "gfx/hud/sb_fuel";
		default: return "";
	}
}

void HUD_Inventory()
{
	float i;
	float stat_items;
	float marigin;

	vector pos, mySize, mysize, mypos, color;
	marigin = HUD_Panel_GetMarigin(1);
	pos = HUD_Panel_GetPos(1);
	mySize = HUD_Panel_GetSize(1);
	color = HUD_Panel_GetColor(1);

	if(HUD_Panel_GetBgActive(1))
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", mySize + '1 1 0' * 2 * marigin, color, hud_alpha_bg, '1 1 0' * (marigin/MARIGIN_MULTIPLIER));

	// ammo
	stat_items = getstati(STAT_ITEMS);
	for (i = 0; i < 4; ++i) {
		float a;
		a = getstati(GetAmmoStat(i)); // how much ammo do we have of type i?

		if(cvar("hud_ammo_onlycurrent")) { // force showing current ammo only with conwidths < 800
			if (stat_items & GetAmmoItemCode(i)) {
				drawpic(pos - '1 1 0' * marigin, "gfx/hud/sb_ammobg", mysize + '1 1 0' * marigin, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
				drawpic(pos + eX * mysize_x * 1.7, GetAmmoPicture(i), '24 24 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
				if(a < 10)
					HUD_DrawXNum(pos + '5 5 0', a, 3, 0, 24, '0.7 0 0', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
				else
					HUD_DrawXNum(pos + '5 5 0', a, 3, 0, 24, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
			}
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
					drawpic(mypos, "gfx/hud/sb_ammobg", mysize, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
				drawpic(mypos + eX * 0.66 * mysize_x + eY * 0.05 * mysize_y, GetAmmoPicture(i), '1 1 0' * 0.8 * mysize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
				if (a < 10) {
					if(stat_items & GetAmmoItemCode(i))
						HUD_DrawXNum(mypos + '6 4.5 0', a, 3, 0, 16, '0.7 0 0', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
					else
						HUD_DrawXNum(mypos + '6 4.5 0', a, 3, 0, 16, '0.7 0 0', 0, 0, hud_alpha_fg * 0.7, DRAWFLAG_NORMAL);
				} else {
					if(stat_items & GetAmmoItemCode(i))
						HUD_DrawXNum(mypos + '1 1 0' * 0.26 * mysize_y, a, 3, 0, 0.5 * mysize_y, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
					else
						HUD_DrawXNum(mypos + '1 1 0' * 0.26 * mysize_y, a, 3, 0, 0.5 * mysize_y, '0.7 0.7 0.7', 0, 0, hud_alpha_fg * 0.7, DRAWFLAG_NORMAL);
				}
			}
		}
	}

	// fuel ammo
	a = getstati(GetAmmoStat(4)); // how much fuel do we have?

	if (a > 0) { // if we have fuel, draw the amount
		float invincibility_time, dt;
		invincibility_time = getstatf(STAT_INVINCIBLE_FINISHED);
		dt = invincibility_time - time;
		if (dt > 0) { // if the invincibility timer is active, draw fuel ammo elsewhere
			pos_x += 140;
			pos_y += -72;
		}
		else { // if the invincibility timer is inactive, draw the fuel ammo there (it's rare to have invincibility + fuel anyway)
			pos_x += 140;
			pos_y += -20;
		}
		drawpic(pos - '0 2 0' + '52 0 0', GetAmmoPicture(4), '20 20 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		if (a > 10)
			HUD_DrawXNum(pos, a, 3, 0, 16, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		else
			HUD_DrawXNum(pos, a, 3, 0, 16, '0.7 0 0', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
	}
}


// Powerups (#2)
// TODO!
void HUD_Powerups() {
	float stat_items, dt;
	float marigin;

	vector pos, mySize, color;
	marigin = HUD_Panel_GetMarigin(2);
	pos = HUD_Panel_GetPos(2);
	mySize = HUD_Panel_GetSize(2);
	color = HUD_Panel_GetColor(2);

	if(HUD_Panel_GetBgActive(2))
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", mySize + '1 1 0' * 2 * marigin, color, hud_alpha_bg, '1 1 0' * (marigin/MARIGIN_MULTIPLIER));

	stat_items = getstati(STAT_ITEMS);
	/*
	if not(stat_items & IT_STRENGTH)
		if not(stat_items & IT_INVINCIBLE)
			return;
	*/

	if (getstati(STAT_HEALTH) <= 0)
		return;

	float strength_time, invincibility_time, countdown_fontsize;

	//strength
	strength_time = getstatf(STAT_STRENGTH_FINISHED);
	invincibility_time = getstatf(STAT_INVINCIBLE_FINISHED);

	if (strength_time) {
		dt = strength_time - time;
		if(dt > 0)
		{
			if(dt < 5)
			{
				drawpic_expanding_two(pos, "gfx/hud/sb_str", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE,
					bound(0, (ceil(dt) - dt) / 0.5, 1));
			}
			else
			{
				drawpic(pos, "gfx/hud/sb_str", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE);
			}
			HUD_DrawXNum(pos - '40 -2 0', ceil(dt), 2, 0, countdown_fontsize, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		}
		else if(dt > -1)
		{
			drawpic_expanding(pos, "gfx/hud/sb_str", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE,
				bound(0, -dt / 0.5, 1));
		}
	}

	//invincibility
	if (invincibility_time) {
		dt = invincibility_time - time;
		if(dt > 0)
		{
			if(dt < 5)
			{
				drawpic_expanding_two(pos - '0 -22 0', "gfx/hud/sb_invinc", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE,
					bound(0, (ceil(dt) - dt) / 0.5, 1));
			}
			else
			{
				drawpic(pos - '0 -22 0', "gfx/hud/sb_invinc", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE);
			}
			HUD_DrawXNum(pos - '40 -24 0', ceil(dt), 2, 0, countdown_fontsize, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		}
		else if(dt > -1)
		{
			drawpic_expanding(pos - '0 -22 0', "gfx/hud/sb_invinc", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE,
				bound(0, -dt / 0.5, 1));
		}
	}
}

// Health/armor (#3)
//
void HUD_HealthArmor(void)
{
	float marigin;

	vector pos, mySize, color;
	marigin = HUD_Panel_GetMarigin(3);
	pos = HUD_Panel_GetPos(3);
	mySize = HUD_Panel_GetSize(3);
	color = HUD_Panel_GetColor(3);

	if(HUD_Panel_GetBgActive(3))
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", mySize + '1 1 0' * 2 * marigin, color, hud_alpha_bg, '1 1 0' * (marigin/MARIGIN_MULTIPLIER));

	float armor, health, x;
	armor = getstati(STAT_ARMOR);
	health = getstati(STAT_HEALTH);

	if(hud_hudselector == 2) // combined health and armor display
	{
		vector v;
		v = healtharmor_maxdamage(health, armor, armorblockpercent);

		vector num_pos;
		num_pos = - '96 28 0';

		x = floor(v_x + 1);

		if(v_z) // fully armored
		{
			// here, armorideal > armor
			drawpic(num_pos + '78 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(num_pos + '108 -4.5 0', "gfx/hud/sb_armor", '20 20 0', '1 1 1', hud_alpha_fg * armor / v_y, DRAWFLAG_NORMAL);
		}
		else
		{
			drawpic(num_pos + '108 -4.5 0', "gfx/hud/sb_health", '20 20 0', '1 1 1', hud_alpha_fg * v_y / armor, DRAWFLAG_NORMAL);
			drawpic(num_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		}
		HUD_DrawXNum_Colored(num_pos, x, 24, hud_alpha_fg); // draw the combined health and armor
	}

	else
	{
		vector health_pos, armor_pos;

		if (hud_hudselector == 0) { // old style layout with armor left of health
			armor_pos = pos;
			health_pos = pos + eX * 0.5 * mySize_x;
		}
		else {
			health_pos = pos;
			armor_pos = pos + eX * 0.5 * mySize_x;
		}

		// armor
		x = armor;
		if (x > 0)
		{
			if (x > 45)
				drawpic(armor_pos + eX * 0.35 * mySize_x, "gfx/hud/sb_armor", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
			else
				drawpic(armor_pos + eX * 0.35 * mySize_x, "gfx/hud/sb_armor", '1 1 0' *  mySize_y, '1 1 1', (x+10)/55 * hud_alpha_fg, DRAWFLAG_NORMAL);
			HUD_DrawXNum_Colored(armor_pos + eY * 0.25 * mySize_y, x, 0.5 * mySize_y, hud_alpha_fg);
		}

		// health
		x = health;
		drawpic(health_pos + eX * 0.35 * mySize_x, "gfx/hud/sb_health", '1 1 0' * mySize_y, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		HUD_DrawXNum_Colored(health_pos + eY * 0.25 * mySize_y, x, 0.5 * mySize_y, hud_alpha_fg);
	}
}

// Score (#7)
//
void HUD_Score()
{
	float marigin;

	vector pos, mySize, color;
	marigin = HUD_Panel_GetMarigin(7);
	pos = HUD_Panel_GetPos(7);
	mySize = HUD_Panel_GetSize(7);
	color = HUD_Panel_GetColor(7);

	if(HUD_Panel_GetBgActive(7))
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", mySize + '1 1 0' * 2 * marigin, color, hud_alpha_bg, '1 1 0' * (marigin/MARIGIN_MULTIPLIER));

	float score, distribution, leader;
	vector score_pos, secondary_score_pos, distribution_color;
	entity tm, pl, me;
	me = (spectatee_status > 0) ? playerslots[spectatee_status - 1] : playerslots[player_localentnum - 1];

	if (!teamplay) { // non-teamgames
		// me vector := [team/connected frags id]
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;

		if(pl)
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);
		else
			distribution = 0;

		score = me.(scores[ps_primary]);

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

		HUD_DrawXNum(pos + eX * mySize_x - eX * 6 * 0.3  * mySize_y, distribution, 6, 3, 0.3 * mySize_y, distribution_color, 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		HUD_DrawXNum(pos + eX * mySize_x - eX * 6 * 0.75 * mySize_y + eY * 0.35 * mySize_y, score, 6, 0, 0.75 * mySize_y, distribution_color, leader, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
	} else { // teamgames
		float max_fragcount;
		max_fragcount = -999;

		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == COLOR_SPECTATOR || !tm.team_size) // no players? don't display
				continue;
			score = tm.(teamscores[ts_primary]);
			leader = 0;

			if (score > max_fragcount)
				max_fragcount = score;

			if(tm.team == myteam) {
				if (max_fragcount == score)
					leader = 1;
				HUD_DrawXNum(score_pos, score, 4, 0, 34, GetTeamRGB(tm.team) * 0.8, leader, 1, hud_alpha_fg, DRAWFLAG_NORMAL);
			} else {
				if (max_fragcount == score)
					leader = 1;
				HUD_DrawXNum(secondary_score_pos, score, 6, 0, 16, GetTeamRGB(tm.team) * 0.8, leader, 1, hud_alpha_fg, DRAWFLAG_NORMAL);
				secondary_score_pos = secondary_score_pos + '0 16 0';
			}
		}
	}
}

// Race timer (#8)
//
void HUD_RaceTimer (void) {
	float marigin;

	vector pos, mySize, color;
	marigin = HUD_Panel_GetMarigin(8);
	pos = HUD_Panel_GetPos(8);
	mySize = HUD_Panel_GetSize(8);
	color = HUD_Panel_GetColor(8);

	if(HUD_Panel_GetBgActive(8))
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", mySize + '1 1 0' * 2 * marigin, color, hud_alpha_bg, '1 1 0' * (marigin/MARIGIN_MULTIPLIER));

	drawfont = sbar_bigfont;
	float a, t;
	string s, forcetime;

	if(race_checkpointtime)
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
			//drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
			drawcolorcodedstring(pos, s, '1 1 0' * mySize_y, hud_alpha_fg * a, DRAWFLAG_NORMAL);
		}

		if(race_penaltytime)
		{
			a = bound(0, 2 - (time - race_penaltyeventtime), 1);
			if(a > 0)
			{
				s = strcat("^1PENALTY: ", ftos_decimals(race_penaltytime * 0.1, 1), " (", race_penaltyreason, ")");
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				//drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos - '0 32 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
			}
		}

		if(forcetime != "")
		{
			a = bound(0, (time - race_checkpointtime) / 0.5, 1);
			//drawstring_expanding(m - '16 0 0' * stringwidth(forcetime, FALSE), forcetime, '32 32 0', '1 1 1', hud_alpha_fg, 0, a);
			drawstring_expanding(pos - eX * stringwidth(forcetime, FALSE, '16 0 0'), forcetime, '32 32 0', '1 1 1', hud_alpha_fg, 0, a);
		}
		else
			a = 1;

		if(race_laptime && race_checkpoint != 255)
		{
			s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime));
			//drawstring(m - '16 0 0' * stringwidth(s, FALSE), s, '32 32 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
			drawstring(pos - '0.5 0 0' * stringwidth(s, FALSE, '32 32 0'), s, '32 32 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		}
	}
	else
	{
		if(race_mycheckpointtime)
		{
			a = bound(0, 2 - (time - race_mycheckpointtime), 1);
			s = MakeRaceString(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -!race_mycheckpointenemy, race_mycheckpointlapsdelta, race_mycheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			//drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
			drawcolorcodedstring(pos - '0 16 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		}
		if(race_othercheckpointtime && race_othercheckpointenemy != "")
		{
			a = bound(0, 2 - (time - race_othercheckpointtime), 1);
			s = MakeRaceString(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -!race_othercheckpointenemy, race_othercheckpointlapsdelta, race_othercheckpointenemy);
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			//drawcolorcodedstring(m - '0 0 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
			drawcolorcodedstring(pos - '0 0 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
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
				//drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
				drawcolorcodedstring(pos - '0 32 0' - '0.5 0 0' * stringwidth(s, TRUE, '16 16 0'), s, '16 16 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
			}
		}
	}

	drawfont = sbar_font;
}







// Notification area (#4)
// OH MY GOOODDDDDD this thing is colossal :/
// TODO
float vote_yescount;
float vote_nocount;
float vote_needed;
float vote_highlighted; // currently selected vote

float vote_active; // is there an active vote?
float vote_prev; // previous state of vote_active to check for a change
float vote_alpha;
float vote_change; // "time" when vote_active changed

/*
{
	if(spectatee_status && !intermission)
	{
		drawfont = sbar_bigfont;
		if(spectatee_status == -1)
			s = "^1Observing";
		else
			s = GetPlayerName(spectatee_status - 1);
		// spectated player name between HUD and chat area, aligned to the left
		pos_x = 0;
		pos_y = - 50 - sbar_fontsize_spec_y;
		s = textShortenToWidth(s, vid_conwidth/2.5, sbar_fontsize_spec, stringwidth_colors);
		drawcolorcodedstring(pos, s, sbar_fontsize_spec, hud_alpha_fg, DRAWFLAG_NORMAL);
		drawfont = sbar_font;

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

	if(vote_active != vote_prev) {
		vote_change = time;
		vote_prev = bound(0, vote_active, 1);
	}

	if(vote_active)
		vote_alpha = bound(0, (time - vote_change) * 2, 1);
	else
		vote_alpha = bound(0, 1 - (time - vote_change) * 2, 1);

	if(vote_alpha) {
		a = vote_alpha * bound(cvar_or("hud_vote_alreadyvoted_alpha", 0.75), 1 - vote_highlighted, 1);

		vector voteorigin = bottomright - '290 135 0';
		vector votesize = '280 70 0';
		drawpic(voteorigin, "gfx/hud/voteprogress_back", votesize, HUD_GetBgColor(), a * hud_alpha_bg, DRAWFLAG_NORMAL);

	        s = "A vote has been called for: ";
		drawstring(voteorigin + '0.5 0 0' * votesize_x + '0 0.1 0' * votesize_y - eX * stringwidth(s, FALSE, '6 0 0'), s, '12 12 0', '1 1 1', a * hud_alpha_fg, DRAWFLAG_NORMAL);
		s = textShortenToWidth(vote_called_vote, votesize_x * 0.96, '10 0 0', stringwidth_colors);
		drawcolorcodedstring(voteorigin + '0.52 0 0' * votesize_x + '0 0.3 0' * votesize_y - eX * stringwidth(s, FALSE, '5 0 0'), s, '10 10 0', a * hud_alpha_fg, DRAWFLAG_NORMAL);

		// print the yes/no counts
		s = strcat("Yes: ", ftos(vote_yescount));
		drawstring(voteorigin + '0 0.6 0' * votesize_y + '0.02 0 0' * votesize_x, s, '12 12 0', eY, a * hud_alpha_fg, DRAWFLAG_NORMAL);
		s = strcat("No: ", ftos(vote_nocount));
		drawstring(voteorigin + '0 0.6 0' * votesize_y + '0.98 0 0' * votesize_x - eX * stringwidth(s, FALSE, '12 0 0'), s, '12 12 0', eX, a * hud_alpha_fg, DRAWFLAG_NORMAL);

		// draw the progress bars
		drawsetcliparea(voteorigin_x, voteorigin_y, votesize_x * 0.5 * (vote_yescount/vote_needed), votesize_y);
		drawpic(voteorigin, "gfx/hud/voteprogress_prog", votesize, eY, a * hud_alpha_fg, DRAWFLAG_NORMAL);

		drawsetcliparea(voteorigin_x + votesize_x - votesize_x * 0.5 * (vote_nocount/vote_needed), voteorigin_y, votesize_x * 0.5, votesize_y);
		drawpic(voteorigin, "gfx/hud/voteprogress_prog", votesize, eX, a * hud_alpha_fg, DRAWFLAG_NORMAL);

		// draw the highlights
		if(vote_highlighted == 1) {
			drawsetcliparea(voteorigin_x, voteorigin_y, votesize_x * 0.5, votesize_y);
			drawpic(voteorigin, "gfx/hud/voteprogress_voted", votesize, eY, a * hud_alpha_fg, DRAWFLAG_NORMAL);
		}
		else if(vote_highlighted == 2) {
			drawsetcliparea(voteorigin_x + 0.5 * votesize_x, voteorigin_y, votesize_x * 0.5, votesize_y);
			drawpic(voteorigin, "gfx/hud/voteprogress_voted", votesize, eX, a * hud_alpha_fg, DRAWFLAG_NORMAL);
		}

		drawresetcliparea();
	}
	else if(!vote_active) {
		vote_highlighted = 0;
	}
}

*/
// Awards system
float race_status_time;
float race_status_prev;
string race_status_name_prev;
void HUD_DrawRaceStatus(vector pos)
{
	if (race_status != race_status_prev || race_status_name != race_status_name_prev) {
		race_status_time = time + 5;
		race_status_prev = race_status;
		if (race_status_name_prev)
			strunzone(race_status_name_prev);
		race_status_name_prev = strzone(race_status_name);
	}

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
		drawpic(pos, "gfx/hud/race/newfail", '80 80 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
	else if(race_status == 1) {
		drawpic(pos, "gfx/hud/race/newtime", '80 80 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '40 80 0' - eX * stringwidth(s, TRUE, '5 0 0'), s, '10 10 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		drawstring(pos + '40 20 0' - eX * stringwidth(rankname, TRUE, '7 0 0'), rankname, '14 14 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
	} else if(race_status == 2) {
		if(race_status_name == GetPlayerName(player_localentnum -1) || !race_myrank || race_myrank < rank)
			drawpic(pos, "gfx/hud/race/newrankgreen", '80 80 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		else
			drawpic(pos, "gfx/hud/race/newrankyellow", '80 80 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '40 80 0' - eX * stringwidth(s, TRUE, '5 0 0'), s, '10 10 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		drawstring(pos + '40 20 0' - eX * stringwidth(rankname, TRUE, '7 0 0'), rankname, '14 14 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
	} else if(race_status == 3) {
		drawpic(pos, "gfx/hud/race/newrecordserver", '80 80 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + '40 80 0' - eX * stringwidth(s, TRUE, '5 0 0'), s, '10 10 0', hud_alpha_fg * a, DRAWFLAG_NORMAL);
		drawstring(pos + '40 20 0' - eX * stringwidth(rankname, TRUE, '7 0 0'), rankname, '14 14 0', '1 1 1', hud_alpha_fg * a, DRAWFLAG_NORMAL);
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
}

// CTF HUD modicon section
float redflag_prevframe, blueflag_prevframe; // status during previous frame
float redflag_prevstatus, blueflag_prevstatus; // last remembered status
float redflag_statuschange_time, blueflag_statuschange_time; // time when the status changed

void CSQC_ctf_hudreset(void)
{
	redflag_prevstatus = blueflag_prevstatus = redflag_prevframe = blueflag_prevframe = redflag_statuschange_time = blueflag_statuschange_time = 0;
}

void CSQC_ctf_hud(void)
{
	vector bottomleft, redflag_pos, blueflag_pos, sz;
	float f; // every function should have that
	bottomleft_y = vid_conheight;
	bottomleft_z = 0;

	float redflag, blueflag; // current status
	float redflag_statuschange_elapsedtime, blueflag_statuschange_elapsedtime; // time since the status changed
	float stat_items;

	stat_items = getstati(STAT_ITEMS);
	redflag = (stat_items/IT_RED_FLAG_TAKEN) & 3;
	blueflag = (stat_items/IT_BLUE_FLAG_TAKEN) & 3;

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
		case 1: red_icon = "gfx/hud/sb_flag_red_taken"; break;
		case 2: red_icon = "gfx/hud/sb_flag_red_lost"; break;
		case 3: red_icon = "gfx/hud/sb_flag_red_carrying"; red_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon = "gfx/hud/sb_flag_red_shielded";
			else
				red_icon = string_null;
			break;
	}
	switch(redflag_prevstatus) {
		case 1: red_icon_prevstatus = "gfx/hud/sb_flag_red_taken"; break;
		case 2: red_icon_prevstatus = "gfx/hud/sb_flag_red_lost"; break;
		case 3: red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; red_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(redflag == 3)
				red_icon_prevstatus = "gfx/hud/sb_flag_red_carrying"; // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon_prevstatus = "gfx/hud/sb_flag_red_shielded";
			else
				red_icon_prevstatus = string_null;
			break;
	}

	string blue_icon, blue_icon_prevstatus;
	float blue_alpha, blue_alpha_prevstatus;
	blue_alpha = blue_alpha_prevstatus = 1;
	switch(blueflag) {
		case 1: blue_icon = "gfx/hud/sb_flag_blue_taken"; break;
		case 2: blue_icon = "gfx/hud/sb_flag_blue_lost"; break;
		case 3: blue_icon = "gfx/hud/sb_flag_blue_carrying"; blue_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon = "gfx/hud/sb_flag_blue_shielded";
			else
				blue_icon = string_null;
			break;
	}
	switch(blueflag_prevstatus) {
		case 1: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_taken"; break;
		case 2: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_lost"; break;
		case 3: blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; blue_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(blueflag == 3)
				blue_icon_prevstatus = "gfx/hud/sb_flag_blue_carrying"; // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon_prevstatus = "gfx/hud/sb_flag_blue_shielded";
			else
				blue_icon_prevstatus = string_null;
			break;
	}

	if (myteam == COLOR_TEAM1) { // always draw own flag on left
		redflag_pos = bottomleft - '-4 50 0';
		blueflag_pos = bottomleft - '-62 50 0';
	} else {
		blueflag_pos = bottomleft - '-4 50 0';
		redflag_pos = bottomleft - '-62 50 0';
	}

	sz = '52 52 0';

	f = bound(0, redflag_statuschange_elapsedtime*2, 1);
	if(red_icon_prevstatus && f < 1)
		drawpic_expanding(redflag_pos, red_icon_prevstatus, sz, '1 1 1', hud_alpha_fg * red_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(red_icon)
		drawpic(redflag_pos, red_icon, sz, '1 1 1', hud_alpha_fg * red_alpha * f, DRAWFLAG_NORMAL);

	f = bound(0, blueflag_statuschange_elapsedtime*2, 1);
	if(blue_icon_prevstatus && f < 1)
		drawpic_expanding(blueflag_pos, blue_icon_prevstatus, sz, '1 1 1', hud_alpha_fg * blue_alpha_prevstatus, DRAWFLAG_NORMAL, f);
	if(blue_icon)
		drawpic(blueflag_pos, blue_icon, sz, '1 1 1', hud_alpha_fg * blue_alpha * f, DRAWFLAG_NORMAL);
}

/*void HUD_Mod_Race (void) {
	if((scores_flags[ps_primary] & SFL_TIME) && !teamplay) { // race/cts record display on HUD
		pl = players.sort_next;
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
			HUD_DrawXNum(bottomright - '0 48 0' - '16 0 0' * TIME_DECIMALS, distmsec, -TIME_DECIMALS, 0, 16, distribution_color, 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
			HUD_DrawXNum(bottomright - '68 48 0' - '16 0 0' * TIME_DECIMALS, distsec, 4, minusplus, 16, distribution_color, 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(bottomright - '10 48 0' - '16 0 0' * TIME_DECIMALS, "gfx/hud/num_dot", '16 16 0', distribution_color, hud_alpha_fg, DRAWFLAG_ADDITIVE);
		}
		// race record display
		if (distribution <= 0 || distribution == score) // draw the highlight background behind the timer if we have the lead
			drawpic(bottomright - '0 32 0' - '32 0 0' * (4 + TIME_DECIMALS), "gfx/hud/sb_highlight_4", '0 28 0' + '32 0 0' * (4 + TIME_DECIMALS), '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);

		HUD_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0', racemsec, -TIME_DECIMALS, 0, 30, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		HUD_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0'  - '66 0 0', racesec, -2, 0, 30, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '18 0 0', "gfx/hud/num_dot", '30 30 0', '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE);

		HUD_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '132 0 0', racemin, -2, 0, 30, '1 1 1', 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '84 0 0', "gfx/hud/num_colon", '30 30 0', '1 1 1', hud_alpha_fg, DRAWFLAG_ADDITIVE);
	}
}*/

// Keyhunt HUD modicon section
float kh_runheretime;

void CSQC_kh_hudreset(void)
{
	kh_runheretime = 0;
}

void CSQC_kh_hud(void)
{
	float kh_keys;
	float keyteam;
	float a, aa;
	vector p, pa, kh_size, kh_asize;

	p_x = 6;
	p_y = vid_conheight - 34 - 3;
	p_z = 0;

	kh_keys = getstati(STAT_KH_KEYS);

	kh_size = '19 34 0';
	kh_asize = '19 10 0';
	pa = p + '0 -10 0';

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
		a = a * hud_alpha_fg;
		aa = aa * hud_alpha_fg;
		if(a > 0)
		{
			switch(keyteam)
			{
				case COLOR_TEAM1:
					drawpic (pa, "gfx/hud/sb_kh_redarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM2:
					drawpic (pa, "gfx/hud/sb_kh_bluearrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM3:
					drawpic (pa, "gfx/hud/sb_kh_yellowarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM4:
					drawpic (pa, "gfx/hud/sb_kh_pinkarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				default:
					break;
			}
			switch(i) // YAY! switch(i) inside a for loop for i. DailyWTF, here we come!
			{
				case 0:
					drawpic (p, "gfx/hud/sb_kh_red", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 1:
					drawpic (p, "gfx/hud/sb_kh_blue", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 2:
					drawpic (p, "gfx/hud/sb_kh_yellow", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 3:
					drawpic (p, "gfx/hud/sb_kh_pink", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
			}
		}
		p_x += 24;
		pa_x += 24;
	}
}

// Nexball HUD modicon section
#define NBPB_SIZE '96 38 0'
#define NBPB_BT 2                   //thickness
#define NBPB_BRGB '1 1 1'
#define NBPB_BALPH 1                //alpha
#define NBPB_BFLAG DRAWFLAG_NORMAL
#define NBPB_IALPH 0.4
#define NBPB_IFLAG DRAWFLAG_NORMAL
#define NBPB_IRGB '0.7 0.1 0'

void CSQC_nb_hud(void)
{
	float stat_items, nb_pb_starttime, dt, p;
	vector pos;

	stat_items = getstati(STAT_ITEMS);
	nb_pb_starttime = getstatf(STAT_NB_METERSTART);

	pos_x = 4;
	pos_y = vid_conheight - 42;
	pos_z = 0;

	//Manage the progress bar if any
	if (nb_pb_starttime > 0)
	{
		vector s;
		dt = mod(time - nb_pb_starttime, nb_pb_period);
		// one period of positive triangle
		p = 2 * dt / nb_pb_period;
		if (p > 1)
			p = 2 - p;

		s = NBPB_SIZE;
		//Draw the filling
		drawfill(pos, p * s_x * eX + s_y * eY, NBPB_IRGB, NBPB_IALPH, NBPB_IFLAG);

		//Draw the box
		s = NBPB_SIZE;
		drawline(NBPB_BT, pos    , pos + eX * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos    , pos + eY * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + eX * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + eY * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
	}

	pos_x += 12; //horizontal margin to the picture
	pos_y += 2; //vertical margin to the picture

	if (stat_items & IT_KEY1)
		drawpic(pos, "gfx/hud/sb_nexball_carrying", '80 34 0', '1 1 1', 1, DRAWFLAG_NORMAL);
}

// Race/CTS HUD modicon section
float crecordtime_prev; // last remembered crecordtime
float crecordtime_change_time; // time when crecordtime last changed
float srecordtime_prev; // last remembered srecordtime
float srecordtime_change_time; // time when srecordtime last changed
void CSQC_race_hud(void)
{
	entity me;
	me = playerslots[player_localentnum - 1];
	float t, score;
	float f; // yet another function has this
	score = me.(scores[ps_primary]);

	if not((scores_flags[ps_primary] & SFL_TIME) && !teamplay) // race/cts record display on HUD
		return; // no records in the actual race

	drawfont = sbar_bigfont;
	vector pos;
	pos_x = 2;
	pos_y = vid_conheight - 48;

	// clientside personal record
	string rr;
	if(gametype == GAME_CTS)
		rr = CTS_RECORD;
	else
		rr = RACE_RECORD;
	t = stof(db_get(ClientProgsDB, strcat(shortmapname, rr, "time")));

	if(score && score < t || !t)
		db_put(ClientProgsDB, strcat(shortmapname, rr, "time"), ftos(score));

	if(t != crecordtime_prev) {
		crecordtime_prev = t;
		crecordtime_change_time = time;
	}
	f = time - crecordtime_change_time;

	if (f > 1) {
		drawstring(pos, "Personal best ", '10 10 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		drawstring(pos + '0 10 0', TIME_ENCODED_TOSTRING(t),'14 14 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	} else {
		drawstring(pos, "Personal best ", '10 10 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		drawstring(pos + '0 10 0', TIME_ENCODED_TOSTRING(t),'14 14 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		drawstring_expanding(pos, "Personal best ", '10 10 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL, f);
		drawstring_expanding(pos + '0 10 0', TIME_ENCODED_TOSTRING(t),'14 14 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL, f);
	}

	// server record
	pos_y += 26;
	t = race_server_record;
	if(t != srecordtime_prev) {
		srecordtime_prev = t;
		srecordtime_change_time = time;
	}
	f = time - srecordtime_change_time;

	if (f > 1) {
		drawstring(pos, "Server best ", '10 10 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		drawstring(pos + '0 10 0', TIME_ENCODED_TOSTRING(t),'14 14 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	} else {
		drawstring(pos, "Server best ", '10 10 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		drawstring(pos + '0 10 0', TIME_ENCODED_TOSTRING(t),'14 14 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
		drawstring_expanding(pos, "Server best ", '10 10 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL, f);
		drawstring_expanding(pos + '0 10 0', TIME_ENCODED_TOSTRING(t),'14 14 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL, f);
	}
	drawfont = sbar_font;
}

// Timer (#5)
//
void HUD_Timer()
{
	float marigin;

	vector pos, mySize, color;
	marigin = HUD_Panel_GetMarigin(5);
	pos = HUD_Panel_GetPos(5);
	mySize = HUD_Panel_GetSize(5);
	color = HUD_Panel_GetColor(5);

	if(HUD_Panel_GetBgActive(5))
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", mySize + '1 1 0' * 2 * marigin, color, hud_alpha_bg, '1 1 0' * (marigin/MARIGIN_MULTIPLIER));

	float timelimit, elapsedTime, minutes, seconds, timeleft, minutesLeft, secondsLeft;

	timelimit = getstatf(STAT_TIMELIMIT);

	HUD_DrawRaceStatus(pos + '0 30 0');

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

	if (cvar("hud_increment_maptime") || timelimit == 0 || warmup_stage) {
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

	if(minutesLeft >= 1 || cvar("hud_increment_maptime") || timelimit == 0 || warmup_stage) {
		HUD_DrawXNum(pos, minutes, 3, 0, mySize_y, timer_color, 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(pos + eX * 0.5 * mySize_x, "gfx/hud/num_colon", eX * mySize_y + eY * mySize_y, timer_color, hud_alpha_fg, DRAWFLAG_NORMAL);
	}
	HUD_DrawXNum(pos + eX * 0.6 * mySize_x, seconds, -2, 0, mySize_y, timer_color, 0, 0, hud_alpha_fg, DRAWFLAG_NORMAL);
}

// Radar (#6)
//

void() teamradar_view =
{
	float marigin;

	vector pos, mySize, color;
	marigin = HUD_Panel_GetMarigin(6);
	pos = HUD_Panel_GetPos(6);
	mySize = HUD_Panel_GetSize(6);
	color = HUD_Panel_GetColor(6);

	if(HUD_Panel_GetBgActive(6))
		draw_BorderPicture(pos - '1 1 0' * marigin, "gfx/hud/border", mySize + '1 1 0' * 2 * marigin, color, hud_alpha_bg, '1 1 0' * (marigin/MARIGIN_MULTIPLIER));

	local float color1, color2; // color already declared as a global in sbar.qc
	local vector rgb;
	local entity tm;
	float scale2d, normalsize, bigsize;
	float f;

	teamradar_origin2d = pos + 0.5 * mySize; // TODO: stupid compat, should be removed
	teamradar_size2d = mySize;

	if(minimapname == "" && !ons_showmap)
		return;

	teamradar_loadcvars();

	switch(cl_teamradar_zoommode)
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

	switch(cl_teamradar_rotation)
	{
		case 0:
			teamradar_angle = view_angles_y - 90;
			break;
		default:
			teamradar_angle = 90 * cl_teamradar_rotation;
			break;
	}

	scale2d = vlen_maxnorm2d(mi_picmax - mi_picmin);
	teamradar_size2d = mySize;

	teamradar_extraclip_mins = teamradar_extraclip_maxs = '0 0 0';
	if(pos == eX * vid_conwidth)
	{
		if(cl_teamradar_nohudhack < 2)
			pos_y += 25;
		if(cl_teamradar_nohudhack < 1)
			teamradar_extraclip_mins_y -= 25;
	}
	else if(pos == eY * vid_conheight || pos == eX * vid_conwidth + eY * vid_conheight)
	{
		if(cl_teamradar_nohudhack < 2)
			pos_y -= 50;
		//if(cl_teamradar_nohudhack < 1)
			//teamradar_extraclip_size_y += 50; // don't, the HUD looks nice
	}

	// pixels per world qu to match the teamradar_size2d_x range in the longest dimension
	if(cl_teamradar_rotation == 0)
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

	normalsize = vlen_maxnorm2d(teamradar_size2d) * scale2d / cl_teamradar_scale;
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
		pos_x + mySize_x,
		pos_y + mySize_y
	);

	draw_teamradar_background(cl_teamradar_background_alpha, cl_teamradar_foreground_alpha);

	if(ons_showmap)
	{
		drawresetcliparea();

		vector frame_origin, frame_size;
		frame_origin = frame_size = '0 0 0';

		frame_origin_x = pos_x - teamradar_size2d_x * 0.55859375; // matches the picture
		frame_origin_y = pos_y - teamradar_size2d_y * 0.55859375; // matches the picture
		frame_size_x = pos_x * 1.1171875; // matches the picture
		frame_size_y = pos_y * 1.1171875; // matches the picture
		drawpic(frame_origin, "gfx/ons-frame.tga", frame_size, '1 1 1', hud_alpha_fg, 0);
		drawpic(frame_origin, "gfx/ons-frame-team.tga", frame_size, rgb, hud_alpha_fg, 0);

		drawsetcliparea(
			pos_x - teamradar_size2d_x * 0.5,
			pos_y - teamradar_size2d_y * 0.5,
			teamradar_size2d_x,
			teamradar_size2d_y
		);
	}

	for(tm = world; (tm = find(tm, classname, "radarlink")); )
		draw_teamradar_link(tm.origin, tm.velocity, tm.team);
	for(tm = world; (tm = findflags(tm, teamradar_icon, 0xFFFFFF)); )
		draw_teamradar_icon(tm.origin, tm.teamradar_icon, tm, tm.teamradar_color, hud_alpha_fg);
	for(tm = world; (tm = find(tm, classname, "entcs_receiver")); )
	{
		color2 = GetPlayerColor(tm.sv_entnum);
		//if(color == COLOR_SPECTATOR || color == color2)
			draw_teamradar_player(tm.origin, tm.angles, GetTeamRGB(color2));
	}
	draw_teamradar_player(view_origin, view_angles, '1 1 1');

	drawresetcliparea();
};

/*
==================
Main HUD system
==================
*/

void HUD_DrawPressedKeys(void)
{
	vector pos, bgsize;
	float pressedkeys;

	pos = stov(cvar_string("cl_showpressedkeys_position"));

	bgsize = '126 75 0';

	pos = eX * (vid_conwidth - bgsize_x) * pos_x
	    + eY * (vid_conheight - bgsize_y) * pos_y;
	pos -= '-15 -6 0'; // adjust to the origin of these numbers

	pressedkeys = getstatf(STAT_PRESSED_KEYS);
	drawpic(pos + '-15   -6   0', "gfx/hud/keys/key_bg.tga",           bgsize, '1 1 1', 0.1 * hud_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 83.5  9   0', ((pressedkeys & KEY_CROUCH) ? "gfx/hud/keys/key_crouch_inv.tga" : "gfx/hud/keys/key_crouch.tga"), ' 24 24 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   -1.5 0', ((pressedkeys & KEY_FORWARD) ? "gfx/hud/keys/key_forward_inv.tga" : "gfx/hud/keys/key_forward.tga"),  ' 32 32 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + '-11.5  9   0', ((pressedkeys & KEY_JUMP) ? "gfx/hud/keys/key_jump_inv.tga" : "gfx/hud/keys/key_jump.tga"),     ' 24 24 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' -1   32   0', ((pressedkeys & KEY_LEFT) ? "gfx/hud/keys/key_left_inv.tga" : "gfx/hud/keys/key_left.tga"),     ' 32 32 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   32   0', ((pressedkeys & KEY_BACKWARD) ? "gfx/hud/keys/key_backward_inv.tga" : "gfx/hud/keys/key_backward.tga"), ' 32 32 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 65   32   0', ((pressedkeys & KEY_RIGHT) ? "gfx/hud/keys/key_right_inv.tga" : "gfx/hud/keys/key_right.tga"),    ' 32 32 0', '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
}

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

	drawfont = sbar_bigfont;
	drawstringcenter(eX + pos * eY, speed, numsize, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);

	if (cvar("cl_showspeed_z") == 1) {
		zspeed = strcat(ftos(fabs(floor( pmove_vel_z * conversion_factor + 0.5 ))), unit);
		drawstringcenter(eX + pos * eY + numsize_y * eY, zspeed, numsize * 0.5, '1 1 1', hud_alpha_fg, DRAWFLAG_NORMAL);
	}

	drawfont = sbar_font;
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
		drawpic(pos, "gfx/hud/accelerometer_gradient", acceleration * scale * '40 0 0' + sz * eY, rgb, alpha * hud_alpha_fg, DRAWFLAG_NORMAL);
	else if (acceleration < 0)
		drawpic(pos + acceleration * scale * '40 0 0', "gfx/hud/accelerometer_gradient", -acceleration * scale * '40 0 0' + sz * eY, rgb, alpha * hud_alpha_fg, DRAWFLAG_NORMAL);
}

void HUD_Reset (void)
{
	// reset gametype specific icons
	if(gametype == GAME_KEYHUNT)
		CSQC_kh_hudreset();
	else if(gametype == GAME_CTF)
		CSQC_ctf_hudreset();
}

void HUD_Main (void)
{
	hud_alpha_bg = cvar_or("hud_alpha_bg", 0.8) * (1 - cvar("_menu_alpha"));
	hud_border_thickness = bound(0, cvar("hud_border_thickness"), 5);
	hud_accuracy_border_thickness = bound(0, cvar_or("hud_accuracy_border_thickness", 1), 5);
	hud_color_bg_team = cvar("hud_color_bg_team");

	sbar_fontsize = Sbar_GetFontsize("sbar_fontsize");
	sbar_fontsize_spec = Sbar_GetFontsize("sbar_fontsize_spec");

	if(cvar_or("hud_inventory", 1))
		HUD_Inventory();
	if(cvar_or("hud_weaponicons", 1))
		HUD_WeaponIcons();
	if(cvar_or("hud_timer", 1))
		HUD_Timer();
	if(cvar_or("hud_powerups", 1))
		HUD_Powerups();
	if(cvar_or("hud_health", 1))
		HUD_HealthArmor();
	if(cvar_or("hud_notify", 1))
		HUD_Score();
	if((gametype == GAME_RACE || gametype == GAME_CTS) && cvar_or("hud_racetimer", 1))
		HUD_RaceTimer();
	if(cvar("hud_pressedkeys"))
		HUD_DrawPressedKeys();
	if(cvar("hud_speed"))
		HUD_ShowSpeed();
	if(cvar("hud_acceleration"))
		HUD_ShowAcceleration();

	//Sbar_UpdatePlayerTeams();
	// move this stuff to View.qc
	if (intermission == 2) // map voting screen
	{
		if(sb_showaccuracy && spectatee_status != -1) {
			//HUD_DrawAccuracyStats();
			//HUD_Score();
			//HUD_Timer();
		}
		else if(sb_showscores) {
			//HUD_DrawScoreboard();
                        //HUD_Score();
                        //HUD_Timer();
                }
		else
			//HUD_FinaleOverlay();

		HUD_Reset();
	}
	else if (sb_showscores_force || getstati(STAT_HEALTH) <= 0 || intermission == 1)
	{
		//if(sb_showaccuracy && spectatee_status != -1)
			//HUD_DrawAccuracyStats();
		//else
			//HUD_DrawScoreboard();
		//HUD_Score();
		//HUD_Timer();

		//HUD_Reset();
	}
	else
	{
		//if(sb_showaccuracy && spectatee_status != -1)
			//HUD_DrawAccuracyStats();
		//else
		//	HUD_DrawScoreboard();

		// draw scores and timer
		//HUD_Score();
		//HUD_Timer();

		// draw gametype specific icons
		if(gametype == GAME_KEYHUNT)
			CSQC_kh_hud();
		else if(gametype == GAME_CTF)
			CSQC_ctf_hud();
		else if(gametype == GAME_NEXBALL)
			CSQC_nb_hud();
		else if(gametype == GAME_CTS || gametype == GAME_RACE)
			CSQC_race_hud();
	}
	return;
}
