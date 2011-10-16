entity secret_counter;

/*
.count - total number of secrets to find
.cnt - number of secrets found
*/
void secret_counter_create() {
	secret_counter = spawn();
	secret_counter.classname = "secret_counter";
	secret_counter.count = 0;
	secret_counter.cnt = 0;
}

/*
A secret has been found!
*/
void trigger_secret_touch() {
	// only a player can trigger this
	if (other.classname != "player")
		return;
	
	// update secrets found counter
	secret_counter.cnt += 1;
	//print("Secret found: ", ftos(secret_counter.cnt), "/");
	//print(ftos(secret_counter.count), "\n");
	
	// handle normal trigger features
	multi_touch();
	remove(self);
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
void spawnfunc_trigger_secret() {
	// FIXME: should it be disabled in most modes?
	
	// create secret counter
	if not(secret_counter)
		secret_counter_create();
	
	// update secrets count
	secret_counter.count += 1;
	
	// add default message
	if (self.message == "")
		self.message = "You found a secret!";
	
	// set default sound
	if (self.noise == "")
	if not(self.sounds)
		self.sounds = 1; // misc/secret.wav
	
	// this entity can't be a target itself!!!!
	self.targetname = "";
	
	// you can't just shoot a room to find it, can you?
	self.health = 0;
	
	// a secret can not be delayed
	self.delay = 0;
	
	// convert this trigger to trigger_once
	self.classname = "trigger_once";
	spawnfunc_trigger_once();
	
	// take over the touch() function, so we can mark secret as found
	self.touch = trigger_secret_touch;
	// ignore triggering;
	self.use = SUB_Null;
}

