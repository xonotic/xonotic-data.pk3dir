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
		if(sk.(scores(ps_primary)) >= 666)
		{
			InfoMessage(_("^1Match has already begun"));
			M_ARGV(0, vector) = pos;
			M_ARGV(2, int) = img_curr_group;
			return true;
		}
		else if(sk.(scores(ps_primary)) > 0)
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
	int stat = STAT(REDALIVE); // number of leaders
	if(!stat)
	{
		mod_active = 0;
		return;
	}

	string pic = "player_neutral";
	vector color = '1 1 1';

	drawpic_aspect_skin(myPos, pic, vec2(0.5 * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(myPos + eX * 0.5 * mySize.x, ftos(stat), vec2(0.5 * mySize.x, mySize.y), color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_Mod_LMS(vector myPos, vector mySize)
{
	mod_active = 1;

	HUD_Mod_LMS_Draw(myPos, mySize);
}
