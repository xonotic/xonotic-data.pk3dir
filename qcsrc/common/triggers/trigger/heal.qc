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
		if (toucher.takedamage)
		if (!IS_DEAD(toucher))
		if (toucher.triggerhealtime < time)
		{
			bool is_trigger = !boolean(!this.nottargeted && this.targetname != "");
			if(is_trigger)
				EXACTTRIGGER_TOUCH(this, toucher);
			toucher.triggerhealtime = time + 1;

			bool playthesound = (this.spawnflags & 4);
			if (toucher.health < this.max_health)
			{
				playthesound = true;
				toucher.health = min(toucher.health + this.health, this.max_health);
				toucher.pauserothealth_finished = max(toucher.pauserothealth_finished, time + autocvar_g_balance_pause_health_rot);
			}

			if(playthesound)
				_sound (toucher, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
		}
	}
}

void trigger_heal_use(entity this, entity actor, entity trigger)
{
	trigger_heal_touch(this, actor);
}

spawnfunc(trigger_heal)
{
	this.active = ACTIVE_ACTIVE;

	EXACTTRIGGER_INIT;
	settouch(this, trigger_heal_touch);
	if (!this.health)
		this.health = 10;
	if (!this.max_health)
		this.max_health = 200; //Max health topoff for field
	if(this.noise == "")
		this.noise = "misc/mediumhealth.wav";
	precache_sound(this.noise);
}

spawnfunc(target_heal)
{
	this.active = ACTIVE_ACTIVE;
	this.use = trigger_heal_use;
	if (!this.health)
		this.health = 10;
	if (!this.max_health)
		this.max_health = 200; //Max health topoff for field
	if(this.noise == "")
		this.noise = "misc/mediumhealth.wav";
	precache_sound(this.noise);
}
#endif
