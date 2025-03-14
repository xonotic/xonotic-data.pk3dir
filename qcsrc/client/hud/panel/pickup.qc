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

void Pickup_Update(entity it, int count)
{
	if(last_pickup_item != it || time - STAT(LAST_PICKUP) > autocvar_hud_panel_pickup_time)
		last_pickup_count = 0;
	last_pickup_item = it;
	last_pickup_count += count;
}

float HUD_Pickup_Time(float t)
{
	float timelimit = (warmup_stage ? STAT(WARMUP_TIMELIMIT) : STAT(TIMELIMIT) * 60);

	if(autocvar_hud_panel_timer_increment || timelimit <= 0)
		return floor(t - STAT(GAMESTARTTIME));
	else
		return ceil(timelimit + STAT(GAMESTARTTIME) - t);
}

void HUD_Pickup()
{
	if(!autocvar_hud_panel_pickup) return;

	HUD_Panel_LoadCvars();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_pickup_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float last_pickup_time = STAT(LAST_PICKUP);
	float display_time = min(5, autocvar_hud_panel_pickup_time);
	entity it = last_pickup_item;

	if((last_pickup_time && last_pickup_time > time - display_time && it) || autocvar__hud_configure)
	{
		if(autocvar__hud_configure)
			it = ITEM_ArmorMega;

		string str_timer, str_name, icon;
		vector fontsize = '1 1 0' * mySize.y;
		vector iconsize = fontsize * autocvar_hud_panel_pickup_iconsize;

		icon = strcat(hud_skin_path, "/", (it.model2) ? it.model2 : it.m_icon);
		if(precache_pic(icon) == "")
			icon = strcat("gfx/hud/default/", (it.model2) ? it.model2 : it.m_icon);

		vector sz = draw_getimagesize(icon);
		sz = vec2(iconsize.y * (sz.y ? sz.x/sz.y : 1), iconsize.y);

		str_name = ((last_pickup_count > 1) ? sprintf("%s (x%d)", it.m_name, last_pickup_count) : it.m_name);

		float a;
		float fade_out_time = min(display_time, autocvar_hud_panel_pickup_fade_out);

		if(autocvar__hud_configure)
			a = 1;
		else if(time < last_pickup_time + display_time - fade_out_time)
			a = 1;
		else
			a = (last_pickup_time + display_time - time) / fade_out_time;

		if(autocvar_hud_panel_pickup_showtimer) {
			// 1 will show the timer always
			// 2 will show the timer only if spectating
			// forbid serverflag will force the 2nd behavior
			if((autocvar_hud_panel_pickup_showtimer == 1 && !(serverflags & SERVERFLAG_FORBID_PICKUPTIMER)) || spectatee_status)
			{
				if(autocvar__hud_configure)
					str_timer = "13:02";
				else
					str_timer = seconds_tostring(HUD_Pickup_Time(last_pickup_time));
				drawstring(pos, str_timer, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
				pos.x += stringwidth(str_timer, false, fontsize) + fontsize.x * 0.25;
			}
		}

		drawpic(pos - eY * ((iconsize.y - fontsize.y) / 2), icon, sz, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		pos.x += sz.x + fontsize.x * 0.25;
		str_name = textShortenToWidth(str_name, mySize.x - (pos.x - panel_pos.x), fontsize, stringwidth_nocolors);
		drawstring(pos, str_name, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}
}
