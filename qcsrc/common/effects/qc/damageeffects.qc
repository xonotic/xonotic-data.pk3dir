#include "damageeffects.qh"

REGISTER_NET_LINKED(ENT_CLIENT_DAMAGEINFO)

#ifdef SVQC

bool Damage_DamageInfo_SendEntity(entity this, entity to, int sf)
{
	vector org = vec3(floor(this.origin.x), floor(this.origin.y), floor(this.origin.z));
	WriteHeader(MSG_ENTITY, ENT_CLIENT_DAMAGEINFO);
	WriteShort(MSG_ENTITY, this.projectiledeathtype);
	WriteVector(MSG_ENTITY, org);
	WriteByte(MSG_ENTITY, bound(1, this.dmg, 255));
	WriteByte(MSG_ENTITY, bound(0, this.dmg_radius, 255));
	WriteByte(MSG_ENTITY, bound(1, this.dmg_edge, 255));
	// we can't send the force vector compressed with compressShortVector as it's too inaccurate
	// it would break decals when hit angle on a surface is small
	// (the traceline performed by the client to spawn a decal wouldn't hit the surface at all)
	WriteShort(MSG_ENTITY, floor(this.velocity.x / 4));
	WriteShort(MSG_ENTITY, floor(this.velocity.y / 4));
	WriteShort(MSG_ENTITY, floor(this.velocity.z / 4));
	WriteByte(MSG_ENTITY, this.species);
	WriteByte(MSG_ENTITY, this.colormap);
	return true;
}

void Damage_DamageInfo(vector org, float coredamage, float edgedamage, float rad, vector force, int deathtype, float bloodtype, entity dmgowner)
{
	// TODO maybe call this from non-edgedamage too?
	// TODO maybe make the client do the particle effects for the weapons and the impact sounds using this info?

	if(!sound_allowed(MSG_BROADCAST, dmgowner))
		deathtype |= 0x8000;

	entity e = new_pure(damageinfo);
	// origin is just data to be sent
	//setorigin(e, org);
	e.origin = org;
	e.projectiledeathtype = deathtype;
	e.dmg = coredamage;
	e.dmg_edge = edgedamage;
	bool rad_negative = false;
	if(rad < 0)
	{
		// make it positive (unsigned) so it can be sent as byte
		rad_negative = true;
		rad = -rad;
	}
	e.dmg_radius = rad;
	e.dmg_force = vlen(force);
	e.velocity = force;

	e.species = bloodtype & BITS(4); // it only uses bits from 0 to 3, see SPECIES_* constants
	if(rad_negative)
		e.species |= BIT(7);

	e.colormap = (teamplay) ? dmgowner.team : dmgowner.clientcolors; // NOTE: doesn't work on non-clients

	Net_LinkEntity(e, false, 0.2, Damage_DamageInfo_SendEntity);
}

#endif

#ifdef CSQC

/** number of effects which currently are attached to a player */
.int total_damages;

.entity tag_entity;

.float cnt;
.int state;

.bool silent;

void DamageEffect_Think(entity this)
{
	// if particle distribution is enabled, slow ticrate by total number of damages
	if(autocvar_cl_damageeffect_distribute)
		this.nextthink = time + autocvar_cl_damageeffect_ticrate * this.owner.total_damages;
	else
		this.nextthink = time + autocvar_cl_damageeffect_ticrate;

	if(time >= this.cnt || !this.owner || !this.owner.modelindex || !this.owner.drawmask)
	{
		// time is up or the player got gibbed / disconnected
		this.owner.total_damages = max(0, this.owner.total_damages - 1);
		delete(this);
		return;
	}
	if(this.state && !this.owner.csqcmodel_isdead)
	{
		// if the player was dead but is now alive, it means they respawned
		// if so, clear their damage effects, or damages from their dead body will be copied back
		this.owner.total_damages = max(0, this.owner.total_damages - 1);
		delete(this);
		return;
	}
	this.state = this.owner.csqcmodel_isdead;
	if((this.owner.isplayermodel & ISPLAYER_LOCAL) && !autocvar_chase_active)
		return; // if we aren't using a third person camera, hide our own effects

	// now generate the particles
	vector org = gettaginfo(this, 0); // origin at attached location
	__pointparticles(this.team, org, '0 0 0', 1);
}

string species_prefix(int specnum)
{
	switch(specnum)
	{
		case SPECIES_HUMAN:       return "";
		case SPECIES_ALIEN:       return "alien_";
		case SPECIES_ROBOT_SHINY: return "robot_";
		case SPECIES_ROBOT_RUSTY: return "robot_"; // use the same effects, only different gibs
		case SPECIES_ROBOT_SOLID: return "robot_"; // use the same effects, only different gibs
		case SPECIES_ANIMAL:      return "animal_";
		case SPECIES_RESERVED:    return "reserved_";
		default:         return "";
	}
}

void DamageEffect(entity this, vector hitorg, float thedamage, int type, int specnum)
{
	// particle effects for players and objects damaged by weapons (eg: flames coming out of victims shot with rockets)

	int nearestbone = 0;
	float life;
	string effectname;
	entity e, wep;

	if(!autocvar_cl_damageeffect || autocvar_cl_gentle || autocvar_cl_gentle_damage)
		return;
	if(!this || !this.modelindex || !this.drawmask)
		return;

	// if this is a rigged mesh, the effect will show on the bone where damage was dealt
	// we do this by choosing the skeletal bone closest to the impact, and attaching our entity to it
	// if there's no skeleton, object origin will automatically be selected
	FOR_EACH_TAG(this)
	{
		if(!tagnum)
			continue; // skip empty bones
		// blacklist bones positioned outside the mesh, or the effect will be floating
		// TODO: Do we have to do it this way? Why do these bones exist at all?
		if(gettaginfo_name == "master" || gettaginfo_name == "knee_L" || gettaginfo_name == "knee_R" || gettaginfo_name == "leg_L" || gettaginfo_name == "leg_R")
			continue; // player model bone blacklist

		// now choose the bone closest to impact origin
		if(nearestbone == 0 || vlen2(hitorg - gettaginfo(this, tagnum)) <= vlen2(hitorg - gettaginfo(this, nearestbone)))
			nearestbone = tagnum;
	}
	gettaginfo(this, nearestbone); // set gettaginfo_name

	// return if we reached our damage effect limit or damages are disabled
	// TODO: When the limit is reached, it would be better if the oldest damage was removed instead of not adding a new one
	if(nearestbone)
	{
		if(this.total_damages >= autocvar_cl_damageeffect_bones)
			return; // allow multiple damages on skeletal models
	}
	else
	{
		if(autocvar_cl_damageeffect < 2 || this.total_damages)
			return; // allow a single damage on non-skeletal models
	}

	life = bound(autocvar_cl_damageeffect_lifetime_min, thedamage * autocvar_cl_damageeffect_lifetime, autocvar_cl_damageeffect_lifetime_max);

	wep = DEATH_WEAPONOF(type);
	effectname = strcat("damage_", wep.netname);
	if((wep.spawnflags & WEP_FLAG_BLEED))
	{
		// if this weapon induces bleeding, use the effect name with the proper species prefix (blood type)
		if((this.isplayermodel & ISPLAYER_MODEL))
		{
			string specstr = species_prefix(specnum);
			effectname = strcat(specstr, effectname);
		}
		else { return; } // objects don't bleed
	}

	e = new(damage);
	setmodel(e, MDL_Null); // necessary to attach and read origin
	setattachment(e, this, gettaginfo_name); // attach to the given bone
	e.owner = this;
	e.cnt = time + life;
	e.team = _particleeffectnum(effectname);
	setthink(e, DamageEffect_Think);
	e.nextthink = time;
	this.total_damages += 1;
}

NET_HANDLE(ENT_CLIENT_DAMAGEINFO, bool isNew)
{
	float thedamage, rad, edge, thisdmg;
	bool hitplayer = false;
	int species, forcemul;
	vector force, thisforce;

	w_deathtype = ReadShort();
	w_issilent = (w_deathtype & 0x8000);
	w_deathtype = (w_deathtype & 0x7FFF);

	w_org = ReadVector();

	thedamage = ReadByte();
	rad = ReadByte();
	edge = ReadByte();
	force.x = ReadShort() * 4 + 2;
	force.y = ReadShort() * 4 + 2;
	force.z = ReadShort() * 4 + 2;

	species = ReadByte();
	bool rad_negative = (species & BIT(7));
	species = (species & BITS(4));

	int dmg_colors = ReadByte();

	return = true;

	if (!isNew)
		return;

	forcemul = (rad_negative ? -1 : 1);
	// team color logic copied from projectiles
	int tcolor = dmg_colors;
	if(teamplay)
	{
		if(dmg_colors)
			tcolor = (dmg_colors - 1) * 0x11;
		else
			tcolor = 0x00;
		tcolor |= BIT(10); // RENDER_COLORMAPPED
	}

	// set globally so weapon impacts can use them
	particles_colormin = colormapPaletteColor(floor(tcolor / 16), false);
	particles_colormax = colormapPaletteColor(tcolor % 16, true);

	FOREACH_ENTITY_RADIUS(w_org, rad + MAX_DAMAGEEXTRARADIUS, !it.tag_entity && !is_pure(it), {
		vector nearest = NearestPointOnBox(it, w_org);
		if (rad)
		{
			thisdmg = ((vlen(nearest - w_org) - bound(MIN_DAMAGEEXTRARADIUS, it.damageextraradius, MAX_DAMAGEEXTRARADIUS)) / rad);
			if(thisdmg >= 1)
				continue;
			if(thisdmg < 0)
				thisdmg = 0;
			if(thedamage)
			{
				thisdmg = thedamage + (edge - thedamage) * thisdmg;
				thisforce = forcemul * vlen(force) * (thisdmg / thedamage) * normalize(it.origin - w_org);
			}
			else
			{
				thisdmg = 0;
				thisforce = forcemul * vlen(force) * normalize(it.origin - w_org);
			}
		}
		else
		{
			if(vdist((nearest - w_org), >, bound(MIN_DAMAGEEXTRARADIUS, it.damageextraradius, MAX_DAMAGEEXTRARADIUS)))
				continue;

			thisdmg = thedamage;
			thisforce = forcemul * force;
		}

		if(it.damageforcescale)
			if(vdist(thisforce, !=, 0))
			{
				it.velocity = it.velocity + damage_explosion_calcpush(it.damageforcescale * thisforce, it.velocity, damagepush_speedfactor);
				UNSET_ONGROUND(it);
			}

		if(w_issilent)
			it.silent = 1;

		if(it.event_damage)
			it.event_damage(it, thisdmg, w_deathtype, w_org, thisforce);

		DamageEffect(it, w_org, thisdmg, w_deathtype, species);

		if(it != csqcplayer && (it.isplayermodel & ISPLAYER_MODEL))
			hitplayer = true; // this impact damaged another player
	});

	if(DEATH_ISVEHICLE(w_deathtype))
	{
		vector force_dir = normalize(force);
		traceline(w_org - force_dir * 16, w_org + force_dir * 16, MOVE_NOMONSTERS, NULL);
		if(trace_plane_normal != '0 0 0')
			w_backoff = trace_plane_normal;
		else
			w_backoff = -1 * normalize(w_org - (w_org + force_dir * 16));

		setorigin(this, w_org + w_backoff * 2); // for sound() calls

		switch(DEATH_ENT(w_deathtype))
		{
			case DEATH_VH_CRUSH:
				break;

			// spiderbot
			case DEATH_VH_SPID_MINIGUN:
				sound(this, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_SPIDERBOT_MINIGUN_IMPACT, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_SPID_ROCKET:
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_SPIDERBOT_ROCKET_EXPLODE, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_SPID_DEATH:
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_EXPLOSION_BIG, this.origin, w_backoff * 1000, 1);
				break;

			case DEATH_VH_WAKI_GUN:
				sound(this, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_RACER_IMPACT, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_WAKI_ROCKET:
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_RACER_ROCKET_EXPLODE, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_WAKI_DEATH:
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_EXPLOSION_BIG, this.origin, w_backoff * 1000, 1);
				break;

			case DEATH_VH_RAPT_CANNON:
				sound(this, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_RAPTOR_CANNON_IMPACT, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_RAPT_FRAGMENT:
				float i;
				vector ang, vel;
				for(i = 1; i < 4; ++i)
				{
					vel = normalize(w_org - (w_org + force_dir * 16)) + randomvec() * 128;
					ang = vectoangles(vel);
					RaptorCBShellfragToss(w_org, vel, ang + '0 0 1' * (120 * i));
				}
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_RAPTOR_BOMB_SPREAD, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_RAPT_BOMB:
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_RAPTOR_BOMB_IMPACT, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_RAPT_DEATH:
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_EXPLOSION_BIG, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_BUMB_GUN:
				sound(this, CH_SHOTS, SND_VEH_BUMBLEBEE_IMPACT, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_BIGPLASMA_IMPACT, this.origin, w_backoff * 1000, 1);
				break;
		}
	}


	if(DEATH_ISTURRET(w_deathtype))
	{
		vector force_dir = normalize(force);
		traceline(w_org - force_dir * 16, w_org + force_dir * 16, MOVE_NOMONSTERS, NULL);
		if(trace_plane_normal != '0 0 0')
			w_backoff = trace_plane_normal;
		else
			w_backoff = -1 * normalize(w_org - (w_org + force_dir * 16));

		setorigin(this, w_org + w_backoff * 2); // for sound() calls

		switch(DEATH_ENT(w_deathtype))
		{
			case DEATH_TURRET_EWHEEL:
				sound(this, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_BLASTER_IMPACT, this.origin, w_backoff * 1000, 1);
				break;

			case DEATH_TURRET_FLAC:
				pointparticles(EFFECT_HAGAR_EXPLODE, w_org, '0 0 0', 1);
				sound(this, CH_SHOTS, SND_FLACEXP_RANDOM(), VOL_BASE, ATTEN_NORM);
				break;

			case DEATH_TURRET_MLRS:
			case DEATH_TURRET_HK:
			case DEATH_TURRET_WALK_ROCKET:
			case DEATH_TURRET_HELLION:
				sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_ROCKET_EXPLODE, this.origin, w_backoff * 1000, 1);
				break;

			case DEATH_TURRET_MACHINEGUN:
			case DEATH_TURRET_WALK_GUN:
				sound(this, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_MACHINEGUN_IMPACT, this.origin, w_backoff * 1000, 1);
				break;

			case DEATH_TURRET_PLASMA:
				sound(this, CH_SHOTS, SND_TUR_PLASMA_IMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_ELECTRO_IMPACT, this.origin, w_backoff * 1000, 1);
				break;

			case DEATH_TURRET_WALK_MELEE:
				sound(this, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_TE_SPARK, this.origin, w_backoff * 1000, 1);
				break;

			case DEATH_TURRET_PHASER:
				break;

			case DEATH_TURRET_TESLA:
				te_smallflash(this.origin);
				break;
		}
	}

	MUTATOR_CALLHOOK(DamageInfo, this, w_deathtype, w_org);

	// TODO spawn particle effects and sounds based on w_deathtype
	if(!DEATH_ISSPECIAL(w_deathtype))
	if(!hitplayer || rad) // don't show ground impacts for hitscan weapons if a player was hit
	{
		Weapon hitwep = DEATH_WEAPONOF(w_deathtype);
		w_random = prandom();

		vector force_dir = normalize(force);
		// this traceline usually starts in solid when a hitscan shot hits a surface with a very small angle
		// if so, try another traceline starting further back (may still start in solid but only with extremely small angles)
		traceline(w_org - force_dir * 16, w_org + force_dir * 16, MOVE_NOMONSTERS, NULL);
		if(trace_startsolid)
			traceline(w_org - force_dir * 40, w_org + force_dir * 16, MOVE_NOMONSTERS, NULL);
		if(trace_fraction < 1)
			w_backoff = trace_plane_normal;
		else
			w_backoff = -force_dir;
		setorigin(this, w_org + w_backoff * 2); // for sound() calls

		if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY))
		{
			if(!MUTATOR_CALLHOOK(Weapon_ImpactEffect, hitwep, this))
				hitwep.wr_impacteffect(hitwep, this);
		}
	}
}

#endif
