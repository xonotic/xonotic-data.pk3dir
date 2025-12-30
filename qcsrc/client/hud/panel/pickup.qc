#include "pickup.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <client/hud/panel/timer.qh>
#include <common/items/inventory.qh>

// Pickup (#26)

void HUD_Pickup_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

void Pickup_Update(entity item, int count)
{
	if (last_pickup_item != item || time - STAT(LAST_PICKUP) > autocvar_hud_panel_pickup_time)
		last_pickup_count = 0;
	last_pickup_item = item;
	last_pickup_count += count;
}

float HUD_Pickup_Time(float t)
{
	float timelimit = (warmup_stage ? STAT(WARMUP_TIMELIMIT) : STAT(TIMELIMIT) * 60);

	if (autocvar_hud_panel_timer_increment || timelimit <= 0)
		return floor(t - STAT(GAMESTARTTIME));
	else
		return ceil(timelimit + STAT(GAMESTARTTIME) - t);
}

void HUD_Pickup(bool should_draw)
{
	if (!should_draw)
		return;
	if (!autocvar_hud_panel_pickup)
		return;

	HUD_Panel_LoadCvars();
	vector pos = panel_pos;
	vector mySize = panel_size;

	if (autocvar_hud_panel_pickup_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if (panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float last_pickup_time = STAT(LAST_PICKUP);
	float display_time = min(5, autocvar_hud_panel_pickup_time);
	entity item = last_pickup_item;

	if ((last_pickup_time && last_pickup_time > time - display_time && item) || autocvar__hud_configure)
	{
		if (autocvar__hud_configure)
			item = ITEM_ArmorMega;

		vector fontsize = '1 1 0' * mySize.y;
		vector iconsize = fontsize * autocvar_hud_panel_pickup_iconsize;

		string icon = strcat(hud_skin_path, "/", (item.model2) ? item.model2 : item.m_icon);
		if (precache_pic(icon) == "")
			icon = strcat("gfx/hud/default/", (item.model2) ? item.model2 : item.m_icon);

		vector sz = draw_getimagesize(icon);
		sz = vec2(iconsize.y * (sz.y ? sz.x / sz.y : 1), iconsize.y);

		float fade_out_time = min(display_time, autocvar_hud_panel_pickup_fade_out);
		float a;
		if (autocvar__hud_configure)
			a = 1;
		else if (time < last_pickup_time + display_time - fade_out_time)
			a = 1;
		else
			a = (last_pickup_time + display_time - time) / fade_out_time;

		if (autocvar_hud_panel_pickup_showtimer)
		{
			// 1 will show the timer always
			// 2 will show the timer only if spectating
			// forbid serverflag will force the 2nd behavior
			if ((autocvar_hud_panel_pickup_showtimer == 1 && !(serverflags & SERVERFLAG_FORBID_PICKUPTIMER))
				|| spectatee_status)
			{
				string str_timer = autocvar__hud_configure
					? "13:02"
					: seconds_tostring(HUD_Pickup_Time(last_pickup_time));
				drawstring(pos, str_timer, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
				pos.x += stringwidth(str_timer, false, fontsize) + fontsize.x * 0.25;
			}
		}

		drawpic(pos - eY * (iconsize.y - fontsize.y) * 0.5, icon, sz, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		pos.x += sz.x + fontsize.x * 0.25;
		string str_name = ((last_pickup_count > 1) ? sprintf("%s (x%d)", item.m_name, last_pickup_count) : item.m_name);
		str_name = textShortenToWidth(str_name, mySize.x - (pos.x - panel_pos.x), fontsize, stringwidth_nocolors);
		drawstring(pos, str_name, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}
}
