#include "normal.qh"

#ifdef SVQC
void nade_normal_boom(entity this)
{
	RadiusDamage(this, this.realowner, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage,
		autocvar_g_nades_nade_radius, this, NULL, autocvar_g_nades_nade_force, this.projectiledeathtype, DMG_NOWEP, this.enemy);
	Damage_DamageInfo(this.origin, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage,
		autocvar_g_nades_nade_radius, '1 1 1' * autocvar_g_nades_nade_force, this.projectiledeathtype, 0, this);
}
#endif // SVQC
#ifdef MENUQC
METHOD(NormalNade, describe, string(NormalNade this))
{
	TC(NormalNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The (normal) %s explodes after a short delay, dealing damage to nearby players. "
	      "If other nade types are destroyed before they detonate, they instead explode similar to this, without doing their special effects."), COLORED_NAME(this));
	PAR(_("Make sure you remember to throw it with %s, or else it will blow up in your hands!"), strcat("^3", _("drop weapon"), "^7"));
	return PAGE_TEXT;
}
#endif // MENUQC
