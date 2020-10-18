#include "secret.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <common/util.qh>
    #include <common/weapons/_all.qh>
    #include <common/stats.qh>
#endif

#ifdef SVQC

/**
 * A secret has been found (maybe :P)
 */
void trigger_secret_touch(entity this, entity toucher)
{
	// only a player can trigger this
	if (!IS_PLAYER(toucher))
		return;

	EXACTTRIGGER_TOUCH(this, toucher);

	// update secrets found counter
	secrets_found += 1;

	// message and noise handled by SUB_UseTargets
	SUB_UseTargets(this, toucher, toucher);

	// we can't just delete(this) here, because this is a touch function
	// called while C code is looping through area links...
	settouch(this, func_null);
}

#if 0
void trigger_secret_reset(entity this)
{
	secrets_found = 0;
	settouch(this, trigger_secret_touch);
}
#endif

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
	if (!this.message || this.message == "")
		this.message = "You found a secret!";

	// set default sound
	if ((!this.noise || this.noise == "") && !this.sounds)
		this.sounds = 1; // misc/secret.wav

	switch(this.sounds)
	{
		case 1: this.noise = "misc/secret.wav"; break;
		case 2: this.noise = strzone(SND(TALK)); break;
		case 3: this.noise = "misc/trigger1.wav"; break;
	}

	if(this.noise && this.noise != "")
		precache_sound(this.noise);

	// a secret cannot be delayed
	this.delay = 0;

	EXACTTRIGGER_INIT;

	settouch(this, trigger_secret_touch);
// NOTE: old maps don't expect secrets to reset, so enabling resetting can cause issues!
#if 0
	this.reset = trigger_secret_reset;
#endif
}
#endif
