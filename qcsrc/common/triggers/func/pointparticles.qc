#ifdef SVQC
// NOTE: also contains func_sparks

float pointparticles_SendEntity(entity to, float fl)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_POINTPARTICLES);

	// optional features to save space
	fl = fl & 0x0F;
	if(self.spawnflags & 2)
		fl |= 0x10; // absolute count on toggle-on
	if(self.movedir != '0 0 0' || self.velocity != '0 0 0')
		fl |= 0x20; // 4 bytes - saves CPU
	if(self.waterlevel || self.count != 1)
		fl |= 0x40; // 4 bytes - obscure features almost never used
	if(self.mins != '0 0 0' || self.maxs != '0 0 0')
		fl |= 0x80; // 14 bytes - saves lots of space

	WriteByte(MSG_ENTITY, fl);
	if(fl & 2)
	{
		if(self.state)
			WriteCoord(MSG_ENTITY, self.impulse);
		else
			WriteCoord(MSG_ENTITY, 0); // off
	}
	if(fl & 4)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}
	if(fl & 1)
	{
		if(self.model != "null")
		{
			WriteShort(MSG_ENTITY, self.modelindex);
			if(fl & 0x80)
			{
				WriteCoord(MSG_ENTITY, self.mins_x);
				WriteCoord(MSG_ENTITY, self.mins_y);
				WriteCoord(MSG_ENTITY, self.mins_z);
				WriteCoord(MSG_ENTITY, self.maxs_x);
				WriteCoord(MSG_ENTITY, self.maxs_y);
				WriteCoord(MSG_ENTITY, self.maxs_z);
			}
		}
		else
		{
			WriteShort(MSG_ENTITY, 0);
			if(fl & 0x80)
			{
				WriteCoord(MSG_ENTITY, self.maxs_x);
				WriteCoord(MSG_ENTITY, self.maxs_y);
				WriteCoord(MSG_ENTITY, self.maxs_z);
			}
		}
		WriteShort(MSG_ENTITY, self.cnt);
		if(fl & 0x20)
		{
			WriteShort(MSG_ENTITY, compressShortVector(self.velocity));
			WriteShort(MSG_ENTITY, compressShortVector(self.movedir));
		}
		if(fl & 0x40)
		{
			WriteShort(MSG_ENTITY, self.waterlevel * 16.0);
			WriteByte(MSG_ENTITY, self.count * 16.0);
		}
		WriteString(MSG_ENTITY, self.noise);
		if(self.noise != "")
		{
			WriteByte(MSG_ENTITY, floor(self.atten * 64));
			WriteByte(MSG_ENTITY, floor(self.volume * 255));
		}
		WriteString(MSG_ENTITY, self.bgmscript);
		if(self.bgmscript != "")
		{
			WriteByte(MSG_ENTITY, floor(self.bgmscriptattack * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptdecay * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptsustain * 255));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptrelease * 64));
		}
	}
	return 1;
}

void pointparticles_use()
{
	self.state = !self.state;
	self.SendFlags |= 2;
}

void pointparticles_think()
{
	if(self.origin != self.oldorigin)
	{
		self.SendFlags |= 4;
		self.oldorigin = self.origin;
	}
	self.nextthink = time;
}

void pointparticles_reset()
{
	if(self.spawnflags & 1)
		self.state = 1;
	else
		self.state = 0;
}

void spawnfunc_func_pointparticles()
{
	if(self.model != "")
		setmodel(self, self.model);
	if(self.noise != "")
		precache_sound (self.noise);

	if(!self.bgmscriptsustain)
		self.bgmscriptsustain = 1;
	else if(self.bgmscriptsustain < 0)
		self.bgmscriptsustain = 0;

	if(!self.atten)
		self.atten = ATTEN_NORM;
	else if(self.atten < 0)
		self.atten = 0;
	if(!self.volume)
		self.volume = 1;
	if(!self.count)
		self.count = 1;
	if(!self.impulse)
		self.impulse = 1;

	if(!self.modelindex)
	{
		setorigin(self, self.origin + self.mins);
		setsize(self, '0 0 0', self.maxs - self.mins);
	}
	if(!self.cnt)
		self.cnt = particleeffectnum(self.mdl);

	Net_LinkEntity(self, (self.spawnflags & 4), 0, pointparticles_SendEntity);

	IFTARGETED
	{
		self.use = pointparticles_use;
		self.reset = pointparticles_reset;
		self.reset();
	}
	else
		self.state = 1;
	self.think = pointparticles_think;
	self.nextthink = time;
}

void spawnfunc_func_sparks()
{
	// self.cnt is the amount of sparks that one burst will spawn
	if(self.cnt < 1) {
		self.cnt = 25.0; // nice default value
	}

	// self.wait is the probability that a sparkthink will spawn a spark shower
	// range: 0 - 1, but 0 makes little sense, so...
	if(self.wait < 0.05) {
		self.wait = 0.25; // nice default value
	}

	self.count = self.cnt;
	self.mins = '0 0 0';
	self.maxs = '0 0 0';
	self.velocity = '0 0 -1';
	self.mdl = "TE_SPARK";
	self.impulse = 10 * self.wait; // by default 2.5/sec
	self.wait = 0;
	self.cnt = 0; // use mdl

	spawnfunc_func_pointparticles();
}
#endif
