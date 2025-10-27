#include "medic.qh"

#ifdef SVQC
MUTATOR_HOOKFUNCTION(buffs, PlayerRegen)
{
	entity player = M_ARGV(0, entity);

	if (StatusEffects_active(BUFF_MEDIC, player))
	{
		M_ARGV(3, float) = autocvar_g_buffs_medic_rot; // rot_mod
		M_ARGV(4, float) = M_ARGV(1, float) = autocvar_g_buffs_medic_max; // limit_mod = max_mod
		M_ARGV(2, float) = autocvar_g_buffs_medic_regen; // regen_mod
	}
}

float buff_Medic_CalculateSurviveDamage(float frag_damage, float health)
{
	if (random() <= autocvar_g_buffs_medic_survive_chance)
		frag_damage = max(5, health - autocvar_g_buffs_medic_survive_health);
	return frag_damage;
}
#endif // SVQC
#ifdef MENUQC
METHOD(MedicBuff, describe, string(MedicBuff this))
{
	TC(MedicBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff increases health regeneration speed, increases the maximum health you can have before health starts to rot, and reduces health rot speed until the buff expires."), COLORED_NAME(this));
	PAR(_("It also gives you a chance to survive a fatal hit, with a small amount of health left over."));
	return PAGE_TEXT;
}
#endif // MENUQC
