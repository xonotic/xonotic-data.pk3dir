#include "racesplits.qh"
#include "racetimer.qh" // for race_checkpoint_splits
#include "physics.qh" // for autocvar_hud_progressbar_acceleration_neg_color
#include <common/gamemodes/gamemode/race/race.qh> // for ISGAMETYPE(RACE)

#include <client/draw.qh>
#include <common/ent_cs.qh>


void HUD_RaceSplits_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_racesplits_align");
	HUD_Write_Cvar("hud_panel_racesplits_flip");
	HUD_Write_Cvar("hud_panel_racesplits_lines");
}

vector RaceSplits_drawstring(string s, vector pos, vector sz, float a, vector fontsize)
{
	getWrappedLine_remaining = s;
	float offset = 0;
	while(getWrappedLine_remaining)
	{
		s = getWrappedLine(sz.x - offset, fontsize, stringwidth_colors);
		if(autocvar_hud_panel_racesplits_align)
			offset = sz.x - stringwidth_colors(s, fontsize) - offset;
		drawcolorcodedstring(pos + eX * offset, s, fontsize, a, DRAWFLAG_NORMAL);
		pos.y += fontsize.y;
		offset = fontsize.x;
	}
	pos.y += fontsize.y * (offset ? 0.25 : 1.25);
	return pos;
}

#define RaceSplit(s) MACRO_BEGIN \
	pos = RaceSplits_drawstring(s, pos, mySize,  panel_fg_alpha, fontsize); \
MACRO_END

void HUD_RaceSplits()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_racesplits) return;
	}

	HUD_Panel_LoadCvars();
	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_racesplits_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	#define HUD_RACESPLITS_MAX_NRLINES 50 // feels like twice more than enough
	int nrlines = min(HUD_RACESPLITS_MAX_NRLINES, autocvar_hud_panel_racesplits_lines);
	vector fontsize = '0.8 1 0' * (mySize.y / (nrlines*1.25));


	string s;
	if(!autocvar__hud_configure)
	{
		int mlines[HUD_RACESPLITS_MAX_NRLINES];
		int ln = nrlines -1;
		// show up to race_nextcheckpoint (not including) or everything
		// if you are before start (0 or 254)
		// (except race_laptime != 0 for race, means next is
		// start+finish so don't show previous lap finish)
		int i;
		if (race_checkpoint != 0 && race_checkpoint != 254)
		{ // middle of run/race
			i = race_checkpoint;
		}
		else if (ISGAMETYPE(RACE) && race_nextcheckpoint == 0)
		{ // before start, but on race, so don't keep old finish visible
			i = 253;
		}
		else
		{ // before start, not on race (cts), keep old run cps visible
			i = 255;
		}
		for (; ln >= 0 && i >= 0; --i)
		{
			if (race_checkpoint_splits[i])
			{
				mlines[ln] = i;
				--ln;
			}
		}
		for (int j = 0; j < nrlines; ++j)
			RaceSplit(race_checkpoint_splits[mlines[autocvar_hud_panel_racesplits_flip ? nrlines - 1 -j : j]]);
	}
	else
	{
		string units_text = autocvar_cl_race_cptimes_showspeed_unit ? GetSpeedUnit(autocvar_hud_speed_unit) : "";
		float speed_conv_f = GetSpeedUnitFactor(autocvar_hud_speed_unit);
		int j;
		string demolines[HUD_RACESPLITS_MAX_NRLINES];
		for(j = 0; j < nrlines && j < 4; ++j)
		{
			string timestr     = TIME_ENCODED_TOSTRING(TIME_ENCODE(18.7 + (j-1) * 5.33), false);
			string time_split  = j == 0 ? "+0.39" : j == 1 ? "+0.0" : j == 2 ? "-0.14" : "-0.08";
			string col         = j == 0 ? "^1" : j == 1 ? "^3" : "^2";
			float speed_split  = speed_conv_f * (1086 + (j-1) * 119);
			float speed_diff   = speed_conv_f * (j == 0 ? -34 : j == 1 ? 86 : j == 2 ? 25 : 0);
			string speed_color = rgb_to_hexcolor(j == 0 ? autocvar_hud_progressbar_acceleration_neg_color : autocvar_hud_progressbar_acceleration_color);
			if(j == 3)
				speed_color = "^3";
			demolines[j] = sprintf(strcat("%s %s", _("Intermediate %d"), " (%s) ^7%d%s %s"), timestr, col, j+1, time_split, speed_split, units_text, sprintf("%s(%+d%s)", speed_color, speed_diff, units_text));
		}
		for(; j < nrlines; ++j)
			demolines[j] = sprintf(strcat("%s ^7", _("Intermediate %d"), " ^7%d%s"), TIME_ENCODED_TOSTRING(TIME_ENCODE(j*9.37), false), j+1, (1100 + j*63) * speed_conv_f, units_text);
		for (int j = 0; j < nrlines; ++j)
			RaceSplit(demolines[autocvar_hud_panel_racesplits_flip ? nrlines - 1 -j : j]);

	}
}
