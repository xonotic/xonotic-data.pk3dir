#include "cl_hook.qh"

#ifdef CSQC
REGISTER_MUTATOR(cl_hook, true);

MUTATOR_HOOKFUNCTION(cl_hook, BuildGameplayTipsString)
{
	if (mut_is_active(MUT_GRAPPLING_HOOK))
	{
		string key = getcommandkey(_("offhand hook"), "+hook");
		M_ARGV(0, string) = strcat(M_ARGV(0, string),
			"\n", sprintf(_("^3grappling hook^8 is enabled, press ^3%s^8 to use it"), key), "\n");
	}
}

#endif
