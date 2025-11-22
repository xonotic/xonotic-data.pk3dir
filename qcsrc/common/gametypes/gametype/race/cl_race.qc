#include "cl_race.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

// Race/CTS HUD mod icons
float crecordtime_prev; ///< Last remembered crecordtime
float crecordtime_change_time; ///< Time when crecordtime last changed
float srecordtime_prev; ///< Last remembered srecordtime
float srecordtime_change_time; ///< Time when srecordtime last changed

float race_status_time;
int race_status_prev;
string race_status_name_prev;

// Check if the given name already exists in race rankings?
// In that case, where? (otherwise return 0)
int race_CheckName(string net_name)
{
	int rank = 0;
	string zoned_name = strzone(strdecolorize(net_name));
	for (int i = RANKINGS_CNT; i > 0; --i)
		if (strdecolorize(grecordholder[i - 1]) == zoned_name)
		{
			rank = i;
			break;
		}
	strfree(zoned_name);
	return rank;
}

void race_DrawTime(vector pos, vector timePos, vector textSize, string text, string timeText, float expand_f)
{
	drawstring_aspect(pos, text, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(timePos, timeText, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (expand_f < 1)
		drawstring_aspect_expanding(timePos, timeText, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, expand_f);
}

void race_UpdateDB(string rr, float new_score, float old_score)
{
	// TODO: relocate this out of HUD code
	db_put(ClientProgsDB, strcat(mi_shortname, rr, "time"), ftos(new_score));
	if (autocvar_cl_autodemo_delete_keeprecords)
	{
		int i = autocvar_cl_autodemo_delete;
		i &= ~1;
		cvar_set("cl_autodemo_delete", itos(i)); // don't delete demo with new record!
	}
	localcmd("\ncl_hook_race_pb \"",
		TIME_ENCODED_TOSTRING(new_score, false), "\" \"",
		TIME_ENCODED_TOSTRING(old_score, false), "\" \"",
		(old_score ? TIME_ENCODED_TOSTRING(old_score - new_score, false) : "0"), "\" \"",
		sprintf("%d", race_myrank), "\"\n");
}

// Also used in CTS
void HUD_Mod_Race(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	if (!(scores_flags(ps_primary) & SFL_TIME) || teamplay) // Race/CTS record display on HUD
	{
		mod_active = false; // hide it in this case!
		return; // no records in the actual race
	}
	else
		mod_active = true;

	float score = playerslots[player_localnum].(scores(ps_primary));

	// Calculate sizes
	vector text1Pos, text2Pos, textSize, medalPos;
	float squareSize; // maximum sized square tiled 2 or 3 times in the format
	float nameWidth; // width the name can be drawn in, can be wider than squareSize
	bool all_3;
	if (mySize.x / mySize.y >= 5) // horizontal with all 3 shown, fit into 5:1 (40%, 20%, 40%)
	{
		all_3 = true;
		squareSize = mySize.y;
		nameWidth = 0.2 * mySize.x;
		textSize.x = 0.4 * 0.9 * mySize.x; // text is 40% of width, 5%*40% padding on both sides

		text1Pos = myPos;
		medalPos = text1Pos;
		medalPos.x += 0.4 * mySize.x;
		text2Pos = medalPos;
		text2Pos.x += 0.2 * mySize.x;

		text1Pos.x += 0.4 * 0.05 * mySize.x;
		text2Pos.x += 0.4 * 0.05 * mySize.x;
		medalPos.x += 0.5 * (mySize.x * 0.2 - squareSize);
	}
	else if (mySize.x / mySize.y >= 1) // horizontal, fit into 2:1
	{
		all_3 = false;
		squareSize = min(mySize.y, mySize.x * 0.5);
		nameWidth = 0.5 * mySize.x;
		textSize.x = 0.5 * 0.9 * mySize.x; // 50% of width, 5%*50% padding on both sides

		text1Pos = myPos;
		text1Pos.y += 0.5 * (mySize.y - squareSize);
		text2Pos = text1Pos;
		text2Pos.x += 0.5 * mySize.x;
		medalPos = text2Pos;

		text1Pos.x += 0.5 * 0.05 * mySize.x;
		text2Pos.x += 0.5 * 0.05 * mySize.x;
		medalPos.x += 0.5 * max(0, mySize.x * 0.5 - squareSize);
	}
	else if (mySize.y / mySize.x >= 3) // vertical with all 3 shown, fit into 3:1
	{
		all_3 = true;
		squareSize = mySize.x;
		nameWidth = mySize.x;
		textSize.x = squareSize;

		text1Pos = myPos;
		text1Pos.y += 0.5 * (mySize.y * 1/3 - squareSize);
		medalPos = text1Pos;
		medalPos.y += 1/3 * mySize.y;
		text2Pos = medalPos;
		text2Pos.y += 1/3 * mySize.y;
	}
	else // vertical, fit into 2:1
	{
		all_3 = false;
		squareSize = min(mySize.x, mySize.y * 0.5);
		nameWidth = mySize.x;
		textSize.x = squareSize;

		text1Pos = myPos;
		text1Pos.x += 0.5 * (mySize.x - squareSize);
		text1Pos.y += 0.5 * max(0, mySize.y * 0.5 - squareSize);
		text2Pos = text1Pos;
		text2Pos.y += 0.5 * mySize.y;
		medalPos = text2Pos;
	}
	vector timeText_ofs = eY * 0.5 * squareSize;
	textSize.y = 0.5 * squareSize;
	textSize.z = 0;

	// Clientside personal record
	string rr = (ISGAMETYPE(CTS)) ? CTS_RECORD : RACE_RECORD;
	float t = stof(db_get(ClientProgsDB, strcat(mi_shortname, rr, "time")));

	if (score && (score < t || !t) && !isdemo())
		race_UpdateDB(rr, score, t);

	if (t != crecordtime_prev)
	{
		crecordtime_prev = t;
		crecordtime_change_time = time;
	}

	race_DrawTime(text1Pos, text1Pos + timeText_ofs, textSize, _("Personal best"), TIME_ENCODED_TOSTRING(t, false), time - crecordtime_change_time);

	// Server record
	t = race_server_record;
	if (t != srecordtime_prev)
	{
		srecordtime_prev = t;
		srecordtime_change_time = time;
	}

	if (race_status != race_status_prev || race_status_name != race_status_name_prev)
	{
		race_status_time = time + 5;
		race_status_prev = race_status;
		strcpy(race_status_name_prev, race_status_name);
	}

	if (all_3 || race_status < 0)
		race_DrawTime(text2Pos, text2Pos + timeText_ofs, textSize, _("Server best"), TIME_ENCODED_TOSTRING(t, false), time - srecordtime_change_time);

	// Race awards
	float a = bound(0, race_status_time - time, 1);
	float rank = (race_status > 0)
		? race_CheckName(race_status_name)
		: 0;

	string pic;
	switch (race_status)
	{
		case 3:
			pic = "race_newrecordserver";
			break;
		case 2:
			pic = (strdecolorize(race_status_name) == strdecolorize(entcs_GetName(player_localnum)) || !race_myrank || race_myrank < rank)
				? "race_newrankgreen"
				: "race_newrankyellow";
			break;
		case 1:
			pic = "race_newtime";
			break;
		case 0: // handle this differently, since rank & name aren't needed
			drawpic_aspect_skin(medalPos, "race_newfail", '1 1 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
			// fallthrough
		default:
			pic = string_null;
			break;
	}

	if (pic)
	{
		vector medalSize = vec3(squareSize * 0.8, squareSize * 0.8, 0);
		medalPos.x += (squareSize - medalSize.x) * 0.5;
		drawpic_aspect_skin(medalPos, pic, medalSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);

		vector rankSize = vec3(squareSize, squareSize * 0.2, 0);
		vector rankPos = medalPos;
		drawstring_aspect(rankPos, count_ordinal(rank), rankSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);

		vector nameSize = vec3(nameWidth, squareSize * 0.2, 0); // use the full nameWidth, so long names are less likely to draw small
		vector namePos = medalPos;
		namePos.y += squareSize - nameSize.y;
		namePos.x -= (nameWidth - squareSize) * 0.5;
		string s = textShortenToWidth(ColorTranslateRGB(race_status_name), squareSize, '1 1 0' * 0.1 * squareSize, stringwidth_colors);
		drawcolorcodedstring_aspect(namePos, s, nameSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}

	if (time >= race_status_time)
	{
		race_status_prev = -1;
		race_status = -1;
		strfree(race_status_name);
		strfree(race_status_name_prev);
	}
}

REGISTER_MUTATOR(cl_race, true);

MUTATOR_HOOKFUNCTION(cl_race, HUD_Physics_showoptional)
{
	return ISGAMETYPE(RACE); // show the optional physics panel
}

MUTATOR_HOOKFUNCTION(cl_race, HUD_StrafeHUD_showoptional)
{
	return ISGAMETYPE(RACE); // show the optional strafehud
}

MUTATOR_HOOKFUNCTION(cl_race, HUD_Score_show)
{
	return spectatee_status == -1 && ISGAMETYPE(RACE); // hide the score panel while observing
}

MUTATOR_HOOKFUNCTION(cl_race, DrawScoreboardItemStats)
{
	return ISGAMETYPE(RACE); // hide the item stats panel
}

MUTATOR_HOOKFUNCTION(cl_race, ShowRankings)
{
	if (ISGAMETYPE(RACE))
	{
		M_ARGV(1, string) = _("Rankings");
		return true;
	}
}

MUTATOR_HOOKFUNCTION(cl_race, DrawScoreboardAccuracy)
{
	return ISGAMETYPE(RACE); // accuracy is not a factor in this gametype
}

MUTATOR_HOOKFUNCTION(cl_race, ShowRaceTimer)
{
	return ISGAMETYPE(RACE); // show the race timer panel
}

MUTATOR_HOOKFUNCTION(cl_race, TeamRadar_Draw)
{
	return ISGAMETYPE(RACE); // show all competitors in a race
}
