#ifndef IMPLEMENTATION
CLASS(Tuba, Weapon)
/* impulse   */ ATTRIB(Tuba, impulse, int, 1)
/* flags     */ ATTRIB(Tuba, spawnflags, int, WEP_FLAG_HIDDEN | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Tuba, bot_pickupbasevalue, float, BOT_PICKUP_RATING_MID);
/* color     */ ATTRIB(Tuba, wpcolor, vector, '0 1 0');
/* modelname */ ATTRIB(Tuba, mdl, string, "tuba");
#ifndef MENUQC
/* model     */ ATTRIB(Tuba, m_model, Model, MDL_TUBA_ITEM);
#endif
/* crosshair */ ATTRIB(Tuba, w_crosshair, string, "gfx/crosshairtuba");
/* crosshair */ //ATTRIB(Tuba, w_crosshair_size, float, 0.65);
/* wepimg    */ ATTRIB(Tuba, model2, string, "weapontuba");
/* refname   */ ATTRIB(Tuba, netname, string, "tuba");
/* xgettext:no-c-format */
/* wepname   */ ATTRIB(Tuba, m_name, string, _("@!#%'n Tuba"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, animtime, float, NONE) \
		P(class, prefix, attenuation, float, NONE) \
		P(class, prefix, damage, float, NONE) \
		P(class, prefix, edgedamage, float, NONE) \
		P(class, prefix, fadetime, float, NONE) \
		P(class, prefix, force, float, NONE) \
		P(class, prefix, pitchstep, float, NONE) \
		P(class, prefix, radius, float, NONE) \
		P(class, prefix, refire, float, NONE) \
		P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, volume, float, NONE) \
		P(class, prefix, weaponreplace, string, NONE) \
		P(class, prefix, weaponstartoverride, float, NONE) \
		P(class, prefix, weaponstart, float, NONE) \
		P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, Tuba, tuba)
#undef X
ENDCLASS(Tuba)
REGISTER_WEAPON(TUBA, tuba, NEW(Tuba));
#endif

#ifdef IMPLEMENTATION

#ifdef SVQC

.entity tuba_note;
.float tuba_smoketime;
.float tuba_instrument;

#define MAX_TUBANOTES 32
.float tuba_lastnotes_last;
.float tuba_lastnotes_cnt; // over
.vector tuba_lastnotes[MAX_TUBANOTES];

spawnfunc(weapon_tuba) { weapon_defaultspawnfunc(this, WEP_TUBA); }

bool W_Tuba_HasPlayed(entity pl, string melody, int instrument, bool ignorepitch, float mintempo, float maxtempo)
{
	float i, j, mmin, mmax, nolength;
	float n = tokenize_console(melody);
	if(n > pl.tuba_lastnotes_cnt)
		return false;
	float pitchshift = 0;

	if(instrument >= 0)
		if(pl.tuba_instrument != instrument)
			return false;

	// verify notes...
	nolength = false;
	for(i = 0; i < n; ++i)
	{
		vector v = pl.(tuba_lastnotes[(pl.tuba_lastnotes_last - i + MAX_TUBANOTES) % MAX_TUBANOTES]);
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
			vector vi = pl.(tuba_lastnotes[(pl.tuba_lastnotes_last - i + MAX_TUBANOTES) % MAX_TUBANOTES]);
			float ai = stof(argv(n - i - 1));
			ti -= 1 / (ai - floor(ai));
			float tj = ti;
			for(j = i+1; j < n; ++j)
			{
				vector vj = pl.(tuba_lastnotes[(pl.tuba_lastnotes_last - j + MAX_TUBANOTES) % MAX_TUBANOTES]);
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

	pl.tuba_lastnotes_cnt = 0;

	return true;
}

void W_Tuba_NoteOff(entity this)
{
	entity actor = this.owner;
	// we have a note:
	//   on: this.spawnshieldtime
	//   off: time
	//   note: this.cnt
	if (actor.tuba_note == this)
	{
		actor.tuba_lastnotes_last = (actor.tuba_lastnotes_last + 1) % MAX_TUBANOTES;
		actor.(tuba_lastnotes[actor.tuba_lastnotes_last]) = eX * this.spawnshieldtime + eY * time + eZ * this.cnt;
		actor.tuba_note = NULL;
		actor.tuba_lastnotes_cnt = bound(0, actor.tuba_lastnotes_cnt + 1, MAX_TUBANOTES);

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
	remove(this);
}

int W_Tuba_GetNote(entity pl, int hittype)
{
	float movestate = 5;
	if (pl.movement.x < 0)		movestate -= 3;
	else if (pl.movement.x > 0)	movestate += 3;
	if (pl.movement.y < 0)		movestate -= 1;
	else if (pl.movement.y > 0)	movestate += 1;

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
	if(pl.BUTTON_CROUCH)
		note -= 12;
	if(pl.BUTTON_JUMP)
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
		WriteCoord(MSG_ENTITY, this.origin.x);
		WriteCoord(MSG_ENTITY, this.origin.y);
		WriteCoord(MSG_ENTITY, this.origin.z);
	}
	return true;
}

void W_Tuba_NoteThink()
{SELFPARAM();
	float dist_mult;
	float vol0, vol1;
	vector dir0, dir1;
	vector v;
	if(time > self.teleport_time)
	{
		W_Tuba_NoteOff(this);
		return;
	}
	self.nextthink = time;
	dist_mult = WEP_CVAR(tuba, attenuation) / autocvar_snd_soundradius;
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != self.realowner, LAMBDA(
		v = self.origin - (it.origin + it.view_ofs);
		vol0 = max(0, 1 - vlen(v) * dist_mult);
		dir0 = normalize(v);
		v = self.realowner.origin - (it.origin + it.view_ofs);
		vol1 = max(0, 1 - vlen(v) * dist_mult);
		dir1 = normalize(v);
		if(fabs(vol0 - vol1) > 0.005) // 0.5 percent change in volume
		{
			setorigin(self, self.realowner.origin);
			self.SendFlags |= 2;
			break;
		}
		if(dir0 * dir1 < 0.9994) // 2 degrees change in angle
		{
			setorigin(self, self.realowner.origin);
			self.SendFlags |= 2;
			break;
		}
	));
}

void W_Tuba_NoteOn(float hittype)
{SELFPARAM();
	vector o;
	float n;

	W_SetupShot(self, false, 2, "", 0, WEP_CVAR(tuba, damage));

	n = W_Tuba_GetNote(self, hittype);

	hittype = 0;
	if(self.tuba_instrument & 1)
		hittype |= HITTYPE_SECONDARY;
	if(self.tuba_instrument & 2)
		hittype |= HITTYPE_BOUNCE;

	if(self.tuba_note)
	{
		if(self.tuba_note.cnt != n || self.tuba_note.tuba_instrument != self.tuba_instrument)
		{
			W_Tuba_NoteOff(self.tuba_note);
		}
	}

	if(!self.tuba_note)
	{
		self.tuba_note = new(tuba_note);
		self.tuba_note.owner = self.tuba_note.realowner = self;
		self.tuba_note.cnt = n;
		self.tuba_note.tuba_instrument = self.tuba_instrument;
		self.tuba_note.think = W_Tuba_NoteThink;
		self.tuba_note.nextthink = time;
		self.tuba_note.spawnshieldtime = time;
		Net_LinkEntity(self.tuba_note, false, 0, W_Tuba_NoteSendEntity);
	}

	self.tuba_note.teleport_time = time + WEP_CVAR(tuba, refire) * 2 * W_WeaponRateFactor(); // so it can get prolonged safely

	//sound(self, c, TUBA_NOTE(n), bound(0, VOL_BASE * cvar("g_balance_tuba_volume"), 1), autocvar_g_balance_tuba_attenuation);
	RadiusDamage(self, self, WEP_CVAR(tuba, damage), WEP_CVAR(tuba, edgedamage), WEP_CVAR(tuba, radius), NULL, NULL, WEP_CVAR(tuba, force), hittype | WEP_TUBA.m_id, NULL);

	o = gettaginfo(self.exteriorweaponentity, 0);
	if(time > self.tuba_smoketime)
	{
		Send_Effect(EFFECT_SMOKE_RING, o + v_up * 45 + v_right * -6 + v_forward * 8, v_up * 100, 1);
		self.tuba_smoketime = time + 0.25;
	}
}
#endif

#ifdef SVQC
METHOD(Tuba, wr_aim, void(Tuba this))
{
	entity actor = self;
	// bots cannot play the Tuba well yet
	// I think they should start with the recorder first
	if (vdist((actor.origin - actor.enemy.origin), <, WEP_CVAR(tuba, radius)))
	{
		if (random() > 0.5)
			actor.BUTTON_ATCK = 1;
		else
			actor.BUTTON_ATCK2 = 1;
	}
}

METHOD(Tuba, wr_think, void(Tuba this, entity actor, .entity weaponentity, int fire))
{
	if (fire & 1)
	if (weapon_prepareattack(this, actor, weaponentity, false, WEP_CVAR(tuba, refire)))
	{
		W_Tuba_NoteOn(0);
		weapon_thinkf(actor, weaponentity, WFRAME_IDLE, WEP_CVAR(tuba, animtime), w_ready);
	}
	if (fire & 2)
	if (weapon_prepareattack(this, actor, weaponentity, true, WEP_CVAR(tuba, refire)))
	{
		W_Tuba_NoteOn(HITTYPE_SECONDARY);
		weapon_thinkf(actor, weaponentity, WFRAME_IDLE, WEP_CVAR(tuba, animtime), w_ready);
	}
	if (actor.tuba_note)
	{
		if (!(fire & 1) && !(fire & 2))
		{
			W_Tuba_NoteOff(actor.tuba_note);
		}
	}
}

METHOD(Tuba, wr_setup, void(Tuba this))
{
	entity actor = self;
	actor.ammo_field = ammo_none;
	actor.tuba_instrument = 0;
}
#endif

REGISTER_NET_S2C(tuba_instrument)
#ifdef CSQC
NET_HANDLE(tuba_instrument, bool)
{
	int i = ReadByte();
	return = true;
	string s = (i == 0) ? "tuba" :
	           (i == 1) ? "akordeon" :
	                      "kleinbottle" ;
	CL_WeaponEntity_SetModel(viewmodel, s);
}
#endif
#ifdef SVQC
void tuba_instrument_send(entity this, int instr)
{
	msg_entity = this;
	int chan = MSG_ONE;
	WriteHeader(chan, tuba_instrument);
	WriteByte(chan, instr);
}
SPECTATE_COPY()
{
	if (this.tuba_instrument != spectatee.tuba_instrument)
		tuba_instrument_send(this, this.tuba_instrument = spectatee.tuba_instrument);
}
METHOD(Tuba, wr_reload, void(Tuba this, entity actor, .entity weaponentity))
{
	// switch to alternate instruments :)
	if (actor.(weaponentity).state == WS_READY)
	{
		switch (actor.tuba_instrument)
		{
			case 0:
				actor.tuba_instrument = 1;
				actor.weaponname = "akordeon";
				break;
			case 1:
				actor.tuba_instrument = 2;
				actor.weaponname = "kleinbottle";
				break;
			case 2:
				actor.tuba_instrument = 0;
				actor.weaponname = "tuba";
				break;
		}
		tuba_instrument_send(actor, actor.tuba_instrument);
		W_SetupShot(actor, false, 0, "", 0, 0);
		Send_Effect(EFFECT_TELEPORT, w_shotorg, '0 0 0', 1);
		actor.(weaponentity).state = WS_INUSE;
		weapon_thinkf(actor, weaponentity, WFRAME_RELOAD, 0.5, w_ready);
	}
}
#endif

#ifdef SVQC

// infinite ammo
METHOD(Tuba, wr_checkammo1, bool(Tuba this)) { return true; }
METHOD(Tuba, wr_checkammo2, bool(Tuba this)) { return true; }

METHOD(Tuba, wr_suicidemessage, int(Tuba this))
{
	if (w_deathtype & HITTYPE_BOUNCE)
		return WEAPON_KLEINBOTTLE_SUICIDE;
	else if (w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_ACCORDEON_SUICIDE;
	else
		return WEAPON_TUBA_SUICIDE;
}
METHOD(Tuba, wr_killmessage, int(Tuba this))
{
	if (w_deathtype & HITTYPE_BOUNCE)
		return WEAPON_KLEINBOTTLE_MURDER;
	else if (w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_ACCORDEON_MURDER;
	else
		return WEAPON_TUBA_MURDER;
}

#endif

#ifdef CSQC

#define TUBA_STARTNOTE(i, n) _Sound_fixpath(W_Sound(strcat("tuba", (i ? ftos(i) : ""), "_loopnote", ftos(n))))

const int TUBA_MIN = -18;
const int TUBA_MAX = 27;
const int TUBA_INSTRUMENTS = 3;

entityclass(Tuba);
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
		_sound(e, CH_TUBA_SINGLE, snd1, e.tuba_volume, e.tuba_attenuate * autocvar_g_balance_tuba_attenuation);
	}
}

void Ent_TubaNote_Think()
{SELFPARAM();
	float f = autocvar_g_balance_tuba_fadetime;
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
			remove(this.enemy);
		}
		remove(this);
	} else {
		tubasound(this, 0);
	}
}

void Ent_TubaNote_UpdateSound(entity this)
{
	this.enemy.tuba_volume = bound(0, VOL_BASE * autocvar_g_balance_tuba_volume, 1);
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

void Ent_TubaNote_StopSound_self() { Ent_TubaNote_StopSound(self); }

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
		this.enemy.origin_x = ReadCoord();
		this.enemy.origin_y = ReadCoord();
		this.enemy.origin_z = ReadCoord();
		setorigin(this.enemy, this.enemy.origin);
		if (this.enemy.enemy) {
			setorigin(this.enemy.enemy, this.enemy.origin);
		}
	}

	this.think = Ent_TubaNote_StopSound_self;
	this.entremove = Ent_TubaNote_StopSound;
	this.enemy.think = Ent_TubaNote_Think;
	this.enemy.nextthink = time + 10;

	if (upd) {
		Ent_TubaNote_UpdateSound(this);
	}
	return true;
}

PRECACHE(Tuba)
{
	Tuba_PitchStep = autocvar_g_balance_tuba_pitchstep;
	if (Tuba_PitchStep) {
		if (!checkextension("DP_SND_SOUND7_WIP2") && !checkextension("DP_SND_SOUND7")) {
			LOG_WARNING("requested pitch shifting, but not supported by this engine build");
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
#endif
