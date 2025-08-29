#include "cl_clanarena.qh"

#include <client/draw.qh>

#include <common/mutators/base.qh>

void HUD_Mod_CA_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_ca_layout");
}

REGISTER_MUTATOR(cl_ca, true);

MUTATOR_HOOKFUNCTION(cl_ca, DrawInfoMessages)
{
	return (ISGAMETYPE(CA) && entcs_GetSpecState(player_localnum) == ENTCS_SPEC_IN_SCOREBOARD);
}

void DrawCAItem(vector myPos, vector mySize, float aspect_ratio, int layout, int i)
{
	TC(int, layout); TC(int, i);
	int stat = -1;
	string pic = "";
	vector color = '0 0 0';
	switch(i)
	{
		case 0: stat = STAT(REDALIVE); pic = "player_red"; color = '1 0 0'; break;
		case 1: stat = STAT(BLUEALIVE); pic = "player_blue"; color = '0 0 1'; break;
		case 2: stat = STAT(YELLOWALIVE); pic = "player_yellow"; color = '1 1 0'; break;
		default:
		case 3: stat = STAT(PINKALIVE); pic = "player_pink"; color = '1 0 1'; break;
	}

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

	if(layout)
	{
		drawpic_aspect_skin(myPos, pic, vec2(0.5 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		drawstring_aspect(myPos + eX * 0.5 * mySize.x, ftos(stat), vec2(0.5 * mySize.x, mySize.y), color, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
	else
		drawstring_aspect(myPos, ftos(stat), mySize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_Mod_CA_Draw(vector myPos, vector mySize, int layout)
{
	int rows, columns;
	float aspect_ratio;
	aspect_ratio = (layout) ? 2 : 1;
	rows = HUD_GetRowCount(team_count, mySize, aspect_ratio);
	columns = ceil(team_count/rows);

	int i;
	float row = 0, column = 0;
	vector pos = '0 0 0', itemSize;
	itemSize = vec2(mySize.x / columns, mySize.y / rows);
	for(i=0; i<team_count; ++i)
	{
		pos.x = myPos.x + column * itemSize.x;
		pos.y = myPos.y + row * itemSize.y;

		DrawCAItem(pos, itemSize, aspect_ratio, layout, i);

		++row;
		if(row >= rows)
		{
			row = 0;
			++column;
		}
	}
}

// Clan Arena and Freeze Tag HUD modicons
void HUD_Mod_CA(vector myPos, vector mySize)
{
	mod_active = 1; // required in each mod function that always shows something

	HUD_Mod_CA_Draw(myPos, mySize, autocvar_hud_panel_modicons_ca_layout);
}
