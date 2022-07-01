#include "notify.qh"

#include <client/draw.qh>
#include <client/hud/panel/scoreboard.qh>
#include <client/view.qh>

// Notifications (#4)

void HUD_Notify_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_notify_flip");
	HUD_Write_Cvar("hud_panel_notify_fontsize");
	HUD_Write_Cvar("hud_panel_notify_time");
	HUD_Write_Cvar("hud_panel_notify_fadetime");
	HUD_Write_Cvar("hud_panel_notify_icon_aspect");
}

void HUD_Notify_Push(string icon, string attacker, string victim)
{
	if (icon == "")
		return;

	++notify_count;
	--notify_index;

	if (notify_index == -1)
		notify_index = NOTIFY_MAX_ENTRIES-1;

	// Free old strings
	if (notify_attackers[notify_index])
		strunzone(notify_attackers[notify_index]);

	if (notify_victims[notify_index])
		strunzone(notify_victims[notify_index]);

	if (notify_icons[notify_index])
		strunzone(notify_icons[notify_index]);

	// Allocate new strings
	if (victim != "")
	{
		notify_attackers[notify_index] = strzone(attacker);
		notify_victims[notify_index] = strzone(victim);
	}
	else
	{
		// In case of a notification without a victim, the attacker
		// is displayed on the victim's side. Instead of special
		// treatment later on, we can simply switch them here.
		notify_attackers[notify_index] = string_null;
		notify_victims[notify_index] = strzone(attacker);
	}

	notify_icons[notify_index] = strzone(icon);
	notify_times[notify_index] = time;
}

void HUD_Notify()
{
	if (!autocvar__hud_configure && !autocvar_hud_panel_notify)
		return;

	HUD_Panel_LoadCvars();

	if (scoreboard_fade_alpha)
	{
		float minalpha = 1;
		if (notify_count == 0)
			minalpha = 0; // hide if empty
		else if (boxesoverlap(panel_pos, panel_pos + panel_size,
			eX * scoreboard_left + eY * scoreboard_top, eX * scoreboard_right + eY * scoreboard_bottom))
		{
			minalpha = 0.5; // transparent if it may overlap the scoreboard
		}
		float f = max(minalpha, (1 - scoreboard_fade_alpha));
		if (f <= 0)
			return;
		panel_bg_alpha *= f;
		panel_fg_alpha *= f;
	}

	if (autocvar_hud_panel_notify_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();

	if (!autocvar__hud_configure && notify_count == 0)
		return;

	vector pos, size;
	pos  = panel_pos;
	size = panel_size;

	if (panel_bg_padding)
	{
		pos  += '1 1 0' * panel_bg_padding;
		size -= '2 2 0' * panel_bg_padding;
	}

	float fade_start = max(0, autocvar_hud_panel_notify_time);
	if (intermission) // fade out in half the time
		fade_start -= (time - intermission_time);
	float fade_time = max(0, autocvar_hud_panel_notify_fadetime);
	float icon_aspect = max(1, autocvar_hud_panel_notify_icon_aspect);

	int entry_count = bound(1, floor(NOTIFY_MAX_ENTRIES * size.y / size.x), NOTIFY_MAX_ENTRIES);
	float entry_height = size.y / entry_count;

	float panel_width_half = size.x * 0.5;
	float icon_width_half = entry_height * icon_aspect / 2;
	float name_maxwidth = panel_width_half - icon_width_half - size.x * NOTIFY_ICON_MARGIN;

	vector font_size = '0.5 0.5 0' * entry_height * autocvar_hud_panel_notify_fontsize;
	vector icon_size = vec2(icon_aspect, 1) * entry_height;
	vector icon_left = eX * (panel_width_half - icon_width_half);
	vector attacker_right = eX * name_maxwidth;
	vector victim_left = eX * (size.x - name_maxwidth);

	vector attacker_pos, victim_pos, icon_pos;
	string attacker, victim, icon;
	int i, j, count, step, limit;
	float alpha;

	if (autocvar_hud_panel_notify_flip)
	{
		// Order items from the top down
		i = 0;
		step = +1;
		limit = entry_count;
	}
	else
	{
		// Order items from the bottom up
		i = entry_count - 1;
		step = -1;
		limit = -1;
	}

	for (j = notify_index, count = 0; i != limit; i += step, ++j, ++count)
	{
		if(autocvar__hud_configure)
		{
			attacker = sprintf(_("Player %d"), count + 1);
			victim = sprintf(_("Player %d"), count + 2);
			icon = REGISTRY_GET(Weapons, min(WEP_FIRST + count * 2, WEP_LAST)).model2;
			alpha = bound(0, 1.2 - count / entry_count, 1);
		}
		else
		{
			if (j == NOTIFY_MAX_ENTRIES)
				j = 0;

			if (notify_times[j] + fade_start > time)
				alpha = 1;
			else if (fade_time != 0)
			{
				alpha = bound(0, (notify_times[j] + fade_start + fade_time - time) / fade_time, 1);
				if (alpha == 0)
					break;
			}
			else
				break;

			attacker = notify_attackers[j];
			victim = notify_victims[j];
			icon = notify_icons[j];
		}

		if (icon != "" && victim != "")
		{
			vector name_top = eY * (i * entry_height + 0.5 * (entry_height - font_size.y));

			icon_pos = pos + icon_left + eY * i * entry_height;
			drawpic_aspect_skin(icon_pos, icon, icon_size, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);

			victim = textShortenToWidth(ColorTranslateRGB(victim), name_maxwidth, font_size, stringwidth_colors);
			victim_pos = pos + victim_left + name_top;
			drawcolorcodedstring(victim_pos, victim, font_size, panel_fg_alpha * alpha, DRAWFLAG_NORMAL);

			if (attacker != "")
			{
				attacker = textShortenToWidth(ColorTranslateRGB(attacker), name_maxwidth, font_size, stringwidth_colors);
				attacker_pos = pos + attacker_right - eX * stringwidth(attacker, true, font_size) + name_top;
				drawcolorcodedstring(attacker_pos, attacker, font_size, panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
			}
		}
	}

	notify_count = count;
}
