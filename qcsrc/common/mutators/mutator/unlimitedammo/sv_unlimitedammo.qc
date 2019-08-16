#include "sv_unlimitedammo.qh"

bool autocvar_g_unlimitedammo;

REGISTER_MUTATOR(unlimitedammo, cvar("g_unlimitedammo"));

MUTATOR_HOOKFUNCTION(unlimitedammo, SetStartItems)
{
	if (autocvar_g_unlimitedammo) {
		start_items |= IT_UNLIMITED_AMMO;
	}
}