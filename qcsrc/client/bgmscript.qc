#include "bgmscript.qh"

#include <client/main.qh>
#include <common/util.qh>

#define CONSTANT_SPEED_DECAY

float bgmscriptbuf;
float bgmscriptbufsize;
float bgmscriptbufloaded;

classfield(BGMScript) .float bgmscriptline;
classfield(BGMScript) .float bgmscriptline0;
classfield(BGMScript) .float bgmscriptvolume;
classfield(BGMScript) .float bgmscripttime;
classfield(BGMScript) .float bgmscriptstate;
classfield(BGMScript) .float bgmscriptstatetime;

float GetAttackDecaySustainAmplitude(float a, float d, float s, float t)
{
	// phase:
	//   attack: from 0 to 1, in time a for a full length
	//   decay: from 1 to s, in time d
	//   sustain: s

	if(t < 0)
		return 0;

	if(a)
		if(t <= a)
			return t / a;

	if(d)
		if(t <= a + d)
			return ((t - a) / d) * (s - 1) + 1;

	return s;
}

float GetReleaseAmplitude(float d, float s, float r, float t)
{
	float decayval, releaseval;

	if(!r)
		return 0;

	if(t > r)
		return 0;

	releaseval = s * (1 - t / r);

	if(t < -d)
		return 1;

	if(t < 0 && t >= -d)
	{
		// pre-time decay
		// value is s at time  0
		//          1 at time -d
		decayval = ((t + d) / d) * (s - 1) + 1;
		return max(decayval, releaseval);
	}

	return releaseval;
}

float GetAttackTime(float a, float amp)
{
	return amp * a;
}

float GetReleaseTime(float d, float s, float r, float amp)
{
	float decaytime, releasetime;

	if(!s)
		return 0;

	// if amp > s, we may be in the attack or in the prolonged decay curve
	releasetime = (1 - amp / s) * r;

	if(amp > s)
	{
		if(s == 1) // gracefully handle division by zero here
			return 0;

		// pre-time decay
		// value is s at time  0
		//          1 at time -d
		decaytime = (amp - 1) / (s - 1) * d - d;
		return max(decaytime, releasetime);
	}

	return releasetime;
}

void BGMScript_Init()
{
	string s;
	float fh;
	bgmscriptbuf = bgmscriptbufsize = 0;
	bgmscriptbufloaded = 1;
	s = strcat("maps/", mi_shortname, ".bgs");
	fh = fopen(s, FILE_READ);
	if(fh < 0)
		return;
	bgmscriptbuf = buf_create();
	while((s = fgets(fh)))
	{
		bufstr_set(bgmscriptbuf, bgmscriptbufsize, s);
		++bgmscriptbufsize;
	}
	fclose(fh);
}

void BGMScript_InitEntity(entity e)
{
	float l;
	string m;
	if(e.bgmscript != "")
	{
		if(!bgmscriptbufloaded)
			BGMScript_Init();

		float i;

		m = strcat(e.bgmscript, " ");
		l = strlen(m);

		e.bgmscriptline0 = -1;
		for(i = 0; i < bgmscriptbufsize; ++i)
		{
			if(substring(bufstr_get(bgmscriptbuf, i), 0, l) == m)
				break;
		}
		e.bgmscriptline = e.bgmscriptline0 = i;
		if(i >= bgmscriptbufsize)
		{
			LOG_INFOF("ERROR: bgmscript does not define %s", e.bgmscript);
			strfree(e.bgmscript);
		}
	}
}

float GetCurrentAmplitude(entity e, float trel)
{
	if(e.bgmscriptstate)
		return GetAttackDecaySustainAmplitude(e.bgmscriptattack, e.bgmscriptdecay, e.bgmscriptsustain, trel) * e.bgmscriptvolume;
	else
	{
#ifdef CONSTANT_SPEED_DECAY
		return GetReleaseAmplitude(e.bgmscriptdecay, e.bgmscriptsustain * e.bgmscriptvolume, e.bgmscriptrelease, trel);
#else
		return GetReleaseAmplitude(e.bgmscriptdecay, e.bgmscriptsustain, e.bgmscriptrelease, trel) * e.bgmscriptvolume;
#endif
	}
}

float GetTimeForAmplitude(entity e, float amp)
{
	if(e.bgmscriptstate)
		return GetAttackTime(e.bgmscriptattack, amp / e.bgmscriptvolume);
	else
	{
#ifdef CONSTANT_SPEED_DECAY
		return GetReleaseTime(e.bgmscriptdecay, e.bgmscriptsustain * e.bgmscriptvolume, e.bgmscriptrelease, amp);
#else
		return GetReleaseTime(e.bgmscriptdecay, e.bgmscriptsustain, e.bgmscriptrelease, amp / e.bgmscriptvolume);
#endif
	}
}

float doBGMScript(entity e)
{
	float amp, vel;

	if(e.bgmscript == "")
		return 1;

	if(autocvar_bgmvolume <= 0)
		return -1;

	e.just_toggled = false;

	if(bgmtime < 0)
		return -1;

	if(bgmtime < e.bgmscripttime)
	{
		amp = GetCurrentAmplitude(e, e.bgmscripttime - e.bgmscriptstatetime + drawframetime);

		e.bgmscriptline = e.bgmscriptline0;
		e.bgmscripttime = bgmtime;

		// treat this as a stop event for all notes, to prevent sticking keys
		e.bgmscriptstate = false;
		e.bgmscriptvolume = 1;
		e.bgmscriptstatetime = bgmtime - GetTimeForAmplitude(e, amp);
	}

	// find the CURRENT line
	for (;;)
	{
		tokenize_console(bufstr_get(bgmscriptbuf, e.bgmscriptline));
		if(stof(argv(1)) >= bgmtime || argv(0) != e.bgmscript)
		{
			e.bgmscripttime = bgmtime;
			return GetCurrentAmplitude(e, bgmtime - e.bgmscriptstatetime);
		}
		else if(bgmtime >= stof(argv(1)))
		{
			e.bgmscriptline += 1;
			e.bgmscripttime = stof(argv(1));

			amp = GetCurrentAmplitude(e, e.bgmscripttime - e.bgmscriptstatetime);

			// time code reached!
			vel = stof(argv(2));
			if(vel > 0)
			{
				e.just_toggled = e.bgmscriptstate = true;
				e.bgmscriptvolume = vel;
			}
			else
				e.just_toggled = e.bgmscriptstate = false;

			e.bgmscriptstatetime = e.bgmscripttime - GetTimeForAmplitude(e, amp);
		}
	}
}

