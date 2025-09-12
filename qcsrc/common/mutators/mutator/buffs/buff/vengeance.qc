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
	PAR(_("The %s reciprocates a portion of the damage enemies deal to you onto them, until the buff expires."), COLORED_NAME_WITH_CONCAT(this, _("Buff")));
	PAR(_("In some sense, this is the opposite of the %s."), COLORED_NAME_WITH_CONCAT(BUFF_VAMPIRE, _("Buff")));
	return PAGE_TEXT;
}
#endif // MENUQC
