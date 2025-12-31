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

void HUD_Mod_TableWithAR_Draw(vector myPos, vector mySize, int limit, float aspect_ratio, void(vector, vector, float, int) drawFunc)
{
	int rows = HUD_GetRowCount(limit, mySize, aspect_ratio);
	int cols = ceil(limit / rows);

	int row = 0, col = 0;
	vector itemPos, itemSize = vec2(mySize.x / cols, mySize.y / rows);
	itemPos.z = 0;
	for (int i = 0; i < limit; ++i)
	{
		itemPos.x = myPos.x + col * itemSize.x;
		itemPos.y = myPos.y + row * itemSize.y;

		drawFunc(itemPos, itemSize, aspect_ratio, i);

		if (row == rows - 1)
		{
			row = 0;
			++col;
		}
		else
			++row;
	}
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
