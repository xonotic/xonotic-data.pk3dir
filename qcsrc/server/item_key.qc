/*
TODO:
- add an unlock sound (here to trigger_keylock and to func_door)
- display available keys on the HUD
- make more tests
- think about adding NOT_EASY/NOT_NORMAL/NOT_HARD for Q1 compatibility
- should keys have a trigger?
*/

/*
================================
item_key1 / item_key2
================================
*/

/*
Key touch handler.
*/
void item_key_touch(void) {
	if (other.classname != "player")
		return;
		
	// player already picked up this key
	if (other.itemkeys & self.itemkeys)
		return;
	
	other.itemkeys |= self.itemkeys;
	play2(other, self.noise);
	
	if (self.message) {
		centerprint(other, self.message);
	}
};

/*
Spawn a key with given model, key code and color.
*/
void spawn_item_key(float key_code) {
	self.itemkeys = key_code;
	precache_model(self.model);
	
	if (self.spawnflags & 1) // FLOATING
		self.noalign = 1;
	
	if (self.noalign)
		self.movetype = MOVETYPE_NONE;
	else
		self.movetype = MOVETYPE_TOSS;
		
	if (!self.noise)
		self.noise = "misc/itempickup.wav";
	
	precache_sound(self.noise);
		
	self.mdl = self.model;
	self.effects = EF_LOWPRECISION;
	setmodel(self, self.model);
	//setsize(self, '-16 -16 -24', '16 16 32');
	setorigin(self, self.origin + '0 0 32');
	setsize(self, '-16 -16 -56', '16 16 0');
	self.modelflags |= MF_ROTATE;
	self.solid = SOLID_TRIGGER;
	
	if (!self.noalign)
	{
		// first nudge it off the floor a little bit to avoid math errors
		setorigin(self, self.origin + '0 0 1');
		// note droptofloor returns FALSE if stuck/or would fall too far
		droptofloor();
	}

	self.touch = item_key_touch;
};


/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32) FLOATING
SILVER key.
-----------KEYS------------
colormod: color of the key (default: '.9 .9 .9').
message: message to print when player picks up this key.
model: custom model to use.
noise: custom sound to play when player picks up the key.
-------- SPAWNFLAGS --------
FLOATING: the item will float in air, instead of aligning to the floor by falling
---------NOTES----------
*/
void spawnfunc_item_key1(void) {
	if (!self.model)
		self.model = "models/keys/key.md3";
	
	if (!self.colormod)
		self.colormod = '.9 .9 .9';
	
	if (!self.message)
		self.message = "You've picked up the silver key!";
		
	spawn_item_key(KEYS_SILVER_KEY);
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32) FLOATING
GOLD key.
-----------KEYS------------
colormod: color of the key (default: '1 .9 0').
message: message to print when player picks up this key.
model: custom model to use.
noise: custom sound to play when player picks up the key.
-------- SPAWNFLAGS --------
FLOATING: the item will float in air, instead of aligning to the floor by falling
---------NOTES----------
*/
void spawnfunc_item_key2(void) {
	if (!self.model)
		self.model = "models/keys/key.md3";
		
	if (!self.colormod)
		self.colormod = '1 .9 0';
	
	if (!self.message)
		self.message = "You've picked up the gold key!";
		
	spawn_item_key(KEYS_GOLD_KEY);
};


/*
================================
trigger_keylock
================================
*/

/*
trigger givent targets
*/
void trigger_keylock_trigger(string s) {
	local entity t, stemp, otemp, atemp;
	
	stemp = self;
	otemp = other;
	atemp = activator;
	
	
	for(t = world; (t = find(t, targetname, s)); )
		if (t.use) {
			self = t;
			other = stemp;
			activator = atemp;
			self.use();
		}
	
	self = stemp;
	other = otemp;
	activator = atemp;
};

/*
kill killtarget of trigger keylock.
*/
void trigger_keylock_kill(string s) {
	local entity t, stemp, otemp, atemp;
	
	stemp = self;
	otemp = other;
	atemp = activator;

	for(t = world; (t = find(t, targetname, s)); )
		if (t.use) {
			remove(t);
		}
	
	self = stemp;
	other = otemp;
	activator = atemp;
};

void trigger_keylock_touch(void) {
	local float key_used, silver_key_missing, gold_key_missing, started_delay;
	
	key_used = FALSE;
	silver_key_missing = FALSE;
	gold_key_missing = FALSE;
	started_delay = FALSE;
	
	// only player may trigger the lock
	if (other.classname != "player")
		return;
	
	
	// check silver key
	if (self.itemkeys & KEYS_SILVER_KEY) {
		// lock still requires the SILVER key
		if (other.itemkeys & KEYS_SILVER_KEY) {
			self.itemkeys &~= KEYS_SILVER_KEY;
			key_used = TRUE;
		} else {
			silver_key_missing = TRUE;
		}
	}
	
	// check gold key
	if (self.itemkeys & KEYS_GOLD_KEY) {
		// lock still requires the GOLD key
		if (other.itemkeys & KEYS_GOLD_KEY) {
			self.itemkeys &~= KEYS_GOLD_KEY;
			key_used = TRUE;
		} else {
			gold_key_missing = TRUE;
		}
	}
	
	
	activator = other;
	
	if (silver_key_missing) {
		// silver key is missing
		if (self.delay <= time) {
			if (self.target4) {
				trigger_keylock_trigger(self.target4);
				started_delay = TRUE;
				self.delay = time + self.wait;
			}
		}
	}
		
	if (gold_key_missing) {
		// gold key is missing
		if (self.delay <= time || started_delay) {
			if (self.target3) {
				trigger_keylock_trigger(self.target3);
				started_delay = TRUE;
				self.delay = time + self.wait;
			}
		}
		
	}
	
	if (silver_key_missing || gold_key_missing) {
		// at least one of the keys is missing
		
		if (key_used) {
			// one key was given, but an other one is missing!
			play2(other, self.noise1);
			if (silver_key_missing)
				centerprint(other, "You also need the silver key!");
			else if (gold_key_missing)
				centerprint(other, "You also need the gold key!");
			other.key_door_messagetime = time + 2;
		} else {
			if (other.key_door_messagetime <= time) {
				play2(other, self.noise2);
				centerprint(other, self.message2);
				other.key_door_messagetime = time + 2;
			}
		}
		
		if (self.delay <= time || started_delay == TRUE) {
			if (self.target2) {
				trigger_keylock_trigger(self.target2);
				started_delay = TRUE;
				self.delay = time + self.wait;
			}
		
		}
	} else {
		// all keys were given!
		play2(other, self.noise);
		centerprint(other, self.message);
		
		if (self.target)
			trigger_keylock_trigger(self.target);
			
		if (self.killtarget)
			trigger_keylock_kill(self.killtarget);
		
		remove(self);
	}
	
};

/*QUAKED trigger_keylock (.0 .5 .8) ? - - - GOLD_KEY SILVER_KEY
Keylock trigger.  Must target other entities.
This trigger will trigger target entities when all required keys are provided.
-------- KEYS --------
wait: prevent triggering again for this amount of time (default: 5) - applies to target2, target3, target4.
sounds: 1 to play misc/secret.wav, 2 to play misc/talk.wav, 3 to play misc/trigger1.wav
target: trigger all entities with this targetname when triggered and all keys have been given to it, then remove this trigger
target2: trigger all entities with this targetname when triggered without giving it all the required keys.
target3: trigger all entities with this targetname when triggered with GOLD_KEY missing (requires GOLD_KEY spawnflag)
target4: trigger all entities with this targetname when triggered with SILVER_KEY missing (requires SILVER_KEY spawnflag)
message: print this message to the player who activated the trigger when all needed keys have been given.
message2: print this message to the player who activated the trigger when not all of the needed keys have been given.
noise: sound to play when lock gets unlocked (default: see sounds)
noise1: sound to play when only one of the needed key was used (default: misc/decreasevalue.wav)
noise2: sound to play when a key is missing (default: misc/talk.wav)
killtarget: remove all entities with this targetname when triggered with all the needed keys.
-------- SPAWNFLAGS --------
GOLD_KEY: causes the door to open only if the activator holds a gold key.
SILVER_KEY: causes the door to open only if the activator holds a silver key.
---------NOTES----------
If spawned without any key specified, this trigger will remove itself.
message2 and noise2 will be resent to the player every 2 seconds while he is in the trigger zone.
*/
void spawnfunc_trigger_keylock(void) {
	if (!(self.spawnflags & (SPAWNFLAGS_SILVER_KEY | SPAWNFLAGS_GOLD_KEY))) {
		remove(self);
		return;
	}

	// give the trigger the silver key	
	if (self.spawnflags & SPAWNFLAGS_SILVER_KEY)
		self.itemkeys |= KEYS_SILVER_KEY;
	
	// give the trigger the gold key
	if (self.spawnflags & SPAWNFLAGS_GOLD_KEY)
		self.itemkeys |= KEYS_GOLD_KEY;

	if (!self.message2) {
		// generate default missing key message
		if (self.itemkeys & (KEYS_GOLD_KEY | KEYS_SILVER_KEY) == KEYS_GOLD_KEY | KEYS_SILVER_KEY) {
			self.message2 = "Silver key and gold key required!";
		} else if (self.itemkeys & KEYS_GOLD_KEY) {
			self.message2 = "Gold key required!";
		} else if (self.itemkeys & KEYS_SILVER_KEY) {
			self.message2 = "Silver key required!";
		}
	}
	
	if (!self.message) {
		self.message = "Unlocked!";
	}
	
	if (!self.noise) {
		if (self.sounds == 1) {
			self.noise = "misc/secret.wav";
		} else if (self.sounds == 2) {
			self.noise = "misc/talk.wav";
		} else { //if (self.sounds == 3) {
			self.noise = "misc/trigger1.wav";
		}
	}
		
	if (!self.noise1)
		self.noise1 = "misc/decreasevalue.wav";
		
	if (!self.noise2)
		self.noise2 = "misc/talk.wav";
	
	if (!self.wait)
		self.wait = 5;
	
	precache_sound(self.noise);
	precache_sound(self.noise1);
	precache_sound(self.noise2);
	
	EXACTTRIGGER_INIT;
	
	self.touch = trigger_keylock_touch;
};

