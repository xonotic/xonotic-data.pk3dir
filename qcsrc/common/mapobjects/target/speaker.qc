#include "speaker.qh"
#ifdef SVQC
// TODO add a way to do looped sounds with sound(); then complete this entity
void target_speaker_use_off(entity this, entity actor, entity trigger);
void target_speaker_use_activator(entity this, entity actor, entity trigger)
{
	if (!IS_REAL_CLIENT(actor))
		return;
	string snd;
	if(substring(this.noise, 0, 1) == "*")
	{
		var .string sample = GetVoiceMessageSampleField(substring(this.noise, 1, -1));
		if(GetPlayerSoundSampleField_notFound)
			snd = SND(Null);
		else if(actor.(sample) == "")
			snd = SND(Null);
		else
		{
			tokenize_console(actor.(sample));
			float n;
			n = stof(argv(1));
			if(n > 0)
				snd = strcat(argv(0), ftos(floor(random() * n + 1)), ".wav"); // randomization
			else
				snd = strcat(argv(0), ".wav"); // randomization
		}
	}
	else
		snd = this.noise;
	msg_entity = actor;
	soundto(MSG_ONE, this, CH_TRIGGER, snd, VOL_BASE * this.volume, this.atten, 0);
}
void target_speaker_use_on(entity this, entity actor, entity trigger)
{
	string snd;
	if(substring(this.noise, 0, 1) == "*")
	{
		var .string sample = GetVoiceMessageSampleField(substring(this.noise, 1, -1));
		if(GetPlayerSoundSampleField_notFound)
			snd = SND(Null);
		else if(actor.(sample) == "")
			snd = SND(Null);
		else
		{
			tokenize_console(actor.(sample));
			float n;
			n = stof(argv(1));
			if(n > 0)
				snd = strcat(argv(0), ftos(floor(random() * n + 1)), ".wav"); // randomization
			else
				snd = strcat(argv(0), ".wav"); // randomization
		}
	}
	else
		snd = this.noise;
	_sound(this, CH_TRIGGER_SINGLE, snd, VOL_BASE * this.volume, this.atten);
	if(this.spawnflags & (SPEAKER_LOOPED_ON + SPEAKER_LOOPED_OFF))
		this.use = target_speaker_use_off;
}
void target_speaker_use_off(entity this, entity actor, entity trigger)
{
	sound(this, CH_TRIGGER_SINGLE, SND_Null, VOL_BASE * this.volume, this.atten);
	this.use = target_speaker_use_on;
}
void target_speaker_reset(entity this)
{
	if(this.spawnflags & SPEAKER_LOOPED_ON)
	{
		if(this.use == target_speaker_use_on)
			target_speaker_use_on(this, NULL, NULL);
	}
	else if(this.spawnflags & SPEAKER_LOOPED_OFF)
	{
		if(this.use == target_speaker_use_off)
			target_speaker_use_off(this, NULL, NULL);
	}
}

spawnfunc(target_speaker)
{
	// TODO: "*" prefix to sound file name
	// TODO: wait and random (just, HOW? random is not a field)
	if(this.noise)
		precache_sound (this.noise);

	if(!this.atten && (this.spawnflags & SPEAKER_GLOBAL) && !(this.spawnflags & 3)) // special check for quake 3: looped sounds are never global
	{
		if (!Q3COMPAT_COMMON)
			LOG_WARN("target_speaker uses legacy spawnflag GLOBAL (BIT(2)), please set atten to -1 instead");
		this.atten = -1;
	}

	if(!this.atten)
	{
		if(this.targetname && this.targetname != "")
			this.atten = ATTEN_NORM;
		else
			this.atten = ATTEN_STATIC;
	}
	else if(this.atten < 0)
		this.atten = 0;

	if(!this.volume)
		this.volume = 1;

	if(this.targetname && this.targetname != "")
	{
		if(this.spawnflags & SPEAKER_ACTIVATOR)
			this.use = target_speaker_use_activator;
		else if(this.spawnflags & SPEAKER_LOOPED_ON)
		{
			target_speaker_use_on(this, NULL, NULL);
			this.reset = target_speaker_reset;
		}
		else if(this.spawnflags & SPEAKER_LOOPED_OFF)
		{
			this.use = target_speaker_use_on;
			this.reset = target_speaker_reset;
		}
		else
			this.use = target_speaker_use_on;
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
	else
	{
		// Quake/Nexuiz fallback
		ambientsound (this.origin, this.noise, VOL_BASE * this.volume, this.atten);
		delete(this);
	}
}
#endif
