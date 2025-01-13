#include "medic.qh"

#ifdef SVQC
MUTATOR_HOOKFUNCTION(buffs, PlayerRegen)
{
	entity player = M_ARGV(0, entity);

	if(StatusEffects_active(BUFF_MEDIC, player))
	{
		M_ARGV(3, float) = autocvar_g_buffs_medic_rot; // rot_mod
		M_ARGV(4, float) = M_ARGV(1, float) = autocvar_g_buffs_medic_max; // limit_mod = max_mod
		M_ARGV(2, float) = autocvar_g_buffs_medic_regen; // regen_mod
	}
}

float buff_Medic_CalculateSurviveDamage(float frag_damage, float health)
{
	if(random() <= autocvar_g_buffs_medic_survive_chance)
		frag_damage = max(5, health - autocvar_g_buffs_medic_survive_health);
	return frag_damage;
}
#endif // SVQC
