#include "multi.qh"
// NOTE: also contains trigger_once at bottom

#ifdef SVQC
.int triggertimes;

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
void multi_trigger(entity this, bool exacttrigger)
{
	if((this.spawnflags & ONLY_PLAYERS) && !IS_PLAYER(this.enemy))
	{
		return; // only players
	}

	// In Q3 .wait <= 0 is forever,
	// in Xonotic .wait == -1 means forever and == -2 means don't wait at all.
	if (IS_GAMETYPE(CTS) && IS_CLIENT(this.enemy))
	{
		// check the client-specific trigger time
		int cnum = etof(this.enemy);
		if (buf_getsize(this.triggertimes) >= cnum) // buffer slot exists
		{
			float triggertime = stof(bufstr_get(this.triggertimes, cnum - 1));
			if (this.enemy.spawn_time <= triggertime) // havn't respawned since triggering
			{
				if ((this.wait <= 0 && (q3compat || this.wait >= -1)) // wait forever (until respawn in CTS)
				|| triggertime + this.wait > time) // too soon
					return;
			}
		}
	}
	else if (this.nextthink > time)
		return;		// allready been triggered

	if (exacttrigger)
		EXACTTRIGGER_TOUCH(this, this.enemy);

	if (this.noise && this.noise != "")
	{
		_sound (this.enemy, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
	}

	// don't trigger again until reset
	this.takedamage = DAMAGE_NO;

	SUB_UseTargets(this, this.enemy, this.goalentity);

	if (IS_GAMETYPE(CTS) && IS_CLIENT(this.enemy))
	{
		// store the client-specific trigger time
		string triggertime = sprintf("%15.14g", time); // 16b, perfect precision until timelimit_max @ <= 512hz (32768 sec)
		int cnum = etof(this.enemy);
		int bsize = buf_getsize(this.triggertimes);
		if (bsize >= cnum) // already got a slot
			bufstr_set(this.triggertimes, cnum - 1, triggertime);
		else while (bsize < cnum) // create any lower numbered slots too
			bufstr_add(this.triggertimes, (++bsize == cnum ? triggertime : "0"), true);
	}
	else if (this.wait > 0)
	{
		setthink(this, multi_wait);
		this.nextthink = time + this.wait;
	}
	else if (this.wait < -1 && !q3compat) // xon maps only: no waiting
	{
		multi_wait(this); // waiting finished
	}
	else
	{
		if (IS_GAMETYPE(CTS)) // client-specific .wait timers
			this.nextthink = stof("inf"); // clients can trigger again after respawning, disabled for other touchers
		else
		{
			// we can't just delete(this) here, because this is a touch function
			// called while C code is looping through area links...
			settouch(this, func_null);
			this.use = func_null;
		}
	}
}

void multi_use(entity this, entity actor, entity trigger)
{
	this.goalentity = trigger;
	this.enemy = actor;
	multi_trigger(this, false);
}

void multi_touch(entity this, entity toucher)
{
	if(!q3compat && !(this.spawnflags & ALL_ENTITIES) && !toucher.iscreature)
	{
		return;
	}

	if (q3compat && AVAILABLE_TEAMS == 2)
	{
		// This feature isn't mentioned in entities.def but it's in the source.
		// Xonotic has given these spawnflags other meanings.
		if(((this.spawnflags & 1) && toucher.team != NUM_TEAM_1) // not on red
		|| ((this.spawnflags & 2) && toucher.team != NUM_TEAM_2)) // not on blue
			return;
	}
	else if (this.team)
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

	this.enemy = toucher;
	this.goalentity = toucher;
	multi_trigger(this, true);
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
		multi_trigger(this, false);
	}
}

void multi_reset(entity this)
{
	if (q3compat || !(this.spawnflags & SPAWNFLAG_NOTOUCH))
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

	if (q3compat)
	{
		if (!this.wait)
		{
			string s = GetField_fullspawndata(this, "wait", false);
			if (!s || s == "") // it's really not set ("0" or "foo" waits forever)
				this.wait = 0.5;
		}
	}
	else if (!this.wait)
		this.wait = 0.2;

	this.use = multi_use;

	EXACTTRIGGER_INIT;

	// TEAMNUMBERS_THAT_ARENT_STUPID TODO: need to convert this.team to index, maybe add .teamindex
	this.team_saved = this.team;
	IL_PUSH(g_saved_team, this);

	// health/damage mode isn't supported in Q3 or with CTS client-specific .wait timers
	if (GetResource(this, RES_HEALTH) && !q3compat && !IS_GAMETYPE(CTS))
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
		if (q3compat || !(this.spawnflags & SPAWNFLAG_NOTOUCH))
			settouch(this, multi_touch);

		if (IS_GAMETYPE(CTS)) // client-specific .wait timers
			if ((this.triggertimes = buf_create()) < 0)
				LOG_FATAL("trigger_multiple: wait timer buffer creation failed somehow!\n");
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
