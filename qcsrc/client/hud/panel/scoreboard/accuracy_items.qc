#include "accuracy_items.qh"

#include "scoreboard.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>
#include <client/hud/panel/weapons.qh>
#include <client/main.qh>
#include <common/items/inventory.qh>
#include <common/mutators/base.qh>
#include <common/weapons/_all.qh>

bool autocvar_hud_panel_scoreboard_accuracy = true;
float autocvar_hud_panel_scoreboard_accuracy_min_aspect = 1.15;
bool autocvar_hud_panel_scoreboard_accuracy_nocolors = false;
float autocvar_hud_panel_scoreboard_accuracy_showdelay = 2;
float autocvar_hud_panel_scoreboard_accuracy_showdelay_minpos = 0.75;

bool autocvar_hud_panel_scoreboard_itemstats = true;
float autocvar_hud_panel_scoreboard_itemstats_min_aspect = 1.25;
int autocvar_hud_panel_scoreboard_itemstats_filter = 1;
int autocvar_hud_panel_scoreboard_itemstats_filter_mask = 12;
float autocvar_hud_panel_scoreboard_itemstats_showdelay = 2.2; // slightly more delayed than accuracy
float autocvar_hud_panel_scoreboard_itemstats_showdelay_minpos = 0.75;


ACCUMULATE void Scoreboard_Draw_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_scoreboard_accuracy_min_aspect");
	HUD_Write_Cvar("hud_panel_scoreboard_accuracy_nocolors");
	HUD_Write_Cvar("hud_panel_scoreboard_itemstats_min_aspect");
}

bool is_item_filtered(entity it)
{
	if (!autocvar_hud_panel_scoreboard_itemstats_filter)
		return false;
	int mask = autocvar_hud_panel_scoreboard_itemstats_filter_mask;
	if (mask <= 0)
		return false;
	if (it.instanceOfArmor || it.instanceOfHealth)
	{
		switch (floor(mask) % 10) // health-armor mask
		{
			default: return false;
			case 4:  if (it == ITEM_HealthMega   || it == ITEM_ArmorMega)   return true; // else fallthrough
			case 3:  if (it == ITEM_HealthBig    || it == ITEM_ArmorBig)    return true; // else fallthrough
			case 2:  if (it == ITEM_HealthMedium || it == ITEM_ArmorMedium) return true; // else fallthrough
			case 1:  if (it == ITEM_HealthSmall  || it == ITEM_ArmorSmall)  return true; // else fallthrough
		}
	}
	if (it.instanceOfAmmo)
		return (floor(mask / 10) % 10) == 1; // ammo mask

	return false;
}

bool have_item_stats;
bool Scoreboard_ItemStats_WouldDraw(float ypos)
{
	if (MUTATOR_CALLHOOK(DrawScoreboardItemStats))
		return false;
	if (!autocvar_hud_panel_scoreboard_itemstats || !g_inventory || warmup_stage || ypos > 0.91 * vid_conheight)
		return false;

	if (time < scoreboard_time + autocvar_hud_panel_scoreboard_itemstats_showdelay
	&& ypos > autocvar_hud_panel_scoreboard_itemstats_showdelay_minpos * vid_conheight
	&& !intermission)
		return false;

	if (!have_item_stats)
	{
		int q;
		IL_EACH(default_order_items, !is_item_filtered(it),
		{
			q = g_inventory.inv_items[it.m_id];
			//q = 1; // debug: display all items
			if (q)
			{
				have_item_stats = true;
				break;
			}
		});
		if (!have_item_stats)
			return false;
	}

	return true;
}

bool have_weapon_stats;
bool Scoreboard_AccuracyStats_WouldDraw(float ypos)
{
	if (MUTATOR_CALLHOOK(DrawScoreboardAccuracy))
		return false;
	if (!autocvar_hud_panel_scoreboard_accuracy || warmup_stage || ypos > 0.91 * vid_conheight)
		return false;

	if (time < scoreboard_time + autocvar_hud_panel_scoreboard_accuracy_showdelay
	&& ypos > autocvar_hud_panel_scoreboard_accuracy_showdelay_minpos * vid_conheight
	&& !intermission)
		return false;

	if (!have_weapon_stats)
	{
		FOREACH(Weapons, it != WEP_Null,
		{
			if (weapon_accuracy[i - WEP_FIRST] >= 0)
			{
				have_weapon_stats = true;
				break;
			}
		});
		if (!have_weapon_stats)
			return false;
	}

	return true;
}

vector Scoreboard_ItemStats_Draw(vector pos, vector rgb, vector bg_size, int item_rows, int item_columns, float item_height, float item_height_just_item, bool merged)
{
	scoreboard_itemstats_fade_alpha = min(scoreboard_fade_alpha, scoreboard_itemstats_fade_alpha + frametime * 10);

	if (!autocvar_hud_panel_scoreboard_minimal) // don't draw label if minimal
	{
		drawstring(pos + eX * panel_bg_padding, _("Item stats"), hud_fontsize, '1 1 1', panel_fg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
		pos.y += 1.25 * hud_fontsize.y;
		if (panel.current_panel_bg != "0")
			pos.y += panel_bg_border;
	}

	panel_pos = pos;
	panel_size.y = item_height * item_rows;
	panel_size.y += panel_bg_padding * 2;

	if (!merged) // don't draw background, accuracy stats already did (and made it large enough)
	{
		float panel_bg_alpha_save = panel_bg_alpha;
		panel_bg_alpha *= scoreboard_itemstats_fade_alpha;
		HUD_Panel_DrawBg();
		panel_bg_alpha = panel_bg_alpha_save;
	}

	vector end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
	if (panel.current_panel_bg != "0") // add irrespective of `merged` - need to end a table regardless
		end_pos.y += panel_bg_border * 2;

	if (panel_bg_padding)
	{
		panel_pos  += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	float item_width = panel_size.x / item_columns;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, SCOREBOARD_BG_PATH, bg_size, panel_size, rgb, sbt_bg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);

	if (sbt_highlight)
	{
		int i;
		// column highlighting
		for (i = 0; i < item_columns; ++i)
			if (i % 2 == 0)
				drawfill(pos + eX * item_width * i, vec2(item_width, item_height * item_rows), '0 0 0', sbt_highlight_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
		// row highlighting
		for (i = 0; i < item_rows; ++i)
			drawfill(pos + eY * (item_height_just_item + item_height * i), vec2(panel_size.x, hud_fontsize.y), rgb, sbt_highlight_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
	}

	float padding, oldposx = pos.x;

	string s;
	int n, column = 0;
	IL_EACH(default_order_items, !is_item_filtered(it),
	{
		n = g_inventory.inv_items[it.m_id];
		//n = 1 + floor(i * 3 + 4.8) % 7; // debug: display a value for each item
		if (n <= 0)
			continue;
		drawpic_aspect_skin(pos, it.m_icon, vec2(item_width, item_height_just_item), '1 1 1', sbt_fg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);
		s = itos(n);
		padding = (item_width - stringwidth(s, false, hud_fontsize)) * 0.5;
		drawstring(pos + vec2(padding, item_height_just_item), s, hud_fontsize, '1 1 1', sbt_fg_alpha * scoreboard_itemstats_fade_alpha, DRAWFLAG_NORMAL);

		if (column == item_columns - 1)
		{
			pos.x = oldposx;
			pos.y += item_height;
			column = 0;
		}
		else
		{
			pos.x += item_width;
			++column;
		}
	});

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

float average_accuracy;
vector Scoreboard_AccuracyStats_Draw(vector pos, vector rgb, vector bg_size, WepSet all_weps, int wep_rows, int wep_columns, float wep_height, float wep_height_just_weapon, int item_rows, float item_height, bool merged)
{
	scoreboard_acc_fade_alpha = min(scoreboard_fade_alpha, scoreboard_acc_fade_alpha + frametime * 10);

	if (autocvar_hud_panel_scoreboard_minimal) // draw average accuracy % next to the table, code copied from team score code
	{
		draw_beginBoldFont();
		string str = sprintf(_("%.*f%%"), 0, average_accuracy); // reuse transifex string
		vector accuracy_fontsize = hud_fontsize * 1.15;
		vector str_pos = pos;
		if (autocvar_hud_panel_scoreboard_team_size_position != 1) // team size not on left
		{
			// team score on the left (default)
			str_pos.x -= 0.5 * hud_fontsize.x + stringwidth(str, false, accuracy_fontsize);
			if (panel.current_panel_bg != "0")
				str_pos.x -= panel_bg_border;
		}
		else
		{
			// team score on the right
			str_pos.x += 0.5 * hud_fontsize.x + panel_size.x;
			if (panel.current_panel_bg != "0")
				str_pos.x += panel_bg_border;
		}
		str_pos.y += panel_bg_border + panel_bg_padding + 0.5 * hud_fontsize.y;
		drawstring(str_pos, str, accuracy_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
	}
	else
	{
		drawstring(pos + eX * panel_bg_padding, sprintf(_("Accuracy stats (average %d%%)"), average_accuracy), hud_fontsize, '1 1 1', panel_fg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
		pos.y += 1.25 * hud_fontsize.y;
	}
	if (panel.current_panel_bg != "0")
		pos.y += panel_bg_border;

	panel_pos = pos;
	panel_size.y = wep_height * wep_rows + item_height * (merged ? item_rows : 0); // make it large enough to include ItemStats
	panel_size.y += panel_bg_padding * 2;

	{
		float panel_bg_alpha_save = panel_bg_alpha;
		panel_bg_alpha *= scoreboard_acc_fade_alpha;
		HUD_Panel_DrawBg();
		panel_bg_alpha = panel_bg_alpha_save;
	}

	vector end_pos;
	if (merged) // only add the height the weapons will take up
		end_pos = panel_pos + eY * (wep_height * wep_rows);
	else
	{
		end_pos = panel_pos + eY * (panel_size.y + 0.5 * hud_fontsize.y);
		if (panel.current_panel_bg != "0")
			end_pos.y += panel_bg_border * 2;
	}

	if (panel_bg_padding)
	{
		panel_pos  += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	pos = panel_pos;
	float wep_width = panel_size.x / wep_columns;

	if (sbt_bg_alpha)
		drawpic_tiled(pos, SCOREBOARD_BG_PATH, bg_size, panel_size, rgb, sbt_bg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);

	if (sbt_highlight)
	{
		int i;
		// column highlighting
		for (i = 0; i < wep_columns; ++i)
			if (i % 2 == 0)
				drawfill(pos + eX * wep_width * i, vec2(wep_width, wep_height * wep_rows), '0 0 0', sbt_highlight_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
		// row highlighting
		for (i = 0; i < wep_rows; ++i)
			drawfill(pos + eY * (wep_height_just_weapon + wep_height * i), vec2(panel_size.x, hud_fontsize.y), rgb, sbt_highlight_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
	}

	vector wep_rgb = '1 1 1';
	if (!autocvar_hud_panel_scoreboard_accuracy_nocolors)
		Accuracy_LoadColors();

	float wep_alpha, padding, oldposx = pos.x;

	string s;
	WepSet set;
	int acc, weps_with_stats = 0;
	int column = 0;
	average_accuracy = 0;
	FOREACH(Weapons, it != WEP_Null,
	{
		acc = weapon_accuracy[i - WEP_FIRST];
		set = it.m_wepset;
		if (acc < 0 && !(all_weps & set))
			continue;
		if (it.spawnflags & WEP_TYPE_OTHER)
			continue;

		wep_alpha = (acc >= 0)
			? sbt_fg_alpha
			: 0.2 * sbt_fg_alpha;

		// weapon icon
		drawpic_aspect_skin(pos, it.model2, vec2(wep_width, wep_height_just_weapon), '1 1 1', wep_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
		// the accuracy
		if (acc >= 0)
		{
			++weps_with_stats;
			average_accuracy += acc; // store sum of all accuracies in average_accuracy

			s = ftos_decimals_percentage(acc, 0);
			padding = (wep_width - stringwidth(s, false, hud_fontsize)) * 0.5;
			if (!autocvar_hud_panel_scoreboard_accuracy_nocolors)
				wep_rgb = Accuracy_GetColor(acc);

			drawstring(pos + vec2(padding, wep_height_just_weapon), s, hud_fontsize, wep_rgb, sbt_fg_alpha * scoreboard_acc_fade_alpha, DRAWFLAG_NORMAL);
		}

		if (column == wep_columns - 1)
		{
			pos.x = oldposx;
			pos.y += wep_height;
			column = 0;
		}
		else
		{
			pos.x += wep_width;
			++column;
		}
	});

	if (weps_with_stats)
		average_accuracy = floor((average_accuracy * 100 / weps_with_stats) + 0.5);

	panel_size.x += panel_bg_padding * 2; // restore initial width
	return end_pos;
}

vector Scoreboard_AccuracyAndItemStats_Draw(vector pos, vector rgb, vector bg_size)
{
	// pre-calculate number of weapons
	WepSet set, all_weps = WepSet_GetFromStat() | WepSet_GetFromStat_InMap();
	int disowned_cnt = 0;
	int wep_hidden = 0;
	int acc;
	FOREACH(Weapons, it != WEP_Null,
	{
		set = it.m_wepset;
		if (it.spawnflags & WEP_TYPE_OTHER)
		{
			++wep_hidden;
			continue;
		}
		acc = weapon_accuracy[i - WEP_FIRST];
		if (acc < 0 && !(all_weps & set))
		{
			if (it.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_MUTATORBLOCKED))
				++wep_hidden;
			else
				++disowned_cnt;
		}
	});
	int wep_cnt = (REGISTRY_COUNT(Weapons) - 1) - disowned_cnt - wep_hidden;

	// pre-calculate number of items
	disowned_cnt = 0;
	int uninteresting_cnt = 0;
	IL_EACH(default_order_items, true,
	{
		if (is_item_filtered(it))
			++uninteresting_cnt;
		else if (!g_inventory.inv_items[it.m_id]) // debug: display all items by changing this to `else if (true)`
			++disowned_cnt;
	});
	int items_cnt = REGISTRY_COUNT(Items) - disowned_cnt - uninteresting_cnt;

	// size pre-calculations
	float table_width = panel_size.x - panel_bg_padding * 2;

	float item_height_just_item = hud_fontsize.y * 2.3;
	float item_height = item_height_just_item + hud_fontsize.y;
	int item_columns = min(floor(table_width / (autocvar_hud_panel_scoreboard_itemstats_min_aspect * item_height)), items_cnt);
	int item_rows = item_columns ? ceil(items_cnt / item_columns) : 0;

	float wep_height_just_weapon = hud_fontsize.y * 2.3 / max(0.001, autocvar_hud_panel_weapons_aspect);
	float wep_height = wep_height_just_weapon + hud_fontsize.y;
	int wep_columns = min(floor(table_width / (autocvar_hud_panel_scoreboard_accuracy_min_aspect * wep_height)), wep_cnt);
	int wep_rows = wep_columns ? ceil(wep_cnt / wep_columns) : 0;


	float items_posy = pos.y;
	bool draw_accuracy = (Scoreboard_AccuracyStats_WouldDraw(pos.y) && wep_cnt > 0);
	if (draw_accuracy)
	{
		// Scoreboard_ItemStats_WouldDraw needs the y-pos as if Scoreboard_AccuracyStats_WouldDraw has already been called,
		// so we need to calculate it manually
		items_posy += wep_height * wep_rows;
		if (panel.current_panel_bg != "0")
			items_posy += panel_bg_border;
		if (!autocvar_hud_panel_scoreboard_minimal)
			items_posy += hud_fontsize.y * 1.75 + (panel_bg_padding + panel_bg_border) * 2;
	}
	bool draw_items = (Scoreboard_ItemStats_WouldDraw(items_posy) && items_cnt > 0);
	bool merged = (autocvar_hud_panel_scoreboard_minimal && draw_accuracy && draw_items);
	// can only merge if both are drawn, hence all this pre-calculation is necessary (determining which will draw)

	if (draw_accuracy)
		pos = Scoreboard_AccuracyStats_Draw(pos, rgb, bg_size, all_weps, wep_rows, wep_columns, wep_height, wep_height_just_weapon, item_rows, item_height, merged);
	if (draw_items)
		pos = Scoreboard_ItemStats_Draw(pos, rgb, bg_size, item_rows, item_columns, item_height, item_height_just_item, merged);
	return pos;
}
