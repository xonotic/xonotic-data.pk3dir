#include "globalsound.qh"

#include <common/ent_cs.qh>

	#include <common/animdecide.qh>

	REGISTER_NET_TEMP(globalsound)
	REGISTER_NET_TEMP(playersound)

	#ifdef GAMEQC
		REPLICATE(cvar_cl_autotaunt, float, "cl_autotaunt");
		REPLICATE(cvar_cl_voice_directional, int, "cl_voice_directional");
		REPLICATE(cvar_cl_voice_directional_taunt_attenuation, float, "cl_voice_directional_taunt_attenuation");
	#endif

	#ifdef SVQC
		/**
		 * @param from the source entity, its position is sent
		 * @param gs the global sound def
		 * @param r a random number in 0..1
		 */
		void globalsound(int channel, entity from, entity gs, float r, int chan, float _vol, float _atten, float _pitch)
		{
			//assert(IS_PLAYER(from), eprint(from));
			if (channel == MSG_ONE && !IS_REAL_CLIENT(msg_entity)) return;
			if (!autocvar_g_debug_globalsounds) {
				string sample = GlobalSound_sample(gs.m_globalsoundstr, r);
				switch (channel) {
					case MSG_ONE:
						soundto(channel, from, chan, sample, _vol, _atten, _pitch);
						break;
					case MSG_ALL:
						if(sound_allowed(MSG_BROADCAST, from))
							sound7(from, chan, sample, _vol, _atten, _pitch, 0);
						break;
				}
				return;
			}
			// FIXME: pitch not implemented
			WriteHeader(channel, globalsound);
			WriteByte(channel, gs.m_id);
			WriteByte(channel, r * 255);
			WriteByte(channel, etof(from));
			WriteByte(channel, chan);
			WriteByte(channel, floor(_vol * 255));
			WriteByte(channel, floor(_atten * 64));
			entcs_force_origin(from);
			vector o = from.origin + 0.5 * (from.mins + from.maxs);
			WriteVector(channel, o);
		}

		/**
		* @param from the source entity, its position is sent
		* @param ps the player sound def
		* @param r a random number in 0..1
		*/
		void playersound(int channel, entity from, entity ps, float r, int chan, float _vol, float _atten, float _pitch)
		{
			//assert(IS_PLAYER(from), eprint(from));
			if (channel == MSG_ONE && !IS_REAL_CLIENT(msg_entity)) return;
			if (!autocvar_g_debug_globalsounds) {
				//UpdatePlayerSounds(from);
				string s = from.(ps.m_playersoundfld);
				string sample = GlobalSound_sample(s, r);
				switch (channel) {
					case MSG_ONE:
						soundto(channel, from, chan, sample, _vol, _atten, _pitch);
						break;
					case MSG_ALL:
						if(sound_allowed(MSG_BROADCAST, from))
							sound7(from, chan, sample, _vol, _atten, _pitch, 0);
						break;
				}
				return;
			}
			// FIXME: pitch not implemented
			WriteHeader(channel, playersound);
			WriteByte(channel, ps.m_id);
			WriteByte(channel, r * 255);
			WriteByte(channel, etof(from));
			WriteByte(channel, chan);
			WriteByte(channel, floor(_vol * 255));
			WriteByte(channel, floor(_atten * 64));
			entcs_force_origin(from);
			vector o = from.origin + 0.5 * (from.mins + from.maxs);
			WriteVector(channel, o);
		}
	#endif

	#ifdef CSQC

		NET_HANDLE(globalsound, bool isnew)
		{
			entity gs = REGISTRY_GET(GlobalSounds, ReadByte());
			float r = ReadByte() / 255;
			string sample = GlobalSound_sample(gs.m_globalsoundstr, r);
			int who = ReadByte();
			entity e = entcs_receiver(who - 1);
			int chan = ReadSByte();
			float vol = ReadByte() / 255;
			float atten = ReadByte() / 64;
			vector o = ReadVector();
			// TODO: is this really what we want to be doing? Footsteps that follow the player at head height?
			if (who == player_currententnum) e = findfloat(NULL, entnum, who);  // play at camera position for full volume
			else if (e) e.origin = o;
			if (e)
			{
				sound7(e, chan, sample, vol, atten, 0, 0);
			}
			else
			{
				// Can this happen?
				LOG_WARNF("Missing entcs data for player %d", who);
				sound8(e, o, chan, sample, vol, atten, 0, 0);
			}
			return true;
		}

		NET_HANDLE(playersound, bool isnew)
		{
			entity ps = REGISTRY_GET(PlayerSounds, ReadByte());
			float r = ReadByte() / 255;
			int who = ReadByte();
			entity e = entcs_receiver(who - 1);
			UpdatePlayerSounds(e);
			string s = e.(ps.m_playersoundfld);
			string sample = GlobalSound_sample(s, r);
			int chan = ReadSByte();
			float vol = ReadByte() / 255;
			float atten = ReadByte() / 64;
			vector o = ReadVector();
			if (who == player_currententnum) e = findfloat(NULL, entnum, who);  // play at camera position for full volume
			else if (e) e.origin = o;
			if (e)
			{
				// TODO: for non-visible players, origin should probably continue to be updated as long as the sound is playing
				sound7(e, chan, sample, vol, atten, 0, 0);
			}
			else
			{
				// Can this happen?
				LOG_WARNF("Missing entcs data for player %d", who);
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

	float GlobalSound_pitch(float _pitch)
	{
		// customizable gradient function that crosses (0,a), (c,1) and asymptotically approaches b
		float a = 1.5; // max pitch
		float b = 0.75; // min pitch
		float c = 100; // standard pitch (scale * 100)
		float d = _pitch;
		float pitch_shift = (b*d*(a-1) + a*c*(1-b)) / (d*(a-1) + c*(1-b));

		return pitch_shift * 100;
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
		FOREACH(PlayerSounds, it.m_playersoundstr == type && it.instanceOfVoiceMessage == true, return it);
		return NULL;
	}

	entity GetPlayerSound(string type)
	{
		FOREACH(PlayerSounds, it.m_playersoundstr == type && it.instanceOfVoiceMessage == false, return it);
		return NULL;
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
			LOG_WARNF("Player sound file not found: %s", f);
			return;
		}
		for (string s; (s = fgets(fh)); )
		{
			int n = tokenize_console(s);
			if (n != 3)
			{
				if (n != 0) LOG_WARNF("Invalid sound info line: %s", s);
				continue;
			}
			string file = argv(1);
			string variants = argv(2);
			PrecacheGlobalSound(strcat(file, " ", variants));
		}
		fclose(fh);
	}

	//#ifdef CSQC

		.string GetPlayerSoundSampleField(string type)
		{
			return _GetPlayerSoundSampleField(type, false);
		}

		void ClearPlayerSounds(entity this)
		{
			FOREACH(PlayerSounds, true, {
				.string fld = it.m_playersoundfld;
				if (this.(fld))
				{
					strfree(this.(fld));
				}
			});
		}

		bool LoadPlayerSounds(entity this, string f, bool strict)
		{
			int fh = fopen(f, FILE_READ);
			if (fh < 0)
			{
				if (strict) LOG_WARNF("Player sound file not found: %s", f);
				return false;
			}
			for (string s; (s = fgets(fh)); )
			{
				int n = tokenize_console(s);
				if (n != 3)
				{
					if (n != 0) LOG_WARNF("Invalid sound info line: %s", s);
					continue;
				}
				string key = argv(0);
				var .string field = GetPlayerSoundSampleField(key);
				if (GetPlayerSoundSampleField_notFound) field = GetVoiceMessageSampleField(key);
				if (GetPlayerSoundSampleField_notFound)
				{
					LOG_TRACEF("Invalid sound info field in player sound file '%s': %s", f, key);
					continue;
				}
				string file = argv(1);
				string variants = argv(2);
				strcpy(this.(field), strcat(file, " ", variants));
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
			strcpy(this.model_for_playersound, this.model);
			this.skin_for_playersound = this.skin;
			ClearPlayerSounds(this);
			LoadPlayerSounds(this, "sound/player/default.sounds", true);
			if (this.model == "null"
			#ifdef SVQC
				&& autocvar_g_debug_globalsounds
			#endif
			) return;
			if (autocvar_g_debug_defaultsounds) return;
			if (LoadPlayerSounds(this, get_model_datafilename(this.model, this.skin, "sounds"), false)) return;
			LoadPlayerSounds(this, get_model_datafilename(this.model, 0, "sounds"), true);
		}

	//#endif

	#ifdef SVQC

		void _GlobalSound(entity this, entity gs, entity ps, string sample, int chan, float vol, int voicetype, bool fake)
		{
			if (gs == NULL && ps == NULL && sample == "") return;
			if(this.classname == "body") return;
			float r = random();
			float myscale = ((this.scale) ? this.scale : 1); // safety net
			float thepitch = ((myscale == 1) ? 0 : GlobalSound_pitch(myscale * 100));
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
							float atten = (CS_CVAR(msg_entity).cvar_cl_voice_directional == 1) ? ATTEN_MIN : ATTEN_NONE;
							if (gs) globalsound(MSG_ONE, this, gs, r, chan, vol, atten, thepitch);
							else if (ps) playersound(MSG_ONE, this, ps, r, chan, vol, atten, thepitch);
							else soundto(MSG_ONE, this, chan, sample, vol, atten, thepitch);
						}
					}
					if (voicetype == VOICETYPE_LASTATTACKER_ONLY) break;
					msg_entity = this;
					if (IS_REAL_CLIENT(msg_entity))
					{
						if (gs) globalsound(MSG_ONE, this, gs, r, chan, VOL_BASE, ATTEN_NONE, thepitch);
						else if (ps) playersound(MSG_ONE, this, ps, r, chan, VOL_BASE, ATTEN_NONE, thepitch);
						else soundto(MSG_ONE, this, chan, sample, VOL_BASE, ATTEN_NONE, thepitch);
					}
					break;
				}
				case VOICETYPE_TEAMRADIO:
				{
					#define X() \
						MACRO_BEGIN \
							float atten = (CS_CVAR(msg_entity).cvar_cl_voice_directional == 1) ? ATTEN_MIN : ATTEN_NONE; \
							if (gs) globalsound(MSG_ONE, this, gs, r, chan, vol, atten, thepitch); \
							else if (ps) playersound(MSG_ONE, this, ps, r, chan, vol, atten, thepitch); \
							else soundto(MSG_ONE, this, chan, sample, vol, atten, thepitch); \
						MACRO_END

					if (fake) { msg_entity = this; X(); }
					else
					{
						FOREACH_CLIENT(IS_REAL_CLIENT(it) && SAME_TEAM(it, this), {
							msg_entity = it;
							X();
						});
					}
					#undef X
					break;
				}
				case VOICETYPE_AUTOTAUNT:
				case VOICETYPE_TAUNT:
				{
					if (voicetype == VOICETYPE_AUTOTAUNT)
					{
						if (!autocvar_sv_autotaunt) break;
					}
					else if (IS_PLAYER(this) && !IS_DEAD(this))
						animdecide_setaction(this, ANIMACTION_TAUNT, true);

					if (!autocvar_sv_taunt) break;
					if (autocvar_sv_gentle) break;
					float tauntrand = 0;
					if (voicetype == VOICETYPE_AUTOTAUNT) tauntrand = random();

					#define X() \
						MACRO_BEGIN \
							if (voicetype != VOICETYPE_AUTOTAUNT || tauntrand < CS_CVAR(msg_entity).cvar_cl_autotaunt) \
							{ \
								float atten = (CS_CVAR(msg_entity).cvar_cl_voice_directional >= 1) \
									? bound(ATTEN_MIN, CS_CVAR(msg_entity).cvar_cl_voice_directional_taunt_attenuation, \
									ATTEN_MAX) \
									: ATTEN_NONE; \
								if (gs) globalsound(MSG_ONE, this, gs, r, chan, vol, atten, thepitch); \
								else if (ps) playersound(MSG_ONE, this, ps, r, chan, vol, atten, thepitch); \
								else soundto(MSG_ONE, this, chan, sample, vol, atten, thepitch); \
							} \
						MACRO_END
					if (fake)
					{
						msg_entity = this;
						X();
					}
					else
					{
						FOREACH_CLIENT(IS_REAL_CLIENT(it), {
							msg_entity = it;
							X();
						});
					}
					#undef X
					break;
				}
				case VOICETYPE_PLAYERSOUND:
				{
					msg_entity = this;
					if (fake)
					{
						if (gs) globalsound(MSG_ONE, this, gs, r, chan, vol, ATTEN_NORM, thepitch);
						else if (ps) playersound(MSG_ONE, this, ps, r, chan, vol, ATTEN_NORM, thepitch);
						else soundto(MSG_ONE, this, chan, sample, vol, ATTEN_NORM, thepitch);
					}
					else
					{
						if (gs) globalsound(MSG_ALL, this, gs, r, chan, vol, ATTEN_NORM, thepitch);
						else if (ps) playersound(MSG_ALL, this, ps, r, chan, vol, ATTEN_NORM, thepitch);
						else if (sound_allowed(MSG_BROADCAST, this)) sound7(this, chan, sample, vol, ATTEN_NORM, thepitch, 0);
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
