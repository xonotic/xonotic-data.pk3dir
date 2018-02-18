#include "kill.qh"
#include "location.qh"
#ifdef SVQC

void target_kill_use(entity this, entity actor, entity trigger)
{
	if(actor.takedamage == DAMAGE_NO)
		return;

	if(!actor.iscreature && !actor.damagedbytriggers)
		return;

	Damage(actor, this, trigger, 1000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, actor.origin, '0 0 0');
}

spawnfunc(target_kill)
{
    this.classname = "target_kill";

    if (this.message == "")
		this.message = "was in the wrong place";

    this.use = target_kill_use;
}

#endif
