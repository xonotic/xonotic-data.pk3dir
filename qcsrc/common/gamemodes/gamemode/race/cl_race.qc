#include "cl_race.qh"

#include <client/draw.qh>
#include <common/mutators/base.qh>
#include <lib/json.qh>

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

void race_showTime(string text, vector pos, vector timeText_ofs, float theTime, vector textSize, float f)
{
	drawstring_aspect(pos, text, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(pos + timeText_ofs, TIME_ENCODED_TOSTRING(theTime, false), textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (f < 1) {
		drawstring_aspect_expanding(pos, text, textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
		drawstring_aspect_expanding(pos + timeText_ofs, TIME_ENCODED_TOSTRING(theTime, false), textSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}
}

void race_LoadPb()
{
		string json_times =  db_get(ClientProgsDB, strcat(mi_shortname, (ISGAMETYPE(CTS) ? CTS_RECORD : RACE_RECORD), "cptimes"));
		string json_speeds = db_get(ClientProgsDB, strcat(mi_shortname, (ISGAMETYPE(CTS) ? CTS_RECORD : RACE_RECORD), "cpspeeds"));

		int buf = json_parse(json_times, _json_parse_object);
		if(buf == -1)
		{
			// FIXME: log error parsing if != ""
			return;
		}
		for (int cp = 0; cp <= 255; cp++)
			race_checkpoint_pb_times[cp] = stof(json_get(buf, sprintf("cptimes.%d", cp)));

		buf = json_parse(json_speeds, _json_parse_object);
		if(buf == -1)
		{
			// FIXME: log error parsing if != ""
			return;
		}
		for (int cp = 0; cp <= 255; cp++)
			race_checkpoint_pb_speeds[cp] = stof(json_get(buf, sprintf("cpspeeds.%d", cp)));
}

void race_SavePb(float pbtime)
{

		string json_times = "{ \"cptimes\": {";
		string json_speeds = "{ \"cpspeeds\": {";
		string comma_times = "";
		string comma_speeds = "";

		for(int cp = 0; cp <= 255; cp++)
		{
			race_checkpoint_pb_speeds[cp] = race_checkpoint_current_speeds[cp];
			race_checkpoint_pb_times[cp] = race_checkpoint_current_times[cp];
		}
		for(int cp = 0; cp <= 255; cp++)
		{
			if(race_checkpoint_pb_times[cp])
			{
				json_times = strcat(json_times, sprintf("%s\"%d\": %d", comma_times, cp, race_checkpoint_pb_times[cp]));
				comma_times = ",";
			}
			if(race_checkpoint_pb_speeds[cp])
			{
				json_speeds = strcat(json_speeds, sprintf("%s\"%d\": %d", comma_speeds, cp, race_checkpoint_pb_speeds[cp]));
				comma_speeds = ",";
			}
			if(race_checkpoint_pb_times[cp] == pbtime) // finish cp, we can leave
				break;
		}
		json_times = strcat(json_times, "} }");
		json_speeds = strcat(json_speeds, "} }");

		db_put(ClientProgsDB, strcat(mi_shortname, (ISGAMETYPE(CTS) ? CTS_RECORD : RACE_RECORD), "time"), ftos(pbtime));
		db_put(ClientProgsDB, strcat(mi_shortname, (ISGAMETYPE(CTS) ? CTS_RECORD : RACE_RECORD), "cptimes"), json_times);
		db_put(ClientProgsDB, strcat(mi_shortname, (ISGAMETYPE(CTS) ? CTS_RECORD : RACE_RECORD), "cpspeeds"), json_speeds);
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
	float t = stof(db_get(ClientProgsDB, strcat(mi_shortname, (ISGAMETYPE(CTS) ? CTS_RECORD : RACE_RECORD), "time")));
	static bool pbloaded = false;

	if(!pbloaded)
	{
		race_LoadPb();
		pbloaded = true; // loaded or not we tried once
	}

	if(score && (score < t || !t) && !isdemo()) {
		race_SavePb(score);
		if(autocvar_cl_autodemo_delete_keeprecords)
		{
			float f = autocvar_cl_autodemo_delete;
			f &= ~1;
			cvar_set("cl_autodemo_delete", ftos(f)); // don't delete demo with new record!
		}
		localcmd("\ncl_hook_race_pb \"",
			TIME_ENCODED_TOSTRING(score, false), "\" \"",
			TIME_ENCODED_TOSTRING(t, false), "\" \"",
			(t ?  TIME_ENCODED_TOSTRING(t-score, false) : "0"), "\" \"",
			sprintf("%d", race_myrank), "\"\n");
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
	return ISGAMETYPE(RACE); // accuracy is not a factor in this gamemode
}

MUTATOR_HOOKFUNCTION(cl_race, ShowRaceTimer)
{
	return ISGAMETYPE(RACE); // show the race timer panel
}

MUTATOR_HOOKFUNCTION(cl_race, TeamRadar_Draw)
{
	return ISGAMETYPE(RACE); // show all competitors in a race
}
