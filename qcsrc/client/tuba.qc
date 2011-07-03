#define TUBA_STARTNOTE(n) strcat((checkextension("DP_SND_SETPARAMS") ? "weapons/tuba_loopnote" : "weapons/tuba_note"), ftos(n), ".wav")
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
		sound(self, CH_SHOTS_SINGLE, "misc/null.wav", 0, 0);
		remove(self);
	}
	else
		sound(self, CH_SHOTS_SINGLE, "", self.cnt, self.attenuate * autocvar_g_balance_tuba_attenuation);
}

void Ent_TubaNote_UpdateSound()
{
	self.enemy.cnt = bound(0, VOL_BASE * autocvar_g_balance_tuba_volume, 1);
	self.enemy.count = self.enemy.cnt;
	sound(self.enemy, CH_SHOTS_SINGLE, TUBA_STARTNOTE(self.cnt), self.enemy.cnt, self.enemy.attenuate * autocvar_g_balance_tuba_attenuation);
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
	for(i = -18; i <= +27; ++i)
	{
		precache_sound(TUBA_STARTNOTE(i));
	}
	//precache_sound(""); // we want to change volume of existing sounds
}
