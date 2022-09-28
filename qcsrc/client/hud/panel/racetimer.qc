#include "racetimer.qh"

#include <client/draw.qh>

// Race timer (#8)

void HUD_RaceTimer_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

// return the string of the onscreen race timer
string MakeRaceString(int cp, float mytime, float theirtime, float othertime, float lapdelta, string theirname)
{
	TC(int, cp);
	string cpname, lapstr = "", timestr = "", col = "^7", othercol = "^7", othertimestr = "";
	if(theirname == "" || !autocvar_cl_race_cptimes_showself)
		othertime = 0; // don't count personal time

	if(theirtime == 0) // goal hit
	{
		if(mytime > 0)
		{
			timestr = strcat("+", ftos_decimals(+mytime, TIME_DECIMALS));
			col = "^1";
		}
		else if(mytime == 0)
		{
			timestr = "+0.0";
			col = "^3";
		}
		else
		{
			timestr = strcat("-", ftos_decimals(-mytime, TIME_DECIMALS));
			col = "^2";
		}

		if(othertime > 0)
		{
			othertimestr = strcat("+", ftos_decimals(+othertime, TIME_DECIMALS));
			othercol = "^1";
		}
		else if(othertime == 0)
		{
			othertimestr = "+0.0";
			othercol = "^3";
		}
		else
		{
			othertimestr = strcat("-", ftos_decimals(-othertime, TIME_DECIMALS));
			othercol = "^2";
		}

		if(lapdelta > 0)
		{
			lapstr = sprintf(_(" (-%dL)"), lapdelta);
			col = "^2";
		}
		else if(lapdelta < 0)
		{
			lapstr = sprintf(_(" (+%dL)"), -lapdelta);
			col = "^1";
		}
	}
	else if(theirtime > 0) // anticipation
	{
		if(mytime >= theirtime)
			timestr = strcat("+", ftos_decimals(mytime - theirtime, TIME_DECIMALS));
		else
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(theirtime), false);
		col = "^3";
		if(mytime >= othertime)
			othertimestr = strcat("+", ftos_decimals(mytime - othertime, TIME_DECIMALS));
		else
			othertimestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(othertime), false);
		othercol = "^7";
	}

	if(cp == 254)
		cpname = _("Start line");
	else if(cp == 255)
		cpname = _("Finish line");
	else if(cp)
		cpname = sprintf(_("Intermediate %d"), cp);
	else
		cpname = _("Finish line");

	if(theirtime < 0)
		return strcat(col, cpname);
	else if(theirname == "")
		return strcat(col, sprintf("%s (%s)", cpname, timestr));
	else if(othertime)
		return strcat(col, sprintf("%s %s(%s)%s (%s %s)", cpname, othercol, othertimestr, col, timestr, strcat(ColorTranslateRGB(theirname), col, lapstr)));
	else
		return strcat(col, sprintf("%s (%s %s)", cpname, timestr, strcat(ColorTranslateRGB(theirname), col, lapstr)));
}

void HUD_RaceTimer ()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_racetimer) return;
		if(!MUTATOR_CALLHOOK(ShowRaceTimer)) return;
		if(spectatee_status == -1) return;
	}

	HUD_Panel_LoadCvars();

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_racetimer_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	// always force 4:1 aspect
	vector newSize = '0 0 0';
	if(mySize.x/mySize.y > 4)
	{
		newSize.x = 4 * mySize.y;
		newSize.y = mySize.y;

		pos.x = pos.x + (mySize.x - newSize.x) / 2;
	}
	else
	{
		newSize.y = 1/4 * mySize.x;
		newSize.x = mySize.x;

		pos.y = pos.y + (mySize.y - newSize.y) / 2;
	}
	mySize = newSize;

	float a, t;
	string s, forcetime;
	vector str_pos;

	if(autocvar__hud_configure)
	{
		s = "0:13:37";
		draw_beginBoldFont();
		str_pos = pos + eX * 0.5 * (mySize.x - stringwidth(s, false, '1 1 0' * 0.6 * mySize.y));
		drawstring(str_pos, s, '1 1 0' * 0.6 * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
		s = strcat("^1", sprintf(_("Intermediate %d"), 1), " (+15.42)");
		str_pos = pos + vec2(0.5 * (mySize.x - stringwidth(s, true, '1 1 0' * 0.2 * mySize.y)), 0.6 * mySize.y);
		drawcolorcodedstring(str_pos, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha, DRAWFLAG_NORMAL);
		s = sprintf(_("PENALTY: %.1f (%s)"), 2, _("missing a checkpoint"));
		s = strcat("^1", s);
		str_pos = pos + vec2(0.5 * (mySize.x - stringwidth(s, true, '1 1 0' * 0.2 * mySize.y)), 0.8 * mySize.y);
		drawcolorcodedstring(str_pos, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else if(race_checkpointtime)
	{
		a = bound(0, 2 - (time - race_checkpointtime), 1);
		s = "";
		forcetime = "";
		if(a > 0) // just hit a checkpoint?
		{
			if(race_checkpoint != 254)
			{
				if(race_time && race_previousbesttime)
					s = MakeRaceString(race_checkpoint, TIME_DECODE(race_time) - TIME_DECODE(race_previousbesttime), 0, ((race_mypreviousbesttime) ? TIME_DECODE(race_time) - TIME_DECODE(race_mypreviousbesttime) : 0), 0, race_previousbestname);
				else
					s = MakeRaceString(race_checkpoint, 0, -1, 0, 0, race_previousbestname);
				if(race_time)
					forcetime = TIME_ENCODED_TOSTRING(race_time, false);
			}
		}
		else
		{
			if(race_laptime && race_nextcheckpoint != 254)
			{
				if(race_nextbesttime)
				{
					a = bound(0, 2 - ((race_laptime + TIME_DECODE(race_nextbesttime)) - (time + TIME_DECODE(race_penaltyaccumulator))), 1);
					float a2 = ((race_mybesttime) ? bound(0, 2 - ((race_laptime + TIME_DECODE(race_mybesttime)) - (time + TIME_DECODE(race_penaltyaccumulator))), 1) : 0);
					if(a > 0) // next one?
						s = MakeRaceString(race_nextcheckpoint, (time + TIME_DECODE(race_penaltyaccumulator)) - race_laptime, TIME_DECODE(race_nextbesttime), ((a2 > 0) ? TIME_DECODE(race_mybesttime) : 0), 0, race_nextbestname);
				}
			}
		}

		if(s != "" && a > 0)
		{
			str_pos = pos + vec2(0.5 * (mySize.x - stringwidth(s, true, '1 1 0' * 0.2 * mySize.y)), 0.6 * mySize.y);
			drawcolorcodedstring(str_pos, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		if(race_penaltytime)
		{
			a = bound(0, 2 - (time - race_penaltyeventtime), 1);
			if(a > 0)
			{
				s = sprintf(_("PENALTY: %.1f (%s)"), race_penaltytime * 0.1, race_penaltyreason);
				s = strcat("^1", s);
				str_pos = pos + vec2(0.5 * (mySize.x - stringwidth(s, true, '1 1 0' * 0.2 * mySize.y)), 0.8 * mySize.y);
				drawcolorcodedstring(str_pos, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}

		draw_beginBoldFont();

		if(forcetime != "")
		{
			a = bound(0, (time - race_checkpointtime) / 0.5, 1);
			str_pos = pos + eX * 0.5 * (mySize.x - stringwidth(forcetime, false, '1 1 0' * 0.6 * mySize.y));
			drawstring_expanding(str_pos, forcetime, '1 1 0' * 0.6 * mySize.y, '1 1 1', panel_fg_alpha, 0, a);
		}
		else
			a = 1;

		if(race_laptime && race_checkpoint != 255)
		{
			s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime), false);
			str_pos = pos + eX * 0.5 * (mySize.x - stringwidth(s, false, '0.6 0.6 0' * mySize.y));
			drawstring(str_pos, s, '0.6 0.6 0' * mySize.y, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		draw_endBoldFont();
	}
	else
	{
		if(race_mycheckpointtime)
		{
			a = bound(0, 2 - (time - race_mycheckpointtime), 1);
			s = MakeRaceString(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -(race_mycheckpointenemy == ""), 0, race_mycheckpointlapsdelta, race_mycheckpointenemy);
			str_pos = pos + vec2(0.5 * (mySize.x - stringwidth(s, true, '1 1 0' * 0.2 * mySize.y)), 0.6 * mySize.y);
			drawcolorcodedstring(str_pos, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}
		if(race_othercheckpointtime && race_othercheckpointenemy != "")
		{
			a = bound(0, 2 - (time - race_othercheckpointtime), 1);
			s = MakeRaceString(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -(race_othercheckpointenemy == ""), 0, race_othercheckpointlapsdelta, race_othercheckpointenemy);
			str_pos = pos + vec2(0.5 * (mySize.x - stringwidth(s, true, '1 1 0' * 0.2 * mySize.y)), 0.6 * mySize.y);
			drawcolorcodedstring(str_pos, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		if(race_penaltytime && !race_penaltyaccumulator)
		{
			t = race_penaltytime * 0.1 + race_penaltyeventtime;
			a = bound(0, (1 + t - time), 1);
			if(a > 0)
			{
				string col;
				if(time < t)
				{
					t = (t - time) * 0.1;
					col = "^1";
				}
				else
				{
					t = 0;
					col = "^2";
				}
				s = sprintf(_("PENALTY: %.1f (%s)"), t, race_penaltyreason);
				s = strcat(col, s);
				str_pos = pos + vec2(0.5 * (mySize.x - stringwidth(s, true, '1 1 0' * 0.2 * mySize.y)), 0.6 * mySize.y);
				drawcolorcodedstring(str_pos, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}
	}
}
