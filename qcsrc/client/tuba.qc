#define TUBA_MIN -18
#define TUBA_MAX  27

#define TUBA_STARTNOTE(n) strcat("weapons/tuba_loopnote", ftos(n), ".wav")
.float note; // note
.float attenuate; // if set, attenuate it
.float cnt; // current volume
.float count; // initial volume

float Tuba_PitchStep;

void tubasound(entity e, float restart)
{
	string snd1;

	snd1 = string_null;

	if(Tuba_PitchStep)
	{
		string snd2;
		float f1, f2;
		float p1, p2;
		float m;

		f1 = 1;
		p1 = 1;
		snd2 = string_null;
		f2 = 0;
		p2 = 1;

		m = mod(e.note, Tuba_PitchStep);
		if(m)
		{
			if(e.note - m < TUBA_MIN)
			{
				if(restart)
					snd1 = TUBA_STARTNOTE(e.note - m + Tuba_PitchStep);
				p1 = pow(2.0, (m - Tuba_PitchStep) / 12.0);
			}
			else if(e.note - m + Tuba_PitchStep > TUBA_MAX)
			{
				if(restart)
					snd1 = TUBA_STARTNOTE(e.note - m);
				p1 = pow(2.0, m / 12.0);
			}
			else
			{
				if(restart)
					snd1 = TUBA_STARTNOTE(e.note - m);
				f1 = cos(M_PI_2 * m / Tuba_PitchStep);
				p1 = pow(2.0, m / 12.0);
				if(restart)
					snd2 = TUBA_STARTNOTE(e.note - m + Tuba_PitchStep);
				f2 = sin(M_PI_2 * m / Tuba_PitchStep);
				p2 = pow(2.0, (m - Tuba_PitchStep) / 12.0);
			}
		}
		else
		{
			if(restart)
				snd1 = TUBA_STARTNOTE(e.note);
		}

		sound7(e, CH_TUBA, snd1, e.cnt * f1, e.attenuate * autocvar_g_balance_tuba_attenuation, 100 * p1, 0);
		if(f2)
			sound7(e.enemy, CH_TUBA, snd2, e.cnt * f2, e.attenuate * autocvar_g_balance_tuba_attenuation, 100 * p2, 0);
	}
	else
	{
		if(restart)
			snd1 = TUBA_STARTNOTE(e.note);
		sound(e, CH_TUBA, snd1, e.cnt, e.attenuate * autocvar_g_balance_tuba_attenuation);
	}
}

void Ent_TubaNote_Think()
{
	float f;
	f = autocvar_g_balance_tuba_fadetime;
	if(f > 0)
		self.cnt -= frametime * self.count / f;
	else
		self.cnt = 0;
	self.nextthink = time;
	if(self.cnt <= 0)
	{
		sound(self, CH_TUBA, "misc/null.wav", 0, 0);
		if(self.enemy)
		{
			sound(self.enemy, CH_TUBA, "misc/null.wav", 0, 0);
			remove(self.enemy);
		}
		remove(self);
	}
	else
	{
		tubasound(self, 0);
	}
}

void Ent_TubaNote_UpdateSound()
{
	self.enemy.cnt = bound(0, VOL_BASE * autocvar_g_balance_tuba_volume, 1);
	self.enemy.count = self.enemy.cnt;
	self.enemy.note = self.note;
	tubasound(self.enemy, 1);
}

void Ent_TubaNote_StopSound()
{
	self.enemy.nextthink = time;
	self.enemy = world;
}

void Ent_TubaNote(float bIsNew)
{
	float f, n;
	f = ReadByte();
	n = floor(f / 2) - 42;
	if(n != self.note || bIsNew)
		if(self.enemy)
			Ent_TubaNote_StopSound();
	if(!self.enemy)
	{
		self.enemy = spawn();
		self.enemy.classname = "tuba_note";
		if(Tuba_PitchStep)
		{
			self.enemy.enemy = spawn();
			self.enemy.enemy.classname = "tuba_note_2";
		}
		bIsNew = TRUE;
	}
	if(f & 1)
	{
		self.enemy.origin_x = ReadCoord();
		self.enemy.origin_y = ReadCoord();
		self.enemy.origin_z = ReadCoord();
		setorigin(self.enemy, self.enemy.origin);
		self.enemy.attenuate = ReadByte();
		if(self.enemy.enemy)
			setorigin(self.enemy.enemy, self.enemy.origin);
	}
	self.think = Ent_TubaNote_StopSound;
	self.entremove = Ent_TubaNote_StopSound;
	self.enemy.think = Ent_TubaNote_Think;
	self.enemy.nextthink = time + 10;
	if(bIsNew)
	{
		self.note = n;
		Ent_TubaNote_UpdateSound();
	}
}

void Tuba_Precache()
{
	float i;
	Tuba_PitchStep = autocvar_g_balance_tuba_pitchstep;
	if(Tuba_PitchStep)
	{
		if(!checkextension("DP_SND_SOUND7_WIP2") && !checkextension("DP_SND_SOUND7"))
		{
			print("^1NOTE:^7 requested pitch shifting, but not supported by this engine build\n");
			Tuba_PitchStep = 0;
		}
	}
	for(i = TUBA_MIN; i <= TUBA_MAX; ++i)
	{
		if(!Tuba_PitchStep || (mod(i, Tuba_PitchStep) == 0))
			precache_sound(TUBA_STARTNOTE(i));
	}
}
