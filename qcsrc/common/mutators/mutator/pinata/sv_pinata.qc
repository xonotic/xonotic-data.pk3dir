#include "sv_pinata.qh"

REGISTER_MUTATOR(pinata, cvar("g_pinata") && !cvar("g_instagib") && !cvar("g_overkill"));

MUTATOR_HOOKFUNCTION(pinata, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];

		if(frag_target.(weaponentity).m_weapon == WEP_Null)
			continue;

		FOREACH(Weapons, it != WEP_Null, LAMBDA(
			if(frag_target.weapons & WepSet_FromWeapon(it))
			if(frag_target.(weaponentity).m_weapon != it)
			if(W_IsWeaponThrowable(frag_target, it.m_id))
				W_ThrowNewWeapon(frag_target, it.m_id, false, CENTER_OR_VIEWOFS(frag_target), randomvec() * 175 + '0 0 325', weaponentity);
		));
	}

	return true;
}

MUTATOR_HOOKFUNCTION(pinata, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":Pinata");
}

MUTATOR_HOOKFUNCTION(pinata, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Piñata");
}
