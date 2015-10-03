#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "../../../server/_all.qh"
    #include "../../constants.qh"
    #include "../../../server/constants.qh"
    #include "../../../server/defs.qh"
#endif

#ifdef SVQC

// values:
//   volume
//   noise
//   targetname
//   lifetime
//   fade_time
//   fade_rate
// when triggered, the music is overridden for activator until lifetime (or forever, if lifetime is 0)
// when targetname is not set, THIS ONE is default
void target_music_sendto(float to, float is)
{SELFPARAM();
	WriteByte(to, SVC_TEMPENTITY);
	WriteByte(to, TE_CSQC_TARGET_MUSIC);
	WriteShort(to, num_for_edict(self));
	WriteByte(to, self.volume * 255.0 * is);
	WriteByte(to, self.fade_time * 16.0);
	WriteByte(to, self.fade_rate * 16.0);
	WriteByte(to, self.lifetime);
	WriteString(to, self.noise);
}
void target_music_reset()
{SELFPARAM();
	if(self.targetname == "")
		target_music_sendto(MSG_ALL, 1);
}
void target_music_use()
{
	if(!activator)
		return;
	if(IS_REAL_CLIENT(activator))
	{
		msg_entity = activator;
		target_music_sendto(MSG_ONE, 1);
	}
	entity head;
	FOR_EACH_SPEC(head) if(head.enemy == activator) { msg_entity = head; target_music_sendto(MSG_ONE, 1); }
}
spawnfunc(target_music)
{
	self.use = target_music_use;
	self.reset = target_music_reset;
	if(!self.volume)
		self.volume = 1;
	if(self.targetname == "")
		target_music_sendto(MSG_INIT, 1);
	else
		target_music_sendto(MSG_INIT, 0);
}
void TargetMusic_RestoreGame()
{SELFPARAM();
	for(entity e = world; (e = find(e, classname, "target_music")); )
	{
		setself(e);
		if(self.targetname == "")
			target_music_sendto(MSG_INIT, 1);
		else
			target_music_sendto(MSG_INIT, 0);
	}
}
// values:
//   volume
//   noise
//   targetname
//   fade_time
// spawnflags:
//   1 = START_OFF
// when triggered, it is disabled/enabled for everyone
float trigger_music_SendEntity(entity to, float sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_TRIGGER_MUSIC);
	sf &= ~0x80;
	if(self.cnt)
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 4)
	{
		WriteCoord(MSG_ENTITY, self.origin.x);
		WriteCoord(MSG_ENTITY, self.origin.y);
		WriteCoord(MSG_ENTITY, self.origin.z);
	}
	if(sf & 1)
	{
		if(self.model != "null")
		{
			WriteShort(MSG_ENTITY, self.modelindex);
			WriteCoord(MSG_ENTITY, self.mins.x);
			WriteCoord(MSG_ENTITY, self.mins.y);
			WriteCoord(MSG_ENTITY, self.mins.z);
			WriteCoord(MSG_ENTITY, self.maxs.x);
			WriteCoord(MSG_ENTITY, self.maxs.y);
			WriteCoord(MSG_ENTITY, self.maxs.z);
		}
		else
		{
			WriteShort(MSG_ENTITY, 0);
			WriteCoord(MSG_ENTITY, self.maxs.x);
			WriteCoord(MSG_ENTITY, self.maxs.y);
			WriteCoord(MSG_ENTITY, self.maxs.z);
		}
		WriteByte(MSG_ENTITY, self.volume * 255.0);
		WriteByte(MSG_ENTITY, self.fade_time * 16.0);
		WriteByte(MSG_ENTITY, self.fade_rate * 16.0);
		WriteString(MSG_ENTITY, self.noise);
	}
	return 1;
}
void trigger_music_reset()
{SELFPARAM();
	self.cnt = !(self.spawnflags & 1);
	self.SendFlags |= 0x80;
}
void trigger_music_use()
{SELFPARAM();
	self.cnt = !self.cnt;
	self.SendFlags |= 0x80;
}
spawnfunc(trigger_music)
{
	if(self.model != "")
		_setmodel(self, self.model);
	if(!self.volume)
		self.volume = 1;
	if(!self.modelindex)
	{
		setorigin(self, self.origin + self.mins);
		setsize(self, '0 0 0', self.maxs - self.mins);
	}
	trigger_music_reset();

	self.use = trigger_music_use;
	self.reset = trigger_music_reset;

	Net_LinkEntity(self, false, 0, trigger_music_SendEntity);
}
#elif defined(CSQC)

void TargetMusic_Advance()
{
	// run AFTER all the thinks!
	entity best, e;
	float vol, vol0;
	best = music_default;
	if(music_target && time < music_target.lifetime)
		best = music_target;
	if(music_trigger)
		best = music_trigger;
	for(e = world; (e = findfloat(e, enttype, ENT_CLIENT_TRIGGER_MUSIC)); ) if(e.noise)
	{
		vol0 = e.lastvol;
		if(getsoundtime(e, CH_BGM_SINGLE) < 0)
		{
			vol0 = -1;
		}
		if(e == best)
		{
			// increase volume
			if(e.fade_time > 0)
				e.state = bound(0, e.state + frametime / e.fade_time, 1);
			else
				e.state = 1;
		}
		else
		{
			// decrease volume
			if(e.fade_rate > 0)
				e.state = bound(0, e.state - frametime / e.fade_rate, 1);
			else
				e.state = 0;
		}
		vol = e.state * e.volume * autocvar_bgmvolume;
		if(vol != vol0)
		{
			if(vol0 < 0)
				_sound(e, CH_BGM_SINGLE, e.noise, vol, ATTEN_NONE); // restart
			else
				_sound(e, CH_BGM_SINGLE, "", vol, ATTEN_NONE);
			e.lastvol = vol;
		}
	}
	music_trigger = world;

	if(best)
		bgmtime = getsoundtime(best, CH_BGM_SINGLE);
	else
		bgmtime = gettime(GETTIME_CDTRACK);
}

void Net_TargetMusic()
{
	int id = ReadShort();
	float vol = ReadByte() / 255.0;
	float fai = ReadByte() / 16.0;
	float fao = ReadByte() / 16.0;
	float tim = ReadByte();
	string noi = ReadString();

	entity e;
	for(e = world; (e = findfloat(e, enttype, ENT_CLIENT_TRIGGER_MUSIC)); )
	{
		if(e.count == id)
			break;
	}
	if(!e)
	{
		e = spawn();
		e.enttype = ENT_CLIENT_TRIGGER_MUSIC;
		e.count = id;
	}
	if(e.noise != noi)
	{
		if(e.noise)
			strunzone(e.noise);
		e.noise = strzone(noi);
		precache_sound(e.noise);
		_sound(e, CH_BGM_SINGLE, e.noise, 0, ATTEN_NONE);
		if(getsoundtime(e, CH_BGM_SINGLE) < 0)
		{
			LOG_TRACEF("Cannot initialize sound %s\n", e.noise);
			strunzone(e.noise);
			e.noise = string_null;
		}
	}
	e.volume = vol;
	e.fade_time = fai;
	e.fade_rate = fao;
	if(vol > 0)
	{
		if(tim == 0)
		{
			music_default = e;
			if(!music_disabled)
			{
				e.state = 2;
				cvar_settemp("music_playlist_index", "-1"); // don't use playlists
				localcmd("cd stop\n"); // just in case
				music_disabled = 1;
			}
		}
		else
		{
			music_target = e;
			e.lifetime = time + tim;
		}
	}
}

void Ent_TriggerMusic_Think()
{SELFPARAM();
	if(WarpZoneLib_BoxTouchesBrush(view_origin, view_origin, self, world))
	{
		music_trigger = self;
	}
	self.nextthink = time;
}

void Ent_TriggerMusic_Remove()
{SELFPARAM();
	if(self.noise)
		strunzone(self.noise);
	self.noise = string_null;
}

void Ent_ReadTriggerMusic()
{SELFPARAM();
	int f = ReadByte();
	if(f & 4)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
	}
	if(f & 1)
	{
		self.modelindex = ReadShort();
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

		self.volume = ReadByte() / 255.0;
		self.fade_time = ReadByte() / 16.0;
		self.fade_rate = ReadByte() / 16.0;
		string s = self.noise;
		if(self.noise)
			strunzone(self.noise);
		self.noise = strzone(ReadString());
		if(self.noise != s)
		{
			precache_sound(self.noise);
			_sound(self, CH_BGM_SINGLE, self.noise, 0, ATTEN_NONE);
			if(getsoundtime(self, CH_BGM_SINGLE) < 0)
			{
				LOG_TRACEF("Cannot initialize sound %s\n", self.noise);
				strunzone(self.noise);
				self.noise = string_null;
			}
		}
	}

	setorigin(self, self.origin);
	setsize(self, self.mins, self.maxs);
	self.cnt = 1;
	self.think = Ent_TriggerMusic_Think;
	self.nextthink = time;
}

#endif
