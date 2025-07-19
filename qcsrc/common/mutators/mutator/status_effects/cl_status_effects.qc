#include "cl_status_effects.qh"

METHOD(StatusEffect, m_active, bool(StatusEffect this, entity actor))
{
	// TODO: allow per-entity status effects on the client side
	actor = g_statuseffects;

	if(!actor) return false;
	TC(StatusEffect, this);
	return (actor.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE);
}

METHOD(StatusEffect, m_tick, void(StatusEffect this, entity actor))
{
	if(this.m_hidden || autocvar__hud_configure)
		return;

	float currentTime = bound(0, actor.statuseffect_time[this.m_id] - time, 99);
	addPowerupItem(this.m_name, this.m_icon, this.m_color, currentTime, this.m_lifetime, (actor.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_PERSISTENT));
}

MUTATOR_HOOKFUNCTION(status_effects, HUD_Powerups_add)
{
	if(!g_statuseffects && !autocvar__hud_configure) return;

	// NOTE: the passed entity may be null here if we're in configure mode
	StatusEffects_tick(g_statuseffects);
}
