#ifdef CSQC
	#include "../../../client/particles.qh"
#endif

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
		self.cnt = _particleeffectnum(self.mdl);

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
#elif defined(CSQC)

void Draw_PointParticles()
{
	float n, i, fail;
	vector p;
	vector sz;
	vector o;
	o = self.origin;
	sz = self.maxs - self.mins;
	n = doBGMScript(self);
	if(self.absolute == 2)
	{
		if(n >= 0)
			n = self.just_toggled ? self.impulse : 0;
		else
			n = self.impulse * drawframetime;
	}
	else
	{
		n *= self.impulse * drawframetime;
		if(self.just_toggled)
			if(n < 1)
				n = 1;
	}
	if(n == 0)
		return;
	fail = 0;
	for(i = random(); i <= n && fail <= 64*n; ++i)
	{
		p = o + self.mins;
		p.x += random() * sz.x;
		p.y += random() * sz.y;
		p.z += random() * sz.z;
		if(WarpZoneLib_BoxTouchesBrush(p, p, self, world))
		{
			if(self.movedir != '0 0 0')
			{
				traceline(p, p + normalize(self.movedir) * 4096, 0, world);
				p = trace_endpos;
				pointparticles(self.cnt, p, trace_plane_normal * vlen(self.movedir) + self.velocity + randomvec() * self.waterlevel, self.count);
			}
			else
			{
				pointparticles(self.cnt, p, self.velocity + randomvec() * self.waterlevel, self.count);
			}
			if(self.noise != "")
			{
				setorigin(self, p);
				sound(self, CH_AMBIENT, self.noise, VOL_BASE * self.volume, self.atten);
			}
			self.just_toggled = 0;
		}
		else if(self.absolute)
		{
			++fail;
			--i;
		}
	}
	setorigin(self, o);
}

void Ent_PointParticles_Remove()
{
	if(self.noise)
		strunzone(self.noise);
	self.noise = string_null;
	if(self.bgmscript)
		strunzone(self.bgmscript);
	self.bgmscript = string_null;
}

void Ent_PointParticles()
{
	float i;
	vector v;
	int f = ReadByte();
	if(f & 2)
	{
		i = ReadCoord(); // density (<0: point, >0: volume)
		if(i && !self.impulse && self.cnt) // self.cnt check is so it only happens if the ent already existed
			self.just_toggled = 1;
		self.impulse = i;
	}
	if(f & 4)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
	}
	if(f & 1)
	{
		self.modelindex = ReadShort();
		if(f & 0x80)
		{
			if(self.modelindex)
			{
				self.mins_x = ReadCoord();
				self.mins_y = ReadCoord();
				self.mins_z = ReadCoord();
				self.maxs_x = ReadCoord();
				self.maxs_y = ReadCoord();
				self.maxs_z = ReadCoord();
			}
			else
			{
				self.mins    = '0 0 0';
				self.maxs_x = ReadCoord();
				self.maxs_y = ReadCoord();
				self.maxs_z = ReadCoord();
			}
		}
		else
		{
			self.mins = self.maxs = '0 0 0';
		}

		self.cnt = ReadShort(); // effect number

		if(f & 0x20)
		{
			self.velocity = decompressShortVector(ReadShort());
			self.movedir = decompressShortVector(ReadShort());
		}
		else
		{
			self.velocity = self.movedir = '0 0 0';
		}
		if(f & 0x40)
		{
			self.waterlevel = ReadShort() / 16.0;
			self.count = ReadByte() / 16.0;
		}
		else
		{
			self.waterlevel = 0;
			self.count = 1;
		}
		if(self.noise)
			strunzone(self.noise);
		if(self.bgmscript)
			strunzone(self.bgmscript);
		self.noise = strzone(ReadString());
		if(self.noise != "")
		{
			self.atten = ReadByte() / 64.0;
			self.volume = ReadByte() / 255.0;
		}
		self.bgmscript = strzone(ReadString());
		if(self.bgmscript != "")
		{
			self.bgmscriptattack = ReadByte() / 64.0;
			self.bgmscriptdecay = ReadByte() / 64.0;
			self.bgmscriptsustain = ReadByte() / 255.0;
			self.bgmscriptrelease = ReadByte() / 64.0;
		}
		BGMScript_InitEntity(self);
	}

	if(f & 2)
	{
		self.absolute = (self.impulse >= 0);
		if(!self.absolute)
		{
			v = self.maxs - self.mins;
			self.impulse *= -v.x * v.y * v.z / 262144; // relative: particles per 64^3 cube
		}
	}

	if(f & 0x10)
		self.absolute = 2;

	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.solid = SOLID_NOT;
	self.draw = Draw_PointParticles;
	self.entremove = Ent_PointParticles_Remove;
}
#endif
