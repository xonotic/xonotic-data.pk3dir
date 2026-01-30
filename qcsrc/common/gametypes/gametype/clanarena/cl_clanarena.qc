#include "cl_clanarena.qh"

#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

void HUD_Mod_CA_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_ca_layout");
}

bool autocvar_hud_panel_modicons_ca_layout = true;

void HUD_Mod_CA(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	mod_active = true; // required in each mod function that always shows something

	HUD_Mod_TableWithAR_Draw(myPos, mySize, team_count, (autocvar_hud_panel_modicons_ca_layout ? 2 : 1), HUD_Mod_EliminatedPlayers_DrawItem);
}

REGISTER_MUTATOR(cl_ca, true);

MUTATOR_HOOKFUNCTION(cl_ca, DrawInfoMessages)
{
	return (ISGAMETYPE(CA) && entcs_GetSpecState(player_localnum) == ENTCS_SPEC_IN_SCOREBOARD);
}
