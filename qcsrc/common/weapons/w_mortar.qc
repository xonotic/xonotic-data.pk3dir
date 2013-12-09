#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ MORTAR,
/* function */ w_glauncher,
/* ammotype */ IT_ROCKETS,
/* impulse  */ 4,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH,
/* rating   */ BOT_PICKUP_RATING_MID,
/* model    */ "gl",
/* netname  */ "grenadelauncher",
/* fullname */ _("Mortar")
);

#define MORTAR_SETTINGS(w_cvar,w_prop) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, ammo) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, animtime) \
	w_cvar(WEP_MORTAR, mortar, MO_NONE, bouncefactor) \
	w_cvar(WEP_MORTAR, mortar, MO_NONE, bouncestop) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, damage) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, damageforcescale) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, edgedamage) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, force) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, health) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, lifetime) \
	w_cvar(WEP_MORTAR, mortar, MO_SEC,  lifetime_bounce) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, lifetime_stick) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, radius) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, refire) \
	w_cvar(WEP_MORTAR, mortar, MO_PRI,  remote_minbouncecnt) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, speed) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, speed_up) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, speed_z) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, spread) \
	w_cvar(WEP_MORTAR, mortar, MO_BOTH, type) \
	w_prop(WEP_MORTAR, mortar, reloading_ammo, reload_ammo) \
	w_prop(WEP_MORTAR, mortar, reloading_time, reload_time) \
	w_prop(WEP_MORTAR, mortar, switchdelay_raise, switchdelay_raise) \
	w_prop(WEP_MORTAR, mortar, switchdelay_drop, switchdelay_drop)

#ifdef SVQC
MORTAR_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
.float gl_detonate_later;
.float gl_bouncecnt;
#endif
#else
#ifdef SVQC

void W_Grenade_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(other))
			if(DIFF_TEAM(self.realowner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	if(self.movetype == MOVETYPE_NONE)
		self.velocity = self.oldvelocity;

	RadiusDamage (self, self.realowner, WEP_CVAR_PRI(mortar, damage), WEP_CVAR_PRI(mortar, edgedamage), WEP_CVAR_PRI(mortar, radius), world, world, WEP_CVAR_PRI(mortar, force), self.projectiledeathtype, other);

	remove (self);
}

void W_Grenade_Explode2 (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(other))
			if(DIFF_TEAM(self.realowner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	if(self.movetype == MOVETYPE_NONE)
		self.velocity = self.oldvelocity;

	RadiusDamage (self, self.realowner, WEP_CVAR_SEC(mortar, damage), WEP_CVAR_SEC(mortar, edgedamage), WEP_CVAR_SEC(mortar, radius), world, world, WEP_CVAR_SEC(mortar, force), self.projectiledeathtype, other);

	remove (self);
}

void W_Grenade_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
		
	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt
		
	self.health = self.health - damage;
	
	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, self.use);
}

void W_Grenade_Think1 (void)
{
	self.nextthink = time;
	if (time > self.cnt)
	{
		other = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Grenade_Explode ();
		return;
	}
	if(self.gl_detonate_later && self.gl_bouncecnt >= WEP_CVAR_PRI(mortar, remote_minbouncecnt))
		W_Grenade_Explode();
}

void W_Grenade_Touch1 (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM || WEP_CVAR_PRI(mortar, type) == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		self.use ();
	}
	else if (WEP_CVAR_PRI(mortar, type) == 1) // bounce
	{
		float r;
		r = random() * 6;
		if(r < 1)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		self.gl_bouncecnt += 1;
	}
	else if(WEP_CVAR_PRI(mortar, type) == 2 && (!other || (other.takedamage != DAMAGE_AIM && other.movetype == MOVETYPE_NONE))) // stick
	{
		spamsound (self, CH_SHOTS, "weapons/grenade_stick.wav", VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		self.oldvelocity = self.velocity;
		self.velocity = '0 0 0';
		self.movetype = MOVETYPE_NONE; // also disables gravity
		self.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(self);

		// do not respond to any more touches
		self.solid = SOLID_NOT;

		self.nextthink = min(self.nextthink, time + WEP_CVAR_PRI(mortar, lifetime_stick));
	}
}

void W_Grenade_Touch2 (void)
{
	PROJECTILE_TOUCH;
	if (other.takedamage == DAMAGE_AIM || WEP_CVAR_SEC(mortar, type) == 0) // always explode when hitting a player, or if normal mortar projectile
	{
		self.use ();
	}
	else if (WEP_CVAR_SEC(mortar, type) == 1) // bounce
	{
		float r;
		r = random() * 6;
		if(r < 1)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce1.wav", VOL_BASE, ATTN_NORM);
		else if(r < 2)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce2.wav", VOL_BASE, ATTN_NORM);
		else if(r < 3)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce3.wav", VOL_BASE, ATTN_NORM);
		else if(r < 4)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce4.wav", VOL_BASE, ATTN_NORM);
		else if(r < 5)
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce5.wav", VOL_BASE, ATTN_NORM);
		else
			spamsound (self, CH_SHOTS, "weapons/grenade_bounce6.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		self.gl_bouncecnt += 1;
		
		if (WEP_CVAR_SEC(mortar, lifetime_bounce) && self.gl_bouncecnt == 1)
			self.nextthink = time + WEP_CVAR_SEC(mortar, lifetime_bounce);
			
	}
	else if(WEP_CVAR_SEC(mortar, type) == 2 && (!other || (other.takedamage != DAMAGE_AIM && other.movetype == MOVETYPE_NONE))) // stick
	{
		spamsound (self, CH_SHOTS, "weapons/grenade_stick.wav", VOL_BASE, ATTN_NORM);

		// let it stick whereever it is
		self.oldvelocity = self.velocity;
		self.velocity = '0 0 0';
		self.movetype = MOVETYPE_NONE; // also disables gravity
		self.gravity = 0; // nope, it does NOT! maybe a bug in CSQC code? TODO
		UpdateCSQCProjectile(self);

		// do not respond to any more touches
		self.solid = SOLID_NOT;

		self.nextthink = min(self.nextthink, time + WEP_CVAR_SEC(mortar, lifetime_stick));
	}
}

void W_Grenade_Attack (void)
{
	entity gren;

	W_DecreaseAmmo(ammo_rockets, WEP_CVAR_PRI(mortar, ammo), autocvar_g_balance_mortar_reload_ammo); // WEAPONTODO

	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', FALSE, 4, "weapons/grenade_fire.wav", CH_WEAPON_A, WEP_CVAR_PRI(mortar, damage));
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = gren.realowner = self;
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = WEP_CVAR_PRI(mortar, damage);
	gren.movetype = MOVETYPE_BOUNCE;
	gren.bouncefactor = WEP_CVAR(mortar, bouncefactor);
	gren.bouncestop = WEP_CVAR(mortar, bouncestop);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_MORTAR;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.cnt = time + WEP_CVAR_PRI(mortar, lifetime);
	gren.nextthink = time;
	gren.think = W_Grenade_Think1;
	gren.use = W_Grenade_Explode;
	gren.touch = W_Grenade_Touch1;

	gren.takedamage = DAMAGE_YES;
	gren.health = WEP_CVAR_PRI(mortar, health);
	gren.damageforcescale = WEP_CVAR_PRI(mortar, damageforcescale);
	gren.event_damage = W_Grenade_Damage;
	gren.damagedbycontents = TRUE;
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	WEP_SETUPPROJVELOCITY_UP_PRI(gren, mortar);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	if(WEP_CVAR_PRI(mortar, type) == 0 || WEP_CVAR_PRI(mortar, type) == 2)
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
	else
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);

	other = gren; MUTATOR_CALLHOOK(EditProjectile);
}

void W_Grenade_Attack2 (void)
{
	entity gren;

	W_DecreaseAmmo(ammo_rockets, WEP_CVAR_SEC(mortar, ammo), autocvar_g_balance_mortar_reload_ammo);

	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', FALSE, 4, "weapons/grenade_fire.wav", CH_WEAPON_A, WEP_CVAR_SEC(mortar, damage));
	w_shotdir = v_forward; // no TrueAim for grenades please

	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = gren.realowner = self;
	gren.classname = "grenade";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = WEP_CVAR_SEC(mortar, damage);
	gren.movetype = MOVETYPE_BOUNCE;
	gren.bouncefactor = WEP_CVAR(mortar, bouncefactor);
	gren.bouncestop = WEP_CVAR(mortar, bouncestop);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_MORTAR | HITTYPE_SECONDARY;
	setorigin(gren, w_shotorg);
	setsize(gren, '-3 -3 -3', '3 3 3');

	gren.nextthink = time + WEP_CVAR_SEC(mortar, lifetime);
	gren.think = adaptor_think2use_hittype_splash;
	gren.use = W_Grenade_Explode2;
	gren.touch = W_Grenade_Touch2;

	gren.takedamage = DAMAGE_YES;
	gren.health = WEP_CVAR_SEC(mortar, health);
	gren.damageforcescale = WEP_CVAR_SEC(mortar, damageforcescale);
	gren.event_damage = W_Grenade_Damage;
	gren.damagedbycontents = TRUE;
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	WEP_SETUPPROJVELOCITY_UP_SEC(gren, mortar); // WEAPONTODO

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	if(WEP_CVAR_SEC(mortar, type) == 0 || WEP_CVAR_SEC(mortar, type) == 2)
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
	else
		CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);

	other = gren; MUTATOR_CALLHOOK(EditProjectile);
}

void spawnfunc_weapon_grenadelauncher (void)
{
	weapon_defaultspawnfunc(WEP_MORTAR);
}

.float bot_secondary_grenademooth;
float w_glauncher(float req)
{
	entity nade;
	float nadefound;
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			self.BUTTON_ATCK = FALSE;
			self.BUTTON_ATCK2 = FALSE;
			if (self.bot_secondary_grenademooth == 0) // WEAPONTODO: merge this into using WEP_CVAR_BOTH
			{
				if(bot_aim(WEP_CVAR_PRI(mortar, speed), WEP_CVAR_PRI(mortar, speed_up), WEP_CVAR_PRI(mortar, lifetime), TRUE))
				{
					self.BUTTON_ATCK = TRUE;
					if(random() < 0.01) self.bot_secondary_grenademooth = 1;
				}
			}
			else
			{
				if(bot_aim(WEP_CVAR_SEC(mortar, speed), WEP_CVAR_SEC(mortar, speed_up), WEP_CVAR_SEC(mortar, lifetime), TRUE))
				{
					self.BUTTON_ATCK2 = TRUE;
					if(random() < 0.02) self.bot_secondary_grenademooth = 0;
				}
			}
			
			return TRUE;
		}
		/*case WR_CALCINFO:
		{
			wepinfo_pri_refire = max3(sys_frametime, WEP_CVAR_PRI(mortar, refire), WEP_CVAR_PRI(mortar, animtime));
			wepinfo_pri_dps = (WEP_CVAR_PRI(mortar, damage) * (1 / wepinfo_pri_refire));
			wepinfo_pri_speed = (1 / max(1, (10000 / max(1, WEP_CVAR_PRI(mortar, speed)))));

			// for the range calculation, closer to 1 is better
			wepinfo_pri_range_max = 2000 * wepinfo_pri_speed;
			wepinfo_pri_range = wepinfo_pri_speed * WEP_CVAR_PRI(mortar, 
			
			wepinfo_sec_refire = max3(sys_frametime, WEP_CVAR_SEC(mortar, refire), WEP_CVAR_SEC(mortar, animtime));
			wepinfo_sec_dps = (WEP_CVAR_SEC(mortar, damage) * (1 / wepinfo_sec_refire));
			
			wepinfo_sec_dps = (WEP_CVAR_SEC(mortar, damage) * (1 / max3(sys_frametime, WEP_CVAR_SEC(mortar, refire), WEP_CVAR_SEC(mortar, animtime))));
			wepinfo_ter_dps = 0;
			*/
		case WR_THINK:
		{
			if(autocvar_g_balance_mortar_reload_ammo && self.clip_load < min(WEP_CVAR_PRI(mortar, ammo), WEP_CVAR_SEC(mortar, ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if (self.BUTTON_ATCK)
			{
				if (weapon_prepareattack(0, WEP_CVAR_PRI(mortar, refire)))
				{
					W_Grenade_Attack();
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(mortar, animtime), w_ready);
				}
			}
			else if (self.BUTTON_ATCK2)
			{
				if (cvar("g_balance_mortar_secondary_remote_detonateprimary"))
				{
					nadefound = 0;
					for(nade = world; (nade = find(nade, classname, "grenade")); ) if(nade.realowner == self)
					{
						if(!nade.gl_detonate_later)
						{
							nade.gl_detonate_later = TRUE;
							nadefound = 1;
						}
					}
					if(nadefound)
						sound (self, CH_WEAPON_B, "weapons/rocket_det.wav", VOL_BASE, ATTN_NORM);
				}
				else if (weapon_prepareattack(1, WEP_CVAR_SEC(mortar, refire)))
				{
					W_Grenade_Attack2();
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(mortar, animtime), w_ready);
				}
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model ("models/weapons/g_gl.md3");
			precache_model ("models/weapons/v_gl.md3");
			precache_model ("models/weapons/h_gl.iqm");
			precache_sound ("weapons/grenade_bounce1.wav");
			precache_sound ("weapons/grenade_bounce2.wav");
			precache_sound ("weapons/grenade_bounce3.wav");
			precache_sound ("weapons/grenade_bounce4.wav");
			precache_sound ("weapons/grenade_bounce5.wav");
			precache_sound ("weapons/grenade_bounce6.wav");
			precache_sound ("weapons/grenade_stick.wav");
			precache_sound ("weapons/grenade_fire.wav");
			MORTAR_SETTINGS(WEP_SKIPCVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_rockets;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.ammo_rockets >= WEP_CVAR_PRI(mortar, ammo);
			ammo_amount += self.(weapon_load[WEP_MORTAR]) >= WEP_CVAR_PRI(mortar, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			ammo_amount = self.ammo_rockets >= WEP_CVAR_SEC(mortar, ammo);
			ammo_amount += self.(weapon_load[WEP_MORTAR]) >= WEP_CVAR_SEC(mortar, ammo);
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			MORTAR_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_Reload(min(WEP_CVAR_PRI(mortar, ammo), WEP_CVAR_SEC(mortar, ammo)), "weapons/reload.wav"); // WEAPONTODO
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_MORTAR_SUICIDE_BOUNCE;
			else
				return WEAPON_MORTAR_SUICIDE_EXPLODE;
		}
		case WR_KILLMESSAGE:
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_MORTAR_MURDER_BOUNCE;
			else
				return WEAPON_MORTAR_MURDER_EXPLODE;
		}
	}
	return TRUE;
}
#endif
#ifdef CSQC
float w_glauncher(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 12;
			pointparticles(particleeffectnum("grenade_explode"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);
				
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/grenade_impact.wav");
			return TRUE;
		}
	}
	return TRUE;
}
#endif
#endif
