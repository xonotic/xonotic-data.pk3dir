#include "cl_invasion.qh"

#include <common/mutators/base.qh>

REGISTER_MUTATOR(cl_inv, true);

MUTATOR_HOOKFUNCTION(cl_inv, DrawScoreboardItemStats)
{
	return ISGAMETYPE(INVASION); // hide the item stats panel
}
