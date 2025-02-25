#include "flight.qh"

#ifdef SVQC
METHOD(FlightBuff, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(!wasactive)
	{
		actor.buff_flight_oldgravity = actor.gravity;
		if(!actor.gravity)
			actor.gravity = 1;
	}
	SUPER(FlightBuff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(FlightBuff, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(wasactive)
	{
		actor.gravity = ((actor.trigger_gravity_check) ? actor.trigger_gravity_check.enemy.gravity : actor.buff_flight_oldgravity);
	}
	actor.buff_flight_oldgravity = 0;
	SUPER(FlightBuff).m_remove(this, actor, removal_type);
}
#endif // SVQC
#ifdef MENUQC
METHOD(FlightBuff, describe, string(FlightBuff this))
{
	TC(FlightBuff, this);
	return sprintf(_("While you have the %s, you can crouch while midair to switch your gravity, allowing flight"),
	COLORED_NAME_WITH_CONCAT(this, _("Buff")));
}
#endif
