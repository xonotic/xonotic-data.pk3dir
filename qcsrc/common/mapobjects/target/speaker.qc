#include "speaker.qh"
REGISTER_NET_LINKED(ENT_CLIENT_SPEAKER)

#ifdef SVQC
void target_speaker_use(entity this, entity actor, entity trigger)
{
	if (this.spawnflags & (SPEAKER_LOOPED_ON | SPEAKER_LOOPED_OFF))
	{
		this.state = !this.state;
		this.SendFlags |= SF_TRIGGER_UPDATE;
		return;
	}

	if(substring(this.noise, 0, 1) == "*")
	{
		entity psnd = GetPlayerSound(substring(this.noise, 1, -1));
		if (psnd && actor.(psnd.m_playersoundfld) != "")
		{
			string snd;
			tokenize_console(actor.(psnd.m_playersoundfld));
			float n = stof(argv(1));
			if(n > 0)
				snd = strcat(argv(0), ftos(floor(random() * n + 1)), ".wav"); // randomization
			else
				snd = strcat(argv(0), ".wav");

			if (psnd.instanceOfVoiceMessage) // perhaps this should support TEAMRADIO?
				_sound(actor, CH_VOICE, snd, VOL_BASEVOICE * this.volume, this.atten);
			else // PAIN: usually it'll be Q3's *falling1.wav
				_sound(actor, CH_PAIN_SINGLE, snd, VOL_BASE * this.volume, this.atten);
		}
	}
	else if (this.spawnflags & SPEAKER_ACTIVATOR && actor)
		_sound(actor, CH_PLAYER_SINGLE, this.noise, VOL_BASE * this.volume, this.atten);
	else
		_sound(this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE * this.volume, this.atten);
}

void target_speaker_think(entity this)
{
	_sound(this, CH_AMBIENT_SINGLE, this.noise, VOL_BASE * this.volume, this.atten);
	this.nextthink = time + this.wait + this.rnd * crandom();
}

void target_speaker_reset(entity this)
{
	this.state = this.spawnflags & SPEAKER_LOOPED_ON;
	this.SendFlags |= SF_TRIGGER_RESET;
}

float target_speaker_send(entity this, entity to, float sf)
{
	if (this.state)
		sf |= SF_TRIGGER_ENABLE;
	else
		sf &= ~SF_TRIGGER_ENABLE;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_SPEAKER);
	WriteByte(MSG_ENTITY, sf);

	if(sf & SF_TRIGGER_INIT)
	{
		WriteVector(MSG_ENTITY, this.origin);
		WriteString(MSG_ENTITY, this.noise);
		WriteFloat(MSG_ENTITY, this.volume);
		WriteFloat(MSG_ENTITY, this.atten);
	}

	return true;
}

/*QUAKED target_speaker (1 0 0) (-8 -8 -8) (8 8 8) looped-on looped-off global activator
"noise"		wav file to play

A global sound will play full volume throughout the level.
Activator sounds will play on the player that activated the target.
Global and activator sounds can't be combined with looping.
Normal sounds play each time the target is used.
Looped sounds will be toggled by use functions.
Multiple identical looping sounds will just increase volume without any speed cost.
"wait" : Seconds between auto triggerings, 0 = don't auto trigger
"random"	wait variance, default is 0
*/
spawnfunc(target_speaker)
{
	G_SpawnFloat("wait", 0, this, wait);
	G_SpawnFloat("random", 0, this, rnd);

	if (!this.noise)
	{
		string s = sprintf("target_speaker without a noise key at %v", this.origin);
		objerror(this, s); // s = macro workaround (origin is always '0 0 0' otherwise)
	}

	if (substring(this.noise, 0, 1) == "*")
	{
		// Q3: force all client reletive sounds to be "activator" speakers that
		// play on the entity that activates it
		this.spawnflags |= SPEAKER_ACTIVATOR;

		// Match Q3 filenames to registered player sounds
		switch (this.noise)
		{
			case "*death1.wav":    this.noise = "*death";   break;
			case "*death2.wav":    this.noise = "*death";   break;
			case "*death3.wav":    this.noise = "*death";   break;
			case "*drown.wav":     this.noise = "*drown";   break;
			case "*fall1.wav":     this.noise = "*fall";    break;
			case "*falling1.wav":  this.noise = "*falling"; break;
			case "*gasp.wav":      this.noise = "*gasp";    break;
			case "*jump1.wav":     this.noise = "*jump";    break;
			case "*pain100_1.wav": this.noise = "*pain100"; break;
			case "*pain25_1.wav":  this.noise = "*pain25";  break;
			case "*pain50_1.wav":  this.noise = "*pain50";  break;
			case "*pain75_1.wav":  this.noise = "*pain75";  break;
			case "*taunt.wav":     this.noise = "*taunt";   break;
		}
	}
	else
		precache_sound(this.noise);

	if(!this.atten)
	{
		if (this.spawnflags == SPEAKER_GLOBAL // Q3 looped and activator sounds are never global
		&& (!this.wait || !this.rnd)) // nor are randomly auto-triggering ones
		{
			if (!Q3COMPAT_COMMON)
				LOG_WARN("target_speaker uses legacy spawnflag GLOBAL (BIT(2)), please set atten to -1 instead");
		}
		else
		{
			if (this.targetname != ""
			&& !(this.spawnflags & (SPEAKER_LOOPED_ON | SPEAKER_LOOPED_OFF)))
				this.atten = ATTEN_NORM;
			else
				this.atten = ATTEN_IDLE;
		}
	}
	else if(this.atten < 0)
		this.atten = 0;

	if(!this.volume)
		this.volume = 1;

	// In Q3 setting "random" + "wait" enables the auto-triggering feature,
	// normal triggering is possible as well.
	// Controlled by SVQC thinking so everyone hears it at the same time (unlike in Q3).
	if (this.wait && this.rnd
	&& !(this.spawnflags & (SPEAKER_LOOPED_ON | SPEAKER_LOOPED_OFF)))
	{
		setthink(this, target_speaker_think);
		this.nextthink = time + 5 + this.rnd * crandom(); // Q3 just plays it immediately
	}

	if(this.targetname != "")
	{
		this.use = target_speaker_use;
		if (this.spawnflags & (SPEAKER_LOOPED_ON | SPEAKER_LOOPED_OFF))
		{
			this.reset = target_speaker_reset;
			target_speaker_reset(this);
			Net_LinkEntity(this, false, 0, target_speaker_send);
		}
	}
	else if(this.spawnflags & SPEAKER_LOOPED_ON)
	{
		ambientsound (this.origin, this.noise, VOL_BASE * this.volume, this.atten);
		delete(this);
	}
	else if(this.spawnflags & SPEAKER_LOOPED_OFF)
	{
		objerror(this, "This sound entity can never be activated");
	}
	else if ((!this.wait || !this.rnd) && !q3compat)
	{
		// Quake/Nexuiz fallback
		ambientsound (this.origin, this.noise, VOL_BASE * this.volume, this.atten);
		delete(this);
	}
}

#elifdef CSQC
void target_speaker_think(entity this)
{
	if (getsoundtime(this, CH_AMBIENT_SINGLE) == -1)
	{
		sound7(this, CH_AMBIENT_SINGLE, this.noise, VOL_BASE * this.volume, this.atten, 0, 0);
		this.nextthink = time + soundlength(this.noise);
	}
	else
		this.nextthink = time;
}

NET_HANDLE(ENT_CLIENT_SPEAKER, bool isnew)
{
	float sf = ReadByte();

	if (sf & SF_TRIGGER_INIT)
	{
		setorigin(this, ReadVector());
		this.noise = strzone(ReadString());
		this.volume = ReadFloat();
		this.atten = ReadFloat();

		setthink(this, target_speaker_think);
	}

	if (sf & SF_TRIGGER_ENABLE)
		target_speaker_think(this);
	else
		this.nextthink = 0;

	return true;
}
#endif
