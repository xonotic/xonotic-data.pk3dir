#ifdef REGISTER_WEAPON
REGISTER_WEAPON(HAGAR, w_hagar, IT_ROCKETS, 8, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_MID, "hagar", "hagar", _("Hagar"))
#else
#ifdef SVQC
// NO bounce protection, as bounces are limited!

void W_Hagar_Explode (void)
{
	self.event_damage = SUB_Null;
	RadiusDamage (self, self.realowner, autocvar_g_balance_hagar_primary_damage, autocvar_g_balance_hagar_primary_edgedamage, autocvar_g_balance_hagar_primary_radius, world, autocvar_g_balance_hagar_primary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Hagar_Explode2 (void)
{
	self.event_damage = SUB_Null;
	RadiusDamage (self, self.realowner, autocvar_g_balance_hagar_secondary_damage, autocvar_g_balance_hagar_secondary_edgedamage, autocvar_g_balance_hagar_secondary_radius, world, autocvar_g_balance_hagar_secondary_force, self.projectiledeathtype, other);

	remove (self);
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
	local entity missile;

	W_DecreaseAmmo(ammo_rockets, autocvar_g_balance_hagar_primary_ammo, autocvar_g_balance_hagar_reload_ammo);

	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", CHAN_WEAPON, autocvar_g_balance_hagar_primary_damage);

	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "missile";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = autocvar_g_balance_hagar_primary_damage;
	missile.touch = W_Hagar_Touch;
	missile.use = W_Hagar_Explode;
	missile.think = adaptor_think2use_hittype_splash;
	missile.nextthink = time + autocvar_g_balance_hagar_primary_lifetime;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR;
	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	missile.movetype = MOVETYPE_FLY;
	W_SETUPPROJECTILEVELOCITY(missile, g_balance_hagar_primary);

	missile.angles = vectoangles (missile.velocity);
	missile.flags = FL_PROJECTILE;

	CSQCProjectile(missile, TRUE, PROJECTILE_HAGAR, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void W_Hagar_Attack2 (void)
{
	local entity missile;

	W_DecreaseAmmo(ammo_rockets, autocvar_g_balance_hagar_secondary_ammo, autocvar_g_balance_hagar_reload_ammo);

	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", CHAN_WEAPON, autocvar_g_balance_hagar_secondary_damage);

	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "missile";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = autocvar_g_balance_hagar_secondary_damage;
	missile.touch = W_Hagar_Touch2;
	missile.cnt = 0;
	missile.use = W_Hagar_Explode2;
	missile.think = adaptor_think2use_hittype_splash;
	missile.nextthink = time + autocvar_g_balance_hagar_secondary_lifetime_min + random() * autocvar_g_balance_hagar_secondary_lifetime_rand;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR | HITTYPE_SECONDARY;
	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	missile.movetype = MOVETYPE_BOUNCEMISSILE;
	W_SETUPPROJECTILEVELOCITY(missile, g_balance_hagar_secondary);

	missile.angles = vectoangles (missile.velocity);
	missile.flags = FL_PROJECTILE;

	CSQCProjectile(missile, TRUE, PROJECTILE_HAGAR_BOUNCING, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

.float hagar_loadstep, hagar_loadblock;
void W_Hagar_Attack2_Load_Release (void)
{
	// time to release the rockets we've loaded

	local entity missile;
	local float counter, shots;
	local vector s;
	vector forward, right, up;

	if(!self.hagar_load)
		return;

	W_DecreaseAmmo(ammo_rockets, autocvar_g_balance_hagar_secondary_ammo * self.hagar_load, autocvar_g_balance_hagar_reload_ammo);

	W_SetupShot (self, FALSE, 2, "weapons/hagar_fire.wav", CHAN_WEAPON, autocvar_g_balance_hagar_secondary_damage);
	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	forward = v_forward;
	right = v_right;
	up = v_up;

	shots = self.hagar_load;
	missile = world;
	while (counter < shots)
	{
		missile = spawn ();
		missile.owner = missile.realowner = self;
		missile.classname = "missile";
		missile.bot_dodge = TRUE;
		missile.bot_dodgerating = autocvar_g_balance_hagar_secondary_damage;

		missile.touch = W_Hagar_Touch; // not bouncy
		missile.use = W_Hagar_Explode2;
		missile.think = adaptor_think2use_hittype_splash;
		missile.nextthink = time + autocvar_g_balance_hagar_secondary_lifetime_min + random() * autocvar_g_balance_hagar_secondary_lifetime_rand;
		PROJECTILE_MAKETRIGGER(missile);
		missile.projectiledeathtype = WEP_HAGAR;
		setorigin (missile, w_shotorg);
		setsize(missile, '0 0 0', '0 0 0');
		missile.movetype = MOVETYPE_FLY;

		s = '0 0 0';
		if (counter == 0)
			s = '0 0 0';
		else
		{
			makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
			s_y = v_forward_x;
			s_z = v_forward_y;
		}
		s = s * cvar("g_balance_hagar_secondary_spread") * g_weaponspreadfactor;
		W_SetupProjectileVelocityEx(missile, w_shotdir + right * s_y + up * s_z, v_up, cvar("g_balance_hagar_secondary_speed"), 0, 0, 0, FALSE);

		missile.angles = vectoangles (missile.velocity);
		missile.flags = FL_PROJECTILE;

		CSQCProjectile(missile, TRUE, PROJECTILE_HAGAR, TRUE);

		other = missile; MUTATOR_CALLHOOK(EditProjectile);

		counter = counter + 1;
	}

	weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_hagar_secondary_refire, w_ready);
	self.hagar_loadstep = time + autocvar_g_balance_hagar_secondary_refire;
	self.hagar_load = 0;
}

void W_Hagar_Attack2_Load (void)
{
	// loadable hagar secondary attack, must always run each frame

	if not(weapon_action(self.weapon, WR_CHECKAMMO2))
	{
		W_SwitchToOtherWeapon(self);
		return;
	}

	local float loaded;
	local float used_ammo, enough_ammo;

	loaded = self.hagar_load >= autocvar_g_balance_hagar_secondary_load_max;

	// check if we have enough ammo for another rocket
	used_ammo = autocvar_g_balance_hagar_secondary_ammo;
	if(autocvar_g_balance_hagar_reload_ammo)
		enough_ammo = self.weapon_load[WEP_HAGAR] >= used_ammo + (used_ammo * self.hagar_load);
	else
		enough_ammo = self.ammo_rockets >= used_ammo + (used_ammo * self.hagar_load);

	if(self.BUTTON_ATCK2)
	{
		if(self.BUTTON_ATCK && autocvar_g_balance_hagar_secondary_load_abort)
		{
			if(self.hagar_load)
			{
				// if we pressed primary fire while loading, unload all rockets and abort
				self.hagar_load = 0;
				sound(self, CHAN_WEAPON, "weapons/hagar_beep.wav", VOL_BASE, ATTN_NORM);

				// pause until we can load rockets again, once we re-press the alt fire button
				self.hagar_loadstep = time + autocvar_g_balance_hagar_secondary_load_speed;

				// require letting go of the alt fire button before we can load again
				self.hagar_loadblock = TRUE;
			}
		}
		else
		{
			// check if we can attempt to load another rocket
			if(!self.hagar_loadblock && !loaded && enough_ammo)
			if(self.hagar_loadstep < time)
			{
				self.hagar_load += 1;
				sound(self, CHAN_WEAPON2, "weapons/hagar_load.wav", VOL_BASE, ATTN_NORM);

				// if this is the last rocket we can load, play the beep sound to notify the player of that
				if(self.hagar_load >= autocvar_g_balance_hagar_secondary_load_max)
					sound(self, CHAN_WEAPON, "weapons/hagar_beep.wav", VOL_BASE, ATTN_NORM);

				self.hagar_loadstep = time + autocvar_g_balance_hagar_secondary_load_speed;
			}
		}
	}
	else if(self.hagar_loadblock)
	{
		// the alt fire button was released, so re-enable loading if blocked
		self.hagar_loadblock = FALSE;
	}

	if(self.hagar_load)
	if(!self.BUTTON_ATCK2 || ((loaded || !enough_ammo) && self.hagar_loadstep < time && !autocvar_g_balance_hagar_secondary_load_hold))
	if(weapon_prepareattack(0, autocvar_g_balance_hagar_secondary_refire))
		W_Hagar_Attack2_Load_Release();
}

void spawnfunc_weapon_hagar (void)
{
	weapon_defaultspawnfunc(WEP_HAGAR);
}

float w_hagar(float req)
{
	float ammo_amount;
	if (req == WR_AIM)
		if (random()>0.15)
			self.BUTTON_ATCK = bot_aim(autocvar_g_balance_hagar_primary_speed, 0, autocvar_g_balance_hagar_primary_lifetime, FALSE);
		else
		{
			// not using secondary_speed since these are only 15% and should cause some ricochets without re-aiming
			self.BUTTON_ATCK2 = bot_aim(autocvar_g_balance_hagar_primary_speed, 0, autocvar_g_balance_hagar_primary_lifetime, FALSE);
		}
	else if (req == WR_THINK)
	{
		if(autocvar_g_balance_hagar_reload_ammo && self.clip_load < min(autocvar_g_balance_hagar_primary_ammo, autocvar_g_balance_hagar_secondary_ammo)) // forced reload
			weapon_action(self.weapon, WR_RELOAD);
		else
		{
			local float loadable_secondary;
			loadable_secondary = autocvar_g_balance_hagar_secondary_load && autocvar_g_balance_hagar_secondary;

			if (loadable_secondary)
				W_Hagar_Attack2_Load(); // must run each frame, even when no firing buttons are pressed
			if (self.BUTTON_ATCK && !self.hagar_load && !self.hagar_loadblock) // not while secondary is loaded or awaiting reset
			{
				if (weapon_prepareattack(0, autocvar_g_balance_hagar_primary_refire))
				{
					W_Hagar_Attack();
					weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_hagar_primary_refire, w_ready);
				}
			}
			else if (self.BUTTON_ATCK2 && !loadable_secondary && autocvar_g_balance_hagar_secondary)
			{
				if (weapon_prepareattack(1, autocvar_g_balance_hagar_secondary_refire))
				{
					W_Hagar_Attack2();
					weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_hagar_secondary_refire, w_ready);
				}
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_hagar.md3");
		precache_model ("models/weapons/v_hagar.md3");
		precache_model ("models/weapons/h_hagar.iqm");
		precache_sound ("weapons/hagar_fire.wav");
		precache_sound ("weapons/hagar_load.wav");
		precache_sound ("weapons/hagar_beep.wav");
		//precache_sound ("weapons/reload.wav"); // until weapons have individual reload sounds, precache the reload sound somewhere else
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_HAGAR);
		self.current_ammo = ammo_rockets;
		self.hagar_load = 0;
	}
	else if (req == WR_CHECKAMMO1)
	{
		ammo_amount = self.ammo_rockets >= autocvar_g_balance_hagar_primary_ammo;
		ammo_amount += self.weapon_load[WEP_HAGAR] >= autocvar_g_balance_hagar_primary_ammo;
		return ammo_amount;
	}
	else if (req == WR_CHECKAMMO2)
	{
		ammo_amount = self.ammo_rockets >= autocvar_g_balance_hagar_secondary_ammo;
		ammo_amount += self.weapon_load[WEP_HAGAR] >= autocvar_g_balance_hagar_secondary_ammo;
		return ammo_amount;
	}
	else if (req == WR_PLAYERDEATH)
	{
		// if we have any rockets loaded when we die, release them
		if(self.hagar_load)
			W_Hagar_Attack2_Load_Release();
	}
	else if (req == WR_RELOAD)
	{
		W_Reload(min(autocvar_g_balance_hagar_primary_ammo, autocvar_g_balance_hagar_secondary_ammo), autocvar_g_balance_hagar_reload_ammo, autocvar_g_balance_hagar_reload_time, "weapons/reload.wav");
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_hagar(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		pointparticles(particleeffectnum("hagar_explode"), org2, '0 0 0', 1);
		if(!w_issilent)
		{
			if (w_random<0.15)
				sound(self, CHAN_PROJECTILE, "weapons/hagexp1.wav", VOL_BASE, ATTN_NORM);
			else if (w_random<0.7)
				sound(self, CHAN_PROJECTILE, "weapons/hagexp2.wav", VOL_BASE, ATTN_NORM);
			else
				sound(self, CHAN_PROJECTILE, "weapons/hagexp3.wav", VOL_BASE, ATTN_NORM);
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/hagexp1.wav");
		precache_sound("weapons/hagexp2.wav");
		precache_sound("weapons/hagexp3.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = _("%s played with tiny rockets");
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_BOUNCE) // must be secondary; unchecked: SPLASH
			w_deathtypestring = _("%s hoped %s's missiles wouldn't bounce");
		else // unchecked: SPLASH, SECONDARY
			w_deathtypestring = _("%s was pummeled by %s");
	}
	return TRUE;
}
#endif
#endif
