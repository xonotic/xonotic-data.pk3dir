#include "modicons.qh"

#include <client/draw.qh>
#include <common/ent_cs.qh>
#include <common/gametypes/_mod.qh>
#include <common/gametypes/gametype/ctf/cl_ctf.qh>
#include <common/mapinfo.qh>
#include <common/scores.qh>

// Mod icons (#10)

void HUD_ModIcons_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files

	FOREACH(Gametypes, it.m_modicons_export, it.m_modicons_export(fh));
}

void HUD_ModIcons_SetFunc()
{
	HUD_ModIcons_GameType = gametype.m_modicons;
}

void HUD_Mod_TableWithAR_Draw(vector myPos, vector mySize, int items, float aspect_ratio, void(vector, vector, float, int) drawFunc)
{
	if (!drawFunc)
		return;

	int rows = HUD_GetRowCount(items, mySize, aspect_ratio);
	int cols = ceil(items / rows);

	vector itemSize = vec2(mySize.x / cols, mySize.y / rows);
	vector itemPos  = myPos;
	int row = 0;
	for (int i = 0; i < items; ++i)
	{
		drawFunc(itemPos, itemSize, aspect_ratio, i); // e.g. HUD_Mod_EliminatedPlayers_DrawItem

		if (row == rows - 1)
		{
			row = 0;
			itemPos.y  = myPos.y;
			itemPos.x += itemSize.x;
		}
		else
		{
			++row;
			itemPos.y += itemSize.y;
		}
	}
}

/// General eliminated player draw func. Used by CA & FT modicons HUD
void HUD_Mod_EliminatedPlayers_DrawItem(vector itemPos, vector itemSize, float aspect_ratio, int i)
{
	float f;
	if (itemSize.x / itemSize.y > aspect_ratio)
	{
		f = itemSize.y * aspect_ratio;
		itemPos.x += (itemSize.x - f) * 0.5;
		itemSize.x = f;
	}
	else
	{
		f = itemSize.x / aspect_ratio;
		itemPos.y += (itemSize.y - f) * 0.5;
		itemSize.y = f;
	}

	int stat = alive_on_team[i];
	int tm = Team_IndexToTeam(i + 1);
	float alpha = (stat == 1 && tm == entcs_GetTeam(player_currententnum - 1))
		? blink(0.85, 0.15, 5) // blink if there's 1 player left on our team
		: (stat ? 1 : 0.5); // half alpha if the team is eliminated
	vector color = Team_ColorRGB(tm) * alpha;

	if (aspect_ratio != 1) // draw icon
	{
		string pic = strcat("player_", Static_Team_ColorName_Lower(tm));
		itemSize.x *= 0.5;
		drawpic_aspect_skin(itemPos, pic, itemSize, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
		itemPos.x += itemSize.x;
	}

	// draw text
	f = bound(0, (time - alive_on_team_change_time[i]) * 2, 1);
	if (f < 1)
		drawstring_aspect_expanding(itemPos, itos(stat), itemSize, color, panel_fg_alpha, DRAWFLAG_NORMAL, f);
	drawstring_aspect(itemPos, itos(stat), itemSize, color, panel_fg_alpha * f, DRAWFLAG_NORMAL);
}

/// Smoothly moves cache_value towards real_value, initially fast then slowing down. Returns new cache_value
float HUD_Mod_SmoothlyUpdateCachedValue(float cache_value, float real_value, float epsilon)
{
	return (fabs(cache_value - real_value) < epsilon)
		? real_value
		: real_value + (cache_value - real_value) * ((33/32) ** (-256 * frametime)); // -256*frametime should be close to 1, ideal for floating point inaccuracies
}

float mod_alpha;

void HUD_ModIcons(bool should_draw)
{
	if (!autocvar__hud_configure)
	{
		if (!autocvar_hud_panel_modicons || !HUD_ModIcons_GameType)
			should_draw = false;
	}
	if (!should_draw)
	{
		if (HUD_ModIcons_GameType)
			HUD_ModIcons_GameType(panel_pos, panel_size, false);
		else if (autocvar__hud_configure)
			HUD_Mod_CTF(panel_pos, panel_size, false);
		return;
	}

	if (mod_active || (!HUD_ModIcons_GameType && autocvar__hud_configure))
		mod_alpha = min(mod_alpha + frametime * 2, 1);
	else
		mod_alpha = max(mod_alpha - frametime * 2, 0);

	//if (mod_alpha <= 0)
	//	return;
	panel_fade_alpha *= mod_alpha;
	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	if (autocvar_hud_panel_modicons_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();

	HUD_Panel_DrawBg();

	if (panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	if (HUD_ModIcons_GameType)
		HUD_ModIcons_GameType(panel_pos, panel_size, should_draw);
	else if (autocvar__hud_configure)
		HUD_Mod_CTF(panel_pos, panel_size, should_draw);

	draw_endBoldFont();
}
