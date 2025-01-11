#include "sv_inferno.qh"

float buff_Inferno_CalculateTime(float dmg)
{
	float offset_x    = 0;
	float offset_y    = autocvar_g_buffs_inferno_burntime_min_time;
	float intersect_x = autocvar_g_buffs_inferno_burntime_target_damage;
	float intersect_y = autocvar_g_buffs_inferno_burntime_target_time;
	float base        = autocvar_g_buffs_inferno_burntime_factor;
	return offset_y + (intersect_y - offset_y) * logn(((dmg - offset_x) * ((base - 1) / intersect_x)) + 1, base);
}
float buff_Inferno_CalculateDamage(float frag_damage)
{
	return frag_damage * autocvar_g_buffs_inferno_damagemultiplier;
}
