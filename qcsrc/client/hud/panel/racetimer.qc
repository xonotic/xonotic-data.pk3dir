#include "racetimer.qh"

#include <common/mapinfo.qh>

// Race timer (#6)

// return the string of the onscreen race timer
string MakeRaceString(int cp, float mytime, float theirtime, float lapdelta, string theirname)
{
	TC(int, cp);
	string col;
	string timestr;
	string cpname;
	string lapstr;
	lapstr = "";

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
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(theirtime));
		col = "^3";
	}
	else
	{
		col = "^7";
		timestr = "";
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
	else
		return strcat(col, sprintf("%s (%s %s)", cpname, timestr, strcat(ColorTranslateRGB(theirname), col, lapstr)));
}

void HUD_RaceTimer ()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_racetimer) return;
		if(!(gametype == MAPINFO_TYPE_RACE || gametype == MAPINFO_TYPE_CTS)) return;
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

	if(autocvar__hud_configure)
	{
		s = "0:13:37";
		draw_beginBoldFont();
		drawstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, false, '0.60 0.60 0' * mySize.y), s, '0.60 0.60 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
		s = _("^1Intermediate 1 (+15.42)");
		drawcolorcodedstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, true, '1 1 0' * 0.20 * mySize.y) + eY * 0.60 * mySize.y, s, '1 1 0' * 0.20 * mySize.y, panel_fg_alpha, DRAWFLAG_NORMAL);
		s = sprintf(_("^1PENALTY: %.1f (%s)"), 2, "missing a checkpoint");
		drawcolorcodedstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, true, '1 1 0' * 0.20 * mySize.y) + eY * 0.80 * mySize.y, s, '1 1 0' * 0.20 * mySize.y, panel_fg_alpha, DRAWFLAG_NORMAL);
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
					s = MakeRaceString(race_checkpoint, TIME_DECODE(race_time) - TIME_DECODE(race_previousbesttime), 0, 0, race_previousbestname);
				else
					s = MakeRaceString(race_checkpoint, 0, -1, 0, race_previousbestname);
				if(race_time)
					forcetime = TIME_ENCODED_TOSTRING(race_time);
			}
		}
		else
		{
			if(race_laptime && race_nextbesttime && race_nextcheckpoint != 254)
			{
				a = bound(0, 2 - ((race_laptime + TIME_DECODE(race_nextbesttime)) - (time + TIME_DECODE(race_penaltyaccumulator))), 1);
				if(a > 0) // next one?
				{
					s = MakeRaceString(race_nextcheckpoint, (time + TIME_DECODE(race_penaltyaccumulator)) - race_laptime, TIME_DECODE(race_nextbesttime), 0, race_nextbestname);
				}
			}
		}

		if(s != "" && a > 0)
		{
			drawcolorcodedstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, true, '1 1 0' * 0.2 * mySize.y) + eY * 0.6 * mySize.y, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		if(race_penaltytime)
		{
			a = bound(0, 2 - (time - race_penaltyeventtime), 1);
			if(a > 0)
			{
				s = sprintf(_("^1PENALTY: %.1f (%s)"), race_penaltytime * 0.1, race_penaltyreason);
				drawcolorcodedstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, true, '1 1 0' * 0.2 * mySize.y) + eY * 0.8 * mySize.y, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}

		draw_beginBoldFont();

		if(forcetime != "")
		{
			a = bound(0, (time - race_checkpointtime) / 0.5, 1);
			drawstring_expanding(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(forcetime, false, '1 1 0' * 0.6 * mySize.y), forcetime, '1 1 0' * 0.6 * mySize.y, '1 1 1', panel_fg_alpha, 0, a);
		}
		else
			a = 1;

		if(race_laptime && race_checkpoint != 255)
		{
			s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime));
			drawstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, false, '0.6 0.6 0' * mySize.y), s, '0.6 0.6 0' * mySize.y, '1 1 1', panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		draw_endBoldFont();
	}
	else
	{
		if(race_mycheckpointtime)
		{
			a = bound(0, 2 - (time - race_mycheckpointtime), 1);
			s = MakeRaceString(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -(race_mycheckpointenemy == ""), race_mycheckpointlapsdelta, race_mycheckpointenemy);
			drawcolorcodedstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, true, '1 1 0' * 0.2 * mySize.y) + eY * 0.6 * mySize.y, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}
		if(race_othercheckpointtime && race_othercheckpointenemy != "")
		{
			a = bound(0, 2 - (time - race_othercheckpointtime), 1);
			s = MakeRaceString(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -(race_othercheckpointenemy == ""), race_othercheckpointlapsdelta, race_othercheckpointenemy);
			drawcolorcodedstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, true, '1 1 0' * 0.2 * mySize.y) + eY * 0.6 * mySize.y, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
		}

		if(race_penaltytime && !race_penaltyaccumulator)
		{
			t = race_penaltytime * 0.1 + race_penaltyeventtime;
			a = bound(0, (1 + t - time), 1);
			if(a > 0)
			{
				if(time < t)
					s = sprintf(_("^1PENALTY: %.1f (%s)"), (t - time) * 0.1, race_penaltyreason);
				else
					s = sprintf(_("^2PENALTY: %.1f (%s)"), 0, race_penaltyreason);
				drawcolorcodedstring(pos + eX * 0.5 * mySize.x - '0.5 0 0' * stringwidth(s, true, '1 1 0' * 0.2 * mySize.y) + eY * 0.6 * mySize.y, s, '1 1 0' * 0.2 * mySize.y, panel_fg_alpha * a, DRAWFLAG_NORMAL);
			}
		}
	}
}
