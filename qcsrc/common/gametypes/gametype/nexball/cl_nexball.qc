#include "cl_nexball.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

// Check if we have the ball with playerslots[player_currententnum - 1].gametype_status
float ball_change_time; ///< Time when playerslots[player_currententnum - 1].gametype_status last changed

NET_HANDLE(ENT_CLIENT_NB_BALLSTATUSES, bool isNew)
{
	int ball_prev = (playerslots[player_currententnum - 1] ? playerslots[player_currententnum - 1].gametype_status : 0);
	// receive ball statuses, in a bitset
	for (int b, B, i = 0; i < maxclients; )
		for (B = ReadByte(), b = BIT(0); b < BIT(8) && i < maxclients; b <<= 1, ++i)
		{
			if (!playerslots[i] && (B & b))
				playerslots[i] = new_pure(playerslot);
			if (playerslots[i])
				playerslots[i].gametype_status = boolean(B & b);
		}

	if ((playerslots[player_currententnum - 1] ? playerslots[player_currententnum - 1].gametype_status : 0) != ball_prev)
		ball_change_time = time;
	return true;
}

void HUD_Mod_NexBall(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	mod_active = playerslots[player_currententnum - 1].gametype_status;
	if (!mod_active && (time - ball_change_time) * 2 < 1)
		mod_active = true; // still need to draw the expanding icons

	if (autocvar__hud_configure && !mod_active) // make up something, so the panel isn't empty & hidden
		mod_placeholder = mod_active = true;
	else if (!mod_active)
		return; // can return since the meterstart should only need to be drawn if the player has the ball
	else
		mod_placeholder = false;

	// Manage the progress bar if any
	float nb_pb_starttime = STAT(NB_METERSTART);
	if (nb_pb_starttime > 0)
	{
		float dt = (time - nb_pb_starttime) % nb_pb_period;
		// one period of positive triangle
		float p = 2 * dt / nb_pb_period;
		if (p > 1)
			p = 2 - p;

		HUD_Panel_DrawProgressBar(myPos, mySize, "progressbar", p, (mySize.x <= mySize.y), 0, autocvar_hud_progressbar_nexball_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	float f;
	if (!mod_placeholder && autocvar_hud_panel_modicons_animations)
	{
		f = bound(0, (time - ball_change_time) * 2, 1);
		if (f < 1)
			drawpic_aspect_skin_expanding(myPos, "nexball_carrying", mySize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}
	else
		f = 1;
	if (playerslots[player_currententnum - 1].gametype_status || mod_placeholder)
		drawpic_aspect_skin(myPos, "nexball_carrying", mySize, '1 1 1', panel_fg_alpha * f, DRAWFLAG_NORMAL);
}

int autocvar_cl_eventchase_nexball = 1;

REGISTER_MUTATOR(cl_nb, true);

MUTATOR_HOOKFUNCTION(cl_nb, WantEventchase)
{
	if (autocvar_cl_eventchase_nexball && ISGAMETYPE(NEXBALL) && !(WepSet_GetFromStat() & WEPSET(NEXBALL)))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_nb, DrawScoreboardAccuracy)
{
	return ISGAMETYPE(NEXBALL); // accuracy is not a factor in this gametype
}

MUTATOR_HOOKFUNCTION(cl_nb, DrawScoreboardItemStats)
{
	return ISGAMETYPE(NEXBALL); // hide the item stats panel
}
