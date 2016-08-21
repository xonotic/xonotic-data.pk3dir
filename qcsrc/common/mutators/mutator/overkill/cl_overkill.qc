#include "cl_overkill.qh"

REGISTER_MUTATOR(ok, false)
{
	MUTATOR_ONADD {
		cvar_settemp("g_overkill", "1");
		WEP_SHOTGUN.mdl = "ok_shotgun";
		WEP_MACHINEGUN.mdl = "ok_mg";
		WEP_VORTEX.mdl = "ok_sniper";
	}
}
