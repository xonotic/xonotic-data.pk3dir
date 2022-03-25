#include "cl_hook.qh"

#ifdef CSQC
REGISTER_MUTATOR(cl_hook, true);

MUTATOR_HOOKFUNCTION(cl_hook, BuildGameplayTipsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string),
		"\n\n", _("^3grappling hook^8 is enabled, press 'e' (+hook) to use it"), "\n");
}

#endif
