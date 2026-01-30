#include "cl_keyhunt.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

int keys, keys_dropped, keys_carrying;
int team_keys[NUM_TEAMS]; ///< Number of keys each team is holding, not including keys_carrying

float keys_carrying_change_time[NUM_TEAMS]; ///< Time when keys_carrying last changed, per key. E.g. keys_carrying_change_time[2] is the last time we gained/lost a 3rd key

NET_HANDLE(ENT_CLIENT_KH_KEYSTATUSES, bool isNew)
{
	int i, sf = ReadByte();
	int keys_carrying_prev = keys_carrying;

	// reset first
	for (i = 0; i < maxclients; ++i)
		if (playerslots[i])
			playerslots[i].gametype_status = 0;
	keys_carrying = 0;
	keys_dropped = 0;
	for (i = 0; i < NUM_TEAMS; ++i)
		team_keys[i] = 0;

	if (sf & SF_KH_KEYS) // receive key statuses
	{
		keys = ReadByte(); // FIXME: should always be == team_count, but that updates late
		int key_owner;
		for (i = 0; i < keys; ++i)
		{
			key_owner = ReadByte();
			if (key_owner)
			{
				--key_owner;
				if (!playerslots[key_owner])
					playerslots[key_owner] = new_pure(playerslot);
				playerslots[key_owner].gametype_status |= BIT(ReadByte()); // red: 0 -> BIT(0), etc.
				if (key_owner == player_currententnum - 1)
					++keys_carrying; // this would be faster with popcount
				else
					++team_keys[Team_TeamToIndex(entcs_GetTeam(key_owner)) - 1];
			}
			else
				++keys_dropped;
		}
	}
	else if (sf & SF_KH_RESET)
		keys = 0;

	// need to update the prevs regardless
	if (keys_carrying > keys_carrying_prev)
		for (i = keys_carrying_prev; i < keys_carrying; ++i)
			keys_carrying_change_time[i] = time;
	else if (keys_carrying < keys_carrying_prev)
		for (i = keys_carrying_prev - 1; i >= keys_carrying; --i)
			keys_carrying_change_time[i] = time;
	return true;
}

string HUD_Mod_KH_GetPic(int team_i, bool carrying)
{
	if (team_i == team_count) // used to signal we're drawing dropped keys
		return "kh_dropped";
	return strcat("kh_", Static_Team_ColorName_Lower(Team_IndexToTeam(team_i + 1)), (carrying ? "_carrying" : "_taken"));
}

void HUD_Mod_KH_DrawItem(vector itemPos, vector itemSize, float alpha, int carrying_i, int team_i)
{
	float f;
	if (!mod_placeholder && autocvar_hud_panel_modicons_animations && carrying_i >= 0)
	{
		// try to draw expanding icon for our team in this slot
		// we need this code since the expanding icon is drawn also after we lose a key
		f = bound(0, (time - keys_carrying_change_time[carrying_i]) * 2, 1);
		if (f < 1)
			drawpic_aspect_skin_expanding(itemPos, HUD_Mod_KH_GetPic(Team_TeamToIndex(entcs_GetTeam(player_currententnum - 1)) - 1, true), itemSize, '1 1 1', alpha * panel_fg_alpha, DRAWFLAG_NORMAL, f);
	}
	else
		f = 1;

	bool carrying = (carrying_i >= 0 && carrying_i < keys_carrying);
	if (!carrying)
		f = 1;
	drawpic_aspect_skin(itemPos, HUD_Mod_KH_GetPic(team_i, carrying), itemSize, '1 1 1', alpha * panel_fg_alpha * f, DRAWFLAG_NORMAL);
}

void HUD_Mod_KH(vector myPos, vector mySize, bool should_draw)
{
	int i;

	if (spectatee_status != spectatee_status_prev) // changed spec, update caches
	{
		keys_carrying = 0;
		for (i = 0; i < keys; ++i)
			team_keys[i] = 0;
		int gt_status;
		for (i = 0; i < maxclients; ++i)
			if (playerslots[i])
				for (gt_status = playerslots[i].gametype_status; gt_status; gt_status >>= 1) // this would be faster with popcount
					if (gt_status & 1)
					{
						if (i == player_currententnum - 1)
							++keys_carrying;
						else
							++team_keys[Team_TeamToIndex(entcs_GetTeam(i)) - 1];
					}
		spectatee_status_prev = spectatee_status;
	}

	if (!should_draw)
		return;

	mod_active = keys;
	if (!mod_active)
		for (i = 0; i < team_count; ++i)
			if ((time - keys_carrying_change_time[i]) * 2 < 1)
			{
				mod_active = true;
				break;
			}

	if (autocvar__hud_configure && !mod_active) // we'll make up something, so the panel isn't empty
		mod_placeholder = mod_active = true;
	else if (!mod_active)
		return;
	else
		mod_placeholder = false;

	// Make icons blink in case of "RUN HERE" (if our team has them all, and we have at least 1)
	int our_team = Team_TeamToIndex(entcs_GetTeam(player_currententnum - 1)) - 1;
	float alpha = (autocvar_hud_panel_modicons_animations && keys_carrying && team_keys[our_team] + keys_carrying == keys)
		? blink(0.6, 0.4, 5) // oscillates between 0.2 and 1
		: 1;

	// Draw icons
	// KH code is more complicated than the other modicons HUDs, since:
	//   teams can have a variable number of icons
	//   we want only the last carrying icon to expand when you pick up 1 key
	//   expanding icons may need to change slots
	int rows = HUD_GetRowCount(team_count, mySize, 1); // aspect ratio 1
	int cols = ceil(team_count / rows);

	vector itemSize = vec2(mySize.x / cols, mySize.y / rows);
	vector itemPos  = myPos;
	i = 0;
	int carrying_i = -1;
	int row = 0;
	// Loop through each team and draw all keys they own, then loop an extra time (team_i == team_count) to draw dropped keys
	for (int i_end, team_i = 0; team_i <= team_count; ++team_i)
	{
		if (mod_placeholder)
			i_end = !(team_count > 1 && team_i == 1); // each team has 1 key, except 2nd team (instead dropped)
		else if (team_i == team_count)
			i_end = keys_dropped; // now just draw all the dropped keys
		else
		{
			i_end = team_keys[team_i];
			if (team_i == our_team)
			{
				carrying_i = 0; // we've reached our team, so the carrying icons start from here (if we're even carrying any)
				i_end += keys_carrying;
			}
		}
		for (i = 0; i < i_end; ++i) // draw all the keys for this team
		{
			HUD_Mod_KH_DrawItem(itemPos, itemSize, alpha, carrying_i, team_i);

			if (row == rows - 1)
			{
				row = 0;
				itemPos.y  = myPos.y;
				itemPos.x += itemSize.x;
			}
			else
			{
				++row;
				itemPos.y += itemSize.y;
			}
			if (carrying_i >= 0)
				++carrying_i;
		}
		if (carrying_i >= 0)
			carrying_i = -1;
	}
}
