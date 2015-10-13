#include "../../common/deathtypes/all.qh"
#include "../g_hook.qh"

REGISTER_MUTATOR(bh, cvar("g_breakablehook"));

bool autocvar_g_breakablehook; // allow toggling mid match?
bool autocvar_g_breakablehook_owner;

MUTATOR_HOOKFUNCTION(bh, PlayerDamage_Calculate)
{
	if(frag_target.classname == "grapplinghook")
	{
		if((!autocvar_g_breakablehook)
		|| (!autocvar_g_breakablehook_owner && frag_attacker == frag_target.realowner)
			) { frag_damage = 0; }

		// hurt the owner of the hook
		if(DIFF_TEAM(frag_attacker, frag_target.realowner))
		{
			Damage (frag_target.realowner, frag_attacker, frag_attacker, 5, WEP_HOOK.m_id | HITTYPE_SPLASH, frag_target.realowner.origin, '0 0 0');
			RemoveGrapplingHook(frag_target.realowner);
			return false; // dead
		}
	}

	return false;
}
