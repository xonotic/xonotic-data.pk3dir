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
	float blinkingamt;
	vector color;
	if(x >= maxvalue) {
		color_x = sin(2*M_PI*time);
		color_y = 1;
		color_z = sin(2*M_PI*time);
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

	blinkingamt = (1 - x/maxvalue/0.25);
	if(blinkingamt > 0)
	{
		color_x = color_x - color_x * blinkingamt * sin(2*M_PI*time);
		color_y = color_y - color_y * blinkingamt * sin(2*M_PI*time);
		color_z = color_z - color_z * blinkingamt * sin(2*M_PI*time);
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

void drawstringright(vector position, string text, vector scale, vector rgb, float theAlpha, float flag)
{
	position_x -= 2 / 3 * strlen(text) * scale_x;
	drawstring(position, text, scale, rgb, theAlpha, flag);
}

void drawstringcenter(vector position, string text, vector scale, vector rgb, float theAlpha, float flag)
{
	position_x = 0.5 * (vid_conwidth - 0.6025 * strlen(text) * scale_x);
	drawstring(position, text, scale, rgb, theAlpha, flag);
}

// return the string of the given race place
string race_PlaceName(float pos) {
	if(pos == 1)
		return _("1st");
	else if(pos == 2)
		return _("2nd");
	else if(pos == 3)
		return _("3rd");
	else
		return sprintf(_("%dth"), pos);
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
			lapstr = sprintf(_(" (-%dL)"), lapdelta);
			col = "^2";
		}
		else if(lapdelta < 0)
		{
			lapstr = sprintf(_(" (+%dL)"), -lapdelta);
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
		cpname = _("Start line");
	else if(cp == 255)
		cpname = _("Finish line");
	else if(cp)
		cpname = sprintf(_("Intermediate %d"), cp);
	else
		cpname = _("Finish line");

	if(histime < 0)
		return strcat(col, cpname);
	else if(hisname == "")
		return strcat(col, sprintf(_("%s (%s)"), cpname, timestr));
	else
		return strcat(col, sprintf(_("%s (%s %s)"), cpname, timestr, strcat(hisname, col, lapstr)));
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

// draw the background/borders
#define HUD_Panel_DrawBg(theAlpha)\
if(panel_bg != "0")\
	draw_BorderPicture(panel_pos - '1 1 0' * panel_bg_border, panel_bg, panel_size + '1 1 0' * 2 * panel_bg_border, panel_bg_color, panel_bg_alpha * theAlpha, '1 1 0' * (panel_bg_border/BORDER_MULTIPLIER))

//basically the same code of draw_ButtonPicture and draw_VertButtonPicture for the menu
void HUD_Panel_DrawProgressBar(vector theOrigin, vector theSize, string pic, float length_ratio, float vertical, float baralign, vector theColor, float theAlpha, float drawflag)
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
			theOrigin_y += (1 - length_ratio) * theSize_y;
        else if (baralign == 2) // center align
            theOrigin_y += 0.5 * (1 - length_ratio) * theSize_y;
        else if (baralign == 3) // center align, positive values down, negative up
		{
			theSize_y *= 0.5;
			if (length_ratio > 0)
				theOrigin_y += theSize_y;
			else
			{
				theOrigin_y += (1 + length_ratio) * theSize_y;
				length_ratio = -length_ratio;
			}
		}
		theSize_y *= length_ratio;

		vector bH;
		width = eX * theSize_x;
		height = eY * theSize_y;
		if(theSize_y <= theSize_x * 2)
		{
			// button not high enough
			// draw just upper and lower part then
			square = eY * theSize_y * 0.5;
			bH = eY * (0.25 * theSize_y / (theSize_x * 2));
			drawsubpic(theOrigin,          square + width, pic, '0 0 0', eX + bH, theColor, theAlpha, drawflag);
			drawsubpic(theOrigin + square, square + width, pic, eY - bH, eX + bH, theColor, theAlpha, drawflag);
		}
		else
		{
			square = eY * theSize_x;
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
			theOrigin_x += (1 - length_ratio) * theSize_x;
        else if (baralign == 2) // center align
            theOrigin_x += 0.5 * (1 - length_ratio) * theSize_x;
        else if (baralign == 3) // center align, positive values on the right, negative on the left
		{
			theSize_x *= 0.5;
			if (length_ratio > 0)
				theOrigin_x += theSize_x;
			else
			{
				theOrigin_x += (1 + length_ratio) * theSize_x;
				length_ratio = -length_ratio;
			}
		}
		theSize_x *= length_ratio;

		vector bW;
		width = eX * theSize_x;
		height = eY * theSize_y;
		if(theSize_x <= theSize_y * 2)
		{
			// button not wide enough
			// draw just left and right part then
			square = eX * theSize_x * 0.5;
			bW = eX * (0.25 * theSize_x / (theSize_y * 2));
			drawsubpic(theOrigin,          square + height, pic, '0 0 0', eY + bW, theColor, theAlpha, drawflag);
			drawsubpic(theOrigin + square, square + height, pic, eX - bW, eY + bW, theColor, theAlpha, drawflag);
		}
		else
		{
			square = eX * theSize_y;
			drawsubpic(theOrigin,                  height  +     square, pic, '0    0 0', '0.25 1 0', theColor, theAlpha, drawflag);
			drawsubpic(theOrigin +         square, theSize - 2 * square, pic, '0.25 0 0', '0.5  1 0', theColor, theAlpha, drawflag);
			drawsubpic(theOrigin + width - square, height  +     square, pic, '0.75 0 0', '0.25 1 0', theColor, theAlpha, drawflag);
		}
	}
}

void HUD_Panel_DrawHighlight(vector pos, vector mySize, vector color, float theAlpha, float drawflag)
{
	if(!theAlpha)
		return;

	string pic;
	pic = strcat(hud_skin_path, "/num_leading");
	if(precache_pic(pic) == "") {
		pic = "gfx/hud/default/num_leading";
	}

	drawsubpic(pos, eX * min(mySize_x * 0.5, mySize_y) + eY * mySize_y, pic, '0 0 0', '0.25 1 0', color, theAlpha, drawflag);
	if(mySize_x/mySize_y > 2)
		drawsubpic(pos + eX * mySize_y, eX * (mySize_x - 2 * mySize_y) + eY * mySize_y, pic, '0.25 0 0', '0.5 1 0', color, theAlpha, drawflag);
	drawsubpic(pos + eX * mySize_x - eX * min(mySize_x * 0.5, mySize_y), eX * min(mySize_x * 0.5, mySize_y) + eY * mySize_y, pic, '0.75 0 0', '0.25 1 0', color, theAlpha, drawflag);
}

// Weapon icons (#0)
//
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
		case WEP_RIFLE: return 1;
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
	// declarations
	float weapons_stat = getstati(STAT_WEAPONS);
	float i, f, a, j, factor;
	float screen_ar, center_x, center_y;
	float weapon_count, weapon_id, weapon_alpha;
	float row, column, rows, columns;
	float aspect = autocvar_hud_panel_weapons_aspect;

	float show_accuracy, panel_weapon_accuracy;

	float timeout = autocvar_hud_panel_weapons_timeout;
	float timein_effect_length = (autocvar_hud_panel_weapons_timeout_effect ? 0.375 : 0);
	float timeout_effect_length = (autocvar_hud_panel_weapons_timeout_effect ? 0.75 : 0);

	float ammo_type, ammo_full, ammo_alpha;
	float barsize_x, barsize_y, baroffset_x, baroffset_y;

	float when = autocvar_hud_panel_weapons_complainbubble_time;
	float fadetime = autocvar_hud_panel_weapons_complainbubble_fadetime;

	vector weapon_pos, weapon_size;
	local noref vector old_panel_size; // fteqcc sucks
	vector color, ammo_color;

	// check to see if we want to continue
	if(hud != HUD_NORMAL) { return; }

	if(!autocvar__hud_configure)
	{
		if((!autocvar_hud_panel_weapons) || (spectatee_status == -1))
			return;
		else if(timeout && time >= weapontime + timeout + timeout_effect_length)
		{
			weaponprevtime = time;
			return;
		}
	}
	else
		hud_configure_active_panel = HUD_PANEL_WEAPONS;

	// update generic hud functions
	HUD_Panel_UpdateCvars(weapons);
	HUD_Panel_ApplyFadeAlpha();

	// calculate fading effect to weapon images for when the panel is idle
	if(autocvar_hud_panel_weapons_fade)
	{
		weapon_alpha = 3.2 - 2 * (time - weapontime);
		weapon_alpha = bound(0.7, weapon_alpha, 1) * panel_fg_alpha;
	}
	else
		weapon_alpha = panel_fg_alpha;

	// figure out weapon order (how the weapons are sorted) // TODO make this configurable
	if(weaponorder_bypriority != autocvar_cl_weaponpriority || !weaponorder[0])
	{
		float weapon_cnt;
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
		for(i = weapon_cnt; i < WEP_MAXCOUNT; ++i)
			weaponorder[i] = world;
		heapsort(weapon_cnt, weaponorder_swap, weaponorder_cmp, world);

		weaponorder_cmp_str = string_null;
	}

	// determine which weapons are going to be shown
	if (autocvar_hud_panel_weapons_onlyowned)
	{
		if(autocvar__hud_configure)
		{
			if (weapons_stat == 0) // create some fake weapons anyway
				for(i = 0; i <= WEP_LAST-WEP_FIRST; i += floor((WEP_LAST-WEP_FIRST)/5))
					weapons_stat |= power2of(i);

			if(menu_enabled != 2)
				HUD_Panel_DrawBg(1); // also draw the bg of the entire panel
		}

		// do we own this weapon?
		for(i = 0; i <= WEP_LAST-WEP_FIRST; ++i)
			if(weapons_stat & weaponorder[i].weapons)
				++weapon_count;

		// add it anyway if weaponcomplain is shown
		if((!autocvar__hud_configure) 
			&& (autocvar_hud_panel_weapons_complainbubble 
				&& time - complain_weapon_time < when + fadetime))
					++weapon_count;

		// might as well commit suicide now, no reason to live ;)
		if (weapon_count == 0) { return; }

		// reduce size of the panel
		if (panel_size_y > panel_size_x)
		{
			old_panel_size_y = panel_size_y;
			panel_size_y *= weapon_count / WEP_COUNT;
			panel_pos_y += (old_panel_size_y - panel_size_y) / 2;
		}
		else
		{
			old_panel_size_x = panel_size_x;
			panel_size_x *= weapon_count / WEP_COUNT;
			panel_pos_x += (old_panel_size_x - panel_size_x) / 2;
		}
	}
	else
		weapon_count = WEP_COUNT;

	// animation for fading in/out the panel respectively when not in use
	if(!autocvar__hud_configure)
	{
		if (timeout && time >= weapontime + timeout) // apply timeout effect if needed
		{
			f = (time - (weapontime + timeout)) / timeout_effect_length;
			if (autocvar_hud_panel_weapons_timeout_effect == 1 || autocvar_hud_panel_weapons_timeout_effect == 3)
			{
				panel_bg_alpha *= (1 - f);
				panel_fg_alpha *= (1 - f);
			}
			if (autocvar_hud_panel_weapons_timeout_effect == 2 || autocvar_hud_panel_weapons_timeout_effect == 3)
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
		else if (timeout && time < weaponprevtime + timein_effect_length) // apply timein effect if needed
		{
			f = (time - weaponprevtime) / timein_effect_length;
			if (autocvar_hud_panel_weapons_timeout_effect == 1 || autocvar_hud_panel_weapons_timeout_effect == 3)
			{
				panel_bg_alpha *= (f);
				panel_fg_alpha *= (f);
			}
			if (autocvar_hud_panel_weapons_timeout_effect == 2 || autocvar_hud_panel_weapons_timeout_effect == 3)
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
	}

	// draw the background, then change the virtual size of it to better fit other items inside
	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	// after the sizing and animations are done, update the other values
	rows = panel_size_y/panel_size_x;
	rows = bound(1, floor((sqrt(4 * aspect * rows * weapon_count + rows * rows) + rows + 0.5) / 2), weapon_count);
	columns = ceil(weapon_count/rows);
	weapon_size = eX * panel_size_x*(1/columns) + eY * panel_size_y*(1/rows);

	// calculate position/size for visual bar displaying ammount of ammo status
	if (autocvar_hud_panel_weapons_ammo)
	{
		ammo_color = stov(autocvar_hud_panel_weapons_ammo_color);
		ammo_alpha = panel_fg_alpha * autocvar_hud_panel_weapons_ammo_alpha;

		if(weapon_size_x/weapon_size_y > aspect)
		{
			barsize_x = aspect * weapon_size_y;
			barsize_y = weapon_size_y;
			baroffset_x = (weapon_size_x - barsize_x) / 2;
		}
		else
		{
			barsize_y = 1/aspect * weapon_size_x;
			barsize_x = weapon_size_x;
			baroffset_y = (weapon_size_y - barsize_y) / 2;
		}
	}

	if(autocvar_hud_panel_weapons_accuracy && acc_levels)
	{
		show_accuracy = true;
		if (acc_col_x[0] == -1)
			for (i = 0; i < acc_levels; ++i)
				acc_col[i] = stov(cvar_string(strcat("accuracy_color", ftos(i))));
	}

	for(i = 0; i <= WEP_LAST-WEP_FIRST; ++i)
	{
		// retrieve information about the current weapon to be drawn
		self = weaponorder[i];
		weapon_id = self.impulse;

		// skip if this weapon doesn't exist
		if (!self || self.impulse < 0) { continue; }

		// skip this weapon if we don't own it (and onlyowned is enabled)-- or if weapons_complainbubble is showing for this weapon
		if (autocvar_hud_panel_weapons_onlyowned
			&& !((weapons_stat & self.weapons) 
			|| (self.weapon == complain_weapon 
				&& time - complain_weapon_time < when + fadetime 
				&& autocvar_hud_panel_weapons_complainbubble)))
					continue;

		// figure out the drawing position of weapon
		weapon_pos = (panel_pos 
			+ eX * column * weapon_size_x 
			+ eY * row * weapon_size_y);

		// draw background behind currently selected weapon
		if(self.weapon == switchweapon)
			drawpic_aspect_skin(weapon_pos, "weapon_current_bg", weapon_size, '1 1 1', weapon_alpha, DRAWFLAG_NORMAL);

		// draw the weapon accuracy
		if(show_accuracy)
		{
			panel_weapon_accuracy = weapon_accuracy[self.weapon-WEP_FIRST];
			if(panel_weapon_accuracy >= 0)
			{
				// find the max level lower than weapon_accuracy
				j = acc_levels-1;
				while ( j && panel_weapon_accuracy < acc_lev[j] )
					--j;

				// inject color j+1 in color j, how much depending on how much weapon_accuracy is higher than level j
				factor = (panel_weapon_accuracy - acc_lev[j]) / (acc_lev[j+1] - acc_lev[j]);
				color = acc_col[j];
				color = color + factor * (acc_col[j+1] - color);

				drawpic_aspect_skin(weapon_pos, "weapon_accuracy", weapon_size, color, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
		}

		// drawing all the weapon items
		if(weapons_stat & self.weapons)
		{
			// draw the weapon image
			drawpic_aspect_skin(weapon_pos, strcat("weapon", self.netname), weapon_size, '1 1 1', weapon_alpha, DRAWFLAG_NORMAL);

			// draw weapon label string
			switch(autocvar_hud_panel_weapons_label)
			{
				case 1: // weapon number
					drawstring(weapon_pos, ftos(weapon_id), '1 1 0' * 0.5 * weapon_size_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
					break;

				case 2: // bind
					drawstring(weapon_pos, getcommandkey(ftos(weapon_id), strcat("impulse ", ftos(weapon_id))), '1 1 0' * 0.5 * weapon_size_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
					break;

				case 3: // weapon name
					drawstring(weapon_pos, self.netname, '1 1 0' * 0.5 * weapon_size_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
					break;

				default: // nothing
					break;
			}

			// draw ammo status bar
			if(autocvar_hud_panel_weapons_ammo && self.weapon != WEP_TUBA && self.weapon != WEP_LASER && self.weapon != WEP_PORTO)
			{
				a = 0;
				ammo_type = GetAmmoTypeForWep(self.weapon);
				if(ammo_type != -1)
					a = getstati(GetAmmoStat(ammo_type)); // how much ammo do we have?

				if(a > 0)
				{
					switch(ammo_type) {
						case 0: ammo_full = autocvar_hud_panel_weapons_ammo_full_shells; break;
						case 1: ammo_full = autocvar_hud_panel_weapons_ammo_full_nails; break;
						case 2: ammo_full = autocvar_hud_panel_weapons_ammo_full_rockets; break;
						case 3: ammo_full = autocvar_hud_panel_weapons_ammo_full_cells; break;
						case 4: ammo_full = autocvar_hud_panel_weapons_ammo_full_fuel; break;
						default: ammo_full = 60;
					}

					drawsetcliparea(
						weapon_pos_x + baroffset_x,
						weapon_pos_y + baroffset_y,
						barsize_x * bound(0, a/ammo_full, 1),
						barsize_y);
					drawpic_aspect_skin(weapon_pos, "weapon_ammo", weapon_size, ammo_color, ammo_alpha, DRAWFLAG_NORMAL);
					drawresetcliparea();
				}
			}
		}
		else // draw a "ghost weapon icon" if you don't have the weapon
		{
			drawpic_aspect_skin(weapon_pos, strcat("weapon", self.netname), weapon_size, '0 0 0', panel_fg_alpha * 0.5, DRAWFLAG_NORMAL);
		}

		// draw the complain message
		if(time - complain_weapon_time < when + fadetime && self.weapon == complain_weapon && autocvar_hud_panel_weapons_complainbubble)
		{
			if(fadetime)
				a = ((complain_weapon_time + when > time) ? 1 : bound(0, (complain_weapon_time + when + fadetime - time) / fadetime, 1));
			else
				a = ((complain_weapon_time + when > time) ? 1 : 0);


			string s;
			if(complain_weapon_type == 0) {
				s = _("Out of ammo");
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_outofammo);
			}
			else if(complain_weapon_type == 1) {
				s = _("Don't have");
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_donthave);
			}
			else {
				s = _("Unavailable");
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_unavailable);
			}
			float padding = autocvar_hud_panel_weapons_complainbubble_padding;
			drawpic_aspect_skin(weapon_pos + '1 1 0' * padding, "weapon_complainbubble", weapon_size - '2 2 0' * padding, color, a * panel_fg_alpha, DRAWFLAG_NORMAL);
			drawstring_aspect(weapon_pos + '1 1 0' * padding, s, weapon_size - '2 2 0' * padding, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		// continue with new position for the next weapon
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

void DrawAmmoItem(vector myPos, vector mySize, float itemcode, float currently_selected, float infinite_ammo)
{
	float a;
	if(autocvar__hud_configure)
	{
		currently_selected = (itemcode == 2); //rockets always selected
		a = 31 + mod(itemcode*93, 128);
	}
	else
		a = getstati(GetAmmoStat(itemcode)); // how much ammo do we have of type itemcode?

	vector color;
	if(infinite_ammo)
		color = '0 0.5 0.75';
	else if(a < 10)
		color = '0.7 0 0';
	else
		color = '1 1 1';

	float theAlpha;
	if(currently_selected)
		theAlpha = 1;
	else
		theAlpha = 0.7;

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
        HUD_Panel_DrawProgressBar(myPos + eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize_x, mySize - eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize_x, autocvar_hud_panel_ammo_progressbar_name, a/autocvar_hud_panel_ammo_maxammo, 0, 0, color, autocvar_hud_progressbar_alpha * panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);

    if(autocvar_hud_panel_ammo_text)
    {
        if(a > 0 || infinite_ammo)
            drawstring_aspect(numpos, ftos(a), eX * (2/3) * mySize_x + eY * mySize_y, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
        else // "ghost" ammo count
            drawstring_aspect(numpos, ftos(a), eX * (2/3) * mySize_x + eY * mySize_y, '0 0 0', panel_fg_alpha * theAlpha * 0.5, DRAWFLAG_NORMAL);
    }
	if(a > 0 || infinite_ammo)
		drawpic_aspect_skin(picpos, GetAmmoPicture(itemcode), '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
	else // "ghost" ammo icon
		drawpic_aspect_skin(picpos, GetAmmoPicture(itemcode), '1 1 0' * mySize_y, '0 0 0', panel_fg_alpha * theAlpha * 0.5, DRAWFLAG_NORMAL);
}

void HUD_Ammo(void)
{
    if(hud != HUD_NORMAL) return;
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_ammo) return;
		if(spectatee_status == -1) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_AMMO;

	HUD_Panel_UpdateCvars(ammo);
	HUD_Panel_ApplyFadeAlpha();
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

	local noref vector offset; // fteqcc sucks
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

	float i, stat_items, currently_selected, infinite_ammo;
	infinite_ammo = FALSE;
	if (autocvar_hud_panel_ammo_onlycurrent)
	{
		if(autocvar__hud_configure)
		{
			DrawAmmoItem(pos, ammo_size, 2, true, FALSE); //show rockets
			return;
		}
		stat_items = getstati(STAT_ITEMS);
		if (stat_items & IT_UNLIMITED_WEAPON_AMMO)
			infinite_ammo = TRUE;
		for (i = 0; i < AMMO_COUNT; ++i) {
			currently_selected = stat_items & GetAmmoItemCode(i);
			if (currently_selected)
			{
				DrawAmmoItem(pos, ammo_size, i, true, infinite_ammo);
				return;
			}
		}
		return; // nothing to display
	}

	stat_items = getstati(STAT_ITEMS);
	if (stat_items & IT_UNLIMITED_WEAPON_AMMO)
		infinite_ammo = TRUE;
	for (i = 0; i < AMMO_COUNT; ++i) {
		currently_selected = stat_items & GetAmmoItemCode(i);
		DrawAmmoItem(pos + eX * column * (ammo_size_x + offset_x) + eY * row * (ammo_size_y + offset_y), ammo_size, i, currently_selected, infinite_ammo);
		++row;
		if(row >= rows)
		{
			row = 0;
			column = column + 1;
		}
	}
}

void DrawNumIcon(vector myPos, vector mySize, float x, string icon, float vertical, float icon_right_align, vector color, float theAlpha)
{
	vector newPos, newSize;
	vector picpos, numpos;

	if (vertical)
	{
		if(mySize_y/mySize_x > 2)
		{
			newSize_y = 2 * mySize_x;
			newSize_x = mySize_x;

			newPos_y = myPos_y + (mySize_y - newSize_y) / 2;
			newPos_x = myPos_x;
		}
		else
		{
			newSize_x = 1/2 * mySize_y;
			newSize_y = mySize_y;

			newPos_x = myPos_x + (mySize_x - newSize_x) / 2;
			newPos_y = myPos_y;
		}

		if(icon_right_align)
		{
			numpos = newPos;
			picpos = newPos + eY * newSize_x;
		}
		else
		{
			picpos = newPos;
			numpos = newPos + eY * newSize_x;
		}

		newSize_y /= 2;
		drawpic_aspect_skin(picpos, icon, newSize, '1 1 1', panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
		// make number smaller than icon, it looks better
		// reduce only y to draw numbers with different number of digits with the same y size
		numpos_y += newSize_y * ((1 - 0.7) / 2);
		newSize_y *= 0.7;
		drawstring_aspect(numpos, ftos(x), newSize, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
		return;
	}

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

	if(icon_right_align) // right align
	{
		numpos = newPos;
		picpos = newPos + eX * 2 * newSize_y;
	}
	else // left align
	{
		numpos = newPos + eX * newSize_y;
		picpos = newPos;
	}

	drawstring_aspect(numpos, ftos(x), '2 1 0' * newSize_y, color, panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(picpos, icon, '1 1 0' * newSize_y, '1 1 1', panel_fg_alpha * theAlpha, DRAWFLAG_NORMAL);
}

void DrawNumIcon_expanding(vector myPos, vector mySize, float x, string icon, float vertical, float icon_right_align, vector color, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	DrawNumIcon(myPos + expandingbox_resize_centered_box_offset(sz, mySize, 1), mySize * sz, x, icon, vertical, icon_right_align, color, (1 - fadelerp));
}

// Powerups (#2)
//
void HUD_Powerups(void)
{
	float strength_time, shield_time;
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_powerups) return;
		if(spectatee_status == -1) return;
		if not(getstati(STAT_ITEMS) & (IT_STRENGTH | IT_INVINCIBLE)) return;
		if (getstati(STAT_HEALTH) <= 0) return;

		strength_time = bound(0, getstatf(STAT_STRENGTH_FINISHED) - time, 99);
		shield_time = bound(0, getstatf(STAT_INVINCIBLE_FINISHED) - time, 99);
	}
	else
	{
		hud_configure_active_panel = HUD_PANEL_POWERUPS;

		strength_time = 15;
		shield_time = 27;
	}

	HUD_Panel_UpdateCvars(powerups);
	HUD_Panel_ApplyFadeAlpha();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(bound(0, max(strength_time, shield_time), 1));
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float panel_ar = mySize_x/mySize_y;
	float is_vertical = (panel_ar < 1);
	vector shield_offset, strength_offset;
	if (panel_ar >= 4 || (panel_ar >= 1/4 && panel_ar < 1))
	{
		mySize_x *= 0.5;
		if (autocvar_hud_panel_powerups_flip)
			shield_offset_x = mySize_x;
		else
			strength_offset_x = mySize_x;
	}
	else
	{
		mySize_y *= 0.5;
		if (autocvar_hud_panel_powerups_flip)
			shield_offset_y = mySize_y;
		else
			strength_offset_y = mySize_y;
	}

	float shield_baralign, strength_baralign;
	float shield_iconalign, strength_iconalign;
	if (autocvar_hud_panel_powerups_flip)
	{
		strength_baralign = (autocvar_hud_panel_powerups_baralign == 2 || autocvar_hud_panel_powerups_baralign == 1);
		shield_baralign = (autocvar_hud_panel_powerups_baralign == 3 || autocvar_hud_panel_powerups_baralign == 1);
		strength_iconalign = (autocvar_hud_panel_powerups_iconalign == 2 || autocvar_hud_panel_powerups_iconalign == 1);
		shield_iconalign = (autocvar_hud_panel_powerups_iconalign == 3 || autocvar_hud_panel_powerups_iconalign == 1);
	}
	else
	{
		shield_baralign = (autocvar_hud_panel_powerups_baralign == 2 || autocvar_hud_panel_powerups_baralign == 1);
		strength_baralign = (autocvar_hud_panel_powerups_baralign == 3 || autocvar_hud_panel_powerups_baralign == 1);
		shield_iconalign = (autocvar_hud_panel_powerups_iconalign == 2 || autocvar_hud_panel_powerups_iconalign == 1);
		strength_iconalign = (autocvar_hud_panel_powerups_iconalign == 3 || autocvar_hud_panel_powerups_iconalign == 1);
	}

	if(shield_time)
	{
		const float maxshield = 30;
		float shield = ceil(shield_time);
		if(autocvar_hud_panel_powerups_progressbar)
		{
			HUD_Panel_GetProgressBarColor(shield);
			HUD_Panel_DrawProgressBar(pos + shield_offset, mySize, autocvar_hud_panel_powerups_progressbar_shield, shield/maxshield, is_vertical, shield_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		if(autocvar_hud_panel_powerups_text)
		{
			if(shield > 1)
				DrawNumIcon(pos + shield_offset, mySize, shield, "shield", is_vertical, shield_iconalign, '1 1 1', 1);
			if(shield <= 5)
				DrawNumIcon_expanding(pos + shield_offset, mySize, shield, "shield", is_vertical, shield_iconalign, '1 1 1', bound(0, (shield - shield_time) / 0.5, 1));
		}
	}

	if(strength_time)
	{
		const float maxstrength = 30;
		float strength = ceil(strength_time);
		if(autocvar_hud_panel_powerups_progressbar)
		{
			HUD_Panel_GetProgressBarColor(strength);
			HUD_Panel_DrawProgressBar(pos + strength_offset, mySize, autocvar_hud_panel_powerups_progressbar_strength, strength/maxstrength, is_vertical, strength_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		if(autocvar_hud_panel_powerups_text)
		{
			if(strength > 1)
				DrawNumIcon(pos + strength_offset, mySize, strength, "strength", is_vertical, strength_iconalign, '1 1 1', 1);
			if(strength <= 5)
				DrawNumIcon_expanding(pos + strength_offset, mySize, strength, "strength", is_vertical, strength_iconalign, '1 1 1', bound(0, (strength - strength_time) / 0.5, 1));
		}
	}
}

// Health/armor (#3)
//

// prev_* vars contain the health/armor at the previous FRAME
// set to -1 when player is dead or was not playing
float prev_health, prev_armor;
float health_damagetime, armor_damagetime;
float health_beforedamage, armor_beforedamage;
// old_p_* vars keep track of previous values when smoothing value changes of the progressbar
float old_p_health, old_p_armor;
float old_p_healthtime, old_p_armortime;
// prev_p_* vars contain the health/armor progressbar value at the previous FRAME
// set to -1 to forcedly stop effects when we switch spectated player (e.g. from playerX: 70h to playerY: 50h)
float prev_p_health, prev_p_armor;

void HUD_HealthArmor(void)
{
	float armor, health, fuel;
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_healtharmor) return;
		if(hud != HUD_NORMAL) return;
		if(spectatee_status == -1) return;

		health = getstati(STAT_HEALTH);
		if(health <= 0)
		{
			prev_health = -1;
			return;
		}
		armor = getstati(STAT_ARMOR);

		// code to check for spectatee_status changes is in Ent_ClientData()
		// prev_p_health and prev_health can be set to -1 there

		if (prev_p_health == -1)
		{
			// no effect
			health_beforedamage = 0;
			armor_beforedamage = 0;
			health_damagetime = 0;
			armor_damagetime = 0;
			prev_health = health;
			prev_armor = armor;
			old_p_health = health;
			old_p_armor = armor;
			prev_p_health = health;
			prev_p_armor = armor;
		}
		else if (prev_health == -1)
		{
			//start the load effect
			health_damagetime = 0;
			armor_damagetime = 0;
			prev_health = 0;
			prev_armor = 0;
		}
		fuel = getstati(STAT_FUEL);
	}
	else
	{
		hud_configure_active_panel = HUD_PANEL_HEALTHARMOR;

		health = 150;
		armor = 75;
		fuel = 20;
	}

	HUD_Panel_UpdateCvars(healtharmor);
	HUD_Panel_ApplyFadeAlpha();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float baralign = autocvar_hud_panel_healtharmor_baralign;
	float iconalign = autocvar_hud_panel_healtharmor_iconalign;

    float maxhealth = autocvar_hud_panel_healtharmor_maxhealth;
    float maxarmor = autocvar_hud_panel_healtharmor_maxarmor;
	if(autocvar_hud_panel_healtharmor == 2) // combined health and armor display
	{
		vector v;
		v = healtharmor_maxdamage(health, armor, armorblockpercent);

		float x;
		x = floor(v_x + 1);

        float maxtotal = maxhealth + maxarmor;
		string biggercount;
		if(v_z) // NOT fully armored
		{
			biggercount = "health";
			if(autocvar_hud_panel_healtharmor_progressbar)
			{
				HUD_Panel_GetProgressBarColor(health);
				HUD_Panel_DrawProgressBar(pos, mySize, autocvar_hud_panel_healtharmor_progressbar_health, x/maxtotal, 0, (baralign == 1 || baralign == 2), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			if(armor)
            if(autocvar_hud_panel_healtharmor_text)
				drawpic_aspect_skin(pos + eX * mySize_x - eX * 0.5 * mySize_y, "armor", '0.5 0.5 0' * mySize_y, '1 1 1', panel_fg_alpha * armor / health, DRAWFLAG_NORMAL);
		}
		else
		{
			biggercount = "armor";
			if(autocvar_hud_panel_healtharmor_progressbar)
			{
				HUD_Panel_GetProgressBarColor(armor);
				HUD_Panel_DrawProgressBar(pos, mySize, autocvar_hud_panel_healtharmor_progressbar_armor, x/maxtotal, 0, (baralign == 1 || baralign == 2), progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			if(health)
            if(autocvar_hud_panel_healtharmor_text)
				drawpic_aspect_skin(pos + eX * mySize_x - eX * 0.5 * mySize_y, "health", '0.5 0.5 0' * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
        if(autocvar_hud_panel_healtharmor_text)
			DrawNumIcon(pos, mySize, x, biggercount, 0, iconalign, HUD_Get_Num_Color(x, maxtotal), 1);

		if(fuel)
		{
			HUD_Panel_GetProgressBarColor(fuel);
			HUD_Panel_DrawProgressBar(pos, eX * mySize_x + eY * 0.2 * mySize_y, "progressbar", fuel/100, 0, (baralign == 1 || baralign == 3), progressbar_color, panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
		}
	}
	else
	{
		float panel_ar = mySize_x/mySize_y;
		float is_vertical = (panel_ar < 1);
		vector health_offset, armor_offset;
		if (panel_ar >= 4 || (panel_ar >= 1/4 && panel_ar < 1))
		{
			mySize_x *= 0.5;
			if (autocvar_hud_panel_healtharmor_flip)
				health_offset_x = mySize_x;
			else
				armor_offset_x = mySize_x;
		}
		else
		{
			mySize_y *= 0.5;
			if (autocvar_hud_panel_healtharmor_flip)
				health_offset_y = mySize_y;
			else
				armor_offset_y = mySize_y;
		}

		float health_baralign, armor_baralign, fuel_baralign;
		float health_iconalign, armor_iconalign;
		if (autocvar_hud_panel_healtharmor_flip)
		{
			armor_baralign = (autocvar_hud_panel_healtharmor_baralign == 2 || autocvar_hud_panel_healtharmor_baralign == 1);
			health_baralign = (autocvar_hud_panel_healtharmor_baralign == 3 || autocvar_hud_panel_healtharmor_baralign == 1);
			fuel_baralign = health_baralign;
			armor_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 2 || autocvar_hud_panel_healtharmor_iconalign == 1);
			health_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 3 || autocvar_hud_panel_healtharmor_iconalign == 1);
		}
		else
		{
			health_baralign = (autocvar_hud_panel_healtharmor_baralign == 2 || autocvar_hud_panel_healtharmor_baralign == 1);
			armor_baralign = (autocvar_hud_panel_healtharmor_baralign == 3 || autocvar_hud_panel_healtharmor_baralign == 1);
			fuel_baralign = armor_baralign;
			health_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 2 || autocvar_hud_panel_healtharmor_iconalign == 1);
			armor_iconalign = (autocvar_hud_panel_healtharmor_iconalign == 3 || autocvar_hud_panel_healtharmor_iconalign == 1);
		}

		//if(health)
		{
			if(autocvar_hud_panel_healtharmor_progressbar)
			{
				HUD_Panel_GetProgressBarColor(health);
				float p_health, pain_health_alpha;
				p_health = health;
				pain_health_alpha = 1;
				if (autocvar_hud_panel_healtharmor_progressbar_gfx)
				{
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_smooth > 0)
					{
						if (fabs(prev_health - health) >= autocvar_hud_panel_healtharmor_progressbar_gfx_smooth)
						{
							if (time - old_p_healthtime < 1)
								old_p_health = prev_p_health;
							else
								old_p_health = prev_health;
							old_p_healthtime = time;
						}
						if (time - old_p_healthtime < 1)
						{
							p_health += (old_p_health - health) * (1 - (time - old_p_healthtime));
							prev_p_health = p_health;
						}
					}
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_damage > 0)
					{
						if (prev_health - health >= autocvar_hud_panel_healtharmor_progressbar_gfx_damage)
						{
							if (time - health_damagetime >= 1)
								health_beforedamage = prev_health;
							health_damagetime = time;
						}
						if (time - health_damagetime < 1)
						{
							float health_damagealpha = 1 - (time - health_damagetime)*(time - health_damagetime);
							HUD_Panel_DrawProgressBar(pos + health_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_health, health_beforedamage/maxhealth, is_vertical, health_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * health_damagealpha, DRAWFLAG_NORMAL);
						}
					}
					prev_health = health;

					if (health <= autocvar_hud_panel_healtharmor_progressbar_gfx_lowhealth)
					{
						float BLINK_FACTOR = 0.15;
						float BLINK_BASE = 0.85;
						float BLINK_FREQ = 9; 
						pain_health_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ);
					}
				}
				HUD_Panel_DrawProgressBar(pos + health_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_health, p_health/maxhealth, is_vertical, health_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * pain_health_alpha, DRAWFLAG_NORMAL);
			}
			if(autocvar_hud_panel_healtharmor_text)
				DrawNumIcon(pos + health_offset, mySize, health, "health", is_vertical, health_iconalign, HUD_Get_Num_Color(health, maxhealth), 1);
		}

		if(armor)
		{
			if(autocvar_hud_panel_healtharmor_progressbar)
			{
				HUD_Panel_GetProgressBarColor(armor);
				float p_armor;
				p_armor = armor;
				if (autocvar_hud_panel_healtharmor_progressbar_gfx)
				{
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_smooth > 0)
					{
						if (fabs(prev_armor - armor) >= autocvar_hud_panel_healtharmor_progressbar_gfx_smooth)
						{
							if (time - old_p_armortime < 1)
								old_p_armor = prev_p_armor;
							else
								old_p_armor = prev_armor;
							old_p_armortime = time;
						}
						if (time - old_p_armortime < 1)
						{
							p_armor += (old_p_armor - armor) * (1 - (time - old_p_armortime));
							prev_p_armor = p_armor;
						}
					}
					if (autocvar_hud_panel_healtharmor_progressbar_gfx_damage > 0)
					{
						if (prev_armor - armor >= autocvar_hud_panel_healtharmor_progressbar_gfx_damage)
						{
							if (time - armor_damagetime >= 1)
								armor_beforedamage = prev_armor;
							armor_damagetime = time;
						}
						if (time - armor_damagetime < 1)
						{
							float armor_damagealpha = 1 - (time - armor_damagetime)*(time - armor_damagetime);
							HUD_Panel_DrawProgressBar(pos + armor_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_armor, armor_beforedamage/maxarmor, is_vertical, armor_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha * armor_damagealpha, DRAWFLAG_NORMAL);
						}
					}
					prev_armor = armor;
				}
				HUD_Panel_DrawProgressBar(pos + armor_offset, mySize, autocvar_hud_panel_healtharmor_progressbar_armor, p_armor/maxarmor, is_vertical, armor_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			if(autocvar_hud_panel_healtharmor_text)
				DrawNumIcon(pos + armor_offset, mySize, armor, "armor", is_vertical, armor_iconalign, HUD_Get_Num_Color(armor, maxarmor), 1);
		}

		if(fuel)
		{
			if (is_vertical)
				mySize_x *= 0.2 / 2; //if vertical always halve x to not cover too much numbers with 3 digits
			else
				mySize_y *= 0.2;
			if (panel_ar >= 4)
				mySize_x *= 2; //restore full panel size
			else if (panel_ar < 1/4)
				mySize_y *= 2; //restore full panel size
			HUD_Panel_GetProgressBarColor(fuel);
			HUD_Panel_DrawProgressBar(pos, mySize, "progressbar", fuel/100, is_vertical, fuel_baralign, progressbar_color, panel_fg_alpha * 0.8, DRAWFLAG_NORMAL);
		}
	}
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
				print (sprintf(_("^1%s^1 couldn't take it anymore\n"), s1));
		} else if (type == DEATH_ROT) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print (sprintf(_("^1%s^1 died\n"), s1));
		} else if (type == DEATH_NOAMMO) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_NOAMMO);
			if (alsoprint)
				print (sprintf(_("^7%s^7 committed suicide. What's the point of living without ammo?\n"), s1));
		} else if (type == DEATH_CAMP) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_CAMP);
			if (alsoprint)
				print (sprintf(_("^1%s^1 thought they found a nice camping ground\n"), s1));
		} else if (type == KILL_TEAM_RED || type == KILL_TEAM_BLUE) {
			HUD_KillNotify_Push(s1, "", 0, type);
			if (alsoprint)
				print (sprintf(_("^1%s^1 didn't become friends with the Lord of Teamplay\n"), s1));
		} else if (type == DEATH_CHEAT) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print (sprintf(_("^1%s^1 unfairly eliminated themself\n"), s1));
		} else if (type == DEATH_FIRE) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print (sprintf(_("^1%s^1 burned to death\n"), s1));
		} else if (type != DEATH_TEAMCHANGE && type != DEATH_QUIET) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if (alsoprint)
				print (sprintf(_("^1%s^1 couldn't resist the urge to self-destruct\n"), s1));
		} 
		
		if (stof(s2) > 2) // killcount > 2
			print (sprintf(_("^1%s^1 ended it all after a %d kill spree\n"), s1, stof(s2)));
	} else if(msg == MSG_KILL) {
		w = DEATH_WEAPONOF(type);
		if(WEP_VALID(w)) {
			if((w == WEP_RIFLE || w == WEP_MINSTANEX) && type & HITTYPE_HEADSHOT) // all headshot weapons go here
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
					print (sprintf(_("^1%s^1 took action against a team mate\n"), s1));
				} else {
					print (sprintf(_("^1%s^1 mows down a team mate\n"), s1));
				}
			}
			if (stof(s2) > 2 && type == KILL_TEAM_SPREE) {
				if(gentle)
					print (sprintf(_("^1%s^1 ended a %d scoring spree by going against a team mate\n"), s1, stof(s3)));
				else
					print (sprintf(_("^1%s^1 ended a %d kill spree by killing a team mate\n"), s1, stof(s3)));
			}
			else if (stof(s2) > 2) {
				if(gentle)
					print (sprintf(_("^1%s^1's %s scoring spree was ended by a team mate!\n"), s1, stof(s3)));
				else
					print (sprintf(_("^1%s^1's %s kill spree was ended by a team mate!\n"), s1, stof(s3)));
			}
		}
		else if(type == KILL_FIRST_BLOOD)
			print(sprintf(_("^1%s^1 drew first blood\n"), s1));
		else if (type == DEATH_TELEFRAG) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_TELEFRAG);
			if(gentle)
				print (sprintf(_("^1%s^1 tried to occupy %s^1's teleport destination space\n"), s2, s1));
			else
				print (sprintf(_("^1%s^1 was telefragged by %s\n"), s2, s1));
		}
		else if (type == DEATH_DROWN) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_DROWN);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was drowned by %s\n"), s2, s1));
		}
		else if (type == DEATH_SLIME) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_SLIME);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was slimed by %s\n"), s2, s1));
		}
		else if (type == DEATH_LAVA) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_LAVA);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was cooked by %s\n"), s2, s1));
		}
		else if (type == DEATH_FALL) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_FALL);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was grounded by %s\n"), s2, s1));
		}
		else if (type == DEATH_SHOOTING_STAR) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_SHOOTING_STAR);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was shot into space by %s\n"), s2, s1));
		}
		else if (type == DEATH_SWAMP) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was conserved by %s\n"), s2, s1));
		}
		else if (type == DEATH_HURTTRIGGER)
		{
			HUD_KillNotify_Push(s1, s2, 1, DEATH_HURTTRIGGER);
			if(alsoprint)
				print(sprintf(_("^1%s^1 was thrown into a world of hurt by %s\n"), s2, s1));
		} else if(type == DEATH_VHCRUSH) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was crushed by %s\n"), s2, s1));
		} else if(type == DEATH_SBMINIGUN) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 got shredded by %s\n"), s2, s1));
		} else if(type == DEATH_SBROCKET) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was blasted to bits by %s\n"), s2, s1));
		} else if(type == DEATH_SBBLOWUP) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 got caught in the destruction of %s^1's vehicle\n"), s2, s1));
		} else if(type == DEATH_WAKIGUN) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was bolted down by %s\n"), s2, s1));
		} else if(type == DEATH_WAKIROCKET) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 could find no shelter from %s^1's rockets\n"), s2, s1));
		} else if(type == DEATH_WAKIBLOWUP) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 dies when %s^1's wakizashi dies.\n"), s2, s1));
		} else if(type == DEATH_RAPTOR_CANNON) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 nailed to hell by %s\n"), s2, s1));
		} else if(type == DEATH_RAPTOR_BOMB) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 cluster crushed by %s\n"), s2, s1));
		} else if(type == DEATH_RAPTOR_DEATH) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 dies when %s^1's raptor dies.\n"), s2, s1));
		} else if(type == DEATH_TURRET) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was pushed into the line of fire by %s\n"), s2, s1));
		} else if(type == DEATH_TOUCHEXPLODE) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was pushed into an accident by %s\n"), s2, s1));
		} else if(type == DEATH_CHEAT) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was unfairly eliminated by %s\n"), s2, s1));
		} else if (type == DEATH_FIRE) {
			HUD_KillNotify_Push(s1, s2, 1, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was burnt to death by %s\n"), s2, s1));
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
				print (sprintf(_("^1%s^1 was fragged by %s\n"), s2, s1));
		}
	} else if(msg == MSG_SPREE) {
		if(type == KILL_END_SPREE) {
			if(gentle)
				print (sprintf(_("^1%s^1's %s scoring spree was ended by %s\n"), s1, s2, s3));
			else
				print (sprintf(_("^1%s^1's %s kill spree was ended by %s\n"), s1, s2, s3));
		} else if(type == KILL_SPREE) {
			if(gentle)
				print (sprintf(_("^1%s^1 made %s scores in a row\n"), s1, s2));
			else
				print (sprintf(_("^1%s^1 has %s frags in a row\n"), s1, s2));
		} else if(type == KILL_SPREE_3) {
			if(gentle)
				print (sprintf(_("%s^7 made a ^1TRIPLE SCORE\n"), s1));
			else
				print (sprintf(_("%s^7 made a ^1TRIPLE FRAG\n"), s1));
		} else if(type == KILL_SPREE_5) {
			if(gentle)
				print (sprintf(_("%s^7 unleashes ^1SCORING RAGE\n"), s1));
			else
				print (sprintf(_("%s^7 unleashes ^1RAGE\n"), s1));
		} else if(type == KILL_SPREE_10) {
			if(gentle)
				print (sprintf(_("%s^7 made ^1TEN SCORES IN A ROW!\n"), s1));
			else
				print (sprintf(_("%s^7 starts the ^1MASSACRE!\n"), s1));
		} else if(type == KILL_SPREE_15) {
			if(gentle)
				print (sprintf(_("%s^7 made ^1FIFTEEN SCORES IN A ROW!\n"), s1));
			else
				print (sprintf(_("%s^7 executes ^1MAYHEM!\n"), s1));
		} else if(type == KILL_SPREE_20) {
			if(gentle)
				print (sprintf(_("%s^7 made ^1TWENTY SCORES IN A ROW!\n"), s1));
			else
				print (sprintf(_("%s^7 is a ^1BERSERKER!\n"), s1));
		} else if(type == KILL_SPREE_25) {
			if(gentle)
				print (sprintf(_("%s^7 made ^1TWENTY FIVE SCORES IN A ROW!\n"), s1));
			else
				print (sprintf(_("%s^7 inflicts ^1CARNAGE!\n"), s1));
		} else if(type == KILL_SPREE_30) {
			if(gentle)
				print (sprintf(_("%s^7 made ^1THIRTY SCORES IN A ROW!\n"), s1));
			else
				print (sprintf(_("%s^7 unleashes ^1ARMAGEDDON!\n"), s1));
		}
	} else if(msg == MSG_KILL_ACTION) { // wtf is this? isnt it basically the same as MSG_SUICIDE?
		if (type == DEATH_DROWN) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_DROWN);
			if(alsoprint)
			{
				if(gentle)
					print (sprintf(_("^1%s^1 was in the water for too long\n"), s1));
				else
					print (sprintf(_("^1%s^1 drowned\n"), s1));
			}
		} else if (type == DEATH_SLIME) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_SLIME);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was slimed\n"), s1));
		} else if (type == DEATH_LAVA) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_LAVA);
			if(alsoprint)
			{
				if(gentle)
					print (sprintf(_("^1%s^1 found a hot place\n"), s1));
				else
					print (sprintf(_("^1%s^1 turned into hot slag\n"), s1));
			}
		} else if (type == DEATH_FALL) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print (sprintf(_("^1%s^1 tested gravity (and it worked)\n"), s1));
				else
					print (sprintf(_("^1%s^1 hit the ground with a crunch\n"), s1));
			}
		} else if (type == DEATH_SHOOTING_STAR) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_SHOOTING_STAR);
			if(alsoprint)
				print (sprintf(_("^1%s^1 became a shooting star\n"), s1));
		} else if (type == DEATH_SWAMP) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print (sprintf(_("^1%s^1 discovered a swamp\n"), s1));
				else
					print (sprintf(_("^1%s^1 is now conserved for centuries to come\n"), s1));
			}
		} else if(DEATH_ISTURRET(type)) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print (sprintf(_("^1%s^1 ran into a turret\n"), s1));
				else
				{
					switch(type)
					{
						case DEATH_TURRET_EWHEEL:
							print (sprintf(_("^1%s^1 was laserd down by a eWheel turret \n"), s1));
							break;
						case DEATH_TURRET_FLAC:
							print (sprintf(_("^1%s^1 got caught in the flac \n"), s1));
							break;
						case DEATH_TURRET_MACHINEGUN:
							print (sprintf(_("^1%s^1 was riddeld full of riddled by a machinegun turret \n"), s1));
							break;
						case DEATH_TURRET_WALKER_GUN:
							print (sprintf(_("^1%s^1 got served a led enrichment by a walker turret \n"), s1));
							break;
						case DEATH_TURRET_WALKER_MEELE:
							print (sprintf(_("^1%s^1 was impaled by a walker turret \n"), s1));
							break;
						case DEATH_TURRET_WALKER_ROCKET:
							print (sprintf(_("^1%s^1 was rocketed to hell by a walker turret \n"), s1));
							break;
						case DEATH_TURRET_HELLION:
							print (sprintf(_("^1%s^1 was blasted away hellion turret \n"), s1));
							break;
						case DEATH_TURRET_HK:
							print (sprintf(_("^1%s^1 could not hide from the hunter turret \n"), s1));
							break;
						case DEATH_TURRET_MLRS:
							print (sprintf(_("^1%s^1 got turned into smoldering gibs by a mlrs turret \n"), s1));
							break;
						case DEATH_TURRET_PLASMA:
							print (sprintf(_("^1%s^1 got served some superheated plasma from a plasma turret \n"), s1));
							break;
						case DEATH_TURRET_PHASER:
							print (sprintf(_("^1%s^1 was phased out \n"), s1));
							break;
						case DEATH_TURRET_TESLA:			
							print (sprintf(_("^1%s^1 was electrocuted by a tesla turret \n"), s1));
							break;
					}
				}
			}
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
				print (sprintf(_("^1%s^1 died in an accident\n"), s1));
		} else if(type == DEATH_CHEAT) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
				print (sprintf(_("^1%s^1 was unfairly eliminated\n"), s1));
		} else if(type == DEATH_FIRE) {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print (sprintf(_("^1%s^1 felt a little hot\n"), s1));
				else
					print (sprintf(_("^1%s^1 burnt to death\n"), s1));
				}
		} else {
			HUD_KillNotify_Push(s1, "", 0, DEATH_GENERIC);
			if(alsoprint)
			{
				if(gentle)
					print (sprintf(_("^1%s^1 needs a restart\n"), s1));
				else
					print (sprintf(_("^1%s^1 died\n"), s1));
			}
		}
	} else if(msg == MSG_KILL_ACTION_SPREE) {
		if(gentle)
			print (sprintf(_("^1%s^1 needs a restart after a %d scoring spree\n"), s1, stof(s2)));
		else
			print (sprintf(_("^1%s^1 died with a %d kill spree\n"), s1, stof(s2)));
	} else if(msg == MSG_INFO) {
		if(type == INFO_GOTFLAG) { // here, s2 is the flag name
			HUD_KillNotify_Push(s1, s2, 0, INFO_GOTFLAG);
			print(sprintf(_("%s^7 got the %s\n"), s1, s2));
		} else if(type == INFO_LOSTFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_LOSTFLAG);
			print(sprintf(_("%s^7 lost the %s\n"), s1, s2));
		} else if(type == INFO_PICKUPFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_GOTFLAG);
			print(sprintf(_("%s^7 picked up the %s\n"), s1, s2));
		} else if(type == INFO_RETURNFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_RETURNFLAG);
			print(sprintf(_("%s^7 returned the %s\n"), s1, s2));
		} else if(type == INFO_CAPTUREFLAG) {
			HUD_KillNotify_Push(s1, s2, 0, INFO_CAPTUREFLAG);
			print(sprintf(_("%s^7 captured the %s%s\n"), s1, s2, s3));
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
				print (sprintf(_("%s^7 has picked up the ball!\n"), s1));
		}
		else if(type == KA_DROPBALL) {
			HUD_KillNotify_Push(s1, s2, 0, KA_DROPBALL);
			if(alsoprint)
				print(sprintf(_("%s^7 has dropped the ball!\n"), s1));
		}
	}
}

void HUD_KillCenterprint(string s1, string s2, float type, float msg)
{
	float gentle;
	gentle = (autocvar_cl_gentle || autocvar_cl_gentle_messages);
	if(msg == MSG_SUICIDE) {
		if (type == DEATH_TEAMCHANGE) {
			centerprint_hud(sprintf(_("You are now on: %s"), s1));
		} else if (type == DEATH_AUTOTEAMCHANGE) {
			centerprint_hud(sprintf(_("You have been moved into a different team to improve team balance\nYou are now on: %s"), s1));
		} else if (type == DEATH_CAMP) {
			if(gentle)
				centerprint_hud(_("^1Reconsider your tactics, camper!"));
			else
				centerprint_hud(_("^1Die camper!"));
		} else if (type == DEATH_NOAMMO) {
			if(gentle)
				centerprint_hud(_("^1You are reinserted into the game for running out of ammo..."));
			else
				centerprint_hud(_("^1You were killed for running out of ammo..."));
		} else if (type == DEATH_ROT) {
			if(gentle)
				centerprint_hud(_("^1You need to preserve your health"));
			else
				centerprint_hud(_("^1You grew too old without taking your medicine"));
		} else if (type == KILL_TEAM_RED || type == KILL_TEAM_BLUE) {
			if(gentle)
				centerprint_hud(_("^1Don't go against team mates!"));
			else
				centerprint_hud(_("^1Don't shoot your team mates!"));
		} else if (type == DEATH_QUIET) {
			// do nothing
		} else { // generic message
			if(gentle)
				centerprint_hud(_("^1You need to be more careful!"));
			else
				centerprint_hud(_("^1You killed your own dumb self!"));
		}
	} else if(msg == MSG_KILL) {
		if (type == KILL_TEAM_RED || type == KILL_TEAM_BLUE) {
			if(gentle) {
				centerprint_hud(sprintf(_("^1Moron! You went against ^7%s^1, a team mate!"), s1));
			} else {
				centerprint_hud(sprintf(_("^1Moron! You fragged ^7%s^1, a team mate!"), s1));
			}
		} else if (type == KILL_FIRST_BLOOD) {
			if(gentle) {
				centerprint_hud(_("^1First score"));
			} else {
				centerprint_hud(_("^1First blood"));
			}
		} else if (type == KILL_FIRST_VICTIM) {
			if(gentle) {
				centerprint_hud(_("^1First casualty"));
			} else {
				centerprint_hud(_("^1First victim"));
			}
		} else if (type == KILL_TYPEFRAG) { // s2 contains "advanced kill messages" such as ping, handicap...
			if(gentle) {
				centerprint_hud(strcat(sprintf(_("^1You scored against ^7%s^1 who was typing!"), s1), s2));
			} else {
				centerprint_hud(strcat(sprintf(_("^1You typefragged ^7%s"), s1), s2));
			}
		} else if (type == KILL_TYPEFRAGGED) {
			if(gentle) {
				centerprint_hud(strcat(sprintf(_("^1You were scored against by ^7%s^1 while you were typing!"), s1), s2));
			} else {
				centerprint_hud(strcat(sprintf(_("^1You were typefragged by ^7%s"), s1), s2));
			}
		} else if (type == KILL_FRAG) {
			if(gentle) {
				centerprint_hud(strcat(sprintf(_("^4You scored against ^7%s"), s1), s2));
			} else {
				centerprint_hud(strcat(sprintf(_("^4You fragged ^7%s"), s1), s2));
			}
		} else { // generic message
			if(gentle) {
				centerprint_hud(strcat(sprintf(_("^1You were scored against by ^7%s"), s1), s2));
			} else {
				centerprint_hud(strcat(sprintf(_("^1You were fragged by ^7%s"), s1), s2));
			}
		}
	} else if(msg == MSG_KILL_ACTION) {
		// TODO: invent more centerprints here?
		centerprint_hud(_("^1Watch your step!"));
	}
}

void HUD_Notify (void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_notify) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_NOTIFY;

	HUD_Panel_UpdateCvars(notify);
	HUD_Panel_ApplyFadeAlpha();
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
	float fontheight = height * autocvar_hud_panel_notify_fontsize;
	fontsize = '0.5 0.5 0' * fontheight;

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
			attacker = textShortenToWidth(sprintf(_("Player %d"), a+1), 0.48 * mySize_x - height, fontsize, stringwidth_colors);
			victim = textShortenToWidth(sprintf(_("Player %d"), a+2), 0.48 * mySize_x - height, fontsize, stringwidth_colors);
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
			pos_attacker = pos + eX * (0.52 * mySize_x + height) + eY * ((0.5 * fontsize_y + i * height) + (0.5 * (height - fontheight)));
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
			pos_attacker = pos + eX * (0.48 * mySize_x - height - width_attacker) + eY * ((0.5 * fontsize_y + i * height) + (0.5 * (height - fontheight)));
			pos_victim = pos + eX * (0.52 * mySize_x + height) + eY * ((0.5 * fontsize_y + i * height) + (0.5 * (height - fontheight)));
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
	return sprintf("%d:%02d", minutes, sec);
}

void HUD_Timer(void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_timer) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_TIMER;

	HUD_Panel_UpdateCvars(timer);
	HUD_Panel_ApplyFadeAlpha();
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

	drawstring_aspect(pos, timer, mySize, timer_color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Radar (#6)
//
void HUD_Radar(void)
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
		}
	}
	else
		hud_configure_active_panel = HUD_PANEL_RADAR;

	HUD_Panel_UpdateCvars(radar);
	HUD_Panel_ApplyFadeAlpha();

	if (hud_panel_radar_maximized && !autocvar__hud_configure)
	{
		panel_size = autocvar_hud_panel_radar_maximized_size;
		panel_size_x = bound(0.2, panel_size_x, 1) * vid_conwidth;
		panel_size_y = bound(0.2, panel_size_y, 1) * vid_conheight;
		panel_pos_x = (vid_conwidth - panel_size_x) / 2;
		panel_pos_y = (vid_conheight - panel_size_y) / 2;
		
		panel_bg = strcat(hud_skin_path, "/border_default"); // always use the default border when maximized
		if(precache_pic(panel_bg) == "") { panel_bg = "gfx/hud/default/border_default"; } // fallback
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

	float color2;
	entity tm;
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
		span_x = max(c0_x, c1_x, c2_x, c3_x) - min(c0_x, c1_x, c2_x, c3_x);
		span_y = max(c0_y, c1_y, c2_y, c3_y) - min(c0_y, c1_y, c2_y, c3_y);

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
void HUD_UpdatePlayerTeams();
void HUD_Score_Rankings(vector pos, vector mySize, entity me, float team_count)
{
	float score;
	entity tm, pl;
#define SCOREPANEL_MAX_ENTRIES 6
#define SCOREPANEL_ASPECTRATIO 2
	float entries = bound(1, floor(SCOREPANEL_MAX_ENTRIES * mySize_y/mySize_x * SCOREPANEL_ASPECTRATIO), SCOREPANEL_MAX_ENTRIES);
	vector fontsize = '1 1 0' * (mySize_y/entries);

	vector rgb, score_color;
	rgb = '1 1 1';
	score_color = '1 1 1';

	float name_size = mySize_x*0.75;
	float spacing_size = mySize_x*0.04;
	const float highlight_alpha = 0.2;
	float i, me_printed, first_pl;
	string s;
	i = 0;
	first_pl = 0;
	if (autocvar__hud_configure)
	{
		float players_per_team;
		if (team_count)
		{
			// show team scores in the first line
			float score_size = mySize_x / team_count;
			players_per_team = max(2, ceil((entries - 1) / team_count));
			for(i=0; i<team_count; ++i) {
				if (i == floor((entries - 2) / players_per_team) || (entries == 1 && i == 0))
					HUD_Panel_DrawHighlight(pos + eX * score_size * i, eX * score_size + eY * fontsize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(pos + eX * score_size * i, ftos(175 - 23*i), eX * score_size + eY * fontsize_y, GetTeamRGB(ColorByTeam(i)) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			first_pl = 1;
			pos_y += fontsize_y;
		}
		score = 10 + SCOREPANEL_MAX_ENTRIES * 3;
		for (i=first_pl; i<entries; ++i)
		{
			//simulate my score is lower than all displayed players,
			//so that I don't appear at all showing pure rankings.
			//This is to better show the difference between the 2 ranking views
			if (i == entries-1 && autocvar_hud_panel_score_rankings == 1)
			{
				rgb = '1 1 0';
				drawfill(pos, eX * mySize_x + eY * fontsize_y, rgb, highlight_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				s = GetPlayerName(pl.sv_entnum);
				score = 7;
			}
			else
			{
				s = sprintf(_("Player %d"), i + 1 - first_pl);
				score -= 3;
			}

			if (team_count)
				score_color = GetTeamRGB(ColorByTeam(floor((i - first_pl) / players_per_team))) * 0.8;
			s = textShortenToWidth(s, name_size, fontsize, stringwidth_colors);
			drawcolorcodedstring(pos + eX * (name_size - stringwidth(s, TRUE, fontsize)), s, fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			drawstring(pos + eX * (name_size + spacing_size), ftos(score), fontsize, score_color, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos_y += fontsize_y;
		}
		return;
	}

	if (!scoreboard_fade_alpha) // the scoreboard too calls HUD_UpdatePlayerTeams
		HUD_UpdatePlayerTeams();
	if (team_count)
	{
		// show team scores in the first line
		float score_size = mySize_x / team_count;
		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == COLOR_SPECTATOR)
				continue;
			if (tm.team == myteam)
				drawfill(pos + eX * score_size * i, eX * score_size + eY * fontsize_y, '1 1 1', highlight_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			drawstring_aspect(pos + eX * score_size * i, ftos(tm.(teamscores[ts_primary])), eX * score_size + eY * fontsize_y, GetTeamRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
			++i;
		}
		first_pl = 1;
		pos_y += fontsize_y;
		tm = teams.sort_next;
	}
	i = first_pl;

	do
	for (pl = players.sort_next; pl && i<entries; pl = pl.sort_next)
	{
		if ((team_count && pl.team != tm.team) || pl.team == COLOR_SPECTATOR)
			continue;

		if (i == entries-1 && !me_printed && pl != me)
		if (autocvar_hud_panel_score_rankings == 1 && spectatee_status != -1)
		{
			for (pl = me.sort_next; pl; pl = pl.sort_next)
				if (pl.team != COLOR_SPECTATOR)
					break;

			if (pl)
				rgb = '1 1 0'; //not last but not among the leading players: yellow
			else
				rgb = '1 0 0'; //last: red
			pl = me;
		}

		if (pl == me)
		{
			if (i == first_pl)
				rgb = '0 1 0'; //first: green
			me_printed = 1;
			drawfill(pos, eX * mySize_x + eY * fontsize_y, rgb, highlight_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		if (team_count)
			score_color = GetTeamRGB(pl.team) * 0.8;
		s = textShortenToWidth(GetPlayerName(pl.sv_entnum), name_size, fontsize, stringwidth_colors);
		drawcolorcodedstring(pos + eX * (name_size - stringwidth(s, TRUE, fontsize)), s, fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring(pos + eX * (name_size + spacing_size), ftos(pl.(scores[ps_primary])), fontsize, score_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		pos_y += fontsize_y;
		++i;
	}
	while (i<entries && team_count && (tm = tm.sort_next) && (tm.team != COLOR_SPECTATOR || (tm = tm.sort_next)));
}

void HUD_Score(void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_score) return;
		if(spectatee_status == -1 && (gametype == GAME_RACE || gametype == GAME_CTS)) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_SCORE;

	HUD_Panel_UpdateCvars(score);
	HUD_Panel_ApplyFadeAlpha();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float score, distribution;
	string sign;
	vector distribution_color;
	entity tm, pl, me;
#ifdef COMPAT_XON050_ENGINE
	me = (spectatee_status > 0) ? playerslots[spectatee_status - 1] : playerslots[player_localentnum - 1];
#else
	me = playerslots[player_localentnum - 1];
#endif

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
		drawstring_aspect(pos, timer, eX * 0.75 * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	} else if (!teamplay) { // non-teamgames
		if ((spectatee_status == -1 && !autocvar__hud_configure) || autocvar_hud_panel_score_rankings)
		{
			HUD_Score_Rankings(pos, mySize, me, 0);
			return;
		}
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

		if(distribution >= 5)
			distribution_color = eY;
		else if(distribution >= 0)
			distribution_color = '1 1 1';
		else if(distribution >= -5)
			distribution_color = '1 1 0';
		else
			distribution_color = eX;

		string distribution_str;
		distribution_str = ftos(distribution);
		if (distribution >= 0)
		{
			if (distribution > 0)
				distribution_str = strcat("+", distribution_str);
			HUD_Panel_DrawHighlight(pos, eX * 0.75 * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		drawstring_aspect(pos, ftos(score), eX * 0.75 * mySize_x + eY * mySize_y, distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(pos + eX * 0.75 * mySize_x, distribution_str, eX * 0.25 * mySize_x + eY * (1/3) * mySize_y, distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
	} else { // teamgames
		float scores_count, row, column, rows, columns;
		local noref vector offset; // fteqcc sucks
		vector score_pos, score_size; //for scores other than myteam
		if (spectatee_status == -1 || autocvar_hud_panel_score_rankings)
		{
			for(tm = teams.sort_next; tm, tm.team != COLOR_SPECTATOR; tm = tm.sort_next)
				++scores_count;
			if (autocvar_hud_panel_score_rankings)
			{
				HUD_Score_Rankings(pos, mySize, me, scores_count);
				return;
			}
			rows = mySize_y/mySize_x;
			rows = bound(1, floor((sqrt(4 * (3/1) * rows * scores_count + rows * rows) + rows + 0.5) / 2), scores_count);
			//                               ^^^ ammo item aspect goes here

			columns = ceil(scores_count/rows);

			score_size = eX * mySize_x*(1/columns) + eY * mySize_y*(1/rows);

			float newSize;
			if(score_size_x/score_size_y > 3)
			{
				newSize = 3 * score_size_y;
				offset_x = score_size_x - newSize;
				pos_x += offset_x/2;
				score_size_x = newSize;
			}
			else
			{
				newSize = 1/3 * score_size_x;
				offset_y = score_size_y - newSize;
				pos_y += offset_y/2;
				score_size_y = newSize;
			}
		}
		else
			score_size = eX * mySize_x*(1/4) + eY * mySize_y*(1/3);

		float max_fragcount;
		max_fragcount = -99;
		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == COLOR_SPECTATOR)
				continue;
			score = tm.(teamscores[ts_primary]);
			if(autocvar__hud_configure)
				score = 123;
			
			if (score > max_fragcount)
				max_fragcount = score;

			if (spectatee_status == -1)
			{
				score_pos = pos + eX * column * (score_size_x + offset_x) + eY * row * (score_size_y + offset_y);
				if (max_fragcount == score)
					HUD_Panel_DrawHighlight(score_pos, score_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(score_pos, ftos(score), score_size, GetTeamRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
				++row;
				if(row >= rows)
				{
					row = 0;
					++column;
				}
			}
			else if(tm.team == myteam) {
				if (max_fragcount == score)
					HUD_Panel_DrawHighlight(pos, eX * 0.75 * mySize_x + eY * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(pos, ftos(score), eX * 0.75 * mySize_x + eY * mySize_y, GetTeamRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
			} else {
				if (max_fragcount == score)
					HUD_Panel_DrawHighlight(pos + eX * 0.75 * mySize_x + eY * (1/3) * rows * mySize_y, score_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(pos + eX * 0.75 * mySize_x + eY * (1/3) * rows * mySize_y, ftos(score), score_size, GetTeamRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
				++rows;
			}
		}
	}
}

// Race timer (#8)
//
void HUD_RaceTimer (void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_racetimer) return;
		if(!(gametype == GAME_RACE || gametype == GAME_CTS)) return;
		if(spectatee_status == -1) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_RACETIMER;

	HUD_Panel_UpdateCvars(racetimer);
	HUD_Panel_ApplyFadeAlpha();
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

	float a, t;
	string s, forcetime;

	if(autocvar__hud_configure)
	{
		s = "0:13:37";
		drawstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, FALSE, '0.60 0.60 0' * mySize_y), s, '0.60 0.60 0' * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		s = _("^1Intermediate 1 (+15.42)");
		drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.20 * mySize_y) + eY * 0.60 * mySize_y, s, '1 1 0' * 0.20 * mySize_y, panel_fg_alpha, DRAWFLAG_NORMAL);
		s = sprintf(_("^1PENALTY: %.1f (%s)"), 2, "missing a checkpoint");
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
				s = sprintf(_("^1PENALTY: %.1f (%s)"), race_penaltytime * 0.1, race_penaltyreason);
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
					s = sprintf(_("^1PENALTY: %.1f (%s)"), (t - time) * 0.1, race_penaltyreason);
				else
					s = sprintf(_("^2PENALTY: %.1f (%s)"), 0, race_penaltyreason);
				drawcolorcodedstring(pos + eX * 0.5 * mySize_x - '0.5 0 0' * stringwidth(s, TRUE, '1 1 0' * 0.2 * mySize_y) + eY * 0.6 * mySize_y, s, '1 1 0' * 0.2 * mySize_y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}
	}
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
	if(autocvar_cl_allow_uid2name == -1 && (gametype == GAME_CTS || gametype == GAME_RACE || (serverflags & SERVERFLAG_PLAYERSTATS)))
	{
		vote_active = 1;
		if (autocvar__hud_configure)
		{
			vote_yescount = 0;
			vote_nocount = 0;
			print(_("^1You must answer before entering hud configure mode\n"));
			cvar_set("_hud_configure", "0");
		}
		if(vote_called_vote)
			strunzone(vote_called_vote);
		vote_called_vote = strzone(_("^2Name ^7instead of \"^1Anonymous player^7\" in stats"));
		uid2name_dialog = 1;
	}

	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_vote) return;

		panel_fg_alpha = autocvar_hud_panel_fg_alpha;
		panel_bg_alpha_str = autocvar_hud_panel_vote_bg_alpha;

		if(panel_bg_alpha_str == "") {
			panel_bg_alpha_str = ftos(autocvar_hud_panel_bg_alpha);
		}
		panel_bg_alpha = stof(panel_bg_alpha_str);
	}
	else
	{
		hud_configure_active_panel = HUD_PANEL_VOTE;

		vote_yescount = 3;
		vote_nocount = 2;
		vote_needed = 4;
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

	if(!vote_alpha)
		return;

	HUD_Panel_UpdateCvars(vote);
	HUD_Panel_ApplyFadeAlpha();

	if(uid2name_dialog)
	{
		panel_pos = eX * 0.3 * vid_conwidth + eY * 0.1 * vid_conheight;
		panel_size = eX * 0.4 * vid_conwidth + eY * 0.3 * vid_conheight;
	}

    // these must be below above block
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	a = vote_alpha * (vote_highlighted ? autocvar_hud_panel_vote_alreadyvoted_alpha : 1);
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

	s = _("A vote has been called for:");
	if(uid2name_dialog)
		s = _("Allow servers to store and display your name?");
	drawstring_aspect(pos, s, eX * mySize_x + eY * (2/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);
	s = textShortenToWidth(vote_called_vote, mySize_x, '1 1 0' * mySize_y * (1/8), stringwidth_colors);
	if(autocvar__hud_configure)
		s = _("^1Configure the HUD");
	drawcolorcodedstring_aspect(pos + eY * (2/8) * mySize_y, s, eX * mySize_x + eY * (1.75/8) * mySize_y, a, DRAWFLAG_NORMAL);

	// print the yes/no counts
    s = sprintf(_("Yes (%s): %d"), getcommandkey("vyes", "vyes"), vote_yescount);
	drawstring_aspect(pos + eY * (4/8) * mySize_y, s, eX * 0.5 * mySize_x + eY * (1.5/8) * mySize_y, '0 1 0', a, DRAWFLAG_NORMAL);
    s = sprintf(_("No (%s): %d"), getcommandkey("vno", "vno"), vote_nocount);
	drawstring_aspect(pos + eX * 0.5 * mySize_x + eY * (4/8) * mySize_y, s, eX * 0.5 * mySize_x + eY * (1.5/8) * mySize_y, '1 0 0', a, DRAWFLAG_NORMAL);

	// draw the progress bar backgrounds
	drawpic_skin(pos + eY * (5/8) * mySize_y, "voteprogress_back", eX * mySize_x + eY * (3/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);

	// draw the highlights
	if(vote_highlighted == 1) {
		drawsetcliparea(pos_x, pos_y, mySize_x * 0.5, mySize_y);
		drawpic_skin(pos + eY * (5/8) * mySize_y, "voteprogress_voted", eX * mySize_x + eY * (3/8) * mySize_y, '1 1 1', a, DRAWFLAG_NORMAL);
	}
	else if(vote_highlighted == -1) {
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
					drawpic_aspect_skin(pa, "kh_redarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% theAlpha key
					break;
				case COLOR_TEAM2:
					drawpic_aspect_skin(pa, "kh_bluearrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% theAlpha key
					break;
				case COLOR_TEAM3:
					drawpic_aspect_skin(pa, "kh_yellowarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% theAlpha key
					break;
				case COLOR_TEAM4:
					drawpic_aspect_skin(pa, "kh_pinkarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% theAlpha key
					break;
				default:
					break;
			}
			switch(i) // YAY! switch(i) inside a for loop for i. DailyWTF, here we come!
			{
				case 0:
					drawpic_aspect_skin(p, "kh_red", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% theAlpha key
					break;
				case 1:
					drawpic_aspect_skin(p, "kh_blue", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% theAlpha key
					break;
				case 2:
					drawpic_aspect_skin(p, "kh_yellow", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% theAlpha key
					break;
				case 3:
					drawpic_aspect_skin(p, "kh_pink", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% theAlpha key
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
	
	vector kaball_pos, kaball_size;
	
	if(mySize_x > mySize_y) {
		kaball_pos = pos + eX * 0.25 * mySize_x;
		kaball_size = eX * 0.5 * mySize_x + eY * mySize_y;
	} else {
		kaball_pos = pos + eY * 0.25 * mySize_y;
		kaball_size = eY * 0.5 * mySize_y + eX * mySize_x;
	}
	
	float kaball_statuschange_elapsedtime = time - kaball_statuschange_time;
	float f = bound(0, kaball_statuschange_elapsedtime*2, 1);
	
	if(kaball_prevstatus && f < 1)
		drawpic_aspect_skin_expanding(kaball_pos, "keepawayball_carrying", kaball_size, '1 1 1', panel_fg_alpha * kaball_alpha, DRAWFLAG_NORMAL, f);
	
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
		HUD_Panel_GetProgressBarColor(nexball);
		if(mySize_x > mySize_y)
			HUD_Panel_DrawProgressBar(pos, mySize, "progressbar", p, 0, 0, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
		else
			HUD_Panel_DrawProgressBar(pos, mySize, "progressbar", p, 1, 0, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
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
	me = playerslots[player_localnum];
	float t, score;
	float f; // yet another function has this
	score = me.(scores[ps_primary]);

	if not((scores_flags[ps_primary] & SFL_TIME) && !teamplay) // race/cts record display on HUD
		return; // no records in the actual race

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
		drawstring_aspect(textPos, _("Personal best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	} else {
		drawstring_aspect(textPos, _("Personal best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.25 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect_expanding(pos, _("Personal best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
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
		drawstring_aspect(textPos + eY * 0.5 * squareSize, _("Server best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	} else {
		drawstring_aspect(textPos + eY * 0.5 * squareSize, _("Server best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(textPos + eY * 0.75 * squareSize, TIME_ENCODED_TOSTRING(t), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect_expanding(textPos + eY * 0.5 * squareSize, _("Server best"), eX * squareSize + eY * 0.25 * squareSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
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
		if(race_status_name == GetPlayerName(player_localnum) || !race_myrank || race_myrank < rank)
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
}

void DrawDomItem(vector myPos, vector mySize, float aspect_ratio, float layout, float i)
{
	float stat, pps_ratio;
	string pic;
	vector color;
	switch(i)
	{
		case 0:
			stat = getstatf(STAT_DOM_PPS_RED);
			pic = "dom_icon_red";
			color = '1 0 0';
			break;
		case 1:
			stat = getstatf(STAT_DOM_PPS_BLUE);
			pic = "dom_icon_blue";
			color = '0 0 1';
			break;
		case 2:
			stat = getstatf(STAT_DOM_PPS_YELLOW);
			pic = "dom_icon_yellow";
			color = '1 1 0';
			break;
		case 3:
			stat = getstatf(STAT_DOM_PPS_PINK);
			pic = "dom_icon_pink";
			color = '1 0 1';
	}
	pps_ratio = stat / getstatf(STAT_DOM_TOTAL_PPS);

	if(mySize_x/mySize_y > aspect_ratio)
	{
		i = aspect_ratio * mySize_y;
		myPos_x = myPos_x + (mySize_x - i) / 2;
		mySize_x = i;
	}
	else
	{
		i = 1/aspect_ratio * mySize_x;
		myPos_y = myPos_y + (mySize_y - i) / 2;
		mySize_y = i;
	}

	if (layout) // show text too
	{
		//draw the text
		color *= 0.5 + pps_ratio * (1 - 0.5); // half saturated color at min, full saturated at max
		if (layout == 2) // average pps
			drawstring_aspect(myPos + eX * mySize_y, ftos_decimals(stat, 2), eX * (2/3) * mySize_x + eY * mySize_y, color, panel_fg_alpha, DRAWFLAG_NORMAL);
		else // percentage of average pps
			drawstring_aspect(myPos + eX * mySize_y, strcat( ftos(floor(pps_ratio*100 + 0.5)), "%" ), eX * (2/3) * mySize_x + eY * mySize_y, color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	//draw the icon
	drawpic_aspect_skin(myPos, pic, '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (stat > 0)
	{
		drawsetcliparea(myPos_x, myPos_y + mySize_y * (1 - pps_ratio), mySize_y, mySize_y * pps_ratio);
		drawpic_aspect_skin(myPos, strcat(pic, "-highlighted"), '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawresetcliparea();
	}
}

void HUD_Mod_Dom(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something
	entity tm;
	float teams_count;
	for(tm = teams.sort_next; tm; tm = tm.sort_next)
		if(tm.team != COLOR_SPECTATOR)
			++teams_count;

	float layout = autocvar_hud_panel_modicons_dom_layout;
	float rows, columns, aspect_ratio;
	rows = mySize_y/mySize_x;
	aspect_ratio = (layout) ? 3 : 1;
	rows = bound(1, floor((sqrt((4 * aspect_ratio * teams_count + rows) * rows) + rows + 0.5) / 2), teams_count);
	columns = ceil(teams_count/rows);

	int i;
	float row, column;
	for(i=0; i<teams_count; ++i)
	{
		vector pos, itemSize;
		pos = myPos + eX * column * mySize_x*(1/columns) + eY * row * mySize_y*(1/rows);
		itemSize = eX * mySize_x*(1/columns) + eY * mySize_y*(1/rows);

		DrawDomItem(pos, itemSize, aspect_ratio, layout, i);

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}
}

float mod_prev; // previous state of mod_active to check for a change
float mod_alpha;
float mod_change; // "time" when mod_active changed

void HUD_ModIcons(void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_modicons) return;
		if (gametype != GAME_CTF && gametype != GAME_KEYHUNT && gametype != GAME_NEXBALL && gametype != GAME_CTS && gametype != GAME_RACE && gametype != GAME_CA && gametype != GAME_FREEZETAG && gametype != GAME_KEEPAWAY && gametype != GAME_DOMINATION) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_MODICONS;

	HUD_Panel_UpdateCvars(modicons);
	HUD_Panel_ApplyFadeAlpha();
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
	else if(gametype == GAME_DOMINATION)
		HUD_Mod_Dom(pos, mySize);
	else if(gametype == GAME_KEEPAWAY)
		HUD_Mod_Keepaway(pos, mySize);
}

// Draw pressed keys (#11)
//
void HUD_DrawPressedKeys(void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_pressedkeys) return;
		if(spectatee_status <= 0 && autocvar_hud_panel_pressedkeys < 2) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_PRESSEDKEYS;


	HUD_Panel_UpdateCvars(pressedkeys);
	HUD_Panel_ApplyFadeAlpha();
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
	drawpic_aspect_skin(pos + eX * keysize_x, ((pressedkeys & KEY_FORWARD) ? "key_forward_inv.tga" : "key_forward.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * keysize_x * 2, ((pressedkeys & KEY_JUMP) ? "key_jump_inv.tga" : "key_jump.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos_y += keysize_y;
	drawpic_aspect_skin(pos, ((pressedkeys & KEY_LEFT) ? "key_left_inv.tga" : "key_left.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * keysize_x, ((pressedkeys & KEY_BACKWARD) ? "key_backward_inv.tga" : "key_backward.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos + eX * keysize_x * 2, ((pressedkeys & KEY_RIGHT) ? "key_right_inv.tga" : "key_right.tga"), keysize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Handle chat as a panel (#12)
//
void HUD_Chat(void)
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
			if(!hud_draw_maximized) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_CHAT;

	HUD_Panel_UpdateCvars(chat);
	HUD_Panel_ApplyFadeAlpha();

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

	cvar_set("con_chatrect_x", ftos(pos_x/vid_conwidth));
	cvar_set("con_chatrect_y", ftos(pos_y/vid_conheight));

	cvar_set("con_chatwidth", ftos(mySize_x/vid_conwidth));
	cvar_set("con_chat", ftos(floor(mySize_y/autocvar_con_chatsize - 0.5)));

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
			drawcolorcodedstring(pos, textShortenToWidth(_("^3Player^7: This is the chat area."), mySize_x, chatsize, stringwidth_colors), chatsize, a, DRAWFLAG_NORMAL);
			pos_y += chatsize_y;
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
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_engineinfo) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_ENGINEINFO;

	HUD_Panel_UpdateCvars(engineinfo);
	HUD_Panel_ApplyFadeAlpha();
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
	drawstring_aspect(pos, sprintf(_("FPS: %.*f"), autocvar_hud_panel_engineinfo_framecounter_decimals, prevfps), mySize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
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
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_infomessages) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_INFOMESSAGES;

	HUD_Panel_UpdateCvars(infomessages);
	HUD_Panel_ApplyFadeAlpha();
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
	a = panel_fg_alpha;

	string s;
	if(!autocvar__hud_configure)
	{
		if(spectatee_status && !intermission)
		{
			a = 1;
			if(spectatee_status == -1)
				s = _("^1Observing");
			else
#ifdef COMPAT_XON050_ENGINE
				s = sprintf(_("^1Spectating: ^7%s"), GetPlayerName(spectatee_status - 1));
#else
				s = sprintf(_("^1Spectating: ^7%s"), GetPlayerName(player_localentnum - 1));
#endif
			drawInfoMessage(s)

			if(spectatee_status == -1)
				s = sprintf(_("^1Press ^3%s^1 to spectate"), getcommandkey("primary fire", "+fire"));
			else
				s = sprintf(_("^1Press ^3%s^1 for another player"), getcommandkey("primary fire", "+fire"));
			drawInfoMessage(s)

			if(spectatee_status == -1)
				s = sprintf(_("^1Use ^3%s^1 or ^3%s^1 to change the speed"), getcommandkey("next weapon", "weapnext"), getcommandkey("previous weapon", "weapprev"));
			else
				s = sprintf(_("^1Press ^3%s^1 to observe"), getcommandkey("secondary fire", "+fire2"));
			drawInfoMessage(s)

			s = sprintf(_("^1Press ^3%s^1 for gamemode info"), getcommandkey("server info", "+show_info"));
			drawInfoMessage(s)

			if(gametype == GAME_ARENA)
				s = _("^1Wait for your turn to join");
			else if(gametype == GAME_LMS)
			{
				entity sk;
				sk = playerslots[player_localnum];
				if(sk.(scores[ps_primary]) >= 666)
					s = _("^1Match has already begun");
				else if(sk.(scores[ps_primary]) > 0)
					s = _("^1You have no more lives left");
				else
					s = sprintf(_("^1Press ^3%s^1 to join"), getcommandkey("jump", "+jump"));
			}
			else
				s = sprintf(_("^1Press ^3%s^1 to join"), getcommandkey("jump", "+jump"));
			drawInfoMessage(s)

			//show restart countdown:
			if (time < getstatf(STAT_GAMESTARTTIME)) {
				float countdown;
				//we need to ceil, otherwise the countdown would be off by .5 when using round()
				countdown = ceil(getstatf(STAT_GAMESTARTTIME) - time);
				s = sprintf(_("^1Game starts in ^3%d^1 seconds"), countdown);
				drawcolorcodedstring(o, s, fontsize, a, DRAWFLAG_NORMAL);
				o_y += fontsize_y;
			}
		}
		if(warmup_stage && !intermission)
		{
			s = _("^2Currently in ^1warmup^2 stage!");
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
					s = sprintf(_("%sPress ^3%s%s to end warmup"), blinkcolor, getcommandkey("ready", "ready"), blinkcolor);
				else
					s = sprintf(_("%sPress ^3%s%s once you are ready"), blinkcolor, getcommandkey("ready", "ready"), blinkcolor);
			}
			else
			{
				if(warmup_stage)
					s = _("^2Waiting for others to ready up to end warmup...");
				else
					s = _("^2Waiting for others to ready up...");
			}
			drawInfoMessage(s)
		}
		else if(warmup_stage && !intermission && !spectatee_status)
		{
			s = sprintf(_("^2Press ^3%s^2 to end warmup"), getcommandkey("ready", "ready"));
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
					s = strcat(blinkcolor, _("Teamnumbers are unbalanced!"));
					tm = GetTeam(myteam, false);
					if (tm)
					if (tm.team != COLOR_SPECTATOR)
					if (tm.team_size == ts_max)
						s = strcat(s, sprintf(_(" Press ^3%s%s to adjust"), getcommandkey("team menu", "menu_showteamselect"), blinkcolor));
					drawInfoMessage(s)
				}
			}
		}
	}
	else 
	{
		s = _("^7Press ^3ESC ^7to show HUD options.");
		drawInfoMessage(s)
		s = _("^3Doubleclick ^7a panel for panel-specific options.");
		drawInfoMessage(s)
		s = _("^3CTRL ^7to disable collision testing, ^3SHIFT ^7and");
		drawInfoMessage(s)
		s = _("^3ALT ^7+ ^3ARROW KEYS ^7for fine adjustments.");
		drawInfoMessage(s)
	}
}

// Physics panel (#15)
//
vector acc_prevspeed;
float acc_prevtime, acc_avg, top_speed, top_speed_time;
void HUD_Physics(void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_physics) return;
		if(spectatee_status == -1 && (autocvar_hud_panel_physics == 1 || autocvar_hud_panel_physics == 3)) return;
		if(autocvar_hud_panel_physics == 3 && !(gametype == GAME_RACE || gametype == GAME_CTS)) return;
	}
	else
		hud_configure_active_panel = HUD_PANEL_PHYSICS;

	HUD_Panel_UpdateCvars(physics);
	HUD_Panel_ApplyFadeAlpha();

	HUD_Panel_DrawBg(1);
	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	//compute speed
	float speed, conversion_factor;
	string unit;

	switch(autocvar_hud_panel_physics_speed_unit)
	{
		default:
		case 1:
			unit = _(" qu/s");
			conversion_factor = 1.0;
			break;
		case 2:
			unit = _(" m/s");
			conversion_factor = 0.0254;
			break;
		case 3:
			unit = _(" km/h");
			conversion_factor = 0.0254 * 3.6;
			break;
		case 4:
			unit = _(" mph");
			conversion_factor = 0.0254 * 3.6 * 0.6213711922;
			break;
		case 5:
			unit = _(" knots");
			conversion_factor = 0.0254 * 1.943844492; // 1 m/s = 1.943844492 knots, because 1 knot = 1.852 km/h
			break;
	}

	float max_speed = floor( autocvar_hud_panel_physics_speed_max * conversion_factor + 0.5 );
	if (autocvar__hud_configure)
		speed = floor( max_speed * 0.65 + 0.5 );
	else if(autocvar_hud_panel_physics_speed_vertical)
		speed = floor( vlen(pmove_vel) * conversion_factor + 0.5 );
	else
		speed = floor( vlen(pmove_vel - pmove_vel_z * '0 0 1') * conversion_factor + 0.5 );

	//compute acceleration
	float acceleration, f;
	if (autocvar__hud_configure)
		acceleration = autocvar_hud_panel_physics_acceleration_max * 0.3;
	else
	{
		// 1 m/s = 0.0254 qu/s; 1 g = 9.80665 m/s^2
		f = time - acc_prevtime;
		if(autocvar_hud_panel_physics_acceleration_vertical)
			acceleration = (vlen(pmove_vel) - vlen(acc_prevspeed)) * (1 / f) * (0.0254 / 9.80665);
		else
			acceleration = (vlen(pmove_vel - '0 0 1' * pmove_vel_z) - vlen(acc_prevspeed - '0 0 1' * acc_prevspeed_z)) * (1 / f) * (0.0254 / 9.80665);
		acc_prevspeed = pmove_vel;
		acc_prevtime = time;

		f = bound(0, f * 10, 1);
		acc_avg = acc_avg * (1 - f) + acceleration * f;
	}

	//compute layout
	float panel_ar = panel_size_x/panel_size_y;
	vector speed_offset, acceleration_offset;
	if (panel_ar >= 5)
	{
		panel_size_x *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset_x = panel_size_x;
		else
			acceleration_offset_x = panel_size_x;
	}
	else
	{
		panel_size_y *= 0.5;
		if (autocvar_hud_panel_physics_flip)
			speed_offset_y = panel_size_y;
		else
			acceleration_offset_y = panel_size_y;
	}
	float speed_baralign, acceleration_baralign;
	if (autocvar_hud_panel_physics_baralign == 1)
		acceleration_baralign = speed_baralign = 1;
    else if(autocvar_hud_panel_physics_baralign == 4)
		acceleration_baralign = speed_baralign = 2;
	else if (autocvar_hud_panel_physics_flip)
	{
		acceleration_baralign = (autocvar_hud_panel_physics_baralign == 2);
		speed_baralign = (autocvar_hud_panel_physics_baralign == 3);
	}
	else
	{
		speed_baralign = (autocvar_hud_panel_physics_baralign == 2);
		acceleration_baralign = (autocvar_hud_panel_physics_baralign == 3);
	}
	if (autocvar_hud_panel_physics_acceleration_mode == 0)
		acceleration_baralign = 3; //override hud_panel_physics_baralign value for acceleration

	//draw speed
	if(speed)
	if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 2)
	{
		HUD_Panel_GetProgressBarColor(speed);
		HUD_Panel_DrawProgressBar(panel_pos + speed_offset, panel_size, "progressbar", speed/max_speed, 0, speed_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	vector tmp_offset, tmp_size;
	if (autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 2)
	{
		tmp_size_x = panel_size_x * 0.75;
		tmp_size_y = panel_size_y;
		if (speed_baralign)
			tmp_offset_x = panel_size_x - tmp_size_x;
		//else
			//tmp_offset_x = 0;
		drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(speed), tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

		//draw speed unit
		if (speed_baralign)
			tmp_offset_x = 0;
		else
			tmp_offset_x = tmp_size_x;
		if (autocvar_hud_panel_physics_speed_unit_show)
		{
			//tmp_offset_y = 0;
			tmp_size_x = panel_size_x * (1 - 0.75);
			tmp_size_y = panel_size_y * 0.4;
			drawstring_aspect(panel_pos + speed_offset + tmp_offset, unit, tmp_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}

	//compute and draw top speed
	if (autocvar_hud_panel_physics_topspeed)
	if (autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 2)
	{
		if (autocvar__hud_configure)
		{
			top_speed = floor( max_speed * 0.75 + 0.5 );
			f = 1;
		}
		else
		{
			if (speed >= top_speed)
			{
				top_speed = speed;
				top_speed_time = time;
			}
			if (top_speed != 0)
			{
				f = max(1, autocvar_hud_panel_physics_topspeed_time);
				// divide by f to make it start from 1
				f = cos( ((time - top_speed_time) / f) * PI/2 );
			}
            else //hide top speed 0, it would be stupid
				f = 0;
		}
		if (f > 0)
		{
			//top speed progressbar peak
			if(speed < top_speed)
			if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 2)
			{
				float peak_offset_x;
				vector peak_size;
				if (speed_baralign == 0)
					peak_offset_x = min(top_speed, max_speed)/max_speed * panel_size_x;
                else if (speed_baralign == 1)
					peak_offset_x = (1 - min(top_speed, max_speed)/max_speed) * panel_size_x;
                else if (speed_baralign == 2)
                    peak_offset_x = min(top_speed, max_speed)/max_speed * panel_size_x * 0.5;
				//if speed is not 0 the speed progressbar already fetched the color
				if (speed == 0)
					HUD_Panel_GetProgressBarColor(speed);
				peak_size_x = floor(panel_size_x * 0.01 + 1.5);
                peak_size_y = panel_size_y;
                if (speed_baralign == 2) // draw two peaks, on both sides
                {
                    drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size_x + peak_offset_x - peak_size_x), peak_size, progressbar_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                    drawfill(panel_pos + speed_offset + eX * (0.5 * panel_size_x - peak_offset_x + peak_size_x), peak_size, progressbar_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
                }
                else
                    drawfill(panel_pos + speed_offset + eX * (peak_offset_x - peak_size_x), peak_size, progressbar_color, f * autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			}

			//top speed
			tmp_offset_y = panel_size_y * 0.4;
			tmp_size_x = panel_size_x * (1 - 0.75);
			tmp_size_y = panel_size_y - tmp_offset_y;
			drawstring_aspect(panel_pos + speed_offset + tmp_offset, ftos(top_speed), tmp_size, '1 0 0', f * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		else
			top_speed = 0;
	}

	//draw acceleration
	if(acceleration)
	if(autocvar_hud_panel_physics_progressbar == 1 || autocvar_hud_panel_physics_progressbar == 3)
	{
		if (acceleration < 0)
			HUD_Panel_GetProgressBarColor(acceleration_neg);
		else
			HUD_Panel_GetProgressBarColor(acceleration);
		HUD_Panel_DrawProgressBar(panel_pos + acceleration_offset, panel_size, "accelbar", acceleration/autocvar_hud_panel_physics_acceleration_max, 0, acceleration_baralign, progressbar_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	if (autocvar_hud_panel_physics_text == 1 || autocvar_hud_panel_physics_text == 3)
		drawstring_aspect(panel_pos + acceleration_offset, strcat(ftos_decimals(acceleration, 2), "g"), panel_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}

// CenterPrint (#16)
//
#define CENTERPRINT_MAX_MSGS 10
#define CENTERPRINT_MAX_ENTRIES 50
#define CENTERPRINT_SPACING 0.7
float cpm_index;
string centerprint_messages[CENTERPRINT_MAX_MSGS];
float centerprint_msgID[CENTERPRINT_MAX_MSGS];
float centerprint_time[CENTERPRINT_MAX_MSGS];
float centerprint_expire_time[CENTERPRINT_MAX_MSGS];
float centerprint_countdown_num[CENTERPRINT_MAX_MSGS];
float centerprint_showing;

void centerprint_generic(float new_id, string strMessage, float duration, float countdown_num)
{
	float i, j;

	if(strMessage == "" && new_id == 0)
		return;

	// strip trailing newlines
	j = strlen(strMessage) - 1;
	while(substring(strMessage, j, 1) == "\n" && j >= 0)
		--j;
	if (j < strlen(strMessage) - 1)
		strMessage = substring(strMessage, 0, j + 1);

	if(strMessage == "" && new_id == 0)
		return;

	// strip leading newlines
	j = 0;
	while(substring(strMessage, j, 1) == "\n" && j < strlen(strMessage))
		++j;
	if (j > 0)
		strMessage = substring(strMessage, j, strlen(strMessage) - j);

	if(strMessage == "" && new_id == 0)
		return;

	if (!centerprint_showing)
		centerprint_showing = TRUE;

	for (i=0, j=cpm_index; i<CENTERPRINT_MAX_MSGS; ++i, ++j)
	{
		if (j == CENTERPRINT_MAX_MSGS)
			j = 0;
		if (new_id && new_id == centerprint_msgID[j])
		{
			if (strMessage == "" && centerprint_messages[j] != "" && centerprint_countdown_num[j] == 0)
			{
				// fade out the current msg (duration and countdown_num are ignored)
				centerprint_time[j] = min(5, autocvar_hud_panel_centerprint_fade_out);
				if (centerprint_expire_time[j] > time + min(5, autocvar_hud_panel_centerprint_fade_out) || centerprint_expire_time[j] < time)
					centerprint_expire_time[j] = time + min(5, autocvar_hud_panel_centerprint_fade_out);
				return;
			}
			break; // found a msg with the same id, at position j
		}
	}

	if (i == CENTERPRINT_MAX_MSGS)
	{
		// a msg with the same id was not found, add the msg at the next position
		--cpm_index;
		if (cpm_index == -1)
			cpm_index = CENTERPRINT_MAX_MSGS - 1;
		j = cpm_index;
	}
	if(centerprint_messages[j])
		strunzone(centerprint_messages[j]);
	centerprint_messages[j] = strzone(strMessage);
	centerprint_msgID[j] = new_id;
	if (duration < 0)
		centerprint_time[j] = -1;
	else
	{
		if(duration == 0)
			duration = max(1, autocvar_hud_panel_centerprint_time);
		centerprint_time[j] = duration;
		centerprint_expire_time[j] = time + duration;
	}
	centerprint_countdown_num[j] = countdown_num;
}

void centerprint_hud(string strMessage)
{
	centerprint_generic(0, strMessage, autocvar_hud_panel_centerprint_time, 0);
}

void reset_centerprint_messages(void)
{
	float i;
	for (i=0; i<CENTERPRINT_MAX_MSGS; ++i)
	{
		centerprint_expire_time[i] = 0;
		centerprint_time[i] = 1;
		centerprint_msgID[i] = 0;
		if(centerprint_messages[i])
			strunzone(centerprint_messages[i]);
		centerprint_messages[i] = string_null;
	}
}
float hud_configure_cp_generation_time;
void HUD_CenterPrint (void)
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_centerprint) return;

		if (hud_configure_prev && hud_configure_prev != -1)
			reset_centerprint_messages();
	}
	else
	{
		hud_configure_active_panel = HUD_PANEL_CENTERPRINT;

		if (!hud_configure_prev)
			reset_centerprint_messages();
		if (time > hud_configure_cp_generation_time)
		{
			float r;
			r = random();
			if (r > 0.9)
				centerprint_generic(floor(r*1000), strcat(sprintf("^3Countdown message at time %s", seconds_tostring(time)), ", seconds left: %d"), 1, 10);
			else if (r > 0.8)
				centerprint_generic(0, sprintf("^1Multiline message at time %s that\n^1lasts longer than normal", seconds_tostring(time)), 20, 0);
			else
				centerprint_hud(sprintf("Message at time %s", seconds_tostring(time)));
			hud_configure_cp_generation_time = time + 1 + random()*4;
		}
	}

	HUD_Panel_UpdateCvars(centerprint);

	// this panel doesn't fade when showing the scoreboard
	if(autocvar__menu_alpha)
		HUD_Panel_ApplyFadeAlpha();

	if(scoreboard_fade_alpha)
	{
		// move the panel below the scoreboard
		if (scoreboard_bottom >= 0.96 * vid_conheight)
			return;
		vector target_pos;
		
		target_pos = eY * scoreboard_bottom + eX * 0.5 * (vid_conwidth - panel_size_x);
		
		if(target_pos_y > panel_pos_y)
		{
			panel_pos = panel_pos + (target_pos - panel_pos) * sqrt(scoreboard_fade_alpha);
			panel_size_y = min(panel_size_y, vid_conheight - scoreboard_bottom);
		}
	}

	HUD_Panel_DrawBg(1);

	if (!centerprint_showing)
		return;

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	float entries, height;
	vector fontsize;
	// entries = bound(1, floor(CENTERPRINT_MAX_ENTRIES * 4 * panel_size_y/panel_size_x), CENTERPRINT_MAX_ENTRIES);
	// height = panel_size_y/entries;
	// fontsize = '1 1 0' * height;
	height = vid_conheight/50 * autocvar_hud_panel_centerprint_fontscale;
	fontsize = '1 1 0' * height;
	entries = bound(1, floor(panel_size_y/height), CENTERPRINT_MAX_ENTRIES);

	float i, j, k, n;
	float a, sz, align, current_msg_pos_y, msg_size;
	vector pos;
	string ts;

	n = -1; // if no msg will be displayed, n stays -1

	pos = panel_pos;
	if (autocvar_hud_panel_centerprint_flip)
		pos_y += panel_size_y;
	align = bound(0, autocvar_hud_panel_centerprint_align, 1);
	for (i=0, j=cpm_index; i<CENTERPRINT_MAX_MSGS; ++i, ++j)
	{
		if (j == CENTERPRINT_MAX_MSGS)
			j = 0;
		if (centerprint_expire_time[j] <= time)
		{
			if (centerprint_countdown_num[j] && centerprint_time[j] > 0)
			{
				centerprint_countdown_num[j] = centerprint_countdown_num[j] - 1;
				if (centerprint_countdown_num[j] == 0)
					continue;
				centerprint_expire_time[j] = centerprint_expire_time[j] + centerprint_time[j];
			}
			else
				continue;
		}
		
		// fade the centerprint_hud in/out 
		if (centerprint_time[j] < 0 || centerprint_expire_time[j] - autocvar_hud_panel_centerprint_fade_out > time)
			a = bound(0, (time - (centerprint_expire_time[j] - centerprint_time[j])) / max(0.0001, autocvar_hud_panel_centerprint_fade_in), 1);
		else if (centerprint_expire_time[j] > time)
			a = (centerprint_expire_time[j] - time) / max(0.0001, autocvar_hud_panel_centerprint_fade_out);
		
		// set the size from fading in/out before subsequent fading
		sz = autocvar_hud_panel_centerprint_fade_minfontsize + a * (1 - autocvar_hud_panel_centerprint_fade_minfontsize); 
		
		// also fade it based on positioning
		if(autocvar_hud_panel_centerprint_fade_subsequent)
		{
			a = a * bound(autocvar_hud_panel_centerprint_fade_subsequent_passone_minalpha, (1 - (i / max(1, autocvar_hud_panel_centerprint_fade_subsequent_passone))), 1); // pass one: all messages after the first have half theAlpha
			a = a * bound(autocvar_hud_panel_centerprint_fade_subsequent_passtwo_minalpha, (1 - (i / max(1, autocvar_hud_panel_centerprint_fade_subsequent_passtwo))), 1); // pass two: after that, gradually lower theAlpha even more for each message
		}
		
		// finally set the size based on the new theAlpha from subsequent fading
		sz = sz * (autocvar_hud_panel_centerprint_fade_subsequent_minfontsize + a * (1 - autocvar_hud_panel_centerprint_fade_subsequent_minfontsize)); 
		drawfontscale = sz * '1 1 0';
		
		if (centerprint_countdown_num[j])
			n = tokenizebyseparator(sprintf(centerprint_messages[j], centerprint_countdown_num[j]), "\n");
		else
			n = tokenizebyseparator(centerprint_messages[j], "\n");

		if (autocvar_hud_panel_centerprint_flip)
		{
			// check if the message can be entirely shown
			for(k = 0; k < n; ++k)
			{
				getWrappedLine_remaining = argv(k);
				while(getWrappedLine_remaining)
				{
					ts = getWrappedLine(panel_size_x * sz, fontsize, stringwidth_colors);
					if (ts != "")
						pos_y -= fontsize_y;
					else
						pos_y -= fontsize_y * CENTERPRINT_SPACING/2;
				}
			}
			current_msg_pos_y = pos_y; // save starting pos (first line) of the current message
		}

		msg_size = pos_y;
		for(k = 0; k < n; ++k)
		{
			getWrappedLine_remaining = argv(k);
			while(getWrappedLine_remaining)
			{
				ts = getWrappedLine(panel_size_x * sz, fontsize, stringwidth_colors);
				if (ts != "")
				{
					if (align)
						pos_x = panel_pos_x + (panel_size_x - stringwidth(ts, TRUE, fontsize)) * align;
					drawcolorcodedstring(pos + eY * 0.5 * (1 - sz) * fontsize_y, ts, fontsize, a * panel_fg_alpha, DRAWFLAG_NORMAL);
					pos_y += fontsize_y;
				}
				else
					pos_y += fontsize_y * CENTERPRINT_SPACING/2;
			}
		}
		msg_size = pos_y - msg_size;
		if (autocvar_hud_panel_centerprint_flip)
		{
			pos_y = current_msg_pos_y - CENTERPRINT_SPACING * fontsize_y;
			if (a < 1 && centerprint_msgID[j] == 0) // messages with id can be replaced just after they are faded out, so never move over them the next messages
				pos_y += (msg_size + CENTERPRINT_SPACING * fontsize_y) * (1 - sqrt(sz));
				
			if (pos_y < panel_pos_y) // check if the next message can be shown
			{
				drawfontscale = '1 1 0';
				return;
			}
		}
		else
		{
			pos_y += CENTERPRINT_SPACING * fontsize_y;
			if (a < 1 && centerprint_msgID[j] == 0) // messages with id can be replaced just after they are faded out, so never move over them the next messages
				pos_y -= (msg_size + CENTERPRINT_SPACING * fontsize_y) * (1 - sqrt(sz));
				
			if(pos_y > panel_pos_y + panel_size_y - fontsize_y) // check if the next message can be shown
			{
				drawfontscale = '1 1 0';
				return;
			}
		}
	}
	drawfontscale = '1 1 0';
	if (n == -1)
	{
		centerprint_showing = FALSE;
		reset_centerprint_messages();
	}
}

/*
==================
Main HUD system
==================
*/

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
	case (HUD_PANEL_PHYSICS):\
		 HUD_Physics(); break;\
	case (HUD_PANEL_CENTERPRINT):\
		 HUD_CenterPrint(); break;\
} ENDS_WITH_CURLY_BRACE

void HUD_Main (void)
{
	float i;
	// global hud theAlpha fade
	if(menu_enabled == 1)
		hud_fade_alpha = 1;
	else
		hud_fade_alpha = (1 - autocvar__menu_alpha);

	if(scoreboard_fade_alpha)
		hud_fade_alpha = (1 - scoreboard_fade_alpha);

	if(intermission == 2) // no hud during mapvote
	{
		if (autocvar__hud_configure) //force exit from hud config
		{
			if (menu_enabled)
			{
				menu_enabled = 0;
				localcmd("togglemenu\n");
			}
			cvar_set("_hud_configure", "0");
		}
		hud_fade_alpha = 0;
	}
	else if(autocvar__menu_alpha == 0 && scoreboard_fade_alpha == 0)
		hud_fade_alpha = 1;

	// panels that we want to be active together with the scoreboard
	// they must call HUD_Panel_ApplyFadeAlpha(); only when showing the menu
	if(scoreboard_fade_alpha == 1)
	{
		HUD_CenterPrint();
		return;
	}

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
		hud_configure_gridSize_x = bound(0.005, cvar("hud_configure_grid_xsize"), 0.2);
		hud_configure_gridSize_y = bound(0.005, cvar("hud_configure_grid_ysize"), 0.2);
		hud_configure_realGridSize_x = hud_configure_gridSize_x * vid_conwidth;
		hud_configure_realGridSize_y = hud_configure_gridSize_y * vid_conheight;
		// x-axis
		for(i = 0; i < 1/hud_configure_gridSize_x; ++i)
			drawfill(eX * i * hud_configure_realGridSize_x, eX + eY * vid_conheight, '0.5 0.5 0.5', autocvar_hud_configure_grid_alpha, DRAWFLAG_NORMAL);
		// y-axis
		for(i = 0; i < 1/hud_configure_gridSize_y; ++i)
			drawfill(eY * i * hud_configure_realGridSize_y, eY + eX * vid_conwidth, '0.5 0.5 0.5', autocvar_hud_configure_grid_alpha, DRAWFLAG_NORMAL);
	}

#ifdef COMPAT_XON050_ENGINE
    current_player = (spectatee_status > 0) ? spectatee_status : player_localentnum;
#else
    current_player = player_localentnum;
#endif

	// draw the dock
	if(autocvar_hud_dock != "" && autocvar_hud_dock != "0")
	{
		float f;
		vector color;
		float hud_dock_color_team = autocvar_hud_dock_color_team;
		if((teamplay) && hud_dock_color_team) {
			f = stof(getplayerkeyvalue(current_player - 1, "colors"));
			color = colormapPaletteColor(mod(f, 16), 1) * hud_dock_color_team;
		}
		else if(autocvar_hud_configure_teamcolorforced && autocvar__hud_configure && hud_dock_color_team) {
			color = '1 0 0' * hud_dock_color_team;
		}
		else
		{
			string hud_dock_color = autocvar_hud_dock_color;
			if(hud_dock_color == "shirt") {
				f = stof(getplayerkeyvalue(current_player - 1, "colors"));
				color = colormapPaletteColor(floor(f / 16), 0);
			}
			else if(hud_dock_color == "pants") {
				f = stof(getplayerkeyvalue(current_player - 1, "colors"));
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
		for(i = 0; i < HUD_PANEL_NUM; ++i)
			panel_order[i] = -1;
		string s;
		float p_num, warning;
		float argc = tokenize_console(autocvar__hud_panelorder);
		if (argc > HUD_PANEL_NUM)
			warning = true;
		//first detect wrong/missing panel numbers
		for(i = 0; i < HUD_PANEL_NUM; ++i) {
			p_num = stof(argv(i));
			if (p_num >= 0 && p_num < HUD_PANEL_NUM) { //correct panel number?
				if (panel_order[p_num] == -1) //found for the first time?
					s = strcat(s, ftos(p_num), " ");
				panel_order[p_num] = 1; //mark as found
			}
			else
				warning = true;
		}
		for(i = 0; i < HUD_PANEL_NUM; ++i) {
			if (panel_order[i] == -1) {
				warning = true;
				s = strcat(s, ftos(i), " "); //add missing panel number
			}
		}
		if (warning)
			print(_("Automatically fixed wrong/missing panel numbers in _hud_panelorder\n"));

		cvar_set("_hud_panelorder", s);
		if(hud_panelorder_prev)
			strunzone(hud_panelorder_prev);
		hud_panelorder_prev = strzone(s);

		//now properly set panel_order
		tokenize_console(s);
		for(i = 0; i < HUD_PANEL_NUM; ++i) {
			panel_order[i] = stof(argv(i));
		}
	}

	hud_draw_maximized = 0;
	// draw panels in order specified by panel_order array
	for(i = HUD_PANEL_NUM - 1; i >= 0; --i)
		HUD_DrawPanel(panel_order[i]);

	hud_draw_maximized = 1; // panels that may be maximized must check this var
	// draw maximized panels on top
	if(hud_panel_radar_maximized)
		HUD_Radar();
	if(autocvar__con_chat_maximized)
		HUD_Chat();

	if(autocvar__hud_configure)
	{
		if(tab_panel != -1)
		{
			HUD_Panel_UpdatePosSizeForId(tab_panel)
			drawfill(panel_pos - '1 1 0' * panel_bg_border, panel_size + '2 2 0' * panel_bg_border, '1 1 1', .2, DRAWFLAG_NORMAL);
		}
		if(highlightedPanel != -1)
		{
			HUD_Panel_UpdatePosSizeForId(highlightedPanel);
			HUD_Panel_HlBorder(panel_bg_border + 1.5 * hlBorderSize, '0 0.5 1', 0.25 * (1 - autocvar__menu_alpha));
		}
	}

	hud_configure_prev = autocvar__hud_configure;

	if (!autocvar__hud_configure) // hud config mode disabled, enable normal theAlpha stuff again
		if (menu_enabled)
			menu_enabled = 0;
}
