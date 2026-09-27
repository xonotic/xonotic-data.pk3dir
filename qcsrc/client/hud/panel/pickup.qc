#include "pickup.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <client/hud/panel/notify.qh>
#include <client/hud/panel/timer.qh>
#include <common/items/inventory.qh>

entity last_pickup_item;
int last_pickup_count;

// Pickup (#26)

void HUD_Pickup_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_pickup_showname");
	HUD_Write_Cvar("hud_panel_pickup_showtimer");
}

string HUD_Pickup_GetIcon(entity item)
{
	string icon = strcat(hud_skin_path, "/", (item.model2) ? item.model2 : item.m_icon);
	if (precache_pic(icon) == "")
		return strcat("gfx/hud/default/", (item.model2) ? item.model2 : item.m_icon);
	return icon;
}

string HUD_Pickup_Time(float t)
{
	float timelimit = (warmup_stage ? STAT(WARMUP_TIMELIMIT) : STAT(TIMELIMIT) * 60);

	if (autocvar_hud_panel_timer_increment || timelimit <= 0)
		t = floor(t - STAT(GAMESTARTTIME));
	else
		t = ceil(timelimit + STAT(GAMESTARTTIME) - t);
	return seconds_tostring(t);
}

void HUD_Pickup_Update(entity item, int count)
{
	if (last_pickup_item != item || time - STAT(LAST_PICKUP) > autocvar_hud_panel_pickup_time)
		last_pickup_count = 0;
	last_pickup_item = item;
	last_pickup_count += count;

	HUD_Notify_PushPickup(item, STAT(LAST_PICKUP));
}

void HUD_Pickup(bool should_draw)
{
	if (!should_draw)
		return;
	if (!autocvar__hud_configure && !autocvar_hud_panel_pickup)
		return;

	HUD_Panel_LoadCvars();
	vector pos = panel_pos;
	vector size = panel_size;

	if (autocvar_hud_panel_pickup_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if (panel_bg_padding)
	{
		pos  += '1 1 0' * panel_bg_padding;
		size -= '2 2 0' * panel_bg_padding;
	}

	float last_pickup_time = STAT(LAST_PICKUP);
	float display_time = min(5, autocvar_hud_panel_pickup_time);
	entity item = (autocvar__hud_configure && !last_pickup_item)
		? ITEM_ArmorMega
		: last_pickup_item;

	if (!autocvar__hud_configure && !(last_pickup_time && last_pickup_time > time - display_time && item))
		return;

	string icon = HUD_Pickup_GetIcon(item);

	vector fontsize = '1 1 0' * size.y;
	vector iconsize = fontsize * autocvar_hud_panel_pickup_iconsize;
	vector sz = draw_getimagesize(icon);
	sz = vec2(iconsize.y * (sz.y ? sz.x / sz.y : 1), iconsize.y);

	float fade_out_time = min(display_time, autocvar_hud_panel_pickup_fade_out);
	float a;
	if (autocvar__hud_configure
	|| time < last_pickup_time + display_time - fade_out_time)
		a = 1;
	else
		a = (last_pickup_time + display_time - time) / fade_out_time;

	// Draw time
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
				: HUD_Pickup_Time(last_pickup_time);
			drawstring(pos, str_timer, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
			pos.x += stringwidth(str_timer, false, fontsize) + fontsize.x * 0.25;
		}
	}

	// Draw icon
	drawpic(pos - eY * (iconsize.y - fontsize.y) * 0.5, icon, sz, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);

	string str_name;
	int count = (autocvar__hud_configure && last_pickup_count <= 1)
		? 2
		: last_pickup_count;
	if (autocvar_hud_panel_pickup_showname)
	{
		str_name = item.m_name;
		if (count > 1)
			str_name = strcat(str_name, sprintf(_(" (%s)"), sprintf("x%d", count)));
	}
	else if (count > 1)
		str_name = sprintf("x%d", count);
	else
		return;

	// Draw name & count text
	pos.x += sz.x + fontsize.x * 0.25;
	str_name = textShortenToWidth(str_name, size.x - (pos.x - panel_pos.x), fontsize, stringwidth_nocolors);
	drawstring(pos, str_name, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
}
