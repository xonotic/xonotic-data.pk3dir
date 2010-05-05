// values:
//   volume
//   noise
//   targetname
//   timeout
//   fade_time
// when triggered, the music is overridden for activator until timeout (or forever, if timeout is 0)
// when targetname is not set, THIS ONE is default
void target_music_sendto(float to)
{
	WriteByte(to, TE_CSQC_TARGET_MUSIC);
	WriteByte(to, self.volume * 255.0);
	WriteByte(to, self.fade_time * 16.0);
	WriteString(to, self.noise);
}
void target_music_reset()
{
	target_music_sendto(MSG_ALL);
}
void target_music_use()
{
	if(!activator)
		return;
	msg_entity = activator;
	target_music_sendto(MSG_ONE);
}
void spawnfunc_target_music()
{
	self.use = target_music_use;
	self.reset = target_music_reset;
	precache_sound(self.noise);
	if(!self.volume)
		self.volume = 1;
	target_music_sendto(MSG_INIT);
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
{
	WriteByte(MSG_ENTITY, TE_CSQC_TARGET_MUSIC);
	sf &~= 0x80;
	if(self.cnt)
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 4)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}
	if(sf & 1)
	{
		if(self.model != "null")
		{
			WriteShort(MSG_ENTITY, self.modelindex);
			WriteCoord(MSG_ENTITY, self.mins_x);
			WriteCoord(MSG_ENTITY, self.mins_y);
			WriteCoord(MSG_ENTITY, self.mins_z);
			WriteCoord(MSG_ENTITY, self.maxs_x);
			WriteCoord(MSG_ENTITY, self.maxs_y);
			WriteCoord(MSG_ENTITY, self.maxs_z);
		}
		else
		{
			WriteShort(MSG_ENTITY, 0);
			WriteCoord(MSG_ENTITY, self.maxs_x);
			WriteCoord(MSG_ENTITY, self.maxs_y);
			WriteCoord(MSG_ENTITY, self.maxs_z);
		}
		WriteByte(MSG_ENTITY, self.volume * 255.0);
		WriteByte(MSG_ENTITY, self.fade_time * 16.0);
		WriteString(MSG_ENTITY, self.noise);
	}
	return 1;
}
void trigger_music_reset()
{
	self.cnt = !(self.spawnflags & 1);
	self.SendFlags |= 0x80;
}
void trigger_music_use()
{
	self.cnt = !self.cnt;
	self.SendFlags |= 0x80;
}
void spawnfunc_trigger_music()
{
	if(self.model != "")
		setmodel(self, self.model);
	precache_sound (self.noise);
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

	Net_LinkEntity(self, FALSE, 0, trigger_music_SendEntity);
}
