#include "sv_vampirehook.qh"

REGISTER_MUTATOR(vh, cvar("g_vampirehook"));

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
	if(thehook.aiment.health > 0)
	if(autocvar_g_vampirehook_damage)
	{
		thehook.last_dmg = time + autocvar_g_vampirehook_damagerate;
		thehook.owner.damage_dealt += autocvar_g_vampirehook_damage;
		Damage(dmgent, thehook, thehook.owner, autocvar_g_vampirehook_damage, WEP_HOOK.m_id, thehook.origin, '0 0 0');
		if(SAME_TEAM(thehook.owner, thehook.aiment))
			thehook.aiment.health = min(thehook.aiment.health + autocvar_g_vampirehook_health_steal, g_pickup_healthsmall_max);
		else
			thehook.owner.health = min(thehook.owner.health + autocvar_g_vampirehook_health_steal, g_pickup_healthsmall_max);

		if(dmgent == thehook.owner)
			dmgent.health -= autocvar_g_vampirehook_damage; // FIXME: friendly fire?!
	}
}
