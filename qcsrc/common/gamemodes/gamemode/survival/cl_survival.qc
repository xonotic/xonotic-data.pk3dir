#include "cl_survival.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

NET_HANDLE(ENT_CLIENT_SURVIVALSTATUSES, bool isnew)
{
	make_pure(this);
	int sf = 0;
	serialize(byte, 0, sf);
	if (sf & BIT(0)) // make all players survivors
	{
		for (int j = 0; j < maxclients; ++j)
			if (playerslots[j])
				playerslots[j].survival_status = SURV_STATUS_PREY;
	}
	if (sf & BIT(1)) // receive hunter statuses
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

	// color all players
	for (int i = 1; i <= maxclients; ++i)
	{
		entity e = playerslots[i - 1];
		if (!e) continue;

		int plcolor = SURV_COLOR_PREY; // default color
		if(e.survival_status == SURV_STATUS_HUNTER) // if client knows this hunter
			plcolor = SURV_COLOR_HUNTER;

		e.colormap = 1024 + plcolor; // override scoreboard and player model colors
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
	if (e && e.colormap)
		player.colormap = e.colormap;
	else
		player.colormap = 1024 + SURV_COLOR_PREY;
	return true;
}

MUTATOR_HOOKFUNCTION(cl_surv, DrawScoreboard)
{
	if(!ISGAMETYPE(SURVIVAL))
		return false;

	// initialize colors of new players
	for(entity pl = players.sort_next; pl; pl = pl.sort_next)
		if(pl.gotscores && pl.colormap == 0)
			pl.colormap = 1024 + SURV_COLOR_PREY;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_surv, DrawScoreboard_Force)
{
	// show the scoreboard when the round ends, so players can see who the hunter was
	return STAT(GAME_STOPPED);
}
