#include "cl_survival.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

NET_HANDLE(ENT_CLIENT_SURVIVALSTATUSES, bool isnew)
{
	make_pure(this);
	int sf = 0;
	serialize(byte, 0, sf);
	if (sf & BIT(1))
	{
		for (int j = 0; j < maxclients; ++j)
			if (playerslots[j])
				playerslots[j].survival_status = SURV_STATUS_PREY;
	}
	if (sf & BIT(0))
	{
		for (int i = 1; i <= maxclients; i += 8)
		{
			int f = 0;
			serialize(byte, 0, f);
			for (int b = 0; b < 8; ++b)
			{
				if (!(f & BIT(b))) continue;
				int j = i - 1 + b;
				if (playerslots[j])
					playerslots[j].survival_status = SURV_STATUS_HUNTER;
			}
		}
	}
	return true;
}

void HUD_Mod_Survival(vector pos, vector mySize)
{
	mod_active = 1; // survival should always show the mod HUD

	int mystatus = playerslots[player_localnum].survival_status;
	string player_text = "";
	vector player_color = '1 1 1';
	//string player_icon = "";

	if(STAT(GAMESTARTTIME) > time || STAT(ROUNDSTARTTIME) > time || entcs_IsSpectating(player_localnum))
		return;

	if(mystatus == SURV_STATUS_HUNTER)
	{
		player_text = _("Hunter");
		player_color = '1 0 0';
		//player_icon = "player_red";
	}
	else if(mystatus == SURV_STATUS_PREY)
	{
		player_text = _("Survivor");
		player_color = '0 1 0';
		//player_icon = "player_neutral";
	}

	drawstring_aspect(pos, player_text, vec2(mySize.x, mySize.y), player_color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

REGISTER_MUTATOR(cl_surv, true);

MUTATOR_HOOKFUNCTION(cl_surv, ForcePlayercolors_Skip, CBC_ORDER_LAST)
{
	if(!ISGAMETYPE(SURVIVAL))
		return false;

	entity player = M_ARGV(0, entity);
	entity e = playerslots[player.entnum - 1];
	int surv_status = ((e) ? e.survival_status : SURV_COLOR_PREY);
	int mystatus = playerslots[player_localnum].survival_status;

	int plcolor = SURV_COLOR_PREY; // default to survivor
	if((mystatus == SURV_STATUS_HUNTER || intermission || STAT(GAME_STOPPED)) && surv_status == SURV_STATUS_HUNTER)
		plcolor = SURV_COLOR_HUNTER;

	player.colormap = 1024 + plcolor;
	return true;
}

MUTATOR_HOOKFUNCTION(cl_surv, DrawScoreboard_Force)
{
	// show the scoreboard when the round ends, so players can see who the hunter was
	return STAT(GAME_STOPPED);
}
