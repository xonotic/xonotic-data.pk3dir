#include "cl_survival.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

// hardcoded player colors for Survival
const int SURV_COLOR_PREY    = 51; // green
const int SURV_COLOR_HUNTER  = 68; // red

bool autocvar_cl_survival_reveal = true;
bool surv_reveal; ///< Show Hunters regardless of autocvar_cl_survival_reveal, since it's the end of the round
bool surv_show_hunters; ///< Cache of whether we're showing Hunters

NET_HANDLE(ENT_CLIENT_SURV_STATUSES, bool isNew)
{
	int i, sf = ReadByte();
	surv_reveal = (sf & SF_SURV_REVEAL);

	if (sf & (SF_SURV_HUNTERS | SF_SURV_REVEAL)) // receive Hunter statuses, in a bitset
	{
		int B, b;
		for (i = 0; i < maxclients; )
			for (B = ReadByte(), b = BIT(0); b < BIT(8) && i < maxclients; b <<= 1, ++i)
			{
				if (!playerslots[i] && (B & b))
					playerslots[i] = new_pure(playerslot);
				if (playerslots[i])
					playerslots[i].gametype_status = (B & b) ? SURV_STATUS_HUNTER : SURV_STATUS_PREY;
			}
	}
	else if (sf & (SF_SURV_SET | SF_SURV_RESET)) // make everyone Survivors (SF_SURV_SET) or 0 status (SF_SURV_RESET)
		for (i = 0; i < maxclients; ++i)
			if (playerslots[i])
				playerslots[i].gametype_status = (sf & SF_SURV_RESET) ? 0 : SURV_STATUS_PREY;

	surv_show_hunters = HUD_Mod_Survival_ShowHunters();
	HUD_Mod_Survival_ColorPlayers();
	return true;
}

bool HUD_Mod_Survival_ShowHunters()
{
	return (surv_reveal // reveal all Hunters
		|| playerslots[player_localnum].gametype_status == SURV_STATUS_HUNTER // we are a Hunter
		|| (spectatee_status > 0 && entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE
			&& playerslots[spectatee_status - 1].gametype_status == SURV_STATUS_HUNTER && autocvar_cl_survival_reveal)); // we're spectating a Hunter and chose to reveal them
}

void HUD_Mod_Survival_ColorPlayers()
{
	entity e;
	for (int plcolor, i = 0; i < maxclients; ++i)
	{
		e = playerslots[i];
		if (!e)
			continue;

		plcolor = (surv_show_hunters && e.gametype_status == SURV_STATUS_HUNTER)
			? SURV_COLOR_HUNTER
			: SURV_COLOR_PREY;
		e.colormap = 1024 + plcolor; // override scoreboard & player model colors
	}
}

void HUD_Mod_Survival(vector myPos, vector mySize, bool should_draw)
{
	bool surv_show_hunters_prev = surv_show_hunters;
	surv_show_hunters = HUD_Mod_Survival_ShowHunters();
	if (surv_show_hunters != surv_show_hunters_prev) // specced a different player or changed cl_survival_reveal
		HUD_Mod_Survival_ColorPlayers();

	if (!should_draw) // return after updating player colors
		return;

	int my_status = (spectatee_status > 0 && entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE && autocvar_cl_survival_reveal)
		? playerslots[spectatee_status - 1].gametype_status
		: playerslots[player_localnum].gametype_status;

	mod_active = (my_status != 0 // there's a status to show
		&& !(spectatee_status == -1 && entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE)); // we're not an observer
	if (autocvar__hud_configure && !mod_active) // make up something, so the panel isn't empty
	{
		my_status = SURV_STATUS_HUNTER;
		mod_active = true;
	}

	if (!mod_active)
		return;

	//string player_icon;
	if (my_status == SURV_STATUS_HUNTER)
		drawstring_aspect(myPos, _("Hunter"),   mySize, '1 0.0625 0.0625', panel_fg_alpha, DRAWFLAG_NORMAL);
		//player_icon = "player_red";
	else
		drawstring_aspect(myPos, _("Survivor"), mySize, '0.0625 1 0.0625', panel_fg_alpha, DRAWFLAG_NORMAL);
		//player_icon = "player_neutral"; // TODO need a green version
}

REGISTER_MUTATOR(cl_surv, true);

MUTATOR_HOOKFUNCTION(cl_surv, ForcePlayercolors_Skip, CBC_ORDER_LAST)
{
	if (!ISGAMETYPE(SURVIVAL))
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
	if (!ISGAMETYPE(SURVIVAL))
		return false;

	// initialize colors of new players
	for (entity pl = players.sort_next; pl; pl = pl.sort_next)
		if (pl.gotscores && pl.colormap == 0)
			pl.colormap = 1024 + SURV_COLOR_PREY;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_surv, DrawScoreboard_Force)
{
	// show the scoreboard when the round ends, so players can see who the hunter was
	return STAT(GAME_STOPPED);
}
