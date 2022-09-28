#include "multi.qh"
// NOTE: also contains trigger_once at bottom

#ifdef SVQC
// the wait time has passed, so set back up for another activation
void multi_wait(entity this)
{
	if (this.max_health)
	{
		SetResourceExplicit(this, RES_HEALTH, this.max_health);
		this.takedamage = DAMAGE_YES;
		this.solid = SOLID_BBOX;
	}
}


// the trigger was just touched/killed/used
// this.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void multi_trigger(entity this)
{
	if (this.nextthink > time)
	{
		return;		// allready been triggered
	}

	if((this.spawnflags & ONLY_PLAYERS) && !IS_PLAYER(this.enemy))
	{
		return; // only players
	}

	if (this.noise && this.noise != "")
	{
		_sound (this.enemy, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
	}

	// don't trigger again until reset
	this.takedamage = DAMAGE_NO;

	SUB_UseTargets(this, this.enemy, this.goalentity);

	if (this.wait > 0)
	{
		setthink(this, multi_wait);
		this.nextthink = time + this.wait;
	}
	else if (this.wait == 0)
	{
		multi_wait(this); // waiting finished
	}
	else
	{	// we can't just delete(this) here, because this is a touch function
		// called while C code is looping through area links...
		settouch(this, func_null);
		this.use = func_null;
	}
}

void multi_use(entity this, entity actor, entity trigger)
{
	this.goalentity = trigger;
	this.enemy = actor;
	multi_trigger(this);
}

void multi_touch(entity this, entity toucher)
{
	if(!(this.spawnflags & ALL_ENTITIES) && !toucher.iscreature)
	{
		return;
	}

	if(this.team)
	{
		if(((this.spawnflags & INVERT_TEAMS) == 0) == (this.team != toucher.team))
		{
			return;
		}
	}

	// if the trigger has an angles field, check player's facing direction
	if (this.movedir != '0 0 0')
	{
		makevectors (toucher.angles);
		if (v_forward * this.movedir < 0)
			return;		// not facing the right way
	}

	// if the trigger has pressed keys, check that the player is pressing those keys
	if(this.pressedkeys && IS_PLAYER(toucher)) // only for players
	{
		if(!(CS(toucher).pressedkeys & this.pressedkeys))
		{
			return;
		}
	}

	EXACTTRIGGER_TOUCH(this, toucher);

	this.enemy = toucher;
	this.goalentity = toucher;
	multi_trigger(this);
}

void multi_eventdamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(!this.takedamage)
		return;
	if(this.spawnflags & NOSPLASH)
		if(!(DEATH_ISSPECIAL(deathtype)) && (deathtype & HITTYPE_SPLASH))
			return;
	if(this.team)
		if(((this.spawnflags & INVERT_TEAMS) == 0) == (this.team != attacker.team))
			return;
	TakeResource(this, RES_HEALTH, damage);
	if (GetResource(this, RES_HEALTH) <= 0)
	{
		this.enemy = attacker;
		this.goalentity = inflictor;
		multi_trigger(this);
	}
}

void multi_reset(entity this)
{
	if ( !(this.spawnflags & SPAWNFLAG_NOTOUCH) )
		settouch(this, multi_touch);
	if (this.max_health)
	{
		SetResourceExplicit(this, RES_HEALTH, this.max_health);
		this.takedamage = DAMAGE_YES;
		this.solid = SOLID_BBOX;
	}
	setthink(this, func_null);
	this.nextthink = 0;
	this.team = this.team_saved;
	this.use = multi_use;
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
	this.reset = multi_reset;
	if (this.sounds == 1)
		this.noise = "misc/secret.wav";
	else if (this.sounds == 2)
		this.noise = strzone(SND(TALK));
	else if (this.sounds == 3)
		this.noise = "misc/trigger1.wav";

	if(this.noise && this.noise != "")
		precache_sound(this.noise);

	if (!this.wait)
		this.wait = 0.2;
	else if(this.wait < -1)
		this.wait = 0;
	this.use = multi_use;

	if(this.wait == -1 && (q3compat & Q3COMPAT_DEFI))
		this.wait = 0.1; // compatibility for q3df: "instant" return

	EXACTTRIGGER_INIT;

	this.team_saved = this.team;
	IL_PUSH(g_saved_team, this);

	if (GetResource(this, RES_HEALTH))
	{
		if (this.spawnflags & SPAWNFLAG_NOTOUCH)
			objerror (this, "health and notouch don't make sense\n");
		this.canteamdamage = true;
		this.max_health = GetResource(this, RES_HEALTH);
		this.event_damage = multi_eventdamage;
		this.takedamage = DAMAGE_YES;
		this.solid = SOLID_BBOX;
		setorigin(this, this.origin);	// make sure it links into the world
	}
	else
	{
		if ( !(this.spawnflags & SPAWNFLAG_NOTOUCH) )
		{
			settouch(this, multi_touch);
			setorigin(this, this.origin);	// make sure it links into the world
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
