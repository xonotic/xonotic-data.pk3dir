#include "weapons.qh"

#include <client/draw.qh>
#include <client/view.qh>
#include <common/wepent.qh>

// Weapons (#0)

void HUD_Weapons_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_weapons_accuracy");
	HUD_Write_Cvar("hud_panel_weapons_label");
	HUD_Write_Cvar("hud_panel_weapons_label_scale");
	HUD_Write_Cvar("hud_panel_weapons_complainbubble");
	HUD_Write_Cvar("hud_panel_weapons_complainbubble_padding");
	HUD_Write_Cvar("hud_panel_weapons_complainbubble_time");
	HUD_Write_Cvar("hud_panel_weapons_complainbubble_fadetime");
	HUD_Write_Cvar("hud_panel_weapons_complainbubble_color_outofammo");
	HUD_Write_Cvar("hud_panel_weapons_complainbubble_color_donthave");
	HUD_Write_Cvar("hud_panel_weapons_complainbubble_color_unavailable");
	HUD_Write_Cvar("hud_panel_weapons_ammo");
	HUD_Write_Cvar("hud_panel_weapons_ammo_color");
	HUD_Write_Cvar("hud_panel_weapons_ammo_alpha");
	HUD_Write_Cvar("hud_panel_weapons_aspect");
	HUD_Write_Cvar("hud_panel_weapons_timeout");
	HUD_Write_Cvar("hud_panel_weapons_timeout_effect");
	HUD_Write_Cvar("hud_panel_weapons_timeout_fadebgmin");
	HUD_Write_Cvar("hud_panel_weapons_timeout_fadefgmin");
	HUD_Write_Cvar("hud_panel_weapons_timeout_speed_in");
	HUD_Write_Cvar("hud_panel_weapons_timeout_speed_out");
	HUD_Write_Cvar("hud_panel_weapons_onlyowned");
	HUD_Write_Cvar("hud_panel_weapons_noncurrent_alpha");
	HUD_Write_Cvar("hud_panel_weapons_noncurrent_scale");
	HUD_Write_Cvar("hud_panel_weapons_selection_radius");
	HUD_Write_Cvar("hud_panel_weapons_selection_speed");
}

void Accuracy_LoadLevels()
{
	if (autocvar_accuracy_color_levels != acc_color_levels)
	{
		strcpy(acc_color_levels, autocvar_accuracy_color_levels);
		acc_levels = tokenize_console(acc_color_levels);
		if (acc_levels > MAX_ACCURACY_LEVELS)
			acc_levels = MAX_ACCURACY_LEVELS;
		if (acc_levels < 2)
			LOG_INFO("Warning: accuracy_color_levels must contain at least 2 values");

		for (int i = 0; i < acc_levels; ++i)
			acc_lev[i] = stof(argv(i)) / 100.0;
	}
}

void Accuracy_LoadColors()
{
	if (time > acc_col_loadtime)
	if (acc_levels >= 2)
	{
		for (int i = 0; i < acc_levels; ++i)
			acc_col[i] = stov(cvar_string(strcat("accuracy_color", ftos(i))));
		acc_col_loadtime = time + 2;
	}
}

vector Accuracy_GetColor(float accuracy)
{
	if (acc_levels < 2)
		return '0 0 0'; // return black, can't determine the right color

	// find the max level lower than acc
	int j = acc_levels-1;
	while (j && accuracy < acc_lev[j])
		--j;

	// inject color j+1 in color j, how much depending on how much accuracy is higher than level j
	float factor = (accuracy - acc_lev[j]) / (acc_lev[j+1] - acc_lev[j]);
	vector color = acc_col[j];
	color = color + factor * (acc_col[j+1] - color);
	return color;
}

entity weaponorder[REGISTRY_MAX(Weapons)];
void weaponorder_swap(int i, int j, entity pass)
{
	TC(int, i); TC(int, j);
	entity h = weaponorder[i];
	weaponorder[i] = weaponorder[j];
	weaponorder[j] = h;
}

string weaponorder_cmp_str;
int weaponorder_cmp(int i, int j, entity pass)
{
	TC(int, i); TC(int, j);
	int ai = strstrofs(weaponorder_cmp_str, sprintf(" %d ", weaponorder[i].m_id), 0);
	int aj = strstrofs(weaponorder_cmp_str, sprintf(" %d ", weaponorder[j].m_id), 0);
	return aj - ai; // the string is in REVERSE order (higher prio at the right is what we want, but higher prio first is the string)
}

#define HUD_WEAPONS_GET_FULL_LAYOUT() MACRO_BEGIN \
	int nHidden = 0; \
	FOREACH(Weapons, it != WEP_Null, { \
		if (weapons_stat & WepSet_FromWeapon(it)) continue; \
		if (it.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED)) nHidden += 1; \
	}); \
	vector table_size = HUD_GetTableSize_BestItemAR((REGISTRY_COUNT(Weapons) - 1) - nHidden, panel_size, aspect); \
	columns = table_size.x; \
	rows = table_size.y; \
	weapon_size.x = panel_size.x / columns; \
	weapon_size.y = panel_size.y / rows; \
MACRO_END

string cl_weaponpriority_old;
bool weapons_orderbyimpulse_old;
void HUD_Weapons()
{
	// check to see if we want to continue
	if (hud != HUD_NORMAL) return;

	if (!autocvar__hud_configure)
	{
		if ((!autocvar_hud_panel_weapons) || (spectatee_status == -1))
			return;
		if (STAT(HEALTH) <= 0 && autocvar_hud_panel_weapons_hide_ondeath)
			return;

		float timeout = autocvar_hud_panel_weapons_timeout;
		float timeout_effect_length = autocvar_hud_panel_weapons_timeout_speed_out; //? 0.75 : 0);

		if (timeout && time >= weapontime + timeout + timeout_effect_length)
		if (autocvar_hud_panel_weapons_timeout_effect == 3
		|| (autocvar_hud_panel_weapons_timeout_effect == 1 && !(autocvar_hud_panel_weapons_timeout_fadebgmin + autocvar_hud_panel_weapons_timeout_fadefgmin)))
		{
			weaponprevtime = time;
			return;
		}
	}

	// declarations
	WepSet weapons_stat = WepSet_GetFromStat();
	entity panel_switchweapon = NULL;
	vector center = '0 0 0';

	float when = max(1, autocvar_hud_panel_weapons_complainbubble_time);
	float fadetime = max(0, autocvar_hud_panel_weapons_complainbubble_fadetime);

	vector weapon_size = '0 0 0';

	// update generic hud functions
	HUD_Panel_LoadCvars();

	if (cl_weaponpriority_old != autocvar_cl_weaponpriority || weapons_orderbyimpulse_old != autocvar_hud_panel_weapons_orderbyimpulse || weaponorder[0] == NULL)
	{
		weapons_orderbyimpulse_old = autocvar_hud_panel_weapons_orderbyimpulse;
		strcpy(cl_weaponpriority_old, autocvar_cl_weaponpriority);
		string weporder = W_FixWeaponOrder_ForceComplete(W_NumberWeaponOrder(cl_weaponpriority_old));
		if (autocvar_hud_panel_weapons_orderbyimpulse)
			weporder = W_FixWeaponOrder_BuildImpulseList(weporder);

		weaponorder_cmp_str = strcat(" ", weporder, " ");

		int weapon_cnt = 0;
		FOREACH(Weapons, it != WEP_Null && it.impulse >= 0, weaponorder[weapon_cnt++] = it);
		for (int i = weapon_cnt; i < REGISTRY_MAX(Weapons); ++i)
			weaponorder[i] = NULL;
		heapsort(weapon_cnt, weaponorder_swap, weaponorder_cmp, NULL);

		weaponorder_cmp_str = string_null;
	}

	if (!autocvar_hud_panel_weapons_complainbubble || autocvar__hud_configure || time - complain_weapon_time >= when + fadetime)
		complain_weapon = NULL;

	entity wepent = viewmodels[0]; // TODO: unhardcode

	if (wepent.switchweapon == WEP_Null)
		panel_switchweapon = NULL;
	else if (!panel_switchweapon)
		panel_switchweapon = wepent.switchweapon;

	if (autocvar__hud_configure)
	{
		if (!weapons_stat)
		{
			int j = 0;
			FOREACH(Weapons, it != WEP_Null && it.impulse >= 0 && (it.impulse % 3 != 0) && j < 6, {
				if (!(it.spawnflags & (WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_SPECIALATTACK)))
				{
					if (!panel_switchweapon || j < 4)
						panel_switchweapon = it;
					weapons_stat |= it.m_wepset;
					++j;
				}
			});
		}

		#if 0
		/// debug code
		if (cvar("wep_add"))
		{
			int nHidden = 0;
			FOREACH(Weapons, it != WEP_Null, {
				if (it.spawnflags & WEP_FLAG_MUTATORBLOCKED) nHidden += 1;
			});
			weapons_stat = '0 0 0';
			float countw = 1 + floor((floor(time * cvar("wep_add"))) % ((REGISTRY_COUNT(Weapons) - 1) - nHidden));
			for (int i = 0, j = 0; i <= (REGISTRY_COUNT(Weapons) - 1) && j < countw; ++i)
			{
				if (weaponorder[i].spawnflags & WEP_FLAG_MUTATORBLOCKED)
					continue;
				weapons_stat |= weaponorder[i].m_wepset;
				++j;
			}
		}
		#endif
	}

	// determine which weapons are going to be shown
	int weapon_count;
	int rows = 0, columns = 0;
	bool vertical_order = true;
	float aspect = max(0.001, autocvar_hud_panel_weapons_aspect);
	if (autocvar_hud_panel_weapons_onlyowned)
	{
		if (autocvar__hud_configure)
		{
			if (hud_configure_menu_open != 2)
				HUD_Panel_DrawBg(); // also draw the bg of the entire panel
		}

		// do we own this weapon?
		weapon_count = 0;
		if (autocvar_hud_panel_weapons_onlyowned >= 2) // only current
		{
			for (int i = 0; i <= WEP_LAST-WEP_FIRST; ++i)
				if (weaponorder[i] == panel_switchweapon || weaponorder[i] == complain_weapon)
					++weapon_count;
		}
		else
		{
			for (int i = 0; i <= WEP_LAST-WEP_FIRST; ++i)
				if ((weapons_stat & WepSet_FromWeapon(weaponorder[i])) || weaponorder[i] == complain_weapon)
					++weapon_count;
		}

		// might as well commit suicide now, no reason to live ;)
		if (weapon_count == 0)
			return;

		vector old_panel_size = panel_size;
		panel_size -= '2 2 0' * panel_bg_padding;

		HUD_WEAPONS_GET_FULL_LAYOUT();

		// NOTE: although weapons should aways look the same even if onlyowned is enabled,
		// we enlarge them a bit when possible to better match the desired aspect ratio
		vertical_order = panel_size.x / panel_size.y >= aspect;
		if (vertical_order)
		{
			// maximum number of columns that allows to display items with the desired aspect ratio
			int max_columns = floor(panel_size.x / (weapon_size.y * aspect));
			rows = min(rows, ceil(weapon_count / max_columns));
			columns = ceil(weapon_count / rows);
			weapon_size.x = min(panel_size.x / columns, aspect * weapon_size.y);
			weapon_size.y = min(panel_size.y / rows, weapon_size.x / aspect);
		}
		else
		{
			int max_rows = floor(panel_size.y / (weapon_size.x / aspect));
			columns = min(columns, ceil(weapon_count / max_rows));
			rows = ceil(weapon_count / columns);
			weapon_size.y = min(panel_size.y / rows, weapon_size.x / aspect);
			weapon_size.x = min(panel_size.x / columns, aspect * weapon_size.y);
		}

		// reduce size of the panel
		panel_size.x = columns * weapon_size.x;
		panel_size.y = rows * weapon_size.y;
		panel_size += '2 2 0' * panel_bg_padding;

		// center the resized panel, or snap it to the screen edge when close enough
		if (panel_pos.x > vid_conwidth * 0.001)
		{
			if(panel_pos.x + old_panel_size.x > vid_conwidth * 0.999)
				panel_pos.x += old_panel_size.x - panel_size.x;
			else
				panel_pos.x += (old_panel_size.x - panel_size.x) / 2;
		}
		else if (old_panel_size.x > vid_conwidth * 0.999)
			panel_pos.x += (old_panel_size.x - panel_size.x) / 2;

		if (panel_pos.y > vid_conheight * 0.001)
		{
			if (panel_pos.y + old_panel_size.y > vid_conheight * 0.999)
				panel_pos.y += old_panel_size.y - panel_size.y;
			else
				panel_pos.y += (old_panel_size.y - panel_size.y) / 2;
		}
		else if (old_panel_size.y > vid_conheight * 0.999)
			panel_pos.y += (old_panel_size.y - panel_size.y) / 2;
	}
	else
		weapon_count = (REGISTRY_COUNT(Weapons) - 1); // unused value


	Weapons_Fade(center);
	Weapons_Draw(panel_switchweapon, weapons_stat, center, weapon_size, aspect, when, fadetime, rows, columns, vertical_order);
}


// animation for fading in/out the panel respectively when not in use
void Weapons_Fade(vector center)
{
	if (autocvar__hud_configure)
		return;

	float timeout = autocvar_hud_panel_weapons_timeout;
	float timein_effect_length  = autocvar_hud_panel_weapons_timeout_speed_in; //? 0.375 : 0);
	float timeout_effect_length = autocvar_hud_panel_weapons_timeout_speed_out; //? 0.75 : 0);

	if (timeout && time >= weapontime + timeout) // apply timeout effect if needed
	{
		float f = bound(0, (time - (weapontime + timeout)) / timeout_effect_length, 1);

		// fade the panel alpha
		if (autocvar_hud_panel_weapons_timeout_effect == 1)
		{
			panel_bg_alpha *= (autocvar_hud_panel_weapons_timeout_fadebgmin * f + (1 - f));
			panel_fg_alpha *= (autocvar_hud_panel_weapons_timeout_fadefgmin * f + (1 - f));
		}
		else if (autocvar_hud_panel_weapons_timeout_effect == 3)
		{
			panel_bg_alpha *= (1 - f);
			panel_fg_alpha *= (1 - f);
		}

		// move the panel off the screen
		if (autocvar_hud_panel_weapons_timeout_effect == 2
		||  autocvar_hud_panel_weapons_timeout_effect == 3)
		{
			f *= f; // for a cooler movement
			center.x = panel_pos.x + panel_size.x/2;
			center.y = panel_pos.y + panel_size.y/2;
			float screen_ar = vid_conwidth/vid_conheight;
			if (center.x/center.y < screen_ar) //bottom left
			{
				if ((vid_conwidth - center.x)/center.y < screen_ar) //bottom
					panel_pos.y += f * (vid_conheight - panel_pos.y);
				else //left
					panel_pos.x -= f * (panel_pos.x + panel_size.x);
			}
			else //top right
			{
				if ((vid_conwidth - center.x)/center.y < screen_ar) //right
					panel_pos.x += f * (vid_conwidth - panel_pos.x);
				else //top
					panel_pos.y -= f * (panel_pos.y + panel_size.y);
			}
			if (f == 1)
				center.x = -1; // mark the panel as off screen
		}
		weaponprevtime = time - (1 - f) * timein_effect_length;
	}
	else if (timeout && time < weaponprevtime + timein_effect_length) // apply timein effect if needed
	{
		float f = bound(0, (time - weaponprevtime) / timein_effect_length, 1);

		// fade the panel alpha
		if (autocvar_hud_panel_weapons_timeout_effect == 1)
		{
			panel_bg_alpha *= (autocvar_hud_panel_weapons_timeout_fadebgmin * (1 - f) + f);
			panel_fg_alpha *= (autocvar_hud_panel_weapons_timeout_fadefgmin * (1 - f) + f);
		}
		else if (autocvar_hud_panel_weapons_timeout_effect == 3)
		{
			panel_bg_alpha *= (f);
			panel_fg_alpha *= (f);
		}

		// move the panel back on screen
		if (autocvar_hud_panel_weapons_timeout_effect == 2
		||  autocvar_hud_panel_weapons_timeout_effect == 3)
		{
			f *= f; // for a cooler movement
			f = 1 - f;
			center.x = panel_pos.x + panel_size.x/2;
			center.y = panel_pos.y + panel_size.y/2;
			float screen_ar = vid_conwidth/vid_conheight;
			if (center.x/center.y < screen_ar) //bottom left
			{
				if ((vid_conwidth - center.x)/center.y < screen_ar) //bottom
					panel_pos.y += f * (vid_conheight - panel_pos.y);
				else //left
					panel_pos.x -= f * (panel_pos.x + panel_size.x);
			}
			else //top right
			{
				if ((vid_conwidth - center.x)/center.y < screen_ar) //right
					panel_pos.x += f * (vid_conwidth - panel_pos.x);
				else //top
					panel_pos.y -= f * (panel_pos.y + panel_size.y);
			}
		}
	}
}

void Weapons_Draw(
	entity panel_switchweapon, WepSet weapons_stat,
	vector center, vector weapon_size, float aspect,
	float when, float fadetime,
	int rows, int columns, bool vertical_order)
{
	// draw the background, then change the virtual size of it to better fit other items inside
	if (autocvar_hud_panel_weapons_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();

	if (center.x == -1)
		return; // panel has gone off screen

	vector color;
	vector barsize = '0 0 0', baroffset = '0 0 0';

	vector ammo_color = '1 0 1';
	float ammo_alpha = 1;
	bool infinite_ammo = (STAT(ITEMS) & IT_UNLIMITED_AMMO);

	int row = 0, column = 0;

	if (panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	// after the sizing and animations are done, update the other values

	if (!rows) // if rows is > 0 onlyowned code has already updated these vars
	{
		HUD_WEAPONS_GET_FULL_LAYOUT();
		vertical_order = (panel_size.x / panel_size.y >= aspect);
	}

	// calculate position/size for visual bar displaying ammount of ammo status
	if (!infinite_ammo && autocvar_hud_panel_weapons_ammo)
	{
		ammo_color = stov(autocvar_hud_panel_weapons_ammo_color);
		ammo_alpha = panel_fg_alpha * autocvar_hud_panel_weapons_ammo_alpha;

		if (weapon_size.x/weapon_size.y > aspect)
		{
			barsize.x = aspect * weapon_size.y;
			barsize.y = weapon_size.y;
			baroffset.x = (weapon_size.x - barsize.x) / 2;
		}
		else
		{
			barsize.y = 1/aspect * weapon_size.x;
			barsize.x = weapon_size.x;
			baroffset.y = (weapon_size.y - barsize.y) / 2;
		}
	}
	if (autocvar_hud_panel_weapons_accuracy)
		Accuracy_LoadColors();

	// draw items
	vector label_size = '1 1 0' * min(weapon_size.x, weapon_size.y) * bound(0, autocvar_hud_panel_weapons_label_scale, 1);
	vector noncurrent_size = weapon_size * bound(0.01, autocvar_hud_panel_weapons_noncurrent_scale, 1);
	float noncurrent_alpha = panel_fg_alpha * bound(0, autocvar_hud_panel_weapons_noncurrent_alpha, 1);
	static vector weapon_pos_current = '-1 0 0';
	if (weapon_pos_current.x == -1)
		weapon_pos_current = panel_pos;

	float switch_speed;
	if (autocvar_hud_panel_weapons_selection_speed <= 0 || autocvar__hud_configure)
		switch_speed = 999;
	else
		switch_speed = frametime * autocvar_hud_panel_weapons_selection_speed;
	vector radius_size = weapon_size * (autocvar_hud_panel_weapons_selection_radius + 1);

	// draw background behind currently selected weapon
	// do it earlier to make sure bg is drawn behind every weapon icons while it's moving
	if (panel_switchweapon)
		drawpic_aspect_skin(weapon_pos_current, "weapon_current_bg", weapon_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

	for (int i = 0; i <= WEP_LAST-WEP_FIRST; ++i)
	{
		// retrieve information about the current weapon to be drawn
		entity it = weaponorder[i];
		int weapon_id = it.impulse;

		// skip if this weapon doesn't exist
		if (!it || weapon_id < 0)
			continue;

		// skip this weapon if we don't own it (and onlyowned is enabled)-- or if weapons_complainbubble is showing for this weapon
		if (autocvar_hud_panel_weapons_onlyowned)
		{
			if (autocvar_hud_panel_weapons_onlyowned >= 2) // only current
			{
				if (!(it == panel_switchweapon || it == complain_weapon))
					continue;
			}
			else
			{
				if (!((weapons_stat & WepSet_FromWeapon(it)) || (it == complain_weapon)))
					continue;
			}
		}
		else
		{
			if ((it.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED))
			&& !(weapons_stat & WepSet_FromWeapon(it)))
				continue;
		}

		// figure out the drawing position of weapon
		vector weapon_pos = panel_pos + vec2(column * weapon_size.x, row * weapon_size.y);

		// update position of the currently selected weapon
		if (it == panel_switchweapon)
		{
			if (weapon_pos_current.y > weapon_pos.y)
				weapon_pos_current.y = max(weapon_pos.y, weapon_pos_current.y - switch_speed * (weapon_pos_current.y - weapon_pos.y));
			else if (weapon_pos_current.y < weapon_pos.y)
				weapon_pos_current.y = min(weapon_pos.y, weapon_pos_current.y + switch_speed * (weapon_pos.y - weapon_pos_current.y));
			if (weapon_pos_current.x > weapon_pos.x)
				weapon_pos_current.x = max(weapon_pos.x, weapon_pos_current.x - switch_speed * (weapon_pos_current.x - weapon_pos.x));
			else if (weapon_pos_current.x < weapon_pos.x)
				weapon_pos_current.x = min(weapon_pos.x, weapon_pos_current.x + switch_speed * (weapon_pos.x - weapon_pos_current.x));
		}

		// draw the weapon accuracy
		if (autocvar_hud_panel_weapons_accuracy)
		{
			float panel_weapon_accuracy = weapon_accuracy[it.m_id-WEP_FIRST];
			if (autocvar__hud_configure && panel_weapon_accuracy == -1)
				panel_weapon_accuracy = (it.m_id % 7 - 2) * 0.11 + 0.3; // make up something
			if (panel_weapon_accuracy >= 0)
			{
				color = Accuracy_GetColor(panel_weapon_accuracy);
				drawpic_aspect_skin(weapon_pos, "weapon_accuracy", weapon_size, color, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
		}

		vector weapon_size_real = noncurrent_size;
		float weapon_alpha_real = noncurrent_alpha;
		float radius_factor_x = 1 - bound(0, fabs(weapon_pos.x - weapon_pos_current.x) / radius_size.x, 1);
		float radius_factor_y = 1 - bound(0, fabs(weapon_pos.y - weapon_pos_current.y) / radius_size.y, 1);
		if (radius_factor_x || radius_factor_y)
		{
			weapon_size_real.x += (weapon_size.x - noncurrent_size.x) * radius_factor_x;
			weapon_size_real.y += (weapon_size.y - noncurrent_size.y) * radius_factor_y;
			weapon_alpha_real += (panel_fg_alpha - noncurrent_alpha) * min(radius_factor_x, radius_factor_y);
		}

		vector weapon_pos_real = weapon_pos;
		weapon_pos_real.x = weapon_pos.x + (weapon_size.x - weapon_size_real.x) / 2;
		weapon_pos_real.y = weapon_pos.y + (weapon_size.y - weapon_size_real.y) / 2;

		// drawing all the weapon items
		if (weapons_stat & WepSet_FromWeapon(it))
		{
			// draw the weapon image
			drawpic_aspect_skin(weapon_pos_real, it.model2, weapon_size_real, '1 1 1', weapon_alpha_real, DRAWFLAG_NORMAL);

			// draw weapon label string
			switch (autocvar_hud_panel_weapons_label)
			{
				case 1: // weapon number
					drawstring(weapon_pos, ftos(weapon_id), label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
					break;

				case 2: // bind
					drawstring(weapon_pos, getcommandkey(ftos(weapon_id), strcat("weapon_group_", ftos(weapon_id))), label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
					break;

				case 3: // weapon name
					drawstring(weapon_pos, strtolower(it.m_name), label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
					break;

				default: // nothing
					break;
			}

			// draw ammo status bar
			if (!infinite_ammo && autocvar_hud_panel_weapons_ammo && (it.ammo_type != RES_NONE))
			{
				float ammo_full;
				float a = getstati(GetAmmoStat(it.ammo_type)); // how much ammo do we have?

				if (autocvar__hud_configure && a == 0)
					a = 60; // make up something

				if (a > 0)
				{
					// TODO: registry handles
					switch (it.ammo_type)
					{
						case RES_SHELLS:  ammo_full = autocvar_hud_panel_weapons_ammo_full_shells;  break;
						case RES_BULLETS: ammo_full = autocvar_hud_panel_weapons_ammo_full_nails;   break;
						case RES_ROCKETS: ammo_full = autocvar_hud_panel_weapons_ammo_full_rockets; break;
						case RES_CELLS:   ammo_full = autocvar_hud_panel_weapons_ammo_full_cells;   break;
						case RES_FUEL:    ammo_full = autocvar_hud_panel_weapons_ammo_full_fuel;    break;
						default: ammo_full = 60;
					}

					drawsetcliparea(
						weapon_pos.x + baroffset.x,
						weapon_pos.y + baroffset.y,
						barsize.x * bound(0, a/ammo_full, 1),
						barsize.y
					);

					drawpic_aspect_skin(
						weapon_pos,
						"weapon_ammo",
						weapon_size,
						ammo_color,
						ammo_alpha,
						DRAWFLAG_NORMAL
					);

					drawresetcliparea();
				}
			}
		}
		else // draw a "ghost weapon icon" if you don't have the weapon
		{
			drawpic_aspect_skin(weapon_pos_real, it.model2, weapon_size_real, '0.2 0.2 0.2', weapon_alpha_real * 0.5, DRAWFLAG_NORMAL);
		}

		// draw the complain message
		if (it == complain_weapon)
		{
			float a;
			if (fadetime)
				a = ((complain_weapon_time + when > time) ? 1 : bound(0, (complain_weapon_time + when + fadetime - time) / fadetime, 1));
			else
				a = ((complain_weapon_time + when > time) ? 1 : 0);

			string s;
			if (complain_weapon_type == 0)
			{
				s = _("Out of ammo");
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_outofammo);
			}
			else if (complain_weapon_type == 1)
			{
				s = _("Don't have");
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_donthave);
			}
			else
			{
				s = _("Unavailable");
				color = stov(autocvar_hud_panel_weapons_complainbubble_color_unavailable);
			}
			float padding = autocvar_hud_panel_weapons_complainbubble_padding;
			drawpic_aspect_skin(weapon_pos + '1 1 0' * padding, "weapon_complainbubble", weapon_size - '2 2 0' * padding, color, a * panel_fg_alpha, DRAWFLAG_NORMAL);
			drawstring_aspect(weapon_pos + '1 1 0' * padding, s, weapon_size - '2 2 0' * padding, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		#if 0
		/// debug code
		if(!autocvar_hud_panel_weapons_onlyowned)
		{
			drawfill(weapon_pos + '1 1 0', weapon_size - '2 2 0', '1 1 1', panel_fg_alpha * 0.2, DRAWFLAG_NORMAL);
			drawstring(weapon_pos, ftos(i + 1), label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		#endif

		// continue with new position for the next weapon
		if (vertical_order)
		{
			++column;
			if (column >= columns)
			{
				column = 0;
				++row;
			}
		}
		else
		{
			++row;
			if (row >= rows)
			{
				row = 0;
				++column;
			}
		}
	}
}
