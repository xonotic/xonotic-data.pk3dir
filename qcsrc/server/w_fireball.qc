#ifdef REGISTER_WEAPON
REGISTER_WEAPON(FIREBALL, w_fireball, IT_FUEL, 9, WEP_TYPE_SPLASH, BOT_PICKUP_RATING_MID, "fireball", "fireball", "Fireball");
#else
#ifdef SVQC
.float bot_primary_fireballmooth; // whatever a mooth is
.vector fireball_impactvec;
.float fireball_primarytime;

void W_Fireball_Explode (void)
{
	entity e;
	float dist;
	float points;
	vector dir;
	float d;

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	// 1. dist damage
	d = (self.owner.health + self.owner.armorvalue);
	RadiusDamage (self, self.realowner, autocvar_g_balance_fireball_primary_damage, autocvar_g_balance_fireball_primary_edgedamage, autocvar_g_balance_fireball_primary_radius, world, autocvar_g_balance_fireball_primary_force, self.projectiledeathtype, other);
	if(self.realowner.health + self.realowner.armorvalue >= d)
	if(!self.cnt)
	{
		modeleffect_spawn("models/sphere/sphere.md3", 0, 0, self.origin, '0 0 0', '0 0 0', '0 0 0', 0, autocvar_g_balance_fireball_primary_bfgradius, 0.2, 0.05, 0.25);

		// 2. bfg effect
		// NOTE: this cannot be made warpzone aware by design. So, better intentionally ignore warpzones here.
		for(e = findradius(self.origin, autocvar_g_balance_fireball_primary_bfgradius); e; e = e.chain)
		if(e != self.owner) if(e.takedamage == DAMAGE_AIM) if(e.classname != "player" || !self.owner || IsDifferentTeam(e, self))
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
			points = (1 - sqrt(dist / autocvar_g_balance_fireball_primary_bfgradius));
			if(points <= 0)
				continue;
			dir = normalize(e.origin + e.view_ofs - self.origin);

			if(accuracy_isgooddamage(self.realowner, e))
				accuracy_add(self.realowner, WEP_FIREBALL, 0, autocvar_g_balance_fireball_primary_bfgdamage * points);

			Damage(e, self, self.realowner, autocvar_g_balance_fireball_primary_bfgdamage * points, self.projectiledeathtype | HITTYPE_BOUNCE | HITTYPE_SPLASH, e.origin + e.view_ofs, autocvar_g_balance_fireball_primary_bfgforce * dir);
			pointparticles(particleeffectnum("fireball_bfgdamage"), e.origin, -1 * dir, 1);
		}
	}

	remove (self);
}

void W_Fireball_TouchExplode (void)
{
	PROJECTILE_TOUCH;
	W_Fireball_Explode ();
}

void W_Fireball_LaserPlay(float dt, float dist, float damage, float edgedamage, float burntime)
{
	entity e;
	float d;
	vector p;

	if(damage <= 0)
		return;

	RandomSelection_Init();
	for(e = WarpZone_FindRadius(self.origin, dist, TRUE); e; e = e.chain)
	if(e != self.owner) if(e.takedamage == DAMAGE_AIM) if(e.classname != "player" || !self.owner || IsDifferentTeam(e, self))
	{
		p = e.origin;
		p_x += e.mins_x + random() * (e.maxs_x - e.mins_x);
		p_y += e.mins_y + random() * (e.maxs_y - e.mins_y);
		p_z += e.mins_z + random() * (e.maxs_z - e.mins_z);
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
		//trailparticles(self, particleeffectnum("fireball_laser"), self.origin, RandomSelection_chosen_ent.fireball_impactvec);
		pointparticles(particleeffectnum("fireball_laser"), self.origin, RandomSelection_chosen_ent.fireball_impactvec - self.origin, 1);
	}
}

void W_Fireball_Think()
{
	if(time > self.pushltime)
	{
		self.cnt = 1;
		self.projectiledeathtype |= HITTYPE_SPLASH;
		W_Fireball_Explode();
		return;
	}

	W_Fireball_LaserPlay(0.1, autocvar_g_balance_fireball_primary_laserradius, autocvar_g_balance_fireball_primary_laserdamage, autocvar_g_balance_fireball_primary_laseredgedamage, autocvar_g_balance_fireball_primary_laserburntime);

	self.nextthink = time + 0.1;
}

void W_Fireball_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health <= 0)
		return;
	self.health = self.health - damage;
	if (self.health <= 0)
	{
		self.cnt = 1;
		W_PrepareExplosionByDamage(attacker, W_Fireball_Explode);
	}
}

void W_Fireball_Attack1()
{
	local entity proj;

	W_SetupShot_ProjectileSize (self, '-16 -16 -16', '16 16 16', FALSE, 2, "weapons/fireball_fire2.wav", CHAN_WEAPON, autocvar_g_balance_fireball_primary_damage + autocvar_g_balance_fireball_primary_bfgdamage);

	pointparticles(particleeffectnum("fireball_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma_prim";
	proj.owner = proj.realowner = self;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = autocvar_g_balance_fireball_primary_damage;
	proj.pushltime = time + autocvar_g_balance_fireball_primary_lifetime;
	proj.use = W_Fireball_Explode;
	proj.think = W_Fireball_Think;
	proj.nextthink = time;
	proj.health = autocvar_g_balance_fireball_primary_health;
	proj.team = self.team;
	proj.event_damage = W_Fireball_Damage;
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = autocvar_g_balance_fireball_primary_damageforcescale;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_FIREBALL;
	setorigin(proj, w_shotorg);

	proj.movetype = MOVETYPE_FLY;
	W_SETUPPROJECTILEVELOCITY(proj, g_balance_fireball_primary);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_Fireball_TouchExplode;
	setsize(proj, '-16 -16 -16', '16 16 16');
	proj.flags = FL_PROJECTILE;

	CSQCProjectile(proj, TRUE, PROJECTILE_FIREBALL, TRUE);

	other = proj; MUTATOR_CALLHOOK(EditProjectile);
}

void W_Fireball_AttackEffect(float i, vector f_diff)
{
	W_SetupShot_ProjectileSize (self, '-16 -16 -16', '16 16 16', FALSE, 0, "", 0, 0);
	w_shotorg += f_diff_x * v_up + f_diff_y * v_right;
	pointparticles(particleeffectnum("fireball_preattack_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);
}

void W_Fireball_Attack1_Frame4()
{
	W_Fireball_Attack1();
	weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_fireball_primary_animtime, w_ready);
}

void W_Fireball_Attack1_Frame3()
{
	W_Fireball_AttackEffect(0, '+1.25 +3.75 0');
	weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_fireball_primary_animtime, W_Fireball_Attack1_Frame4);
}

void W_Fireball_Attack1_Frame2()
{
	W_Fireball_AttackEffect(0, '-1.25 +3.75 0');
	weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_fireball_primary_animtime, W_Fireball_Attack1_Frame3);
}

void W_Fireball_Attack1_Frame1()
{
	W_Fireball_AttackEffect(1, '+1.25 -3.75 0');
	weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_fireball_primary_animtime, W_Fireball_Attack1_Frame2);
}

void W_Fireball_Attack1_Frame0()
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel = self.ammo_fuel - autocvar_g_balance_fireball_primary_ammo;

	W_Fireball_AttackEffect(0, '-1.25 -3.75 0');
	sound (self, CHAN_WEAPON, "weapons/fireball_prefire2.wav", VOL_BASE, ATTN_NORM);
	weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_fireball_primary_animtime, W_Fireball_Attack1_Frame1);
}

void W_Firemine_Think()
{
	if(time > self.pushltime)
	{
		remove(self);
		return;
	}

	// make it "hot" once it leaves its owner
	if(self.owner)
	{
		if(vlen(self.origin - self.owner.origin - self.owner.view_ofs) > autocvar_g_balance_fireball_secondary_laserradius)
		{
			self.cnt += 1;
			if(self.cnt == 3)
				self.owner = world;
		}
		else
			self.cnt = 0;
	}

	W_Fireball_LaserPlay(0.1, autocvar_g_balance_fireball_secondary_laserradius, autocvar_g_balance_fireball_secondary_laserdamage, autocvar_g_balance_fireball_secondary_laseredgedamage, autocvar_g_balance_fireball_secondary_laserburntime);

	self.nextthink = time + 0.1;
}

void W_Firemine_Touch (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM)
	if(Fire_AddDamage(other, self.realowner, autocvar_g_balance_fireball_secondary_damage, autocvar_g_balance_fireball_secondary_damagetime, self.projectiledeathtype | HITTYPE_HEADSHOT) >= 0)
	{
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

void W_Fireball_Attack2()
{
	local entity proj;
	vector f_diff;
	float c;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel = self.ammo_fuel - autocvar_g_balance_fireball_secondary_ammo;

	c = mod(self.bulletcounter, 4);
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
	W_SetupShot_ProjectileSize(self, '-4 -4 -4', '4 4 4', FALSE, 2, "weapons/fireball_fire.wav", CHAN_WEAPON, autocvar_g_balance_fireball_secondary_damage);
	traceline(w_shotorg, w_shotorg + f_diff_x * v_up + f_diff_y * v_right, MOVE_NORMAL, self);
	w_shotorg = trace_endpos;

	pointparticles(particleeffectnum("fireball_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.owner = proj.realowner = self;
	proj.classname = "grenade";
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = autocvar_g_balance_fireball_secondary_damage;
	proj.movetype = MOVETYPE_BOUNCE;
	proj.projectiledeathtype = WEP_FIREBALL | HITTYPE_SECONDARY;
	proj.touch = W_Firemine_Touch;
	PROJECTILE_MAKETRIGGER(proj);
	setsize(proj, '-4 -4 -4', '4 4 4');
	setorigin(proj, w_shotorg);
	proj.think = W_Firemine_Think;
	proj.nextthink = time;
	proj.damageforcescale = autocvar_g_balance_fireball_secondary_damageforcescale;
	proj.pushltime = time + autocvar_g_balance_fireball_secondary_lifetime;
	W_SETUPPROJECTILEVELOCITY_UP(proj, g_balance_fireball_secondary);

	proj.angles = vectoangles(proj.velocity);
	proj.flags = FL_PROJECTILE;

	CSQCProjectile(proj, TRUE, PROJECTILE_FIREMINE, TRUE);

	other = proj; MUTATOR_CALLHOOK(EditProjectile);
}

void spawnfunc_weapon_fireball (void)
{
	weapon_defaultspawnfunc(WEP_FIREBALL);
}

float w_fireball(float req)
{
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK = FALSE;
		self.BUTTON_ATCK2 = FALSE;
		if (self.bot_primary_fireballmooth == 0)
		{
			if(bot_aim(autocvar_g_balance_fireball_primary_speed, 0, autocvar_g_balance_fireball_primary_lifetime, FALSE))
			{
				self.BUTTON_ATCK = TRUE;
				if(random() < 0.02) self.bot_primary_fireballmooth = 0;
			}
		}
		else
		{
			if(bot_aim(autocvar_g_balance_fireball_secondary_speed, autocvar_g_balance_fireball_secondary_speed_up, autocvar_g_balance_fireball_secondary_lifetime, TRUE))
			{
				self.BUTTON_ATCK2 = TRUE;
				if(random() < 0.01) self.bot_primary_fireballmooth = 1;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (time >= self.fireball_primarytime)
		if (weapon_prepareattack(0, autocvar_g_balance_fireball_primary_refire))
		{
			W_Fireball_Attack1_Frame0();
			self.fireball_primarytime = time + autocvar_g_balance_fireball_primary_refire2;
		}
		if (self.BUTTON_ATCK2)
		if (weapon_prepareattack(1, autocvar_g_balance_fireball_secondary_refire))
		{
			W_Fireball_Attack2();
			weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_fireball_secondary_animtime, w_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_fireball.md3");
		precache_model ("models/weapons/v_fireball.md3");
		precache_model ("models/weapons/h_fireball.iqm");
		precache_model ("models/sphere/sphere.md3");
		precache_sound ("weapons/fireball_fire.wav");
		precache_sound ("weapons/fireball_fire2.wav");
		precache_sound ("weapons/fireball_prefire2.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_FIREBALL);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_fuel >= autocvar_g_balance_fireball_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_fuel >= autocvar_g_balance_fireball_secondary_ammo;
	else if (req == WR_RESETPLAYER)
	{
		self.fireball_primarytime = time;
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_fireball(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			// firemine goes out silently
		}
		else
		{
			org2 = w_org + w_backoff * 16;
			pointparticles(particleeffectnum("fireball_explode"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CHAN_PROJECTILE, "weapons/fireball_impact2.wav", VOL_BASE, ATTN_NORM * 0.25); // long range boom
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/fireball_impact2.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "%s forgot about some firemine";
		else
			w_deathtypestring = "%s should have used a smaller gun";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(w_deathtype & HITTYPE_HEADSHOT)
				w_deathtypestring = "%s tried to catch %s's firemine";
			else
				w_deathtypestring = "%s fatefully ignored %s's firemine";
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				if(w_deathtype & HITTYPE_SPLASH) // BFG effect
					w_deathtypestring = "%s could not hide from %s's fireball";
				else // laser
					w_deathtypestring = "%s saw the pretty lights of %s's fireball";
			}
			else if(w_deathtype & HITTYPE_SPLASH)
				w_deathtypestring = "%s got too close to %s's fireball";
			else
				w_deathtypestring = "%s tasted %s's fireball";
		}
	}
	return TRUE;
}
#endif
#endif
