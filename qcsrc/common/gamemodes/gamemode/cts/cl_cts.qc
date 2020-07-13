#include "cl_cts.qh"

REGISTER_MUTATOR(cl_cts, true);

MUTATOR_HOOKFUNCTION(cl_cts, HUD_Physics_showoptional)
{
	return ISGAMETYPE(CTS); // show the optional physics panel
}
