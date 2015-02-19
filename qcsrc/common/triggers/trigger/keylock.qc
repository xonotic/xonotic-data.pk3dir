/**
 * trigger given targets
 */
void trigger_keylock_trigger(string s)
{
	entity stemp = self;
	entity otemp = other;
	entity atemp = activator;

	entity t;
	for(t = world; (t = find(t, targetname, s)); )
		if(t.use)
		{
			self = t;
			other = stemp;
			activator = atemp;
			self.use();
		}

	self = stemp;
	other = otemp;
	activator = atemp;
}

/**
 * kill killtarget of trigger keylock.
 */
void trigger_keylock_kill(string s)
{
	entity t;
	for(t = world; (t = find(t, targetname, s)); )
		remove(t);
}

void trigger_keylock_touch()
{
	bool key_used = false;
	bool started_delay = false;

	// only player may trigger the lock
	if(!IS_PLAYER(other))
		return;

	// check silver key
	if(self.itemkeys)
		key_used = item_keys_usekey(self, other);

	activator = other;

	if(self.itemkeys)
	{
#ifdef SVQC
		// at least one of the keys is missing
		if(key_used)
		{
			// one or more keys were given, but others are still missing!
			play2(other, self.noise1);
			Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_DOOR_LOCKED_ALSONEED, item_keys_keylist(self.itemkeys));
			other.key_door_messagetime = time + 2;
		}
		else if(other.key_door_messagetime <= time)
		{
			// no keys were given
			play2(other, self.noise2);
			Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_DOOR_LOCKED_NEED, item_keys_keylist(self.itemkeys));
			other.key_door_messagetime = time + 2;
		}
#endif

		// trigger target2
		if(self.delay <= time || started_delay == true)
		if(self.target2)
		{
			trigger_keylock_trigger(self.target2);
			started_delay = true;
			self.delay = time + self.wait;
		}
	}
	else
	{
#ifdef SVQC
		// all keys were given!
		play2(other, self.noise);
		centerprint(other, self.message);
#endif

		if(self.target)
			trigger_keylock_trigger(self.target);

		if(self.killtarget)
			trigger_keylock_kill(self.killtarget);

		remove(self);
	}

}

#ifdef SVQC
bool trigger_keylock_send(entity to, int sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_KEYLOCK);

	WriteString(MSG_ENTITY, self.target);
	WriteString(MSG_ENTITY, self.target2);
	WriteString(MSG_ENTITY, self.target3);
	WriteString(MSG_ENTITY, self.target4);
	WriteString(MSG_ENTITY, self.killtarget);
	WriteString(MSG_ENTITY, self.targetname);

	WriteInt24_t(MSG_ENTITY, self.itemkeys);
	WriteByte(MSG_ENTITY, self.warpzone_isboxy);
	WriteByte(MSG_ENTITY, self.height);
	WriteByte(MSG_ENTITY, self.scale);

	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteCoord(MSG_ENTITY, self.mins_x);
	WriteCoord(MSG_ENTITY, self.mins_y);
	WriteCoord(MSG_ENTITY, self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x);
	WriteCoord(MSG_ENTITY, self.maxs_y);
	WriteCoord(MSG_ENTITY, self.maxs_z);

	WriteCoord(MSG_ENTITY, self.movedir_x);
	WriteCoord(MSG_ENTITY, self.movedir_y);
	WriteCoord(MSG_ENTITY, self.movedir_z);

	return true;
}

void trigger_keylock_link()
{
	// uncomment to network keylocks
	//Net_LinkEntity(self, false, 0, trigger_keylock_send);
}

/*QUAKED trigger_keylock (.0 .5 .8) ?
Keylock trigger.  Must target other entities.
This trigger will trigger target entities when all required keys are provided.
-------- KEYS --------
itemkeys: A bit field with key IDs that are needed to open this lock.
sounds: 1 to play misc/secret.wav, 2 to play misc/talk.wav, 3 to play misc/trigger1.wav (3 is default)
target: trigger all entities with this targetname when triggered and all keys have been given to it, then remove this trigger
target2: trigger all entities with this targetname when triggered without giving it all the required keys.
killtarget: remove all entities with this targetname when triggered with all the needed keys.
message: print this message to the player who activated the trigger when all needed keys have been given.
message2: print this message to the player who activated the trigger when not all of the needed keys have been given.
noise: sound to play when lock gets unlocked (default: see sounds)
noise1: sound to play when only some of the needed key were used but not all (default: misc/decreasevalue.wav)
noise2: sound to play when a key is missing (default: misc/talk.wav)
wait: prevent triggering again for this amount of time (default: 5) - applies to target2, target3, target4.
---------NOTES----------
If spawned without any key specified in itemkeys, this trigger will display an error and remove itself.
message2 and noise2 will be resent to the player every 2 seconds while he is in the trigger zone.
*/
void spawnfunc_trigger_keylock(void)
{
	if(!self.itemkeys) { remove(self); return; }

	// set unlocked message
	if(self.message == "")
		self.message = "Unlocked!";

	// set default unlock noise
	if(self.noise == "")
	{
		if(self.sounds == 1)
			self.noise = "misc/secret.wav";
		else if(self.sounds == 2)
			self.noise = "misc/talk.wav";
		else //if (self.sounds == 3) {
			self.noise = "misc/trigger1.wav";
	}

	// set default use key sound
	if(self.noise1 == "")
		self.noise1 = "misc/decreasevalue.wav";

	// set closed sourd
	if(self.noise2 == "")
		self.noise2 = "misc/talk.wav";

	// delay between triggering message2 and trigger2
	if(!self.wait) { self.wait = 5; }

	// precache sounds
	precache_sound(self.noise);
	precache_sound(self.noise1);
	precache_sound(self.noise2);

	EXACTTRIGGER_INIT;

	self.touch = trigger_keylock_touch;

	trigger_keylock_link();
}
#elif defined(CSQC)
void keylock_remove()
{
	if(self.target) { strunzone(self.target); }
	self.target = string_null;

	if(self.target2) { strunzone(self.target2); }
	self.target2 = string_null;

	if(self.target3) { strunzone(self.target3); }
	self.target3 = string_null;

	if(self.target4) { strunzone(self.target4); }
	self.target4 = string_null;

	if(self.killtarget) { strunzone(self.killtarget); }
	self.killtarget = string_null;

	if(self.targetname) { strunzone(self.targetname); }
	self.targetname = string_null;
}

void ent_keylock()
{
	self.target = strzone(ReadString());
	self.target2 = strzone(ReadString());
	self.target3 = strzone(ReadString());
	self.target4 = strzone(ReadString());
	self.killtarget = strzone(ReadString());
	self.targetname = strzone(ReadString());

	self.itemkeys = ReadInt24_t();
	self.warpzone_isboxy = ReadByte();
	self.height = ReadByte();
	self.scale = ReadByte();

	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();

	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();

	self.movedir_x = ReadCoord();
	self.movedir_y = ReadCoord();
	self.movedir_z = ReadCoord();

	self.classname = "trigger_keylock";
	self.drawmask = MASK_NORMAL;
	self.draw = trigger_draw_generic;
	self.trigger_touch = trigger_keylock_touch;
	self.entremove = keylock_remove;
}
#endif
