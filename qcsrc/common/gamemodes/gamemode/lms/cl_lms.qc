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
