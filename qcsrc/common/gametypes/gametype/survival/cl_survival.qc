#include "cl_survival.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

bool autocvar_cl_survival_reveal = true;
bool surv_reveal_roles; ///< Cache of whether we're revealing roles
bool surv_reveal; ///< Show Hunters regardless of autocvar_cl_survival_reveal, since it's the end of the round

/// Reads a bitset describing all players with role `role`, and sets every other none-role player to `off_role`
void HUD_Mod_Survival_ReadRoleBitset(int role, int off_role)
{
	for (int b, B, i = 0; i < maxclients; )
		for (B = ReadByte(), b = BIT(0); b < BIT(8) && i < maxclients; b <<= 1, ++i)
			if (B & b)
			{
				if (!playerslots[i])
					playerslots[i] = new_pure(playerslot);
				playerslots[i].survival_role = role;
			}
			else if (playerslots[i] && playerslots[i].survival_role == SURV_ROLE_NONE)
				playerslots[i].survival_role = off_role;
}

NET_HANDLE(ENT_CLIENT_SURV_ROLES, bool isNew)
{
	int sf = ReadByte();
	surv_reveal = boolean(sf & SF_SURV_REVEAL);

	if (sf & SF_SURV_RESET) // reset everyone to none-role
		for (int i = 0; i < maxclients; ++i)
			if (playerslots[i])
				playerslots[i].survival_role = SURV_ROLE_NONE;
	if (sf & SF_SURV_START)   // receive Detectives, in a bitset
		HUD_Mod_Survival_ReadRoleBitset(SURV_ROLE_DETECTIVE, SURV_ROLE_NONE);
	if (sf & SF_SURV_HUNTERS) // receive Hunters,    in a bitset
		HUD_Mod_Survival_ReadRoleBitset(SURV_ROLE_HUNTER,    SURV_ROLE_SURVIVOR);

	if (!(sf & SF_SURV_RESET) && playerslots[player_localnum].survival_role == SURV_ROLE_NONE)
		playerslots[player_localnum].survival_role = SURV_ROLE_SURVIVOR; // well I must be a good guy then

	surv_reveal_roles = HUD_Mod_Survival_RevealRoles();
	HUD_Mod_Survival_SetPlayerColors();
	return true;
}

NET_HANDLE(CLIENT_SURV_INVESTIGATION, bool isNew)
{
	int num = ReadByte() - 1;
	if (!playerslots[num])
		playerslots[num] = new_pure(playerslot);
	playerslots[num].survival_role = ReadByte();
	HUD_Mod_Survival_SetPlayerColors();
	return true;
}

/// Reveal every player's role
bool HUD_Mod_Survival_RevealRoles()
{
	return (surv_reveal // reveal all Hunters
		|| playerslots[player_localnum].survival_role == SURV_ROLE_HUNTER // we are a Hunter
		|| (entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE && autocvar_cl_survival_reveal)); // we're spectating and chose to reveal roles
}

/// Reveal to a spectator the role of a player
bool HUD_Mod_Survival_RevealSpectateeRole(entity player)
{
	return (autocvar_cl_survival_reveal // we chose to reveal roles
		|| player.survival_role == SURV_ROLE_DETECTIVE); // we're spectating a Detective (known to everyone)
}
bool HUD_Mod_Survival_ShouldColorPlayer(entity player)
{
	return (entcs_GetSpecState(player_localnum) != ENTCS_SPEC_PURE || surv_reveal_roles || HUD_Mod_Survival_RevealSpectateeRole(player));
}

// Hardcoded player colors for Survival
const int SURV_COLOR_SURVIVOR   = 51; ///< Top & bottom green
const int SURV_COLOR_HUNTER     = 68; ///< Top & bottom red
const int SURV_COLOR_DETECTIVE  = 85; ///< Top & bottom light blue
const int SURV_COLOR_UNKNOWN    = 52; ///< Green top, red bottom
int HUD_Mod_Survival_RoleColor(int role)
{
	switch (role)
	{
		case SURV_ROLE_HUNTER:     return SURV_COLOR_HUNTER;
		case SURV_ROLE_SURVIVOR:   return SURV_COLOR_SURVIVOR;
		case SURV_ROLE_DETECTIVE:  return SURV_COLOR_DETECTIVE;
		default:                   return SURV_COLOR_UNKNOWN;
	}
}

void HUD_Mod_Survival_SetPlayerColors()
{
	entity e;
	for (int role, i = 0; i < maxclients; ++i)
	{
		e = playerslots[i];
		if (e)
		{
			role = HUD_Mod_Survival_ShouldColorPlayer(e)
				? e.survival_role
				: SURV_ROLE_NONE;
			e.colormap = 1024 + HUD_Mod_Survival_RoleColor(role); // override scoreboard & player model colors
		}
	}
}

void HUD_Mod_Survival(vector myPos, vector mySize, bool should_draw)
{
	bool surv_reveal_roles_prev = surv_reveal_roles;
	surv_reveal_roles = HUD_Mod_Survival_RevealRoles();
	if (spectatee_status != spectatee_status_prev) // changed spec, update caches
	{
		HUD_Mod_Survival_SetPlayerColors(); // may need to make one player SURV_COLOR_SURVIVOR and another SURV_COLOR_UNKNOWN
		spectatee_status_prev = spectatee_status;
	}
	else if (surv_reveal_roles != surv_reveal_roles_prev) // may have changed cl_survival_reveal
		HUD_Mod_Survival_SetPlayerColors();

	if (!should_draw) // return after updating player colors
		return;

	int my_role;
	if (entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE)
		my_role = (spectatee_status > 0 && HUD_Mod_Survival_RevealSpectateeRole(playerslots[spectatee_status - 1]))
			? playerslots[spectatee_status - 1].survival_role // spectating and should show the role
			: SURV_ROLE_NONE; // observing or should hide the role
	else
		my_role = playerslots[player_localnum].survival_role; // playing

	mod_active = (my_role != SURV_ROLE_NONE); // there's a role to show
	if (autocvar__hud_configure && !mod_active) // make up something, so the panel isn't empty
	{
		my_role = SURV_ROLE_HUNTER;
		mod_active = true;
	}
	else if (!mod_active)
		return;

	//string player_icon;
	string s;
	vector color;
	switch (my_role)
	{
		case SURV_ROLE_HUNTER:
			s = _("Hunter");
			color = '1 0.0625 0.0625';
			//player_icon = "player_red";
			break;
		case SURV_ROLE_DETECTIVE:
			s = _("Detective");
			color = '0.0625 0.5 1';
			//player_icon = "player_blue";
			break;
		default:
			s = _("Survivor");
			color = '0.0625 1 0.0625';
			//player_icon = "player_neutral"; // TODO: need a green version
			break;
	}
	float alpha = (entcs_GetSpecState(player_localnum) == ENTCS_SPEC_IN_SCOREBOARD) ? 0.5 : 1; // half alpha if we're in the game but eliminated
	drawstring_aspect(myPos, s, mySize, color, panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
}

REGISTER_MUTATOR(cl_surv, true);

MUTATOR_HOOKFUNCTION(cl_surv, ResetPlayerGametypeFields)
{
	entity player = M_ARGV(0, entity);
	player.survival_role = SURV_ROLE_NONE;
}

MUTATOR_HOOKFUNCTION(cl_surv, ForcePlayercolors_Skip, CBC_ORDER_LAST)
{
	if (!ISGAMETYPE(SURVIVAL))
		return false;

	entity player = M_ARGV(0, entity);
	// On corpses the entity num is networked via .sv_entnum
	int slot = ((player.isplayermodel & ISPLAYER_CLIENT) ? player.entnum : player.sv_entnum);
	entity e = (slot > 0 && slot <= maxclients) ? playerslots[slot - 1] : NULL;
	if (e && e.colormap)
		player.colormap = e.colormap;
	else
		player.colormap = 1024 + SURV_COLOR_UNKNOWN;
	return true;
}

MUTATOR_HOOKFUNCTION(cl_surv, DrawScoreboard)
{
	if (!ISGAMETYPE(SURVIVAL))
		return false;

	// initialize colors of new players
	for (entity pl = players.sort_next; pl; pl = pl.sort_next)
		if (pl.gotscores && pl.colormap == 0)
			pl.colormap = 1024 + SURV_COLOR_UNKNOWN;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_surv, DrawScoreboard_Force)
{
	// show the scoreboard when the round ends, so players can see who the Hunters were
	return STAT(GAME_STOPPED);
}

MUTATOR_HOOKFUNCTION(cl_surv, SetScoreboardGametypeIcons)
{
	if (!ISGAMETYPE(SURVIVAL))
		return;

	entity player = M_ARGV(0, entity);
	if (!player)
		return;

	// Icons help for colorblind people
	if (player.survival_role == SURV_ROLE_DETECTIVE)
		Scoreboard_AddGametypeIcon("player_blue");
	else if (player.survival_role == SURV_ROLE_HUNTER && HUD_Mod_Survival_ShouldColorPlayer(player))
		Scoreboard_AddGametypeIcon("player_red");
}
