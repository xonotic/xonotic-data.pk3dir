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
	soundto(MSG_ONE, this, CH_TRIGGER, snd, VOL_BASE * this.volume, this.atten);
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
	if(this.spawnflags & 3)
		this.use1 = target_speaker_use_off;
}
void target_speaker_use_off(entity this, entity actor, entity trigger)
{
	sound(this, CH_TRIGGER_SINGLE, SND_Null, VOL_BASE * this.volume, this.atten);
	this.use1 = target_speaker_use_on;
}
void target_speaker_reset(entity this)
{
	if(this.spawnflags & 1) // LOOPED_ON
	{
		if(this.use1 == target_speaker_use_on)
			target_speaker_use_on(this, NULL, NULL);
	}
	else if(this.spawnflags & 2)
	{
		if(this.use1 == target_speaker_use_off)
			target_speaker_use_off(this, NULL, NULL);
	}
}

spawnfunc(target_speaker)
{
	// TODO: "*" prefix to sound file name
	// TODO: wait and random (just, HOW? random is not a field)
	if(self.noise)
		precache_sound (self.noise);

	if(!self.atten && !(self.spawnflags & 4))
	{
		IFTARGETED
			self.atten = ATTEN_NORM;
		else
			self.atten = ATTEN_STATIC;
	}
	else if(self.atten < 0)
		self.atten = 0;

	if(!self.volume)
		self.volume = 1;

	IFTARGETED
	{
		if(self.spawnflags & 8) // ACTIVATOR
			self.use1 = target_speaker_use_activator;
		else if(self.spawnflags & 1) // LOOPED_ON
		{
			target_speaker_use_on(self, NULL, NULL);
			self.reset = target_speaker_reset;
		}
		else if(self.spawnflags & 2) // LOOPED_OFF
		{
			self.use1 = target_speaker_use_on;
			self.reset = target_speaker_reset;
		}
		else
			self.use1 = target_speaker_use_on;
	}
	else if(self.spawnflags & 1) // LOOPED_ON
	{
		ambientsound (self.origin, self.noise, VOL_BASE * self.volume, self.atten);
		remove(self);
	}
	else if(self.spawnflags & 2) // LOOPED_OFF
	{
		objerror("This sound entity can never be activated");
	}
	else
	{
		// Quake/Nexuiz fallback
		ambientsound (self.origin, self.noise, VOL_BASE * self.volume, self.atten);
		remove(self);
	}
}
#endif
