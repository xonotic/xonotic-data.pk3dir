#include "cl_ctf.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

enum
{
	FLAG_STATUS_BASE, FLAG_STATUS_SHIELDED, FLAG_STATUS_DROPPED, FLAG_STATUS_TAKEN, FLAG_STATUS_CARRY
};
// Teams can potentially have multiple flags (g_ctf_flag_stay 1 or if map has multiple) and hence multiple statuses
// We choose the highest (most important) status to display
int flag_status[NUM_TEAMS + 1]; ///< Each team's flag status we'll display, index 0 is neutral
bool ctf_oneflag; ///< One-flag CTF mode enabled/disabled
bool ctf_stalemate; ///< Currently in stalemate
bool ctf_icons_shown; ///< Whether the modicons HUD will show any icons

float flag_carry_change_time[NUM_TEAMS + 1]; ///< Time when flag_status[...] last changed to FLAG_STATUS_CARRY
float flag_taken_change_time[NUM_TEAMS + 1]; ///< Time when flag_status[...] last changed to FLAG_STATUS_TAKEN

NET_HANDLE(ENT_CLIENT_CTF_FLAGSTATUSES, bool isNew)
{
	int sf = ReadByte();
	int currententnum = (sf & SF_CTF_SPEC)
		? ReadByte() - 1 // spec - receive their entnum
		: player_localnum; // playing - use our own
	ctf_oneflag = boolean(sf & SF_CTF_ONEFLAG);
	ctf_stalemate = boolean(sf & SF_CTF_STALEMATE);
	int flag_status_prev[NUM_TEAMS + 1];

	// reset flag statuses first
	int i, i_begin, i_end, our_team_i;
	if (ctf_oneflag)
		i_begin = i_end = our_team_i = 0;
	else
	{
		i_begin = 1;
		i_end = NUM_TEAMS;
		our_team_i = Team_TeamToIndex(entcs_GetTeam(currententnum));
	}
	for (i = i_begin; i <= i_end; ++i)
	{
		flag_status_prev[i] = flag_status[i];
		if ((sf & SF_CTF_FLAGS) || flag_status[i] < FLAG_STATUS_DROPPED) // reset all if receiving flag statuses, otherwise only BASE and SHIELDED
			flag_status[i] = ((sf & SF_CTF_SHIELDED) && i != our_team_i) ? FLAG_STATUS_SHIELDED : FLAG_STATUS_BASE; // can't be shielded from our own flag
	}

	if (sf & SF_CTF_FLAGS) // receive flag statuses
	{
		for (i = 0; i < maxclients; ++i)
			if (playerslots[i])
				playerslots[i].gametype_status = 0;

		// read all away-flag statuses
		int new_status, team_i, flag_owner, flags_away = ReadShort();
		for (i = 0; i < flags_away; ++i)
		{
			flag_owner = ReadByte();
			team_i = ReadByte(); // 0 is neutral, 1 is 1st team (red), etc.
			if (flag_owner)
			{
				--flag_owner;
				if (!playerslots[flag_owner])
					playerslots[flag_owner] = new_pure(playerslot);
				playerslots[flag_owner].gametype_status |= BIT(team_i);
				new_status = (flag_owner == currententnum)
					? FLAG_STATUS_CARRY // carrying / passing as sender
					: FLAG_STATUS_TAKEN;
			}
			else
				new_status = FLAG_STATUS_DROPPED;
			if (flag_status[team_i] < new_status)
				flag_status[team_i] = new_status;
		}

		for (i = i_begin; i <= i_end; ++i)
			if (flag_status[i] != flag_status_prev[i])
			{
				if (flag_status[i] == FLAG_STATUS_CARRY || flag_status_prev[i] == FLAG_STATUS_CARRY)
					flag_carry_change_time[i] = time;
				else if (flag_status[i] == FLAG_STATUS_TAKEN || flag_status_prev[i] == FLAG_STATUS_TAKEN)
					flag_taken_change_time[i] = time;
			}
	}
	else if (sf & SF_CTF_SPEC_CHANGED) // spec status changed but we didn't re-receive flags, need to update caches
	{
		// above we managed FLAG_STATUS_SHIELDED and FLAG_STATUS_BASE,
		// now change all FLAG_STATUS_CARRY to FLAG_STATUS_TAKEN, then re-set the flags we're carrying
		int team_i, gt_status;
		for (i = i_begin; i <= i_end; ++i)
			if (flag_status[i] == FLAG_STATUS_CARRY)
				flag_status[i] = FLAG_STATUS_TAKEN;
		if (playerslots[currententnum])
			for (i = 0, gt_status = playerslots[currententnum].gametype_status; gt_status; gt_status >>= 1, ++i)
				if (gt_status & 1)
					flag_status[i] = FLAG_STATUS_CARRY;
	}

	ctf_icons_shown = false;
	for (i = i_begin; i <= i_end; ++i)
		if (flag_status[i] != FLAG_STATUS_BASE)
		{
			ctf_icons_shown = true;
			break;
		}
	return true;
}

string HUD_Mod_CTF_GetPic(int team_i, int status)
{
	string suffix;
	switch (status)
	{
		default:
		case FLAG_STATUS_CARRY:     suffix = "_carrying";  break;
		case FLAG_STATUS_TAKEN:     suffix = "_taken";     break;
		case FLAG_STATUS_DROPPED:   suffix = "_lost";      break;
		case FLAG_STATUS_SHIELDED:  suffix = "_shielded";  break;
	}
	return strcat("flag_", Static_Team_ColorName_Lower(Team_IndexToTeam(team_i)), suffix);
}

void HUD_Mod_CTF_DrawItem(vector itemPos, vector itemSize, float aspect_ratio, int i)
{
	int team_i;
	if (ctf_oneflag)
		team_i = 0; // neutral
	else if (mod_placeholder)
		team_i = i + 1; // just draw red, blue, etc.
	else
	{
		// get the ith team: teams may be skipped in CTF
		team_i = -1;
		for (; i >= 0; --i)
			while (!(autocvar__teams_available & BIT(++team_i)))
				if (team_i + 1 == NUM_TEAMS)
					break;
		++team_i; // skip neutral
	}

	int status = (mod_placeholder)
		? (-i) % (FLAG_STATUS_CARRY - FLAG_STATUS_SHIELDED + 1) + FLAG_STATUS_CARRY // CARRY -> SHIELDED, repeat
		: flag_status[team_i];

	float alpha = (autocvar_hud_panel_modicons_animations && status == FLAG_STATUS_CARRY)
		? blink(0.85, 0.15, 5) // blink only if we're carrying
		: 1;
	float f = 1;
	if (!mod_placeholder && autocvar_hud_panel_modicons_animations)
	{
		float expanding_f;
		#define DRAW_EXPANDING(the_arr, the_status) \
			expanding_f = bound(0, (time - the_arr[team_i]) * 2, 1); \
			if (expanding_f < 1) \
				drawpic_aspect_skin_expanding(itemPos, HUD_Mod_CTF_GetPic(team_i, the_status), itemSize, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL, expanding_f); \
			if (the_status == status) \
				f = expanding_f;
		DRAW_EXPANDING(flag_carry_change_time, FLAG_STATUS_CARRY);
		DRAW_EXPANDING(flag_taken_change_time, FLAG_STATUS_TAKEN);
		#undef DRAW_EXPANDING
	}

	if (status == FLAG_STATUS_BASE)
		return;

	if (status != FLAG_STATUS_SHIELDED && (ctf_stalemate || (mod_placeholder && ctf_oneflag)))
		drawpic_aspect_skin(itemPos, "flag_stalemate", itemSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(itemPos, HUD_Mod_CTF_GetPic(team_i, status), itemSize, '1 1 1', panel_fg_alpha * alpha * f, DRAWFLAG_NORMAL);
}

void HUD_Mod_CTF(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	mod_active = ctf_icons_shown;
	if (!mod_active) // ctf_icons_shown doesn't account for expanding icons (since they're time-dependent)
	{
		int i_end = (ctf_oneflag ? 0 : NUM_TEAMS);
		for (int i = !ctf_oneflag; i <= i_end; ++i)
			if ((time - flag_carry_change_time[i]) * 2 < 1
			||  (time - flag_taken_change_time[i]) * 2 < 1)
			{
				mod_active = true;
				break;
			}
	}

	if (autocvar__hud_configure && !mod_active) // we'll make up something, so the panel isn't empty
		mod_placeholder = mod_active = true; // this is more complicated in CTF, since it needs it also work in gametypes with no modicons
	else if (!mod_active)
		return;
	else
		mod_placeholder = false;

	// Draw icons
	if (ctf_oneflag)
		HUD_Mod_CTF_DrawItem(myPos, mySize, 1, 0);
	else
		HUD_Mod_TableWithAR_Draw(myPos, mySize, max(2, team_count), 1, HUD_Mod_CTF_DrawItem); // aspect ratio 1
}

bool autocvar_hud_panel_scoreboard_ctf_leaderboard = true;

REGISTER_MUTATOR(cl_ctf, true);

MUTATOR_HOOKFUNCTION(cl_ctf, ShowRankings)
{
	if (autocvar_hud_panel_scoreboard_ctf_leaderboard && ISGAMETYPE(CTF) && STAT(CTF_SHOWLEADERBOARD))
	{
		M_ARGV(0, string) = _("Capture time rankings");
		return true;
	}
}
