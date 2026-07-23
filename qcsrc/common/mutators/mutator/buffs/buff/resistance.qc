#include "resistance.qh"

#ifdef SVQC
float buff_Resistance_CalculateDamage(float frag_damage)
{
	return bound(0, frag_damage * (1 - autocvar_g_buffs_resistance_blockpercent), frag_damage);
}

METHOD(ResistanceBuff, m_tick, void(StatusEffect this, entity actor))
{
	SUPER(ResistanceBuff).m_tick(this, actor);
	if(!this.m_active(this, actor))
		return;
	buff_Effect(actor, EFFECT_ARMOR_REPAIR, CENTER_OF_ENT(actor), vec2(actor.velocity), 1, true);
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
