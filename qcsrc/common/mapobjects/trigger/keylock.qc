#include "keylock.qh"
/**
 * trigger given targets
 */
void trigger_keylock_trigger(entity this, entity actor, string s)
{
	for(entity t = NULL; (t = find(t, targetname, s)); )
		if(t.use)
			t.use(t, actor, this);
}

/**
 * kill killtarget of trigger keylock.
 */
void trigger_keylock_kill(string s)
{
	entity t;
	for(t = NULL; (t = find(t, targetname, s)); )
		delete(t);
}

void trigger_keylock_touch(entity this, entity toucher)
{
	bool key_used = false;
	bool started_delay = false;

	// only player may trigger the lock
	if(!IS_PLAYER(toucher))
		return;

	// check silver key
	if(this.itemkeys)
	{
#ifdef SVQC
		entity store = PS(toucher);
#elif defined(CSQC)
		entity store = toucher;
#endif
		key_used = item_keys_usekey(this, store);
	}

	if(this.itemkeys)
	{
#ifdef SVQC
		// at least one of the keys is missing
		if(key_used)
		{
			// one or more keys were given, but others are still missing!
			play2(toucher, this.noise1);
			Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_DOOR_LOCKED_ALSONEED, item_keys_keylist(this.itemkeys));
			toucher.key_door_messagetime = time + 2;
		}
		else if(toucher.key_door_messagetime <= time)
		{
			// no keys were given
			play2(toucher, this.noise2);
			Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_DOOR_LOCKED_NEED, item_keys_keylist(this.itemkeys));
			toucher.key_door_messagetime = time + 2;
		}
#endif

		// trigger target2
		if(this.delay <= time || started_delay == true)
		if(this.target2)
		{
			trigger_keylock_trigger(this, toucher, this.target2);
			started_delay = true;
			this.delay = time + this.wait;
		}
	}
	else
	{
#ifdef SVQC
		// all keys were given!
		play2(toucher, this.noise);
		centerprint(toucher, this.message);
#endif

		if(this.target)
			trigger_keylock_trigger(this, toucher, this.target);

		if(this.killtarget)
			trigger_keylock_kill(this.killtarget);

		delete(this);
	}

}

REGISTER_NET_LINKED(ENT_CLIENT_KEYLOCK)

#ifdef SVQC
bool trigger_keylock_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_KEYLOCK);

	WriteInt24_t(MSG_ENTITY, this.itemkeys);
	WriteByte(MSG_ENTITY, this.height);

	trigger_common_write(this, true);

	return true;
}

void trigger_keylock_link(entity this)
{
	// uncomment to network keylocks
	//Net_LinkEntity(this, false, 0, trigger_keylock_send);
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
message2 and noise2 will be resent to the player every 2 seconds while they are in the trigger zone.
*/
spawnfunc(trigger_keylock)
{
	if(!this.itemkeys) { delete(this); return; }

	// set unlocked message
	if(this.message == "")
		this.message = "Unlocked!";

	// set default unlock noise
	if(this.noise == "")
	{
		if(this.sounds == 1)
			this.noise = "misc/secret.wav";
		else if(this.sounds == 2)
			this.noise = strzone(SND(TALK));
		else //if (this.sounds == 3) {
			this.noise = "misc/trigger1.wav";
	}

	// set default use key sound
	if(this.noise1 == "")
		this.noise1 = "misc/decreasevalue.wav";

	// set closed sourd
	if(this.noise2 == "")
		this.noise2 = SND(TALK);

	// delay between triggering message2 and trigger2
	if(!this.wait) { this.wait = 5; }

	// precache sounds
	precache_sound(this.noise);
	precache_sound(this.noise1);
	precache_sound(this.noise2);

	EXACTTRIGGER_INIT;

	settouch(this, trigger_keylock_touch);

	trigger_keylock_link(this);
}
#elif defined(CSQC)
NET_HANDLE(ENT_CLIENT_KEYLOCK, bool isnew)
{
	this.itemkeys = ReadInt24_t();
	this.height = ReadByte();

	trigger_common_read(this, true);

	return = true;

	this.entremove = trigger_remove_generic;
}
#endif
