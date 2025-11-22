#include "cl_race.qh"

#include <client/draw.qh>
#include <common/mutators/base.qh>

// Race/CTS HUD mod icons
float crecordtime_prev; // last remembered crecordtime
float crecordtime_change_time; // time when crecordtime last changed
float srecordtime_prev; // last remembered srecordtime
float srecordtime_change_time; // time when srecordtime last changed

float race_status_time;
int race_status_prev;
string race_status_name_prev;

// Check if the given name already exists in race rankings?
// In that case, where? (otherwise return 0)
int race_CheckName(string net_name)
{
	int rank = 0;
	string zoned_name = strzone(strdecolorize(net_name));
	for (int i = RANKINGS_CNT - 1; i >= 0; --i)
		if (strdecolorize(grecordholder[i]) == zoned_name)
		{
			rank = i + 1;
			break;
		}
	strfree(zoned_name);
	return rank;
}

void race_showTime(string text, vector pos, vector timeText_ofs, float theTime, vector textSize, float expand_f)
{
	drawstring_aspect(pos, text, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(pos + timeText_ofs, TIME_ENCODED_TOSTRING(theTime, false), textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (expand_f < 1)
	{
		drawstring_aspect_expanding(pos, text, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, expand_f);
		drawstring_aspect_expanding(pos + timeText_ofs, TIME_ENCODED_TOSTRING(theTime, false), textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, expand_f);
	}
}

void HUD_Mod_Race(vector myPos, vector mySize)
{
	if (!(scores_flags(ps_primary) & SFL_TIME) || teamplay) // Race/CTS record display on HUD
	{
		mod_active = 0; // hide it in this case!
		return; // no records in the actual race
	}

	mod_active = 1;

	entity me = playerslots[player_localnum];
	float score = me.(scores(ps_primary));

	// clientside personal record
	string rr = (ISGAMETYPE(CTS)) ? CTS_RECORD : RACE_RECORD;
	float t = stof(db_get(ClientProgsDB, strcat(mi_shortname, rr, "time")));

	if (score && (score < t || !t) && !isdemo())
	{
		db_put(ClientProgsDB, strcat(mi_shortname, rr, "time"), ftos(score));
		if (autocvar_cl_autodemo_delete_keeprecords)
		{
			float f = autocvar_cl_autodemo_delete;
			f &= ~1;
			cvar_set("cl_autodemo_delete", ftos(f)); // don't delete demo with new record!
		}
		localcmd("\ncl_hook_race_pb \"",
			TIME_ENCODED_TOSTRING(score, false), "\" \"",
			TIME_ENCODED_TOSTRING(t, false), "\" \"",
			(t ? TIME_ENCODED_TOSTRING(t - score, false) : "0"), "\" \"",
			sprintf("%d", race_myrank), "\"\n");
	}

	if (t != crecordtime_prev)
	{
		crecordtime_prev = t;
		crecordtime_change_time = time;
	}

	vector text1Pos, text2Pos, textSize, ofs;
	float squareSize;
	bool all_3;
	if (mySize.x / mySize.y >= 5) // horizontal with all 3 shown, fit into 5:1 (2,2,1)
	{
		all_3 = true;
		squareSize = mySize.y;
		ofs = vec2(0.5 * (mySize.x * 0.2 - squareSize), 0);
		text1Pos = myPos + eX * 0.4 * 0.05 * mySize.x;
		text2Pos = text1Pos + eX * 0.4 * mySize.x;
		textSize.x = 0.4 * 0.9 * mySize.x;
		ofs.x += 0.8 * mySize.x;
	}
	else if (mySize.x / mySize.y >= 1) // horizontal, fit into 2:1
	{
		all_3 = false;
		squareSize = min(mySize.y, mySize.x * 0.5);
		ofs = vec2(0.5 * max(0, mySize.x * 0.5 - squareSize), 0.5 * (mySize.y - squareSize));
		text1Pos = myPos + eX * 0.5 * 0.05 * mySize.x + eY * ofs.y;
		text2Pos = text1Pos + eX * 0.5 * mySize.x;
		textSize.x = 0.5 * 0.9 * mySize.x;
		ofs.x += 0.5 * mySize.x;
	}
	else if (mySize.y / mySize.x >= 3) // vertical with all 3 shown, fit into 3:1
	{
		all_3 = true;
		squareSize = mySize.x;
		ofs = vec2(0, 0.5 * mySize.y * 1/3 - squareSize);
		text1Pos = myPos;
		text2Pos = text1Pos + eY * 1/3 * mySize.y;
		textSize.x = squareSize;
		ofs.y += 2/3 * mySize.y;
	}
	else // vertical, fit into 2:1
	{
		all_3 = false;
		squareSize = min(mySize.x, mySize.y * 0.5);
		ofs = vec2(0.5 * (mySize.x - squareSize), 0.5 * max(0, mySize.y * 0.5 - squareSize));
		text1Pos = myPos + eX * ofs.x;
		text2Pos = text1Pos + eY * 0.5 * mySize.y;
		textSize.x = squareSize;
		ofs.y += 0.5 * mySize.y;
	}
	vector timeText_ofs = eY * 0.5 * squareSize;
	textSize.y = 0.5 * squareSize;
	textSize.z = 0;
	vector medalPos = myPos + ofs;

	race_showTime(_("Personal best"), text1Pos, timeText_ofs, t, textSize, time - crecordtime_change_time);

	// server record
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
		race_showTime(_("Server best"), text2Pos, timeText_ofs, t, textSize, time - srecordtime_change_time);

	// race "awards"
	float a = bound(0, race_status_time - time, 1);
	string s = textShortenToWidth(ColorTranslateRGB(race_status_name), squareSize, '1 1 0' * 0.1 * squareSize, stringwidth_colors);

	float rank = (race_status > 0)
		? race_CheckName(race_status_name)
		: 0;
	string rankname = count_ordinal(rank);
	vector namePos = medalPos + '0 0.8 0'  * squareSize;
	vector rankPos = medalPos + '0 0.15 0' * squareSize;

	if (race_status == 0)
		drawpic_aspect_skin(medalPos, "race_newfail", '1 1 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	else if (race_status == 1)
	{
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newtime", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namePos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankPos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}
	else if (race_status == 2)
	{
		if (strdecolorize(race_status_name) == strdecolorize(entcs_GetName(player_localnum)) || !race_myrank || race_myrank < rank)
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankgreen",  '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		else
			drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrankyellow", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namePos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankPos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
	}
	else if(race_status == 3)
	{
		drawpic_aspect_skin(medalPos + '0.1 0 0' * squareSize, "race_newrecordserver", '1 1 0' * 0.8 * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawcolorcodedstring_aspect(namePos, s, '1 0.2 0' * squareSize, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		drawstring_aspect(rankPos, rankname, '1 0.15 0' * squareSize, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
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
	if(ISGAMETYPE(RACE))
	{
		M_ARGV(0, string) = _("Rankings");
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
