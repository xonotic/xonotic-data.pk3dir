#include "cl_freezetag.qh"

#include <common/gamemodes/gamemode/clanarena/cl_clanarena.qh>

void HUD_Mod_FreezeTag_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_freezetag_layout");
}

void HUD_Mod_FreezeTag(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	HUD_Mod_CA_Draw(myPos, mySize, autocvar_hud_panel_modicons_freezetag_layout);
}
