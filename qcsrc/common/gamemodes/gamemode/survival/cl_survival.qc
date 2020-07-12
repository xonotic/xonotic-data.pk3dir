#include "cl_survival.qh"

#include <client/hud/panel/modicons.qh>

void HUD_Mod_Survival(vector pos, vector mySize)
{
	mod_active = 1; // survival should always show the mod HUD

	// since survivor state is the default value, spectators are considered survivors
	// so we must hide them manually here
	if(entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE)
		return; // no icon while spectating

	int mystatus = entcs_receiver(player_localnum).survival_status;
	//string player_icon = ((mystatus == SURV_STATUS_HUNTER) ? "player_red" : "player_neutral");
	string player_text = ((mystatus == SURV_STATUS_HUNTER) ? _("Hunter") : _("Survivor"));
	vector player_color = ((mystatus == SURV_STATUS_HUNTER) ? '1 0 0' : '0 1 0');
	//drawpic_aspect_skin(pos, player_icon, vec2(0.5 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(pos, player_text, vec2(mySize.x, mySize.y), player_color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

REGISTER_MUTATOR(cl_surv, true);

MUTATOR_HOOKFUNCTION(cl_surv, ForcePlayercolors_Skip)
{
	if(!ISGAMETYPE(SURVIVAL))
		return false;
		
	entity player = M_ARGV(0, entity);
	entity e = entcs_receiver(player.entnum - 1);
	int surv_status = ((e) ? e.survival_status : 0);
	int mystatus = entcs_receiver(player_localnum).survival_status;

	int plcolor = SURV_COLOR_PREY; // green
	if((mystatus == SURV_STATUS_HUNTER || intermission || STAT(GAME_STOPPED)) && surv_status == SURV_STATUS_HUNTER)
		plcolor = SURV_COLOR_HUNTER; // red

	player.colormap = 1024 + plcolor;
	return true;
}
