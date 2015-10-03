// NOTE: also contains trigger_once at bottom

#ifdef SVQC
// the wait time has passed, so set back up for another activation
void multi_wait()
{SELFPARAM();
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
}


// the trigger was just touched/killed/used
// self.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void multi_trigger()
{SELFPARAM();
	if (self.nextthink > time)
	{
		return;		// allready been triggered
	}

	if (self.classname == "trigger_secret")
	{
		if (!IS_PLAYER(self.enemy))
			return;
		found_secrets = found_secrets + 1;
		WriteByte (MSG_ALL, SVC_FOUNDSECRET);
	}

	if (self.noise)
		_sound (self.enemy, CH_TRIGGER, self.noise, VOL_BASE, ATTEN_NORM);

// don't trigger again until reset
	self.takedamage = DAMAGE_NO;

	activator = self.enemy;
	other = self.goalentity;
	SUB_UseTargets();

	if (self.wait > 0)
	{
		self.think = multi_wait;
		self.nextthink = time + self.wait;
	}
	else if (self.wait == 0)
	{
		multi_wait(); // waiting finished
	}
	else
	{	// we can't just remove (self) here, because this is a touch function
		// called wheil C code is looping through area links...
		self.touch = func_null;
	}
}

void multi_use()
{SELFPARAM();
	self.goalentity = other;
	self.enemy = activator;
	multi_trigger();
}

void multi_touch()
{SELFPARAM();
	if(!(self.spawnflags & 2))
	if(!other.iscreature)
			return;

	if(self.team)
		if(((self.spawnflags & 4) == 0) == (self.team != other.team))
			return;

// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0')
	{
		makevectors (other.angles);
		if (v_forward * self.movedir < 0)
			return;		// not facing the right way
	}

	// if the trigger has pressed keys, check that the player is pressing those keys
	if(self.pressedkeys)
	if(IS_PLAYER(other)) // only for players
	if(!(other.pressedkeys & self.pressedkeys))
		return;

	EXACTTRIGGER_TOUCH;

	self.enemy = other;
	self.goalentity = other;
	multi_trigger ();
}

void multi_eventdamage (entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if (!self.takedamage)
		return;
	if(self.spawnflags & DOOR_NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	self.health = self.health - damage;
	if (self.health <= 0)
	{
		self.enemy = attacker;
		self.goalentity = inflictor;
		multi_trigger();
	}
}

void multi_reset()
{SELFPARAM();
	if ( !(self.spawnflags & SPAWNFLAG_NOTOUCH) )
		self.touch = multi_touch;
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
	self.think = func_null;
	self.nextthink = 0;
	self.team = self.team_saved;
}

/*QUAKED spawnfunc_trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by spawnfunc_trigger_relay!
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
spawnfunc(trigger_multiple)
{
	self.reset = multi_reset;
	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		self.noise = SND(TALK);
	}
	else if (self.sounds == 3)
	{
		precache_sound ("misc/trigger1.wav");
		self.noise = "misc/trigger1.wav";
	}

	if (!self.wait)
		self.wait = 0.2;
	else if(self.wait < -1)
		self.wait = 0;
	self.use = multi_use;

	EXACTTRIGGER_INIT;

	self.team_saved = self.team;

	if (self.health)
	{
		if (self.spawnflags & SPAWNFLAG_NOTOUCH)
			objerror ("health and notouch don't make sense\n");
		self.max_health = self.health;
		self.event_damage = multi_eventdamage;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin (self, self.origin);	// make sure it links into the world
	}
	else
	{
		if ( !(self.spawnflags & SPAWNFLAG_NOTOUCH) )
		{
			self.touch = multi_touch;
			setorigin (self, self.origin);	// make sure it links into the world
		}
	}
}


/*QUAKED spawnfunc_trigger_once (.5 .5 .5) ? notouch
Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
"targetname".  If "health" is set, the trigger must be killed to activate.
If notouch is set, the trigger is only fired by other entities, not by touching.
if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
spawnfunc(trigger_once)
{
	this.wait = -1;
	spawnfunc_trigger_multiple(this);
}
#endif
