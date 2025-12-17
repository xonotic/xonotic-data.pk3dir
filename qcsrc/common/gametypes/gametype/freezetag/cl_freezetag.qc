#include "cl_freezetag.qh"

#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

void HUD_Mod_FT_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_ft_layout");
}

bool autocvar_hud_panel_modicons_ft_layout = true;

void HUD_Mod_FT(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	mod_active = true; // required in each mod function that always shows something

	HUD_Mod_TableWithAR_Draw(myPos, mySize, team_count, (autocvar_hud_panel_modicons_ft_layout ? 2 : 1), HUD_Mod_EliminatedPlayers_DrawItem);
}

REGISTER_MUTATOR(cl_ft, true);

MUTATOR_HOOKFUNCTION(cl_ft, WantEventchase)
{
	if (autocvar_cl_eventchase_frozen && ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_ft, HUD_Draw_overlay)
{
	if (ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
	{
		vector col = '0.25 0.90 1';
		float col_fade = max(0, STAT(REVIVE_PROGRESS) * 2 - 1);
		float alpha_fade = 0.3 + 0.7 * (1 - max(0, STAT(REVIVE_PROGRESS) * 4 - 3));
		if (col_fade)
			col += vec3(col_fade, -col_fade, -col_fade);

		M_ARGV(0, vector) = col;
		M_ARGV(1, float) = alpha_fade;
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(cl_ft, HUD_Damage_show)
{
	if (ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
		return true;
	return false;
}
