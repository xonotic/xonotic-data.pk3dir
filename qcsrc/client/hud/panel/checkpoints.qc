#include "checkpoints.qh"
#include "racetimer.qh"
#include "physics.qh"

#include <common/gametypes/gametype/race/race.qh>
#include <client/draw.qh>
#include <common/ent_cs.qh>

// Checkpoints (#27)

void HUD_Checkpoints_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_checkpoints_align");
	HUD_Write_Cvar("hud_panel_checkpoints_flip");
	HUD_Write_Cvar("hud_panel_checkpoints_fontscale");
}

const float CHECKPOINTS_SPACING   = 0.25;
const float CHECKPOINTS_BASE_SIZE = 0.75;

string demolines[10];

vector Checkpoints_drawstring(string s, vector pos, vector sz, float a, vector fontsize)
{
	getWrappedLine_remaining = s;
	const float align = bound(0, autocvar_hud_panel_checkpoints_align, 1);
	float offset = 0;
	if (autocvar_hud_panel_checkpoints_flip)
	{
		const string s_original = s;
		do
		{
			s = getWrappedLine(sz.x - offset, fontsize, stringwidth_colors);
			if (autocvar_hud_panel_checkpoints_align)
				offset = (sz.x - stringwidth_colors(s, fontsize) - offset) * align;
			pos.y -= fontsize.y;
			offset = fontsize.x;
		}
		while (getWrappedLine_remaining);

		getWrappedLine_remaining = s_original;
		offset = 0;
	}
	const float old_pos_y = pos.y;

	do
	{
		s = getWrappedLine(sz.x - offset, fontsize, stringwidth_colors);
		if (autocvar_hud_panel_checkpoints_align)
			offset = (sz.x - stringwidth_colors(s, fontsize) - offset) * align;
		drawcolorcodedstring(pos + eX * offset, s, fontsize, a, DRAWFLAG_NORMAL);
		pos.y += fontsize.y;
		offset = fontsize.x;
	}
	while (getWrappedLine_remaining);

	if (autocvar_hud_panel_checkpoints_flip)
	{
		pos.y = old_pos_y;
		pos.y -= CHECKPOINTS_SPACING * fontsize.y;
	}
	else
		pos.y += CHECKPOINTS_SPACING * fontsize.y;

	return pos;
}

vector Checkpoints_Draw(int end, vector pos, vector fontsize, vector rs_fontsize)
{
	string s;
	for (int j = end; j >= 0; --j)
	{
		s = autocvar__hud_configure ? demolines[j] : race_checkpoint_splits[j];
		if (s == "")
			continue;
		pos = Checkpoints_drawstring(s, pos, panel_size, panel_fg_alpha, fontsize);
		if (autocvar_hud_panel_checkpoints_flip) // now check if the next line can be shown (fit)
		{
			if (pos.y < panel_pos.y)
				break;
		}
		else
		{
			if (pos.y > panel_pos.y + panel_size.y - rs_fontsize.y)
				break;
		}
	}
	return pos;
}

void HUD_Checkpoints()
{
	if (!autocvar__hud_configure)
	{
		if (!autocvar_hud_panel_checkpoints) return;
	}

	HUD_Panel_LoadCvars();

	if (autocvar_hud_panel_checkpoints_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();

	if (panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	vector pos = panel_pos;
	if (autocvar_hud_panel_checkpoints_flip)
		pos.y += panel_size.y;

	const vector rs_fontsize = hud_fontsize * CHECKPOINTS_BASE_SIZE;
	const vector fontsize = autocvar_hud_panel_checkpoints_fontscale > 0.125 ? rs_fontsize * autocvar_hud_panel_checkpoints_fontscale : rs_fontsize;

	int i;
	if (!autocvar__hud_configure)
	{
		// show up to race_nextcheckpoint (not including) or everything if you are before start (0 or 254)
		// (except race_laptime != 0 for race, means next is start+finish so don't show previous lap finish)
		if (race_checkpoint != 0 && race_checkpoint != 254) // middle of run/race
			i = race_checkpoint;
		else if (ISGAMETYPE(RACE) && race_nextcheckpoint == 0) // before start, but on race, so don't keep old finish visible
			i = 253;
		else // before start, not on race (cts), keep old run cps visible
			i = 255;
	}
	else
	{
		const string units_text = autocvar_cl_race_cptimes_showspeed_unit ? GetSpeedUnit(autocvar_hud_speed_unit) : "";
		const float speed_conv_f = GetSpeedUnitFactor(autocvar_hud_speed_unit);
		for (i = 0; i < 4; ++i)
		{
			string timestr     = TIME_ENCODED_TOSTRING(TIME_ENCODE(18.7 + i * 5.33), false);
			string time_split  = i == 0 ? "+0.39" : i == 1 ? "+0.0" : i == 2 ? "-0.14" : "-0.08";
			string col         = i == 0 ? "^1" : i == 1 ? "^3" : "^2";
			float speed_split  = speed_conv_f * (1086 + i * 51);
			float speed_diff   = speed_conv_f * (i == 0 ? -34 : i == 1 ? 86 : i == 2 ? 25 : 0);
			string speed_color = rgb_to_hexcolor(i == 0 ? autocvar_hud_progressbar_acceleration_neg_color : autocvar_hud_progressbar_acceleration_color);
			if (i == 3)
				speed_color = "^3";
			demolines[i] = sprintf(strcat("%s %s", _("Checkpoint %d"), " (%s) ^7%d%s %s"), timestr, col, i+1, time_split, speed_split, units_text, sprintf("%s(%+d%s)", speed_color, speed_diff, units_text));
		}
		for (; i < 10; ++i) // iust draw 10 for configuring the HUD
			demolines[i] = sprintf(strcat("%s ^7", _("Checkpoint %d"), " ^7%d%s"), TIME_ENCODED_TOSTRING(TIME_ENCODE(i*9.37), false), i+1, (1100 + i*63) * speed_conv_f, units_text);
		--i;
	}

	pos = Checkpoints_Draw(i, pos, fontsize, rs_fontsize);
}
