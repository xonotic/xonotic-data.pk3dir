#include "sv_vehicles.qh"

#include <common/items/_mod.qh>
#include <common/mapobjects/defs.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/mapobjects/triggers.qh>
#include <common/vehicles/vehicles.qh>
#include <server/bot/api.qh>
#include <server/client.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/weapons/common.qh>
#include <server/world.qh>

bool SendAuxiliaryXhair(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_AUXILIARYXHAIR);
	WriteByte(MSG_ENTITY, sf);

	WriteByte(MSG_ENTITY, this.cnt);

	if(sf & 2)
	{
		WriteVector(MSG_ENTITY, this.origin);
	}

	if(sf & 4)
	{
		WriteByte(MSG_ENTITY, rint(this.colormod_x * 255));
		WriteByte(MSG_ENTITY, rint(this.colormod_y * 255));
		WriteByte(MSG_ENTITY, rint(this.colormod_z * 255));
	}

	return true;
}

bool AuxiliaryXhair_customize(entity this, entity client)
{
	entity e = WaypointSprite_getviewentity(client);
	entity axh = e.(AuxiliaryXhair[this.cnt]);
	return axh.owner == this.owner; // cheaply check if the client's axh owner is the same as our real owner
}

.vector axh_prevorigin;
.vector axh_prevcolors;

void UpdateAuxiliaryXhair(entity own, vector loc, vector clr, int axh_id)
{
	if(!IS_REAL_CLIENT(own))
		return;

	axh_id = bound(0, axh_id, MAX_AXH);
	entity axh = own.(AuxiliaryXhair[axh_id]);

	if(axh == NULL || wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist? Mario: because of sloppy code like this)
	{
		axh = new(auxiliary_xhair);
		axh.cnt = axh_id;
		//axh.drawonlytoclient = own; // not spectatable
		setcefc(axh, AuxiliaryXhair_customize);
		axh.owner = own;
		Net_LinkEntity(axh, false, 0, SendAuxiliaryXhair);
	}

	if(loc != axh.axh_prevorigin)
	{
		setorigin(axh, loc);
		axh.SendFlags |= 2;
	}

	if(clr != axh.axh_prevcolors)
	{
		axh.colormod = clr;
		axh.SendFlags |= 4;
	}

	own.(AuxiliaryXhair[axh_id]) = axh; // set it anyway...?
}

void CSQCVehicleSetup(entity own, int vehicle_id)
{
	if(!IS_REAL_CLIENT(own))
		return;

	msg_entity = own;

	WriteHeader(MSG_ONE, TE_CSQC_VEHICLESETUP);
	WriteByte(MSG_ONE, vehicle_id);

	if(vehicle_id == 0 || vehicle_id == HUD_NORMAL)
	{
		for(int i = 0; i < MAX_AXH; ++i)
		{
			entity axh = own.(AuxiliaryXhair[i]);
			own.(AuxiliaryXhair[i]) = NULL;

			if(axh.owner == own && axh != NULL && !wasfreed(axh))
				delete(axh);
		}
	}
}

void vehicles_locktarget(entity this, float incr, float decr, float _lock_time)
{
	if(this.lock_target && IS_DEAD(this.lock_target))
	{
		this.lock_target	= NULL;
		this.lock_strength  = 0;
		this.lock_time	  = 0;
	}

	if(this.lock_time > time)
	{
		if(this.lock_target)
		if(this.lock_soundtime < time)
		{
			this.lock_soundtime = time + 0.5;
			play2(this.owner, "vehicles/locked.wav");
		}

		return;
	}

	if(trace_ent != NULL)
	{
		if(SAME_TEAM(trace_ent, this))
			trace_ent = NULL;

		if(IS_DEAD(trace_ent))
			trace_ent = NULL;

		if(!(IS_VEHICLE(trace_ent) || IS_TURRET(trace_ent)))
			trace_ent = NULL;

		if(trace_ent.alpha <= 0.5 && trace_ent.alpha != 0)
			trace_ent = NULL; // invisible
	}

	if(this.lock_target == NULL && trace_ent != NULL)
		this.lock_target = trace_ent;

	if(this.lock_target && trace_ent == this.lock_target)
	{
		if(this.lock_strength != 1 && this.lock_strength + incr >= 1)
		{
			play2(this.owner, "vehicles/lock.wav");
			this.lock_soundtime = time + 0.8;
		}
		else if (this.lock_strength != 1 && this.lock_soundtime < time)
		{
			play2(this.owner, "vehicles/locking.wav");
			this.lock_soundtime = time + 0.3;
		}
	}

	// Have a locking target
	// Trace hit current target
	if(trace_ent == this.lock_target && trace_ent != NULL)
	{
		this.lock_strength = min(this.lock_strength + incr, 1);
		if(this.lock_strength == 1)
			this.lock_time = time + _lock_time;
	}
	else
	{
		if(trace_ent)
			this.lock_strength = max(this.lock_strength - decr * 2, 0);
		else
			this.lock_strength = max(this.lock_strength - decr, 0);

		if(this.lock_strength == 0)
			this.lock_target = NULL;
	}
}

// projectile handling
void vehicles_projectile_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	// Ignore damage from oterh projectiles from my owner (dont mess up volly's)
	if(inflictor.owner == this.owner)
		return;

	TakeResource(this, RES_HEALTH, damage);
	this.velocity += force;
	if(GetResource(this, RES_HEALTH) < 1)
	{
		this.takedamage = DAMAGE_NO;
		this.event_damage = func_null;
		setthink(this, adaptor_think2use);
		this.nextthink = time;
	}
}

void vehicles_projectile_explode(entity this, entity toucher)
{
	if(this.owner && toucher != NULL)
	{
		if(toucher == this.owner.vehicle)
			return;

		if(toucher == this.owner.vehicle.tur_head)
			return;
	}

	PROJECTILE_TOUCH(this, toucher);

	this.event_damage = func_null;
	RadiusDamage (this, this.realowner, this.shot_dmg, 0, this.shot_radius, this, NULL, this.shot_force, this.projectiledeathtype, DMG_NOWEP, toucher);

	delete(this);
}

void vehicles_projectile_explode_think(entity this)
{
	vehicles_projectile_explode(this, NULL);
}

void vehicles_projectile_explode_use(entity this, entity actor, entity trigger)
{
	vehicles_projectile_explode(this, trigger);
}

entity vehicles_projectile(entity this, entity _mzlfx, Sound _mzlsound,
						   vector _org, vector _vel,
						   float _dmg, float _radi, float _force,  float _size,
						   int _deahtype, float _projtype, float _health,
						   bool _cull, bool _clianim, entity _owner)
{
    TC(Sound, _mzlsound);
	entity proj = new(vehicles_projectile);

	PROJECTILE_MAKETRIGGER(proj);
	setorigin(proj, _org);

	proj.shot_dmg		 = _dmg;
	proj.shot_radius	  = _radi;
	proj.shot_force	   = _force;
	proj.projectiledeathtype	   = _deahtype;
	proj.solid			= SOLID_BBOX;
	set_movetype(proj, MOVETYPE_FLYMISSILE);
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.bot_dodge		= true;
	proj.bot_dodgerating  = _dmg;
	proj.velocity		 = _vel;
	settouch(proj, vehicles_projectile_explode);
	proj.use			  = vehicles_projectile_explode_use;
	proj.owner			= this;
	proj.realowner		= _owner;
	setthink(proj, SUB_Remove);
	proj.nextthink		= time + 30;

	if(_health)
	{
		proj.takedamage	   = DAMAGE_AIM;
		proj.event_damage	 = vehicles_projectile_damage;
		SetResourceExplicit(proj, RES_HEALTH, _health);
	}
	else
		proj.flags |= FL_NOTARGET;

	if(_mzlsound != SND_Null)
		sound (this, CH_WEAPON_A, _mzlsound, VOL_BASE, ATTEN_NORM);

	if(_mzlfx != EFFECT_Null)
		Send_Effect(_mzlfx, proj.origin, proj.velocity, 1);

	setsize (proj, '-1 -1 -1' * _size, '1 1 1' * _size);

	CSQCProjectile(proj, _clianim, _projtype, _cull);

	return proj;
}

void vehicles_gib_explode(entity this)
{
	sound (this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_EXPLOSION_SMALL, randomvec() * 80 + (this.origin + '0 0 100'), '0 0 0', 1);
	Send_Effect(EFFECT_EXPLOSION_SMALL, this.wp00.origin + '0 0 64', '0 0 0', 1);
	delete(this);
}

void vehicles_gib_touch(entity this, entity toucher)
{
	vehicles_gib_explode(this);
}

void vehicles_gib_think(entity this)
{
	this.alpha -= 0.1;
	if(this.cnt >= time)
		delete(this);
	else
		this.nextthink = time + 0.1;
}

entity vehicle_tossgib(entity this, entity _template, vector _vel, string _tag, bool _burn, bool _explode, float _maxtime, vector _rot)
{
	entity _gib = new(vehicle_gib);
	_setmodel(_gib, _template.model);
	vector org = gettaginfo(this, gettagindex(this, _tag));
	setorigin(_gib, org);
	_gib.velocity = _vel;
	set_movetype(_gib, MOVETYPE_TOSS);
	_gib.solid = SOLID_CORPSE;
	_gib.colormod = '-0.5 -0.5 -0.5';
	_gib.effects = EF_LOWPRECISION;
	_gib.avelocity = _rot;

	if(_burn)
		_gib.effects |= EF_FLAME;

	if(_explode)
	{
		setthink(_gib, vehicles_gib_explode);
		_gib.nextthink = time + random() * _explode;
		settouch(_gib, vehicles_gib_touch);
	}
	else
	{
		_gib.cnt = time + _maxtime;
		setthink(_gib, vehicles_gib_think);
		_gib.nextthink = time + _maxtime - 1;
		_gib.alpha = 1;
	}
	return _gib;
}

bool vehicle_addplayerslot(	entity _owner,
								entity _slot,
								int _hud,
								Model _hud_model,
								bool(entity,float) _framefunc,
								void(entity,bool) _exitfunc, float(entity, entity) _enterfunc)
{
	if(!(_owner.vehicle_flags & VHF_MULTISLOT))
		_owner.vehicle_flags |= VHF_MULTISLOT;

	_slot.PlayerPhysplug = _framefunc;
	_slot.vehicle_exit = _exitfunc;
	_slot.vehicle_enter = _enterfunc;
	STAT(HUD, _slot) = _hud;
	_slot.vehicle_flags = VHF_PLAYERSLOT;
	_slot.vehicle_viewport = new(vehicle_viewport);
	_slot.vehicle_hudmodel = new(vehicle_hudmodel);
	_slot.vehicle_hudmodel.viewmodelforclient = _slot;
	_slot.vehicle_viewport.effects = (EF_ADDITIVE | EF_DOUBLESIDED | EF_FULLBRIGHT | EF_NODEPTHTEST | EF_NOGUNBOB | EF_NOSHADOW | EF_LOWPRECISION | EF_SELECTABLE | EF_TELEPORT_BIT);

	setmodel(_slot.vehicle_hudmodel, _hud_model);
	setmodel(_slot.vehicle_viewport, MDL_Null);

	setattachment(_slot.vehicle_hudmodel, _slot, "");
	setattachment(_slot.vehicle_viewport, _slot.vehicle_hudmodel, "");

	return true;
}

vector vehicle_aimturret(entity _vehic, vector _target, entity _turrret, string _tagname,
						 float _pichlimit_min, float _pichlimit_max,
						 float _rotlimit_min, float _rotlimit_max, float _aimspeed, float dt)
{
	vector vtmp, vtag;
	float ftmp;
	vtag = gettaginfo(_turrret, gettagindex(_turrret, _tagname));
	vtmp = vectoangles(normalize(_target - vtag));
	vtmp = AnglesTransform_ToAngles(AnglesTransform_LeftDivide(AnglesTransform_FromAngles(_vehic.angles), AnglesTransform_FromAngles(vtmp))) - _turrret.angles;
	vtmp = AnglesTransform_Normalize(vtmp, true);
	ftmp = _aimspeed * dt;
	vtmp_y = bound(-ftmp, vtmp_y, ftmp);
	vtmp_x = bound(-ftmp, vtmp_x, ftmp);
	_turrret.angles_y = bound(_rotlimit_min, _turrret.angles_y + vtmp_y, _rotlimit_max);
	_turrret.angles_x = bound(_pichlimit_min, _turrret.angles_x + vtmp_x, _pichlimit_max);
	return vtag;
}

void vehicles_reset_colors(entity this, entity player)
{
	int eff = 0, cmap;
	const vector cmod = '0 0 0';
	if(this.team && teamplay)
		cmap = 1024 + (this.team - 1) * 17;
	else if(player)
		cmap = player.colormap;
	else
		cmap = 1024;
	if(autocvar_g_nodepthtestplayers)
		eff |= EF_NODEPTHTEST;
	if(autocvar_g_fullbrightplayers)
		eff |= EF_FULLBRIGHT;

	// Find all ents attacked to main model and setup effects, colormod etc.
	FOREACH_ENTITY_ENT(tag_entity, this,
	{
		if(it == this.vehicle_shieldent)
			continue;

		it.effects = eff;
		it.colormod = cmod;
		it.colormap = cmap;
		it.alpha = 1;
	});

	// Also check head tags
	FOREACH_ENTITY_ENT(tag_entity, this.tur_head,
	{
		if(it == this.vehicle_shieldent)
			continue;

		it.effects = eff;
		it.colormod = cmod;
		it.colormap = cmap;
		it.alpha = 1;
	});

	this.vehicle_hudmodel.effects  = this.effects  = eff; // | EF_LOWPRECISION;
	this.vehicle_hudmodel.colormod = this.colormod = cmod;
	this.vehicle_hudmodel.colormap = this.colormap = cmap;
	this.vehicle_viewport.effects = (EF_ADDITIVE | EF_DOUBLESIDED | EF_FULLBRIGHT | EF_NODEPTHTEST | EF_NOGUNBOB | EF_NOSHADOW | EF_LOWPRECISION | EF_SELECTABLE | EF_TELEPORT_BIT);

	this.alpha	 = 1;
	this.avelocity = '0 0 0';
	this.velocity  = '0 0 0';
	this.effects   = eff;

	Vehicle info = this.vehicledef; //REGISTRY_GET(Vehicles, this.vehicleid);
	info.vr_setcolors(info, this);
}

void vehicles_clearreturn(entity veh)
{
	// Remove "return helper" entities, if any.
	IL_EACH(g_vehicle_returners, it.wp00 == veh,
	{
		it.classname = "";
		setthink(it, SUB_Remove);
		it.nextthink = time + 0.1;
		IL_REMOVE(g_vehicle_returners, it);

		if(it.waypointsprite_attached)
			WaypointSprite_Kill(it.waypointsprite_attached);
	});
}

void vehicles_spawn(entity this);
void vehicles_return(entity this)
{
	Send_Effect(EFFECT_TELEPORT, this.wp00.origin + '0 0 64', '0 0 0', 1);

	setthink(this.wp00, vehicles_spawn);
	this.wp00.nextthink = time;

	if(this.waypointsprite_attached)
		WaypointSprite_Kill(this.waypointsprite_attached);

	delete(this);
}

void vehicles_showwp_goaway(entity this)
{
	if(this.waypointsprite_attached)
		WaypointSprite_Kill(this.waypointsprite_attached);

	delete(this);
}

void vehicles_showwp(entity this)
{
	entity ent = this;

	if(ent.cnt)
	{
		setthink(ent, vehicles_return);
		ent.nextthink = ent.cnt;
	}
	else
	{
		setthink(ent, vehicles_return);
		ent.nextthink  = time + 1;

		ent = spawn();
		ent.team = this.wp00.team;
		ent.wp00 = this.wp00;
		setorigin(ent, this.wp00.pos1);

		ent.nextthink = time + 5;
		setthink(ent, vehicles_showwp_goaway);
	}

	vector rgb;
	if(teamplay && ent.team)
		rgb = Team_ColorRGB(ent.team);
	else
		rgb = '1 1 1';
	entity wp = WaypointSprite_Spawn(WP_Vehicle, 0, 0, ent, '0 0 64', NULL, 0, ent, waypointsprite_attached, true, RADARICON_Vehicle);
	wp.wp_extra = ent.wp00.vehicleid;
	wp.colormod = rgb;
	if(ent.waypointsprite_attached)
	{
		WaypointSprite_UpdateRule(ent.waypointsprite_attached, ent.wp00.team, SPRITERULE_DEFAULT);
		if(this == NULL)
			WaypointSprite_UpdateBuildFinished(ent.waypointsprite_attached, ent.nextthink);
		WaypointSprite_Ping(ent.waypointsprite_attached);
	}
}

void vehicles_setreturn(entity veh)
{
	vehicles_clearreturn(veh);

	entity ret = new(vehicle_return);
	IL_PUSH(g_vehicle_returners, ret);
	ret.wp00	   = veh;
	ret.team		= veh.team;
	setthink(ret, vehicles_showwp);

	if(IS_DEAD(veh))
	{
		ret.cnt		 = time + veh.respawntime;
		ret.nextthink   = min(time + veh.respawntime, time + veh.respawntime - 5);
	}
	else
	{
		ret.nextthink   = min(time + veh.respawntime, time + veh.respawntime - 1);
	}

	setorigin(ret, veh.pos1 + '0 0 96');
}

void vehicle_use(entity this, entity actor, entity trigger)
{
	LOG_DEBUG("vehicle ", this.netname, " used by ", actor.classname);

	this.tur_head.team = actor.team;

	if(this.tur_head.team == 0)
		this.active = ACTIVE_NOT;
	else
		this.active = ACTIVE_ACTIVE;

	if(this.active == ACTIVE_ACTIVE && !IS_DEAD(this) && !game_stopped)
	{
		LOG_DEBUG("Respawning vehicle: ", this.netname);
		if(this.effects & EF_NODRAW)
		{
			setthink(this, vehicles_spawn);
			this.nextthink = time + 3;
		}
		else
		{
			vehicles_setreturn(this);
			vehicles_reset_colors(this, actor);
		}
	}
}

void vehicles_regen(entity this, float timer, .float regen_field, float field_max, float rpause, float regen, float delta_time, float _healthscale)
{
	if(this.(regen_field) < field_max)
	if(timer + rpause < time)
	{
		if(_healthscale)
			regen = regen * (GetResource(this, RES_HEALTH) / this.max_health);

		this.(regen_field) = min(this.(regen_field) + regen * delta_time, field_max);

		if(this.owner)
			this.owner.(regen_field) = (this.(regen_field) / field_max) * 100;
	}
}

void vehicles_regen_resource(entity this, float timer, .float regen_field, float field_max, float rpause, float regen, float delta_time, float _healthscale, Resource resource)
{
	float resource_amount = GetResource(this, resource);

	if(resource_amount < field_max)
	if(timer + rpause < time)
	{
		if(_healthscale)
			regen = regen * (resource_amount / this.max_health);

		SetResource(this, resource, min(resource_amount + regen * delta_time, field_max));

		if(this.owner)
			this.owner.(regen_field) = (GetResource(this, resource) / field_max) * 100;
	}
}

void shieldhit_think(entity this)
{
	this.alpha -= 0.1;
	if (this.alpha <= 0)
	{
		// setmodel(this, MDL_Null);
		this.alpha = -1;
		this.effects |= EF_NODRAW;
	}
	else
	{
		this.nextthink = time + 0.1;
	}
}

void vehicles_painframe(entity this)
{
	int myhealth = ((this.owner) ? this.owner.vehicle_health : ((GetResource(this, RES_HEALTH) / this.max_health) * 100));

	if(myhealth <= 50)
	if(this.pain_frame < time)
	{
		float _ftmp = myhealth / 50;
		this.pain_frame = time + max(0.1, 0.1 + (random() * 0.5 * _ftmp));
		Send_Effect(EFFECT_SMOKE_SMALL, (this.origin + (randomvec() * 80)), '0 0 0', 1);

		if(this.vehicle_flags & VHF_DMGSHAKE)
			this.velocity += randomvec() * 30;

		if(this.vehicle_flags & VHF_DMGROLL)
		{
			if(this.vehicle_flags & VHF_DMGHEADROLL)
				this.tur_head.angles += randomvec();
			else
				this.angles += randomvec();
		}
	}
}

void vehicles_frame(entity this, entity actor)
{
	vehicles_painframe(this);
}

void vehicles_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	this.dmg_time = time;

	// WEAPONTODO
	if(DEATH_ISWEAPON(deathtype, WEP_VORTEX))
		damage *= autocvar_g_vehicles_vortex_damagerate;
	else if(DEATH_ISWEAPON(deathtype, WEP_MACHINEGUN))
		damage *= autocvar_g_vehicles_machinegun_damagerate;
	else if(DEATH_ISWEAPON(deathtype, WEP_RIFLE))
		damage *= autocvar_g_vehicles_rifle_damagerate;
	else if(DEATH_ISWEAPON(deathtype, WEP_VAPORIZER))
		damage *= autocvar_g_vehicles_vaporizer_damagerate;
	else if(DEATH_ISWEAPON(deathtype, WEP_SEEKER))
		damage *= autocvar_g_vehicles_tag_damagerate;
	else if(DEATH_WEAPONOF(deathtype) != WEP_Null)
		damage *= autocvar_g_vehicles_weapon_damagerate;

	this.enemy = attacker;

	this.pain_finished = time;

	if((this.vehicle_flags & VHF_HASSHIELD) && (this.vehicle_shield > 0))
	{
		if (wasfreed(this.vehicle_shieldent) || this.vehicle_shieldent == NULL)
		{
			this.vehicle_shieldent = new(vehicle_shieldent);
			this.vehicle_shieldent.effects = EF_LOWPRECISION;

			setmodel(this.vehicle_shieldent, MDL_VEH_SHIELD);
			setattachment(this.vehicle_shieldent, this, "");
			setorigin(this.vehicle_shieldent, real_origin(this) - this.origin);
			this.vehicle_shieldent.scale	   = 256 / vlen(this.maxs - this.mins);
			setthink(this.vehicle_shieldent, shieldhit_think);
		}

		this.vehicle_shieldent.colormod	= '1 1 1';
		this.vehicle_shieldent.alpha = 0.45;
		this.vehicle_shieldent.angles = vectoangles(normalize(hitloc - (this.origin + this.vehicle_shieldent.origin))) - this.angles;
		this.vehicle_shieldent.nextthink = time;
		this.vehicle_shieldent.effects &= ~EF_NODRAW;

		this.vehicle_shield -= damage;

		if(this.vehicle_shield < 0)
		{
			TakeResource(this, RES_HEALTH, fabs(this.vehicle_shield));
			this.vehicle_shieldent.colormod = '2 0 0';
			this.vehicle_shield = 0;
			this.vehicle_shieldent.alpha = 0.75;

			if(sound_allowed(MSG_BROADCAST, attacker))
				spamsound (this, CH_PAIN, SND_ONS_HIT2, VOL_BASE, ATTEN_NORM);   // FIXME: PLACEHOLDER
		}
		else
			if(sound_allowed(MSG_BROADCAST, attacker))
				spamsound (this, CH_PAIN, SND_ONS_ELECTRICITY_EXPLODE, VOL_BASE, ATTEN_NORM);  // FIXME: PLACEHOLDER

	}
	else
	{
		TakeResource(this, RES_HEALTH, damage);

		if(sound_allowed(MSG_BROADCAST, attacker))
			spamsound (this, CH_PAIN, SND_ONS_HIT2, VOL_BASE, ATTEN_NORM);  // FIXME: PLACEHOLDER
	}

	if(this.damageforcescale < 1 && this.damageforcescale > 0)
		this.velocity += force * this.damageforcescale;
	else
		this.velocity += force;

	if(GetResource(this, RES_HEALTH) <= 0)
	{
		if(this.owner)
		{
			if(this.vehicle_flags & VHF_DEATHEJECT)
				vehicles_exit(this, VHEF_EJECT);
			else
				vehicles_exit(this, VHEF_RELEASE);
		}

		antilag_clear(this, this);

		Vehicle info = this.vehicledef; //REGISTRY_GET(Vehicles, this.vehicleid);
		info.vr_death(info, this);
		vehicles_setreturn(this);
	}
}

bool vehicles_heal(entity targ, entity inflictor, float amount, float limit)
{
	float true_limit = ((limit != RES_LIMIT_NONE) ? limit : targ.max_health);
	if(GetResource(targ, RES_HEALTH) <= 0 || GetResource(targ, RES_HEALTH) >= true_limit)
		return false;

	GiveResourceWithLimit(targ, RES_HEALTH, amount, true_limit);
	if(targ.owner)
		targ.owner.vehicle_health = (GetResource(targ, RES_HEALTH) / targ.max_health) * 100;
	return true;
}

bool vehicles_crushable(entity e)
{
	if(IS_PLAYER(e) && time >= e.vehicle_enter_delay)
		return true;

	if(IS_MONSTER(e))
		return true;

	return false;
}

void vehicles_impact(entity this, float _minspeed, float _speedfac, float _maxpain)
{
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		return;

	if(this.play_time < time)
	{
		if(vdist(this.velocity - this.oldvelocity, >, _minspeed))
		{
			float wc = vlen(this.velocity - this.oldvelocity);
			float take = min(_speedfac * wc, _maxpain);
			Damage(this, NULL, NULL, take, DEATH_FALL.m_id, DMG_NOWEP, this.origin, '0 0 0');
			this.play_time = time + 0.25;
		}
	}
}

// vehicle enter/exit handling
vector vehicles_findgoodexit(entity this, entity player, vector prefer_spot)
{
	// TODO: we actually want the player's size here
	tracebox(this.origin + '0 0 32', PL_MIN_CONST, PL_MAX_CONST, prefer_spot, MOVE_NORMAL, player);
	if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
		return prefer_spot;

	float mysize = 1.5 * vlen(this.maxs - this.mins);
	vector v;
	vector v2 = 0.5 * (this.absmin + this.absmax);
	for(int i = 0; i < autocvar_g_vehicles_exit_attempts; ++i)
	{
		v = randomvec();
		v_z = 0;
		v = v2 + normalize(v) * mysize;
		tracebox(v2, PL_MIN_CONST, PL_MAX_CONST, v, MOVE_NORMAL, player);
		if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
			return v;
	}

	return this.origin;
}

.int old_vehicle_flags;
void vehicles_exit(entity vehic, bool eject)
{
	entity player = vehic.owner;

	if(vehicles_exit_running)
	{
		LOG_TRACE("^1vehicles_exit already running! this is not good...");
		return;
	}

	vehicles_exit_running = true;

	if(vehic.vehicle_flags & VHF_PLAYERSLOT)
	{
		vehic.vehicle_exit(vehic, eject);
		vehicles_exit_running = false;
		return;
	}

	if (player)
	{
		if (IS_REAL_CLIENT(player))
		{
			msg_entity = player;
			WriteByte (MSG_ONE, SVC_SETVIEWPORT);
			WriteEntity( MSG_ONE, player);

			// NOTE: engine networked
			WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
			WriteAngle(MSG_ONE, 0);
			WriteAngle(MSG_ONE, vehic.angles_y);
			WriteAngle(MSG_ONE, 0);
		}

		player.takedamage		= DAMAGE_AIM;
		player.solid			= SOLID_SLIDEBOX;
		set_movetype(player, MOVETYPE_WALK);
		player.effects		   &= ~EF_NODRAW;
		player.teleportable		= TELEPORT_NORMAL;
		player.alpha			= default_player_alpha;
		player.PlayerPhysplug	= func_null;
		player.vehicle			= NULL;
		player.view_ofs			= STAT(PL_VIEW_OFS, player);
		player.event_damage		= PlayerDamage;
		STAT(HUD, player)		= HUD_NORMAL;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++ slot)
		{
			.entity weaponentity = weaponentities[slot];
			player.(weaponentity).m_switchweapon = vehic.(weaponentity).m_switchweapon;
			delete(vehic.(weaponentity)); // no longer needed
		}
		player.last_vehiclecheck = time + 3;
		player.vehicle_enter_delay = time + 2;
		setsize(player, STAT(PL_MIN, player), STAT(PL_MAX, player));

		CSQCVehicleSetup(player, HUD_NORMAL);

		Kill_Notification(NOTIF_ONE, player, MSG_CENTER, CPID_VEHICLES);
		Kill_Notification(NOTIF_ONE, player, MSG_CENTER, CPID_VEHICLES_OTHER); // kill all vehicle notifications when exiting a vehicle?
	}

	vehic.flags |= FL_NOTARGET;

	if(!IS_DEAD(vehic))
		vehic.avelocity = '0 0 0';

	vehic.tur_head.nodrawtoclient = NULL;

	if(!teamplay)
		vehic.team = 0;

	WaypointSprite_Kill(vehic.wps_intruder);

	MUTATOR_CALLHOOK(VehicleExit, player, vehic);

	vehic.team = vehic.tur_head.team;

	if(vehic.old_vehicle_flags & VHF_SHIELDREGEN)
		vehic.vehicle_flags |= VHF_SHIELDREGEN;
	vehic.old_vehicle_flags = 0;

	sound (vehic, CH_TRIGGER_SINGLE, SND_Null, 1, ATTEN_NORM);
	vehic.vehicle_hudmodel.viewmodelforclient = vehic;
	vehic.phase = time + 1;

	vehic.vehicle_exit(vehic, eject);

	vehicles_setreturn(vehic);
	vehicles_reset_colors(vehic, NULL);
	vehic.owner = NULL;

	CSQCMODEL_AUTOINIT(vehic);

	if(player)
		player.oldorigin = player.origin; // player's location is set by the exit functions, so we need to do this after everything

	vehicles_exit_running = false;
}

void vehicles_touch(entity this, entity toucher)
{
	if(MUTATOR_CALLHOOK(VehicleTouch, this, toucher))
		return;

	// Vehicle currently in use
	if(this.owner)
	{
		if(toucher != NULL)
		if((this.origin_z + this.maxs_z) > (toucher.origin_z))
		if(vehicles_crushable(toucher))
		if(!weaponLocked(this.owner))
		{
			if(vdist(this.velocity, >=, autocvar_g_vehicles_crush_minspeed))
				Damage(toucher, this, this.owner, autocvar_g_vehicles_crush_dmg, DEATH_VH_CRUSH.m_id, DMG_NOWEP, '0 0 0', normalize(toucher.origin - this.origin) * autocvar_g_vehicles_crush_force);

			return; // Dont do selfdamage when hitting "soft targets".
		}

		if(this.play_time < time) {
			Vehicle info = this.vehicledef; //REGISTRY_GET(Vehicles, this.vehicleid);
			info.vr_impact(info, this);
		}

		return;
	}

	if(autocvar_g_vehicles_enter)
		return;

	vehicles_enter(toucher, this);
}

bool vehicle_impulse(entity this, int imp)
{
	entity v = this.vehicle;
	if (!v) return false;
	if (IS_DEAD(v)) return false;
	bool(entity,int) f = v.vehicles_impulse;
	if (f && f(this,imp)) return true;
	switch (imp)
	{
		case IMP_weapon_drop.impulse:
		{
			stuffcmd(this, "\ntoggle cl_eventchase_vehicle\nset _vehicles_shownchasemessage 1\n");
			return true;
		}
	}
	return false;
}

void vehicles_enter(entity pl, entity veh)
{
	// Remove this when bots know how to use vehicles
	if((IS_BOT_CLIENT(pl) && !autocvar_g_vehicles_allow_bots))
		return;

	// TODO: mutator hook to prevent entering vehicles
	if((!IS_PLAYER(pl))
	|| (veh.phase >= time)
	|| (pl.vehicle_enter_delay >= time)
	|| (STAT(FROZEN, pl) || StatusEffects_active(STATUSEFFECT_Frozen, pl))
	|| (IS_DEAD(pl))
	|| (pl.vehicle)
	) { return; }

	Vehicle info = veh.vehicledef; //REGISTRY_GET(Vehicles, veh.vehicleid);

	if(autocvar_g_vehicles_enter) // vehicle's touch function should handle this if entering via use key is disabled (TODO)
	if(veh.vehicle_flags & VHF_MULTISLOT)
	if(veh.owner && SAME_TEAM(pl, veh))
	{
		// we don't need a return value or anything here
		// if successful the owner check below will prevent anything weird
		info.vr_gunner_enter(info, veh, pl);
	}

	if(veh.owner)
		return; // got here and didn't enter the gunner, return

	if(teamplay)
	if(veh.team)
	if(DIFF_TEAM(pl, veh))
	if(autocvar_g_vehicles_steal)
	{
		FOREACH_CLIENT(IS_PLAYER(it) && SAME_TEAM(it, veh), Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_VEHICLE_STEAL));

		Send_Notification(NOTIF_ONE, pl, MSG_CENTER, CENTER_VEHICLE_STEAL_SELF);

		veh.vehicle_shield = 0;
		veh.old_vehicle_flags = veh.vehicle_flags; // make a backup just so we're not permanently crippling this vehicle
		veh.vehicle_flags &= ~VHF_SHIELDREGEN;

		if (autocvar_g_vehicles_steal_show_waypoint) {
			entity wp = WaypointSprite_Spawn(WP_VehicleIntruder, 0, 0, pl, '0 0 68', NULL, veh.team, veh, wps_intruder, true, RADARICON_DANGER);
			wp.colormod = Team_ColorRGB(pl.team);
		}
	}
	else return;

	RemoveGrapplingHooks(pl);

	veh.vehicle_ammo1 = 0;
	veh.vehicle_ammo2 = 0;
	veh.vehicle_reload1 = 0;
	veh.vehicle_reload2 = 0;
	veh.vehicle_energy = 0;

	veh.owner = pl;
	pl.vehicle = veh;

	// .viewmodelforclient works better.
	//veh.vehicle_hudmodel.drawonlytoclient = veh.owner;

	veh.vehicle_hudmodel.viewmodelforclient = pl;

	UNSET_DUCKED(pl);
	pl.view_ofs = STAT(PL_VIEW_OFS, pl);
	setsize(pl, STAT(PL_MIN, pl), STAT(PL_MAX, pl));

	veh.event_damage	= vehicles_damage;
	veh.event_heal 		= vehicles_heal;
	veh.nextthink		= 0;
	pl.items &= ~IT_USING_JETPACK;
	pl.angles			= veh.angles;
	pl.takedamage		= DAMAGE_NO;
	pl.solid			= SOLID_NOT;
	pl.disableclientprediction = 1; // physics is no longer run, so this won't be reset
	set_movetype(pl, MOVETYPE_NOCLIP);
	pl.teleportable		= false;
	pl.alpha			= -1;
	pl.event_damage		= func_null;
	pl.view_ofs			= '0 0 0';
	veh.colormap		= pl.colormap;
	if(veh.tur_head)
		veh.tur_head.colormap = pl.colormap;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		veh.(weaponentity) = new(temp_wepent);
		veh.(weaponentity).m_switchweapon = pl.(weaponentity).m_switchweapon;
	}
	STAT(HUD, pl) = veh.vehicleid;
	pl.PlayerPhysplug = veh.PlayerPhysplug;

	pl.vehicle_ammo1 = veh.vehicle_ammo1;
	pl.vehicle_ammo2 = veh.vehicle_ammo2;
	pl.vehicle_reload1 = veh.vehicle_reload1;
	pl.vehicle_reload2 = veh.vehicle_reload2;
	pl.vehicle_energy = veh.vehicle_energy;

	// Cant do this, hides attached objects too.
	//veh.exteriormodeltoclient = veh.owner;
	//veh.tur_head.exteriormodeltoclient = veh.owner;

	UNSET_ONGROUND(pl);
	UNSET_ONGROUND(veh);

	veh.team = pl.team;
	veh.flags -= FL_NOTARGET;

	vehicles_reset_colors(veh, pl);

	if (IS_REAL_CLIENT(pl))
	{
		Send_Notification(NOTIF_ONE, pl, MSG_CENTER, CENTER_VEHICLE_ENTER);

		msg_entity = pl;
		WriteByte (MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, veh.vehicle_viewport);

		// NOTE: engine networked
		WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
		if(veh.tur_head)
		{
			WriteAngle(MSG_ONE, veh.tur_head.angles_x + veh.angles_x); // tilt
			WriteAngle(MSG_ONE, veh.tur_head.angles_y + veh.angles_y); // yaw
			WriteAngle(MSG_ONE, 0);									  // roll
		}
		else
		{
			WriteAngle(MSG_ONE, veh.angles_x * -1); // tilt
			WriteAngle(MSG_ONE, veh.angles_y);	  // yaw
			WriteAngle(MSG_ONE, 0);				  // roll
		}
	}

	vehicles_clearreturn(veh);

	CSQCVehicleSetup(pl, veh.vehicleid);

	MUTATOR_CALLHOOK(VehicleEnter, pl, veh);

	CSQCModel_UnlinkEntity(veh);
	info.vr_enter(info, veh);

	antilag_clear(pl, CS(pl));
}

void vehicles_think(entity this)
{
	this.nextthink = time + autocvar_g_vehicles_thinkrate;

	if(this.owner)
		STAT(VEHICLESTAT_W2MODE, this.owner) = STAT(VEHICLESTAT_W2MODE, this);

	Vehicle info = this.vehicledef; //REGISTRY_GET(Vehicles, this.vehicleid);
	info.vr_think(info, this);

	vehicles_painframe(this);

	CSQCMODEL_AUTOUPDATE(this);
}

void vehicles_reset(entity this)
{
	if(this.owner)
		vehicles_exit(this, VHEF_RELEASE);

	vehicles_clearreturn(this);

	if(this.active != ACTIVE_NOT)
		vehicles_spawn(this);
}

// initialization
void vehicles_spawn(entity this)
{
	LOG_DEBUG("Spawning vehicle: ", this.classname);

	// disown & reset
	this.vehicle_hudmodel.viewmodelforclient = this;

	this.owner				= NULL;
	settouch(this, vehicles_touch);
	this.event_damage		= vehicles_damage;
	this.event_heal 		= vehicles_heal;
	this.reset 				= vehicles_reset;
	this.iscreature			= true;
	this.teleportable		= false; // no teleporting for vehicles, too buggy
	this.damagedbycontents	= true;
	set_movetype(this, MOVETYPE_WALK);
	this.solid				= SOLID_SLIDEBOX;
	this.takedamage			= DAMAGE_AIM;
	this.deadflag			= DEAD_NO;
	if(!this.bot_attack)
		IL_PUSH(g_bot_targets, this);
	this.bot_attack			= true;
	this.flags				= FL_NOTARGET;
	this.avelocity			= '0 0 0';
	this.velocity			= '0 0 0';
	setthink(this, vehicles_think);
	this.nextthink			= time;

	// Reset locking
	this.lock_strength = 0;
	this.lock_target = NULL;
	this.misc_bulletcounter = 0;

	// Return to spawn
	this.angles = this.pos2;
	setorigin(this, this.pos1);
	// Show it
	Send_Effect(EFFECT_TELEPORT, this.origin + '0 0 64', '0 0 0', 1);

	if(this.vehicle_controller)
		this.team = this.vehicle_controller.team;

	FOREACH_CLIENT(IS_PLAYER(it),
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	    {
	    	.entity weaponentity = weaponentities[slot];
	    	if(it.(weaponentity).hook.aiment == this)
	    		RemoveHook(it.(weaponentity).hook);
	    }
	});


	Vehicle info = this.vehicledef; //REGISTRY_GET(Vehicles, this.vehicleid);
	info.vr_spawn(info, this);

	vehicles_reset_colors(this, NULL);

	CSQCMODEL_AUTOINIT(this);
}

bool vehicle_initialize(entity this, Vehicle info, bool nodrop)
{
	if(!autocvar_g_vehicles)
		return false;

	if(!info.vehicleid)
		return false;

	if(!this.tur_head)
		info.vr_precache(info);

	if(this.targetname && this.targetname != "")
	{
		this.vehicle_controller = find(NULL, target, this.targetname);
		if(!this.vehicle_controller)
		{
			LOG_DEBUG("^1WARNING: ^7Vehicle with invalid .targetname");
			this.active = ACTIVE_ACTIVE;
		}
		else
		{
			this.team = this.vehicle_controller.team;
			this.use = vehicle_use;

			if(teamplay)
			{
				if(this.vehicle_controller.team == 0)
					this.active = ACTIVE_NOT;
				else
					this.active = ACTIVE_ACTIVE;
			}
		}
	}
	else { this.active = ACTIVE_ACTIVE; }

	if(this.team && (!teamplay || !autocvar_g_vehicles_teams))
		this.team = 0;

	if(this.mdl == "" || !this.mdl)
		_setmodel(this, info.model);
	else
		_setmodel(this, this.mdl);

	this.vehicle_flags |= VHF_ISVEHICLE;

	this.vehicle_viewport		= new(vehicle_viewport);
	this.vehicle_hudmodel		= new(vehicle_hudmodel);
	this.tur_head				= new(tur_head);
	this.tur_head.owner			= this;
	this.takedamage				= DAMAGE_NO;
	this.bot_attack				= true;
	IL_PUSH(g_bot_targets, this);
	this.iscreature				= true;
	this.teleportable			= false; // no teleporting for vehicles, too buggy
	this.damagedbycontents		= true;
	IL_PUSH(g_damagedbycontents, this);
	this.vehicleid				= info.vehicleid;
	this.vehicledef 			= info;
	this.PlayerPhysplug			= info.PlayerPhysplug;
	this.event_damage			= func_null;
	this.event_heal 			= func_null;
	settouch(this, vehicles_touch);
	setthink(this, vehicles_spawn);
	this.nextthink				= time;
	this.effects				= EF_NODRAW;
	this.dphitcontentsmask		= DPCONTENTS_BODY | DPCONTENTS_SOLID;

	if(autocvar_g_playerclip_collisions)
		this.dphitcontentsmask |= DPCONTENTS_PLAYERCLIP;

	if(autocvar_g_nodepthtestplayers)
		this.effects |= EF_NODEPTHTEST;

	if(autocvar_g_fullbrightplayers)
		this.effects |= EF_FULLBRIGHT;

	_setmodel(this.vehicle_hudmodel, info.hud_model);
	setmodel(this.vehicle_viewport, MDL_Null);

	if(info.head_model != "")
	{
		_setmodel(this.tur_head, info.head_model);
		setattachment(this.tur_head, this, info.tag_head);
		setattachment(this.vehicle_hudmodel, this.tur_head, info.tag_hud);
		setattachment(this.vehicle_viewport, this.vehicle_hudmodel, info.tag_view);
	}
	else
	{
		setattachment(this.tur_head, this, "");
		setattachment(this.vehicle_hudmodel, this, info.tag_hud);
		setattachment(this.vehicle_viewport, this.vehicle_hudmodel, info.tag_view);
	}

	setsize(this, info.m_mins, info.m_maxs);

	info.vr_setup(info, this);

	if(!nodrop)
	{
		setorigin(this, this.origin);
		tracebox(this.origin + '0 0 100', info.m_mins, info.m_maxs, this.origin - '0 0 10000', MOVE_WORLDONLY, this);
		setorigin(this, trace_endpos);
	}

	this.pos1 = this.origin;
	this.pos2 = this.angles;
	this.tur_head.team = this.team;

	if(this.active == ACTIVE_NOT)
		this.nextthink = 0; // wait until activated
	else if(autocvar_g_vehicles_delayspawn)
		this.nextthink = time + this.respawntime + (random() * autocvar_g_vehicles_delayspawn_jitter);
	else
		this.nextthink = time + game_starttime;

	if(MUTATOR_CALLHOOK(VehicleInit, this))
		return false;

	return true;
}
