#include "sv_jump.qh"

float buff_Jump_ChangeDamage(float frag_damage, float frag_deathtype)
{
	if(frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;
	return frag_damage;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(StatusEffects_active(BUFF_JUMP, player))
		STAT(MOVEVARS_JUMPVELOCITY, player) = autocvar_g_buffs_jump_height;
}
