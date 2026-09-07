#include "table.qh"

#include "scoreboard.qh"
#include "fields.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <common/ent_cs.qh>
#include <common/teams.qh>

bool autocvar_hud_panel_scoreboard_others_showscore = true;
bool autocvar_hud_panel_scoreboard_spectators_showping = true;
bool autocvar_hud_panel_scoreboard_spectators_aligned = false;

float autocvar_hud_panel_scoreboard_maxheight = 0.6;


vector Scoreboard_DrawHeader(vector pos, vector rgb, bool other_players, bool draw_text)
{
	vector column_dim = vec2(0, panel_size.y);
	if (other_players)
		column_dim.y -= 1.25 * hud_fontsize.y;
	vector text_offset = vec2(0, (1.25 - 1) * 0.5 * hud_fontsize.y);
	pos.x += hud_fontsize.x * 0.5;

	int i;
	for (i = 0; i < sbt_num_fields; ++i)
	{
		if (sbt_field[i] == SP_SEPARATOR)
			break;
		column_dim.x = sbt_field_size[i] + hud_fontsize.x;
		if (sbt_highlight && (i % 2))
			drawfill(pos - eX * hud_fontsize.x * 0.5, column_dim, '0 0 0', sbt_highlight_alpha, DRAWFLAG_NORMAL);

		if (draw_text)
		{
			vector prev_drawfontscale = drawfontscale;
			if (sbt_field_title_condense_factor[i])
				drawfontscale.x *= sbt_field_title_condense_factor[i];
			drawstring(pos + text_offset, sbt_field_title[i], hud_fontsize, rgb * 1.5, sbt_fg_alpha, DRAWFLAG_NORMAL);
			if (sbt_field_title_condense_factor[i])
			{
				drawfontscale.x *= sbt_field_title_condense_factor[i];
				drawfontscale = prev_drawfontscale;
			}
		}
		pos.x += column_dim.x;
	}

	if (sbt_field[i] == SP_SEPARATOR)
	{
		pos.x = panel_pos.x + panel_size.x - hud_fontsize.x * 0.5;
		vector prev_drawfontscale;
		float titlewidth;
		for (i = sbt_num_fields - 1; i > 0; --i)
		{
			if (sbt_field[i] == SP_SEPARATOR)
				break;

			pos.x -= sbt_field_size[i];

			if (sbt_highlight && !(i % 2))
			{
				column_dim.x = sbt_field_size[i] + hud_fontsize.x;
				drawfill(pos - eX * hud_fontsize.x * 0.5, column_dim, '0 0 0', sbt_highlight_alpha, DRAWFLAG_NORMAL);
			}

			if (draw_text)
			{
				prev_drawfontscale = drawfontscale;
				titlewidth = stringwidth(sbt_field_title[i], false, hud_fontsize);
				if (sbt_field_title_condense_factor[i])
				{
					drawfontscale.x *= sbt_field_title_condense_factor[i];
					text_offset.x = sbt_field_size[i] - titlewidth * sbt_field_title_condense_factor[i];
				}
				else
					text_offset.x = sbt_field_size[i] - titlewidth;
				drawstring(pos + text_offset, sbt_field_title[i], hud_fontsize, rgb * 1.5, sbt_fg_alpha, DRAWFLAG_NORMAL);
				if (sbt_field_title_condense_factor[i])
				{
					drawfontscale.x *= sbt_field_title_condense_factor[i];
					drawfontscale = prev_drawfontscale;
				}
			}
			pos.x -= hud_fontsize.x;
		}
	}

	pos.x = panel_pos.x;
	if (draw_text)
		pos.y += 1.25 * hud_fontsize.y;
	return pos;
}

void Scoreboard_DrawItem(vector item_pos, vector rgb, entity pl, bool is_self, int pl_number)
{
	TC(bool, is_self); TC(int, pl_number);
	string str;
	bool is_spec = (entcs_GetSpecState(pl.sv_entnum) == ENTCS_SPEC_PURE);

	vector h_pos = item_pos;
	vector h_size = vec2(panel_size.x, hud_fontsize.y * 1.25);
	// alternated rows highlighting
	if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD && scoreboard_ui_enabled == 1)
	{
		if (pl == scoreboard_selected_player)
			drawfill(h_pos, h_size, rgb, 0.44 * panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else if (is_self)
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha_self, DRAWFLAG_NORMAL);
	else if (sbt_highlight && !(pl_number % 2))
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

	float fg_alpha = (is_self ? sbt_fg_alpha_self : sbt_fg_alpha);

	vector pos = item_pos;
	// put a "self indicator" beside the self row, unicode U+25C0 (black left-pointing triangle)
	if (is_self)
		drawstring(pos + eX * (panel_size.x + 0.5 * hud_fontsize.x) + eY, "\xE2\x97\x80", hud_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);

	pos.x += hud_fontsize.x * 0.5;
	pos.y += (1.25 - 1) * 0.5 * hud_fontsize.y; // center text vertically
	vector tmp = '0 0 0';
	vector icon_sz;
	int i, j;
	PlayerScoreField field;
	for (i = 0; i < sbt_num_fields; ++i)
	{
		field = sbt_field[i];
		if (field == SP_SEPARATOR)
			break;

		if (is_spec && field != SP_NAME && field != SP_PING)
		{
			pos.x += sbt_field_size[i] + hud_fontsize.x;
			continue;
		}
		str = Scoreboard_GetField(pl, field, autocvar_hud_panel_scoreboard_scores_per_round);
		str = Scoreboard_FixColumnWidth(i, str, false);

		pos.x += sbt_field_size[i] + hud_fontsize.x;

		if (field == SP_NAME)
		{
			tmp.x = sbt_field_size[i] + hud_fontsize.x
				- hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor;
			for (j = 0; j < sbt_field_icon_extra_set; ++j)
				tmp.x -= hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[j];
			if (sbt_fixcolumnwidth_iconlen_playercolor || sbt_field_icon_extra_set) // playercolor/extra icons next to name
				tmp.x -= sbt_fixcolumnwidth_marginlen;
			if (teamplay)
			{
				int wants_join = entcs_GetWantsJoin(pl.sv_entnum);
				if (wants_join)
				{
					vector tmcolor = Team_ColorRGB(Team_IndexToTeam(wants_join)) * min(1, 1 + sin(2*M_PI * time));
					drawstring(pos - tmp, "(Q)", hud_fontsize, tmcolor, sbt_fg_alpha, DRAWFLAG_NORMAL);
					tmp.x -= stringwidth("(Q) ", false, hud_fontsize);
				}
			}
			drawcolorcodedstring(pos - tmp, str, hud_fontsize, fg_alpha, DRAWFLAG_NORMAL);

			tmp.x = sbt_field_size[i] + hud_fontsize.x;
			icon_sz = vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor, hud_fontsize.y);
			for (j = 0; j < sbt_field_icon_playercolor_set; ++j)
				drawpic(pos - tmp, sbt_field_icon_playercolor[j], icon_sz, sbt_field_icon_playercolor_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
			for (j = 0; j < sbt_field_icon_extra_set; ++j)
			{
				tmp.x -= icon_sz.x;
				icon_sz.x = hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[j];
				drawpic(pos - tmp, sbt_field_icon_extra[j], icon_sz, sbt_field_icon_extra_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
			}
			tmp.x = hud_fontsize.x * 0.5; // gametype icons on the right
			for (j = 0; j < sbt_field_icon_gametype_set; ++j)
			{
				icon_sz.x = hud_fontsize.x * sbt_fixcolumnwidth_iconlen_gametype[j];
				tmp.x += icon_sz.x;
				drawpic_skin(pos - tmp, sbt_field_icon_gametype[j], icon_sz, '1 1 1', fg_alpha, DRAWFLAG_NORMAL);
			}
		}
		else
		{
			tmp.x = sbt_fixcolumnwidth_len + hud_fontsize.x;
			drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, fg_alpha, DRAWFLAG_NORMAL);
		}
	}

	if (sbt_field[i] == SP_SEPARATOR)
	{
		pos.x = item_pos.x + panel_size.x - hud_fontsize.x * 0.5;
		for (i = sbt_num_fields-1; i > 0; --i)
		{
			field = sbt_field[i];
			if (field == SP_SEPARATOR)
				break;

			if (is_spec && field != SP_NAME && field != SP_PING)
			{
				pos.x -= sbt_field_size[i] + hud_fontsize.x;
				continue;
			}

			str = Scoreboard_GetField(pl, field, autocvar_hud_panel_scoreboard_scores_per_round);
			str = Scoreboard_FixColumnWidth(i, str, false);

			if (field == SP_NAME)
			{
				tmp.x = sbt_fixcolumnwidth_len; // left or right aligned? let's put it right...
				for (j = 0; j < sbt_field_icon_extra_set; ++j)
					tmp.x += hud_fontsize.x * sbt_fixcolumnwidth_iconlen_gametype[j];
				if (sbt_field_icon_gametype_set) // gametype icons next to name
					tmp.x += sbt_fixcolumnwidth_marginlen;
				drawcolorcodedstring(pos - tmp, str, hud_fontsize, fg_alpha, DRAWFLAG_NORMAL);

				tmp.x = sbt_field_size[i];
				icon_sz = vec2(hud_fontsize.x * sbt_fixcolumnwidth_iconlen_playercolor, hud_fontsize.y);
				for (j = 0; j < sbt_field_icon_playercolor_set; ++j)
					drawpic(pos - tmp, sbt_field_icon_playercolor[j], icon_sz, sbt_field_icon_playercolor_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
				for (j = 0; j < sbt_field_icon_extra_set; ++j)
				{
					tmp.x -= icon_sz.x;
					icon_sz.x = hud_fontsize.x * sbt_fixcolumnwidth_iconlen_extra[j];
					drawpic(pos - tmp, sbt_field_icon_extra[j], icon_sz, sbt_field_icon_extra_rgb[j], fg_alpha, DRAWFLAG_NORMAL);
				}
				tmp.x = 0; // gametype icons on the right
				for (j = 0; j < sbt_field_icon_gametype_set; ++j)
				{
					icon_sz.x = hud_fontsize.x * sbt_fixcolumnwidth_iconlen_gametype[j];
					tmp.x -= icon_sz.x;
					drawpic_skin(pos + tmp, sbt_field_icon_gametype[j], icon_sz, '1 1 1', fg_alpha, DRAWFLAG_NORMAL);
				}
			}
			else
			{
				tmp.x = sbt_fixcolumnwidth_len;
				drawstring(pos - tmp, str, hud_fontsize, sbt_field_rgb, fg_alpha, DRAWFLAG_NORMAL);
			}
			pos.x -= sbt_field_size[i] + hud_fontsize.x;
		}
	}

	if (pl.eliminated)
		drawfill(h_pos, h_size, '0 0 0', sbt_highlight_alpha_eliminated, DRAWFLAG_NORMAL);
}

vector Scoreboard_DrawOthers(vector item_pos, vector rgb, int this_team, entity excluded_pl, entity pl, int pl_number)
{
	int i = 0;
	vector h_pos = item_pos;
	vector h_size = vec2(panel_size.x, hud_fontsize.y * 1.25);

	bool complete = (this_team == NUM_SPECTATOR);

	if (!complete && sbt_highlight && !(pl_number % 2))
		drawfill(h_pos, h_size, rgb, sbt_highlight_alpha, DRAWFLAG_NORMAL);

	vector pos = item_pos;
	pos.x += hud_fontsize.x * 0.5;
	pos.y += (1.25 - 1) / 2 * hud_fontsize.y; // center text vertically

	float width_limit = item_pos.x + panel_size.x - hud_fontsize.x;
	if (!complete)
		width_limit -= stringwidth("...", false, hud_fontsize);
	float namesize = autocvar_hud_panel_scoreboard_namesize * hud_fontsize.x;
	static float max_name_width = 0;
	string field = "";
	float fieldsize = 0;
	float min_fieldsize = 0;
	float fieldpadding = hud_fontsize.x * 0.25;
	if (this_team == NUM_SPECTATOR)
	{
		if (autocvar_hud_panel_scoreboard_spectators_showping)
			min_fieldsize = stringwidth("999", false, hud_fontsize);
	}
	else if (autocvar_hud_panel_scoreboard_others_showscore)
		min_fieldsize = stringwidth("99", false, hud_fontsize);
	for (i = 0; pl; pl = pl.sort_next)
	{
		if (pl.team != this_team)
			continue;
		if (pl == excluded_pl)
			continue;

		field = "";
		if (this_team == NUM_SPECTATOR)
		{
			if (autocvar_hud_panel_scoreboard_spectators_showping)
				field = Scoreboard_GetField(pl, SP_PING, autocvar_hud_panel_scoreboard_scores_per_round);
		}
		else if (autocvar_hud_panel_scoreboard_others_showscore)
			field = Scoreboard_GetField(pl, SP_SCORE, autocvar_hud_panel_scoreboard_scores_per_round);

		string str = entcs_GetName(pl.sv_entnum);
		if (autocvar_hud_panel_scoreboard_playerid)
			str = Scoreboard_AddPlayerId(str, pl);

		// ignored_size includes icon and padding
		float ignored_size = (pl.ignored ? hud_fontsize.y + hud_fontsize.x * 0.25 : 0);
		int wants_join = (teamplay ? entcs_GetWantsJoin(pl.sv_entnum) : 0);
		float queued_size = (wants_join ? stringwidth("(Q) ", false, hud_fontsize) : 0);
		str = textShortenToWidth(str, namesize - ignored_size - queued_size, hud_fontsize, stringwidth_colors);
		float column_width = stringwidth(str, true, hud_fontsize) + ignored_size + queued_size;
		if ((this_team == NUM_SPECTATOR) && autocvar_hud_panel_scoreboard_spectators_aligned)
		{
			if (column_width > max_name_width)
				max_name_width = column_width;
			column_width = max_name_width;
		}
		if (field != "")
		{
			fieldsize = stringwidth(field, false, hud_fontsize);
			column_width += hud_fontsize.x * 0.25 + max(fieldsize, min_fieldsize) + 2 * fieldpadding;
		}

		if (pos.x + column_width > width_limit)
		{
			++i;
			if (!complete)
			{
				drawstring(pos, "...", hud_fontsize, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
				break;
			}
			else
			{
				pos.x = item_pos.x + hud_fontsize.x * 0.5;
				pos.y += hud_fontsize.y * 1.25;
			}
		}

		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD && scoreboard_ui_enabled == 1)
		{
			if (pl == scoreboard_selected_player)
			{
				h_size.x = column_width + hud_fontsize.x * 0.25;
				h_size.y = hud_fontsize.y;
				drawfill(pos - hud_fontsize.x * 0.25 * eX, h_size, rgb, 0.44 * panel_fg_alpha, DRAWFLAG_NORMAL);
			}
		}

		vector name_pos = pos;
		if (this_team == NUM_SPECTATOR && autocvar_hud_panel_scoreboard_spectators_aligned)
			name_pos.x += max(fieldsize, min_fieldsize) + 2 * fieldpadding + hud_fontsize.x * 0.25;
		if (pl.ignored)
		{
			drawpic(name_pos, "gfx/scoreboard/player_ignored", '1 1 0' * hud_fontsize.y, '1 1 1', sbt_fg_alpha, DRAWFLAG_NORMAL);
			name_pos.x += ignored_size;
		}
		if (wants_join)
		{
			vector tmcolor = Team_ColorRGB(Team_IndexToTeam(wants_join)) * min(1, 1 + sin(2*M_PI * time));
			drawstring(name_pos, "(Q)", hud_fontsize, tmcolor, sbt_fg_alpha, DRAWFLAG_NORMAL);
			name_pos.x += queued_size;
		}
		drawcolorcodedstring(name_pos, str, hud_fontsize, sbt_fg_alpha, DRAWFLAG_NORMAL);

		if (field != "")
		{
			h_size.x = max(fieldsize, min_fieldsize) + 2 * fieldpadding;
			h_size.y = hud_fontsize.y;
			vector field_pos = pos;
			if (!(this_team == NUM_SPECTATOR && autocvar_hud_panel_scoreboard_spectators_aligned))
				field_pos.x += column_width - h_size.x;
			if (sbt_highlight)
				drawfill(field_pos, h_size, '1 1 1', sbt_highlight_alpha, DRAWFLAG_NORMAL);
			field_pos.x += fieldpadding + (max(fieldsize, min_fieldsize) - fieldsize) * 0.5;
			drawstring(field_pos, field, hud_fontsize, sbt_field_rgb, sbt_fg_alpha, DRAWFLAG_NORMAL);
		}
		if (pl.eliminated)
		{
			h_size.x = column_width + hud_fontsize.x * 0.25;
			h_size.y = hud_fontsize.y;
			drawfill(pos - hud_fontsize.x * 0.25 * eX, h_size, '0 0 0', sbt_highlight_alpha_eliminated, DRAWFLAG_NORMAL);
		}
		pos.x += column_width;
		pos.x += hud_fontsize.x;
	}
	return vec2(item_pos.x, item_pos.y + i * hud_fontsize.y * 1.25);
}

vector Scoreboard_MakeTable(vector pos, entity tm, vector rgb, vector bg_size, bool is_header)
{
	// is_header is whether we're drawing the header table (minimal scoreboard)
	int max_players = 999;
	int tm_size = (!is_header ? tm.team_size : 0);
	if (autocvar_hud_panel_scoreboard_maxheight > 0)
	{
		float height = autocvar_hud_panel_scoreboard_maxheight * vid_conheight;
		if (teamplay)
		{
			if (autocvar_hud_panel_scoreboard_minimal)
				height -= (panel_bg_padding * 2) * (team_count + 1) // - padding
					+ hud_fontsize.y * 1.25; // - header
			else
				height -= (panel_bg_padding * 2 + hud_fontsize.y * 1.25) * team_count // - padding and header
					+ hud_fontsize.y * (team_count - 1); // - spacing between tables
			height /= team_count;
		}
		else
			height -= panel_bg_padding * 2; // - padding
		max_players = floor(height / (hud_fontsize.y * 1.25));
		if (max_players <= 1)
			max_players = 1;
		if (max_players == tm_size)
			max_players = 999;
	}

	bool draw_header = !(autocvar_hud_panel_scoreboard_minimal && teamplay && !is_header);

	panel_pos = pos;
	panel_size.y = 1.25 * hud_fontsize.y * (draw_header + bound(!is_header, tm_size, max_players));
	panel_size.y += panel_bg_padding * 2;

	vector scoreboard_selected_hl_pos = pos;
	vector scoreboard_selected_hl_size = '0 0 0';
	scoreboard_selected_hl_size.x = fixed_scoreboard_width;
	scoreboard_selected_hl_size.y = panel_size.y;

	HUD_Panel_DrawBg();

	vector end_pos = panel_pos + eY * panel_size.y;
	if (!(autocvar_hud_panel_scoreboard_minimal && teamplay))
		end_pos.y += 0.5 * hud_fontsize.y;
	if (panel.current_panel_bg != "0")
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
	{
		panel_pos  += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	vector tmp = vec2(panel_size.x, 1.25 * hud_fontsize.y);

	// rounded header
	if (draw_header)
	{
		if (sbt_bg_alpha)
			drawpic(pos, "gfx/scoreboard/scoreboard_tableheader", tmp, rgb + '0.5 0.5 0.5', sbt_bg_alpha, DRAWFLAG_NORMAL);
		pos.y += 1.25 * hud_fontsize.y;
		tmp.y = panel_size.y - 1.25 * hud_fontsize.y;
	}

	// table background
	if (sbt_bg_alpha && tm)
		drawpic_tiled(pos, SCOREBOARD_BG_PATH, bg_size, tmp, rgb, sbt_bg_alpha, DRAWFLAG_NORMAL);

	// highlight columns, and print header row if draw_header
	pos = Scoreboard_DrawHeader(panel_pos, rgb, (max_players < tm_size), draw_header);

	if (!is_header)
	{
		// fill the table and draw the rows
		bool is_self = false;
		bool self_shown = false;
		int i = 0;
		entity me = playerslots[current_player];
		for (entity pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if (pl.team != tm.team)
				continue;
			if (i == max_players - 2 && pl != me
			&& !self_shown && me.team == tm.team)
			{
				Scoreboard_DrawItem(pos, rgb, me, true, i);
				self_shown = true;
				pos.y += 1.25 * hud_fontsize.y;
				++i;
			}
			if (i >= max_players - 1)
			{
				pos = Scoreboard_DrawOthers(pos, rgb, tm.team, (self_shown ? me : NULL), pl, i);
				break;
			}
			is_self = (pl.sv_entnum == current_player);
			Scoreboard_DrawItem(pos, rgb, pl, is_self, i);
			if (is_self)
				self_shown = true;
			pos.y += 1.25 * hud_fontsize.y;
			++i;
		}

		if (scoreboard_selected_panel == SB_PANEL_SCOREBOARD
		&& (scoreboard_ui_enabled == 1 || scoreboard_selected_team == tm))
		{
			float hl_alpha = (scoreboard_ui_enabled == 2) ? 0.2 : 0.3 * max(0, 1 - (time - scoreboard_selected_panel_time) * 2);
			hl_alpha *= panel_fg_alpha;
			if (hl_alpha)
				drawfill(scoreboard_selected_hl_pos, scoreboard_selected_hl_size, '0.75 0.75 0.75' + 0.25 * rgb, hl_alpha, DRAWFLAG_NORMAL);
		}
	}

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}
