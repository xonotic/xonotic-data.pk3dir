#include "cl_lms.qh"

#include <common/mutators/base.qh>

REGISTER_MUTATOR(cl_lms, true);

MUTATOR_HOOKFUNCTION(cl_lms, DrawInfoMessages)
{
	if(!warmup_stage && ISGAMETYPE(LMS))
	{
		entity sk = playerslots[player_localnum];
		vector pos = M_ARGV(0, vector);
		vector mySize = M_ARGV(1, vector);
		vector fontsize = '0.2 0.2 0' * mySize.y;
		int img_curr_group = M_ARGV(2, int);
		if(sk.(scores(ps_primary)) > 0)
		{
			InfoMessage(_("^1You have no more lives left"));
			M_ARGV(0, vector) = pos;
			M_ARGV(2, int) = img_curr_group;
			return true;
		}
	}
	return false;
}

void HUD_Mod_LMS_Draw(vector myPos, vector mySize)
{
	int leaders_count = STAT(REDALIVE); // recycled stat
	if(!leaders_count)
	{
		mod_active = 0;
		return;
	}

	int rows, columns;
	float aspect_ratio = 2;
	rows = HUD_GetRowCount(2, mySize, aspect_ratio);
	columns = ceil(2 / rows);

	vector pos = myPos;
	vector itemSize = vec2(mySize.x / columns, mySize.y / rows);

	bool visible_leaders = STAT(OBJECTIVE_STATUS);

	if (visible_leaders)
		drawpic_aspect_skin(pos, "flag_stalemate", vec2(0.5 * itemSize.x, itemSize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(pos, "player_neutral", vec2(0.5 * itemSize.x, itemSize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(pos + eX * 0.5 * itemSize.x, ftos(leaders_count), vec2(0.5 * itemSize.x, itemSize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

	if (rows > 1)
		pos.y = myPos.y + itemSize.y;
	else
		pos.x = myPos.x + itemSize.x;

	int lives_diff = STAT(BLUEALIVE); // recycled stat
	vector color = '1 1 0';
	if (lives_diff >= 4)
		color = '1 0 0';
	else if (lives_diff == 3)
		color = '1 0.5 0';
	float scale = 0.75;
	drawstring_aspect(pos + itemSize * (1 - scale) * 0.5, strcat("+", ftos(lives_diff)), itemSize * scale, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_Mod_LMS(vector myPos, vector mySize)
{
	mod_active = 1;

	HUD_Mod_LMS_Draw(myPos, mySize);
}
