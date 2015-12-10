#ifndef IMPLEMENTATION
CLASS(Fireball, Weapon)
/* ammotype  */ //ATTRIB(Fireball, ammo_field, .int, ammo_none)
/* impulse   */ ATTRIB(Fireball, impulse, int, 9)
/* flags     */ ATTRIB(Fireball, spawnflags, int, WEP_FLAG_SUPERWEAPON | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Fireball, bot_pickupbasevalue, float, BOT_PICKUP_RATING_MID);
/* color     */ ATTRIB(Fireball, wpcolor, vector, '1 0.5 0');
/* modelname */ ATTRIB(Fireball, mdl, string, "fireball");
#ifndef MENUQC
/* model     */ ATTRIB(Fireball, m_model, Model, MDL_FIREBALL_ITEM);
#endif
/* crosshair */ ATTRIB(Fireball, w_crosshair, string, "gfx/crosshairfireball");
/* crosshair */ //ATTRIB(Fireball, w_crosshair_size, float, 0.65);
/* wepimg    */ ATTRIB(Fireball, model2, string, "weaponfireball");
/* refname   */ ATTRIB(Fireball, netname, string, "fireball");
/* wepname   */ ATTRIB(Fireball, m_name, string, _("Fireball"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, bfgdamage, float, PRI) \
		P(class, prefix, bfgforce, float, PRI) \
		P(class, prefix, bfgradius, float, PRI) \
		P(class, prefix, damageforcescale, float, BOTH) \
		P(class, prefix, damagetime, float, SEC) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, edgedamage, float, PRI) \
		P(class, prefix, force, float, PRI) \
		P(class, prefix, health, float, PRI) \
		P(class, prefix, laserburntime, float, BOTH) \
		P(class, prefix, laserdamage, float, BOTH) \
		P(class, prefix, laseredgedamage, float, BOTH) \
		P(class, prefix, laserradius, float, BOTH) \
		P(class, prefix, lifetime, float, BOTH) \
		P(class, prefix, radius, float, PRI) \
		P(class, prefix, refire2, float, PRI) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, speed, float, BOTH) \
		P(class, prefix, speed_up, float, SEC) \
		P(class, prefix, speed_z, float, SEC) \
		P(class, prefix, spread, float, BOTH) \
		P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, weaponreplace, string,NONE) \
		P(class, prefix, weaponstartoverride, float, NONE) \
		P(class, prefix, weaponstart, float, NONE) \
		P(class, prefix, weaponthrowable, float, NONE) \
	END()
	W_PROPS(X, Fireball, fireball)
#undef X

ENDCLASS(Fireball)
REGISTER_WEAPON(FIREBALL, fireball, NEW(Fireball));

#ifdef SVQC
.float bot_primary_fireballmooth; // whatever a mooth is
.vector fireball_impactvec;
.float fireball_primarytime;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_fireball) { weapon_defaultspawnfunc(this, WEP_FIREBALL); }

void W_Fireball_Explode()
{SELFPARAM();
	entity e;
	float dist;
	float points;
	vector dir;
	float d;

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	// 1. dist damage
	d = (self.realowner.health + self.realowner.armorvalue);
	RadiusDamage(self, self.realowner, WEP_CVAR_PRI(fireball, damage), WEP_CVAR_PRI(fireball, edgedamage), WEP_CVAR_PRI(fireball, radius), world, world, WEP_CVAR_PRI(fireball, force), self.projectiledeathtype, other);
	if(self.realowner.health + self.realowner.armorvalue >= d)
	if(!self.cnt)
	{
		modeleffect_spawn("models/sphere/sphere.md3", 0, 0, self.origin, '0 0 0', '0 0 0', '0 0 0', 0, WEP_CVAR_PRI(fireball, bfgradius), 0.2, 0.05, 0.25);

		// 2. bfg effect
		// NOTE: this cannot be made warpzone aware by design. So, better intentionally ignore warpzones here.
		for(e = findradius(self.origin, WEP_CVAR_PRI(fireball, bfgradius)); e; e = e.chain)
		if(e != self.realowner) if(e.takedamage == DAMAGE_AIM) if(!IS_PLAYER(e) || !self.realowner || DIFF_TEAM(e, self))
		{
			// can we see fireball?
			traceline(e.origin + e.view_ofs, self.origin, MOVE_NORMAL, e);
			if(/* trace_startsolid || */ trace_fraction != 1) // startsolid should be never happening anyway
				continue;
			// can we see player who shot fireball?
			traceline(e.origin + e.view_ofs, self.realowner.origin + self.realowner.view_ofs, MOVE_NORMAL, e);
			if(trace_ent != self.realowner)
			if(/* trace_startsolid || */ trace_fraction != 1)
				continue;
			dist = vlen(self.origin - e.origin - e.view_ofs);
			points = (1 - sqrt(dist / WEP_CVAR_PRI(fireball, bfgradius)));
			if(points <= 0)
				continue;
			dir = normalize(e.origin + e.view_ofs - self.origin);

			if(accuracy_isgooddamage(self.realowner, e))
				accuracy_add(self.realowner, WEP_FIREBALL.m_id, 0, WEP_CVAR_PRI(fireball, bfgdamage) * points);

			Damage(e, self, self.realowner, WEP_CVAR_PRI(fireball, bfgdamage) * points, self.projectiledeathtype | HITTYPE_BOUNCE | HITTYPE_SPLASH, e.origin + e.view_ofs, WEP_CVAR_PRI(fireball, bfgforce) * dir);
			Send_Effect(EFFECT_FIREBALL_BFGDAMAGE, e.origin, -1 * dir, 1);
		}
	}

	remove(self);
}

void W_Fireball_TouchExplode()
{
	PROJECTILE_TOUCH;
	W_Fireball_Explode();
}

void W_Fireball_LaserPlay(float dt, float dist, float damage, float edgedamage, float burntime)
{SELFPARAM();
	entity e;
	float d;
	vector p;

	if(damage <= 0)
		return;

	RandomSelection_Init();
	for(e = WarpZone_FindRadius(self.origin, dist, true); e; e = e.chain)
	if(e != self.realowner) if(e.takedamage == DAMAGE_AIM) if(!IS_PLAYER(e) || !self.realowner || DIFF_TEAM(e, self))
	{
		p = e.origin;
		p.x += e.mins.x + random() * (e.maxs.x - e.mins.x);
		p.y += e.mins.y + random() * (e.maxs.y - e.mins.y);
		p.z += e.mins.z + random() * (e.maxs.z - e.mins.z);
		d = vlen(WarpZone_UnTransformOrigin(e, self.origin) - p);
		if(d < dist)
		{
			e.fireball_impactvec = p;
			RandomSelection_Add(e, 0, string_null, 1 / (1 + d), !Fire_IsBurning(e));
		}
	}
	if(RandomSelection_chosen_ent)
	{
		d = vlen(WarpZone_UnTransformOrigin(RandomSelection_chosen_ent, self.origin) - RandomSelection_chosen_ent.fireball_impactvec);
		d = damage + (edgedamage - damage) * (d / dist);
		Fire_AddDamage(RandomSelection_chosen_ent, self.realowner, d * burntime, burntime, self.projectiledeathtype | HITTYPE_BOUNCE);
		//trailparticles(self, particleeffectnum(EFFECT_FIREBALL_LASER), self.origin, RandomSelection_chosen_ent.fireball_impactvec);
		Send_Effect(EFFECT_FIREBALL_LASER, self.origin, RandomSelection_chosen_ent.fireball_impactvec - self.origin, 1);
	}
}

void W_Fireball_Think()
{SELFPARAM();
	if(time > self.pushltime)
	{
		self.cnt = 1;
		self.projectiledeathtype |= HITTYPE_SPLASH;
		W_Fireball_Explode();
		return;
	}

	W_Fireball_LaserPlay(0.1, WEP_CVAR_PRI(fireball, laserradius), WEP_CVAR_PRI(fireball, laserdamage), WEP_CVAR_PRI(fireball, laseredgedamage), WEP_CVAR_PRI(fireball, laserburntime));

	self.nextthink = time + 0.1;
}

void W_Fireball_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.health <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;
	if(self.health <= 0)
	{
		self.cnt = 1;
		W_PrepareExplosionByDamage(attacker, W_Fireball_Explode);
	}
}

void W_Fireball_Attack1()
{SELFPARAM();
	entity proj;

	W_SetupShot_ProjectileSize(self, '-16 -16 -16', '16 16 16', false, 2, SND(FIREBALL_FIRE2), CH_WEAPON_A, WEP_CVAR_PRI(fireball, damage) + WEP_CVAR_PRI(fireball, bfgdamage));

	Send_Effect(EFFECT_FIREBALL_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	proj = new(plasma_prim);
	proj.owner = proj.realowner = self;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_PRI(fireball, damage);
	proj.pushltime = time + WEP_CVAR_PRI(fireball, lifetime);
	proj.use = W_Fireball_Explode;
	proj.think = W_Fireball_Think;
	proj.nextthink = time;
	proj.health = WEP_CVAR_PRI(fireball, health);
	proj.team = self.team;
	proj.event_damage = W_Fireball_Damage;
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = WEP_CVAR_PRI(fireball, damageforcescale);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_FIREBALL.m_id;
	setorigin(proj, w_shotorg);

	proj.movetype = MOVETYPE_FLY;
	W_SetupProjVelocity_PRI(proj, fireball);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Fireball_TouchExplode;
	setsize(proj, '-16 -16 -16', '16 16 16');
	proj.flags = FL_PROJECTILE;
    proj.missile_flags = MIF_SPLASH | MIF_PROXY;

	CSQCProjectile(proj, true, PROJECTILE_FIREBALL, true);

	MUTATOR_CALLHOOK(EditProjectile, self, proj);
}

void W_Fireball_AttackEffect(float i, vector f_diff)
{SELFPARAM();
	W_SetupShot_ProjectileSize(self, '-16 -16 -16', '16 16 16', false, 0, "", 0, 0);
	w_shotorg += f_diff.x * v_up + f_diff.y * v_right;
	Send_Effect(EFFECT_FIREBALL_PRE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);
}

void W_Fireball_Attack1_Frame4(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_Attack1();
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), w_ready);
}

void W_Fireball_Attack1_Frame3(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(0, '+1.25 +3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame4);
}

void W_Fireball_Attack1_Frame2(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(0, '-1.25 +3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame3);
}

void W_Fireball_Attack1_Frame1(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(1, '+1.25 -3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame2);
}

void W_Fireball_Attack1_Frame0(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{SELFPARAM();
	W_Fireball_AttackEffect(0, '-1.25 -3.75 0');
	sound(self, CH_WEAPON_SINGLE, SND_FIREBALL_PREFIRE2, VOL_BASE, ATTEN_NORM);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame1);
}

void W_Fireball_Firemine_Think()
{SELFPARAM();
	if(time > self.pushltime)
	{
		remove(self);
		return;
	}

	// make it "hot" once it leaves its owner
	if(self.owner)
	{
		if(vlen(self.origin - self.owner.origin - self.owner.view_ofs) > WEP_CVAR_SEC(fireball, laserradius))
		{
			self.cnt += 1;
			if(self.cnt == 3)
				self.owner = world;
		}
		else
			self.cnt = 0;
	}

	W_Fireball_LaserPlay(0.1, WEP_CVAR_SEC(fireball, laserradius), WEP_CVAR_SEC(fireball, laserdamage), WEP_CVAR_SEC(fireball, laseredgedamage), WEP_CVAR_SEC(fireball, laserburntime));

	self.nextthink = time + 0.1;
}

void W_Fireball_Firemine_Touch()
{SELFPARAM();
	PROJECTILE_TOUCH;
	if(other.takedamage == DAMAGE_AIM)
	if(Fire_AddDamage(other, self.realowner, WEP_CVAR_SEC(fireball, damage), WEP_CVAR_SEC(fireball, damagetime), self.projectiledeathtype) >= 0)
	{
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void W_Fireball_Attack2()
{SELFPARAM();
	entity proj;
	vector f_diff;
	float c;

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
	W_SetupShot_ProjectileSize(self, '-4 -4 -4', '4 4 4', false, 2, SND(FIREBALL_FIRE), CH_WEAPON_A, WEP_CVAR_SEC(fireball, damage));
	traceline(w_shotorg, w_shotorg + f_diff_x * v_up + f_diff_y * v_right, MOVE_NORMAL, self);
	w_shotorg = trace_endpos;

	Send_Effect(EFFECT_FIREBALL_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	proj = new(grenade);
	proj.owner = proj.realowner = self;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_SEC(fireball, damage);
	proj.movetype = MOVETYPE_BOUNCE;
	proj.projectiledeathtype = WEP_FIREBALL.m_id | HITTYPE_SECONDARY;
	proj.touch = W_Fireball_Firemine_Touch;
	PROJECTILE_MAKETRIGGER(proj);
	setsize(proj, '-4 -4 -4', '4 4 4');
	setorigin(proj, w_shotorg);
	proj.think = W_Fireball_Firemine_Think;
	proj.nextthink = time;
	proj.damageforcescale = WEP_CVAR_SEC(fireball, damageforcescale);
	proj.pushltime = time + WEP_CVAR_SEC(fireball, lifetime);
	W_SetupProjVelocity_UP_SEC(proj, fireball);

	proj.angles = vectoangles(proj.velocity);
	proj.flags = FL_PROJECTILE;
    proj.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_ARC;

	CSQCProjectile(proj, true, PROJECTILE_FIREMINE, true);

	MUTATOR_CALLHOOK(EditProjectile, self, proj);
}

		METHOD(Fireball, wr_aim, void(entity thiswep))
		{
			self.BUTTON_ATCK = false;
			self.BUTTON_ATCK2 = false;
			if(self.bot_primary_fireballmooth == 0)
			{
				if(bot_aim(WEP_CVAR_PRI(fireball, speed), 0, WEP_CVAR_PRI(fireball, lifetime), false))
				{
					self.BUTTON_ATCK = true;
					if(random() < 0.02) self.bot_primary_fireballmooth = 0;
				}
			}
			else
			{
				if(bot_aim(WEP_CVAR_SEC(fireball, speed), WEP_CVAR_SEC(fireball, speed_up), WEP_CVAR_SEC(fireball, lifetime), true))
				{
					self.BUTTON_ATCK2 = true;
					if(random() < 0.01) self.bot_primary_fireballmooth = 1;
				}
			}
		}
		METHOD(Fireball, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(fire & 1)
			{
				if(time >= actor.fireball_primarytime)
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(fireball, refire)))
				{
					W_Fireball_Attack1_Frame0(thiswep, actor, weaponentity, fire);
					actor.fireball_primarytime = time + WEP_CVAR_PRI(fireball, refire2) * W_WeaponRateFactor();
				}
			}
			else if(fire & 2)
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(fireball, refire)))
				{
					W_Fireball_Attack2();
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(fireball, animtime), w_ready);
				}
			}
		}
		METHOD(Fireball, wr_setup, void(entity thiswep))
		{
			self.ammo_field = ammo_none;
		}
		METHOD(Fireball, wr_checkammo1, bool(entity thiswep))
		{
			return true; // infinite ammo
		}
		METHOD(Fireball, wr_checkammo2, bool(entity thiswep))
		{
			return true; // fireball has infinite ammo
		}
		METHOD(Fireball, wr_resetplayer, void(entity thiswep))
		{
			self.fireball_primarytime = time;
		}
		METHOD(Fireball, wr_suicidemessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_FIREBALL_SUICIDE_FIREMINE;
			else
				return WEAPON_FIREBALL_SUICIDE_BLAST;
		}
		METHOD(Fireball, wr_killmessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_FIREBALL_MURDER_FIREMINE;
			else
				return WEAPON_FIREBALL_MURDER_BLAST;
		}

#endif
#ifdef CSQC

		METHOD(Fireball, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			if(w_deathtype & HITTYPE_SECONDARY)
			{
				// firemine goes out silently
			}
			else
			{
				org2 = w_org + w_backoff * 16;
				pointparticles(EFFECT_FIREBALL_EXPLODE, org2, '0 0 0', 1);
				if(!w_issilent)
					sound(self, CH_SHOTS, SND_FIREBALL_IMPACT2, VOL_BASE, ATTEN_NORM * 0.25); // long range boom
			}
		}

#endif
#endif
