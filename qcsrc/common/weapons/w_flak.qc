#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id  */ FLAK,
/* function  */ W_Flak,
/* ammotype  */ ammo_shells,
/* impulse   */ 8,
/* flags     */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH,
/* rating    */ BOT_PICKUP_RATING_MID,
/* color     */ '1 1 0',
/* modelname */ "flak",
/* simplemdl */ "foobar",
/* crosshair */ "gfx/crosshairflak 0.8",
/* wepimg    */ "weaponflak",
/* refname   */ "flak",
/* wepname   */ _("Flak Cannon")
);

#define FLAK_SETTINGS(w_cvar,w_prop) FLAK_SETTINGS_LIST(w_cvar, w_prop, FLAK, flak)
#define FLAK_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, bouncefactor) \
	w_cvar(id, sn, BOTH, count) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, damage_bouncefactor) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, BOTH, gravity) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, BOTH, speed) \
	w_cvar(id, sn, BOTH, speed_up) \
	w_cvar(id, sn, BOTH, spread_side) \
	w_cvar(id, sn, BOTH, spread_up) \
	w_cvar(id, sn, BOTH, passthrough) \
	w_cvar(id, sn, BOTH, lifetime) \
	w_cvar(id, sn, NONE, bomb_ammo) \
	w_cvar(id, sn, NONE, bomb) \
	w_cvar(id, sn, NONE, bomb_count) \
	w_cvar(id, sn, NONE, bomb_damage) \
	w_cvar(id, sn, NONE, bomb_damageforcescale) \
	w_cvar(id, sn, NONE, bomb_edgedamage) \
	w_cvar(id, sn, NONE, bomb_force) \
	w_cvar(id, sn, NONE, bomb_health) \
	w_cvar(id, sn, NONE, bomb_lifetime) \
	w_cvar(id, sn, NONE, bomb_radius) \
	w_cvar(id, sn, NONE, bomb_speed) \
	w_cvar(id, sn, NONE, bomb_speed_up) \
	w_cvar(id, sn, NONE, bomb_spread_side) \
	w_cvar(id, sn, NONE, bomb_spread_up) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
FLAK_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#else
#ifdef SVQC
#include "../effects.qh"

void spawnfunc_weapon_flak(void) { weapon_defaultspawnfunc(WEP_FLAK); }

void W_Flak_Projectile_Touch(void)
{
	PROJECTILE_TOUCH;

	if(other.takedamage)
	{
		float damage, bnc, frc;
		bool isprimary = !(self.projectiledeathtype & HITTYPE_SECONDARY);

		if(other != self.enemy && (other != self.realowner || (self.projectiledeathtype & HITTYPE_BOUNCE)))
		{
			bnc = pow(WEP_CVAR_BOTH(flak, isprimary, damage_bouncefactor), self.cnt);
			damage = WEP_CVAR_BOTH(flak, isprimary, damage) * bnc;
			frc = WEP_CVAR_BOTH(flak, isprimary, force) * bnc;

			vector force = normalize(NearestPointOnBox(other, self.origin) - self.origin + self.velocity) * frc;

			self.owner = self.realowner;
			Damage(other, self, self.realowner, damage, self.projectiledeathtype, self.origin, force);

			if(accuracy_isgooddamage(self.realowner, other))
 				{ accuracy_add(self.realowner, WEP_FLAK, 0, damage); }
		}

		//Send_Effect(EFFECT_FLAK_BOUNCE, self.origin, self.velocity, 1);

		bool passThrough = WEP_CVAR_BOTH(flak, isprimary, passthrough);

		if(passThrough <= 0)
		{
			remove(self);
			return;
		}

		// semi-fix for "melee" hits
		if(other == self.realowner && !(self.projectiledeathtype & HITTYPE_BOUNCE))
			self.velocity = self.velocity * -1;

		// pass through - we don't want to bounce here, overwrite velocity later
		self.oldvelocity = self.velocity * passThrough;

		// we don't want to hit the same entity again right away
		self.owner = other;
		if(other.iscreature)
			self.enemy = other;
	}
	else if(other.solid == SOLID_BSP)
	{   
		spamsound(self, CH_SHOTS, W_Sound(strcat("casings", ftos(floor(random() * 3) + 1))), VOL_BASE * 0.7, ATTN_NORM);
		//pointparticles(particleeffectnum("flak_bounce"), self.origin, self.velocity, 1);
		self.owner = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		self.cnt += 1;
	}
}

void W_Flak_Projectile_Think(void)
{
	if(time > self.spawnshieldtime)
	{
		remove(self);
		return;
	}

	if(self.oldvelocity)
	{
		self.velocity = self.oldvelocity;
		self.oldvelocity = '0 0 0';
		UpdateCSQCProjectile(self);
	}

	self.nextthink = time;
}

entity W_Flak_Projectile(entity o, bool isprimary, float damage, float grav, float lt, float spd, float upspd, float bnc, float deathtype)
{
	entity e = spawn();
	e.owner = e.realowner = o;
	e.classname = "flak_proj";
	e.bot_dodge = true;
	e.bot_dodgerating = damage;
	e.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(e);
	e.projectiledeathtype = deathtype;
	e.gravity = grav;
	e.bouncefactor = bnc;
	setorigin(e, w_shotorg);
	setsize(e, '0 0 -3', '0 0 -3');

	e.spawnshieldtime = time + lt;
	e.nextthink = time;
	e.think = W_Flak_Projectile_Think;
	e.touch = W_Flak_Projectile_Touch;
	W_SetupProjVelocity_Explicit(e, v_forward, v_up, spd, upspd, 0, 0, false);

	e.angles = vectoangles(e.velocity);
	e.flags = FL_PROJECTILE;
	e.missile_flags = MIF_ARC;

	CSQCProjectile(e, true, PROJECTILE_FLAK, true);   
	return e;
}

void W_Flak_Attack1(bool isprimary)
{
	float pcount = WEP_CVAR_BOTH(flak, isprimary, count), i;
	int dtype = (isprimary) ? WEP_FLAK : (WEP_FLAK | HITTYPE_SECONDARY | HITTYPE_BOUNCE);

	W_DecreaseAmmo(WEP_CVAR_BOTH(flak, isprimary, ammo));

	W_SetupShot_ProjectileSize(self, '0 0 -3', '0 0 -3', false, 4,
							   W_Sound(((isprimary) ? "flak_fire2" : "flak_fire")), CH_WEAPON_A, WEP_CVAR_BOTH(flak, isprimary, damage) * pcount);
	w_shotdir = v_forward;
	vector a;

	for(i = 0; i < pcount; ++i)
	{
		a = fixedvectoangles(w_shotdir);

		fixedmakevectors(a + '1 0 0' *  random() * WEP_CVAR_BOTH(flak, isprimary, spread_up) + '0 1 0' * crandom() * WEP_CVAR_BOTH(flak, isprimary, spread_side));

		W_Flak_Projectile(self, isprimary,
						  WEP_CVAR_BOTH(flak, isprimary, damage),
						  WEP_CVAR_BOTH(flak, isprimary, gravity),
						  WEP_CVAR_BOTH(flak, isprimary, lifetime),
						  WEP_CVAR_BOTH(flak, isprimary, speed),
						  WEP_CVAR_BOTH(flak, isprimary, speed_up),
						  WEP_CVAR_BOTH(flak, isprimary, bouncefactor),
						  dtype);
	}

	entity flash = spawn();
	setmodel(flash, "models/uziflash.md3");
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');
}

void W_Flak_Bomb_Explode(void)
{
	vector dir = normalize(self.velocity);
	dir = dir - 2 * (dir * trace_plane_normal) * trace_plane_normal; 

	if(other.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(other))
			if(DIFF_TEAM(self.realowner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage(self, self.owner, WEP_CVAR(flak, bomb_damage), WEP_CVAR(flak, bomb_edgedamage), WEP_CVAR(flak, bomb_radius),
				 world, world, WEP_CVAR(flak, bomb_force), self.projectiledeathtype, other);

	float i, c = WEP_CVAR(flak, bomb_count);
	w_shotorg = self.origin;

	float spread_up, spread_side;

	if(other.takedamage == DAMAGE_AIM && other.iscreature)
	{
		spread_side = 360;
		spread_up = 360;
	}
	else
	{
		spread_side = WEP_CVAR(flak, bomb_spread_side);
		spread_up = WEP_CVAR(flak, bomb_spread_up);
	}

	for(i = 0; i < c; ++i)
	{
		vector a = fixedvectoangles(dir);

		fixedmakevectors(a + '1 0 0' * crandom() * spread_up
						   + '0 1 0' * crandom() * spread_side);

		entity p = W_Flak_Projectile(self.owner, false,
						  WEP_CVAR_SEC(flak, damage),
						  WEP_CVAR_SEC(flak, gravity),
						  WEP_CVAR_SEC(flak, lifetime),
						  WEP_CVAR_SEC(flak, speed),
						  WEP_CVAR_SEC(flak, speed_up),
						  WEP_CVAR_SEC(flak, bouncefactor),
						  WEP_FLAK | HITTYPE_SECONDARY | HITTYPE_BOUNCE);

		// do not hit the direct hit entity with shrapnel right away (causes very inconsistent behavior)
		p.owner = other;
	}

	remove (self);
}

void W_Flak_Bomb_Touch(void)
{
	PROJECTILE_TOUCH;
	self.use();
}

void W_Flak_Bomb_Damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;

	if(self.health <= 0)
		W_PrepareExplosionByDamage(attacker, self.use);
}

void W_Flak_Attack3(void)
{
	if(!(self.items & IT_UNLIMITED_WEAPON_AMMO))
		self.ammo_rockets -= WEP_CVAR(flak, bomb_ammo);

	W_DecreaseAmmo(WEP_CVAR_SEC(flak, ammo));

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', false, 4, W_Sound("flak_fire3"), CH_WEAPON_A, WEP_CVAR(flak, bomb_damage));
	w_shotdir = v_forward;

	entity e = spawn();
	e.owner = e.realowner = self;
	e.classname = "flak_bomb";
	e.bot_dodge = true;
	e.bot_dodgerating = WEP_CVAR(flak, bomb_damage);
	e.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(e);
	e.projectiledeathtype = WEP_FLAK | HITTYPE_SECONDARY;
	setsize(e, '0 0 -3', '0 0 -3');
	setorigin(e, w_shotorg);

	e.nextthink = time + WEP_CVAR(flak, bomb_lifetime);
	e.think = adaptor_think2use;
	e.use = W_Flak_Bomb_Explode;
	e.touch = W_Flak_Bomb_Touch;
	e.takedamage = DAMAGE_YES;
	e.health = WEP_CVAR(flak, bomb_health);
	e.damageforcescale = WEP_CVAR(flak, bomb_damageforcescale);
	e.event_damage = W_Flak_Bomb_Damage;
	W_SetupProjVelocity_Explicit(e, w_shotdir, v_up, WEP_CVAR(flak, bomb_speed), WEP_CVAR(flak, bomb_speed_up), 0, 0, false);

	e.angles = vectoangles(e.velocity);
	e.flags = FL_PROJECTILE;
	e.missile_flags = MIF_SPLASH | MIF_ARC | MIF_PROXY;

	CSQCProjectile(e, true, PROJECTILE_FLAK_BOMB, true);
}

float W_Flak(float req)
{
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			if(random() < 0.35 && WEP_CVAR(flak, bomb) && self.ammo_rockets >= WEP_CVAR(flak, bomb_ammo))
				self.BUTTON_ATCK2 = bot_aim(WEP_CVAR(flak, bomb_speed), WEP_CVAR(flak, bomb_speed_up), WEP_CVAR(flak, bomb_lifetime), true);
			else
				self.BUTTON_ATCK = bot_aim(WEP_CVAR_PRI(flak, speed), WEP_CVAR_PRI(flak, speed_up), WEP_CVAR_PRI(flak, lifetime), true);
			return true;
		}
		case WR_THINK:
		{
			if(self.BUTTON_ATCK)
			if(weapon_prepareattack(0, WEP_CVAR_PRI(flak, refire)))
			{
				W_Flak_Attack1(true);
				weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(flak, animtime), w_ready);
			}

			if(self.BUTTON_ATCK2)
			if(weapon_prepareattack(1, WEP_CVAR_SEC(flak, refire)))
			{
				if(WEP_CVAR(flak, bomb))
					W_Flak_Attack3();
				else
					W_Flak_Attack1(false);
				weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(flak, animtime), w_ready);
			}

			return true;
		}
		case WR_INIT:
		{
			precache_model(W_Model("g_flak.md3"));
			precache_model(W_Model("v_flak.md3"));
			precache_model(W_Model("h_flak.iqm"));
			precache_sound(W_Sound("flak_fire"));
			precache_sound(W_Sound("flak_fire2"));
			precache_sound(W_Sound("flak_fire3"));
			precache_sound(W_Sound("casings1"));
			precache_sound(W_Sound("casings2"));
			precache_sound(W_Sound("casings3"));
			FLAK_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
			return true;
		}
		case WR_CONFIG:
		{
			FLAK_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
			return true;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.WEP_AMMO(FLAK) >= WEP_CVAR_PRI(flak, ammo);
			ammo_amount += self.(weapon_load[WEP_FLAK]) >= WEP_CVAR_PRI(flak, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			// can't use above logic here, as we have 2 ammo types - WEAPONTODO
			return self.ammo_shells >= WEP_CVAR_SEC(flak, ammo) && (!WEP_CVAR(flak, bomb) || self.ammo_rockets >= WEP_CVAR(flak, bomb_ammo));
		}
		case WR_RELOAD:
		{
			W_Reload(min(WEP_CVAR_PRI(flak, ammo), WEP_CVAR_SEC(flak, ammo), WEP_CVAR(flak, bomb_ammo)), W_Sound("reload"));
			return true;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_FLAK_SUICIDE;
		}
		case WR_KILLMESSAGE:
		{
			if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
				return WEAPON_FLAK_MURDER_SPLASH;
			else
				return WEAPON_FLAK_MURDER_SPRAY;
		}
	}

	return true;
}
#endif
#ifdef CSQC
.float last_bounce;
void Flak_Touch(void)
{
	if(time >= self.last_bounce)
	{
		self.last_bounce = time + 0.1; // spam
    	pointparticles(particleeffectnum("flak_bounce"), self.move_origin, self.move_velocity, 1);
	}
}

float W_Flak(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 12;
			pointparticles(particleeffectnum("rocket_explode"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);

			return true;
		}
		case WR_INIT:
		{
			precache_sound("weapons/rocket_impact.wav");
			return true;
		}
		case WR_ZOOMRETICLE:
		{
			// no weapon specific image for this weapon
			return false;
		}
	}
	return false;
}
#endif
#endif
