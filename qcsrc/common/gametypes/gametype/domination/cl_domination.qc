#include "cl_domination.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

void HUD_Mod_Dom_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_dom_layout");
}

int autocvar_hud_panel_modicons_dom_layout;

void DrawDomItem(vector myPos, vector mySize, float aspect_ratio, int layout, int i)
{
	TC(int, layout); TC(int, i);
	float stat = -1;
	string pic = "";
	vector color = '0 0 0';
	switch(i)
	{
		case 0: stat = STAT(DOM_PPS_RED); pic = "dom_icon_red"; color = '1 0 0'; break;
		case 1: stat = STAT(DOM_PPS_BLUE); pic = "dom_icon_blue"; color = '0 0 1'; break;
		case 2: stat = STAT(DOM_PPS_YELLOW); pic = "dom_icon_yellow"; color = '1 1 0'; break;
		default:
		case 3: stat = STAT(DOM_PPS_PINK); pic = "dom_icon_pink"; color = '1 0 1'; break;
	}
	float pps_ratio = 0;
	if(STAT(DOM_TOTAL_PPS))
		pps_ratio = stat / STAT(DOM_TOTAL_PPS);

	if(mySize.x/mySize.y > aspect_ratio)
	{
		i = aspect_ratio * mySize.y;
		myPos.x = myPos.x + (mySize.x - i) / 2;
		mySize.x = i;
	}
	else
	{
		i = 1/aspect_ratio * mySize.x;
		myPos.y = myPos.y + (mySize.y - i) / 2;
		mySize.y = i;
	}

	if (layout) // show text too
	{
		//draw the text
		color *= 0.5 + pps_ratio * (1 - 0.5); // half saturated color at min, full saturated at max
		if (layout == 2) // average pps
			drawstring_aspect(myPos + eX * mySize.y, ftos_decimals(stat, 2), vec2((2/3) * mySize.x, mySize.y), color, panel_fg_alpha, DRAWFLAG_NORMAL);
		else // percentage of average pps
			drawstring_aspect(myPos + eX * mySize.y, strcat( ftos(floor(pps_ratio*100 + 0.5)), "%" ), vec2((2/3) * mySize.x, mySize.y), color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	//draw the icon
	drawpic_aspect_skin(myPos, pic, '1 1 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	if (stat > 0)
	{
		drawsetcliparea(myPos.x, myPos.y + mySize.y * (1 - pps_ratio), mySize.y, mySize.y * pps_ratio);
		drawpic_aspect_skin(myPos, strcat(pic, "-highlighted"), '1 1 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawresetcliparea();
	}
}

void HUD_Mod_Dom(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	int layout = autocvar_hud_panel_modicons_dom_layout;
	int rows, columns;
	float aspect_ratio;
	aspect_ratio = (layout) ? 3 : 1;
	rows = HUD_GetRowCount(team_count, mySize, aspect_ratio);
	columns = ceil(team_count/rows);

	int i;
	float row = 0, column = 0;
	vector pos, itemSize;
	itemSize = vec2(mySize.x / columns, mySize.y / rows);
	for(i=0; i<team_count; ++i)
	{
		pos = myPos + vec2(column * itemSize.x, row * itemSize.y);

		DrawDomItem(pos, itemSize, aspect_ratio, layout, i);

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}
}
