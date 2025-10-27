#include "flight.qh"

#ifdef SVQC
METHOD(FlightBuff, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
	bool was_active = actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE);
	if (!was_active)
	{
		actor.buff_flight_oldgravity = actor.gravity;
		if (!actor.gravity)
			actor.gravity = 1;
	}
	SUPER(FlightBuff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(FlightBuff, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
	bool was_active = actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE);
	if (was_active)
		actor.gravity = (actor.trigger_gravity_check)
			? actor.trigger_gravity_check.enemy.gravity
			: actor.buff_flight_oldgravity;
	actor.buff_flight_oldgravity = 0;
	SUPER(FlightBuff).m_remove(this, actor, removal_type);
}
#endif // SVQC
#ifdef MENUQC
METHOD(FlightBuff, describe, string(FlightBuff this))
{
	TC(FlightBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("While you have the %s buff, you can crouch while mid-air to switch your gravity, allowing flight."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif
