#include "sv_vampirehook.qh"

string autocvar_g_vampirehook;
REGISTER_MUTATOR(vh, expr_evaluate(autocvar_g_vampirehook));

bool autocvar_g_vampirehook_teamheal;
float autocvar_g_vampirehook_damage;
float autocvar_g_vampirehook_damagerate;
float autocvar_g_vampirehook_health_steal;

.float last_dmg;

MUTATOR_HOOKFUNCTION(vh, GrappleHookThink)
{
	entity thehook = M_ARGV(0, entity);

	entity dmgent = ((SAME_TEAM(thehook.owner, thehook.aiment) && autocvar_g_vampirehook_teamheal) ? thehook.owner : thehook.aiment);

	if(IS_PLAYER(thehook.aiment))
	if(thehook.last_dmg < time)
	if(!STAT(FROZEN, thehook.aiment))
	if(time >= game_starttime)
	if(DIFF_TEAM(thehook.owner, thehook.aiment) || autocvar_g_vampirehook_teamheal)
	if(GetResource(thehook.aiment, RES_HEALTH) > 0)
	if(autocvar_g_vampirehook_damage)
	{
		thehook.last_dmg = time + autocvar_g_vampirehook_damagerate;
		thehook.owner.hitsound_damage_dealt += autocvar_g_vampirehook_damage;
		Damage(dmgent, thehook, thehook.owner, autocvar_g_vampirehook_damage, WEP_HOOK.m_id, DMG_NOWEP, thehook.origin, '0 0 0');
		entity targ = ((SAME_TEAM(thehook.owner, thehook.aiment)) ? thehook.aiment : thehook.owner);
		// TODO: we can't do this due to an issue with globals and the mutator arguments
		//Heal(targ, thehook.owner, autocvar_g_vampirehook_health_steal, g_pickup_healthsmall_max);
		SetResourceExplicit(targ, RES_HEALTH, min(GetResource(targ, RES_HEALTH) + autocvar_g_vampirehook_health_steal, g_pickup_healthsmall_max));

		if(dmgent == thehook.owner)
			TakeResource(dmgent, RES_HEALTH, autocvar_g_vampirehook_damage); // FIXME: friendly fire?!
	}
}
