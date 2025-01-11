#include "sv_normal.qh"

void normal_nade_boom(entity this)
{
	RadiusDamage(this, this.realowner, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage,
		autocvar_g_nades_nade_radius, this, NULL, autocvar_g_nades_nade_force, this.projectiledeathtype, DMG_NOWEP, this.enemy);
	Damage_DamageInfo(this.origin, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage,
		autocvar_g_nades_nade_radius, '1 1 1' * autocvar_g_nades_nade_force, this.projectiledeathtype, 0, this);
}
