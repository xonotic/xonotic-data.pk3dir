#include "cl_offhand_blaster.qh"

REGISTER_MUTATOR(cl_offhand_blaster, true);

MUTATOR_HOOKFUNCTION(cl_offhand_blaster, BuildGameplayTipsString)
{
	string key = getcommandkey(_("off-hand hook"), "+hook");
	M_ARGV(0, string) = strcat(M_ARGV(0, string),
		"\n\n", sprintf(_("^3offhand blaster^8 is enabled, press ^3%s^8 to use it"), key), "\n");
}
