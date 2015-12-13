#ifndef IMPLEMENTATION
CLASS(Seeker, Weapon)
/* ammotype  */ ATTRIB(Seeker, ammo_field, .int, ammo_rockets)
/* impulse   */ ATTRIB(Seeker, impulse, int, 8)
/* flags     */ ATTRIB(Seeker, spawnflags, int, WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Seeker, bot_pickupbasevalue, float, BOT_PICKUP_RATING_HIGH);
/* color     */ ATTRIB(Seeker, wpcolor, vector, '0.5 1 0');
/* modelname */ ATTRIB(Seeker, mdl, string, "seeker");
#ifndef MENUQC
/* model     */ ATTRIB(Seeker, m_model, Model, MDL_SEEKER_ITEM);
#endif
/* crosshair */ ATTRIB(Seeker, w_crosshair, string, "gfx/crosshairseeker");
/* crosshair */ ATTRIB(Seeker, w_crosshair_size, float, 0.8);
/* wepimg    */ ATTRIB(Seeker, model2, string, "weaponseeker");
/* refname   */ ATTRIB(Seeker, netname, string, "seeker");
/* wepname   */ ATTRIB(Seeker, m_name, string, _("T.A.G. Seeker"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
    	P(class, prefix, flac_ammo, float, NONE) \
    	P(class, prefix, flac_animtime, float, NONE) \
    	P(class, prefix, flac_damage, float, NONE) \
    	P(class, prefix, flac_edgedamage, float, NONE) \
    	P(class, prefix, flac_force, float, NONE) \
    	P(class, prefix, flac_lifetime, float, NONE) \
    	P(class, prefix, flac_lifetime_rand, float, NONE) \
    	P(class, prefix, flac_radius, float, NONE) \
    	P(class, prefix, flac_refire, float, NONE) \
    	P(class, prefix, flac_speed, float, NONE) \
    	P(class, prefix, flac_speed_up, float, NONE) \
    	P(class, prefix, flac_speed_z, float, NONE) \
    	P(class, prefix, flac_spread, float, NONE) \
    	P(class, prefix, missile_accel, float, NONE) \
    	P(class, prefix, missile_ammo, float, NONE) \
    	P(class, prefix, missile_animtime, float, NONE) \
    	P(class, prefix, missile_count, float, NONE) \
    	P(class, prefix, missile_damageforcescale, float, NONE) \
    	P(class, prefix, missile_damage, float, NONE) \
    	P(class, prefix, missile_decel, float, NONE) \
    	P(class, prefix, missile_delay, float, NONE) \
    	P(class, prefix, missile_edgedamage, float, NONE) \
    	P(class, prefix, missile_force, float, NONE) \
    	P(class, prefix, missile_health, float, NONE) \
    	P(class, prefix, missile_lifetime, float, NONE) \
    	P(class, prefix, missile_proxy, float, NONE) \
    	P(class, prefix, missile_proxy_delay, float, NONE) \
    	P(class, prefix, missile_proxy_maxrange, float, NONE) \
    	P(class, prefix, missile_radius, float, NONE) \
    	P(class, prefix, missile_refire, float, NONE) \
    	P(class, prefix, missile_smart, float, NONE) \
    	P(class, prefix, missile_smart_mindist, float, NONE) \
    	P(class, prefix, missile_smart_trace_max, float, NONE) \
    	P(class, prefix, missile_smart_trace_min, float, NONE) \
    	P(class, prefix, missile_speed, float, NONE) \
    	P(class, prefix, missile_speed_max, float, NONE) \
    	P(class, prefix, missile_speed_up, float, NONE) \
    	P(class, prefix, missile_speed_z, float, NONE) \
    	P(class, prefix, missile_spread, float, NONE) \
    	P(class, prefix, missile_turnrate, float, NONE) \
    	P(class, prefix, reload_ammo, float, NONE) \
		P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
    	P(class, prefix, tag_ammo, float, NONE) \
    	P(class, prefix, tag_animtime, float, NONE) \
    	P(class, prefix, tag_damageforcescale, float, NONE) \
    	P(class, prefix, tag_health, float, NONE) \
    	P(class, prefix, tag_lifetime, float, NONE) \
    	P(class, prefix, tag_refire, float, NONE) \
    	P(class, prefix, tag_speed, float, NONE) \
    	P(class, prefix, tag_spread, float, NONE) \
    	P(class, prefix, tag_tracker_lifetime, float, NONE) \
		P(class, prefix, type, float, NONE) \
		P(class, prefix, weaponreplace, string, NONE) \
		P(class, prefix, weaponstartoverride, float, NONE) \
		P(class, prefix, weaponstart, float, NONE) \
		P(class, prefix, weaponthrowable, float, NONE) \
	END()
	W_PROPS(X, Seeker, seeker)
#undef X
ENDCLASS(Seeker)
REGISTER_WEAPON(SEEKER, seeker, NEW(Seeker));


#ifdef SVQC
.entity tag_target, wps_tag_tracker;
.float tag_time;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_seeker) { weapon_defaultspawnfunc(this, WEP_SEEKER); }

// ============================
// Begin: Missile functions, these are general functions to be manipulated by other code
// ============================
void W_Seeker_Missile_Explode()
{SELFPARAM();
	self.event_damage = func_null;
	RadiusDamage(self, self.realowner, WEP_CVAR(seeker, missile_damage), WEP_CVAR(seeker, missile_edgedamage), WEP_CVAR(seeker, missile_radius), world, world, WEP_CVAR(seeker, missile_force), self.projectiledeathtype, other);

	remove(self);
}

void W_Seeker_Missile_Touch()
{
	PROJECTILE_TOUCH;

	W_Seeker_Missile_Explode();
}

void W_Seeker_Missile_Think()
{SELFPARAM();
	entity e;
	vector desireddir, olddir, newdir, eorg;
	float turnrate;
	float dist;
	float spd;

	if(time > self.cnt)
	{
		self.projectiledeathtype |= HITTYPE_SPLASH;
		W_Seeker_Missile_Explode();
	}

	spd = vlen(self.velocity);
	spd = bound(
		spd - WEP_CVAR(seeker, missile_decel) * frametime,
		WEP_CVAR(seeker, missile_speed_max),
		spd + WEP_CVAR(seeker, missile_accel) * frametime
	);

	if(self.enemy != world)
		if(self.enemy.takedamage != DAMAGE_AIM || self.enemy.deadflag != DEAD_NO)
			self.enemy = world;

	if(self.enemy != world)
	{
		e               = self.enemy;
		eorg            = 0.5 * (e.absmin + e.absmax);
		turnrate        = WEP_CVAR(seeker, missile_turnrate); // how fast to turn
		desireddir      = normalize(eorg - self.origin);
		olddir          = normalize(self.velocity); // get my current direction
		dist            = vlen(eorg - self.origin);

		// Do evasive maneuvers for world objects? ( this should be a cpu hog. :P )
		if(WEP_CVAR(seeker, missile_smart) && (dist > WEP_CVAR(seeker, missile_smart_mindist)))
		{
			// Is it a better idea (shorter distance) to trace to the target itself?
			if( vlen(self.origin + olddir * self.wait) < dist)
				traceline(self.origin, self.origin + olddir * self.wait, false, self);
			else
				traceline(self.origin, eorg, false, self);

			// Setup adaptive tracelength
			self.wait = bound(WEP_CVAR(seeker, missile_smart_trace_min), vlen(self.origin - trace_endpos), self.wait = WEP_CVAR(seeker, missile_smart_trace_max));

			// Calc how important it is that we turn and add this to the desierd (enemy) dir.
			desireddir  = normalize(((trace_plane_normal * (1 - trace_fraction)) + (desireddir * trace_fraction)) * 0.5);
		}

		newdir = normalize(olddir + desireddir * turnrate); // take the average of the 2 directions; not the best method but simple & easy
		self.velocity = newdir * spd; // make me fly in the new direction at my flight speed
	}
	else
		dist = 0;

	// Proxy
	if(WEP_CVAR(seeker, missile_proxy))
	{
		if(dist <= WEP_CVAR(seeker, missile_proxy_maxrange))
		{
			if(self.autoswitch == 0)
			{
				self.autoswitch = time + WEP_CVAR(seeker, missile_proxy_delay);
			}
			else
			{
				if(self.autoswitch <= time)
				{
					W_Seeker_Missile_Explode();
					self.autoswitch = 0;
				}
			}
		}
		else
		{
			if(self.autoswitch != 0)
				self.autoswitch = 0;
		}
	}
	///////////////

	if(self.enemy.deadflag != DEAD_NO)
	{
		self.enemy = world;
		self.cnt = time + 1 + (random() * 4);
		self.nextthink = self.cnt;
		return;
	}

	//self.angles = vectoangles(self.velocity);			// turn model in the new flight direction
	self.nextthink = time;// + 0.05; // csqc projectiles
	UpdateCSQCProjectile(self);
}



void W_Seeker_Missile_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.health <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	if(self.realowner == attacker)
		self.health = self.health - (damage * 0.25);
	else
		self.health = self.health - damage;

	if(self.health <= 0)
		W_PrepareExplosionByDamage(attacker, W_Seeker_Missile_Explode);
}

/*
void W_Seeker_Missile_Animate()
{
	self.frame = self.frame +1;
	self.nextthink = time + 0.05;

	if(self.enemy != world)
		if(self.enemy.takedamage != DAMAGE_AIM || self.enemy.deadflag != DEAD_NO)
			self.enemy = world;

	if(self.frame == 5)
	{
		self.think           = W_Seeker_Missile_Think;
		self.nextthink       = time;// + cvar("g_balance_seeker_missile_activate_delay"); // cant dealy with csqc projectiles

		if(autocvar_g_balance_seeker_missile_proxy)
			self.movetype    = MOVETYPE_BOUNCEMISSILE;
		else
			self.movetype    = MOVETYPE_FLYMISSILE;
	}

	UpdateCSQCProjectile(self);
}
*/

void W_Seeker_Fire_Missile(Weapon thiswep, vector f_diff, entity m_target)
{SELFPARAM();
	entity missile;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR(seeker, missile_ammo));

	makevectors(self.v_angle);
	W_SetupShot_ProjectileSize(self, '-2 -2 -2', '2 2 2', false, 2, SND(SEEKER_FIRE), CH_WEAPON_A, 0);
	w_shotorg += f_diff;
	Send_Effect(EFFECT_SEEKER_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	//self.detornator         = false;

	missile                 = new(seeker_missile);
	missile.owner           = missile.realowner = self;
	missile.bot_dodge       = true;
	missile.bot_dodgerating = WEP_CVAR(seeker, missile_damage);

	missile.think           = W_Seeker_Missile_Think;
	missile.touch           = W_Seeker_Missile_Touch;
	missile.event_damage    = W_Seeker_Missile_Damage;
	missile.nextthink       = time;// + 0.2;// + cvar("g_balance_seeker_missile_activate_delay");
	missile.cnt             = time + WEP_CVAR(seeker, missile_lifetime);
	missile.enemy           = m_target;
	missile.solid           = SOLID_BBOX;
	missile.scale           = 2;
	missile.takedamage      = DAMAGE_YES;
	missile.health          = WEP_CVAR(seeker, missile_health);
	missile.damageforcescale = WEP_CVAR(seeker, missile_damageforcescale);
	missile.damagedbycontents = true;
	//missile.think           = W_Seeker_Missile_Animate; // csqc projectiles.

	if(missile.enemy != world)
		missile.projectiledeathtype = WEP_SEEKER.m_id | HITTYPE_SECONDARY;
	else
		missile.projectiledeathtype = WEP_SEEKER.m_id;


	setorigin(missile, w_shotorg);
	setsize(missile, '-4 -4 -4', '4 4 4');
	missile.movetype    = MOVETYPE_FLYMISSILE;
	missile.flags       = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH | MIF_GUIDED_TAG;

	W_SetupProjVelocity_UP_PRE(missile, seeker, missile_);

	missile.angles = vectoangles(missile.velocity);

	CSQCProjectile(missile, false, PROJECTILE_SEEKER, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

// ============================
// Begin: FLAC, close range attack meant for defeating rockets which are coming at you.
// ============================
void W_Seeker_Flac_Explode()
{SELFPARAM();
	self.event_damage = func_null;

	RadiusDamage(self, self.realowner, WEP_CVAR(seeker, flac_damage), WEP_CVAR(seeker, flac_edgedamage), WEP_CVAR(seeker, flac_radius), world, world, WEP_CVAR(seeker, flac_force), self.projectiledeathtype, other);

	remove(self);
}

void W_Seeker_Flac_Touch()
{
	PROJECTILE_TOUCH;

	W_Seeker_Flac_Explode();
}

void W_Seeker_Fire_Flac(Weapon thiswep)
{SELFPARAM();
	entity missile;
	vector f_diff;
	float c;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR(seeker, flac_ammo));

	c = self.bulletcounter % 4;
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
	W_SetupShot_ProjectileSize(self, '-2 -2 -2', '2 2 2', false, 2, SND(FLAC_FIRE), CH_WEAPON_A, WEP_CVAR(seeker, flac_damage));
	w_shotorg += f_diff;

	Send_Effect(EFFECT_HAGAR_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile 				= new(missile);
	missile.owner 			= missile.realowner = self;
	missile.bot_dodge 		= true;
	missile.bot_dodgerating = WEP_CVAR(seeker, flac_damage);
	missile.touch 			= W_Seeker_Flac_Explode;
	missile.use 			= W_Seeker_Flac_Explode;
	missile.think 			= adaptor_think2use_hittype_splash;
	missile.nextthink 		= time + WEP_CVAR(seeker, flac_lifetime) + WEP_CVAR(seeker, flac_lifetime_rand);
	missile.solid 			= SOLID_BBOX;
	missile.movetype 		= MOVETYPE_FLY;
	missile.projectiledeathtype = WEP_SEEKER.m_id;
	missile.projectiledeathtype = WEP_SEEKER.m_id | HITTYPE_SECONDARY;
	missile.flags 				= FL_PROJECTILE;
	missile.missile_flags       = MIF_SPLASH;

	// csqc projectiles
	//missile.angles 				= vectoangles(missile.velocity);
	//missile.scale = 0.4; // BUG: the model is too big

	setorigin(missile, w_shotorg);
	setsize(missile, '-2 -2 -2', '2 2 2');

	W_SetupProjVelocity_UP_PRE(missile, seeker, flac_);
	CSQCProjectile(missile, true, PROJECTILE_FLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

// ============================
// Begin: Tag and rocket controllers
// ============================
entity W_Seeker_Tagged_Info(entity isowner, entity istarget)
{
	entity tag;
	for(tag = world; (tag = find(tag, classname, "tag_tracker")); )
		if((tag.realowner == isowner) && (tag.tag_target == istarget))
			return tag;

	return world;
}

void W_Seeker_Attack()
{SELFPARAM();
	entity tracker, closest_target;

	closest_target = world;
	for(tracker = world; (tracker = find(tracker, classname, "tag_tracker")); ) if (tracker.realowner == self)
	{
		if(closest_target)
		{
			if(vlen(self.origin - tracker.tag_target.origin) < vlen(self.origin - closest_target.origin))
				closest_target = tracker.tag_target;
		}
		else
			closest_target = tracker.tag_target;
	}

	traceline(self.origin + self.view_ofs, closest_target.origin, MOVE_NOMONSTERS, self);
	if((!closest_target) || ((trace_fraction < 1) && (trace_ent != closest_target)))
		closest_target = world;

	W_Seeker_Fire_Missile(WEP_SEEKER, '0 0 0', closest_target);
}

void W_Seeker_Vollycontroller_Think() // TODO: Merge this with W_Seeker_Attack
{SELFPARAM();
	float c;
	entity oldenemy;
	self.cnt = self.cnt - 1;

	Weapon thiswep = WEP_SEEKER;
	if((!(self.realowner.items & IT_UNLIMITED_AMMO) && self.realowner.(thiswep.ammo_field) < WEP_CVAR(seeker, missile_ammo)) || (self.cnt <= -1) || (self.realowner.deadflag != DEAD_NO) || (PS(self.realowner).m_switchweapon != WEP_SEEKER))
	{
		remove(self);
		return;
	}

	self.nextthink = time + WEP_CVAR(seeker, missile_delay) * W_WeaponRateFactor();

	setself(self.realowner);

	oldenemy = self.enemy;
	self.enemy = this.enemy;

	c = self.cnt % 4;
	switch(c)
	{
		case 0:
			W_Seeker_Fire_Missile(WEP_SEEKER, '-1.25 -3.75 0', self.enemy);
			break;
		case 1:
			W_Seeker_Fire_Missile(WEP_SEEKER, '+1.25 -3.75 0', self.enemy);
			break;
		case 2:
			W_Seeker_Fire_Missile(WEP_SEEKER, '-1.25 +3.75 0', self.enemy);
			break;
		case 3:
		default:
			W_Seeker_Fire_Missile(WEP_SEEKER, '+1.25 +3.75 0', self.enemy);
			break;
	}

	self.enemy = oldenemy;
	setself(this);
}

void W_Seeker_Tracker_Think()
{SELFPARAM();
	// commit suicide if: You die OR target dies OR you switch away from the seeker OR commit suicide if lifetime is up
	if((self.realowner.deadflag != DEAD_NO) || (self.tag_target.deadflag != DEAD_NO) || (PS(self.realowner).m_switchweapon != WEP_SEEKER)
	|| (time > self.tag_time + WEP_CVAR(seeker, tag_tracker_lifetime)))
	{
		if(self)
		{
			WaypointSprite_Kill(self.tag_target.wps_tag_tracker);
			remove(self);
		}
		return;
	}

	// Update the think method information
	self.nextthink = time;
}

// ============================
// Begin: Tag projectile
// ============================
void W_Seeker_Tag_Explode()
{SELFPARAM();
	//if(other==self.realowner)
	//    return;
	Damage_DamageInfo(self.origin, 0, 0, 0, self.velocity, WEP_SEEKER.m_id | HITTYPE_BOUNCE, other.species, self);

	remove(self);
}

void W_Seeker_Tag_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.health <= 0)
		return;
	self.health = self.health - damage;
	if(self.health <= 0)
		W_Seeker_Tag_Explode();
}

void W_Seeker_Tag_Touch()
{SELFPARAM();
	vector dir;
	vector org2;
	entity e;

	PROJECTILE_TOUCH;

	dir     = normalize(self.realowner.origin - self.origin);
	org2    = findbetterlocation(self.origin, 8);

	te_knightspike(org2);

	self.event_damage = func_null;
	Damage_DamageInfo(self.origin, 0, 0, 0, self.velocity, WEP_SEEKER.m_id | HITTYPE_BOUNCE | HITTYPE_SECONDARY, other.species, self);

	if(other.takedamage == DAMAGE_AIM && other.deadflag == DEAD_NO)
	{
		// check to see if this person is already tagged by me
		entity tag = W_Seeker_Tagged_Info(self.realowner, other);

		if(tag != world)
		{
			if(other.wps_tag_tracker && (WEP_CVAR(seeker, type) == 1)) // don't attach another waypointsprite without killing the old one first
				WaypointSprite_Kill(other.wps_tag_tracker);

			tag.tag_time = time;
		}
		else
		{
			//sprint(self.realowner, strcat("You just tagged ^2", other.netname, "^7 with a tracking device!\n"));
			e             = new(tag_tracker);
			e.cnt         = WEP_CVAR(seeker, missile_count);
			e.owner       = self.owner;
			e.realowner   = self.realowner;

			if(WEP_CVAR(seeker, type) == 1)
			{
				e.tag_target  = other;
				e.tag_time    = time;
				e.think       = W_Seeker_Tracker_Think;
			}
			else
			{
				e.enemy     = other;
				e.think     = W_Seeker_Vollycontroller_Think;
			}

			e.nextthink   = time;
		}

		if(WEP_CVAR(seeker, type) == 1)
		{
			WaypointSprite_Spawn(WP_Seeker, WEP_CVAR(seeker, tag_tracker_lifetime), 0, other, '0 0 64', self.realowner, 0, other, wps_tag_tracker, true, RADARICON_TAGGED);
			WaypointSprite_UpdateRule(other.wps_tag_tracker, 0, SPRITERULE_DEFAULT);
		}
	}

	remove(self);
	return;
}

void W_Seeker_Fire_Tag(Weapon thiswep)
{SELFPARAM();
	entity missile;
	W_DecreaseAmmo(thiswep, self, WEP_CVAR(seeker, tag_ammo));

	W_SetupShot_ProjectileSize(self, '-2 -2 -2', '2 2 2', false, 2, SND(TAG_FIRE), CH_WEAPON_A, WEP_CVAR(seeker, missile_damage) * WEP_CVAR(seeker, missile_count));

	missile                 = new(seeker_tag);
	missile.owner           = missile.realowner = self;
	missile.bot_dodge       = true;
	missile.bot_dodgerating = 50;
	missile.touch           = W_Seeker_Tag_Touch;
	missile.think           = SUB_Remove_self;
	missile.nextthink       = time + WEP_CVAR(seeker, tag_lifetime);
	missile.movetype        = MOVETYPE_FLY;
	missile.solid           = SOLID_BBOX;

	missile.takedamage       = DAMAGE_YES;
	missile.event_damage     = W_Seeker_Tag_Damage;
	missile.health           = WEP_CVAR(seeker, tag_health);
	missile.damageforcescale = WEP_CVAR(seeker, tag_damageforcescale);

	setorigin(missile, w_shotorg);
	setsize(missile, '-2 -2 -2', '2 2 2');

	missile.flags       = FL_PROJECTILE;
	//missile.missile_flags = MIF_..?;

	missile.movetype    = MOVETYPE_FLY;
	W_SetupProjVelocity_PRE(missile, seeker, tag_);
	missile.angles = vectoangles(missile.velocity);

	CSQCProjectile(missile, true, PROJECTILE_TAG, false); // has sound

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

// ============================
// Begin: Genereal weapon functions
// ============================

		METHOD(Seeker, wr_aim, void(entity thiswep))
		{
			if(WEP_CVAR(seeker, type) == 1)
				if(W_Seeker_Tagged_Info(self, self.enemy) != world)
					self.BUTTON_ATCK = bot_aim(WEP_CVAR(seeker, missile_speed_max), 0, WEP_CVAR(seeker, missile_lifetime), false);
				else
					self.BUTTON_ATCK2 = bot_aim(WEP_CVAR(seeker, tag_speed), 0, WEP_CVAR(seeker, tag_lifetime), false);
			else
				self.BUTTON_ATCK = bot_aim(WEP_CVAR(seeker, tag_speed), 0, WEP_CVAR(seeker, tag_lifetime), false);
		}
		METHOD(Seeker, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(autocvar_g_balance_seeker_reload_ammo && actor.clip_load < min(WEP_CVAR(seeker, missile_ammo), WEP_CVAR(seeker, tag_ammo))) { // forced reload
				thiswep.wr_reload(thiswep);
			} else if(fire & 1)
			{
				if(WEP_CVAR(seeker, type) == 1)
				{
					if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(seeker, missile_refire)))
					{
						W_Seeker_Attack();
						weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(seeker, missile_animtime), w_ready);
					}
				}
				else
				{
					if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(seeker, tag_refire)))
					{
						W_Seeker_Fire_Tag(thiswep);
						weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(seeker, tag_animtime), w_ready);
					}
				}
			}

			else if(fire & 2)
			{
				if(WEP_CVAR(seeker, type) == 1)
				{
					if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(seeker, tag_refire)))
					{
						W_Seeker_Fire_Tag(thiswep);
						weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(seeker, tag_animtime), w_ready);
					}
				}
				else
				{
					if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(seeker, flac_refire)))
					{
						W_Seeker_Fire_Flac(thiswep);
						weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(seeker, flac_animtime), w_ready);
					}
				}
			}
		}
		METHOD(Seeker, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount;
			if(WEP_CVAR(seeker, type) == 1)
			{
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(seeker, missile_ammo);
				ammo_amount += self.(weapon_load[WEP_SEEKER.m_id]) >= WEP_CVAR(seeker, missile_ammo);
			}
			else
			{
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(seeker, tag_ammo);
				ammo_amount += self.(weapon_load[WEP_SEEKER.m_id]) >= WEP_CVAR(seeker, tag_ammo);
			}
			return ammo_amount;
		}
		METHOD(Seeker, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount;
			if(WEP_CVAR(seeker, type) == 1)
			{
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(seeker, tag_ammo);
				ammo_amount += self.(weapon_load[WEP_SEEKER.m_id]) >= WEP_CVAR(seeker, tag_ammo);
			}
			else
			{
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(seeker, flac_ammo);
				ammo_amount += self.(weapon_load[WEP_SEEKER.m_id]) >= WEP_CVAR(seeker, flac_ammo);
			}
			return ammo_amount;
		}
		METHOD(Seeker, wr_reload, void(entity thiswep))
		{
			W_Reload(self, min(WEP_CVAR(seeker, missile_ammo), WEP_CVAR(seeker, tag_ammo)), SND(RELOAD));
		}
		METHOD(Seeker, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_SEEKER_SUICIDE;
		}
		METHOD(Seeker, wr_killmessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_SEEKER_MURDER_TAG;
			else
				return WEAPON_SEEKER_MURDER_SPRAY;
		}

#endif
#ifdef CSQC

		METHOD(Seeker, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				if(w_deathtype & HITTYPE_SECONDARY)
				{
					if(!w_issilent)
						sound(self, CH_SHOTS, SND_TAG_IMPACT, 1, ATTEN_NORM);
				}
				else
				{
					pointparticles(EFFECT_HAGAR_EXPLODE, org2, '0 0 0', 1);
					if(!w_issilent)
					{
						if(w_random<0.15)
							sound(self, CH_SHOTS, SND_TAGEXP1, 1, ATTEN_NORM);
						else if(w_random<0.7)
							sound(self, CH_SHOTS, SND_TAGEXP2, 1, ATTEN_NORM);
						else
							sound(self, CH_SHOTS, SND_TAGEXP3, 1, ATTEN_NORM);
					}
				}
			}
			else
			{
				pointparticles(EFFECT_HAGAR_EXPLODE, org2, '0 0 0', 1);
				if(!w_issilent)
				{
					if(w_random<0.15)
						sound(self, CH_SHOTS, SND_SEEKEREXP1, 1, ATTEN_NORM);
					else if(w_random<0.7)
						sound(self, CH_SHOTS, SND_SEEKEREXP2, 1, ATTEN_NORM);
					else
						sound(self, CH_SHOTS, SND_SEEKEREXP3, 1, ATTEN_NORM);
				}
			}
		}

#endif
#endif
