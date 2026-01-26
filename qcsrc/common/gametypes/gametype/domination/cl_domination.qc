#include "cl_domination.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

void HUD_Mod_Dom_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_dom_layout");
}

float dom_pps_total; ///< Total pps (points per second), all controlpoints combined
float dom_pps[NUM_TEAMS]; ///< pps (points per second) for each team
float dom_pps_ratio_cache[NUM_TEAMS]; ///< Cache of pps_ratio for each team

NET_HANDLE(ENT_CLIENT_DOM_PPSSTATUSES, bool isNew)
{
	// receive pps statuses
	dom_pps_total = ReadFloat();
	for (int i = 0; i < NUM_TEAMS; ++i)
		if (autocvar__teams_available & BIT(i))
			dom_pps[i] = (dom_pps_total ? ReadFloat() : 0);
	return true;
}

int autocvar_hud_panel_modicons_dom_layout;

void HUD_Mod_Dom_DrawItem(vector itemPos, vector itemSize, float aspect_ratio, int i)
{
	int tm = Team_IndexToTeam(i + 1);

	if (autocvar_hud_panel_modicons_dom_layout) // show text too
	{
		float f; // this code is only required if drawing text
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

		vector textSize = vec2(itemSize.x * ((aspect_ratio - 1) / aspect_ratio), itemSize.y);
		itemSize.x /= aspect_ratio;

		float pps = dom_pps[i];
		float pps_ratio = (dom_pps_total)
			? pps / dom_pps_total
			: 0;
		vector color = Team_ColorRGB(tm) * (0.5 + dom_pps_ratio_cache[i] * (1 - 0.5)); // half saturated color at min, full saturated at max
		string s = (autocvar_hud_panel_modicons_dom_layout == 2)
			? ftos_decimals(pps, 2) // average pps
			: ftos_decimals_percentage(pps_ratio, 0); // percentage of average pps
		drawstring_aspect(itemPos + eX * itemSize.x, s, textSize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	// draw the icon
	string pic = strcat("dom_icon_", Static_Team_ColorName_Lower(tm));
	if (dom_pps_ratio_cache[i] < 1 || tm == entcs_GetTeam(player_currententnum - 1)) // background image
		drawpic_aspect_skin(itemPos, pic, itemSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (dom_pps_ratio_cache[i] > 0) // colored image
	{
		float alpha = (autocvar_hud_panel_modicons_animations && tm == entcs_GetTeam(player_currententnum - 1))
			? blink(0.85, 0.15, 5) // make our teams blink
			: 1;
		drawsetcliparea(itemPos.x, itemPos.y + itemSize.y * (1 - dom_pps_ratio_cache[i]), itemSize.x, itemSize.y * dom_pps_ratio_cache[i]);
		drawpic_aspect_skin(itemPos, strcat(pic, "-highlighted"), itemSize, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL);
		drawresetcliparea();
	}
}

void HUD_Mod_Dom(vector myPos, vector mySize, bool should_draw)
{
	// update caches
	for (int pps_ratio, i = 0; i < NUM_TEAMS; ++i)
	{
		pps_ratio = (dom_pps_total ? dom_pps[i] / dom_pps_total : 0);
		if (dom_pps_ratio_cache[i] != pps_ratio)
			dom_pps_ratio_cache[i] = HUD_Mod_SmoothlyUpdateCachedValue(dom_pps_ratio_cache[i], pps_ratio, 0.001);
	}

	if (!should_draw)
		return;

	mod_active = true; // required in each mod function that always shows something

	HUD_Mod_TableWithAR_Draw(myPos, mySize, team_count, (autocvar_hud_panel_modicons_dom_layout ? 3 : 1), HUD_Mod_Dom_DrawItem);
}
