#include "cl_invasion.qh"

#include <common/mutators/base.qh>

REGISTER_MUTATOR(cl_inv, true);

MUTATOR_HOOKFUNCTION(cl_inv, DrawScoreboardItemStats)
{
	return ISGAMETYPE(INVASION); // hide the item stats panel
}

void HUD_Mod_Invasion_Draw(vector myPos, vector mySize)
{
	int monster_count = STAT(MONSTERS_TOTAL) - STAT(MONSTERS_KILLED);
	if(monster_count <= 0)
	{
		mod_active = 0;
		return;
	}

	int rows, columns;
	float aspect_ratio = 1;
	rows = HUD_GetRowCount(1, mySize, aspect_ratio);
	columns = ceil(1 / rows);

	vector pos = myPos;
	vector itemSize = vec2(mySize.x / columns, mySize.y / rows);

	// TODO: unique icon for monsters
	drawpic_aspect_skin(pos, "notify_death", vec2(0.5 * itemSize.x, itemSize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(pos + eX * 0.5 * itemSize.x, ftos(monster_count), vec2(0.5 * itemSize.x, itemSize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_Mod_Invasion(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	mod_active = 1;

	HUD_Mod_Invasion_Draw(myPos, mySize);
}
