#ifdef SVQC
// TODO add a way to do looped sounds with sound(); then complete this entity
void target_speaker_use_off();
void target_speaker_use_activator()
{SELFPARAM();
	if (!IS_REAL_CLIENT(activator))
		return;
	string snd;
	if(substring(self.noise, 0, 1) == "*")
	{
		var .string sample = GetVoiceMessageSampleField(substring(self.noise, 1, -1));
		if(GetPlayerSoundSampleField_notFound)
			snd = SND(Null);
		else if(activator.(sample) == "")
			snd = SND(Null);
		else
		{
			tokenize_console(activator.(sample));
			float n;
			n = stof(argv(1));
			if(n > 0)
				snd = strcat(argv(0), ftos(floor(random() * n + 1)), ".wav"); // randomization
			else
				snd = strcat(argv(0), ".wav"); // randomization
		}
	}
	else
		snd = self.noise;
	msg_entity = activator;
	soundto(MSG_ONE, self, CH_TRIGGER, snd, VOL_BASE * self.volume, self.atten);
}
void target_speaker_use_on()
{SELFPARAM();
	string snd;
	if(substring(self.noise, 0, 1) == "*")
	{
		var .string sample = GetVoiceMessageSampleField(substring(self.noise, 1, -1));
		if(GetPlayerSoundSampleField_notFound)
			snd = SND(Null);
		else if(activator.(sample) == "")
			snd = SND(Null);
		else
		{
			tokenize_console(activator.(sample));
			float n;
			n = stof(argv(1));
			if(n > 0)
				snd = strcat(argv(0), ftos(floor(random() * n + 1)), ".wav"); // randomization
			else
				snd = strcat(argv(0), ".wav"); // randomization
		}
	}
	else
		snd = self.noise;
	_sound(self, CH_TRIGGER_SINGLE, snd, VOL_BASE * self.volume, self.atten);
	if(self.spawnflags & 3)
		self.use = target_speaker_use_off;
}
void target_speaker_use_off()
{SELFPARAM();
	sound(self, CH_TRIGGER_SINGLE, SND_Null, VOL_BASE * self.volume, self.atten);
	self.use = target_speaker_use_on;
}
void target_speaker_reset()
{SELFPARAM();
	if(self.spawnflags & 1) // LOOPED_ON
	{
		if(self.use == target_speaker_use_on)
			target_speaker_use_on();
	}
	else if(self.spawnflags & 2)
	{
		if(self.use == target_speaker_use_off)
			target_speaker_use_off();
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
			self.use = target_speaker_use_activator;
		else if(self.spawnflags & 1) // LOOPED_ON
		{
			target_speaker_use_on();
			self.reset = target_speaker_reset;
		}
		else if(self.spawnflags & 2) // LOOPED_OFF
		{
			self.use = target_speaker_use_on;
			self.reset = target_speaker_reset;
		}
		else
			self.use = target_speaker_use_on;
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
