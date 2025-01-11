#include "sv_vengeance.qh"

void buff_Vengeance_DelayedDamage(entity this)
{
	if(this.enemy)
		Damage(this.enemy, this.owner, this.owner, this.dmg, DEATH_BUFF.m_id, DMG_NOWEP, this.enemy.origin, '0 0 0');

	delete(this);
	return;
}
float buff_Vengeance_CalculateDamage(float frag_damage)
{
	return frag_damage * autocvar_g_buffs_vengeance_damage_multiplier;
}
