#include "tuba.qh"

#ifdef SVQC

.entity tuba_note;
.float tuba_smoketime;

#define MAX_TUBANOTES 32
.float tuba_lastnotes_last;
.float tuba_lastnotes_cnt; // over
.vector tuba_lastnotes[MAX_TUBANOTES];

bool W_Tuba_HasPlayed(entity pl, .entity weaponentity, string melody, int instrument, bool ignorepitch, float mintempo, float maxtempo)
{
	float i, j, mmin, mmax, nolength;
	float n = tokenize_console(melody);
	if(n > pl.(weaponentity).tuba_lastnotes_cnt)
		return false;
	float pitchshift = 0;

	if(instrument >= 0)
		if(pl.(weaponentity).tuba_instrument != instrument)
			return false;

	// verify notes...
	nolength = false;
	for(i = 0; i < n; ++i)
	{
		vector v = pl.(weaponentity).(tuba_lastnotes[(pl.(weaponentity).tuba_lastnotes_last - i + MAX_TUBANOTES) % MAX_TUBANOTES]);
		float ai = stof(argv(n - i - 1));
		float np = floor(ai);
		if(ai == np)
			nolength = true;
		// n counts the last played notes BACKWARDS
		// _x is start
		// _y is end
		// _z is note pitch
		if(ignorepitch && i == 0)
		{
			pitchshift = np - v.z;
		}
		else
		{
			if(v.z + pitchshift != np)
				return false;
		}
	}

	// now we know the right NOTES were played
	if(!nolength)
	{
		// verify rhythm...
		float ti = 0;
		if(maxtempo > 0)
			mmin = 240 / maxtempo; // 60 = "0.25 means 1 sec", at 120 0.5 means 1 sec, at 240 1 means 1 sec
		else
			mmin = 0;
		if(mintempo > 0)
			mmax = 240 / mintempo; // 60 = "0.25 means 1 sec", at 120 0.5 means 1 sec, at 240 1 means 1 sec
		else
			mmax = 240; // you won't try THAT hard... (tempo 1)
		//printf("initial tempo rules: %f %f\n", mmin, mmax);

		for(i = 0; i < n; ++i)
		{
			vector vi = pl.(weaponentity).(tuba_lastnotes[(pl.(weaponentity).tuba_lastnotes_last - i + MAX_TUBANOTES) % MAX_TUBANOTES]);
			float ai = stof(argv(n - i - 1));
			ti -= 1 / (ai - floor(ai));
			float tj = ti;
			for(j = i+1; j < n; ++j)
			{
				vector vj = pl.(weaponentity).(tuba_lastnotes[(pl.(weaponentity).tuba_lastnotes_last - j + MAX_TUBANOTES) % MAX_TUBANOTES]);
				float aj = stof(argv(n - j - 1));
				tj -= (aj - floor(aj));

				// note i should be at m*ti+b
				// note j should be at m*tj+b
				// so:
				// we have a LINE l, so that
				// vi_x <= l(ti) <= vi_y
				// vj_x <= l(tj) <= vj_y
				// what is m?

				// vi_x <= vi_y <= vj_x <= vj_y
				// ti <= tj
				//printf("first note: %f to %f, should be %f\n", vi_x, vi_y, ti);
				//printf("second note: %f to %f, should be %f\n", vj_x, vj_y, tj);
				//printf("m1 = %f\n", (vi_x - vj_y) / (ti - tj));
				//printf("m2 = %f\n", (vi_y - vj_x) / (ti - tj));
				mmin = max(mmin, (vi.x - vj.y) / (ti - tj)); // lower bound
				mmax = min(mmax, (vi.y - vj.x) / (ti - tj)); // upper bound
			}
		}

		if(mmin > mmax) // rhythm fail
			return false;
	}

	pl.(weaponentity).tuba_lastnotes_cnt = 0;

	return true;
}

void W_Tuba_NoteOff(entity this)
{
	entity actor = this.owner;
	// we have a note:
	//   on: this.spawnshieldtime
	//   off: time
	//   note: this.cnt
	.entity weaponentity = this.weaponentity_fld;
	if (actor.(weaponentity).tuba_note == this)
	{
		actor.(weaponentity).tuba_lastnotes_last = (actor.(weaponentity).tuba_lastnotes_last + 1) % MAX_TUBANOTES;
		actor.(weaponentity).(tuba_lastnotes[actor.(weaponentity).tuba_lastnotes_last]) = vec3(this.spawnshieldtime, time, this.cnt);
		actor.(weaponentity).tuba_note = NULL;
		actor.(weaponentity).tuba_lastnotes_cnt = bound(0, actor.(weaponentity).tuba_lastnotes_cnt + 1, MAX_TUBANOTES);

		string s = trigger_magicear_processmessage_forallears(actor, 0, NULL, string_null);
		if (s != "")
		{
			// simulate a server message
			switch (this.tuba_instrument)
			{
				default:
				case 0: // Tuba
					bprint(strcat("\{1}\{13}* ^3", actor.netname, "^3 played on the @!#%'n Tuba: ^7", s, "\n"));
					break;
				case 1:
					bprint(strcat("\{1}\{13}* ^3", actor.netname, "^3 played on the @!#%'n Accordeon: ^7", s, "\n"));
					break;
				case 2:
					bprint(strcat("\{1}\{13}* ^3", actor.netname, "^3 played on the @!#%'n Klein Bottle: ^7", s, "\n"));
					break;
			}
		}
	}
	delete(this);
}

int W_Tuba_GetNote(entity pl, int hittype)
{
	float movestate = 5;
	if (CS(pl).movement.x < 0)		movestate -= 3;
	else if (CS(pl).movement.x > 0)	movestate += 3;
	if (CS(pl).movement.y < 0)		movestate -= 1;
	else if (CS(pl).movement.y > 0)	movestate += 1;

	int note = 0;
	switch (movestate)
	{
	// layout: originally I wanted
	//   eb e  e#=f
	//   B  c  d
	//   Gb G  G#
	// but then you only use forward and right key. So to make things more
	// interesting, I swapped B with e#. Har har har...
	//   eb e  B
	// f=e# c  d
	//   Gb G  G#
		case 1: note = -6; break; // Gb
		case 2: note = -5; break; // G
		case 3: note = -4; break; // G#
		case 4: note = +5; break; // e#
		default:
		case 5: note =  0; break; // c
		case 6: note = +2; break; // d
		case 7: note = +3; break; // eb
		case 8: note = +4; break; // e
		case 9: note = -1; break; // B
	}
	if(PHYS_INPUT_BUTTON_CROUCH(pl))
		note -= 12;
	if(PHYS_INPUT_BUTTON_JUMP(pl))
		note += 12;
	if(hittype & HITTYPE_SECONDARY)
		note += 7;

	// we support two kinds of tubas, those tuned in Eb and those tuned in C
	// kind of tuba currently is player slot number, or team number if in
	// teamplay
	// that way, holes in the range of notes are "plugged"
	if(teamplay)
	{
		if(pl.team == NUM_TEAM_2 || pl.team == NUM_TEAM_4)
			note += 3;
	}
	else
	{
		if(pl.clientcolors & 1)
			note += 3;
	}

	// total range of notes:
	//                       0
	//                 ***  ** ****
	//                        ***  ** ****
	//     ***  ** ****
	//            ***  ** ****
	//     ***  ********************* ****
	//     -18.........................+12
	//        ***  ********************* ****
	//     -18............................+15
	//     with jump: ... +24
	//     ... +27
	return note;
}

bool W_Tuba_NoteSendEntity(entity this, entity to, int sf)
{
	msg_entity = to;
	if (!sound_allowed(MSG_ONE, this.realowner)) return false;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_TUBANOTE);
	WriteByte(MSG_ENTITY, sf);
	if (sf & 1)
	{
		WriteChar(MSG_ENTITY, this.cnt);
		int f = 0;
		f |= 1 * (this.realowner != to);
		f |= 2 * this.tuba_instrument;
		WriteByte(MSG_ENTITY, f);
	}
	if (sf & 2)
	{
		WriteVector(MSG_ENTITY, this.origin);
	}
	return true;
}

void W_Tuba_NoteThink(entity this)
{
	float dist_mult;
	float vol0, vol1;
	vector dir0, dir1;
	vector v;
	if(time > this.teleport_time)
	{
		W_Tuba_NoteOff(this);
		return;
	}
	this.nextthink = time;
	dist_mult = WEP_CVAR(WEP_TUBA, attenuation) / autocvar_snd_soundradius;
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != this.realowner, {
		v = this.origin - (it.origin + it.view_ofs);
		vol0 = max(0, 1 - vlen(v) * dist_mult);
		dir0 = normalize(v);
		v = this.realowner.origin - (it.origin + it.view_ofs);
		vol1 = max(0, 1 - vlen(v) * dist_mult);
		dir1 = normalize(v);
		if(fabs(vol0 - vol1) > 0.005) // 0.5 percent change in volume
		{
			setorigin(this, this.realowner.origin);
			this.SendFlags |= 2;
			break;
		}
		if(dir0 * dir1 < 0.9994) // 2 degrees change in angle
		{
			setorigin(this, this.realowner.origin);
			this.SendFlags |= 2;
			break;
		}
	});
}

void W_Tuba_NoteOn(entity actor, .entity weaponentity, float hittype)
{
	float n = W_Tuba_GetNote(actor, hittype);

	hittype = HITTYPE_SOUND;
	if(actor.(weaponentity).tuba_instrument & 1)
		hittype |= HITTYPE_SECONDARY;
	if(actor.(weaponentity).tuba_instrument & 2)
		hittype |= HITTYPE_BOUNCE;

	W_SetupShot(actor, weaponentity, false, 2, SND_Null, 0, WEP_CVAR(WEP_TUBA, damage), hittype | WEP_TUBA.m_id);

	if(actor.(weaponentity).tuba_note)
	{
		if(actor.(weaponentity).tuba_note.cnt != n || actor.(weaponentity).tuba_note.tuba_instrument != actor.(weaponentity).tuba_instrument)
		{
			W_Tuba_NoteOff(actor.(weaponentity).tuba_note);
		}
	}

	if(!actor.(weaponentity).tuba_note)
	{
		entity note = new(tuba_note);
		note.weaponentity_fld = weaponentity;
		actor.(weaponentity).tuba_note = note;
		note.owner = note.realowner = actor;
		note.cnt = n;
		note.tuba_instrument = actor.(weaponentity).tuba_instrument;
		setthink(note, W_Tuba_NoteThink);
		note.nextthink = time;
		note.spawnshieldtime = time;
		Net_LinkEntity(note, false, 0, W_Tuba_NoteSendEntity);
	}

	actor.(weaponentity).tuba_note.teleport_time = time + WEP_CVAR(WEP_TUBA, refire) * 2 * W_WeaponRateFactor(actor); // so it can get prolonged safely

	//sound(actor, c, TUBA_NOTE(n), bound(0, VOL_BASE * autocvar_cl_tuba_volume, 1), autocvar_cl_tuba_attenuation);
	RadiusDamage(actor, actor, WEP_CVAR(WEP_TUBA, damage), WEP_CVAR(WEP_TUBA, edgedamage), WEP_CVAR(WEP_TUBA, radius), NULL, NULL, WEP_CVAR(WEP_TUBA, force), hittype | WEP_TUBA.m_id, weaponentity, NULL);

	if(time > actor.(weaponentity).tuba_smoketime)
	{
		// FIXME gettaginfo(actor.(weaponentity), 0) doesn't return the real origin of the weapon
		vector org = gettaginfo(actor.(weaponentity), 0);
		if(actor.(weaponentity).tuba_instrument == 1)
			Send_Effect(EFFECT_SMOKE_RING, org + v_up * 25 + v_right * 10 + v_forward * 14, v_up * 100, 1);
		else if(actor.(weaponentity).tuba_instrument == 2)
			Send_Effect(EFFECT_SMOKE_RING, org + v_up * 50 + v_right * 10 + v_forward * 45, v_up * 100, 1);
		else
			Send_Effect(EFFECT_SMOKE_RING, org + v_up * 40 + v_right * 10 + v_forward * 14, v_up * 100, 1);
		actor.(weaponentity).tuba_smoketime = time + 0.25;
	}
}
#endif

#ifdef SVQC
METHOD(Tuba, wr_aim, void(Tuba this, entity actor, .entity weaponentity))
{
	// bots cannot play the Tuba well yet
	// I think they should start with the recorder first
	if (vdist((actor.origin - actor.enemy.origin), <, WEP_CVAR(WEP_TUBA, radius)))
	{
		if (random() > 0.5)
			PHYS_INPUT_BUTTON_ATCK(actor) = true;
		else
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
	}
}

METHOD(Tuba, wr_think, void(Tuba this, entity actor, .entity weaponentity, int fire))
{
	if (fire & 1)
	if (weapon_prepareattack(this, actor, weaponentity, false, WEP_CVAR(WEP_TUBA, refire)))
	{
		W_Tuba_NoteOn(actor, weaponentity, 0);
		weapon_thinkf(actor, weaponentity, WFRAME_IDLE, WEP_CVAR(WEP_TUBA, animtime), w_ready);
	}
	if (fire & 2)
	if (weapon_prepareattack(this, actor, weaponentity, true, WEP_CVAR(WEP_TUBA, refire)))
	{
		W_Tuba_NoteOn(actor, weaponentity, HITTYPE_SECONDARY);
		weapon_thinkf(actor, weaponentity, WFRAME_IDLE, WEP_CVAR(WEP_TUBA, animtime), w_ready);
	}
	if (actor.(weaponentity).tuba_note)
	{
		if (!(fire & (1 | 2)))
		{
			W_Tuba_NoteOff(actor.(weaponentity).tuba_note);
		}
	}
}

METHOD(Tuba, wr_setup, void(Tuba this, entity actor, .entity weaponentity))
{
	actor.(weaponentity).tuba_instrument = 0;
}

METHOD(Tuba, wr_reload, void(Tuba this, entity actor, .entity weaponentity))
{
	// switch to alternate instruments :)
	if (actor.(weaponentity).state == WS_READY)
	{
		switch (actor.(weaponentity).tuba_instrument)
		{
			case 0:
				actor.(weaponentity).tuba_instrument = 1;
				actor.(weaponentity).weaponname = "akordeon";
				break;
			case 1:
				actor.(weaponentity).tuba_instrument = 2;
				actor.(weaponentity).weaponname = "kleinbottle";
				break;
			case 2:
				actor.(weaponentity).tuba_instrument = 0;
				actor.(weaponentity).weaponname = "tuba";
				break;
		}
		int hittype = 0;
		if(actor.(weaponentity).tuba_instrument & 1)
			hittype |= HITTYPE_SECONDARY;
		if(actor.(weaponentity).tuba_instrument & 2)
			hittype |= HITTYPE_BOUNCE;
		W_SetupShot(actor, weaponentity, false, 0, SND_Null, 0, 0, hittype | WEP_TUBA.m_id);
		Send_Effect(EFFECT_TELEPORT, w_shotorg, '0 0 0', 1);
		actor.(weaponentity).state = WS_INUSE;
		weapon_thinkf(actor, weaponentity, WFRAME_RELOAD, 0.5, w_ready);
	}
}
#endif

#ifdef SVQC

// infinite ammo
METHOD(Tuba, wr_checkammo1, bool(Tuba this, entity actor, .entity weaponentity)) { return true; }
METHOD(Tuba, wr_checkammo2, bool(Tuba this, entity actor, .entity weaponentity)) { return true; }

METHOD(Tuba, wr_suicidemessage, Notification(Tuba this))
{
	if (w_deathtype & HITTYPE_BOUNCE)
		return WEAPON_KLEINBOTTLE_SUICIDE;
	else if (w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_ACCORDEON_SUICIDE;
	else
		return WEAPON_TUBA_SUICIDE;
}
METHOD(Tuba, wr_killmessage, Notification(Tuba this))
{
	if (w_deathtype & HITTYPE_BOUNCE)
		return WEAPON_KLEINBOTTLE_MURDER;
	else if (w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_ACCORDEON_MURDER;
	else
		return WEAPON_TUBA_MURDER;
}

#elif defined(CSQC)

METHOD(Tuba, wr_viewmodel, string(Tuba this, entity wep))
{
	return (wep.tuba_instrument == 0) ? "tuba" :
	       (wep.tuba_instrument == 1) ? "akordeon" :
	                                    "kleinbottle";
}

#endif

#ifdef CSQC

#define TUBA_STARTNOTE(i, n) _Sound_fixpath(W_Sound(strcat("tuba", (i ? ftos(i) : ""), "_loopnote", ftos(n))))

const int TUBA_MIN = -18;
const int TUBA_MAX = 27;
const int TUBA_INSTRUMENTS = 3;

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
				speed1 = (2.0 ** ((m - Tuba_PitchStep) / 12.0));
			} else if (e.note - m + Tuba_PitchStep > TUBA_MAX) {
				if (restart) {
					snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note - m);
				}
				speed1 = (2.0 ** (m / 12.0));
			} else {
				if (restart) {
					snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note - m);
				}
				vol1 = cos(M_PI_2 * m / Tuba_PitchStep);
				speed1 = (2.0 ** (m / 12.0));
				if (restart) {
					snd2 = TUBA_STARTNOTE(e.tuba_instrument, e.note - m + Tuba_PitchStep);
				}
				vol2 = sin(M_PI_2 * m / Tuba_PitchStep);
				speed2 = (2.0 ** ((m - Tuba_PitchStep) / 12.0));
			}
		} else if (restart) {
			snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note);
		}

		sound7(e, CH_TUBA_SINGLE, snd1, e.tuba_volume * vol1, e.tuba_attenuate * autocvar_cl_tuba_attenuation, 100 * speed1, 0);
		if (vol2) {
			sound7(e.enemy, CH_TUBA_SINGLE, snd2, e.tuba_volume * vol2, e.tuba_attenuate * autocvar_cl_tuba_attenuation, 100 * speed2, 0);
		}
	} else {
		if (restart) {
			snd1 = TUBA_STARTNOTE(e.tuba_instrument, e.note);
		}
		_sound(e, CH_TUBA_SINGLE, snd1, e.tuba_volume, e.tuba_attenuate * autocvar_cl_tuba_attenuation);
	}
}

void Ent_TubaNote_Think(entity this)
{
	float f = autocvar_cl_tuba_fadetime;
	if (f > 0) {
		this.tuba_volume -= frametime * this.tuba_volume_initial / f;
	} else {
		this.tuba_volume = 0;
	}
	this.nextthink = time;
	if (this.tuba_volume <= 0) {
		sound(this, CH_TUBA_SINGLE, SND_Null, 0, 0);
		if (this.enemy) {
			sound(this.enemy, CH_TUBA_SINGLE, SND_Null, 0, 0);
			delete(this.enemy);
		}
		delete(this);
	} else {
		tubasound(this, 0);
	}
}

void Ent_TubaNote_UpdateSound(entity this)
{
	this.enemy.tuba_volume = bound(0, VOL_BASE * autocvar_cl_tuba_volume, 1);
	this.enemy.tuba_volume_initial = this.enemy.tuba_volume;
	this.enemy.note = this.note;
	this.enemy.tuba_instrument = this.tuba_instrument;
	tubasound(this.enemy, 1);
}

void Ent_TubaNote_StopSound(entity this)
{
	this.enemy.nextthink = time;
	this.enemy = NULL;
}

NET_HANDLE(ENT_CLIENT_TUBANOTE, bool isNew)
{
	bool upd = false;
	int f = ReadByte();
	if (f & 1) {
		int n = ReadChar();
		int i = ReadByte();
		bool att = (i & 1);
		i >>= 1;

		if (this.enemy) {
			if (n != this.note || i != this.tuba_instrument || isNew) {
				Ent_TubaNote_StopSound(this);
			}
		} else {
			this.enemy = new(tuba_note);
			if (Tuba_PitchStep) {
				this.enemy.enemy = new(tuba_note_2);
			}
			isNew = true;
		}

		this.enemy.tuba_attenuate = att;

		if (isNew) {
			this.note = n;
			this.tuba_instrument = i;
			upd = true;
		}
	}

	if (f & 2) {
		this.enemy.origin = ReadVector();
		setorigin(this.enemy, this.enemy.origin);
		if (this.enemy.enemy) {
			setorigin(this.enemy.enemy, this.enemy.origin);
		}
	}

	setthink(this, Ent_TubaNote_StopSound);
	this.entremove = Ent_TubaNote_StopSound;
	setthink(this.enemy, Ent_TubaNote_Think);
	this.enemy.nextthink = time + 10;

	if (upd) {
		Ent_TubaNote_UpdateSound(this);
	}
	return true;
}

PRECACHE(Tuba)
{
	Tuba_PitchStep = autocvar_cl_tuba_pitchstep;
	if (Tuba_PitchStep) {
		if (!checkextension("DP_SND_SOUND7_WIP2") && !checkextension("DP_SND_SOUND7")) {
			LOG_WARN("requested pitch shifting, but not supported by this engine build");
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

#endif
#ifdef MENUQC

METHOD(Tuba, describe, string(Tuba this))
{
	TC(Tuba, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s is a unique weapon that makes the ears of nearby enemies bleed by playing awful sounds, also slightly knocking them back."), COLORED_NAME(this));
	PAR(_("The secondary fire works the same way, playing a higher pitch."));
	PAR(_("The only ammo it needs to operate is the breath from your lungs."));
	PAR(_("Since your enemies need to be close by to hear your rubbish music, the %s is only effective at very close ranges."), COLORED_NAME(this));
	PAR(_("The pitch the %s plays depends on the movement keys pressed."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne_unnamed(this.netname));
	return PAGE_TEXT;
}

#endif
