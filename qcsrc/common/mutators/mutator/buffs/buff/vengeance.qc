#include "vengeance.qh"

#ifdef SVQC
void buff_Vengeance_DelayedDamage(entity this)
{
	if (this.enemy)
		Damage(this.enemy, this.owner, this.owner, this.dmg, DEATH_BUFF.m_id, DMG_NOWEP, this.enemy.origin, '0 0 0');

	delete(this);
	return;
}
float buff_Vengeance_CalculateDamage(float frag_damage)
{
	return frag_damage * autocvar_g_buffs_vengeance_damage_multiplier;
}
#endif // SVQC
#ifdef MENUQC
#include "vampire.qh"

METHOD(VengeanceBuff, describe, string(VengeanceBuff this))
{
	TC(VengeanceBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff reciprocates a portion of the damage enemies deal to you onto them, until the buff expires."), COLORED_NAME(this));
	PAR(_("In some sense, this is the opposite of the %s buff."), COLORED_NAME(BUFF_VAMPIRE));
	return PAGE_TEXT;
}
#endif // MENUQC
