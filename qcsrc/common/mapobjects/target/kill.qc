#include "kill.qh"

#ifdef SVQC
void target_kill_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	if(actor.takedamage == DAMAGE_NO)
		return;

	if(!actor.iscreature && !actor.damagedbytriggers)
		return;

	Damage(actor, this, trigger, 1000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, actor.origin, '0 0 0');
}

void target_kill_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
}

spawnfunc(target_kill)
{
    if (this.message == "")
		this.message = "was in the wrong place";

	if (this.message2 == "")
		this.message2 = "was thrown into a world of hurt by";

    this.use = target_kill_use;
    this.reset = target_kill_reset;
    this.active = ACTIVE_ACTIVE;
}
#endif
