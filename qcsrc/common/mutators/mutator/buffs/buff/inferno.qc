#include "inferno.qh"

#ifdef SVQC
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
#endif // SVQC
#ifdef MENUQC
METHOD(InfernoBuff, describe, string(InfernoBuff this))
{
	TC(InfernoBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff sets any enemies or monsters you attack alight, dealing burn damage to them for several seconds until the buff expires."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
