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

float mod_alpha;

void HUD_ModIcons()
{
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_modicons) return;
		if(!HUD_ModIcons_GameType) return;
	}

	if(mod_active || autocvar__hud_configure)
		mod_alpha = min(mod_alpha + frametime * 2, 1);
	else
		mod_alpha = max(mod_alpha - frametime * 2, 0);

	//if(mod_alpha <= 0)
	//	return;
	panel_fade_alpha *= mod_alpha;
	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	if (autocvar_hud_panel_modicons_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();

	HUD_Panel_DrawBg();

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	if(autocvar__hud_configure)
		HUD_Mod_CTF(panel_pos, panel_size);
	else
		HUD_ModIcons_GameType(panel_pos, panel_size);

	draw_endBoldFont();
}
