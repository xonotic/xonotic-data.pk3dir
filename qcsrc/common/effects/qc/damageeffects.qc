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
	WriteShort(MSG_ENTITY, this.oldorigin.x);
	WriteByte(MSG_ENTITY, this.species);
	return true;
}

void Damage_DamageInfo(vector org, float coredamage, float edgedamage, float rad, vector force, int deathtype, float bloodtype, entity dmgowner)
{
	// TODO maybe call this from non-edgedamage too?
	// TODO maybe make the client do the particle effects for the weapons and the impact sounds using this info?

	entity e;

	if(!sound_allowed(MSG_BROADCAST, dmgowner))
		deathtype |= 0x8000;

	e = new_pure(damageinfo);
	// origin is just data to be sent
	//setorigin(e, org);
	e.origin = org;
	e.projectiledeathtype = deathtype;
	e.dmg = coredamage;
	e.dmg_edge = edgedamage;
	e.dmg_radius = rad;
	e.dmg_force = vlen(force);
	e.velocity = force;
	e.oldorigin_x = compressShortVector(e.velocity);
	e.species = bloodtype;

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
		// if the player was dead but is now alive, it means he respawned
		// if so, clear his damage effects, or damages from his dead body will be copied back
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
	force = decompressShortVector(ReadShort());
	species = ReadByte();

	return = true;

	if (!isNew)
		return;

	if(rad < 0)
	{
		rad = -rad;
		forcemul = -1;
	}
	else
		forcemul = 1;

    FOREACH_ENTITY_RADIUS(w_org, rad + MAX_DAMAGEEXTRARADIUS, !it.tag_entity, {
		vector nearest = NearestPointOnBox(it, w_org);
		if (rad)
		{
			thisdmg = ((vlen (nearest - w_org) - bound(MIN_DAMAGEEXTRARADIUS, it.damageextraradius, MAX_DAMAGEEXTRARADIUS)) / rad);
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

		if((it.isplayermodel & ISPLAYER_MODEL))
			hitplayer = true; // this impact damaged a player
	});

	if(DEATH_ISVEHICLE(w_deathtype))
	{
		traceline(w_org - normalize(force) * 16, w_org + normalize(force) * 16, MOVE_NOMONSTERS, NULL);
		if(trace_plane_normal != '0 0 0')
			w_backoff = trace_plane_normal;
		else
			w_backoff = -1 * normalize(w_org - (w_org + normalize(force) * 16));

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
					vel = normalize(w_org - (w_org + normalize(force) * 16)) + randomvec() * 128;
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
				sound(this, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_EXPLOSION_BIG, this.origin, w_backoff * 1000, 1);
				break;
			case DEATH_VH_BUMB_GUN:
				sound(this, CH_SHOTS, SND_FIREBALL_IMPACT2, VOL_BASE, ATTEN_NORM);
				pointparticles(EFFECT_BIGPLASMA_IMPACT, this.origin, w_backoff * 1000, 1);
				break;
		}
	}


	if(DEATH_ISTURRET(w_deathtype))
	{
		traceline(w_org - normalize(force) * 16, w_org + normalize(force) * 16, MOVE_NOMONSTERS, NULL);
		if(trace_plane_normal != '0 0 0')
			w_backoff = trace_plane_normal;
		else
			w_backoff = -1 * normalize(w_org - (w_org + normalize(force) * 16));

		setorigin(this, w_org + w_backoff * 2); // for sound() calls

		switch(DEATH_ENT(w_deathtype))
		{
			 case DEATH_TURRET_EWHEEL:
				sound(this, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTEN_LOW);
				pointparticles(EFFECT_BLASTER_IMPACT, this.origin, w_backoff * 1000, 1);
				break;

			 case DEATH_TURRET_FLAC:
				pointparticles(EFFECT_HAGAR_EXPLODE, w_org, '0 0 0', 1);
				sound(this, CH_SHOTS, SND_HAGEXP_RANDOM(), VOL_BASE, ATTEN_NORM);
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
				sound(this, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTEN_LOW);
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

		traceline(w_org - normalize(force) * 16, w_org + normalize(force) * 16, MOVE_NOMONSTERS, NULL);
		if(trace_fraction < 1 && !(hitwep.spawnflags & WEP_TYPE_HITSCAN))
			w_backoff = trace_plane_normal;
		else
			w_backoff = -1 * normalize(force);
		setorigin(this, w_org + w_backoff * 2); // for sound() calls

		if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY))
		{
			if(!MUTATOR_CALLHOOK(Weapon_ImpactEffect, hitwep, this))
				hitwep.wr_impacteffect(hitwep, this);
		}
	}
}

#endif
