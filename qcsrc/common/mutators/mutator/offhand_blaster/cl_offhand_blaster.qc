#include "cl_offhand_blaster.qh"

REGISTER_MUTATOR(cl_offhand_blaster, true);

MUTATOR_HOOKFUNCTION(cl_offhand_blaster, BuildGameplayTipsString)
{
	if (mut_is_active(MUT_OFFHAND_BLASTER))
	{
		string key = getcommandkey(_("offhand hook"), "+hook");
		M_ARGV(0, string) = strcat(M_ARGV(0, string),
			"\n", sprintf(_("^3offhand blaster^8 is enabled, press ^3%s^8 to use it"), key), "\n");
	}
}
