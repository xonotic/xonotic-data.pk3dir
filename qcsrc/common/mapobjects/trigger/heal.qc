#include "heal.qh"
#ifdef SVQC
.float triggerhealtime;
void trigger_heal_touch(entity this, entity toucher)
{
	if (this.active != ACTIVE_ACTIVE)
		return;

	// only do the EXACTTRIGGER_TOUCH checks when really needed (saves some cpu)
	if (toucher.iscreature)
	{
		if (toucher.takedamage && !IS_DEAD(toucher) && toucher.triggerhealtime < time)
		{
			bool is_trigger = this.targetname == "";
			if(is_trigger)
				EXACTTRIGGER_TOUCH(this, toucher);
			if(this.delay > 0)
				toucher.triggerhealtime = time + this.delay;

			bool playthesound = (this.spawnflags & HEAL_SOUND_ALWAYS);
			bool healed = Heal(toucher, this, this.health, this.max_health);

			if(playthesound || healed)
				_sound (toucher, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
		}
	}
}

void trigger_heal_use(entity this, entity actor, entity trigger)
{
	trigger_heal_touch(this, actor);
}

void trigger_heal_init(entity this)
{
	this.active = ACTIVE_ACTIVE;
	if(!this.delay)
		this.delay = 1;
	if(!this.health)
		this.health = 10;
	if(!this.max_health)
		this.max_health = 200; // max health topoff for field
	if(this.noise == "")
		this.noise = "misc/mediumhealth.wav";
	precache_sound(this.noise);
}

spawnfunc(trigger_heal)
{
	EXACTTRIGGER_INIT;
	settouch(this, trigger_heal_touch);
	trigger_heal_init(this);
}

spawnfunc(target_heal)
{
	this.use = trigger_heal_use;
	trigger_heal_init(this);
}
#endif
