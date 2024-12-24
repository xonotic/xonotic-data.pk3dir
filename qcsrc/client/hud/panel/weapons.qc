#include "weapons.qh"

#include <client/draw.qh>
#include <client/view.qh>
#include <common/wepent.qh>
#include <common/mutators/mutator/nades/nades.qh>
#include <common/mutators/mutator/offhand_blaster/cl_offhand_blaster.qh>
#include <common/mutators/mutator/hook/cl_hook.qh>
#include <common/weapons/weapon/blaster.qh>
#include <common/weapons/weapon/hook.qh>

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
	HUD_Write_Cvar("hud_panel_weapons_offhand");
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
	{ \
		int nHidden = 0; \
		FOREACH(Weapons, it != WEP_Null, { \
			if (weapons_stat & WepSet_FromWeapon(it)) continue; \
			if (it.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_SPECIALATTACK)) nHidden += 1; \
		}); \
		{ \
			vector table_size = HUD_GetTableSize_BestItemAR((REGISTRY_COUNT(Weapons) - 1) - nHidden + offhands.x, panel_size, aspect); \
			columns = table_size.x; \
			rows = table_size.y; \
		} \
	} \
	weapon_size.x = panel_size.x / columns; \
	weapon_size.y = panel_size.y / rows; \
MACRO_END

entity panel_switchweapon;
WepSet weapons_stat;
vector panel_center;
vector pos_current = '-1 0 0';
string cl_weaponpriority_old;
float cb_when, cb_fadetime;
bool infinite_ammo;
bool weapons_orderbyimpulse_old;

void HUD_Weapons()
{
	// check to see if we want to continue
	if (hud != HUD_NORMAL) return;

	infinite_ammo = (STAT(ITEMS) & IT_UNLIMITED_AMMO);
	cb_when = max(1, autocvar_hud_panel_weapons_complainbubble_time);
	cb_fadetime = max(0, autocvar_hud_panel_weapons_complainbubble_fadetime);

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

	weapons_stat = WepSet_GetFromStat();
	panel_switchweapon = NULL;
	panel_center = '0 0 0';

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

	if (!autocvar_hud_panel_weapons_complainbubble || autocvar__hud_configure || time - complain_weapon_time >= cb_when + cb_fadetime)
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
				if (!(it.spawnflags & WEP_FLAG_MUTATORBLOCKED) && !(it.spawnflags & WEP_FLAG_SPECIALATTACK))
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

	// determine which offhands are going to be shown
	vector offhands = Weapons_GetOffhands();

	// determine which weapons are going to be shown
	vector weapon_size = '0 0 0';
	float aspect = max(0.001, autocvar_hud_panel_weapons_aspect);
	int rows = 0, columns = 0;
	int weapon_count;
	bool vertical_order = true;
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
		vertical_order = (panel_size.x / panel_size.y >= aspect);
		if (vertical_order)
		{
			// maximum number of columns that allows to display items with the desired aspect ratio
			int max_columns = floor(panel_size.x / (weapon_size.y * aspect));
			rows = min(rows, ceil((weapon_count + offhands.x) / max_columns));
			columns = ceil((weapon_count + offhands.x) / rows);
			weapon_size.x = min(panel_size.x / columns, aspect * weapon_size.y);
			weapon_size.y = min(panel_size.y / rows, weapon_size.x / aspect);
		}
		else
		{
			int max_rows = floor(panel_size.y / (weapon_size.x / aspect));
			columns = min(columns, ceil((weapon_count + offhands.x) / max_rows));
			rows = ceil((weapon_count + offhands.x) / columns);
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


	Weapons_Fade();
	Weapons_Draw(weapon_size, offhands, aspect, rows, columns, vertical_order);
}


/* returns vec2(x, y)
 * x is the total offhand weapons (since there's no popcount)
 * y is a bitfield describing which offhand weapons the player has
 */
vector Weapons_GetOffhands()
{
	if (!autocvar_hud_panel_weapons_offhand)
		return vec2(0, 0);
	if (autocvar__hud_configure)
		return vec2(1, BIT(1));

	// TODO: make this dynamic with an OffhandWeapon registry or something of the sorts
	int bits = 0; // BIT(0) = nade, BIT(1) = hook, BIT(2) = blaster
	int total = 0;
	if (mut_is_active(MUT_NADES))
	{
		bits |= BIT(0);
		++total;
	}
	if (mut_is_active(MUT_OFFHAND_BLASTER))
	{
		bits |= BIT(2);
		++total;
	}
	else if (mut_is_active(MUT_GRAPPLING_HOOK)) // overridden by blaster
	{
		bits |= BIT(1);
		++total;
	}

	return vec2(total, bits);
}

// animation for fading in/out the panel respectively when not in use
void Weapons_Fade()
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
			panel_center.x = panel_pos.x + panel_size.x/2;
			panel_center.y = panel_pos.y + panel_size.y/2;
			float screen_ar = vid_conwidth/vid_conheight;
			if (panel_center.x/panel_center.y < screen_ar) //bottom left
			{
				if ((vid_conwidth - panel_center.x)/panel_center.y < screen_ar) //bottom
					panel_pos.y += f * (vid_conheight - panel_pos.y);
				else //left
					panel_pos.x -= f * (panel_pos.x + panel_size.x);
			}
			else //top right
			{
				if ((vid_conwidth - panel_center.x)/panel_center.y < screen_ar) //right
					panel_pos.x += f * (vid_conwidth - panel_pos.x);
				else //top
					panel_pos.y -= f * (panel_pos.y + panel_size.y);
			}
			if (f == 1)
				panel_center.x = -1; // mark the panel as off screen
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
			panel_center.x = panel_pos.x + panel_size.x/2;
			panel_center.y = panel_pos.y + panel_size.y/2;
			float screen_ar = vid_conwidth/vid_conheight;
			if (panel_center.x/panel_center.y < screen_ar) //bottom left
			{
				if ((vid_conwidth - panel_center.x)/panel_center.y < screen_ar) //bottom
					panel_pos.y += f * (vid_conheight - panel_pos.y);
				else //left
					panel_pos.x -= f * (panel_pos.x + panel_size.x);
			}
			else //top right
			{
				if ((vid_conwidth - panel_center.x)/panel_center.y < screen_ar) //right
					panel_pos.x += f * (vid_conwidth - panel_pos.x);
				else //top
					panel_pos.y -= f * (panel_pos.y + panel_size.y);
			}
		}
	}
}

void Weapons_Draw(
	vector weapon_size, vector offhands,
	float aspect, int rows, int columns, bool vertical_order)
{
	// draw the background, then change the virtual size of it to better fit other items inside
	if (autocvar_hud_panel_weapons_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if (panel_center.x == -1)
		return; // panel has gone off screen

	// draw the foreground
	vector barsize = '0 0 0', baroffset = '0 0 0';
	vector ammo_color = '1 0 1';
	float ammo_alpha = 1;

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

	// draw background behind currently selected weapon
	// do it earlier to make sure bg is drawn behind every weapon icons while it's moving
	if (pos_current.x == -1)
		pos_current = panel_pos;
	if (panel_switchweapon)
		drawpic_aspect_skin(pos_current, "weapon_current_bg", weapon_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

	int start_idx = 0, end_idx = WEP_LAST-WEP_FIRST,
	    row = 0, column = 0;
	if (offhands.y)
	{
		if (autocvar_hud_panel_weapons_offhand == 1)
			start_idx -= 3;
		else if (autocvar_hud_panel_weapons_offhand == 2)
			end_idx += 3;
	}

	for (int i = start_idx; i <= end_idx; ++i)
	{
		entity wep_or_offhand;
		int offhand_bit;
		if (i == -1 || i == WEP_LAST-WEP_FIRST + 1)
		{
			if (!(offhands.y & BIT(0)))
				continue;
			wep_or_offhand = NADE_TYPE_ICE; // nade TODO!!!
			offhand_bit = BIT(0);
		}
		else if (i == -2 || i == WEP_LAST-WEP_FIRST + 2)
		{
			if (!(offhands.y & BIT(1)))
				continue;
			wep_or_offhand = WEP_HOOK; // hook
			offhand_bit = BIT(1);
		}
		else if (i == -3 || i == WEP_LAST-WEP_FIRST + 3)
		{
			if (!(offhands.y & BIT(2)))
				continue;
			wep_or_offhand = WEP_BLASTER; // blaster
			offhand_bit = BIT(2);
		}
		else
		{
			wep_or_offhand = weaponorder[i]; // weapon
			offhand_bit = 0;
		}

		// figure out the drawing position of weapon
		vector weapon_pos = panel_pos + vec2(column * weapon_size.x, row * weapon_size.y);
		if (!Weapons_DrawWeaponOrOffhand(wep_or_offhand, weapon_size, weapon_pos, barsize, baroffset, ammo_color, ammo_alpha, offhand_bit))
			continue;

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

// returns continue bool
bool Weapons_DrawWeaponOrOffhand(
	entity it, vector size, vector pos,
	vector barsize, vector baroffset, vector ammo_color, float ammo_alpha,
	int offhand_bit)
{
	vector color;
	vector label_size = '1 1 0' * min(size.x, size.y) * bound(0, autocvar_hud_panel_weapons_label_scale, 1);
	vector noncurrent_size = size * bound(0.01, autocvar_hud_panel_weapons_noncurrent_scale, 1);
	float noncurrent_alpha = panel_fg_alpha * bound(0, autocvar_hud_panel_weapons_noncurrent_alpha, 1);

	float switch_speed;
	if (autocvar_hud_panel_weapons_selection_speed <= 0 || autocvar__hud_configure)
		switch_speed = 999;
	else
		switch_speed = frametime * autocvar_hud_panel_weapons_selection_speed;
	vector radius_size = size * (autocvar_hud_panel_weapons_selection_radius + 1);

	// skip if this weapon/offhand doesn't exist
	if (!it)
		return false;

	// retrieve information about the current weapon to be drawn
	int weapon_id;
	if (offhand_bit)
		weapon_id = -1;
	else
	{
		weapon_id = it.impulse;
		if (weapon_id < 0)
			return false;
	}

	// skip this weapon if we don't own it (and onlyowned is enabled)-- or if weapons_complainbubble is showing for this weapon
	if (!offhand_bit)
	{
		if (autocvar_hud_panel_weapons_onlyowned)
		{
			if (autocvar_hud_panel_weapons_onlyowned >= 2) // only current
			{
				if (!(it == panel_switchweapon || it == complain_weapon))
					return true;
			}
			else
			{
				if (!((weapons_stat & WepSet_FromWeapon(it)) || (it == complain_weapon)))
					return false;
			}
		}
		else
		{
			if ((it.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_SPECIALATTACK))
			&& !(weapons_stat & WepSet_FromWeapon(it)))
				return false;
		}
	}

	// update position of the currently selected weapon
	if (!offhand_bit && it == panel_switchweapon)
	{
		if (pos_current.y > pos.y)
			pos_current.y = max(pos.y, pos_current.y - switch_speed * (pos_current.y - pos.y));
		else if (pos_current.y < pos.y)
			pos_current.y = min(pos.y, pos_current.y + switch_speed * (pos.y - pos_current.y));
		if (pos_current.x > pos.x)
			pos_current.x = max(pos.x, pos_current.x - switch_speed * (pos_current.x - pos.x));
		else if (pos_current.x < pos.x)
			pos_current.x = min(pos.x, pos_current.x + switch_speed * (pos.x - pos_current.x));
	}

	// draw the weapon accuracy
	if (!offhand_bit && autocvar_hud_panel_weapons_accuracy)
	{
		float panel_weapon_accuracy = weapon_accuracy[it.m_id-WEP_FIRST];
		if (panel_weapon_accuracy >= 0)
		{
			color = Accuracy_GetColor(panel_weapon_accuracy);
			drawpic_aspect_skin(pos, "weapon_accuracy", size, color, panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}

	vector size_real = noncurrent_size;
	float alpha_real = noncurrent_alpha;
	float radius_factor_x = 1 - bound(0, fabs(pos.x - pos_current.x) / radius_size.x, 1);
	float radius_factor_y = 1 - bound(0, fabs(pos.y - pos_current.y) / radius_size.y, 1);
	if (radius_factor_x || radius_factor_y)
	{
		size_real.x += (size.x - noncurrent_size.x) * radius_factor_x;
		size_real.y += (size.y - noncurrent_size.y) * radius_factor_y;
		alpha_real += (panel_fg_alpha - noncurrent_alpha) * min(radius_factor_x, radius_factor_y);
	}

	vector pos_real = pos;
	if (offhand_bit > BIT(0))
		size_real *= 0.8; // make it obvious that it's an offhand weapon
	else if (offhand_bit == BIT(0))
		size_real *= 0.9; // make the grenade a bit smaller so it's similar to the offhand weapons
	pos_real.x = pos.x + (size.x - size_real.x) / 2;
	pos_real.y = pos.y + (size.y - size_real.y) / 2;

	string icon_str, bind_str;
	switch (offhand_bit)
	{
		case BIT(0):
			icon_str = it.m_icon;
			bind_str = getcommandkey(_("drop weapon"), "dropweapon");
			break;
		case BIT(1):
			icon_str = it.model2;
			bind_str = getcommandkey(_("off-hand hook"), "+hook");
			break;
		case BIT(2):
			icon_str = it.model2;
			bind_str = "";
			break;
		default:
			icon_str = it.model2;
			bind_str = getcommandkey(ftos(weapon_id), strcat("weapon_group_", ftos(weapon_id)));
			break;
	}

	// drawing all the weapon/offhand items
	if (offhand_bit || weapons_stat & WepSet_FromWeapon(it))
	{
		// draw the weapon/offhand image
		drawpic_aspect_skin(pos_real, icon_str, size_real, '1 1 1', alpha_real, DRAWFLAG_NORMAL);

		// draw weapon/offhand label string
		switch (autocvar_hud_panel_weapons_label)
		{
			case 1: // weapon number
				if (weapon_id != -1)
					drawstring(pos, ftos(weapon_id), label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				break;
			case 2: // bind
				if (bind_str != "")
					drawstring(pos, bind_str, label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				break;
			case 3: // weapon/offhand name
				drawstring(pos, strtolower(it.m_name), label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				break;
			default: // nothing
				break;
		}

		// draw ammo status bar
		// TODO: offhand ammo?
		if (!offhand_bit && !infinite_ammo && autocvar_hud_panel_weapons_ammo && (it.ammo_type != RES_NONE))
		{
			float ammo_full;
			float a = getstati(GetAmmoStat(it.ammo_type)); // how much ammo do we have?

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
					pos.x + baroffset.x,
					pos.y + baroffset.y,
					barsize.x * bound(0, a/ammo_full, 1),
					barsize.y
				);
				drawpic_aspect_skin(
					pos,
					"weapon_ammo",
					size,
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
		drawpic_aspect_skin(pos_real, icon_str, size_real, '0.2 0.2 0.2', alpha_real * 0.5, DRAWFLAG_NORMAL);
	}

	// draw the complain message
	if (!offhand_bit && it == complain_weapon)
	{
		float a;
		if (cb_fadetime)
			a = ((complain_weapon_time + cb_when > time) ? 1 : bound(0, (complain_weapon_time + cb_when + cb_fadetime - time) / cb_fadetime, 1));
		else
			a = ((complain_weapon_time + cb_when > time) ? 1 : 0);

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
		drawpic_aspect_skin(pos + '1 1 0' * padding, "weapon_complainbubble", size - '2 2 0' * padding, color, a * panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(pos + '1 1 0' * padding, s, size - '2 2 0' * padding, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}

	#if 0
	/// debug code
	if (!offhand_bit && !autocvar_hud_panel_weapons_onlyowned)
	{
		drawfill(pos + '1 1 0', size - '2 2 0', '1 1 1', panel_fg_alpha * 0.2, DRAWFLAG_NORMAL);
		drawstring(pos, ftos(i + 1), label_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	#endif

	return true;
}
