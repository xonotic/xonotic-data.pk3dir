#include "music.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <common/constants.qh>
    #include <common/net_linked.qh>
    #include <server/constants.qh>
    #include <server/defs.qh>
#endif

REGISTER_NET_TEMP(TE_CSQC_TARGET_MUSIC)
REGISTER_NET_LINKED(ENT_CLIENT_TRIGGER_MUSIC)

#ifdef SVQC

IntrusiveList g_targetmusic_list;
STATIC_INIT(g_targetmusic_list) { g_targetmusic_list = IL_NEW(); }

// values:
//   volume
//   noise
//   targetname
//   lifetime
//   fade_time
//   fade_rate
// when triggered, the music is overridden for activator until lifetime (or forever, if lifetime is 0)
// when targetname is not set, THIS ONE is default
void target_music_sendto(entity this, int to, bool is)
{
	WriteHeader(to, TE_CSQC_TARGET_MUSIC);
	WriteShort(to, etof(this));
	WriteByte(to, this.volume * 255.0 * is);
	WriteByte(to, this.fade_time * 16.0);
	WriteByte(to, this.fade_rate * 16.0);
	WriteByte(to, this.lifetime);
	WriteString(to, this.noise);
}
void target_music_reset(entity this)
{
	if (this.targetname == "") target_music_sendto(this, MSG_ALL, 1);
}
void target_music_kill()
{
	IL_EACH(g_targetmusic_list, true,
	{
		it.volume = 0;
        if (it.targetname == "")
            target_music_sendto(it, MSG_ALL, 1);
        else
            target_music_sendto(it, MSG_ALL, 0);
	});
}
void target_music_use(entity this, entity actor, entity trigger)
{
	if(!actor)
		return;
	if(IS_REAL_CLIENT(actor))
	{
		msg_entity = actor;
		target_music_sendto(this, MSG_ONE, 1);
	}
	FOREACH_CLIENT(IS_SPEC(it) && it.enemy == actor, {
		msg_entity = it;
		target_music_sendto(this, MSG_ONE, 1);
	});
}
spawnfunc(target_music)
{
	this.use = target_music_use;
	this.reset = target_music_reset;
	if(!this.volume)
		this.volume = 1;
	IL_PUSH(g_targetmusic_list, this);
	if(this.targetname == "")
		target_music_sendto(this, MSG_INIT, 1);
	else
		target_music_sendto(this, MSG_INIT, 0);
}
void TargetMusic_RestoreGame()
{
	IL_EACH(g_targetmusic_list, true,
	{
		if(it.targetname == "")
			target_music_sendto(it, MSG_INIT, 1);
		else
			target_music_sendto(it, MSG_INIT, 0);
	});
}
// values:
//   volume
//   noise
//   targetname
//   fade_time
// spawnflags:
//   1 = START_OFF
// when triggered, it is disabled/enabled for everyone
bool trigger_music_SendEntity(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TRIGGER_MUSIC);
	sf &= ~0x80;
	if(this.cnt)
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 4)
	{
		WriteCoord(MSG_ENTITY, this.origin.x);
		WriteCoord(MSG_ENTITY, this.origin.y);
		WriteCoord(MSG_ENTITY, this.origin.z);
	}
	if(sf & 1)
	{
		if(this.model != "null")
		{
			WriteShort(MSG_ENTITY, this.modelindex);
			WriteCoord(MSG_ENTITY, this.mins.x);
			WriteCoord(MSG_ENTITY, this.mins.y);
			WriteCoord(MSG_ENTITY, this.mins.z);
			WriteCoord(MSG_ENTITY, this.maxs.x);
			WriteCoord(MSG_ENTITY, this.maxs.y);
			WriteCoord(MSG_ENTITY, this.maxs.z);
		}
		else
		{
			WriteShort(MSG_ENTITY, 0);
			WriteCoord(MSG_ENTITY, this.maxs.x);
			WriteCoord(MSG_ENTITY, this.maxs.y);
			WriteCoord(MSG_ENTITY, this.maxs.z);
		}
		WriteByte(MSG_ENTITY, this.volume * 255.0);
		WriteByte(MSG_ENTITY, this.fade_time * 16.0);
		WriteByte(MSG_ENTITY, this.fade_rate * 16.0);
		WriteString(MSG_ENTITY, this.noise);
	}
	return 1;
}
void trigger_music_reset(entity this)
{
	this.cnt = !(this.spawnflags & 1);
	this.SendFlags |= 0x80;
}
void trigger_music_use(entity this, entity actor, entity trigger)
{
	this.cnt = !this.cnt;
	this.SendFlags |= 0x80;
}
spawnfunc(trigger_music)
{
	if(this.model != "") _setmodel(this, this.model);
	if(!this.volume) this.volume = 1;
	if(!this.modelindex)
	{
		setorigin(this, this.origin + this.mins);
		setsize(this, '0 0 0', this.maxs - this.mins);
	}
	trigger_music_reset(this);

	this.use = trigger_music_use;
	this.reset = trigger_music_reset;

	Net_LinkEntity(this, false, 0, trigger_music_SendEntity);
}
#elif defined(CSQC)

entity TargetMusic_list;
STATIC_INIT(TargetMusic_list)
{
	TargetMusic_list = LL_NEW();
}

void TargetMusic_Advance()
{
	// run AFTER all the thinks!
	entity best = music_default;
	if (music_target && time < music_target.lifetime) best = music_target;
	if (music_trigger) best = music_trigger;
	LL_EACH(TargetMusic_list, it.noise, {
		const float vol0 = (getsoundtime(it, CH_BGM_SINGLE) >= 0) ? it.lastvol : -1;
		if (it == best)
		{
			// increase volume
			it.state = (it.fade_time > 0) ? bound(0, it.state + frametime / it.fade_time, 1) : 1;
		}
		else
		{
			// decrease volume
			it.state = (it.fade_rate > 0) ? bound(0, it.state - frametime / it.fade_rate, 1) : 0;
		}
		const float vol = it.state * it.volume * autocvar_bgmvolume;
		if (vol != vol0)
		{
			if(vol0 < 0)
				_sound(it, CH_BGM_SINGLE, it.noise, vol, ATTEN_NONE); // restart
			else
				_sound(it, CH_BGM_SINGLE, "", vol, ATTEN_NONE);
			it.lastvol = vol;
		}
	});
	music_trigger = NULL;
	bgmtime = (best) ? getsoundtime(best, CH_BGM_SINGLE) : gettime(GETTIME_CDTRACK);
}

NET_HANDLE(TE_CSQC_TARGET_MUSIC, bool isNew)
{
	Net_TargetMusic();
	return true;
}

void Net_TargetMusic()
{
	const int id = ReadShort();
	const float vol = ReadByte() / 255.0;
	const float fai = ReadByte() / 16.0;
	const float fao = ReadByte() / 16.0;
	const float tim = ReadByte();
	const string noi = ReadString();

	entity e = NULL;
	LL_EACH(TargetMusic_list, it.count == id, { e = it; break; });
	if (!e)
	{
		LL_PUSH(TargetMusic_list, e = new_pure(TargetMusic));
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
			LOG_TRACEF("Cannot initialize sound %s", e.noise);
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

void Ent_TriggerMusic_Think(entity this)
{
	if(WarpZoneLib_BoxTouchesBrush(view_origin, view_origin, this, NULL))
	{
		music_trigger = this;
	}
	this.nextthink = time;
}

void Ent_TriggerMusic_Remove(entity this)
{
	if(this.noise)
		strunzone(this.noise);
	this.noise = string_null;
}

NET_HANDLE(ENT_CLIENT_TRIGGER_MUSIC, bool isnew)
{
	int f = ReadByte();
	if(f & 4)
	{
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
	}
	if(f & 1)
	{
		this.modelindex = ReadShort();
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

		this.volume = ReadByte() / 255.0;
		this.fade_time = ReadByte() / 16.0;
		this.fade_rate = ReadByte() / 16.0;
		string s = this.noise;
		if(this.noise)
			strunzone(this.noise);
		this.noise = strzone(ReadString());
		if(this.noise != s)
		{
			precache_sound(this.noise);
			_sound(this, CH_BGM_SINGLE, this.noise, 0, ATTEN_NONE);
			if(getsoundtime(this, CH_BGM_SINGLE) < 0)
			{
				LOG_TRACEF("Cannot initialize sound %s", this.noise);
				strunzone(this.noise);
				this.noise = string_null;
			}
		}
	}

	setorigin(this, this.origin);
	setsize(this, this.mins, this.maxs);
	this.cnt = 1;
	setthink(this, Ent_TriggerMusic_Think);
	this.nextthink = time;
	return true;
}

#endif
