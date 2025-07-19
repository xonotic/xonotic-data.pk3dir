#include "status_effects.qh"

#ifdef GAMEQC
bool StatusEffects_active(StatusEffect this, entity actor)
{
	return this.m_active(this, actor);
}

void StatusEffects_tick(entity actor)
{
	FOREACH(StatusEffects, it.m_active(it, actor),
	{
		it.m_tick(it, actor);
	});
}

float StatusEffects_gettime(StatusEffect this, entity actor)
{
	entity store = actor;
#ifdef SVQC
	store = actor.statuseffects;
#endif
	if(!store) return 0;
	float eff_time = store.statuseffect_time[this.m_id];
	// if effect end time has passed and m_tick hasn't removed the effect yet
	// return current time since the effect is actually still active in this frame
	return (eff_time < time ? time : eff_time);
}
#endif
#ifdef SVQC
void StatusEffects_apply(StatusEffect this, entity actor, float eff_time, int eff_flags)
{
	if (!actor || eff_time <= time)
		return;

	this.m_apply(this, actor, eff_time, eff_flags);
}

void StatusEffects_copy(StatusEffect this, entity store, float time_offset)
{
	if(!this || !store)
		return;
	FOREACH(StatusEffects, true,
	{
		if(time_offset)
			store.statuseffect_time[it.m_id] = time + this.statuseffect_time[it.m_id] - time_offset;
		else
			store.statuseffect_time[it.m_id] = this.statuseffect_time[it.m_id];
		store.statuseffect_flags[it.m_id] = this.statuseffect_flags[it.m_id];
	});
}

void StatusEffects_remove(StatusEffect this, entity actor, int removal_type)
{
	this.m_remove(this, actor, removal_type);
}

void StatusEffects_removeall(entity actor, int removal_type)
{
	if(!actor.statuseffects)
		return;
	FOREACH(StatusEffects, true,
	{
		it.m_remove(it, actor, removal_type);
	});
}
#endif
