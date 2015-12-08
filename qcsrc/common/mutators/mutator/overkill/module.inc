#include "hmg.qc"
#include "rpc.qc"

#ifdef SVQC
	#include "overkill.qc"
#endif
#ifdef CSQC
	#ifdef IMPLEMENTATION
		REGISTER_MUTATOR(ok, false)
		{
			MUTATOR_ONADD {
				cvar_settemp("g_overkill", "1");
				WEP_SHOTGUN.mdl = "ok_shotgun";
				WEP_MACHINEGUN.mdl = "ok_mg";
				WEP_VORTEX.mdl = "ok_sniper";
			}
		}
	#endif
#endif
