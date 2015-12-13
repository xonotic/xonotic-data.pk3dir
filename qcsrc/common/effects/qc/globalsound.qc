#include "globalsound.qh"

#include "../../ent_cs.qh"

#ifdef IMPLEMENTATION
	#include "../../animdecide.qh"

	#ifdef SVQC
		#include "../../../server/cl_player.qh"
	#endif

	REGISTER_NET_TEMP(globalsound)
	REGISTER_NET_TEMP(playersound)

	#ifdef SVQC
		/**
		 * @param from the source entity, its position is sent
		 * @param gs the global sound def
		 * @param r a random number in 0..1
		 */
		void globalsound(int channel, entity from, entity gs, float r, int chan, float vol, float atten)
		{
			assert(IS_PLAYER(from), eprint(from));
			if (channel == MSG_ONE && !IS_REAL_CLIENT(msg_entity)) return;
			WriteHeader(channel, globalsound);
			WriteByte(channel, gs.m_id);
			WriteByte(channel, r * 255);
			WriteByte(channel, etof(from));
			WriteByte(channel, chan);
			WriteByte(channel, floor(vol * 255));
			WriteByte(channel, floor(atten * 64));
			entcs_force_origin(from);
			vector o = from.origin + 0.5 * (from.mins + from.maxs);
			WriteCoord(channel, o.x);
			WriteCoord(channel, o.y);
			WriteCoord(channel, o.z);
		}

		/**
		* @param from the source entity, its position is sent
		* @param ps the player sound def
		* @param r a random number in 0..1
		*/
		void playersound(int channel, entity from, entity ps, float r, int chan, float vol, float atten)
		{
			assert(IS_PLAYER(from), eprint(from));
			if (channel == MSG_ONE && !IS_REAL_CLIENT(msg_entity)) return;
			WriteHeader(channel, playersound);
			WriteByte(channel, ps.m_id);
			WriteByte(channel, r * 255);
			WriteByte(channel, etof(from));
			WriteByte(channel, chan);
			WriteByte(channel, floor(vol * 255));
			WriteByte(channel, floor(atten * 64));
			entcs_force_origin(from);
			vector o = from.origin + 0.5 * (from.mins + from.maxs);
			WriteCoord(channel, o.x);
			WriteCoord(channel, o.y);
			WriteCoord(channel, o.z);
		}
	#endif

	string GlobalSound_sample(string pair, float r);

	#ifdef CSQC

		NET_HANDLE(globalsound, bool isnew)
		{
			entity gs = GlobalSounds_from(ReadByte());
			float r = ReadByte() / 255;
			string sample = GlobalSound_sample(gs.m_globalsoundstr, r);
			int who = ReadByte();
			entity e = entcs_receiver(who - 1);
			int chan = ReadSByte();
			float vol = ReadByte() / 255;
			float atten = ReadByte() / 64;
			vector o;
			o.x = ReadCoord();
			o.y = ReadCoord();
			o.z = ReadCoord();
			// TODO: is this really what we want to be doing? Footsteps that follow the player at head height?
			if (who == player_currententnum) e = findfloat(world, entnum, who);  // play at camera position for full volume
			else if (e) e.origin = o;
			if (e)
			{
				sound7(e, chan, sample, vol, atten, 0, 0);
			}
			else
			{
				// Can this happen?
				LOG_WARNINGF("Missing entcs data for player %d\n", who);
				sound8(e, o, chan, sample, vol, atten, 0, 0);
			}
			return true;
		}

		NET_HANDLE(playersound, bool isnew)
		{
			entity ps = PlayerSounds_from(ReadByte());
			float r = ReadByte() / 255;
			int who = ReadByte();
			entity e = entcs_receiver(who - 1);
			UpdatePlayerSounds(e);
			string s = e.(ps.m_playersoundfld);
			string sample = GlobalSound_sample(s, r);
			int chan = ReadSByte();
			float vol = ReadByte() / 255;
			float atten = ReadByte() / 64;
			vector o;
			o.x = ReadCoord();
			o.y = ReadCoord();
			o.z = ReadCoord();
			if (who == player_currententnum) e = findfloat(world, entnum, who);  // play at camera position for full volume
			else if (e) e.origin = o;
			if (e)
			{
				// TODO: for non-visible players, origin should probably continue to be updated as long as the sound is playing
				sound7(e, chan, sample, vol, atten, 0, 0);
			}
			else
			{
				// Can this happen?
				LOG_WARNINGF("Missing entcs data for player %d\n", who);
				sound8(e, o, chan, sample, vol, atten, 0, 0);
			}
			return true;
		}

	#endif

	string GlobalSound_sample(string pair, float r)
	{
		int n;
		{
			string s = cdr(pair);
			if (s) n = stof(s);
			else n = 0;
		}
		string sample = car(pair);
		if (n > 0) sample = sprintf("%s%d.wav", sample, floor(r * n + 1));  // randomization
		else sample = sprintf("%s.wav", sample);
		return sample;
	}

	void PrecacheGlobalSound(string sample)
	{
		int n;
		{
			string s = cdr(sample);
			if (s) n = stof(s);
			else n = 0;
		}
		sample = car(sample);
		if (n > 0)
		{
			for (int i = 1; i <= n; ++i)
				precache_sound(sprintf("%s%d.wav", sample, i));
		}
		else
		{
			precache_sound(sprintf("%s.wav", sample));
		}
	}

	entity GetVoiceMessage(string type)
	{
		FOREACH(PlayerSounds, it.m_playersoundstr == type && it.instanceOfVoiceMessage == true, LAMBDA(return it));
		return NULL;
	}

	entity GetPlayerSound(string type)
	{
		FOREACH(PlayerSounds, it.m_playersoundstr == type && it.instanceOfVoiceMessage == false, LAMBDA(return it));
		return NULL;
	}

	string allvoicesamples;
	STATIC_INIT(allvoicesamples)
	{
		FOREACH(PlayerSounds, it.instanceOfVoiceMessage, LAMBDA(
			allvoicesamples = strcat(allvoicesamples, " ", it.m_playersoundstr)
			                                                   ));
		allvoicesamples = strzone(substring(allvoicesamples, 1, -1));
	}

	.string _GetPlayerSoundSampleField(string type, bool voice)
	{
		GetPlayerSoundSampleField_notFound = false;
		entity e = voice ? GetVoiceMessage(type) : GetPlayerSound(type);
		if (e) return e.m_playersoundfld;
		GetPlayerSoundSampleField_notFound = true;
		return playersound_taunt.m_playersoundfld;
	}

	.string GetVoiceMessageSampleField(string type)
	{
		return _GetPlayerSoundSampleField(type, true);
	}

	void PrecachePlayerSounds(string f)
	{
		int fh = fopen(f, FILE_READ);
		if (fh < 0)
		{
			LOG_WARNINGF("Player sound file not found: %s\n", f);
			return;
		}
		for (string s; (s = fgets(fh)); )
		{
			int n = tokenize_console(s);
			if (n != 3)
			{
				if (n != 0) LOG_WARNINGF("Invalid sound info line: %s\n", s);
				continue;
			}
			string file = argv(1);
			string variants = argv(2);
			PrecacheGlobalSound(strcat(file, " ", variants));
		}
		fclose(fh);
	}

	#ifdef CSQC

		.string GetPlayerSoundSampleField(string type)
		{
			return _GetPlayerSoundSampleField(type, false);
		}

		void ClearPlayerSounds(entity this)
		{
			FOREACH(PlayerSounds, true, LAMBDA(
				.string fld = it.m_playersoundfld;
				if (this.(fld))
	{
		strunzone(this.(fld));
		this.(fld) = string_null;
	}
				                              ));
		}

		bool LoadPlayerSounds(entity this, string f, bool strict)
		{
			int fh = fopen(f, FILE_READ);
			if (fh < 0)
			{
				if (strict) LOG_WARNINGF("Player sound file not found: %s\n", f);
				return false;
			}
			for (string s; (s = fgets(fh)); )
			{
				int n = tokenize_console(s);
				if (n != 3)
				{
					if (n != 0) LOG_WARNINGF("Invalid sound info line: %s\n", s);
					continue;
				}
				string key = argv(0);
				var.string field = GetPlayerSoundSampleField(key);
				if (GetPlayerSoundSampleField_notFound) field = GetVoiceMessageSampleField(key);
				if (GetPlayerSoundSampleField_notFound)
				{
					LOG_TRACEF("Invalid sound info field: %s\n", key);
					continue;
				}
				string file = argv(1);
				string variants = argv(2);
				if (this.(field)) strunzone(this.(field));
				this.(field) = strzone(strcat(file, " ", variants));
			}
			fclose(fh);
			return true;
		}

		.string model_for_playersound;
		.int skin_for_playersound;

		bool autocvar_g_debug_defaultsounds;

		void UpdatePlayerSounds(entity this)
		{
			if (this.model == this.model_for_playersound && this.skin == this.skin_for_playersound) return;
			if (this.model_for_playersound) strunzone(this.model_for_playersound);
			this.model_for_playersound = strzone(this.model);
			this.skin_for_playersound = this.skin;
			ClearPlayerSounds(this);
			LoadPlayerSounds(this, "sound/player/default.sounds", true);
			if (this.model == "null" || autocvar_g_debug_defaultsounds) return;
			if (LoadPlayerSounds(this, get_model_datafilename(this.model, this.skin, "sounds"), false)) return;
			LoadPlayerSounds(this, get_model_datafilename(this.model, 0, "sounds"), true);
		}

	#endif

	#ifdef SVQC

		bool autocvar_g_debug_globalsounds;

		void _GlobalSound(entity this, entity gs, entity ps, string sample, int chan, int voicetype, bool fake)
		{
			if (gs == NULL && ps == NULL && sample == "") return;
			float r = random();
			if (sample != "") sample = GlobalSound_sample(sample, r);
			switch (voicetype)
			{
				case VOICETYPE_LASTATTACKER_ONLY:
				case VOICETYPE_LASTATTACKER:
				{
					if (!fake)
					{
						if (!this.pusher) break;
						msg_entity = this.pusher;
						if (IS_REAL_CLIENT(msg_entity))
						{
							float atten = (msg_entity.cvar_cl_voice_directional == 1) ? ATTEN_MIN : ATTEN_NONE;
							if (gs) globalsound(MSG_ONE, this, gs, r, chan, VOL_BASEVOICE, atten);
							else if (ps) playersound(MSG_ONE, this, ps, r, chan, VOL_BASEVOICE, atten);
							else soundto(MSG_ONE, this, chan, sample, VOL_BASEVOICE, atten);
						}
					}
					if (voicetype == VOICETYPE_LASTATTACKER_ONLY) break;
					msg_entity = this;
					if (IS_REAL_CLIENT(msg_entity))
					{
						if (gs) globalsound(MSG_ONE, this, gs, r, chan, VOL_BASE, ATTEN_NONE);
						else if (ps) playersound(MSG_ONE, this, ps, r, chan, VOL_BASE, ATTEN_NONE);
						else soundto(MSG_ONE, this, chan, sample, VOL_BASE, ATTEN_NONE);
					}
					break;
				}
				case VOICETYPE_TEAMRADIO:
				{
					#define X() \
						MACRO_BEGIN \
						{ \
							float atten = (msg_entity.cvar_cl_voice_directional == 1) ? ATTEN_MIN : ATTEN_NONE; \
							if (gs) globalsound(MSG_ONE, this, gs, r, chan, VOL_BASEVOICE, atten); \
							else if (ps) playersound(MSG_ONE, this, ps, r, chan, VOL_BASEVOICE, atten); \
							else soundto(MSG_ONE, this, chan, sample, VOL_BASEVOICE, atten); \
						} MACRO_END

					if (fake) { msg_entity = this; X(); }
					else
					{
						FOR_EACH_REALCLIENT(msg_entity)
						{
							if (!teamplay || msg_entity.team == this.team) X();
						}
					}
		#undef X
					break;
				}
				case VOICETYPE_AUTOTAUNT:
				case VOICETYPE_TAUNT:
				{
					if (voicetype == VOICETYPE_AUTOTAUNT) if (!sv_autotaunt) { break; }else {}
					else if (IS_PLAYER(this) && this.deadflag == DEAD_NO) animdecide_setaction(this, ANIMACTION_TAUNT,
							true);
					if (!sv_taunt) break;
					if (autocvar_sv_gentle) break;
					float tauntrand = 0;
					if (voicetype == VOICETYPE_AUTOTAUNT) tauntrand = random();
					#define X() \
						MACRO_BEGIN \
						{ \
							if (voicetype != VOICETYPE_AUTOTAUNT || tauntrand < msg_entity.cvar_cl_autotaunt) \
							{ \
								float atten = (msg_entity.cvar_cl_voice_directional >= 1) \
								    ? bound(ATTEN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, \
									ATTEN_MAX) \
									: ATTEN_NONE; \
								if (gs) globalsound(MSG_ONE, this, gs, r, chan, VOL_BASEVOICE, atten); \
								else if (ps) playersound(MSG_ONE, this, ps, r, chan, VOL_BASEVOICE, atten); \
								else soundto(MSG_ONE, this, chan, sample, VOL_BASEVOICE, atten); \
							} \
						} MACRO_END
					if (fake)
					{
						msg_entity = this;
						X();
					}
					else
					{
						FOR_EACH_REALCLIENT(msg_entity)
						{
							X();
						}
					}
		#undef X
					break;
				}
				case VOICETYPE_PLAYERSOUND:
				{
					msg_entity = this;
					if (fake)
					{
						if (gs) globalsound(MSG_ONE, this, gs, r, chan, VOL_BASE, ATTEN_NORM);
						else if (ps) playersound(MSG_ONE, this, ps, r, chan, VOL_BASE, ATTEN_NORM);
						else soundto(MSG_ONE, this, chan, sample, VOL_BASE, ATTEN_NORM);
					}
					else
					{
						if (gs)
						{
							if(autocvar_g_debug_globalsounds)
								globalsound(MSG_ALL, this, gs, r, chan, VOL_BASE, ATTEN_NORM);
							else
								_sound(this, chan, GlobalSound_sample(gs.m_globalsoundstr, r), VOL_BASE, ATTEN_NORM);
						}
						else if (ps) playersound(MSG_ALL, this, ps, r, chan, VOL_BASE, ATTEN_NORM);
						else _sound(this, chan, sample, VOL_BASE, ATTEN_NORM);
					}
					break;
				}
				default:
				{
					backtrace("Invalid voice type!");
					break;
				}
			}
		}

	#endif
#endif
