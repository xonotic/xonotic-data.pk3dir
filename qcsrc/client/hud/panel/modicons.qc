#include "modicons.qh"

#include <client/miscfunctions.qh>
#include <client/autocvars.qh>
#include <common/mapinfo.qh>
#include <common/ent_cs.qh>
#include <common/scores.qh>
#include <common/gamemodes/_mod.qh>

// Mod icons (#10)

void DrawCAItem(vector myPos, vector mySize, float aspect_ratio, int layout, int i)
{
	TC(int, layout); TC(int, i);
	int stat = -1;
	string pic = "";
	vector color = '0 0 0';
	switch(i)
	{
		case 0: stat = STAT(REDALIVE); pic = "player_red"; color = '1 0 0'; break;
		case 1: stat = STAT(BLUEALIVE); pic = "player_blue"; color = '0 0 1'; break;
		case 2: stat = STAT(YELLOWALIVE); pic = "player_yellow"; color = '1 1 0'; break;
		default:
		case 3: stat = STAT(PINKALIVE); pic = "player_pink"; color = '1 0 1'; break;
	}

	if(mySize.x/mySize.y > aspect_ratio)
	{
		i = aspect_ratio * mySize.y;
		myPos.x = myPos.x + (mySize.x - i) / 2;
		mySize.x = i;
	}
	else
	{
		i = 1/aspect_ratio * mySize.x;
		myPos.y = myPos.y + (mySize.y - i) / 2;
		mySize.y = i;
	}

	if(layout)
	{
		drawpic_aspect_skin(myPos, pic, vec2(0.5 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(myPos + eX * 0.5 * mySize.x, ftos(stat), vec2(0.5 * mySize.x, mySize.y), color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else
		drawstring_aspect(myPos, ftos(stat), mySize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Clan Arena and Freeze Tag HUD modicons
void HUD_Mod_CA(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	int layout;
	if(ISGAMETYPE(CA))
		layout = autocvar_hud_panel_modicons_ca_layout;
	else //if(ISGAMETYPE(FREEZETAG))
		layout = autocvar_hud_panel_modicons_freezetag_layout;
	int rows, columns;
	float aspect_ratio;
	aspect_ratio = (layout) ? 2 : 1;
	rows = HUD_GetRowCount(team_count, mySize, aspect_ratio);
	columns = ceil(team_count/rows);

	int i;
	float row = 0, column = 0;
	vector pos = '0 0 0', itemSize;
	itemSize = vec2(mySize.x / columns, mySize.y / rows);
	for(i=0; i<team_count; ++i)
	{
		pos.x = myPos.x + column * itemSize.x;
		pos.y = myPos.y + row * itemSize.y;

		DrawCAItem(pos, itemSize, aspect_ratio, layout, i);

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}
}

// Race/CTS HUD mod icons
float crecordtime_prev; // last remembered crecordtime
float crecordtime_change_time; // time when crecordtime last changed
float srecordtime_prev; // last remembered srecordtime
float srecordtime_change_time; // time when srecordtime last changed

float race_status_time;
int race_status_prev;
string race_status_name_prev;

// Check if the given name already exist in race rankings? In that case, where? (otherwise return 0)
int race_CheckName(string net_name)
{
	int rank = 0;
	string zoned_name = strzone(strdecolorize(entcs_GetName(player_localnum)));
	for (int i = RANKINGS_CNT - 1; i >= 0; --i)
		if (strdecolorize(grecordholder[i]) == zoned_name)
		{
			rank = i + 1;
			break;
		}
	strfree(zoned_name);
	return rank;
}

void race_showTime(string text, vector pos, vector timeText_ofs, float theTime, vector textSize, float f)
{
	drawstring_aspect(pos, text, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(pos + timeText_ofs, TIME_ENCODED_TOSTRING(theTime), textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (f < 1) {
		drawstring_aspect_expanding(pos, text, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
		drawstring_aspect_expanding(pos + timeText_ofs, TIME_ENCODED_TOSTRING(theTime), textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}
}

void HUD_Mod_Race(vector pos, vector mySize)
{
	entity me = playerslots[player_localnum];
	float score = me.(scores(ps_primary));

	if(!(scores_flags(ps_primary) & SFL_TIME) || teamplay) // race/cts record display on HUD
	{
		mod_active = 0; // hide it in this case!
		return; // no records in the actual race
	}

	mod_active = 1;

	// clientside personal record
	string rr;
	if(ISGAMETYPE(CTS))
		rr = CTS_RECORD;
	else
		rr = RACE_RECORD;
	float t = stof(db_get(ClientProgsDB, strcat(shortmapname, rr, "time")));

	if(score && (score < t || !t)) {
		db_put(ClientProgsDB, strcat(shortmapname, rr, "time"), ftos(score));
		if(autocvar_cl_autodemo_delete_keeprecords)
		{
			float f = autocvar_cl_autodemo_delete;
			f &= ~1;
			cvar_set("cl_autodemo_delete", ftos(f)); // don't delete demo with new record!
		}
	}

	if(t != crecordtime_prev) {
		crecordtime_prev = t;
		crecordtime_change_time = time;
	}

	vector textPos, medalPos;
	float squareSize;
	if(mySize.x > mySize.y) {
		// text on left side
		squareSize = min(mySize.y, mySize.x/2);
		vector ofs = vec2(0.5 * max(0, mySize.x/2 - squareSize), 0.5 * (mySize.y - squareSize));
		textPos = pos + ofs;
		ofs.x += 0.5 * mySize.x;
		medalPos = pos + ofs;
	} else {
		// text on top
		squareSize = min(mySize.x, mySize.y/2);
		vector ofs = vec2(0.5 * (mySize.x - squareSize), 0.5 * max(0, mySize.y/2 - squareSize));
		textPos = pos + ofs;
		ofs.y += 0.5 * mySize.y;
		medalPos = pos + ofs;
	}
	vector textSize = vec2(squareSize, 0.25 * squareSize);

	race_showTime(_("Personal best"), textPos, eY * 0.25 * squareSize, t, textSize, time - crecordtime_change_time);

	// server record
	t = race_server_record;
	if(t != srecordtime_prev) {
		srecordtime_prev = t;
		srecordtime_change_time = time;
	}

	textPos += eY * 0.5 * squareSize;
	race_showTime(_("Server best"), textPos, eY * 0.25 * squareSize, t, textSize, time - srecordtime_change_time);

	if (race_status != race_status_prev || race_status_name != race_status_name_prev) {
		race_status_time = time + 5;
		race_status_prev = race_status;
		strcpy(race_status_name_prev, race_status_name);
	}

	// race "awards"
	float a = bound(0, race_status_time - time, 1);
	string s = textShortenToWidth(ColorTranslateRGB(race_status_name), squareSize, '1 1 0' * 0.1 * squareSize, stringwidth_colors);

	float rank = 0;
	if(race_status > 0)
		rank = race_CheckName(race_status_name);
	string rankname = count_ordinal(rank);
	vector namepos = medalPos + '0 0.8 0' * squareSize;
	vector rankpos = medalPos + '0 0.15 0' * squareSize;

	if(race_status == 0)
		drawpic_aspect_skin(medalPos, "race_newfail", '1 1 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	else if(race_status == 1) {
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newtime", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	} else if(race_status == 2) {
		if(strdecolorize(race_status_name) == strdecolorize(entcs_GetName(player_localnum)) || !race_myrank || race_myrank < rank)
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankgreen", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		else
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankyellow", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	} else if(race_status == 3) {
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrecordserver", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namepos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankpos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}

	if (race_status_time - time <= 0) {
		race_status_prev = -1;
		race_status = -1;
		strfree(race_status_name);
		strfree(race_status_name_prev);
	}
}

void HUD_ModIcons_SetFunc()
{
	HUD_ModIcons_GameType = gametype.m_modicons;
}

float mod_alpha;

void HUD_ModIcons()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_modicons) return;
		if(!HUD_ModIcons_GameType) return;
	}

	if(mod_active || autocvar__hud_configure)
		mod_alpha = min(mod_alpha + frametime * 2, 1);
	else
		mod_alpha = max(mod_alpha - frametime * 2, 0);

	//if(mod_alpha <= 0)
	//	return;
	panel_fade_alpha *= mod_alpha;
	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	if (autocvar_hud_panel_modicons_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();

	HUD_Panel_DrawBg();

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	if(autocvar__hud_configure)
		HUD_Mod_CTF(panel_pos, panel_size);
	else
		HUD_ModIcons_GameType(panel_pos, panel_size);

	draw_endBoldFont();
}
