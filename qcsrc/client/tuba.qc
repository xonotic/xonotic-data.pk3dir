#define TUBA_STARTNOTE(n) strcat("weapons/tuba_loopnote", ftos(n), ".wav")
.float cnt; // note
.float attenuate; // if set, attenuate it

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
		remove(self);
	}
	else
		sound(self, CH_TUBA, "", self.cnt, self.attenuate * autocvar_g_balance_tuba_attenuation);
}

void Ent_TubaNote_UpdateSound()
{
	self.enemy.cnt = bound(0, VOL_BASE * autocvar_g_balance_tuba_volume, 1);
	self.enemy.count = self.enemy.cnt;
#ifdef PITCHSHIFT
	sound7(self.enemy, CH_TUBA, TUBA_STARTNOTE(0), self.enemy.cnt, self.enemy.attenuate * autocvar_g_balance_tuba_attenuation, 100 * pow(2.0, self.cnt / 12.0), 0);
#else
	sound(self.enemy, CH_TUBA, TUBA_STARTNOTE(self.cnt), self.enemy.cnt, self.enemy.attenuate * autocvar_g_balance_tuba_attenuation);
#endif
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
	if(n != self.cnt || bIsNew)
		if(self.enemy)
			Ent_TubaNote_StopSound();
	if(!self.enemy)
	{
		self.enemy = spawn();
		self.enemy.classname = "tuba_note";
		bIsNew = TRUE;
	}
	if(f & 1)
	{
		self.enemy.origin_x = ReadCoord();
		self.enemy.origin_y = ReadCoord();
		self.enemy.origin_z = ReadCoord();
		setorigin(self.enemy, self.enemy.origin);
		self.enemy.attenuate = ReadByte();
	}
	self.think = Ent_TubaNote_StopSound;
	self.entremove = Ent_TubaNote_StopSound;
	self.enemy.think = Ent_TubaNote_Think;
	self.enemy.nextthink = time + 10;
	if(bIsNew)
	{
		self.cnt = n;
		Ent_TubaNote_UpdateSound();
	}
}

void Tuba_Precache()
{
	float i;
#ifdef PITCHSHIFT
	precache_sound(TUBA_STARTNOTE(0));
#else
	for(i = -18; i <= +27; ++i)
	{
		precache_sound(TUBA_STARTNOTE(i));
	}
#endif
	//precache_sound(""); // we want to change volume of existing sounds
}
