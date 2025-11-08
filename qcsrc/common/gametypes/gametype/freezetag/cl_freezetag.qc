#include "cl_freezetag.qh"

#include <common/gametypes/gametype/clanarena/cl_clanarena.qh>

void HUD_Mod_FreezeTag_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_freezetag_layout");
}

void HUD_Mod_FreezeTag(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	HUD_Mod_CA_Draw(myPos, mySize, autocvar_hud_panel_modicons_freezetag_layout);
}

REGISTER_MUTATOR(cl_ft, true);

MUTATOR_HOOKFUNCTION(cl_ft, WantEventchase)
{
	if(autocvar_cl_eventchase_frozen && ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_ft, HUD_Draw_overlay)
{
	if(STAT(FROZEN) && ISGAMETYPE(FREEZETAG))
	{
		vector col = '0.25 0.90 1';
		float col_fade = max(0, STAT(REVIVE_PROGRESS) * 2 - 1);
		float alpha_fade = 0.3 + 0.7 * (1 - max(0, STAT(REVIVE_PROGRESS) * 4 - 3));
		if(col_fade)
			col += vec3(col_fade, -col_fade, -col_fade);

		M_ARGV(0, vector) = col;
		M_ARGV(1, float) = alpha_fade;
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(cl_ft, HUD_Damage_show)
{
	if(ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
		return true;
	return false;
}
