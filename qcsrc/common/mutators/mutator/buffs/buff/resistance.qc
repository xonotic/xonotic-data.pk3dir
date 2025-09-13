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
	PAGE_TEXT_INIT();
	PAR(_("The %s buff greatly reduces your damage taken while the buff is active."), COLORED_NAME(this));
	PAR(_("This also impacts the damage you deal to yourself."));
	return PAGE_TEXT;
}
#endif // MENUQC
