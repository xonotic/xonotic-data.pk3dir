#include "sv_breakablehook.qh"

#include <common/deathtypes/all.qh>
#include <server/hook.qh>

REGISTER_MUTATOR(breakablehook, cvar("g_breakablehook"));

bool autocvar_g_breakablehook; // allow toggling mid match?
bool autocvar_g_breakablehook_owner;

MUTATOR_HOOKFUNCTION(breakablehook, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if(frag_target.classname == "grapplinghook")
	{
		if((!autocvar_g_breakablehook)
		|| (!autocvar_g_breakablehook_owner && frag_attacker == frag_target.realowner)
			) { M_ARGV(4, float) = 0; }

		// hurt the owner of the hook
		if(DIFF_TEAM(frag_attacker, frag_target.realowner))
		{
			Damage (frag_target.realowner, frag_attacker, frag_attacker, 5, WEP_HOOK.m_id | HITTYPE_SPLASH, DMG_NOWEP, frag_target.realowner.origin, '0 0 0'); // TODO: should get weapon entity from mutator hook
			RemoveHook(frag_target);
			return; // dead
		}
	}
}
