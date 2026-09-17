#include "cl_freezetag.qh"

#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

void HUD_Mod_FT_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_ft_layout");
}

bool autocvar_hud_panel_modicons_ft_layout = true;

void HUD_Mod_FT(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	mod_active = true; // this mod function always draws something

	HUD_Mod_TableWithAR_Draw(myPos, mySize, team_count, (autocvar_hud_panel_modicons_ft_layout ? 2 : 1), HUD_Mod_EliminatedPlayers_DrawItem);
}


// Jagged icy-looking revival ring
float RevivalRingNoise(float seed)
{
#define REVIVAL_RING_RAND(x) (2 * fract(fabs(sin((x) * 127.1)) * 43758.5453) - 1) /* [-1, 1], numbers copied from GLSL */
	// Just using REVIVAL_RING_RAND(seed) makes it change too erratically, so instead smoothly change between outputs
	float i = floor(seed);
	float a = REVIVAL_RING_RAND(i);
	float b = REVIVAL_RING_RAND(i + 1);
#undef REVIVAL_RING_RAND
	return a + (b - a) * (seed - i);
}

int autocvar_cl_freezetag_dynamicring_segments = 24;
vector RevivalRingPointPos(vector pos, int i, float size, float seed, bool outer)
{
	float noise_ang = RevivalRingNoise((seed + outer) * 4.2069 + i * 13); // leet magic numbers
	float noise_rad = RevivalRingNoise((seed + outer) * 4.2069 + i * 37); //
	// Amplify extent of outer points going out and inner points going in
	if ((outer && noise_rad > 0)
	|| (!outer && noise_rad < 0))
	{
		noise_ang *= 1 + fabs(noise_rad); // up to max 2
		noise_rad *= 2;
	}

	float ang = (2 * M_PI / autocvar_cl_freezetag_dynamicring_segments) * (i + noise_ang / 4);
	float rad = size * (outer ? 1 : 0.75) * 0.36; // size * 0.36 roughly matches the ring icon above
	rad += noise_rad * (size * 0.04);
	pos.x += rad * cos(ang);
	pos.y += rad * sin(ang);
	return pos;
}
vector RevivalRingPointColor(int i, float progress, float seed, bool outer)
{
	vector col = '0.25 0.7 0.85';
	float noise_col = RevivalRingNoise((seed + outer) * 6.7 + i * 73); // magic numbers, as above
	col.y += noise_col * 0.25; // vary from medium to light blue
	col.z += noise_col * 0.1;  //
	float redness = progress * ((i / autocvar_cl_freezetag_dynamicring_segments) ** 3);
	col.x += redness * (0.8 - 0.25); // points closer to the end are redder,
	col.z -= redness * (0.85 - 0.4); // and become more red as revival progresses
	return col;
}

void DrawRevivalRing(vector pos, float size, string pic, float progress, vector color, float alpha, int drawflags)
{
	if (progress <= 0)
		return;
	if (autocvar_cl_freezetag_dynamicring_segments < 3)
	{
		DrawCircleClippedPic(pos, size, pic, progress, color, alpha, drawflags);
		return;
	}

	static float progress_seed = 0;
	static float last_called = 0;
	if (time > last_called + 1) // if this function hasn't been called for a second, change the seed
		progress_seed = time; // use time as the seed
	last_called = time;

	float points_f = progress * autocvar_cl_freezetag_dynamicring_segments;
	int points = ceil(points_f);
#define REVIVAL_RING_POINT_POS(i, outer) RevivalRingPointPos(pos, i, size, progress + progress_seed, outer)
#define REVIVAL_RING_POINT_COL(i, outer) RevivalRingPointColor(i, progress, progress + progress_seed, outer)
	// Have to draw as separate polygons since R_EndPolygon draws a triangle fan; we need a strip since rings are non-convex
	// Draw the complete segments
	int i = 0;
	vector outer = REVIVAL_RING_POINT_POS(i, true);
	vector inner = REVIVAL_RING_POINT_POS(i, false);
	vector outer_color = REVIVAL_RING_POINT_COL(i, true);
	vector inner_color = REVIVAL_RING_POINT_COL(i, false);
	while (i < points - 1)
	{
		R_BeginPolygon("", drawflags, true);
		R_PolygonVertex(outer, '0 0 0', outer_color, alpha);
		R_PolygonVertex(inner, '0 0 0', inner_color, alpha);
		++i;
		R_PolygonVertex(inner = REVIVAL_RING_POINT_POS(i, false), '0 0 0', inner_color = REVIVAL_RING_POINT_COL(i, false), alpha);
		R_PolygonVertex(outer = REVIVAL_RING_POINT_POS(i, true),  '0 0 0', outer_color = REVIVAL_RING_POINT_COL(i, true),  alpha);
		R_EndPolygon();
	}
	if (fabs(1 - (points - points_f)) < 0.001)
		return;

	// Draw partial segment
	float f = points - points_f;
	R_BeginPolygon("", drawflags, true);
	R_PolygonVertex(outer, '0 0 0', outer_color, alpha);
	R_PolygonVertex(inner, '0 0 0', inner_color, alpha);
	i = points % autocvar_cl_freezetag_dynamicring_segments;
	// 1-f percent from points-1 to points
	outer = outer * f + (1 - f) * REVIVAL_RING_POINT_POS(i, true);
	inner = inner * f + (1 - f) * REVIVAL_RING_POINT_POS(i, false);
	outer_color = outer_color * f + (1 - f) * REVIVAL_RING_POINT_COL(points, true);
	inner_color = inner_color * f + (1 - f) * REVIVAL_RING_POINT_COL(points, false);
	R_PolygonVertex(inner, '0 0 0', inner_color, alpha);
	R_PolygonVertex(outer, '0 0 0', outer_color, alpha);
	R_EndPolygon();
#undef REVIVAL_RING_POINT_POS
#undef REVIVAL_RING_POINT_COL
}


REGISTER_MUTATOR(cl_ft, true);

MUTATOR_HOOKFUNCTION(cl_ft, WantEventchase)
{
	if (autocvar_cl_eventchase_frozen && ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
		return true;
	return false;
}

MUTATOR_HOOKFUNCTION(cl_ft, HUD_Draw_overlay)
{
	if (ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
	{
		vector col = '0.25 0.90 1';
		float col_fade = max(0, STAT(REVIVE_PROGRESS) * 2 - 1);
		float alpha_fade = 0.3 + 0.7 * (1 - max(0, STAT(REVIVE_PROGRESS) * 4 - 3));
		if (col_fade)
			col += vec3(col_fade, -col_fade, -col_fade);

		M_ARGV(0, vector) = col;
		M_ARGV(1, float) = alpha_fade;
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(cl_ft, HUD_Damage_show)
{
	if (ISGAMETYPE(FREEZETAG) && STAT(FROZEN))
		return true;
	return false;
}
