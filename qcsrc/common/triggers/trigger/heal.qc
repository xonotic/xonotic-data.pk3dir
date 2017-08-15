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
			EXACTTRIGGER_TOUCH(this, toucher);
			toucher.triggerhealtime = time + 1;

			if (toucher.health < this.max_health)
			{
				toucher.health = min(toucher.health + this.health, this.max_health);
				toucher.pauserothealth_finished = max(toucher.pauserothealth_finished, time + autocvar_g_balance_pause_health_rot);
				_sound (toucher, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
			}
		}
	}
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
#endif
