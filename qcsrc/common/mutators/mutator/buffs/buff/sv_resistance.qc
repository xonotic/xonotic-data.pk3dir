#include "sv_resistance.qh"

float buff_Resistance_CalculateDamage(float frag_damage)
{
	return bound(0, frag_damage * (1 - autocvar_g_buffs_resistance_blockpercent), frag_damage);
}
