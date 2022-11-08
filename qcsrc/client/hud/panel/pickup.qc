#include "pickup.qh"

#include <client/hud/hud.qh>
#include <common/items/inventory.qh>

// Pickup

void HUD_Pickup_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

void HUD_Pickup()
{
	if(!autocvar_hud_panel_pickup) return;

	HUD_Panel_LoadCvars();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_score_dynamichud)
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
	entity it = last_pickup_item;

	if((last_pickup_time && last_pickup_time > time - 3 && it) || autocvar__hud_configure) {
		float a;
		string str1, str2, icon;
		vector sz, sz2;
		vector fontsize = '1 1 0' * mySize.y;
		vector iconsize = fontsize * autocvar_hud_panel_pickup_iconsize;

		if(autocvar__hud_configure)
			icon = strcat(hud_skin_path, "/weaponnex");
		else
			icon = strcat(hud_skin_path, "/", ((it.model2) ? it.model2 : it.m_icon));

		sz = draw_getimagesize(icon);
		sz2 = vec2(iconsize.y*(sz.x/sz.y), iconsize.y);
		if(autocvar__hud_configure)
			str2 = "Medium Health";
		else
			str2 = ((last_pickup_times > 1) ? sprintf("%s (x%d)", it.m_name, last_pickup_times) : it.m_name);

		if(autocvar__hud_configure)
			a = 1;
		else if(time < last_pickup_time + 3 - 0.5)
			a = 1;
		else
			a = (last_pickup_time + 3 - time) / 0.5;

		if(autocvar_hud_panel_pickup_timer) {
			// 1 will show the timer always
			// 2 will show the timer only if spectating
			// forbid serverflag will force the 2nd behavior
			if((autocvar_hud_panel_pickup_timer == 1 && !(serverflags & SERVERFLAG_FORBID_PICKUPTIMER)) || spectatee_status)
			{
				str1 = seconds_tostring(last_pickup_timer);
				drawstring(pos, str1, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
				pos.x += stringwidth(str1, false, fontsize) + fontsize.x * 0.25;
			}
		}

		drawpic(pos - eY * ((iconsize.y - fontsize.y) / 2), icon, sz2, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		pos.x += sz2.x + fontsize.x * 0.25;
		drawstring(pos, str2, fontsize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}
}
