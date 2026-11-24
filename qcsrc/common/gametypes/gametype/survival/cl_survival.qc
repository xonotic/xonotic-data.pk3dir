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
	if (sf & SF_SURV_HUNTERS) // receive Hunters, in a bitset
		HUD_Mod_Survival_ReadRoleBitset(SURV_ROLE_HUNTER, SURV_ROLE_SURVIVOR);

	if (!(sf & SF_SURV_RESET) && playerslots[player_localnum].survival_role == SURV_ROLE_NONE)
		playerslots[player_localnum].survival_role = SURV_ROLE_SURVIVOR; // well I must be a good guy then

	surv_reveal_roles = HUD_Mod_Survival_RevealRoles();
	HUD_Mod_Survival_SetPlayerColors();
	return true;
}

/// Reveal to a spectator the role of the player they're spectating
bool HUD_Mod_Survival_UseSpectateeRole()
{
	return (spectatee_status > 0 && entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE // we're spectating someone
		&& autocvar_cl_survival_reveal); // ... and chose to reveal their role
}

/// Reveal every player's role
bool HUD_Mod_Survival_RevealRoles()
{
	return (surv_reveal // reveal all Hunters
		|| playerslots[player_localnum].survival_role == SURV_ROLE_HUNTER // we are a Hunter
		|| HUD_Mod_Survival_UseSpectateeRole()); // we're spectating a player and chose to reveal their role
}

// Hardcoded player colors for Survival
const int SURV_COLOR_SURVIVOR  = 51; ///< Top & bottom green
const int SURV_COLOR_HUNTER    = 68; ///< Top & bottom red
const int SURV_COLOR_UNKNOWN   = 52; ///< Green top, red bottom
int HUD_Mod_Survival_RoleColor(int role)
{
	switch (role)
	{
		case SURV_ROLE_HUNTER:    return SURV_COLOR_HUNTER;
		case SURV_ROLE_SURVIVOR:  return SURV_COLOR_SURVIVOR;
		default:                  return SURV_COLOR_UNKNOWN;
	}
}

void HUD_Mod_Survival_SetPlayerColors()
{
	// Add 1024 to override scoreboard & player model colors

	entity e;
	for (int i = 0; i < maxclients; ++i)
	{
		e = playerslots[i];
		if (e)
			e.colormap = 1024 + HUD_Mod_Survival_RoleColor((surv_reveal_roles)
				? e.survival_role
				: SURV_ROLE_NONE);
	}
	if (surv_reveal_roles)
		return;

	// Now set our own color
	e = HUD_Mod_Survival_UseSpectateeRole()
		? playerslots[spectatee_status - 1]
		: playerslots[player_localnum];
	if (e && e.survival_role != SURV_ROLE_NONE)
		e.colormap = 1024 + HUD_Mod_Survival_RoleColor(e.survival_role);
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

	int my_role = HUD_Mod_Survival_UseSpectateeRole()
		? playerslots[spectatee_status - 1].survival_role
		: playerslots[player_localnum].survival_role;

	mod_active = (my_role != SURV_ROLE_NONE // there's a role to show
		&& !(spectatee_status == -1 && entcs_GetSpecState(player_localnum) == ENTCS_SPEC_PURE)); // we're not an observer
	if (autocvar__hud_configure && !mod_active) // make up something, so the panel isn't empty
	{
		my_role = SURV_ROLE_HUNTER;
		mod_active = true;
	}

	if (!mod_active)
		return;

	float alpha = (entcs_GetSpecState(player_localnum) == ENTCS_SPEC_IN_SCOREBOARD) ? 0.5 : 1; // half alpha if we're in the game but eliminated
	//string player_icon;
	if (my_role == SURV_ROLE_HUNTER)
		drawstring_aspect(myPos, _("Hunter"),   mySize, '1 0.0625 0.0625', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
		//player_icon = "player_red";
	else
		drawstring_aspect(myPos, _("Survivor"), mySize, '0.0625 1 0.0625', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
		//player_icon = "player_neutral"; // TODO: need a green version
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
	if (player && player.survival_role == SURV_ROLE_HUNTER && surv_reveal_roles)
		Scoreboard_AddGametypeIcon("player_red"); // helps for colorblind people
}
