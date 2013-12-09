#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ HAGAR,
/* function */ w_hagar,
/* ammotype */ IT_ROCKETS,
/* impulse  */ 8,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH,
/* rating   */ BOT_PICKUP_RATING_MID,
/* model    */ "hagar",
/* netname  */ "hagar",
/* fullname */ _("Hagar")
);

#define HAGAR_SETTINGS(w_cvar,w_prop) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, ammo) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, damage) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, edgedamage) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, force) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, radius) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, refire) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, speed) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, damageforcescale) \
	w_cvar(WEP_HAGAR, hagar, MO_BOTH, health) \
	w_cvar(WEP_HAGAR, hagar, MO_PRI,  lifetime) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  spread) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_max) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_abort) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_animtime) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_hold) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_speed) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_releasedeath) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_spread) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_spread_bias) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  load_linkexplode) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  lifetime_min) \
	w_cvar(WEP_HAGAR, hagar, MO_SEC,  lifetime_rand) \
	w_cvar(WEP_HAGAR, hagar, MO_NONE, secondary) \
	w_prop(WEP_HAGAR, hagar, reloading_ammo, reload_ammo) \
	w_prop(WEP_HAGAR, hagar, reloading_time, reload_time) \
	w_prop(WEP_HAGAR, hagar, switchdelay_raise, switchdelay_raise) \
	w_prop(WEP_HAGAR, hagar, switchdelay_drop, switchdelay_drop)

#ifdef SVQC
HAGAR_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_hagar() { weapon_defaultspawnfunc(WEP_HAGAR); }

// NO bounce protection, as bounces are limited!

void W_Hagar_Explode (void)
{
	self.event_damage = func_null;
	RadiusDamage (self, self.realowner, WEP_CVAR_PRI(hagar, damage), WEP_CVAR_PRI(hagar, edgedamage), WEP_CVAR_PRI(hagar, radius), world, world, WEP_CVAR_PRI(hagar, force), self.projectiledeathtype, other);

	remove (self);
}

void W_Hagar_Explode2 (void)
{
	self.event_damage = func_null;
	RadiusDamage (self, self.realowner, WEP_CVAR_SEC(hagar, damage), WEP_CVAR_SEC(hagar, edgedamage), WEP_CVAR_SEC(hagar, radius), world, world, WEP_CVAR_SEC(hagar, force), self.projectiledeathtype, other);

	remove (self);
}

void W_Hagar_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
		
	float is_linkexplode = ( ((inflictor.owner != world) ? (inflictor.owner == self.owner) : TRUE)
		&& (inflictor.projectiledeathtype & HITTYPE_SECONDARY) 
		&& (self.projectiledeathtype & HITTYPE_SECONDARY));
	
	if(is_linkexplode)
		is_linkexplode = (is_linkexplode && WEP_CVAR_SEC(hagar, load_linkexplode));
	else
		is_linkexplode = -1; // not secondary load, so continue as normal without exception.

	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, is_linkexplode))
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;
	self.angles = vectoangles(self.velocity);
	
	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, self.think);
}

void W_Hagar_Touch (void)
{
	PROJECTILE_TOUCH;
	self.use ();
}

void W_Hagar_Touch2 (void)
{
	PROJECTILE_TOUCH;

	if(self.cnt > 0 || other.takedamage == DAMAGE_AIM) {
		self.use();
	} else {
		self.cnt++;
		pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);
		self.angles = vectoangles (self.velocity);
		self.owner = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Hagar_Attack (void)
{
	entity missile;

	W_DecreaseAmmo(ammo_rockets, WEP_CVAR_PRI(hagar, ammo), autocvar_g_balance_hagar_reload_ammo);

	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", CH_WEAPON_A, WEP_CVAR_PRI(hagar, damage));

	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "missile";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = WEP_CVAR_PRI(hagar, damage);
	
	missile.takedamage = DAMAGE_YES;
	missile.health = WEP_CVAR_PRI(hagar, health);
	missile.damageforcescale = WEP_CVAR_PRI(hagar, damageforcescale);
	missile.event_damage = W_Hagar_Damage;
	missile.damagedbycontents = TRUE;
	
	missile.touch = W_Hagar_Touch;
	missile.use = W_Hagar_Explode;
	missile.think = adaptor_think2use_hittype_splash;
	missile.nextthink = time + WEP_CVAR_PRI(hagar, lifetime);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR;
	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	missile.movetype = MOVETYPE_FLY;
	W_SETUPPROJECTILEVELOCITY(missile, g_balance_hagar_primary);

	missile.angles = vectoangles (missile.velocity);
	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH; 

	CSQCProjectile(missile, TRUE, PROJECTILE_HAGAR, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void W_Hagar_Attack2 (void)
{
	entity missile;

	W_DecreaseAmmo(ammo_rockets, WEP_CVAR_SEC(hagar, ammo), autocvar_g_balance_hagar_reload_ammo);

	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", CH_WEAPON_A, WEP_CVAR_SEC(hagar, damage));

	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "missile";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = WEP_CVAR_SEC(hagar, damage);
	
	missile.takedamage = DAMAGE_YES;
	missile.health = WEP_CVAR_SEC(hagar, health);
	missile.damageforcescale = WEP_CVAR_SEC(hagar, damageforcescale);
	missile.event_damage = W_Hagar_Damage;
	missile.damagedbycontents = TRUE;

	missile.touch = W_Hagar_Touch2;
	missile.cnt = 0;
	missile.use = W_Hagar_Explode2;
	missile.think = adaptor_think2use_hittype_splash;
	missile.nextthink = time + WEP_CVAR_SEC(hagar, lifetime_min) + random() * WEP_CVAR_SEC(hagar, lifetime_rand);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR | HITTYPE_SECONDARY;
	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	missile.movetype = MOVETYPE_BOUNCEMISSILE;
	W_SETUPPROJECTILEVELOCITY(missile, g_balance_hagar_secondary);

	missile.angles = vectoangles (missile.velocity);
	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH; 

	CSQCProjectile(missile, TRUE, PROJECTILE_HAGAR_BOUNCING, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

.float hagar_loadstep, hagar_loadblock, hagar_loadbeep, hagar_warning;
void W_Hagar_Attack2_Load_Release (void)
{
	// time to release the rockets we've loaded

	entity missile;
	float counter, shots, spread_pershot;
	vector s;
	vector forward, right, up;

	if(!self.hagar_load)
		return;

	weapon_prepareattack_do(1, WEP_CVAR_SEC(hagar, refire));

	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", CH_WEAPON_A, WEP_CVAR_SEC(hagar, damage));
	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	forward = v_forward;
	right = v_right;
	up = v_up;

	shots = self.hagar_load;
	missile = world;
	for(counter = 0; counter < shots; ++counter)
	{
		missile = spawn ();
		missile.owner = missile.realowner = self;
		missile.classname = "missile";
		missile.bot_dodge = TRUE;
		missile.bot_dodgerating = WEP_CVAR_SEC(hagar, damage);
		
		missile.takedamage = DAMAGE_YES;
		missile.health = WEP_CVAR_SEC(hagar, health);
		missile.damageforcescale = WEP_CVAR_SEC(hagar, damageforcescale);
		missile.event_damage = W_Hagar_Damage;
		missile.damagedbycontents = TRUE;

		missile.touch = W_Hagar_Touch; // not bouncy
		missile.use = W_Hagar_Explode2;
		missile.think = adaptor_think2use_hittype_splash;
		missile.nextthink = time + WEP_CVAR_SEC(hagar, lifetime_min) + random() * WEP_CVAR_SEC(hagar, lifetime_rand);
		PROJECTILE_MAKETRIGGER(missile);
		missile.projectiledeathtype = WEP_HAGAR | HITTYPE_SECONDARY;
		setorigin (missile, w_shotorg);
		setsize(missile, '0 0 0', '0 0 0');
		missile.movetype = MOVETYPE_FLY;
		missile.missile_flags = MIF_SPLASH; 
		
		// per-shot spread calculation: the more shots there are, the less spread is applied (based on the bias cvar)
		spread_pershot = ((shots - 1) / (WEP_CVAR_SEC(hagar, load_max) - 1)); 
		spread_pershot = (1 - (spread_pershot * WEP_CVAR_SEC(hagar, load_spread_bias)));
		spread_pershot = (WEP_CVAR_SEC(hagar, spread) * spread_pershot * g_weaponspreadfactor);
		
		// pattern spread calculation
		s = '0 0 0';
		if (counter == 0)
			s = '0 0 0';
		else
		{
			makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
			s_y = v_forward_x;
			s_z = v_forward_y;
		}
		s = s * WEP_CVAR_SEC(hagar, load_spread) * g_weaponspreadfactor;
		
		W_SetupProjectileVelocityEx(missile, w_shotdir + right * s_y + up * s_z, v_up, WEP_CVAR_SEC(hagar, speed), 0, 0, spread_pershot, FALSE);

		missile.angles = vectoangles (missile.velocity);
		missile.flags = FL_PROJECTILE;

		CSQCProjectile(missile, TRUE, PROJECTILE_HAGAR, TRUE);

		other = missile; MUTATOR_CALLHOOK(EditProjectile);
	}

	weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(hagar, load_animtime), w_ready);
	self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, refire) * W_WeaponRateFactor();
	self.hagar_load = 0;
}

void W_Hagar_Attack2_Load (void)
{
	// loadable hagar secondary attack, must always run each frame
	
	if(time < game_starttime)
		return;

	float loaded, enough_ammo;
	loaded = self.hagar_load >= WEP_CVAR_SEC(hagar, load_max);

	// this is different than WR_CHECKAMMO when it comes to reloading
	if(autocvar_g_balance_hagar_reload_ammo)
		enough_ammo = self.(weapon_load[WEP_HAGAR]) >= WEP_CVAR_SEC(hagar, ammo);
	else
		enough_ammo = self.ammo_rockets >= WEP_CVAR_SEC(hagar, ammo);

	if(self.BUTTON_ATCK2)
	{
		if(self.BUTTON_ATCK && WEP_CVAR_SEC(hagar, load_abort))
		{
			if(self.hagar_load)
			{
				// if we pressed primary fire while loading, unload all rockets and abort
				self.weaponentity.state = WS_READY;
				W_DecreaseAmmo(ammo_rockets, WEP_CVAR_SEC(hagar, ammo) * self.hagar_load * -1, autocvar_g_balance_hagar_reload_ammo); // give back ammo
				self.hagar_load = 0;
				sound(self, CH_WEAPON_A, "weapons/hagar_beep.wav", VOL_BASE, ATTN_NORM);

				// pause until we can load rockets again, once we re-press the alt fire button
				self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_speed) * W_WeaponRateFactor();

				// require letting go of the alt fire button before we can load again
				self.hagar_loadblock = TRUE;
			}
		}
		else
		{
			// check if we can attempt to load another rocket
			if(!loaded && enough_ammo)
			{
				if(!self.hagar_loadblock && self.hagar_loadstep < time)
				{
					W_DecreaseAmmo(ammo_rockets, WEP_CVAR_SEC(hagar, ammo), autocvar_g_balance_hagar_reload_ammo);
					self.weaponentity.state = WS_INUSE;
					self.hagar_load += 1;
					sound(self, CH_WEAPON_B, "weapons/hagar_load.wav", VOL_BASE * 0.8, ATTN_NORM); // sound is too loud according to most

					if (self.hagar_load >= WEP_CVAR_SEC(hagar, load_max))
						self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_hold) * W_WeaponRateFactor();
					else
						self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_speed) * W_WeaponRateFactor();
				}
			}
			else if(!self.hagar_loadbeep && self.hagar_load) // prevents the beep from playing each frame
			{
				// if this is the last rocket we can load, play a beep sound to notify the player
				sound(self, CH_WEAPON_A, "weapons/hagar_beep.wav", VOL_BASE, ATTN_NORM);
				self.hagar_loadbeep = TRUE;
			}
		}
	}
	else if(self.hagar_loadblock)
	{
		// the alt fire button has been released, so re-enable loading if blocked
		self.hagar_loadblock = FALSE;
	}

	if(self.hagar_load)
	{
		// play warning sound if we're about to release
		if((loaded || !enough_ammo) && self.hagar_loadstep - 0.5 < time && WEP_CVAR_SEC(hagar, load_hold) >= 0)
		{
			if(!self.hagar_warning && self.hagar_load) // prevents the beep from playing each frame
			{
				// we're about to automatically release after holding time, play a beep sound to notify the player
				sound(self, CH_WEAPON_A, "weapons/hagar_beep.wav", VOL_BASE, ATTN_NORM);
				self.hagar_warning = TRUE;
			}
		}
		
		// release if player let go of button or if they've held it in too long
		if(!self.BUTTON_ATCK2 || ((loaded || !enough_ammo) && self.hagar_loadstep < time && WEP_CVAR_SEC(hagar, load_hold) >= 0))
		{
			self.weaponentity.state = WS_READY;
			W_Hagar_Attack2_Load_Release();
		}
	}
	else
	{
		self.hagar_loadbeep = FALSE;
		self.hagar_warning = FALSE;
	}

	// we aren't checking ammo during an attack, so we must do it here
	if(!WEP_ACTION(self.weapon, WR_CHECKAMMO1) + WEP_ACTION(self.weapon, WR_CHECKAMMO2))
	{
		// note: this doesn't force the switch
		W_SwitchToOtherWeapon(self);
		return;
	}
}

float w_hagar(float req)
{
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			if (random()>0.15)
				self.BUTTON_ATCK = bot_aim(WEP_CVAR_PRI(hagar, speed), 0, WEP_CVAR_PRI(hagar, lifetime), FALSE);
			else // not using secondary_speed since these are only 15% and should cause some ricochets without re-aiming
				self.BUTTON_ATCK2 = bot_aim(WEP_CVAR_PRI(hagar, speed), 0, WEP_CVAR_PRI(hagar, lifetime), FALSE);
				
			return TRUE;
		}
		case WR_THINK:
		{
			float loadable_secondary;
			loadable_secondary = (WEP_CVAR_SEC(hagar, load) && WEP_CVAR(hagar, secondary));

			if (loadable_secondary)
				W_Hagar_Attack2_Load(); // must always run each frame
			if(autocvar_g_balance_hagar_reload_ammo && self.clip_load < min(WEP_CVAR_PRI(hagar, ammo), WEP_CVAR_SEC(hagar, ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if (self.BUTTON_ATCK && !self.hagar_load && !self.hagar_loadblock) // not while secondary is loaded or awaiting reset
			{
				if (weapon_prepareattack(0, WEP_CVAR_PRI(hagar, refire)))
				{
					W_Hagar_Attack();
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(hagar, refire), w_ready);
				}
			}
			else if (self.BUTTON_ATCK2 && !loadable_secondary && WEP_CVAR(hagar, secondary))
			{
				if (weapon_prepareattack(1, WEP_CVAR_SEC(hagar, refire)))
				{
					W_Hagar_Attack2();
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(hagar, refire), w_ready);
				}
			}
			
			return TRUE;
		}
		case WR_GONETHINK:
		{
			// we lost the weapon and want to prepare switching away
			if(self.hagar_load)
			{
				self.weaponentity.state = WS_READY;
				W_Hagar_Attack2_Load_Release();
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model ("models/weapons/g_hagar.md3");
			precache_model ("models/weapons/v_hagar.md3");
			precache_model ("models/weapons/h_hagar.iqm");
			precache_sound ("weapons/hagar_fire.wav");
			precache_sound ("weapons/hagar_load.wav");
			precache_sound ("weapons/hagar_beep.wav");
			HAGAR_SETTINGS(WEP_SKIPCVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_rockets;
			self.hagar_loadblock = FALSE;

			if(self.hagar_load)
			{
				W_DecreaseAmmo(ammo_rockets, WEP_CVAR_SEC(hagar, ammo) * self.hagar_load * -1, autocvar_g_balance_hagar_reload_ammo); // give back ammo if necessary
				self.hagar_load = 0;
			}
			
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.ammo_rockets >= WEP_CVAR_PRI(hagar, ammo);
			ammo_amount += self.(weapon_load[WEP_HAGAR]) >= WEP_CVAR_PRI(hagar, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			ammo_amount = self.ammo_rockets >= WEP_CVAR_SEC(hagar, ammo);
			ammo_amount += self.(weapon_load[WEP_HAGAR]) >= WEP_CVAR_SEC(hagar, ammo);
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			HAGAR_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RESETPLAYER:
		{
			self.hagar_load = 0;
			return TRUE;
		}
		case WR_PLAYERDEATH:
		{
			// if we have any rockets loaded when we die, release them
			if(self.hagar_load && WEP_CVAR_SEC(hagar, load_releasedeath))
				W_Hagar_Attack2_Load_Release();
				
			return TRUE;
		}
		case WR_RELOAD:
		{
			if(!self.hagar_load) // require releasing loaded rockets first
				W_Reload(min(WEP_CVAR_PRI(hagar, ammo), WEP_CVAR_SEC(hagar, ammo)), "weapons/reload.wav");
				
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_HAGAR_SUICIDE;
		}
		case WR_KILLMESSAGE:
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_HAGAR_MURDER_BURST;
			else
				return WEAPON_HAGAR_MURDER_SPRAY;
		}
	}
	return TRUE;
}
#endif
#ifdef CSQC
float w_hagar(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum("hagar_explode"), org2, '0 0 0', 1);
			if(!w_issilent)
			{
				if (w_random<0.15)
					sound(self, CH_SHOTS, "weapons/hagexp1.wav", VOL_BASE, ATTN_NORM);
				else if (w_random<0.7)
					sound(self, CH_SHOTS, "weapons/hagexp2.wav", VOL_BASE, ATTN_NORM);
				else
					sound(self, CH_SHOTS, "weapons/hagexp3.wav", VOL_BASE, ATTN_NORM);
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/hagexp1.wav");
			precache_sound("weapons/hagexp2.wav");
			precache_sound("weapons/hagexp3.wav");
			return TRUE;
		}
	}
	return TRUE;
}
#endif
#endif
