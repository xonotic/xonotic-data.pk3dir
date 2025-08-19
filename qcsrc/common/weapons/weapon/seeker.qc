#include "seeker.qh"

#ifdef SVQC

// ============================
// Begin: Missile functions, these are general functions to be manipulated by other code
// ============================
void W_Seeker_Missile_Explode(entity this, entity directhitentity)
{
	this.event_damage = func_null;
	RadiusDamage(this, this.realowner, WEP_CVAR(WEP_SEEKER, missile_damage), WEP_CVAR(WEP_SEEKER, missile_edgedamage), WEP_CVAR(WEP_SEEKER, missile_radius), NULL, NULL, WEP_CVAR(WEP_SEEKER, missile_force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	delete(this);
}

void W_Seeker_Missile_Explode_think(entity this)
{
	W_Seeker_Missile_Explode(this, NULL);
}

void W_Seeker_Missile_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);

	W_Seeker_Missile_Explode(this, toucher);
}

void W_Seeker_Missile_Think(entity this)
{
	entity e;
	vector desireddir, olddir, newdir, eorg;
	float turnrate;
	float dist;
	float spd;

	if(time > this.cnt)
	{
		this.projectiledeathtype |= HITTYPE_SPLASH;
		W_Seeker_Missile_Explode(this, NULL);
	}

	spd = vlen(this.velocity);
	spd = bound(
		spd - WEP_CVAR(WEP_SEEKER, missile_decel) * frametime,
		WEP_CVAR(WEP_SEEKER, missile_speed_max),
		spd + WEP_CVAR(WEP_SEEKER, missile_accel) * frametime
	);

	if(this.enemy != NULL)
		if(this.enemy.takedamage != DAMAGE_AIM || IS_DEAD(this.enemy))
			this.enemy = NULL;

	if(this.enemy != NULL)
	{
		e = this.enemy;
		eorg = 0.5 * (e.absmin + e.absmax);
		turnrate = WEP_CVAR(WEP_SEEKER, missile_turnrate); // how fast to turn
		desireddir = normalize(eorg - this.origin);
		olddir = normalize(this.velocity); // get my current direction
		dist = vlen(eorg - this.origin);

		// Do evasive maneuvers for world objects? ( this should be a cpu hog. :P )
		if(WEP_CVAR(WEP_SEEKER, missile_smart) && (dist > WEP_CVAR(WEP_SEEKER, missile_smart_mindist)))
		{
			// Is it a better idea (shorter distance) to trace to the target itself?
			if( vdist(this.origin + olddir * this.wait, <, dist))
				traceline(this.origin, this.origin + olddir * this.wait, false, this);
			else
				traceline(this.origin, eorg, false, this);

			// Setup adaptive tracelength
			this.wait = bound(WEP_CVAR(WEP_SEEKER, missile_smart_trace_min), vlen(this.origin - trace_endpos), this.wait = WEP_CVAR(WEP_SEEKER, missile_smart_trace_max));

			// Calc how important it is that we turn and add this to the desierd (enemy) dir.
			desireddir  = normalize(((trace_plane_normal * (1 - trace_fraction)) + (desireddir * trace_fraction)) * 0.5);
		}

		newdir = normalize(olddir + desireddir * turnrate); // take the average of the 2 directions; not the best method but simple & easy
		this.velocity = newdir * spd; // make me fly in the new direction at my flight speed
	}
	else
		dist = 0;

	// Proxy
	if(WEP_CVAR(WEP_SEEKER, missile_proxy))
	{
		if(dist <= WEP_CVAR(WEP_SEEKER, missile_proxy_maxrange))
		{
			if(this.cvar_cl_autoswitch == 0)
			{
				this.cvar_cl_autoswitch = time + WEP_CVAR(WEP_SEEKER, missile_proxy_delay);
			}
			else
			{
				if(this.cvar_cl_autoswitch <= time)
				{
					W_Seeker_Missile_Explode(this, NULL);
					this.cvar_cl_autoswitch = 0;
				}
			}
		}
		else
		{
			if(this.cvar_cl_autoswitch != 0)
				this.cvar_cl_autoswitch = 0;
		}
	}
	///////////////

	if(IS_DEAD(this.enemy))
	{
		this.enemy = NULL;
		this.cnt = time + 1 + (random() * 4);
		this.nextthink = this.cnt;
		return;
	}

	//this.angles = vectoangles(this.velocity); // turn model in the new flight direction
	this.nextthink = time;// + 0.05; // csqc projectiles
	UpdateCSQCProjectile(this);
}



void W_Seeker_Missile_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	if(this.realowner == attacker)
		TakeResource(this, RES_HEALTH, (damage * 0.25));
	else
		TakeResource(this, RES_HEALTH, damage);

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, W_Seeker_Missile_Explode_think);
}

/*
void W_Seeker_Missile_Animate(entity this)
{
	this.frame = this.frame +1;
	this.nextthink = time + 0.05;

	if(this.enemy != NULL)
		if(this.enemy.takedamage != DAMAGE_AIM || IS_DEAD(this.enemy))
			this.enemy = NULL;

	if(this.frame == 5)
	{
		this.think = W_Seeker_Missile_Think;
		this.nextthink = time;// + cvar("g_balance_seeker_missile_activate_delay"); // cant dealy with csqc projectiles

		if(autocvar_g_balance_seeker_missile_proxy)
			this.move_movetype = MOVETYPE_BOUNCEMISSILE;
		else
			this.move_movetype = MOVETYPE_FLYMISSILE;
	}

	UpdateCSQCProjectile(this);
}
*/

void W_Seeker_Fire_Missile(Weapon thiswep, entity actor, .entity weaponentity, vector f_diff, entity m_target)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_SEEKER, missile_ammo), weaponentity);

	makevectors(actor.v_angle);
	W_SetupShot_ProjectileSize(actor, weaponentity, '-4 -4 -4', '4 4 4', false, 2, SND_SEEKER_FIRE, CH_WEAPON_A, 0, ((m_target != NULL) ? thiswep.m_id | HITTYPE_SECONDARY : thiswep.m_id));
	w_shotorg += f_diff;
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	//actor.detornator = false;

	entity missile = new(seeker_missile);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR(WEP_SEEKER, missile_damage);

	setthink(missile, W_Seeker_Missile_Think);
	settouch(missile, W_Seeker_Missile_Touch);
	missile.event_damage = W_Seeker_Missile_Damage;
	missile.nextthink = time; // + 0.2; // + cvar("g_balance_seeker_missile_activate_delay");
	missile.cnt = time + WEP_CVAR(WEP_SEEKER, missile_lifetime);
	missile.enemy = m_target;
	missile.solid = SOLID_BBOX;
	missile.scale = 2;
	missile.takedamage = DAMAGE_YES;
	missile.weaponentity_fld = weaponentity;
	SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR(WEP_SEEKER, missile_health));
	missile.damageforcescale = WEP_CVAR(WEP_SEEKER, missile_damageforcescale);
	missile.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, missile);
	//missile.think = W_Seeker_Missile_Animate; // csqc projectiles.

	if(missile.enemy != NULL)
		missile.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
	else
		missile.projectiledeathtype = thiswep.m_id;


	setorigin(missile, w_shotorg);
	setsize(missile, '-4 -4 -4', '4 4 4');
	set_movetype(missile, MOVETYPE_FLYMISSILE);
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.missile_flags = MIF_SPLASH | MIF_GUIDED_TAG;

	W_SetupProjVelocity_UP_PRE(missile, WEP_SEEKER, missile_);

	missile.angles = vectoangles(missile.velocity);

	CSQCProjectile(missile, false, PROJECTILE_SEEKER, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

// ============================
// Begin: FLAC, close range attack meant for defeating rockets which are coming at you.
// ============================
void W_Seeker_Flac_Explode(entity this, entity directhitentity)
{
	this.event_damage = func_null;

	RadiusDamage(this, this.realowner, WEP_CVAR(WEP_SEEKER, flac_damage), WEP_CVAR(WEP_SEEKER, flac_edgedamage), WEP_CVAR(WEP_SEEKER, flac_radius), NULL, NULL, WEP_CVAR(WEP_SEEKER, flac_force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	delete(this);
}

void W_Seeker_Flac_Touch(entity this, entity toucher)
{
	W_Seeker_Flac_Explode(this, toucher);
}

void W_Seeker_Flac_Explode_use(entity this, entity actor, entity trigger)
{
	W_Seeker_Flac_Explode(this, trigger);
}

void W_Seeker_Fire_Flac(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity missile;
	vector f_diff;
	float c;

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_SEEKER, flac_ammo), weaponentity);

	c = actor.(weaponentity).bulletcounter % 4;
	switch(c)
	{
		case 0:
			f_diff = '-1.25 -3.75 0';
			break;
		case 1:
			f_diff = '+1.25 -3.75 0';
			break;
		case 2:
			f_diff = '-1.25 +3.75 0';
			break;
		case 3:
		default:
			f_diff = '+1.25 +3.75 0';
			break;
	}
	W_SetupShot_ProjectileSize(actor, weaponentity, '-2 -2 -2', '2 2 2', false, 2, SND_SEEKER_FLAC_FIRE, CH_WEAPON_A, WEP_CVAR(WEP_SEEKER, flac_damage), thiswep.m_id | HITTYPE_SECONDARY);
	w_shotorg += f_diff;

	// uses hagar effects!
	W_MuzzleFlash(WEP_HAGAR, actor, weaponentity, w_shotorg, w_shotdir);

	missile = new(missile);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR(WEP_SEEKER, flac_damage);
	settouch(missile, W_Seeker_Flac_Touch);
	missile.use = W_Seeker_Flac_Explode_use;
	setthink(missile, adaptor_think2use_hittype_splash);
	missile.nextthink = time + WEP_CVAR(WEP_SEEKER, flac_lifetime) + WEP_CVAR(WEP_SEEKER, flac_lifetime_rand);
	missile.solid = SOLID_BBOX;
	set_movetype(missile, MOVETYPE_FLY);
	missile.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
	missile.weaponentity_fld = weaponentity;
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	missile.missile_flags = MIF_SPLASH;

	// csqc projectiles
	//missile.angles = vectoangles(missile.velocity);
	//missile.scale = 0.4; // BUG: the model is too big

	setorigin(missile, w_shotorg);
	setsize(missile, '-2 -2 -2', '2 2 2');

	W_SetupProjVelocity_UP_PRE(missile, WEP_SEEKER, flac_);
	CSQCProjectile(missile, true, PROJECTILE_FLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

// ============================
// Begin: Tag and rocket controllers
// ============================
entity W_Seeker_Tagged_Info(entity isowner, .entity weaponentity, entity istarget)
{
	IL_EACH(g_seeker_trackers, it.classname == "tag_tracker" && it.realowner == isowner,
	{
		if(it.tag_target == istarget && it.weaponentity_fld == weaponentity)
			return it;
	});

	return NULL;
}

void W_Seeker_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	entity closest_target = NULL;

	IL_EACH(g_seeker_trackers, it.classname == "tag_tracker" && it.realowner == actor,
	{
		if(closest_target)
		{
			if(vlen2(actor.origin - it.tag_target.origin) < vlen2(actor.origin - closest_target.origin))
				closest_target = it.tag_target;
		}
		else
			closest_target = it.tag_target;
	});

	if(closest_target)
	{
		traceline(actor.origin + actor.view_ofs, closest_target.origin, MOVE_NOMONSTERS, actor);
		if(!closest_target || (trace_fraction < 1 && trace_ent != closest_target))
			closest_target = NULL;
	}

	W_Seeker_Fire_Missile(thiswep, actor, weaponentity, '0 0 0', closest_target);
}

void W_Seeker_Vollycontroller_Think(entity this) // TODO: Merge this with W_Seeker_Attack
{
	this.cnt = this.cnt - 1;

	Weapon thiswep = WEP_SEEKER;
	.entity weaponentity = this.weaponentity_fld;
	if((!(this.realowner.items & IT_UNLIMITED_AMMO) && GetResource(this.realowner, thiswep.ammo_type) < WEP_CVAR(WEP_SEEKER, missile_ammo)) || (this.cnt <= -1) || (IS_DEAD(this.realowner)) || (this.realowner.(weaponentity).m_switchweapon != thiswep))
	{
		delete(this);
		return;
	}

	this.nextthink = time + WEP_CVAR(WEP_SEEKER, missile_delay) * W_WeaponRateFactor(this.realowner);

	entity own = this.realowner;

	entity oldenemy = own.enemy;
	own.enemy = this.enemy;

	switch(own.cnt % 4)
	{
		case 0:
			W_Seeker_Fire_Missile(thiswep, own, weaponentity, '-1.25 -3.75 0', own.enemy); // TODO
			break;
		case 1:
			W_Seeker_Fire_Missile(thiswep, own, weaponentity, '+1.25 -3.75 0', own.enemy); // TODO
			break;
		case 2:
			W_Seeker_Fire_Missile(thiswep, own, weaponentity, '-1.25 +3.75 0', own.enemy); // TODO
			break;
		case 3:
		default:
			W_Seeker_Fire_Missile(thiswep, own, weaponentity, '+1.25 +3.75 0', own.enemy); // TODO
			break;
	}

	own.enemy = oldenemy;
}

void W_Seeker_Tracker_Think(entity this)
{
	.entity weaponentity = this.weaponentity_fld;
	// commit suicide if: You die OR target dies OR you switch away from the seeker OR commit suicide if lifetime is up
	if((IS_DEAD(this.realowner)) || (IS_DEAD(this.tag_target)) || (this.realowner.(weaponentity).m_switchweapon != WEP_SEEKER)
	|| (time > this.tag_time + WEP_CVAR(WEP_SEEKER, tag_tracker_lifetime)))
	{
		if(this)
		{
			WaypointSprite_Kill(this.tag_target.wps_tag_tracker);
			delete(this);
		}
		return;
	}

	// Update the think method information
	this.nextthink = time;
}

// ============================
// Begin: Tag projectile
// ============================
void W_Seeker_Tag_Explode(entity this)
{
	//if(other==this.realowner)
	//	return;
	Damage_DamageInfo(this.origin, 0, 0, 0, this.velocity, WEP_SEEKER.m_id | HITTYPE_BOUNCE, 0, this);

	delete(this);
}

void W_Seeker_Tag_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;
	TakeResource(this, RES_HEALTH, damage);
	if(GetResource(this, RES_HEALTH) <= 0)
		W_Seeker_Tag_Explode(this);
}

void W_Seeker_Tag_Touch(entity this, entity toucher)
{
	vector dir;
	vector org2;
	entity e;

	PROJECTILE_TOUCH(this, toucher);

	dir     = normalize(this.realowner.origin - this.origin);
	org2    = findbetterlocation(this.origin, 8);

	te_knightspike(org2);

	this.event_damage = func_null;
	Damage_DamageInfo(this.origin, 0, 0, 0, this.velocity, WEP_SEEKER.m_id | HITTYPE_BOUNCE | HITTYPE_SECONDARY, toucher.species, this);

	if(toucher.takedamage == DAMAGE_AIM && !IS_DEAD(toucher))
	{
		// check to see if this person is already tagged by me
		.entity weaponentity = this.weaponentity_fld;
		entity tag = W_Seeker_Tagged_Info(this.realowner, weaponentity, toucher);

		if(tag != NULL)
		{
			if(toucher.wps_tag_tracker && (WEP_CVAR(WEP_SEEKER, type) == 1)) // don't attach another waypointsprite without killing the old one first
				WaypointSprite_Kill(toucher.wps_tag_tracker);

			tag.tag_time = time;
		}
		else
		{
			//sprint(this.realowner, strcat("You just tagged ^2", toucher.netname, "^7 with a tracking device!\n"));
			e = new(tag_tracker);
			e.weaponentity_fld = this.weaponentity_fld;
			e.cnt = WEP_CVAR(WEP_SEEKER, missile_count);
			e.owner = this.owner;
			e.realowner = this.realowner;
			IL_PUSH(g_seeker_trackers, e);

			if(WEP_CVAR(WEP_SEEKER, type) == 1)
			{
				e.tag_target = toucher;
				e.tag_time = time;
				setthink(e, W_Seeker_Tracker_Think);
			}
			else
			{
				e.enemy = toucher;
				setthink(e, W_Seeker_Vollycontroller_Think);
			}

			e.nextthink = time;
		}

		if(WEP_CVAR(WEP_SEEKER, type) == 1)
		{
			WaypointSprite_Spawn(WP_Seeker, WEP_CVAR(WEP_SEEKER, tag_tracker_lifetime), 0, toucher, '0 0 64', this.realowner, 0, toucher, wps_tag_tracker, true, RADARICON_TAGGED);
			WaypointSprite_UpdateRule(toucher.wps_tag_tracker, 0, SPRITERULE_DEFAULT);
		}
	}

	delete(this);
	return;
}

void W_Seeker_Fire_Tag(Weapon thiswep, entity actor, .entity weaponentity)
{
	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_SEEKER, tag_ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-2 -2 -2', '2 2 2', false, 2, SND_TAG_FIRE, CH_WEAPON_A, WEP_CVAR(WEP_SEEKER, missile_damage) * WEP_CVAR(WEP_SEEKER, missile_count), thiswep.m_id | HITTYPE_BOUNCE | HITTYPE_SECONDARY);

	entity missile = new(seeker_tag);
	missile.weaponentity_fld = weaponentity;
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	missile.bot_dodgerating = 50;
	settouch(missile, W_Seeker_Tag_Touch);
	setthink(missile, SUB_Remove);
	missile.nextthink = time + WEP_CVAR(WEP_SEEKER, tag_lifetime);
	set_movetype(missile, MOVETYPE_FLY);
	missile.solid = SOLID_BBOX;

	missile.takedamage = DAMAGE_YES;
	missile.event_damage = W_Seeker_Tag_Damage;
	SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR(WEP_SEEKER, tag_health));
	missile.damageforcescale = WEP_CVAR(WEP_SEEKER, tag_damageforcescale);

	setorigin(missile, w_shotorg);
	setsize(missile, '-2 -2 -2', '2 2 2');

	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);
	//missile.missile_flags = MIF_..?;

	set_movetype(missile, MOVETYPE_FLY);
	W_SetupProjVelocity_PRE(missile, WEP_SEEKER, tag_);
	missile.angles = vectoangles(missile.velocity);

	CSQCProjectile(missile, true, PROJECTILE_TAG, false); // has sound

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);
}

// ============================
// Begin: Genereal weapon functions
// ============================

METHOD(Seeker, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(WEP_CVAR(WEP_SEEKER, type) == 1)
	{
		if(W_Seeker_Tagged_Info(actor, weaponentity, actor.enemy) != NULL)
			PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR(WEP_SEEKER, missile_speed_max), 0, WEP_CVAR(WEP_SEEKER, missile_lifetime), false, false);
		else
			PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, WEP_CVAR(WEP_SEEKER, tag_speed), 0, WEP_CVAR(WEP_SEEKER, tag_lifetime), false, false);
	}
	else
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR(WEP_SEEKER, tag_speed), 0, WEP_CVAR(WEP_SEEKER, tag_lifetime), false, true);
}

METHOD(Seeker, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(autocvar_g_balance_seeker_reload_ammo && actor.(weaponentity).clip_load < min(WEP_CVAR(WEP_SEEKER, missile_ammo), WEP_CVAR(WEP_SEEKER, tag_ammo))) { // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
	} else if(fire & 1)
	{
		if(WEP_CVAR(WEP_SEEKER, type) == 1)
		{
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_SEEKER, missile_refire)))
			{
				W_Seeker_Attack(thiswep, actor, weaponentity);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(WEP_SEEKER, missile_animtime), w_ready);
			}
		}
		else
		{
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_SEEKER, tag_refire)))
			{
				W_Seeker_Fire_Tag(thiswep, actor, weaponentity);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(WEP_SEEKER, tag_animtime), w_ready);
			}
		}
	}

	else if(fire & 2)
	{
		if(WEP_CVAR(WEP_SEEKER, type) == 1)
		{
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_SEEKER, tag_refire)))
			{
				W_Seeker_Fire_Tag(thiswep, actor, weaponentity);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(WEP_SEEKER, tag_animtime), w_ready);
			}
		}
		else
		{
			if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_SEEKER, flac_refire)))
			{
				W_Seeker_Fire_Flac(thiswep, actor, weaponentity);
				weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(WEP_SEEKER, flac_animtime), w_ready);
			}
		}
	}
}

METHOD(Seeker, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	if(WEP_CVAR(WEP_SEEKER, type) == 1)
	{
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_SEEKER, missile_ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_SEEKER, missile_ammo);
	}
	else
	{
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_SEEKER, tag_ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_SEEKER, tag_ammo);
	}
	return ammo_amount;
}

METHOD(Seeker, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	if(WEP_CVAR(WEP_SEEKER, type) == 1)
	{
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_SEEKER, tag_ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_SEEKER, tag_ammo);
	}
	else
	{
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_SEEKER, flac_ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_SEEKER, flac_ammo);
	}
	return ammo_amount;
}

METHOD(Seeker, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(WEP_CVAR(WEP_SEEKER, missile_ammo), WEP_CVAR(WEP_SEEKER, tag_ammo)), SND_RELOAD);
}

METHOD(Seeker, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_SEEKER_SUICIDE;
}

METHOD(Seeker, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_SEEKER_MURDER_TAG;
	else
		return WEAPON_SEEKER_MURDER_SPRAY;
}

#endif
#ifdef CSQC

METHOD(Seeker, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	if(w_deathtype & HITTYPE_BOUNCE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(!w_issilent)
				sound(actor, CH_SHOTS, SND_TAG_IMPACT, 1, ATTEN_NORM);
		}
		else
		{
			pointparticles(EFFECT_HAGAR_EXPLODE, org2, '0 0 0', 1);
			if(!w_issilent)
				sound(actor, CH_SHOTS, SND_TAGEXP_RANDOM(w_random), 1, ATTEN_NORM);
		}
	}
	else
	{
		pointparticles(EFFECT_HAGAR_EXPLODE, org2, '0 0 0', 1);
		if(!w_issilent)
			sound(actor, CH_SHOTS, SND_SEEKEREXP_RANDOM(w_random), 1, ATTEN_NORM);
	}
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>

METHOD(Seeker, describe, string(Seeker this))
{
	TC(Seeker, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s is a unique weapon, firing a \"tag\" which then launches a few homing missiles if it collides with a player. "
	      "The homing isn't perfect, so sometimes the missiles can hit an object or a corner."), COLORED_NAME(this));
	PAR(_("The secondary fire launches a rapid barrage of scattered explosives that travel only a short distance."));
	PAR(_("It consumes %s ammo, even when the tag doesn't land."), COLORED_NAME(ITEM_Rockets));
	PAR(_("The %s primary fire deals quite a lot of damage when a tag lands, although it requires skill to aim effectively. "
	      "The secondary fire is only useful in close range combat, and sometimes the explosives can damage yourself too."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_primaryMultishot(this.netname, "missile", "flac", "missile_count", "tag_refire"));
	return PAGE_TEXT;
}

#endif
