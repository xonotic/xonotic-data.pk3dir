#include "disability.qh"

#ifdef SVQC
void buff_Disability_ApplyStunned(entity frag_target, entity frag_attacker)
{
	if(frag_target != frag_attacker)
		StatusEffects_apply(STATUSEFFECT_Stunned, frag_target, time + autocvar_g_buffs_disability_slowtime, 0);
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(StatusEffects_active(STATUSEFFECT_Stunned, player))
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_buffs_disability_speed;
}

MUTATOR_HOOKFUNCTION(buffs, MonsterMove)
{
	entity mon = M_ARGV(0, entity);

	if(StatusEffects_active(STATUSEFFECT_Stunned, mon))
	{
		M_ARGV(1, float) *= autocvar_g_buffs_disability_speed; // run speed
		M_ARGV(2, float) *= autocvar_g_buffs_disability_speed; // walk speed
	}
}

MUTATOR_HOOKFUNCTION(buffs, WeaponRateFactor)
{
	entity player = M_ARGV(1, entity);

	if(StatusEffects_active(STATUSEFFECT_Stunned, player))
		M_ARGV(0, float) *= autocvar_g_buffs_disability_rate;
}
MUTATOR_HOOKFUNCTION(buffs, WeaponSpeedFactor)
{
	entity player = M_ARGV(1, entity);

	if(StatusEffects_active(STATUSEFFECT_Stunned, player))
		M_ARGV(0, float) *= autocvar_g_buffs_disability_weaponspeed;
}
#endif // SVQC
