#include "sv_running_guns.qh"

bool autocvar_g_running_guns;
REGISTER_MUTATOR(running_guns, autocvar_g_running_guns);

MUTATOR_HOOKFUNCTION(running_guns, SetDefaultAlpha)
{
	default_player_alpha = -1;
	default_weapon_alpha = +1;
	return true;
}
