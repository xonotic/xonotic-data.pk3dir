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

	if (!autocvar_g_vampirehook_damage || thehook.last_dmg > time || time < game_starttime)
		return;

	entity hook_owner = thehook.realowner;
	entity hook_aiment = thehook.aiment;

	if (hook_owner != hook_aiment && IS_PLAYER(hook_aiment) && !STAT(FROZEN, hook_aiment)
		&& (DIFF_TEAM(hook_owner, hook_aiment) || autocvar_g_vampirehook_teamheal)
		&& GetResource(hook_aiment, RES_HEALTH) > 0)
	{
		thehook.last_dmg = time + autocvar_g_vampirehook_damagerate;
		hook_owner.hitsound_damage_dealt += autocvar_g_vampirehook_damage;
		entity dmgent = ((SAME_TEAM(hook_owner, hook_aiment) && autocvar_g_vampirehook_teamheal) ? hook_owner : hook_aiment);
		Damage(dmgent, thehook, hook_owner, autocvar_g_vampirehook_damage, WEP_HOOK.m_id, DMG_NOWEP, thehook.origin, '0 0 0');
		entity targ = ((SAME_TEAM(hook_owner, hook_aiment)) ? hook_aiment : hook_owner);
		Heal(targ, hook_owner, autocvar_g_vampirehook_health_steal, autocvar_g_pickup_healthsmall_max);

		if(dmgent == hook_owner)
			TakeResource(dmgent, RES_HEALTH, autocvar_g_vampirehook_damage); // FIXME: friendly fire?!
	}
}
