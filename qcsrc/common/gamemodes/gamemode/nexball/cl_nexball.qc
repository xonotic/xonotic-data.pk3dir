#include "cl_nexball.qh"

#include <client/hud/panel/modicons.qh>

// Nexball HUD mod icon
void HUD_Mod_NexBall(vector pos, vector mySize)
{
	float nb_pb_starttime, dt, p;
	int stat_items;

	stat_items = STAT(ITEMS);
	nb_pb_starttime = STAT(NB_METERSTART);

	if (stat_items & IT_KEY1)
		mod_active = 1;
	else
		mod_active = 0;

	//Manage the progress bar if any
	if (nb_pb_starttime > 0)
	{
		dt = (time - nb_pb_starttime) % nb_pb_period;
		// one period of positive triangle
		p = 2 * dt / nb_pb_period;
		if (p > 1)
			p = 2 - p;

		HUD_Panel_DrawProgressBar(pos, mySize, "progressbar", p, (mySize.x <= mySize.y), 0, autocvar_hud_progressbar_nexball_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if (stat_items & IT_KEY1)
		drawpic_aspect_skin(pos, "nexball_carrying", eX * mySize.x + eY * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}

int autocvar_cl_eventchase_nexball = 1;

REGISTER_MUTATOR(cl_nb, true);

MUTATOR_HOOKFUNCTION(cl_nb, WantEventchase)
{
	if(autocvar_cl_eventchase_nexball && ISGAMETYPE(NEXBALL) && !(WepSet_GetFromStat() & WEPSET(NEXBALL)))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_nb, DrawScoreboardAccuracy)
{
	return ISGAMETYPE(NEXBALL); // accuracy is not a factor in this gamemode
}
