#include "projectile.qh"

#include <client/mutators/_mod.qh>
#include <common/constants.qh>
#include <common/effects/all.qh>
#include <common/effects/effect.qh>
#include <common/mutators/mutator/nades/_mod.qh>
#include <common/net_linked.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <lib/csqcmodel/interpolate.qh>
#include <lib/warpzone/anglestransform.qh>

.float alpha;
.float scale;
.vector colormod;
.vector glowmod;

void SUB_Stop(entity this, entity toucher)
{
	this.velocity = this.avelocity = '0 0 0';
	set_movetype(this, MOVETYPE_NONE);
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
	if (this.cnt == PROJECTILE_FIREMINE)
		if (from == to)
			from.z += 1;

	// Note: alpha value 0 actually means 1 on entities.
	// This can be relevant when coming from CSQCModel_Effects_Apply.
	float a = (this.alpha == 0) ? 1 : this.alpha;

	// TODO: Do we actually need alpha support? Consider removing this
	// support entirely and instead making necessary adjustments in
	// effectinfo.
	//
	// Right now (2024-12-30), only Crylink can generate alpha via
	// fade_rate/fade_time, and only PROJECTILE_PORTO_* set a fixed alpha
	// (and reuse the Arc's TE_WIZSPIKE).
	if (this.traileffect && a > 0)
	{
		float f = PARTICLES_DRAWASTRAIL;
		if (a < 1)
		{
			// Do some of the fading using particle count, and some of it using alpha.
			// Fading by particle count is less smooth but also cheaper to render.
			// A higher power here performs more of the fading using particle count.
			const float fade_power = 0.5;
			particles_fade = pow(a, fade_power);
			particles_alphamin = particles_alphamax = a / particles_fade;  // == pow(a, 1 - fade_power)
			f |= PARTICLES_USEALPHA | PARTICLES_USEFADE;
			//LOG_INFOF("particle fade: %f alpha: %f", particles_fade, particles_alphamin);
		}
		//else
		//	LOG_INFOF("particle fade skipped");

		if (this.colormod != '0 0 0')
		{
			particles_colormin = particles_colormax = this.colormod;
			f |= PARTICLES_USECOLOR;
		}
		entity eff = REGISTRY_GET(Effects, this.traileffect);
		boxparticles(particleeffectnum(eff), this, from, to, this.velocity, this.velocity, 1, f);
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

	f = this.flags;

	if (this.count & 0x80)
	{
		// UNSET_ONGROUND(this);
		if (this.move_movetype == MOVETYPE_NONE || this.move_movetype == MOVETYPE_FLY)
			Movetype_Physics_NoMatchServer(this);
		// the trivial movetypes do not have to match the
		// server's ticrate as they are ticrate independent
		// NOTE: this assumption is only true if MOVETYPE_FLY
		// projectiles detonate on impact. If they continue
		// moving, we might still be ticrate dependent.
		else
			Movetype_Physics_MatchServer(this, autocvar_cl_projectiles_sloppy);
		if (!IS_ONGROUND(this))
			if (this.velocity != '0 0 0')
				this.angles = vectoangles(this.velocity);
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
	bool is_nade = Projectile_isnade(this.cnt);

	if (!(f & FL_ONGROUND))
	{
		rot = '0 0 0';
		if (is_nade) rot = this.avelocity;
		else switch (this.cnt)
		{
			case PROJECTILE_GRENADE_BOUNCING:
				rot = '0 -1000 0'; // sideways
				break;
			case PROJECTILE_HOOKBOMB:
				rot = '1000 0 0';  // forward
				break;
			case PROJECTILE_ROCKET:
				rot = '0 0 720'; // spinning
				break;
		}

		if (rot)
		{
			if (!rot.x && !rot.y)
			{
				// cheaper z-only rotation formula
				this.angles.z = (rot.z * (t - this.spawntime)) % 360;
				if (this.angles.z < 0)
					this.angles.z += 360;
			}
			else
				this.angles = AnglesTransform_ToAngles(AnglesTransform_Multiply(AnglesTransform_FromAngles(this.angles), rot * (t - this.spawntime)));
		}
	}

	// negation used to ensure a zero fade_(time/rate) does not affect opacity
	a = 1 - (time - this.fade_time) * this.fade_rate;
	this.alpha = bound(0, this.alphamod * a, 1);
	if (this.alpha <= 0)
		drawn = 0;
	this.renderflags = 0;

	vector ang = this.angles;
	ang.x = -ang.x;
	trailorigin = this.origin;
	if (is_nade)
	{
		makevectors(ang);
		trailorigin += v_up * 4;
	}
	else switch (this.cnt)
	{
		case PROJECTILE_GRENADE:
		case PROJECTILE_GRENADE_BOUNCING:
			makevectors(ang);
			trailorigin += v_right * 1 + v_forward * -10;
			break;
	}

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

void loopsound(entity e, int ch, Sound samp, float vol, float attn)
{
	TC(int, ch);
	if (e.silent)
		return;

	sound(e, ch, samp, vol, attn);
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
		SET_ONGROUND(this);
	else
		UNSET_ONGROUND(this);

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
		this.origin = ReadVector();
		setorigin(this, this.origin);
		if (this.count & 0x80)
		{
			this.velocity = ReadVector();
			if (f & 0x10)
				this.gravity = ReadCoord();
			else
				this.gravity = 0;  // none
		}

		if (time == this.spawntime || (this.count & 0x80) || (f & 0x08))
		{
			this.trail_oldorigin = this.origin;
			if (!(this.count & 0x80))
				InterpolateOrigin_Reset(this);
		}

		if (f & 0x20)
		{
			float fadetime = ReadByte();
			float faderate = ReadByte();

			// workaround for division by 0
			// TODO: apply fade settings WITHOUT ticrate here and multiply during use cases
			if(ticrate <= 0)
			{
				this.fade_time = 0;
				this.fade_rate = 0;
			}
			else
			{
				this.fade_time = time + fadetime * ticrate;
				this.fade_rate = 1 / (faderate * ticrate);
			}
		}
		else
		{
			this.fade_time = 0;
			this.fade_rate = 0;
		}

		int proj_team = ReadByte();

		if(teamplay)
		{
			this.team = proj_team - 1;
			if(proj_team)
				this.colormap = (this.team) * 0x11; // note: team - 1 on server (client uses different numbers)
			else
				this.colormap = 0x00;
			this.colormap |= BIT(10); // RENDER_COLORMAPPED
		}
		else
		{
			this.team = 0;
			this.colormap = proj_team;
		}
		// TODO: projectiles use glowmaps for their color, not teams
		#if 0
		if(this.colormap > 0)
			this.glowmod = colormapPaletteColor(this.colormap & 0x0F, true);
		else
			this.glowmod = '1 1 1';
		#endif
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
			HANDLE(ARC_BOLT)           this.traileffect = EFFECT_TR_WIZSPIKE.m_id; break;
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
			HANDLE(GOLEM_LIGHTNING)    this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;

			HANDLE(RAPTORBOMB)         this.gravity = 1; this.avelocity = '0 0 180'; this.traileffect = EFFECT_Null.m_id; break;
			HANDLE(RAPTORBOMBLET)      this.gravity = 1; this.avelocity = '0 0 180'; this.traileffect = EFFECT_Null.m_id; break;
			HANDLE(RAPTORCANNON)       this.traileffect = EFFECT_TR_CRYLINKPLASMA.m_id; break;

			HANDLE(SPIDERROCKET)       this.traileffect = EFFECT_SPIDERBOT_ROCKET_TRAIL.m_id; break;
			HANDLE(WAKIROCKET)         this.traileffect = EFFECT_RACER_ROCKET_TRAIL.m_id; break;
			HANDLE(WAKICANNON)         this.traileffect = EFFECT_Null.m_id; break;

			HANDLE(BUMBLE_GUN)         this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;
			HANDLE(BUMBLE_BEAM)        this.traileffect = EFFECT_TR_NEXUIZPLASMA.m_id; break;

			HANDLE(RPC)                this.traileffect = EFFECT_TR_ROCKET.m_id; break;

			HANDLE(ROCKETMINSTA_LASER) this.traileffect = EFFECT_ROCKETMINSTA_LASER.m_id; break;
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
		settouch(this, SUB_Stop);
		set_movetype(this, MOVETYPE_TOSS);
		this.alphamod = 1;

		switch (this.cnt)
		{
			case PROJECTILE_ELECTRO:
				// only new engines support sound moving with object
				loopsound(this, CH_SHOTS_SINGLE, SND_ELECTRO_FLY, VOL_BASE, ATTEN_NORM);
				this.mins = '-4 -4 -4';
				this.maxs = '4 4 4';
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
				this.bouncefactor = WEP_CVAR_SEC(WEP_ELECTRO, bouncefactor);
				this.bouncestop = WEP_CVAR_SEC(WEP_ELECTRO, bouncestop);
				break;
			case PROJECTILE_RPC:
			case PROJECTILE_ROCKET:
				loopsound(this, CH_SHOTS_SINGLE, SND_DEVASTATOR_FLY, VOL_BASE, ATTEN_NORM);
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
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
				this.bouncefactor = WEP_CVAR(WEP_MORTAR, bouncefactor);
				this.bouncestop = WEP_CVAR(WEP_MORTAR, bouncestop);
				break;
			case PROJECTILE_GOLEM_LIGHTNING:
				this.mins = '-8 -8 -8';
				this.maxs = '8 8 8';
				this.scale = 2.5;
				this.avelocity = randomvec() * 720;
				break;
			case PROJECTILE_MINE:
				this.mins = '-4 -4 -4';
				this.maxs = '4 4 4';
				this.glowmod = colormapPaletteColor(this.colormap & 0x0F, true);
				break;
			case PROJECTILE_PORTO_RED:
				this.colormod = '2 1 1';
				this.alphamod = 0.5;
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
				break;
			case PROJECTILE_PORTO_BLUE:
				this.colormod = '1 1 2';
				this.alphamod = 0.5;
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
				break;
			case PROJECTILE_HAGAR_BOUNCING:
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
				break;
			case PROJECTILE_CRYLINK_BOUNCING:
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
				break;
			case PROJECTILE_FIREBALL:
				loopsound(this, CH_SHOTS_SINGLE, SND_FIREBALL_FLY2, VOL_BASE, ATTEN_NORM);
				this.mins = '-16 -16 -16';
				this.maxs = '16 16 16';
				break;
			case PROJECTILE_FIREMINE:
				loopsound(this, CH_SHOTS_SINGLE, SND_FIREBALL_FLY, VOL_BASE, ATTEN_NORM);
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
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
				loopsound(this, CH_SHOTS_SINGLE, SND_SEEKER_ROCKET_FLY, VOL_BASE, ATTEN_NORM);
				this.mins = '-4 -4 -4';
				this.maxs = '4 4 4';
				break;
			case PROJECTILE_ARC_BOLT:
				set_movetype(this, MOVETYPE_BOUNCE);
				settouch(this, func_null);
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
				loopsound(this, CH_SHOTS_SINGLE, SND_VEH_SPIDERBOT_ROCKET_FLY, VOL_BASE, ATTEN_NORM);
				break;
			case PROJECTILE_WAKIROCKET:
				loopsound(this, CH_SHOTS_SINGLE, SND_VEH_RACER_ROCKET_FLY, VOL_BASE, ATTEN_NORM);
				break;
			case PROJECTILE_ROCKETMINSTA_LASER:
				if(this.colormap > 0)
					this.colormod = colormapPaletteColor(this.colormap & 0x0F, true);
				break;
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
			set_movetype(this, MOVETYPE_TOSS);
		if (this.move_movetype == MOVETYPE_BOUNCEMISSILE)
			set_movetype(this, MOVETYPE_BOUNCE);
	}
	else
	{
		if (this.move_movetype == MOVETYPE_TOSS)
			set_movetype(this, MOVETYPE_FLY);
		if (this.move_movetype == MOVETYPE_BOUNCE)
			set_movetype(this, MOVETYPE_BOUNCEMISSILE);
	}

	if (!(this.count & 0x80))
		InterpolateOrigin_Note(this);

	this.draw = Projectile_Draw;
	if (isnew) IL_PUSH(g_drawables, this);
	this.entremove = Ent_RemoveProjectile;
}

PRECACHE(Projectiles)
{
	MUTATOR_CALLHOOK(PrecacheProjectiles);
}
