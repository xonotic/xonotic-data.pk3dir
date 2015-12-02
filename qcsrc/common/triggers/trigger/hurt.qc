#ifdef SVQC
void trigger_hurt_use()
{SELFPARAM();
	if(IS_PLAYER(activator))
		self.enemy = activator;
	else
		self.enemy = world; // let's just destroy it, if taking over is too much work
}

.float triggerhurttime;
void trigger_hurt_touch()
{SELFPARAM();
	if (self.active != ACTIVE_ACTIVE)
		return;

	if(self.team)
		if(((self.spawnflags & 4) == 0) == (self.team != other.team))
			return;

	// only do the EXACTTRIGGER_TOUCH checks when really needed (saves some cpu)
	if (other.iscreature)
	{
		if (other.takedamage)
		if (other.triggerhurttime < time)
		{
			EXACTTRIGGER_TOUCH;
			other.triggerhurttime = time + 1;

			entity own;
			own = self.enemy;
			if (!IS_PLAYER(own))
			{
				own = self;
				self.enemy = world; // I still hate you all
			}

			Damage (other, self, own, self.dmg, DEATH_HURTTRIGGER.m_id, other.origin, '0 0 0');
		}
	}
	else if(other.damagedbytriggers)
	{
		if(other.takedamage)
		{
			EXACTTRIGGER_TOUCH;
			Damage(other, self, self, self.dmg, DEATH_HURTTRIGGER.m_id, other.origin, '0 0 0');
		}
	}

	return;
}

/*QUAKED spawnfunc_trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
defalt dmg = 5
*/
.entity trigger_hurt_next;
entity trigger_hurt_last;
entity trigger_hurt_first;
spawnfunc(trigger_hurt)
{
	EXACTTRIGGER_INIT;
	self.active = ACTIVE_ACTIVE;
	self.touch = trigger_hurt_touch;
	self.use = trigger_hurt_use;
	self.enemy = world; // I hate you all
	if (!self.dmg)
		self.dmg = 1000;
	if (self.message == "")
		self.message = "was in the wrong place";
	if (self.message2 == "")
		self.message2 = "was thrown into a world of hurt by";
	// self.message = "someone like %s always gets wrongplaced";

	if(!trigger_hurt_first)
		trigger_hurt_first = self;
	if(trigger_hurt_last)
		trigger_hurt_last.trigger_hurt_next = self;
	trigger_hurt_last = self;
}

float tracebox_hits_trigger_hurt(vector start, vector mi, vector ma, vector end)
{
	entity th;

	for(th = trigger_hurt_first; th; th = th.trigger_hurt_next)
		if(tracebox_hits_box(start, mi, ma, end, th.absmin, th.absmax))
			return true;

	return false;
}
#endif
