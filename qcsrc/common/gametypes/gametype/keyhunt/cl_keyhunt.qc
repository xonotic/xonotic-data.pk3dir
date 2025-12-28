#include "cl_keyhunt.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

.int kh_status[NUM_TEAM_WORDS]; ///< Bitmask of NUM_TEAMS bits, of which teams' keys the player is carrying

int keys, keys_carrying;
int keys_our_team; ///< Number of keys held by our team
int kh_key_owner[NUM_TEAMS]; ///< Unordered key owners (playerslots index, or -1 if dropped)

// Icons in the order they're drawn (by teams, carrying before taken, dropped last)
int kh_icon_team[NUM_TEAMS]; ///< Team index of the icon, red is 0, etc., -1 if dropped
int kh_icon_owner[NUM_TEAMS]; ///< playerslots index of the key's owner, -1 if dropped
int kh_carrying_start_idx; ///< Icon index the key carrying icons start at
float kh_carrying_change_time[NUM_TEAMS]; ///< Time when keys_carrying last changed, per key. E.g., kh_carrying_change_time[2] is the last time we gained/lost a 3rd key

void HUD_Mod_KH_UpdateIcons(bool update_change_time);

NET_HANDLE(ENT_CLIENT_KH_KEYSTATUSES, bool isNew)
{
	int word_i, i, sf = ReadByte();

	// reset first
	for (i = 0; i < maxclients; ++i)
		if (playerslots[i])
			for (word_i = 0; word_i < NUM_TEAM_WORDS; ++word_i)
				playerslots[i].kh_status[word_i] = 0;

	if (sf & SF_KH_KEYS) // receive key statuses
	{
		keys = ReadByte(); // NOTE: should always be == team_count, but that updates late (FIXME)
		int key_owner, key_team;
		for (i = 0; i < keys; ++i)
		{
			key_owner = ReadByte();
			if (key_owner)
			{
				key_team = ReadByte(); // red is 0, etc.
				--key_owner;
				if (!playerslots[key_owner])
					playerslots[key_owner] = new_pure(playerslot);
				playerslots[key_owner].kh_status[key_team / 24] |= BIT(key_team % 24);
			}
			else
				key_owner = -1; // dropped
			kh_key_owner[i] = key_owner;
		}
	}
	else if (sf & SF_KH_RESET)
		keys = 0;

	HUD_Mod_KH_UpdateIcons(true);
	return true;
}

/// Builds the ordered icon arrays from kh_key_owner
void HUD_Mod_KH_UpdateIcons(bool update_change_time)
{
	int keys_carrying_prev = keys_carrying;
	keys_carrying = keys_our_team = 0;

	int me = player_currententnum - 1;
	int our_team = Team_TeamToIndex(entcs_GetTeam(me)) - 1;
	int k, idx = 0;
	for (int owner, team_i = 0; team_i < team_count; ++team_i)
	{
		if (team_i == our_team)
			kh_carrying_start_idx = idx;
		for (k = 0; k < keys; ++k) // add carrying icons
		{
			owner = kh_key_owner[k];
			if (owner == me && team_i == our_team)
			{
				kh_icon_team[idx] = team_i;
				kh_icon_owner[idx] = owner;
				++idx;
				++keys_carrying;
				++keys_our_team;
			}
		}
		for (k = 0; k < keys; ++k) // add taken icons
		{
			owner = kh_key_owner[k];
			if (owner >= 0 && owner != me && Team_TeamToIndex(entcs_GetTeam(owner)) - 1 == team_i)
			{
				kh_icon_team[idx] = team_i;
				kh_icon_owner[idx] = owner;
				++idx;
				if (team_i == our_team)
					++keys_our_team;
			}
		}
	}
	for (k = 0; k < keys; ++k) // add dropped keys last
		if (kh_key_owner[k] < 0)
		{
			kh_icon_team[idx] = -1;
			kh_icon_owner[idx] = -1;
			++idx;
		}

	if (update_change_time)
	{
		if (keys_carrying > keys_carrying_prev)
			for (k = keys_carrying_prev; k < keys_carrying; ++k)
				kh_carrying_change_time[k] = time;
		else if (keys_carrying < keys_carrying_prev)
			for (k = keys_carrying_prev - 1; k >= keys_carrying; --k)
				kh_carrying_change_time[k] = time;
	}
	else // reset change_time since we switched spectator
		for (k = 0; k < team_count; ++k)
			kh_carrying_change_time[k] = 0;
}

string HUD_Mod_KH_GetPic(int team_i, bool carrying)
{
	if (team_i < 0) // used to signal we're drawing dropped keys
		return "kh_dropped";
	return strcat("kh_", Static_Team_ColorName_Lower(Team_IndexToTeam(team_i + 1)), (carrying ? "_carrying" : "_taken"));
}

void HUD_Mod_KH_DrawItem(vector itemPos, vector itemSize, float alpha, int i, int owner, int team_i, int our_team)
{
	float f;
	if (!mod_placeholder && i >= 0)
	{
		// try to draw expanding icon for our team in this slot
		// we need this code since the expanding icon is drawn also after we lose a key
		f = bound(0, (time - kh_carrying_change_time[i]) * 2, 1);
		if (f < 1)
			drawpic_aspect_skin_expanding(itemPos, HUD_Mod_KH_GetPic(our_team, true), itemSize, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL, f);
	}
	else
		f = 1;

	bool carrying = (owner >= 0 && owner == player_currententnum - 1);
	if (!carrying)
		f = 1;
	drawpic_aspect_skin(itemPos, HUD_Mod_KH_GetPic(team_i, carrying), itemSize, '1 1 1', panel_fg_alpha * alpha * f, DRAWFLAG_NORMAL);
}

void HUD_Mod_KH(vector myPos, vector mySize, bool should_draw)
{
	if (spectatee_status != spectatee_status_prev) // changed spec, update caches
	{
		HUD_Mod_KH_UpdateIcons(false);
		spectatee_status_prev = spectatee_status;
	}

	if (!should_draw)
		return;

	int i;
	mod_active = keys;
	if (!mod_active)
		for (i = 0; i < team_count; ++i)
			if ((time - kh_carrying_change_time[i]) * 2 < 1)
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
	float alpha = (keys_carrying && keys_our_team == keys)
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
	int team_i, owner, row = 0;
	for (i = 0; i < team_count; ++i)
	{
		if (mod_placeholder)
		{
			team_i = (i == 1) ? -1 : i; // each team has one key, except 2nd team (instead dropped)
			owner = -1;
		}
		else
		{
			team_i = kh_icon_team[i];
			owner = kh_icon_owner[i];
		}

		HUD_Mod_KH_DrawItem(itemPos, itemSize, alpha, i - kh_carrying_start_idx, owner, team_i, our_team);

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
	}
}

REGISTER_MUTATOR(cl_kh, true);

MUTATOR_HOOKFUNCTION(cl_kh, ResetPlayerGametypeFields)
{
	entity player = M_ARGV(0, entity);
	for (int word_i = 0; word_i < NUM_TEAM_WORDS; ++word_i)
		player.kh_status[word_i] = 0;
}
