#include "jump.qh"

#ifdef SVQC
float buff_Jump_ChangeDamage(float frag_damage, float frag_deathtype)
{
	if (frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;
	return frag_damage;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);

	// these automatically reset, no need to worry
	if (StatusEffects_active(BUFF_JUMP, player))
		STAT(MOVEVARS_JUMPVELOCITY, player) = autocvar_g_buffs_jump_velocity;
}
#endif // SVQC
#ifdef MENUQC
METHOD(JumpBuff, describe, string(JumpBuff this))
{
	TC(JumpBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff greatly increases your jump height, while the buff is active."), COLORED_NAME(this));
	PAR(_("It also makes you immune to fall damage."));
	return PAGE_TEXT;
}
#endif // MENUQC
