#include "cl_overkill.qh"

REGISTER_MUTATOR(ok, false)
{
	MUTATOR_ONADD {
		cvar_settemp("g_overkill", "1");
	}
}
