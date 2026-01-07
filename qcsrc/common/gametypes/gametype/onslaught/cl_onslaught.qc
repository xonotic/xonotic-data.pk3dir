#include "cl_onslaught.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

void HUD_Mod_Ons_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_ons_layout");
}

// Links is used for the two-team bar, ons_points is drawn as text, ons_gen_team_mask determines text color
float ons_links[NUM_TEAMS + 1]; ///< Ons controlpoint/generator half-links of each team, index 0 = red, etc., NUM_TEAMS = total
float ons_links_cache[NUM_TEAMS]; ///< Cache of ons_links for each team
int ons_gen_team_mask[NUM_TEAM_WORDS]; ///< Bitmask of which teams still have remaining generators, contains NUM_TEAMS bits
int ons_points[NUM_TEAMS]; ///< Ons owned controlpoints + generators by each team, index 0 = red, etc.
float ons_points_change_time[NUM_TEAMS]; ///< Time when ons_points[...] last changed

NET_HANDLE(ENT_CLIENT_ONS_STATUSES, bool isNew)
{
	int sf = ReadByte();

	if (sf & SF_ONS_COUNTS) // receive controlpoint + generator counts
		for (int prev, i = 0; i < NUM_TEAMS; ++i)
		{
			prev = ons_points[i];
			ons_points[i] = ReadShort();
			if (ons_points[i] != prev)
				ons_points_change_time[i] = time;
		}
	if (sf & SF_ONS_GEN_MASK) // receive gen bitmask
		for (int shift, w, word_i = 0, byte_i = 0; byte_i < NUM_TEAM_BYTES; ++word_i)
		{
			w = 0; // combine 3 bytes into 1 int
			for (shift = 0; byte_i < NUM_TEAM_BYTES && shift < 24; shift += 8, ++byte_i)
				w |= ReadByte() << shift;
			ons_gen_team_mask[word_i] = w;
		}
	return true;
}

/// Called via networking when g_radarlinks changes, to update caches used by the ons modicons HUD
void HUD_Mod_Ons_UpdateLinks()
{
	// FIXME: team_count can be setup after NET_HANDLEs run, so may be uninitiliazed in them
	//if (team_count != 2) // information is only needed if we can draw the two-team bar
	//	return;

	int team_i, goal_team_i, enemy_team_i;
	for (team_i = 0; team_i <= NUM_TEAMS; ++team_i)
		ons_links[team_i] = 0;
	IL_EACH(g_radarlinks, true,
	{
		++ons_links[NUM_TEAMS];
		if (!it.team)
			continue;
		goal_team_i   = Team_TeamToIndex(it.team & BITS(4));
		enemy_team_i  = Team_TeamToIndex(it.team >> 4);
		if (goal_team_i  > 0)
			ons_links[goal_team_i  - 1] += 0.5;
		if (enemy_team_i > 0)
			ons_links[enemy_team_i - 1] += 0.5;
	});
}

bool autocvar_hud_panel_modicons_ons_layout = true;

void HUD_Mod_Ons_DrawTwoTeamBar(vector itemPos, vector itemSize, int team_i, bool fade_in, bool vertical)
{
	float val = ons_links_cache[team_i];
	if (!val)
		return;

	vector col = Team_ColorRGB(Team_IndexToTeam(team_i + 1));
	vector diff = (vertical ? eX * itemSize.x : eY * itemSize.y);
	float alpha = ((fade_in ^ !autocvar_hud_panel_modicons_ons_layout) ? 0 : panel_fg_alpha * 0.8);
	R_BeginPolygon("", DRAWFLAG_NORMAL, true);
	R_PolygonVertex(itemPos,        '0 0 0', col, alpha);
	R_PolygonVertex(itemPos + diff, '0 0 0', col, alpha);
	if (vertical)
		itemPos.y += itemSize.y * val / ons_links[NUM_TEAMS];
	else
		itemPos.x += itemSize.x * val / ons_links[NUM_TEAMS];
	alpha = (panel_fg_alpha * 0.8) - alpha;
	R_PolygonVertex(itemPos + diff, '0 0 0', col, alpha);
	R_PolygonVertex(itemPos,        '0 0 0', col, alpha);
	R_EndPolygon();
}

void HUD_Mod_Ons_DrawItem(vector itemPos, vector itemSize, float aspect_ratio, int i)
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

	string text = itos(ons_points[i]);
	vector color = Team_ColorRGB(Team_IndexToTeam(i + 1));
	if (!(ons_gen_team_mask[i / 24] & BIT(i % 24))) // this team has no generators left
		color *= 0.5;

	f = bound(0, (time - ons_points_change_time[i]) * 2, 1);
	if (f < 1)
		drawstring_aspect_expanding(itemPos, text, itemSize, color, panel_fg_alpha, DRAWFLAG_NORMAL, f);
	drawstring_aspect(itemPos, text, itemSize, color, panel_fg_alpha * f, DRAWFLAG_NORMAL);
}

void HUD_Mod_Ons(vector myPos, vector mySize, bool should_draw)
{
	// update caches
	for (int i = 0; i < NUM_TEAMS; ++i)
		if (ons_links_cache[i] != ons_links[i])
			ons_links_cache[i] = HUD_Mod_SmoothlyUpdateCachedValue(ons_links_cache[i], ons_links[i], 0.01);

	if (!should_draw)
		return;

	mod_active = true; // required in each mod function that always shows something

	if (team_count == 2)
	{
		// draw the text in squares at the ends of the panel
		bool vertical = (mySize.y > mySize.x);
		vector itemPos = myPos;
		vector itemSize = (vertical)
			? vec2(mySize.x, min(mySize.x, mySize.y * 0.5))
			: vec2(min(mySize.x * 0.5, mySize.y), mySize.y);

		HUD_Mod_Ons_DrawItem(itemPos, itemSize, 1, 0);
		if (vertical)
			itemPos.y += mySize.y - itemSize.y;
		else
			itemPos.x += mySize.x - itemSize.x;
		HUD_Mod_Ons_DrawItem(itemPos, itemSize, 1, 1);

		if (vertical ? mySize.y < mySize.x * 2.5 : mySize.x < mySize.y * 2.5)
			return; // require at least 1:2.5 or 2.5:1 to draw the two-team bar
		if (ons_links[NUM_TEAMS] <= 0)
			return;

		// two-team bar draws in the remaining space, taking up half the height (width if vertical)
		if (vertical)
		{
			myPos.y  += itemSize.y;
			mySize.y -= itemSize.y * 2;
			myPos.x  += mySize.x * 0.25;
			mySize.x *= 0.5;
		}
		else
		{
			myPos.x  += itemSize.x;
			mySize.x -= itemSize.x * 2;
			myPos.y  += mySize.y * 0.25;
			mySize.y *= 0.5;
		}

		drawfill(myPos, mySize, '1 1 1', panel_fg_alpha * (1 - 0.8), DRAWFLAG_NORMAL);
		HUD_Mod_Ons_DrawTwoTeamBar(myPos, mySize, 0, false, vertical);
		if (ons_links_cache[1] <= 0)
			return;
		if (vertical)
			myPos.y += mySize.y * (1 - ons_links_cache[1] / ons_links[NUM_TEAMS]);
		else
			myPos.x += mySize.x * (1 - ons_links_cache[1] / ons_links[NUM_TEAMS]);
		HUD_Mod_Ons_DrawTwoTeamBar(myPos, mySize, 1, true,  vertical);
	}
	else // text only
		HUD_Mod_TableWithAR_Draw(myPos, mySize, team_count, 1, HUD_Mod_Ons_DrawItem);
}
