#include "cl_tka.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>
#include <common/gametypes/gametype/keepaway/cl_keepaway.qh>

int tkaballs, tkaballs_carry, tkaballs_dropped;
int tkaballs_taken[NUM_TEAMS]; // taken doesn't include carrying -- taken by others

float tkaballs_carry_change_time; ///< Time when tkaballs_carry last changed
float tkaballs_taken_change_time[NUM_TEAMS]; ///< Time when tkaballs_taken[...] last changed

NET_HANDLE(ENT_CLIENT_TKA_BALLSTATUSES, bool isNew)
{
	int i, sf = ReadByte();
	for (i = 0; i < maxclients; ++i)
		if (playerslots[i])
			playerslots[i].gametype_status = 0;
	int tkaballs_carry_prev = tkaballs_carry;
	int tkaballs_taken_prev[NUM_TEAMS];
	for (i = 0; i < team_count; ++i)
		tkaballs_taken_prev[i] = tkaballs_taken[i];

	if (sf & SF_TKA_BALLS) // receive ball statuses
	{
		tkaballs = ReadShort();
		tkaballs_dropped = 0;
		for (i = 0; i < team_count; ++i)
			tkaballs_taken[i] = 0;
		int ball_owner;
		for (i = 0; i < tkaballs; ++i)
		{
			ball_owner = ReadByte();
			if (!ball_owner)
				++tkaballs_dropped;
			else
			{
				--ball_owner;
				if (!playerslots[ball_owner])
					playerslots[ball_owner] = new_pure(playerslot);
				++playerslots[ball_owner].gametype_status;
				++tkaballs_taken[Team_TeamToIndex(entcs_GetTeam(ball_owner)) - 1];
			}
		}
		tkaballs_carry = (playerslots[player_currententnum - 1] ? playerslots[player_currententnum - 1].gametype_status : 0);
		tkaballs_taken[Team_TeamToIndex(entcs_GetTeam(player_currententnum - 1)) - 1] -= tkaballs_carry;
	}
	else if (sf & SF_TKA_RESET) // reset - 0 balls
	{
		tkaballs = tkaballs_carry = tkaballs_dropped = 0;
		for (i = 0; i < team_count; ++i)
			tkaballs_taken[i] = 0;
	}

	// need to update the prevs regardless
	if (tkaballs_carry != tkaballs_carry_prev)
		tkaballs_carry_change_time = time;
	for (i = 0; i < team_count; ++i)
		if (tkaballs_taken[i] != tkaballs_taken_prev[i])
			tkaballs_taken_change_time[i] = time;
	return true;
}

#define TKA_TAKEN_PIC(team_i) \
	strcat("tka_taken_", Static_Team_ColorName_Lower(Team_IndexToTeam(team_i)))
void HUD_Mod_TKA_DrawItem_Multiple(vector itemPos, vector itemSize, float aspect_ratio, int i)
{
	float f;
	if (itemSize.x / itemSize.y > aspect_ratio)
	{
		f = itemSize.y * aspect_ratio;
		itemPos.x += (itemSize.x - f) * 0.5;
		itemSize.x = f;
	}
	else
	{
		f = itemSize.x / aspect_ratio;
		itemPos.y += (itemSize.y - f) * 0.5;
		itemSize.y = f;
	}

	itemSize.x *= 0.5;
	int d = team_count + 1;
	switch (i)
	{
		case 0:  HUD_Mod_Keepaway_DrawItem_Single(itemPos, itemSize, "keepawayball_carrying", tkaballs_carry_change_time,        tkaballs_carry,        true,  itos(tkaballs_carry));         break;
		case d:  HUD_Mod_Keepaway_DrawItem_Single(itemPos, itemSize, "notify_balldropped",    0,                                 tkaballs_dropped,      false, itos(tkaballs_dropped));       break;
		default: HUD_Mod_Keepaway_DrawItem_Single(itemPos, itemSize, TKA_TAKEN_PIC(i),        tkaballs_taken_change_time[i - 1], tkaballs_taken[i - 1], false, itos(tkaballs_taken[i - 1]));  break;
	}
}

void HUD_Mod_TKA(vector myPos, vector mySize, bool should_draw)
{
	int i;

	if (spectatee_status != spectatee_status_prev) // changed spec, update caches
	{
		for (i = 0; i < team_count; ++i)
			tkaballs_taken[i] = 0;
		for (i = 0; i < maxclients; ++i)
			if (playerslots[i])
				tkaballs_taken[Team_TeamToIndex(entcs_GetTeam(i)) - 1] += playerslots[i].gametype_status;
		tkaballs_carry = playerslots[player_currententnum - 1].gametype_status;
		tkaballs_taken[Team_TeamToIndex(entcs_GetTeam(player_currententnum - 1)) - 1] -= tkaballs_carry;
		spectatee_status_prev = spectatee_status;
	}

	if (!should_draw)
		return;

	mod_active = (tkaballs >= 1);
	if (autocvar__hud_configure && !mod_active) // we'll make up something, so the panel isn't empty
		mod_placeholder = mod_active = true;
	else if (!mod_active)
		return;
	else
		mod_placeholder = false;

	// Draw icons
	if (mod_placeholder || tkaballs == 1)
	{
		// TODO: unique team-based carrying icons
		HUD_Mod_Keepaway_DrawItem_Single(myPos, mySize, "keepawayball_carrying", tkaballs_carry_change_time, tkaballs_carry, true, "");
		HUD_Mod_Keepaway_DrawItem_Single(myPos, mySize, "notify_balldropped", 0, tkaballs_dropped, false, "");
		for (i = 0; i < team_count; ++i)
			HUD_Mod_Keepaway_DrawItem_Single(myPos, mySize, TKA_TAKEN_PIC(i + 1), tkaballs_taken_change_time[i], tkaballs_taken[i], false, "");
	}
	else // >1 balls
		HUD_Mod_TableWithAR_Draw(myPos, mySize, team_count + 2, 2, HUD_Mod_TKA_DrawItem_Multiple); // aspect ratio 2 (icon & text)
}
#undef TKA_TAKEN_PIC
