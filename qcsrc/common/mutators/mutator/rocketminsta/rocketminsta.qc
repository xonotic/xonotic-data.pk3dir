#ifdef IMPLEMENTATION
#include "../../../deathtypes/all.qh"
#include "../../../../server/round_handler.qh"

REGISTER_MUTATOR(rm, cvar("g_instagib"));

MUTATOR_HOOKFUNCTION(rm, PlayerDamage_Calculate)
{
	// we do it this way, so rm can be toggled during the match
	if(!autocvar_g_rm) { return false; }

	if(DEATH_ISWEAPON(frag_deathtype, WEP_DEVASTATOR))
	if(frag_attacker == frag_target || frag_target.classname == "nade")
		frag_damage = 0;

	if(autocvar_g_rm_laser)
	if(DEATH_ISWEAPON(frag_deathtype, WEP_ELECTRO))
	if(frag_attacker == frag_target || (round_handler_IsActive() && !round_handler_IsRoundStarted()))
		frag_damage = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(rm, PlayerDies)
{
	// we do it this way, so rm can be toggled during the match
	if(!autocvar_g_rm) { return false; }

	if(DEATH_ISWEAPON(frag_deathtype, WEP_DEVASTATOR) || DEATH_ISWEAPON(frag_deathtype, WEP_ELECTRO))
		frag_damage = 1000; // always gib if it was a vaporizer death

	return false;
}

#endif
