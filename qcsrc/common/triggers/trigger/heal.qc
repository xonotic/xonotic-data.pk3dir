#ifdef SVQC
.float triggerhealtime;
void trigger_heal_touch(entity this)
{
	if (this.active != ACTIVE_ACTIVE)
		return;

	// only do the EXACTTRIGGER_TOUCH checks when really needed (saves some cpu)
	if (other.iscreature)
	{
		if (other.takedamage)
		if (!IS_DEAD(other))
		if (other.triggerhealtime < time)
		{
			EXACTTRIGGER_TOUCH;
			other.triggerhealtime = time + 1;

			if (other.health < this.max_health)
			{
				other.health = min(other.health + this.health, this.max_health);
				other.pauserothealth_finished = max(other.pauserothealth_finished, time + autocvar_g_balance_pause_health_rot);
				_sound (other, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
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
