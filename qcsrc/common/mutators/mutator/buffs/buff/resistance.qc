#include "resistance.qh"

#ifdef SVQC
float buff_Resistance_CalculateDamage(float frag_damage)
{
	return bound(0, frag_damage * (1 - autocvar_g_buffs_resistance_blockpercent), frag_damage);
}
#endif // SVQC
#ifdef MENUQC
METHOD(ResistanceBuff, describe, string(ResistanceBuff this))
{
	TC(ResistanceBuff, this);
	return sprintf(_("The %s greatly reduces your damage taken while the buff is active.\n\n"
		"This also impacts the damage you deal to yourself."),
	COLORED_NAME_WITH_CONCAT(this, _("Buff")));
}
#endif // MENUQC
