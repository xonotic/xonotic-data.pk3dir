#include "score.qh"

#include <client/draw.qh>
#include <client/hud/panel/scoreboard.qh>
#include <common/ent_cs.qh>
#include <common/scores.qh>

// Score (#7)

void HUD_Score_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_score_rankings");
}

void HUD_Score_Rankings(vector pos, vector mySize, entity me)
{
	float score;
	entity tm = NULL, pl;
	int SCOREPANEL_MAX_ENTRIES = 6;
	float SCOREPANEL_ASPECTRATIO = 2;
	int entries = bound(1, floor(SCOREPANEL_MAX_ENTRIES * mySize.y/mySize.x * SCOREPANEL_ASPECTRATIO), SCOREPANEL_MAX_ENTRIES);
	vector fontsize = '1 1 0' * (mySize.y/entries);

	vector rgb, score_color;
	rgb = '1 1 1';
	score_color = '1 1 1';

	float name_size = mySize.x*0.75;
	float spacing_size = mySize.x*0.04;
	const float highlight_alpha = 0.2;
	int i = 0, first_pl = 0;
	bool me_printed = false;
	string s;
	if (autocvar__hud_configure)
	{
		float players_per_team = 0;
		if (team_count)
		{
			// show team scores in the first line
			float score_size = mySize.x / team_count;
			players_per_team = max(2, ceil((entries - 1) / team_count));
			for(i=0; i<team_count; ++i) {
				if (i == floor((entries - 2) / players_per_team) || (entries == 1 && i == 0))
					HUD_Panel_DrawHighlight(pos + eX * score_size * i, vec2(score_size, fontsize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(pos + eX * score_size * i, ftos(175 - 23*i), vec2(score_size, fontsize.y), Team_ColorRGB(ColorByTeam(i)) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
			}
			first_pl = 1;
			pos.y += fontsize.y;
		}
		score = 10 + SCOREPANEL_MAX_ENTRIES * 3;
		for (i=first_pl; i<entries; ++i)
		{
			//simulate my score is lower than all displayed players,
			//so that I don't appear at all showing pure rankings.
			//This is to better show the difference between the 2 ranking views
			if (i == entries-1 && autocvar_hud_panel_score_rankings == 1)
			{
				rgb = '1 1 0';
				drawfill(pos, vec2(mySize.x, fontsize.y), rgb, highlight_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
				s = entcs_GetName(player_localnum);
				score = 7;
			}
			else
			{
				s = sprintf(_("Player %d"), i + 1 - first_pl);
				score -= 3;
			}

			if (team_count)
				score_color = Team_ColorRGB(ColorByTeam(floor((i - first_pl) / players_per_team))) * 0.8;
			s = textShortenToWidth(s, name_size, fontsize, stringwidth_colors);
			drawcolorcodedstring(pos + eX * (name_size - stringwidth(s, true, fontsize)), s, fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
			drawstring(pos + eX * (name_size + spacing_size), ftos(score), fontsize, score_color, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.y += fontsize.y;
		}
		return;
	}

	Scoreboard_UpdatePlayerTeams();
	if (team_count)
	{
		// show team scores in the first line
		float score_size = mySize.x / team_count;
		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == NUM_SPECTATOR)
				continue;
			if(!tm.team)
				continue;

			if (tm.team == myteam)
				drawfill(pos + eX * score_size * i, vec2(score_size, fontsize.y), '1 1 1', highlight_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
			drawstring_aspect(pos + eX * score_size * i, ftos(tm.(teamscores(ts_primary))), vec2(score_size, fontsize.y), Team_ColorRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
			++i;
		}
		first_pl = 1;
		pos.y += fontsize.y;
		tm = teams.sort_next;
	}
	i = first_pl;

	do
	for (pl = players.sort_next; pl && i<entries; pl = pl.sort_next)
	{
		if ((team_count && pl.team != tm.team) || pl.team == NUM_SPECTATOR)
			continue;

		if (i == entries-1 && !me_printed && pl != me)
		if (autocvar_hud_panel_score_rankings == 1 && spectatee_status != -1)
		{
			for (pl = me.sort_next; pl; pl = pl.sort_next)
				if (pl.team != NUM_SPECTATOR)
					break;

			if (pl)
				rgb = '1 1 0'; //not last but not among the leading players: yellow
			else
				rgb = '1 0 0'; //last: red
			pl = me;
		}

		if (pl == me)
		{
			if (i == first_pl)
				rgb = '0 1 0'; //first: green
			me_printed = true;
			drawfill(pos, eX * mySize.x + eY * fontsize.y, rgb, highlight_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		if (team_count)
			score_color = Team_ColorRGB(pl.team) * 0.8;
		s = textShortenToWidth(entcs_GetName(pl.sv_entnum), name_size, fontsize, stringwidth_colors);
		drawcolorcodedstring(pos + eX * (name_size - stringwidth(s, true, fontsize)), s, fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring(pos + eX * (name_size + spacing_size), ftos(pl.(scores(ps_primary))), fontsize, score_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += fontsize.y;
		++i;
	}
	while (i<entries && team_count && (tm = tm.sort_next) && (tm.team != NUM_SPECTATOR || (tm = tm.sort_next)));
}

void HUD_Score()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_score) return;
		if(MUTATOR_CALLHOOK(HUD_Score_show)) return;
	}

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

	float score, distribution = 0;
	string sign;
	vector distribution_color;
	entity tm, pl, me;

	me = playerslots[current_player];

	if((scores_flags(ps_primary) & SFL_TIME) && !teamplay) { // race/cts record display on HUD
		string timer, distrtimer;

		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;
		if(scores_flags(ps_primary) & SFL_ZERO_IS_WORST)
			if(pl.scores(ps_primary) == 0)
				pl = NULL;

		score = me.(scores(ps_primary));
		timer = TIME_ENCODED_TOSTRING(score, false);

		draw_beginBoldFont();
		if (pl && ((!(scores_flags(ps_primary) & SFL_ZERO_IS_WORST)) || score)) {
			// distribution display
			distribution = me.(scores(ps_primary)) - pl.(scores(ps_primary));

			distrtimer = ftos_decimals(fabs(distribution/(10 ** TIME_DECIMALS)), TIME_DECIMALS);

			if (distribution <= 0) {
				distribution_color = '0 1 0';
				sign = "-";
			}
			else {
				distribution_color = '1 0 0';
				sign = "+";
			}
			drawstring_aspect(pos + eX * 0.75 * mySize.x, strcat(sign, distrtimer), vec2(0.25 * mySize.x, (1/3) * mySize.y), distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		// race record display
		if (distribution <= 0)
			HUD_Panel_DrawHighlight(pos, vec2(0.75 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(pos, timer, vec2(0.75 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
	} else if (!teamplay) { // non-teamgames
		if ((spectatee_status == -1 && !autocvar__hud_configure) || autocvar_hud_panel_score_rankings)
		{
			HUD_Score_Rankings(pos, mySize, me);
			return;
		}
		// me vector := [team/connected frags id]
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;

		if(autocvar__hud_configure)
			distribution = 42;
		else if(pl)
			distribution = me.(scores(ps_primary)) - pl.(scores(ps_primary));
		else
			distribution = 0;

		score = me.(scores(ps_primary));
		if(autocvar__hud_configure)
			score = 123;

		if(distribution >= 5)
			distribution_color = eY;
		else if(distribution >= 0)
			distribution_color = '1 1 1';
		else if(distribution >= -5)
			distribution_color = '1 1 0';
		else
			distribution_color = eX;

		string distribution_str;
		distribution_str = ftos(distribution);
		draw_beginBoldFont();
		if (distribution >= 0)
		{
			if (distribution > 0)
				distribution_str = strcat("+", distribution_str);
			HUD_Panel_DrawHighlight(pos, eX * 0.75 * mySize.x + eY * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
		drawstring_aspect(pos, ftos(score), eX * 0.75 * mySize.x + eY * mySize.y, distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(pos + eX * 0.75 * mySize.x, distribution_str, vec2(0.25 * mySize.x, (1/3) * mySize.y), distribution_color, panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
	} else { // teamgames
		float row, column, rows = 0, columns = 0;
		vector offset = '0 0 0';
		vector score_pos, score_size; //for scores other than myteam
		if(autocvar_hud_panel_score_rankings)
		{
			HUD_Score_Rankings(pos, mySize, me);
			return;
		}
		if(spectatee_status == -1)
		{
			rows = HUD_GetRowCount(team_count, mySize, 3);
			columns = ceil(team_count/rows);
			score_size = vec2(mySize.x / columns, mySize.y / rows);

			float newSize;
			if(score_size.x/score_size.y > 3)
			{
				newSize = 3 * score_size.y;
				offset.x = score_size.x - newSize;
				pos.x += offset.x/2;
				score_size.x = newSize;
			}
			else
			{
				newSize = 1/3 * score_size.x;
				offset.y = score_size.y - newSize;
				pos.y += offset.y/2;
				score_size.y = newSize;
			}
		}
		else
			score_size = vec2(mySize.x / 4, mySize.y / 3);

		float max_fragcount;
		max_fragcount = -99;
		draw_beginBoldFont();
		row = column = 0;
		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == NUM_SPECTATOR)
				continue;
			if(!tm.team)
				continue;

			score = tm.(teamscores(ts_primary));
			if(autocvar__hud_configure)
				score = 123;

			if (score > max_fragcount)
				max_fragcount = score;

			if (spectatee_status == -1)
			{
				score_pos = pos + vec2(column * (score_size.x + offset.x), row * (score_size.y + offset.y));
				if (max_fragcount == score)
					HUD_Panel_DrawHighlight(score_pos, score_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(score_pos, ftos(score), score_size, Team_ColorRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
				++row;
				if(row >= rows)
				{
					row = 0;
					++column;
				}
			}
			else if(tm.team == myteam) {
				if (max_fragcount == score)
					HUD_Panel_DrawHighlight(pos, vec2(0.75 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(pos, ftos(score), vec2(0.75 * mySize.x, mySize.y), Team_ColorRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
			} else {
				if (max_fragcount == score)
					HUD_Panel_DrawHighlight(pos + vec2(0.75 * mySize.x, (1/3) * rows * mySize.y), score_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
				drawstring_aspect(pos + vec2(0.75 * mySize.x, (1/3) * rows * mySize.y), ftos(score), score_size, Team_ColorRGB(tm.team) * 0.8, panel_fg_alpha, DRAWFLAG_NORMAL);
				++rows;
			}
		}
		draw_endBoldFont();
	}
}
