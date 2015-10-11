#include "projectile.qh"

#include "../autocvars.qh"
#include "../defs.qh"
#include "../main.qh"
#include "../mutators/events.qh"

#include "../../common/constants.qh"
#include "../../common/nades/all.qh"
#include "../../common/movetypes/movetypes.qh"

#include "../../lib/csqcmodel/interpolate.qh"

#include "../../lib/warpzone/anglestransform.qh"

.float alpha;
.float scale;
.vector colormod;

void SUB_Stop()
{SELFPARAM();
	self.move_velocity = self.move_avelocity = '0 0 0';
	self.move_movetype = MOVETYPE_NONE;
}

void Projectile_ResetTrail(entity this, vector to)
{
	this.trail_oldorigin = to;
	this.trail_oldtime = time;
}

void Projectile_DrawTrail(entity this, vector to)
{
	vector from = this.trail_oldorigin;
	// float t0 = this.trail_oldtime;
	this.trail_oldorigin = to;
	this.trail_oldtime = time;

	// force the effect even for stationary firemine
	if(this.cnt == PROJECTILE_FIREMINE)
		if(from == to)
			from.z += 1;

	if (this.traileffect)
	{
		particles_alphamin = particles_alphamax = particles_fade = sqrt(this.alpha);
		boxparticles(particleeffectnum(Effects[this.traileffect]), this, from, to, this.velocity, this.velocity, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE | PARTICLES_DRAWASTRAIL);
	}
}

void Projectile_Draw(entity this)
{
	vector rot;
	vector trailorigin;
	int f;
	bool drawn;
	float t;
	float a;

	f = self.move_flags;

	if(self.count & 0x80)
	{
		//self.move_flags &= ~FL_ONGROUND;
		if(self.move_movetype == MOVETYPE_NONE || self.move_movetype == MOVETYPE_FLY)
			Movetype_Physics_NoMatchServer();
			// the trivial movetypes do not have to match the
			// server's ticrate as they are ticrate independent
			// NOTE: this assumption is only true if MOVETYPE_FLY
			// projectiles detonate on impact. If they continue
			// moving, we might still be ticrate dependent.
		else
			Movetype_Physics_MatchServer(autocvar_cl_projectiles_sloppy);
		if(!(self.move_flags & FL_ONGROUND))
			if(self.velocity != '0 0 0')
				self.move_angles = self.angles = vectoangles(self.velocity);
	}
	else
	{
		InterpolateOrigin_Do();
	}

	if(self.count & 0x80)
	{
		drawn = (time >= self.spawntime - 0.02);
		t = max(time, self.spawntime);
	}
	else
	{
		drawn = (self.iflags & IFLAG_VALID);
		t = time;
	}

	if(!(f & FL_ONGROUND))
	{
		rot = '0 0 0';
		switch(self.cnt)
		{
			/*
			case PROJECTILE_GRENADE:
				rot = '-2000 0 0'; // forward
				break;
			*/
			case PROJECTILE_GRENADE_BOUNCING:
				rot = '0 -1000 0'; // sideways
				break;
			case PROJECTILE_HOOKBOMB:
				rot = '1000 0 0'; // forward
				break;
			default:
				break;
		}

		if(Nade_FromProjectile(self.cnt) != NADE_TYPE_Null)
			rot = self.avelocity;

		self.angles = AnglesTransform_ToAngles(AnglesTransform_Multiply(AnglesTransform_FromAngles(self.angles), rot * (t - self.spawntime)));
	}

	vector ang;
	ang = self.angles;
	ang.x = -ang.x;
	makevectors(ang);

	a = 1 - (time - self.fade_time) * self.fade_rate;
	self.alpha = bound(0, self.alphamod * a, 1);
	if(self.alpha <= 0)
		drawn = 0;
	self.renderflags = 0;

	trailorigin = self.origin;
	switch(self.cnt)
	{
		case PROJECTILE_GRENADE:
		case PROJECTILE_GRENADE_BOUNCING:
			trailorigin += v_right * 1 + v_forward * -10;
			break;
		default:
			break;
	}

	if(Nade_FromProjectile(self.cnt) != NADE_TYPE_Null)
		trailorigin += v_up * 4;

	if(drawn)
		Projectile_DrawTrail(self, trailorigin);
	else
		Projectile_ResetTrail(self, trailorigin);

	self.drawmask = 0;

	if(!drawn)
		return;

	switch(self.cnt)
	{
		// Possibly add dlights here.
		default:
			break;
	}

	self.drawmask = MASK_NORMAL;
}

void loopsound(entity e, int ch, string samp, float vol, float attn)
{SELFPARAM();
	if(self.silent)
		return;

	_sound(e, ch, samp, vol, attn);
	e.snd_looping = ch;
}

void Ent_RemoveProjectile()
{SELFPARAM();
	if(self.count & 0x80)
	{
		tracebox(self.origin, self.mins, self.maxs, self.origin + self.velocity * 0.05, MOVE_NORMAL, self);
		Projectile_DrawTrail(self, trace_endpos);
	}
}

void Ent_Projectile()
{SELFPARAM();
	int f;

	// projectile properties:
	//   kind (interpolated, or clientside)
	//
	//   modelindex
	//   origin
	//   scale
	//   if clientside:
	//     velocity
	//     gravity
	//   soundindex (hardcoded list)
	//   effects
	//
	// projectiles don't send angles, because they always follow the velocity

	f = ReadByte();
	self.count = (f & 0x80);
	self.iflags = (self.iflags & IFLAG_INTERNALMASK) | IFLAG_AUTOANGLES | IFLAG_ANGLES | IFLAG_ORIGIN;
	self.solid = SOLID_TRIGGER;
	//self.effects = EF_NOMODELFLAGS;

	// this should make collisions with bmodels more exact, but it leads to
	// projectiles no longer being able to lie on a bmodel
	self.move_nomonsters = MOVE_WORLDONLY;
	if(f & 0x40)
		self.move_flags |= FL_ONGROUND;
	else
		self.move_flags &= ~FL_ONGROUND;

	if(!self.move_time)
	{
		// for some unknown reason, we don't need to care for
		// sv_gameplayfix_delayprojectiles here.
		self.move_time = time;
		self.spawntime = time;
	}
	else
		self.move_time = max(self.move_time, time);

	if(!(self.count & 0x80))
		InterpolateOrigin_Undo();

	if(f & 1)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
		if(self.count & 0x80)
		{
			self.velocity_x = ReadCoord();
			self.velocity_y = ReadCoord();
			self.velocity_z = ReadCoord();
			if(f & 0x10)
				self.gravity = ReadCoord();
			else
				self.gravity = 0; // none
			self.move_origin = self.origin;
			self.move_velocity = self.velocity;
		}

		if(time == self.spawntime || (self.count & 0x80) || (f & 0x08))
		{
			self.trail_oldorigin = self.origin;
			if(!(self.count & 0x80))
				InterpolateOrigin_Reset();
		}

		if(f & 0x20)
		{
			self.fade_time = time + ReadByte() * ticrate;
			self.fade_rate = 1 / (ReadByte() * ticrate);
		}
		else
		{
			self.fade_time = 0;
			self.fade_rate = 0;
		}

		self.team = ReadByte() - 1;
	}

	if(f & 2)
	{
		self.cnt = ReadByte();

		self.silent = (self.cnt & 0x80);
		self.cnt = (self.cnt & 0x7F);

		self.scale = 1;
		self.traileffect = 0;
		switch (self.cnt) {
#define CASE(id) case PROJECTILE_##id: setmodel(self, MDL_PROJECTILE_##id);
			CASE(ELECTRO)            self.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;
			CASE(ROCKET)             self.traileffect = EFFECT_TR_ROCKET.m_id; self.scale = 2; break;
			CASE(CRYLINK)            self.traileffect = EFFECT_TR_CRYLINKPLASMA.m_id; break;
			CASE(CRYLINK_BOUNCING)   self.traileffect = EFFECT_TR_CRYLINKPLASMA.m_id; break;
			CASE(ELECTRO_BEAM)       self.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;
			CASE(GRENADE)            self.traileffect = EFFECT_TR_GRENADE.m_id; break;
			CASE(GRENADE_BOUNCING)   self.traileffect = EFFECT_TR_GRENADE.m_id; break;
			CASE(MINE)               self.traileffect = EFFECT_TR_GRENADE.m_id; break;
			CASE(BLASTER)            self.traileffect = EFFECT_Null.m_id; break;
			CASE(HLAC)               self.traileffect = EFFECT_Null.m_id; break;
			CASE(PORTO_RED)          self.traileffect = EFFECT_TR_WIZSPIKE.m_id; self.scale = 4; break;
			CASE(PORTO_BLUE)         self.traileffect = EFFECT_TR_WIZSPIKE.m_id; self.scale = 4; break;
			CASE(HOOKBOMB)           self.traileffect = EFFECT_TR_KNIGHTSPIKE.m_id; break;
			CASE(HAGAR)              self.traileffect = EFFECT_HAGAR_ROCKET.m_id; self.scale = 0.75; break;
			CASE(HAGAR_BOUNCING)     self.traileffect = EFFECT_HAGAR_ROCKET.m_id; self.scale = 0.75; break;
			CASE(NAPALM_FOUNTAIN)    // fallthrough // sself.modelindex = 0; self.traileffect = _particleeffectnum("torch_small"); break;
			CASE(FIREBALL)           self.modelindex = 0; self.traileffect = EFFECT_FIREBALL.m_id; break; // particle effect is good enough
			CASE(FIREMINE)           self.modelindex = 0; self.traileffect = EFFECT_FIREMINE.m_id; break; // particle effect is good enough
			CASE(TAG)                self.traileffect = EFFECT_TR_ROCKET.m_id; break;
			CASE(FLAC)               self.scale = 0.4; self.traileffect = EFFECT_FLAC_TRAIL.m_id; break;
			CASE(SEEKER)             self.traileffect = EFFECT_SEEKER_TRAIL.m_id; break;

			CASE(MAGE_SPIKE)         self.traileffect = EFFECT_TR_VORESPIKE.m_id; break;
			CASE(SHAMBLER_LIGHTNING) self.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;

			CASE(RAPTORBOMB)         self.gravity = 1; self.avelocity = '0 0 180'; self.traileffect = EFFECT_Null.m_id; break;
			CASE(RAPTORBOMBLET)      self.gravity = 1; self.avelocity = '0 0 180'; self.traileffect = EFFECT_Null.m_id; break;
			CASE(RAPTORCANNON)       self.traileffect = EFFECT_TR_CRYLINKPLASMA.m_id; break;

			CASE(SPIDERROCKET)       self.traileffect = EFFECT_SPIDERBOT_ROCKET_TRAIL.m_id; break;
			CASE(WAKIROCKET)         self.traileffect = EFFECT_RACER_ROCKET_TRAIL.m_id; break;
			CASE(WAKICANNON)         self.traileffect = EFFECT_Null.m_id; break;

			CASE(BUMBLE_GUN)         self.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;
			CASE(BUMBLE_BEAM)        self.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;

			CASE(RPC)                self.traileffect = EFFECT_TR_ROCKET.m_id; break;

			CASE(ROCKETMINSTA_LASER) self.traileffect = EFFECT_ROCKETMINSTA_LASER(self.team).m_id; break;
#undef CASE
			default:
				if(MUTATOR_CALLHOOK(Ent_Projectile, self))
					break;

				if (Nade_FromProjectile(self.cnt) != NADE_TYPE_Null)
				{
					setmodel(self, MDL_PROJECTILE_NADE);
					entity trail = Nade_TrailEffect(self.cnt, self.team);
					if (trail.eent_eff_name) self.traileffect = trail.m_id;
					break;
				}
				error("Received invalid CSQC projectile, can't work with this!");
				break;
		}

		self.mins = '0 0 0';
		self.maxs = '0 0 0';
		self.colormod = '0 0 0';
		self.move_touch = SUB_Stop;
		self.move_movetype = MOVETYPE_TOSS;
		self.alphamod = 1;

		switch(self.cnt)
		{
			case PROJECTILE_ELECTRO:
				// only new engines support sound moving with object
				loopsound(self, CH_SHOTS_SINGLE, SND(ELECTRO_FLY), VOL_BASE, ATTEN_NORM);
				self.mins = '0 0 -4';
				self.maxs = '0 0 -4';
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				self.move_bounce_factor = g_balance_electro_secondary_bouncefactor;
				self.move_bounce_stopspeed = g_balance_electro_secondary_bouncestop;
				break;
			case PROJECTILE_RPC:
			case PROJECTILE_ROCKET:
				loopsound(self, CH_SHOTS_SINGLE, SND(ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				self.mins = '-3 -3 -3';
				self.maxs = '3 3 3';
				break;
			case PROJECTILE_GRENADE:
				self.mins = '-3 -3 -3';
				self.maxs = '3 3 3';
				break;
			case PROJECTILE_GRENADE_BOUNCING:
				self.mins = '-3 -3 -3';
				self.maxs = '3 3 3';
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				self.move_bounce_factor = g_balance_mortar_bouncefactor;
				self.move_bounce_stopspeed = g_balance_mortar_bouncestop;
				break;
			case PROJECTILE_SHAMBLER_LIGHTNING:
				self.mins = '-8 -8 -8';
				self.maxs = '8 8 8';
				self.scale = 2.5;
				self.avelocity = randomvec() * 720;
				break;
			case PROJECTILE_MINE:
				self.mins = '-4 -4 -4';
				self.maxs = '4 4 4';
				break;
			case PROJECTILE_PORTO_RED:
				self.colormod = '2 1 1';
				self.alphamod = 0.5;
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				break;
			case PROJECTILE_PORTO_BLUE:
				self.colormod = '1 1 2';
				self.alphamod = 0.5;
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				break;
			case PROJECTILE_HAGAR_BOUNCING:
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				break;
			case PROJECTILE_CRYLINK_BOUNCING:
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				break;
			case PROJECTILE_NAPALM_FOUNTAIN:
			case PROJECTILE_FIREBALL:
				loopsound(self, CH_SHOTS_SINGLE, SND(FIREBALL_FLY2), VOL_BASE, ATTEN_NORM);
				self.mins = '-16 -16 -16';
				self.maxs = '16 16 16';
				break;
			case PROJECTILE_FIREMINE:
				loopsound(self, CH_SHOTS_SINGLE, SND(FIREBALL_FLY), VOL_BASE, ATTEN_NORM);
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				self.mins = '-4 -4 -4';
				self.maxs = '4 4 4';
				break;
			case PROJECTILE_TAG:
				self.mins = '-2 -2 -2';
				self.maxs = '2 2 2';
				break;
			case PROJECTILE_FLAC:
				self.mins = '-2 -2 -2';
				self.maxs = '2 2 2';
				break;
			case PROJECTILE_SEEKER:
				loopsound(self, CH_SHOTS_SINGLE, SND(TAG_ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				self.mins = '-4 -4 -4';
				self.maxs = '4 4 4';
				break;
            case PROJECTILE_RAPTORBOMB:
				self.mins = '-3 -3 -3';
				self.maxs = '3 3 3';
				break;
            case PROJECTILE_RAPTORBOMBLET:
				break;
            case PROJECTILE_RAPTORCANNON:
				break;
            case PROJECTILE_SPIDERROCKET:
                loopsound(self, CH_SHOTS_SINGLE, SND(TAG_ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				break;
            case PROJECTILE_WAKIROCKET:
                loopsound(self, CH_SHOTS_SINGLE, SND(TAG_ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				break;
            /*
            case PROJECTILE_WAKICANNON:
				break;
			case PROJECTILE_BUMBLE_GUN:
				// only new engines support sound moving with object
				loopsound(self, CH_SHOTS_SINGLE, SND(ELECTRO_FLY), VOL_BASE, ATTEN_NORM);
				self.mins = '0 0 -4';
				self.maxs = '0 0 -4';
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = func_null;
				self.move_bounce_factor = g_balance_electro_secondary_bouncefactor;
				self.move_bounce_stopspeed = g_balance_electro_secondary_bouncestop;
				break;
			*/
			default:
				break;
		}

		if(Nade_FromProjectile(self.cnt) != NADE_TYPE_Null)
		{
			entity nade_type = Nade_FromProjectile(self.cnt);
			self.mins = '-16 -16 -16';
			self.maxs = '16 16 16';
			self.colormod = nade_type.m_color;
			self.move_movetype = MOVETYPE_BOUNCE;
			self.move_touch = func_null;
			self.scale = 1.5;
			self.avelocity = randomvec() * 720;

			if(nade_type == NADE_TYPE_TRANSLOCATE || nade_type == NADE_TYPE_SPAWN)
				self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
			else
				self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
		}

		MUTATOR_CALLHOOK(EditProjectile, self);

		setsize(self, self.mins, self.maxs);
	}

	if(self.gravity)
	{
		if(self.move_movetype == MOVETYPE_FLY)
			self.move_movetype = MOVETYPE_TOSS;
		if(self.move_movetype == MOVETYPE_BOUNCEMISSILE)
			self.move_movetype = MOVETYPE_BOUNCE;
	}
	else
	{
		if(self.move_movetype == MOVETYPE_TOSS)
			self.move_movetype = MOVETYPE_FLY;
		if(self.move_movetype == MOVETYPE_BOUNCE)
			self.move_movetype = MOVETYPE_BOUNCEMISSILE;
	}

	if(!(self.count & 0x80))
		InterpolateOrigin_Note();

	self.classname = "csqcprojectile";
	self.draw = Projectile_Draw;
	self.entremove = Ent_RemoveProjectile;
}

void Projectile_Precache()
{
	MUTATOR_CALLHOOK(PrecacheProjectiles);
}
