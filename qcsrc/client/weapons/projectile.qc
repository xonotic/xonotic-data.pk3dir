#include "projectile.qh"

#include "../autocvars.qh"
#include "../defs.qh"
#include "../main.qh"
#include "../mutators/events.qh"

#include <common/constants.qh>
#include <common/physics/movetypes/movetypes.qh>

#include <lib/csqcmodel/interpolate.qh>

#include <lib/warpzone/anglestransform.qh>

.float alpha;
.float scale;
.vector colormod;

void SUB_Stop(entity this)
{
	this.move_velocity = this.move_avelocity = '0 0 0';
	this.move_movetype = MOVETYPE_NONE;
}

void SUB_Stop_self() { SUB_Stop(self); }

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
	if (this.cnt == PROJECTILE_FIREMINE)
		if (from == to)
			from.z += 1;

	if (this.traileffect)
	{
		particles_alphamin = particles_alphamax = particles_fade = sqrt(this.alpha);
		boxparticles(particleeffectnum(Effects_from(this.traileffect)), this, from, to, this.velocity, this.velocity, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE | PARTICLES_DRAWASTRAIL);
	}
}

bool Projectile_isnade(int proj); // TODO: remove

void Projectile_Draw(entity this)
{
	vector rot;
	vector trailorigin;
	int f;
	bool drawn;
	float t;
	float a;

	f = this.move_flags;

	if (this.count & 0x80)
	{
		// this.move_flags &= ~FL_ONGROUND;
		if (this.move_movetype == MOVETYPE_NONE || this.move_movetype == MOVETYPE_FLY)
			Movetype_Physics_NoMatchServer(this);
		// the trivial movetypes do not have to match the
		// server's ticrate as they are ticrate independent
		// NOTE: this assumption is only true if MOVETYPE_FLY
		// projectiles detonate on impact. If they continue
		// moving, we might still be ticrate dependent.
		else
			Movetype_Physics_MatchServer(this, autocvar_cl_projectiles_sloppy);
		if (!(this.move_flags & FL_ONGROUND))
			if (this.velocity != '0 0 0')
				this.move_angles = this.angles = vectoangles(this.velocity);
	}
	else
	{
		InterpolateOrigin_Do(this);
	}

	if (this.count & 0x80)
	{
		drawn = (time >= this.spawntime - 0.02);
		t = max(time, this.spawntime);
	}
	else
	{
		drawn = (this.iflags & IFLAG_VALID);
		t = time;
	}

	if (!(f & FL_ONGROUND))
	{
		rot = '0 0 0';
		switch (this.cnt)
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
				rot = '1000 0 0';  // forward
				break;
			default:
				break;
		}

		if (Projectile_isnade(this.cnt))
			rot = this.avelocity;

		this.angles = AnglesTransform_ToAngles(AnglesTransform_Multiply(AnglesTransform_FromAngles(this.angles), rot * (t - this.spawntime)));
	}

	vector ang;
	ang = this.angles;
	ang.x = -ang.x;
	makevectors(ang);

	a = 1 - (time - this.fade_time) * this.fade_rate;
	this.alpha = bound(0, this.alphamod * a, 1);
	if (this.alpha <= 0)
		drawn = 0;
	this.renderflags = 0;

	trailorigin = this.origin;
	switch (this.cnt)
	{
		case PROJECTILE_GRENADE:
		case PROJECTILE_GRENADE_BOUNCING:
			trailorigin += v_right * 1 + v_forward * -10;
			break;
		default:
			break;
	}

	if (Projectile_isnade(this.cnt))
		trailorigin += v_up * 4;

	if (drawn)
		Projectile_DrawTrail(this, trailorigin);
	else
		Projectile_ResetTrail(this, trailorigin);

	this.drawmask = 0;

	if (!drawn)
		return;

	switch (this.cnt)
	{
		// Possibly add dlights here.
		default:
			break;
	}

	this.drawmask = MASK_NORMAL;
}

void loopsound(entity e, int ch, string samp, float vol, float attn)
{
	if (e.silent)
		return;

	_sound(e, ch, samp, vol, attn);
	e.snd_looping = ch;
}

void Ent_RemoveProjectile(entity this)
{
	if (this.count & 0x80)
	{
		tracebox(this.origin, this.mins, this.maxs, this.origin + this.velocity * 0.05, MOVE_NORMAL, this);
		Projectile_DrawTrail(this, trace_endpos);
	}
}

NET_HANDLE(ENT_CLIENT_PROJECTILE, bool isnew)
{
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

	int f = ReadByte();
	this.count = (f & 0x80);
	this.flags |= FL_PROJECTILE;
	this.iflags = (this.iflags & IFLAG_INTERNALMASK) | IFLAG_AUTOANGLES | IFLAG_ANGLES | IFLAG_ORIGIN;
	this.solid = SOLID_TRIGGER;
	// this.effects = EF_NOMODELFLAGS;

	// this should make collisions with bmodels more exact, but it leads to
	// projectiles no longer being able to lie on a bmodel
	this.move_nomonsters = MOVE_WORLDONLY;
	if (f & 0x40)
		this.move_flags |= FL_ONGROUND;
	else
		this.move_flags &= ~FL_ONGROUND;

	if (!this.move_time)
	{
		// for some unknown reason, we don't need to care for
		// sv_gameplayfix_delayprojectiles here.
		this.move_time = time;
		this.spawntime = time;
	}
	else
	{
		this.move_time = max(this.move_time, time);
	}

	if (!(this.count & 0x80))
		InterpolateOrigin_Undo(this);

	if (f & 1)
	{
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
		setorigin(this, this.origin);
		if (this.count & 0x80)
		{
			this.velocity_x = ReadCoord();
			this.velocity_y = ReadCoord();
			this.velocity_z = ReadCoord();
			if (f & 0x10)
				this.gravity = ReadCoord();
			else
				this.gravity = 0;  // none
			this.move_origin = this.origin;
			this.move_velocity = this.velocity;
		}

		if (time == this.spawntime || (this.count & 0x80) || (f & 0x08))
		{
			this.trail_oldorigin = this.origin;
			if (!(this.count & 0x80))
				WITH(entity, self, this, InterpolateOrigin_Reset());
		}

		if (f & 0x20)
		{
			this.fade_time = time + ReadByte() * ticrate;
			this.fade_rate = 1 / (ReadByte() * ticrate);
		}
		else
		{
			this.fade_time = 0;
			this.fade_rate = 0;
		}

		this.team = ReadByte() - 1;
	}

	if (f & 2)
	{
		this.cnt = ReadByte();

		this.silent = (this.cnt & 0x80);
		this.cnt = (this.cnt & 0x7F);

		this.scale = 1;
		this.traileffect = 0;
		switch (this.cnt)
		{
#define HANDLE(id) case PROJECTILE_##id: setmodel(this, MDL_PROJECTILE_##id);
			HANDLE(ELECTRO)            this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;
			HANDLE(ROCKET)             this.traileffect = EFFECT_TR_ROCKET.m_id; this.scale = 2; break;
			HANDLE(CRYLINK)            this.traileffect = EFFECT_TR_CRYLINKPLASMA.m_id; break;
			HANDLE(CRYLINK_BOUNCING)   this.traileffect = EFFECT_TR_CRYLINKPLASMA.m_id; break;
			HANDLE(ELECTRO_BEAM)       this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;
			HANDLE(GRENADE)            this.traileffect = EFFECT_TR_GRENADE.m_id; break;
			HANDLE(GRENADE_BOUNCING)   this.traileffect = EFFECT_TR_GRENADE.m_id; break;
			HANDLE(MINE)               this.traileffect = EFFECT_TR_GRENADE.m_id; break;
			HANDLE(BLASTER)            this.traileffect = EFFECT_Null.m_id; break;
			HANDLE(HLAC)               this.traileffect = EFFECT_Null.m_id; break;
			HANDLE(PORTO_RED)          this.traileffect = EFFECT_TR_WIZSPIKE.m_id; this.scale = 4; break;
			HANDLE(PORTO_BLUE)         this.traileffect = EFFECT_TR_WIZSPIKE.m_id; this.scale = 4; break;
			HANDLE(HOOKBOMB)           this.traileffect = EFFECT_TR_KNIGHTSPIKE.m_id; break;
			HANDLE(HAGAR)              this.traileffect = EFFECT_HAGAR_ROCKET.m_id; this.scale = 0.75; break;
			HANDLE(HAGAR_BOUNCING)     this.traileffect = EFFECT_HAGAR_ROCKET.m_id; this.scale = 0.75; break;
			HANDLE(FIREBALL)           this.modelindex = 0; this.traileffect = EFFECT_FIREBALL.m_id; break; // particle effect is good enough
			HANDLE(FIREMINE)           this.modelindex = 0; this.traileffect = EFFECT_FIREMINE.m_id; break; // particle effect is good enough
			HANDLE(TAG)                this.traileffect = EFFECT_TR_ROCKET.m_id; break;
			HANDLE(FLAC)               this.scale = 0.4; this.traileffect = EFFECT_FLAC_TRAIL.m_id; break;
			HANDLE(SEEKER)             this.traileffect = EFFECT_SEEKER_TRAIL.m_id; break;

			HANDLE(MAGE_SPIKE)         this.traileffect = EFFECT_TR_VORESPIKE.m_id; break;
			HANDLE(SHAMBLER_LIGHTNING) this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;

			HANDLE(RAPTORBOMB)         this.gravity = 1; this.avelocity = '0 0 180'; this.traileffect = EFFECT_Null.m_id; break;
			HANDLE(RAPTORBOMBLET)      this.gravity = 1; this.avelocity = '0 0 180'; this.traileffect = EFFECT_Null.m_id; break;
			HANDLE(RAPTORCANNON)       this.traileffect = EFFECT_TR_CRYLINKPLASMA.m_id; break;

			HANDLE(SPIDERROCKET)       this.traileffect = EFFECT_SPIDERBOT_ROCKET_TRAIL.m_id; break;
			HANDLE(WAKIROCKET)         this.traileffect = EFFECT_RACER_ROCKET_TRAIL.m_id; break;
			HANDLE(WAKICANNON)         this.traileffect = EFFECT_Null.m_id; break;

			HANDLE(BUMBLE_GUN)         this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;
			HANDLE(BUMBLE_BEAM)        this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;

			HANDLE(RPC)                this.traileffect = EFFECT_TR_ROCKET.m_id; break;

			HANDLE(ROCKETMINSTA_LASER) this.traileffect = EFFECT_ROCKETMINSTA_LASER(this.team).m_id; break;
#undef HANDLE
			default:
				if (MUTATOR_CALLHOOK(Ent_Projectile, this))
					break;

				error("Received invalid CSQC projectile, can't work with this!");
				break;
		}

		this.mins = '0 0 0';
		this.maxs = '0 0 0';
		this.colormod = '0 0 0';
		this.move_touch = SUB_Stop_self;
		this.move_movetype = MOVETYPE_TOSS;
		this.alphamod = 1;

		switch (this.cnt)
		{
			case PROJECTILE_ELECTRO:
				// only new engines support sound moving with object
				loopsound(this, CH_SHOTS_SINGLE, SND(ELECTRO_FLY), VOL_BASE, ATTEN_NORM);
				this.mins = '0 0 -4';
				this.maxs = '0 0 -4';
				this.move_movetype = MOVETYPE_BOUNCE;
				this.move_touch = func_null;
				this.move_bounce_factor = WEP_CVAR_SEC(electro, bouncefactor);
				this.move_bounce_stopspeed = WEP_CVAR_SEC(electro, bouncestop);
				break;
			case PROJECTILE_RPC:
			case PROJECTILE_ROCKET:
				loopsound(this, CH_SHOTS_SINGLE, SND(ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				this.mins = '-3 -3 -3';
				this.maxs = '3 3 3';
				break;
			case PROJECTILE_GRENADE:
				this.mins = '-3 -3 -3';
				this.maxs = '3 3 3';
				break;
			case PROJECTILE_GRENADE_BOUNCING:
				this.mins = '-3 -3 -3';
				this.maxs = '3 3 3';
				this.move_movetype = MOVETYPE_BOUNCE;
				this.move_touch = func_null;
				this.move_bounce_factor = WEP_CVAR(mortar, bouncefactor);
				this.move_bounce_stopspeed = WEP_CVAR(mortar, bouncestop);
				break;
			case PROJECTILE_SHAMBLER_LIGHTNING:
				this.mins = '-8 -8 -8';
				this.maxs = '8 8 8';
				this.scale = 2.5;
				this.avelocity = randomvec() * 720;
				break;
			case PROJECTILE_MINE:
				this.mins = '-4 -4 -4';
				this.maxs = '4 4 4';
				break;
			case PROJECTILE_PORTO_RED:
				this.colormod = '2 1 1';
				this.alphamod = 0.5;
				this.move_movetype = MOVETYPE_BOUNCE;
				this.move_touch = func_null;
				break;
			case PROJECTILE_PORTO_BLUE:
				this.colormod = '1 1 2';
				this.alphamod = 0.5;
				this.move_movetype = MOVETYPE_BOUNCE;
				this.move_touch = func_null;
				break;
			case PROJECTILE_HAGAR_BOUNCING:
				this.move_movetype = MOVETYPE_BOUNCE;
				this.move_touch = func_null;
				break;
			case PROJECTILE_CRYLINK_BOUNCING:
				this.move_movetype = MOVETYPE_BOUNCE;
				this.move_touch = func_null;
				break;
			case PROJECTILE_FIREBALL:
				loopsound(this, CH_SHOTS_SINGLE, SND(FIREBALL_FLY2), VOL_BASE, ATTEN_NORM);
				this.mins = '-16 -16 -16';
				this.maxs = '16 16 16';
				break;
			case PROJECTILE_FIREMINE:
				loopsound(this, CH_SHOTS_SINGLE, SND(FIREBALL_FLY), VOL_BASE, ATTEN_NORM);
				this.move_movetype = MOVETYPE_BOUNCE;
				this.move_touch = func_null;
				this.mins = '-4 -4 -4';
				this.maxs = '4 4 4';
				break;
			case PROJECTILE_TAG:
				this.mins = '-2 -2 -2';
				this.maxs = '2 2 2';
				break;
			case PROJECTILE_FLAC:
				this.mins = '-2 -2 -2';
				this.maxs = '2 2 2';
				break;
			case PROJECTILE_SEEKER:
				loopsound(this, CH_SHOTS_SINGLE, SND(TAG_ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				this.mins = '-4 -4 -4';
				this.maxs = '4 4 4';
				break;
			case PROJECTILE_RAPTORBOMB:
				this.mins = '-3 -3 -3';
				this.maxs = '3 3 3';
				break;
			case PROJECTILE_RAPTORBOMBLET:
				break;
			case PROJECTILE_RAPTORCANNON:
				break;
			case PROJECTILE_SPIDERROCKET:
				loopsound(this, CH_SHOTS_SINGLE, SND(TAG_ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				break;
			case PROJECTILE_WAKIROCKET:
				loopsound(this, CH_SHOTS_SINGLE, SND(TAG_ROCKET_FLY), VOL_BASE, ATTEN_NORM);
				break;
			/*
			case PROJECTILE_WAKICANNON:
			    break;
			case PROJECTILE_BUMBLE_GUN:
			    // only new engines support sound moving with object
			    loopsound(this, CH_SHOTS_SINGLE, SND(ELECTRO_FLY), VOL_BASE, ATTEN_NORM);
			    this.mins = '0 0 -4';
			    this.maxs = '0 0 -4';
			    this.move_movetype = MOVETYPE_BOUNCE;
			    this.move_touch = func_null;
			    this.move_bounce_factor = WEP_CVAR_SEC(electro, bouncefactor);
			    this.move_bounce_stopspeed = WEP_CVAR_SEC(electro, bouncestop);
			    break;
			*/
			default:
				break;
		}

		MUTATOR_CALLHOOK(EditProjectile, this);

		setsize(this, this.mins, this.maxs);
	}

	return = true;

	if (this.gravity)
	{
		if (this.move_movetype == MOVETYPE_FLY)
			this.move_movetype = MOVETYPE_TOSS;
		if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
			this.move_movetype = MOVETYPE_BOUNCE;
	}
	else
	{
		if (this.move_movetype == MOVETYPE_TOSS)
			this.move_movetype = MOVETYPE_FLY;
		if (this.move_movetype == MOVETYPE_BOUNCE)
			this.move_movetype = MOVETYPE_BOUNCEMISSILE;
	}

	if (!(this.count & 0x80))
		InterpolateOrigin_Note(this);

	this.classname = "csqcprojectile";
	this.draw = Projectile_Draw;
	this.entremove = Ent_RemoveProjectile;
}

PRECACHE(Projectiles)
{
	MUTATOR_CALLHOOK(PrecacheProjectiles);
}
