#include "luck.qh"

#ifdef SVQC
float buff_Luck_CalculateDamage(float frag_damage)
{
	if(autocvar_g_buffs_luck_damagemultiplier > 0)
	if(random() <= autocvar_g_buffs_luck_chance)
		frag_damage *= autocvar_g_buffs_luck_damagemultiplier;
	return frag_damage;
}
#endif // SVQC
