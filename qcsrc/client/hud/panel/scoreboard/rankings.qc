#include "rankings.qh"

#include "scoreboard.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <client/hud/panel/racetimer.qh>
#include <client/main.qh>
#include <common/ent_cs.qh>
#include <common/mutators/base.qh>
#include <common/util.qh>


vector Scoreboard_Rankings_Draw(vector pos, string ranktitle, entity pl, vector rgb, vector bg_size)
{
	int i;
	RANKINGS_RECEIVED_CNT = 0;
	for (i = RANKINGS_CNT; i > 0; --i)
		if (grecordtime[i - 1])
			++RANKINGS_RECEIVED_CNT;

	if (RANKINGS_RECEIVED_CNT == 0)
		return pos;

	vector hl_rgb = rgb + '0.5 0.5 0.5';

	vector scoreboard_selected_hl_pos = pos;

	if (!autocvar_hud_panel_scoreboard_minimal)
	{
		drawstring(pos + eX * panel_bg_padding, ranktitle, hud_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += 1.25 * hud_fontsize.y;
	}
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	vector scoreboard_selected_hl_size = '0 0 0';
	scoreboard_selected_hl_size.x = fixed_scoreboard_width;
	scoreboard_selected_hl_size.y = pos.y - scoreboard_selected_hl_pos.y;

	panel_pos = pos;

	float f, namesize = 0;
	for (i = 0; i < RANKINGS_RECEIVED_CNT; ++i)
	{
		f = stringwidth(ColorTranslateRGB(grecordholder[i]), true, hud_fontsize);
		if (f > namesize)
			namesize = f;
	}
	bool cut;
	if (namesize > autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x)
	{
		namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
		cut = true;
	}
	else
		cut = false;

	float ranksize = 3 * hud_fontsize.x;
	float timesize = 5 * hud_fontsize.x;
	vector columnsize = vec2(ranksize + timesize + namesize + hud_fontsize.x, 1.25 * hud_fontsize.y);
	rankings_columns = max(1, floor((panel_size.x - 2 * panel_bg_padding) / columnsize.x));
	rankings_columns = min(rankings_columns, RANKINGS_RECEIVED_CNT);
	if (!rankings_cnt)
	{
		rankings_cnt = RANKINGS_RECEIVED_CNT;
		rankings_rows = ceil(rankings_cnt / rankings_columns);
	}

	// expand name column to fill the entire row
	float available_space = (panel_size.x - 2 * panel_bg_padding - columnsize.x * rankings_columns) / rankings_columns;
	namesize += available_space;
	columnsize.x += available_space;

	panel_size.y = rankings_rows * 1.25 * hud_fontsize.y;
	panel_size.y += panel_bg_padding * 2;
	scoreboard_selected_hl_size.y += panel_size.y;

	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
	{
		panel_pos  += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, "gfx/scoreboard/scoreboard_bg", bg_size, panel_size, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

	vector text_ofs = vec2(0.5 * hud_fontsize.x, (1.25 - 1) * 0.5 * hud_fontsize.y); // center text vertically
	string str = "";
	int column = 0, j = 0;
	string zoned_name_self = strzone(strdecolorize(entcs_GetName(player_localnum)));
	int start_item = rankings_start_column * rankings_rows;
	for (i = start_item; i < start_item + rankings_cnt; ++i)
	{
		int t = grecordtime[i];
		if (t == 0)
			continue;

		if (strdecolorize(grecordholder[i]) == zoned_name_self)
			drawfill(pos, columnsize, hl_rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
		else if (!((j + rankings_start_column + column) & 1) && sbt_highlight)
			drawfill(pos, columnsize, hl_rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

		str = count_ordinal(i + 1);
		vector rank_color;
		switch (i)
		{
			case 0:  rank_color = '0.933 0.733 0.200'; break; // 1st; gold
			case 1:  rank_color = '0.667 0.667 0.667'; break; // 2nd; silver
			case 2:  rank_color = '0.800 0.467 0.267'; break; // 3rd; bronze
			default: rank_color = '1 1 1';
		}
		drawstring(pos + text_ofs, str, hud_fontsize, rank_color, sbt_fg_alpha, DRAWFLAG_NORMAL);
		drawstring(pos + text_ofs + eX * ranksize, TIME_ENCODED_TOSTRING(t, true), hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
		str = ColorTranslateRGB(grecordholder[i]);
		if (cut)
			str = textShortenToWidth(str, namesize, hud_fontsize, stringwidth_colors);
		drawcolorcodedstring(pos + text_ofs + eX * (ranksize + timesize), str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);

		pos.y += 1.25 * hud_fontsize.y;
		++j;
		if (j >= rankings_rows)
		{
			++column;
			j = 0;
			pos.x += panel_size.x / rankings_columns;
			pos.y = panel_pos.y;
		}
	}
	strfree(zoned_name_self);

	if (scoreboard_selected_panel == SB_PANEL_RANKINGS)
	{
		float fade = max(0, (1 - (time - scoreboard_selected_panel_time) * 2));
		drawfill(scoreboard_selected_hl_pos, scoreboard_selected_hl_size, '1 1 1', fade * 0.44, DRAWFLAG_NORMAL);
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

/// Draws the rankings and (if any) race awards, if the ShowRankings hook permits
vector Scoreboard_RankingsAndAwards_Draw(vector pos, vector bg_size, bool deathscoreboard)
{
	if (MUTATOR_CALLHOOK(ShowRankings, deathscoreboard))
	{
		string ranktitle = M_ARGV(1, string);
		if (race_speedaward_alltimebest)
		{
			string unit = GetSpeedUnit(autocvar_hud_speed_unit);
			float conversion_factor = GetSpeedUnitFactor(autocvar_hud_speed_unit);
			float namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
			string name, str = "";
			if (race_speedaward)
			{
				name = textShortenToWidth(ColorTranslateRGB(race_speedaward_holder), namesize, hud_fontsize, stringwidth_colors);
				str = sprintf(_("Speed award: %d%s ^7(%s^7)"), race_speedaward * conversion_factor, unit, name);
				str = strcat(str, " / ");
			}
			name = textShortenToWidth(ColorTranslateRGB(race_speedaward_alltimebest_holder), namesize, hud_fontsize, stringwidth_colors);
			str = strcat(str, sprintf(_("All-time fastest: %d%s ^7(%s^7)"), race_speedaward_alltimebest * conversion_factor, unit, name));

			vector tmp = pos;
			tmp.x += 0.5 * (panel_size.x - stringwidth_colors(str, hud_fontsize)); // center
			drawcolorcodedstring(tmp, str, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.y += 1.25 * hud_fontsize.y; // line height + line spacing
		}

		return Scoreboard_Rankings_Draw(pos, ranktitle, playerslots[player_localnum], panel_bg_color, bg_size);
	}

	rankings_cnt = 0;
	return pos;
}
