#include "cl_offhand_blaster.qh"

REGISTER_MUTATOR(cl_offhand_blaster, true);

MUTATOR_HOOKFUNCTION(cl_offhand_blaster, BuildGameplayTipsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string),
		"\n\n", _("^3offhand blaster^8 is enabled, press 'e' (+hook) to use it"), "\n");
}
