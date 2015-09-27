#ifdef SVQC
.float triggerhealtime;
void trigger_heal_touch()
{SELFPARAM();
	if (self.active != ACTIVE_ACTIVE)
		return;

	// only do the EXACTTRIGGER_TOUCH checks when really needed (saves some cpu)
	if (other.iscreature)
	{
		if (other.takedamage)
		if (!other.deadflag)
		if (other.triggerhealtime < time)
		{
			EXACTTRIGGER_TOUCH;
			other.triggerhealtime = time + 1;

			if (other.health < self.max_health)
			{
				other.health = min(other.health + self.health, self.max_health);
				other.pauserothealth_finished = max(other.pauserothealth_finished, time + autocvar_g_balance_pause_health_rot);
				_sound (other, CH_TRIGGER, self.noise, VOL_BASE, ATTEN_NORM);
			}
		}
	}
}

void spawnfunc_trigger_heal()
{SELFPARAM();
	self.active = ACTIVE_ACTIVE;

	EXACTTRIGGER_INIT;
	self.touch = trigger_heal_touch;
	if (!self.health)
		self.health = 10;
	if (!self.max_health)
		self.max_health = 200; //Max health topoff for field
	if(self.noise == "")
		self.noise = "misc/mediumhealth.wav";
	precache_sound(self.noise);
}
#endif
