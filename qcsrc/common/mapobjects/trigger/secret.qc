#include "secret.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <common/util.qh>
    #include <server/defs.qh>
#endif

#ifdef SVQC

void secrets_setstatus(entity this)
{
	// TODO: use global stats!
	STAT(SECRETS_TOTAL, this) = secrets_total;
	STAT(SECRETS_FOUND, this) = secrets_found;
}

/**
 * A secret has been found (maybe :P)
 */
void trigger_secret_touch(entity this, entity toucher)
{
	// only a player can trigger this
	if (!IS_PLAYER(toucher))
		return;

	// update secrets found counter
	secrets_found += 1;
	//print("Secret found: ", ftos(secret_counter.cnt), "/");
	//print(ftos(secret_counter.count), "\n");

	// centerprint message (multi_touch() doesn't always call centerprint())
	centerprint(toucher, this.message);
	this.message = "";

	// handle normal trigger features
	multi_touch(this, toucher);
	// we can't just delete(this) here, because this is a touch function
	// called while C code is looping through area links...
	//delete(this);
}

/*QUAKED trigger_secret (.5 .5 .5) ?
Variable sized secret trigger. Can be targeted at one or more entities.
Basically, it's a trigger_once (with restrictions, see notes) that additionally updates the number of secrets found.
-------- KEYS --------
sounds: 1 to play misc/secret.wav, 2 to play misc/talk.wav, 3 to play misc/trigger1.wav (default: 1)
noise: path to sound file, if you want to play something else
target: trigger all entities with this targetname when triggered
message: print this message to the player who activated the trigger instead of the standard 'You found a secret!'
killtarget: remove all entities with this targetname when triggered
-------- NOTES --------
You should create a common/trigger textured brush covering the entrance to a secret room/area.
Trigger secret can only be trigger by a player's touch and can not be a target itself.
*/
spawnfunc(trigger_secret)
{
	// FIXME: should it be disabled in most modes?

	// update secrets count
	secrets_total += 1;

	// add default message
	if (this.message == "")
		this.message = "You found a secret!";

	// set default sound
	if (this.noise == "")
	if (!this.sounds)
		this.sounds = 1; // misc/secret.wav

	// this entity can't be a target itself!!!!
	this.targetname = "";

	// you can't just shoot a room to find it, can you?
	SetResource(this, RES_HEALTH, 0);

	// a secret can not be delayed
	this.delay = 0;

	// convert this trigger to trigger_once
	//this.classname = "trigger_once";
	spawnfunc_trigger_once(this);

	// take over the touch() function, so we can mark secret as found
	settouch(this, trigger_secret_touch);
	// ignore triggering;
	this.use = func_null;
}
#endif
