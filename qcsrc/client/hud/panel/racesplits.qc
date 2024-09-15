#include "racesplits.qh"
#include "racetimer.qh" // for race_checkpoint_splits
#include <common/gamemodes/gamemode/race/race.qh> // for ISGAMETYPE(RACE)

#include <client/draw.qh>
#include <common/ent_cs.qh>


void HUD_RaceSplits_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_racesplits_flip");
}

vector RaceSplits_drawstring(string s, vector pos, vector sz, float a, vector fontsize)
{
	getWrappedLine_remaining = s;
	float offset = 0;
	while(getWrappedLine_remaining)
	{
		s = getWrappedLine(sz.x - offset, fontsize, stringwidth_colors);
		if(autocvar_hud_panel_racesplits_flip)
			offset = sz.x - stringwidth_colors(s, fontsize) - offset;
		drawcolorcodedstring(pos + eX * offset, s, fontsize, a, DRAWFLAG_NORMAL);
		pos.y += fontsize.y;
		offset = fontsize.x;
	}
	pos.y += fontsize.y * 0.25;
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
	int nrlines = autocvar_hud_panel_racesplits_lines <= HUD_RACESPLITS_MAX_NRLINES ? autocvar_hud_panel_racesplits_lines : HUD_RACESPLITS_MAX_NRLINES;
	vector fontsize = '0.8 1 0' * (mySize.y / (nrlines+2));
	string s;
	if(!autocvar__hud_configure)
	{
		if(spectatee_status)
		{
		//	RaceSplit(_("Splits not supported while spectating"));
		}

		if(!spectatee_status)
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
				RaceSplit(race_checkpoint_splits[mlines[j]]);
		}
	}
	else
	{
		string col[4]; col[0] = "^7"; col[1] = "^1"; col[2] = "^3"; col[3] = "^2";
		for (int j = 0; j < nrlines; ++j)
			// strcat to use same string as racetimer does, ugly but it's just for hud_configure
			RaceSplit(sprintf(strcat("%s",_("Intermediate %d"),"..."), col[j%4], j+1));
	}
}
