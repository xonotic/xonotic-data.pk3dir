#include "notify.qh"

#include <client/draw.qh>
#include <client/hud/panel/scoreboard/scoreboard.qh>
#include <client/view.qh>

const int NOTIFY_MAX_ENTRIES = 10;
const float NOTIFY_ICON_MARGIN = 0.02;

int notify_index;
int notify_count;
float notify_times[NOTIFY_MAX_ENTRIES];
string notify_attackers[NOTIFY_MAX_ENTRIES];
string notify_victims[NOTIFY_MAX_ENTRIES];
string notify_icons[NOTIFY_MAX_ENTRIES];
bool notify_highlight[NOTIFY_MAX_ENTRIES];

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

	int i, n = tokenizebyseparator(autocvar_hud_panel_notify_list_exclude, " ");
	for (i = 0; i < n; ++i)
		if (icon == argv(i))
			return;

	++notify_count;
	--notify_index;

	if (notify_index == -1)
		notify_index = NOTIFY_MAX_ENTRIES - 1;

	// Allocate new strings
	if (victim != "")
	{
		strcpy(notify_victims[notify_index], victim);
		strcpy(notify_attackers[notify_index], attacker);
	}
	else
	{
		// In case of a notification without a victim, the attacker
		// is displayed on the victim's side. Instead of special
		// treatment later on, we can simply switch them here.
		strcpy(notify_victims[notify_index], attacker);
		if (notify_attackers[notify_index])
		{
			strunzone(notify_attackers[notify_index]);
			notify_attackers[notify_index] = string_null;
		}
	}

	notify_highlight[notify_index] = false;
	n = tokenizebyseparator(autocvar_hud_panel_notify_list_highlight, " ");
	for (i = 0; i < n; ++i)
		if (icon == argv(i))
		{
			notify_highlight[notify_index] = true;
			break;
		}

	strcpy(notify_icons[notify_index], icon);
	notify_times[notify_index] = time;
}

void HUD_Notify(bool should_draw)
{
	if (!should_draw)
		return;
	if (!autocvar__hud_configure && !autocvar_hud_panel_notify)
		return;

	HUD_Panel_LoadCvars();

	if (scoreboard_fade_alpha)
	{
		float minalpha;
		if (notify_count == 0)
			minalpha = 0; // hide if empty
		else if (boxesoverlap(panel_pos, panel_pos + panel_size, scoreboard_pos, scoreboard_bottom))
			minalpha = 0.5; // transparent if overlaps the scoreboard
		else
			minalpha = 1;
		float f = max(minalpha, 1 - scoreboard_fade_alpha);
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

	vector pos = panel_pos;
	vector size = panel_size;

	if (panel_bg_padding)
	{
		pos  += '1 1 0' * panel_bg_padding;
		size -= '2 2 0' * panel_bg_padding;
	}

	float fade_start = max(0, autocvar_hud_panel_notify_time);
	if (intermission) // fade out in half the time
		fade_start -= time - intermission_time;
	float fade_time = max(0, autocvar_hud_panel_notify_fadetime);
	float icon_aspect = max(1, autocvar_hud_panel_notify_icon_aspect);

	int entry_count = bound(1, floor(NOTIFY_MAX_ENTRIES * size.y / size.x), NOTIFY_MAX_ENTRIES);
	float entry_height = size.y / entry_count;

	float panel_width_half = size.x * 0.5;
	float icon_width_half = entry_height * icon_aspect * 0.5;
	float name_maxwidth = panel_width_half - icon_width_half - size.x * NOTIFY_ICON_MARGIN;

	vector font_size = '0.5 0.5 0' * entry_height * autocvar_hud_panel_notify_fontsize;
	vector icon_size = vec2(icon_aspect, 1) * entry_height;
	vector icon_left = vec2(panel_width_half - icon_width_half, 0);
	vector attacker_right = vec2(name_maxwidth, 0);
	vector victim_left = vec2(size.x - name_maxwidth, 0);

	vector attacker_pos, victim_pos, icon_pos;
	string attacker, victim, icon;

	int i, step, limit;
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

	vector name_top;
	float alpha;
	int count = 0;
	for (int j = notify_index; i != limit; i += step, ++j, ++count)
	{
		if (autocvar__hud_configure)
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

			victim = notify_victims[j];
			icon = notify_icons[j];
			if (icon == "" || victim == "")
				continue;
			attacker = notify_attackers[j];
		}

		name_top = vec2(0, i * entry_height + 0.5 * (entry_height - font_size.y));
		icon_pos = pos + icon_left;
		icon_pos.y += i * entry_height;

		victim = textShortenToWidth(ColorTranslateRGB(victim), name_maxwidth, font_size, stringwidth_colors);
		victim_pos = pos + victim_left + name_top;
		drawcolorcodedstring(victim_pos, victim, font_size, panel_fg_alpha * alpha, DRAWFLAG_NORMAL);

		if (attacker != "")
		{
			attacker = textShortenToWidth(ColorTranslateRGB(attacker), name_maxwidth, font_size, stringwidth_colors);
			attacker_pos = pos + attacker_right + name_top;
			attacker_pos.x -= stringwidth(attacker, true, font_size); // align right
			drawcolorcodedstring(attacker_pos, attacker, font_size, panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
		}

		if (notify_highlight[j])
			alpha *= blink(0.85, 0.15, 5);

		drawpic_aspect_skin(icon_pos, icon, icon_size, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
		if (notify_highlight[j])
		{
			float f = bound(0, (time - notify_times[j]) * 2, 1);
			if (f < 1)
				drawpic_aspect_skin_expanding(icon_pos, icon, icon_size, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL, f);
		}
	}

	notify_count = count;
}
