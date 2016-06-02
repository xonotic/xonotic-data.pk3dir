REGISTER_NET_LINKED(ENT_CLIENT_POINTPARTICLES)

#ifdef SVQC
// NOTE: also contains func_sparks

bool pointparticles_SendEntity(entity this, entity to, float fl)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_POINTPARTICLES);

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
		WriteString(MSG_ENTITY, self.mdl);
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

void pointparticles_use(entity this, entity actor, entity trigger)
{
	this.state = !this.state;
	this.SendFlags |= 2;
}

void pointparticles_think(entity this)
{
	if(self.origin != self.oldorigin)
	{
		self.SendFlags |= 4;
		self.oldorigin = self.origin;
	}
	self.nextthink = time;
}

void pointparticles_reset(entity this)
{
	if(this.spawnflags & 1)
		this.state = 1;
	else
		this.state = 0;
}

spawnfunc(func_pointparticles)
{
	if(this.model != "") { precache_model(this.model); _setmodel(this, this.model); }
	if(this.noise != "") precache_sound(this.noise);
	if(this.mdl != "") this.cnt = 0; // use a good handler

	if(!this.bgmscriptsustain) this.bgmscriptsustain = 1;
	else if(this.bgmscriptsustain < 0) this.bgmscriptsustain = 0;

	if(!this.atten) this.atten = ATTEN_NORM;
	else if(this.atten < 0) this.atten = 0;
	if(!this.volume) this.volume = 1;
	if(!this.count) this.count = 1;
	if(!this.impulse) this.impulse = 1;

	if(!this.modelindex)
	{
		setorigin(this, this.origin + this.mins);
		setsize(this, '0 0 0', this.maxs - this.mins);
	}
	//if(!this.cnt) this.cnt = _particleeffectnum(this.mdl);

	Net_LinkEntity(this, (this.spawnflags & 4), 0, pointparticles_SendEntity);

	IFTARGETED
	{
		this.use = pointparticles_use;
		this.reset = pointparticles_reset;
		this.reset(this);
	}
	else
		this.state = 1;
	setthink(this, pointparticles_think);
	this.nextthink = time;
}

spawnfunc(func_sparks)
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

	spawnfunc_func_pointparticles(this);
}
#elif defined(CSQC)

.int dphitcontentsmask;

entityclass(PointParticles);
class(PointParticles) .int cnt; // effect number
class(PointParticles) .vector velocity; // particle velocity
class(PointParticles) .float waterlevel; // direction jitter
class(PointParticles) .int count; // count multiplier
class(PointParticles) .int impulse; // density
class(PointParticles) .string noise; // sound
class(PointParticles) .float atten;
class(PointParticles) .float volume;
class(PointParticles) .float absolute; // 1 = count per second is absolute, 2 = only spawn at toggle
class(PointParticles) .vector movedir; // trace direction
class(PointParticles) .float glow_color; // palette index

void Draw_PointParticles(entity this)
{
	float n, i, fail;
	vector p;
	vector sz;
	vector o;
	o = this.origin;
	sz = this.maxs - this.mins;
	n = doBGMScript(this);
	if(this.absolute == 2)
	{
		if(n >= 0)
			n = this.just_toggled ? this.impulse : 0;
		else
			n = this.impulse * drawframetime;
	}
	else
	{
		n *= this.impulse * drawframetime;
		if(this.just_toggled)
			if(n < 1)
				n = 1;
	}
	if(n == 0)
		return;
	fail = 0;
	for(i = random(); i <= n && fail <= 64*n; ++i)
	{
		p = o + this.mins;
		p.x += random() * sz.x;
		p.y += random() * sz.y;
		p.z += random() * sz.z;
		if(WarpZoneLib_BoxTouchesBrush(p, p, this, world))
		{
			if(this.movedir != '0 0 0')
			{
				traceline(p, p + normalize(this.movedir) * 4096, 0, world);
				p = trace_endpos;
				int eff_num;
				if(this.cnt)
					eff_num = this.cnt;
				else
					eff_num = _particleeffectnum(this.mdl);
				__pointparticles(eff_num, p, trace_plane_normal * vlen(this.movedir) + this.velocity + randomvec() * this.waterlevel, this.count);
			}
			else
			{
				int eff_num;
				if(this.cnt)
					eff_num = this.cnt;
				else
					eff_num = _particleeffectnum(this.mdl);
				__pointparticles(eff_num, p, this.velocity + randomvec() * this.waterlevel, this.count);
			}
			if(this.noise != "")
			{
				setorigin(this, p);
				_sound(this, CH_AMBIENT, this.noise, VOL_BASE * this.volume, this.atten);
			}
			this.just_toggled = 0;
		}
		else if(this.absolute)
		{
			++fail;
			--i;
		}
	}
	setorigin(this, o);
}

void Ent_PointParticles_Remove(entity this)
{
	if(this.noise)
		strunzone(this.noise);
	this.noise = string_null;
	if(this.bgmscript)
		strunzone(this.bgmscript);
	this.bgmscript = string_null;
	if(this.mdl)
		strunzone(this.mdl);
	this.mdl = string_null;
}

NET_HANDLE(ENT_CLIENT_POINTPARTICLES, bool isnew)
{
	float i;
	vector v;
	int f = ReadByte();
	if(f & 2)
	{
		i = ReadCoord(); // density (<0: point, >0: volume)
		if(i && !this.impulse && (this.cnt || this.mdl)) // this.cnt check is so it only happens if the ent already existed
			this.just_toggled = 1;
		this.impulse = i;
	}
	if(f & 4)
	{
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
	}
	if(f & 1)
	{
		this.modelindex = ReadShort();
		if(f & 0x80)
		{
			if(this.modelindex)
			{
				this.mins_x = ReadCoord();
				this.mins_y = ReadCoord();
				this.mins_z = ReadCoord();
				this.maxs_x = ReadCoord();
				this.maxs_y = ReadCoord();
				this.maxs_z = ReadCoord();
			}
			else
			{
				this.mins    = '0 0 0';
				this.maxs_x = ReadCoord();
				this.maxs_y = ReadCoord();
				this.maxs_z = ReadCoord();
			}
		}
		else
		{
			this.mins = this.maxs = '0 0 0';
		}

		this.cnt = ReadShort(); // effect number
		this.mdl = strzone(ReadString()); // effect string

		if(f & 0x20)
		{
			this.velocity = decompressShortVector(ReadShort());
			this.movedir = decompressShortVector(ReadShort());
		}
		else
		{
			this.velocity = this.movedir = '0 0 0';
		}
		if(f & 0x40)
		{
			this.waterlevel = ReadShort() / 16.0;
			this.count = ReadByte() / 16.0;
		}
		else
		{
			this.waterlevel = 0;
			this.count = 1;
		}
		if(this.noise)
			strunzone(this.noise);
		if(this.bgmscript)
			strunzone(this.bgmscript);
		this.noise = strzone(ReadString());
		if(this.noise != "")
		{
			this.atten = ReadByte() / 64.0;
			this.volume = ReadByte() / 255.0;
		}
		this.bgmscript = strzone(ReadString());
		if(this.bgmscript != "")
		{
			this.bgmscriptattack = ReadByte() / 64.0;
			this.bgmscriptdecay = ReadByte() / 64.0;
			this.bgmscriptsustain = ReadByte() / 255.0;
			this.bgmscriptrelease = ReadByte() / 64.0;
		}
		BGMScript_InitEntity(this);
	}

	return = true;

	if(f & 2)
	{
		this.absolute = (this.impulse >= 0);
		if(!this.absolute)
		{
			v = this.maxs - this.mins;
			this.impulse *= -v.x * v.y * v.z / 262144; // relative: particles per 64^3 cube
		}
	}

	if(f & 0x10)
		this.absolute = 2;

	setorigin(this, this.origin);
	setsize(this, this.mins, this.maxs);
	this.solid = SOLID_NOT;
	this.draw = Draw_PointParticles;
	this.entremove = Ent_PointParticles_Remove;
}
#endif
