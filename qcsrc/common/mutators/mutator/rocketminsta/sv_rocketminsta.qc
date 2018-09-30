#include "sv_rocketminsta.qh"

#include <common/deathtypes/all.qh>
#include <server/round_handler.qh>

REGISTER_MUTATOR(rm, autocvar_g_instagib);

MUTATOR_HOOKFUNCTION(rm, Damage_Calculate)
{
	// we do it this way, so rm can be toggled during the match
	if(!autocvar_g_rm) { return; }

	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);

	if(DEATH_ISWEAPON(frag_deathtype, WEP_DEVASTATOR))
	if(frag_attacker == frag_target || frag_target.classname == "nade")
		frag_damage = 0;

	if(autocvar_g_rm_laser)
	if(DEATH_ISWEAPON(frag_deathtype, WEP_ELECTRO))
	if(frag_attacker == frag_target || (round_handler_IsActive() && !round_handler_IsRoundStarted()))
		frag_damage = 0;

	M_ARGV(4, float) = frag_damage;
}

MUTATOR_HOOKFUNCTION(rm, PlayerDies)
{
	// we do it this way, so rm can be toggled during the match
	if(!autocvar_g_rm) { return; }

	float frag_deathtype = M_ARGV(3, float);

	if(DEATH_ISWEAPON(frag_deathtype, WEP_DEVASTATOR) || DEATH_ISWEAPON(frag_deathtype, WEP_ELECTRO))
		M_ARGV(4, float) = 1000; // always gib if it was a vaporizer death
}
