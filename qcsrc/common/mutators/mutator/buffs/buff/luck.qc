#include "luck.qh"

#ifdef SVQC
float buff_Luck_CalculateDamage(float frag_damage)
{
	if (autocvar_g_buffs_luck_damagemultiplier > 0)
	if (random() <= autocvar_g_buffs_luck_chance)
		frag_damage *= autocvar_g_buffs_luck_damagemultiplier;
	return frag_damage;
}
#endif // SVQC
#ifdef MENUQC
METHOD(LuckBuff, describe, string(LuckBuff this))
{
	TC(LuckBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("While you have the %s buff, each attack has a chance of being a critical hit with greatly increased damage."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
