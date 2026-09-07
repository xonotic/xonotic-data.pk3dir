#include "mapstats.qh"

#include "scoreboard.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <common/stats.qh>


vector MapStats_DrawKeyValue(vector pos, string key, string value)
{
	float px = pos.x;
	pos.x += hud_fontsize.x * 0.25;
	drawstring(pos, key, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = panel_pos.x + panel_size.x - stringwidth(value, false, hud_fontsize) - hud_fontsize.x * 0.25;
	drawstring(pos, value, hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
	pos.x = px;
	pos.y += hud_fontsize.y;

	return pos;
}

vector Scoreboard_MapStats_Draw(vector pos, vector rgb, vector bg_size)
{
	// Get monster stats
	int stat_monsters_killed = STAT(MONSTERS_KILLED);
	int stat_monsters_total  = STAT(MONSTERS_TOTAL);

	// Get secrets stats
	int stat_secrets_found = STAT(SECRETS_FOUND);
	int stat_secrets_total = STAT(SECRETS_TOTAL);

	// Get number of rows
	int rows = (stat_secrets_total > 0) + (stat_monsters_total > 0);
	if (!rows)
		return pos;

	// Draw table header
	drawstring(pos + eX * panel_bg_padding, _("Map stats:"), hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	pos.y += 1.25 * hud_fontsize.y;
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = hud_fontsize.y * rows;
	panel_size.y += panel_bg_padding * 2;
	HUD_Panel_DrawBg();

	vector end_pos = panel_pos;
	end_pos.y += panel_size.y + 0.5 * hud_fontsize.y;
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
	{
		panel_pos  += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, SCOREBOARD_BG_PATH, bg_size, panel_size, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

	// Draw monsters
	string val;
	if (stat_monsters_total)
	{
		val = sprintf("%d/%d", stat_monsters_killed, stat_monsters_total);
		pos = MapStats_DrawKeyValue(pos, _("Monsters killed:"), val);
	}

	// Draw secrets
	if (stat_secrets_total)
	{
		val = sprintf("%d/%d", stat_secrets_found, stat_secrets_total);
		pos = MapStats_DrawKeyValue(pos, _("Secrets found:"), val);
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}
