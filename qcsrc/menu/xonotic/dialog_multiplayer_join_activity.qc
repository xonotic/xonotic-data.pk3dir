#include "dialog_multiplayer_join_activity.qh"

#include <lib/urllib.qh>
#include "textbox.qh"
#include "textlabel.qh"

int heatmap_games_per_hour[24 * 7];
int heatmap_max_games;
int heatmap_max_games_hour;


// TRANSLATORS: %EEEE: Weekday name, %h: hour in a 12 hour clock, %a: AM or PM.
// "%H" (hour in a 24 hour clock system using 0-23), "%HH" (zero-padded version of "%H"), "%K" (12 hour cycle using 0 through 11), "%k" (24 hour cycle using 1 through 24), "%b" (am, noon, pm, or midnight) are supported too.
// "%a" and "%b" require "%h" or "%K".
/* xgettext:no-c-format */
#define DAY_HOUR_FORMAT _("DATE^%EEEE at %h %a")

#define LIST_OF_HOUR_FORMATS(h) \
	X("%h", ((h) % 12 ? itos((h) % 12) : "12")) \
	X("%K", itos((h) % 12)) \
	X("%HH", sprintf("%02d", (h) % 24)) \
	X("%kk", sprintf("%02d", ((h) % 24) + 1)) \
	X("%H", itos((h) % 24)) \
	X("%k", itos(((h) % 24) + 1)) \
	/**/

/// Returns translatable time format including the weekday name and hour
string ActivityHeatmap_createDayHourTime(int hour)
{
	string day, hourtime = CTX(DAY_HOUR_FORMAT);

	switch (floor(hour / 24.0))
	{
		// In some languages, day names in a format are different to day names when standalone
		case 0:  day = CTX(_("DATE_FORMAT^Monday"));     break;
		case 1:  day = CTX(_("DATE_FORMAT^Tuesday"));    break;
		case 2:  day = CTX(_("DATE_FORMAT^Wednesday"));  break;
		case 3:  day = CTX(_("DATE_FORMAT^Thursday"));   break;
		case 4:  day = CTX(_("DATE_FORMAT^Friday"));     break;
		case 5:  day = CTX(_("DATE_FORMAT^Saturday"));   break;
		case 6:  day = CTX(_("DATE_FORMAT^Sunday"));     break;
		default: return itos(hour); // failed, why?
	}
	hourtime = strreplace("%EEEE", day, hourtime); // not much point in supporting %E

	if (strstrofs(hourtime, "%h", 0) >= 0
	||  strstrofs(hourtime, "%K", 0) >= 0) // %a, %b, and %B require %h or %K (12 hour time)
	{
		hourtime = strreplace("%a", (hour % 24 < 12 ? CTX(_("TIME^AM")) : CTX(_("TIME^PM"))), hourtime);
		hourtime = strreplace("%b", (hour % 24 == 0 ? _("midnight") : hour % 24 == 12 ? _("noon") : hour % 24 < 12 ? CTX(_("TIME^am")) : CTX(_("TIME^pm"))), hourtime);
	}

#define X(formatter, replacement) \
	hourtime = strreplace(formatter, replacement, hourtime);
	LIST_OF_HOUR_FORMATS(hour)
#undef X

	return hourtime;
}

/// Returns translatable hour, excluding the "AM" or whatnot
string ActivityHeatmap_createHourTime(int hour)
{
	string hourtime = CTX(DAY_HOUR_FORMAT);

#define X(formatter, replacement) \
	if (strstrofs(hourtime, formatter, 0) >= 0) \
		return replacement;
	LIST_OF_HOUR_FORMATS(hour)
#undef X

	return itos(hour);
}
#undef LIST_OF_HOUR_FORMATS

/// Returns translatable abbreviated standalone weekday name (eg. "Fri") from 0-6 (Mon-Sun)
string ActivityHeatmap_createDayTime(int weekday)
{
	string str;
	switch (weekday)
	{
		// In some languages, day names in a format are different to day names when standalone
		case 0:  str = CTX(_("DATE_STANDALONE^Mon"));  break;
		case 1:  str = CTX(_("DATE_STANDALONE^Tue"));  break;
		case 2:  str = CTX(_("DATE_STANDALONE^Wed"));  break;
		case 3:  str = CTX(_("DATE_STANDALONE^Thu"));  break;
		case 4:  str = CTX(_("DATE_STANDALONE^Fri"));  break;
		case 5:  str = CTX(_("DATE_STANDALONE^Sat"));  break;
		case 6:  str = CTX(_("DATE_STANDALONE^Sun"));  break;
		default: return itos(weekday); // failed, why?
	}
	// Only supporting %ccc (abbreviated standalone weekday name)
	return str;
}

void ActivityHeatmap_setMostPopularTime(entity me)
{
	if (heatmap_max_games <= 0)
		me.statsLabel.setText(me.statsLabel, _("This server hasn't seen any activity recently"));
	else
		me.statsLabel.setText(me.statsLabel, strzone(sprintf(_("The most popular time to play is %s: %s"),
			ActivityHeatmap_createDayHourTime(heatmap_max_games_hour),
			count_games(heatmap_max_games))));
}

int ActivityHeatmap_cellToHour(entity me, vector cell)
{
	if (cell.x < 0 || cell.x >= me.columns
	||  cell.y < 0 || cell.y >= me.rows)
		return -1;
	// Flip vertically to put Sunday at the top, Monday at the bottom, copying XonStat's layout
	return (me.rows - 1 - cell.y) * me.columns + cell.x;
}

void ActivityHeatmap_updateFocus(entity me)
{
	int hour = ActivityHeatmap_cellToHour(me, me.focusedCell);
	if (hour < 0)
		ActivityHeatmap_setMostPopularTime(me);
	else
		me.statsLabel.setText(me.statsLabel, strzone(sprintf(_("%s %s"),
			sprintf(_("%s:"), ActivityHeatmap_createDayHourTime(hour)),
			count_games(heatmap_games_per_hour[hour]))));
}

entity makeXonoticActivityHeatmap()
{
	entity me = NEW(XonoticActivityHeatmap);
	me.configureXonoticActivityHeatmap(me);
	return me;
}

void XonoticActivityHeatmap_configureXonoticActivityHeatmap(entity me)
{
	me.configureXonoticPicker(me);
	SUPER(XonoticActivityHeatmap).cellSelect(me, '-1 -1 0'); // start deselected
}

void XonoticActivityHeatmap_focusEnter(entity me)
{
	SUPER(XonoticActivityHeatmap).focusLeave(me);
	ActivityHeatmap_updateFocus(me);
}

void XonoticActivityHeatmap_focusLeave(entity me)
{
	SUPER(XonoticActivityHeatmap).focusLeave(me);
	ActivityHeatmap_setMostPopularTime(me);
}

float XonoticActivityHeatmap_mouseMove(entity me, vector coords)
{
	float ret = SUPER(XonoticActivityHeatmap).mouseMove(me, coords);
	ActivityHeatmap_updateFocus(me);
	return ret;
}

void XonoticActivityHeatmap_moveFocus(entity me, vector initialCell, vector step)
{
	int new_x = me.focusedCell.x + step.x; // make hour overflow change the day
	if (new_x >= me.columns || new_x < 0)
		step.y -= floor(new_x / me.columns);

	SUPER(XonoticActivityHeatmap).moveFocus(me, initialCell, step);
	ActivityHeatmap_updateFocus(me);
}

void XonoticActivityHeatmap_cellSelect(entity me, vector cell)
{
	// Don't select cells
}

bool XonoticActivityHeatmap_cellIsValid(entity me, vector cell)
{
	return ActivityHeatmap_cellToHour(me, cell) >= 0;
}

void XonoticActivityHeatmap_cellDraw(entity me, vector cell, vector cellPos)
{
	int hour = ActivityHeatmap_cellToHour(me, cell);
	if (heatmap_games_per_hour[hour])
	{
		vector size;
		size.x = 1 / me.columns;
		size.y = 1 / me.rows;
		size.z = 0;
		vector pos;
		pos.x = size.x * cell.x;
		pos.y = size.y * cell.y;
		pos.z = 0;
		// alpha**(2/3) slightly amplifies low values so hours with very low game counts aren't almost-fully-transparent
		draw_Fill(pos, size, SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED * (heatmap_games_per_hour[hour] / heatmap_max_games) ** (2/3));
	}
}

const float HEATMAP_CURRENT_WIDTH = 0.1;
void XonoticActivityHeatmap_draw(entity me)
{
	string local_time = strftime(true, "%w%H%M%S"); // k9er: DP doesn't implement %T
	int day = 6 - ((stoi(substring(local_time, 0, 1)) + 6) % 7);
	float hour = stoi(substring(local_time, 1, 2));
	hour += stoi(substring(local_time, 3, 2)) / 60.0;
	hour += stoi(substring(local_time, 5, 2)) / (60.0 * 60.0);

	// Draw a red bar to mark the current time
	vector size;
	size.x = HEATMAP_CURRENT_WIDTH / me.columns;
	size.y = 1 / me.rows;
	size.z = 0;
	vector pos;
	pos.x = (hour - HEATMAP_CURRENT_WIDTH * 0.5) / me.columns;
	pos.y = size.y * day;
	pos.z = 0;
	// Width is 10% of an hour, have split it if in the first 5% of hour 0 or last 5% of hour 23
	if (pos.x < 0)
	{
		float underflow = pos.x;
		pos.x = 0;
		size.x = (hour + HEATMAP_CURRENT_WIDTH * 0.5) / me.columns;
		draw_Fill(pos, size, SKINCOLOR_HEATMAP_CURRENT, SKINALPHA_HEATMAP_CURRENT);
		size.x = -underflow;
		pos.x = 1 + underflow;
		pos.y = size.y * ((day + 1) % 7); // prev day
	}
	else if (pos.x + size.x > 1)
	{
		float overflow = pos.x + size.x - 1;
		size.x = 1 - pos.x;
		draw_Fill(pos, size, SKINCOLOR_HEATMAP_CURRENT, SKINALPHA_HEATMAP_CURRENT);
		size.x = overflow;
		pos.x = 0;
		pos.y = size.y * ((day - 1 + 7) % 7); // next day
	}
	draw_Fill(pos, size, SKINCOLOR_HEATMAP_CURRENT, SKINALPHA_HEATMAP_CURRENT);

	SUPER(XonoticActivityHeatmap).draw(me);
}


void ActivityHeatmap_OnGet(entity fh, entity me, int status)
{
	switch (status)
	{
		case URL_READY_CANREAD:
		{
			int i;
			for (i = 0; i < 24 * 7; ++i)
				heatmap_games_per_hour[i] = 0;
			heatmap_max_games = 0;

			string temp = "";
			for (string s; (s = url_fgets(fh)); )
				temp = cons_mid(temp, "\n", s);
			url_fclose(fh);

			// k9er: DP doesn't implement %z properly so we have to figure out timezone by comparing to UTC
			// This doesn't account for timezones with partial-hour differences - not possible with what XonStat gives us
			string local_time = strftime(true,  "%w%H");
			string utc_time   = strftime(false, "%w%H");
			int local_hour = 24 * stoi(substring(local_time, 0, 1)) + stoi(substring(local_time, 1, 2));
			int utc_hour   = 24 * stoi(substring(utc_time,   0, 1)) + stoi(substring(utc_time,   1, 2));
			local_hour += 24 * 7 - utc_hour;

			int buf = json_parse(temp, _json_parse_array);
			EXPECT_NE(-1, buf);
			// Format: [[ day:1-7, hour:0-23, games:>0 ], ...]
			// Example: [[1,0,50],[7,23,57]]
			string prefix;
			int games, hour, inner_count, count = stoi(bufstr_get(buf, 0));
			for (i = 0; i < count; ++i)
			{
				prefix = itos(i);
				inner_count = stoi(json_get(buf, strcat(prefix, ".length")));
				if (inner_count != 3)
					continue;

				hour = 24 * (stoi(json_get(buf, strcat(prefix, ".0"))) - 1) + stoi(json_get(buf, strcat(prefix, ".1")));
				hour = (hour + local_hour) % (24 * 7);
				games = stoi(json_get(buf, strcat(prefix, ".2")));
				heatmap_games_per_hour[hour] = games;
				if (games > heatmap_max_games)
				{
					heatmap_max_games = games;
					heatmap_max_games_hour = hour;
				}
			}

			json_del(buf);
			ActivityHeatmap_setMostPopularTime(me.heatmap);
			break;
		}

		case URL_READY_ERROR:
		{
			for (int i = 0; i < 24 * 7; ++i)
				heatmap_games_per_hour[i] = 0;
			heatmap_max_games = 0;
			break;
		}

		case URL_READY_CLOSED:
		default:
			break;
	}
}


entity makeXonoticServerActivityTab()
{
	entity me = NEW(XonoticServerActivityTab);
	me.configureDialog(me);
	return me;
}

void XonoticServerActivityTab_loadFromURL(entity me, string downloadurl)
{
	url_single_fopen(downloadurl, FILE_READ, ActivityHeatmap_OnGet, me);
}

void XonoticServerActivityTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticTextLabel(0.5, ""));
			e.colorL = SKINCOLOR_SERVERINFO_NAME;
			e.allowCut = true;
			me.nameLabel = e;

	me.gotoRC(me, 2, 0.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, me.rows - 6, me.columns - 0.5, e = makeXonoticActivityHeatmap());
			me.heatmap = e;

	int i;
	// Add weekday names
	float height = (me.rows - 6) / me.heatmap.rows;
	me.gotoRC(me, 2, 0); me.setFirstColumn(me, 0);
	for (i = 0; i < me.heatmap.rows; ++i)
	{
		me.gotoRC(me, 2 + height * i, 0);
			me.TD(me, height, 0.5, e = makeXonoticTextLabel(1, strzone(ActivityHeatmap_createDayTime(me.heatmap.rows - 1 - i))));
				e.marginRight = 0.25;
	}
	// Add hour numbers
	float width = (me.columns - 0.5) / me.heatmap.columns;
	me.gotoRC(me, me.rows - 4, 0.5); me.setFirstColumn(me, me.currentColumn);
		for (i = 0; i < me.heatmap.columns; ++i)
			me.TD(me, 0.75, width, e = makeXonoticTextLabel(0.5, strzone(ActivityHeatmap_createHourTime(i))));
	// Add AM/PM
	string hourtime = CTX(DAY_HOUR_FORMAT);
	if (strstrofs(hourtime, "%h", 0) >= 0
	||  strstrofs(hourtime, "%K", 0) >= 0) // 12 hour time
	{
		bool lowercase = strstrofs(hourtime, "%b", 0) >= 0;
		me.gotoRC(me, me.rows - 3.25, 0.5);
			me.TD(me, 0.75, width, e = makeXonoticTextLabel(0.5, strzone(CTX(lowercase ? _("TIME^am") : _("TIME^AM")))));
			me.TDempty(me, width * 11);
			me.TD(me, 0.75, width, e = makeXonoticTextLabel(0.5, strzone(CTX(lowercase ? _("TIME^pm") : _("TIME^PM")))));
	}

	me.gotoRC(me, me.rows - 2, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, me.columns, e = makeXonoticTextLabel(0.5, ""));
			me.heatmap.statsLabel = e;
}

#undef DAY_HOUR_FORMAT
