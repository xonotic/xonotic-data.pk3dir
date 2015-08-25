#include "tuba.qh"
#include "_all.qh"

#include "../common/constants.qh"
#include "../common/util.qh"

#include "../warpzonelib/mathlib.qh"

#define TUBA_STARTNOTE(i, n) W_Sound(strcat("tuba", (i ? ftos(i) : ""), "_loopnote", ftos(n)))

const int TUBA_MIN = -18;
const int TUBA_MAX = 27;
const int TUBA_INSTRUMENTS = 3;

class(Tuba) .int note;
class(Tuba) .bool tuba_attenuate;
class(Tuba) .float tuba_volume;
class(Tuba) .float tuba_volume_initial;
class(Tuba) .int tuba_instrument;

int Tuba_PitchStep;

void tubasound(entity e, bool restart)
{
	string snd1 = string_null;
	if (Tuba_PitchStep) {
		float vol1 = 1;
		float speed1 = 1;
		string snd2 = string_null;
		float vol2 = 0;
		float speed2 = 1;

		int m = pymod(e.note, Tuba_PitchStep);
		if (m) {
			if (e.note - m < TUBA_MIN) {
				if (restart) {
					snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note - m + Tuba_PitchStep);
				}
				speed1 = pow(2.0, (m - Tuba_PitchStep) / 12.0);
			} else if (e.note - m + Tuba_PitchStep > TUBA_MAX) {
				if (restart) {
					snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note - m);
				}
				speed1 = pow(2.0, m / 12.0);
			} else {
				if (restart) {
					snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note - m);
				}
				vol1 = cos(M_PI_2 * m / Tuba_PitchStep);
				speed1 = pow(2.0, m / 12.0);
				if (restart) {
					snd2 = TUBA_STARTNOTE(e.tuba_instrument, e.note - m + Tuba_PitchStep);
				}
				vol2 = sin(M_PI_2 * m / Tuba_PitchStep);
				speed2 = pow(2.0, (m - Tuba_PitchStep) / 12.0);
			}
		} else if (restart) {
			snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note);
		}

		sound7(e, CH_TUBA_SINGLE, snd1, e.tuba_volume * vol1, e.tuba_attenuate * autocvar_g_balance_tuba_attenuation, 100 * speed1, 0);
		if (vol2) {
			sound7(e.enemy, CH_TUBA_SINGLE, snd2, e.tuba_volume * vol2, e.tuba_attenuate * autocvar_g_balance_tuba_attenuation, 100 * speed2, 0);
		}
	} else {
		if (restart) {
			snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note);
		}
		sound(e, CH_TUBA_SINGLE, snd1, e.tuba_volume, e.tuba_attenuate * autocvar_g_balance_tuba_attenuation);
	}
}

void Ent_TubaNote_Think()
{
	float f = autocvar_g_balance_tuba_fadetime;
	if (f > 0) {
		self.tuba_volume -= frametime * self.tuba_volume_initial / f;
	} else {
		self.tuba_volume = 0;
	}
	self.nextthink = time;
	if (self.tuba_volume <= 0) {
		sound(self, CH_TUBA_SINGLE, "misc/null.wav", 0, 0);
		if (self.enemy) {
			sound(self.enemy, CH_TUBA_SINGLE, "misc/null.wav", 0, 0);
			remove(self.enemy);
		}
		remove(self);
	} else {
		tubasound(self, 0);
	}
}

void Ent_TubaNote_UpdateSound()
{
	self.enemy.tuba_volume = bound(0, VOL_BASE * autocvar_g_balance_tuba_volume, 1);
	self.enemy.tuba_volume_initial = self.enemy.tuba_volume;
	self.enemy.note = self.note;
	self.enemy.tuba_instrument = self.tuba_instrument;
	tubasound(self.enemy, 1);
}

void Ent_TubaNote_StopSound()
{
	self.enemy.nextthink = time;
	self.enemy = world;
}

void Ent_TubaNote(bool isNew)
{
	bool upd = false;
	int f = ReadByte();
	if (f & 1) {
		int n = ReadChar();
		int i = ReadByte();
		bool att = (i & 1);
		i >>= 1;

		if (self.enemy) {
			if (n != self.note || i != self.tuba_instrument || isNew) {
				Ent_TubaNote_StopSound();
			}
		} else {
			self.enemy = spawn();
			self.enemy.classname = "tuba_note";
			if (Tuba_PitchStep) {
				self.enemy.enemy = spawn();
				self.enemy.enemy.classname = "tuba_note_2";
			}
			isNew = true;
		}

		self.enemy.tuba_attenuate = att;

		if (isNew) {
			self.note = n;
			self.tuba_instrument = i;
			upd = true;
		}
	}

	if (f & 2) {
		self.enemy.origin_x = ReadCoord();
		self.enemy.origin_y = ReadCoord();
		self.enemy.origin_z = ReadCoord();
		setorigin(self.enemy, self.enemy.origin);
		if (self.enemy.enemy) {
			setorigin(self.enemy.enemy, self.enemy.origin);
		}
	}

	self.think = Ent_TubaNote_StopSound;
	self.entremove = Ent_TubaNote_StopSound;
	self.enemy.think = Ent_TubaNote_Think;
	self.enemy.nextthink = time + 10;

	if (upd) {
		Ent_TubaNote_UpdateSound();
	}
}

void Tuba_Precache()
{
	Tuba_PitchStep = autocvar_g_balance_tuba_pitchstep;
	if (Tuba_PitchStep) {
		if (!checkextension("DP_SND_SOUND7_WIP2") && !checkextension("DP_SND_SOUND7")) {
			print("^1NOTE:^7 requested pitch shifting, but not supported by this engine build\n");
			Tuba_PitchStep = 0;
		}
	}
	for (int n = TUBA_MIN; n <= TUBA_MAX; ++n) {
		if (!Tuba_PitchStep || pymod(n, Tuba_PitchStep) == 0) {
			for (int i = 0; i < TUBA_INSTRUMENTS; ++i) {
				precache_sound(TUBA_STARTNOTE(i, n));
			}
		}
	}
}
