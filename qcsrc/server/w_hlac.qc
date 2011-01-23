#ifdef REGISTER_WEAPON
REGISTER_WEAPON(HLAC, w_hlac, IT_CELLS, 6, WEP_FLAG_NORMAL | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_MID, "hlac", "hlac", _("Heavy Laser Assault Cannon"))
#else
#ifdef SVQC

// weapon load persistence, for weapons that support reloading
.float hlac_load;

void W_HLAC_SetAmmoCounter()
{
	// set clip_load to the weapon we have switched to, if the gun uses reloading
	if(!autocvar_g_balance_hlac_reload_ammo)
		self.clip_load = 0; // also keeps crosshair ammo from displaying
	else
	{
		self.clip_load = self.hlac_load;
		self.clip_size = autocvar_g_balance_hlac_reload_ammo; // for the crosshair ammo display
	}
}

void W_HLAC_ReloadedAndReady()
{
	float t;

	// now do the ammo transfer
	self.clip_load = self.old_clip_load; // restore the ammo counter, in case we still had ammo in the weapon before reloading
	while(self.clip_load < autocvar_g_balance_hlac_reload_ammo && self.ammo_cells) // make sure we don't add more ammo than we have
	{
		self.clip_load += 1;
		self.ammo_cells -= 1;
	}
	self.hlac_load = self.clip_load;

	t = ATTACK_FINISHED(self) - autocvar_g_balance_hlac_reload_time - 1;
	ATTACK_FINISHED(self) = t;
	w_ready();
}

void W_HLAC_Reload()
{
	// return if reloading is disabled for this weapon
	if(!autocvar_g_balance_hlac_reload_ammo)
		return;

	if(!W_ReloadCheck(self.ammo_cells, min(autocvar_g_balance_hlac_primary_ammo, autocvar_g_balance_hlac_secondary_ammo)))
		return;

	float t;

	sound (self, CHAN_WEAPON2, "weapons/reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + autocvar_g_balance_hlac_reload_time + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, autocvar_g_balance_hlac_reload_time, W_HLAC_ReloadedAndReady);

	self.old_clip_load = self.clip_load;
	self.clip_load = -1;
}

void W_HLAC_Touch (void)
{
	PROJECTILE_TOUCH;

	self.event_damage = SUB_Null;
	
	if(self.projectiledeathtype & HITTYPE_SECONDARY)
		RadiusDamage (self, self.owner, autocvar_g_balance_hlac_secondary_damage, autocvar_g_balance_hlac_secondary_edgedamage, autocvar_g_balance_hlac_secondary_radius, world, autocvar_g_balance_hlac_secondary_force, self.projectiledeathtype, other);
	else
		RadiusDamage (self, self.owner, autocvar_g_balance_hlac_primary_damage, autocvar_g_balance_hlac_primary_edgedamage, autocvar_g_balance_hlac_primary_radius, world, autocvar_g_balance_hlac_primary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_HLAC_Attack (void)
{
	local entity missile;
    float spread;

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(autocvar_g_balance_hlac_reload_ammo)
		{
			self.clip_load -= autocvar_g_balance_hlac_primary_ammo;
			self.hlac_load = self.clip_load;
		}
		else
			self.ammo_cells -= autocvar_g_balance_hlac_primary_ammo;
	}

    spread = autocvar_g_balance_hlac_primary_spread_min + (autocvar_g_balance_hlac_primary_spread_add * self.misc_bulletcounter);
    spread = min(spread,autocvar_g_balance_hlac_primary_spread_max);
    if(self.crouch)
        spread = spread * autocvar_g_balance_hlac_primary_spread_crouchmod;

	W_SetupShot (self, FALSE, 3, "weapons/lasergun_fire.wav", CHAN_WEAPON, autocvar_g_balance_hlac_primary_damage);
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);
	if (!g_norecoil)
	{
		self.punchangle_x = random () - 0.5;
		self.punchangle_y = random () - 0.5;
	}

	missile = spawn ();
	missile.owner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = TRUE;

    missile.bot_dodgerating = autocvar_g_balance_hlac_primary_damage;

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjectileVelocity(missile, autocvar_g_balance_hlac_primary_speed, spread);
	//missile.angles = vectoangles (missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + autocvar_g_balance_hlac_primary_lifetime;

	missile.flags = FL_PROJECTILE;
	missile.projectiledeathtype = WEP_HLAC;

	CSQCProjectile(missile, TRUE, PROJECTILE_HLAC, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void W_HLAC_Attack2f (void)
{
	local entity missile;
    float spread;

    spread = autocvar_g_balance_hlac_secondary_spread;


    if(self.crouch)
        spread = spread * autocvar_g_balance_hlac_secondary_spread_crouchmod;

	W_SetupShot (self, FALSE, 3, "weapons/lasergun_fire.wav", CHAN_WEAPON, autocvar_g_balance_hlac_secondary_damage);
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = TRUE;

    missile.bot_dodgerating = autocvar_g_balance_hlac_secondary_damage;

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjectileVelocity(missile, autocvar_g_balance_hlac_secondary_speed, spread);
	//missile.angles = vectoangles (missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + autocvar_g_balance_hlac_secondary_lifetime;

	missile.flags = FL_PROJECTILE;
	missile.projectiledeathtype = WEP_HLAC | HITTYPE_SECONDARY;

	CSQCProjectile(missile, TRUE, PROJECTILE_HLAC, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void W_HLAC_Attack2 (void)
{
    float i;

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(autocvar_g_balance_hlac_reload_ammo)
		{
			self.clip_load -= autocvar_g_balance_hlac_secondary_ammo;
			self.hlac_load = self.clip_load;
		}
		else
			self.ammo_cells -= autocvar_g_balance_hlac_secondary_ammo;
	}

    for(i=autocvar_g_balance_hlac_secondary_shots;i>0;--i)
        W_HLAC_Attack2f();

	if (!g_norecoil)
	{
		self.punchangle_x = random () - 0.5;
		self.punchangle_y = random () - 0.5;
	}
}

// weapon frames
void HLAC_fire1_02()
{
	if(self.weapon != self.switchweapon) // abort immediately if switching
	{
		w_ready();
		return;
	}

	if (self.BUTTON_ATCK)
	{
		if (!weapon_action(self.weapon, WR_CHECKAMMO1))
		{
			W_SwitchWeapon_Force(self, w_getbestweapon(self));
			w_ready();
			return;
		}

		ATTACK_FINISHED(self) = time + autocvar_g_balance_hlac_primary_refire * W_WeaponRateFactor();
		W_HLAC_Attack();
		self.misc_bulletcounter = self.misc_bulletcounter + 1;
        weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_hlac_primary_refire, HLAC_fire1_02);
	}
	else
	{
		weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_hlac_primary_animtime, w_ready);
	}
};

void spawnfunc_weapon_hlac (void)
{
	weapon_defaultspawnfunc(WEP_HLAC);
}

float w_hlac(float req)
{
	float ammo_amount;
	if (req == WR_AIM)
        self.BUTTON_ATCK = bot_aim(autocvar_g_balance_hlac_primary_speed, 0, autocvar_g_balance_hlac_primary_lifetime, FALSE);
	else if (req == WR_THINK)
	{
		if(autocvar_g_balance_hlac_reload_ammo && self.clip_load < min(autocvar_g_balance_hlac_primary_ammo, autocvar_g_balance_hlac_secondary_ammo)) // forced reload
			W_HLAC_Reload();
		else if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, autocvar_g_balance_hlac_primary_refire))
			{
				self.misc_bulletcounter = 0;
				W_HLAC_Attack();
				weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_hlac_primary_refire, HLAC_fire1_02);
			}
		}

		else if (self.BUTTON_ATCK2 && autocvar_g_balance_hlac_secondary)
		{
			if (weapon_prepareattack(1, autocvar_g_balance_hlac_secondary_refire))
			{
				W_HLAC_Attack2();
				weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_hlac_secondary_animtime, w_ready);
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
        precache_model ("models/weapons/g_hlac.md3");
		precache_model ("models/weapons/v_hlac.md3");
		precache_model ("models/weapons/h_hlac.iqm");
		precache_sound ("weapons/lasergun_fire.wav");
		precache_sound ("weapons/reload.wav");

	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_HLAC);
		W_HLAC_SetAmmoCounter();
	}
	else if (req == WR_CHECKAMMO1)
	{
		ammo_amount = self.ammo_cells >= autocvar_g_balance_hlac_primary_ammo;
		ammo_amount += (autocvar_g_balance_hlac_reload_ammo && self.hlac_load >= autocvar_g_balance_hlac_primary_ammo);
		return ammo_amount;
	}
	else if (req == WR_CHECKAMMO2)
	{
		ammo_amount = self.ammo_cells >= autocvar_g_balance_hlac_secondary_ammo;
		ammo_amount += (autocvar_g_balance_hlac_reload_ammo && self.hlac_load >= autocvar_g_balance_hlac_secondary_ammo);
		return ammo_amount;
	}
	else if (req == WR_RESETPLAYER)
	{
		// all weapons must be fully loaded when we spawn
		self.hlac_load = autocvar_g_balance_hlac_reload_ammo;
	}
	else if (req == WR_RELOAD)
	{
		W_HLAC_Reload();
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_hlac(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		pointparticles(particleeffectnum("laser_impact"), org2, w_backoff * 1000, 1);
		if(!w_issilent)
			sound(self, CHAN_PROJECTILE, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/laserimpact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "%s should have used a smaller gun";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "%s was cut down by %s";
	return TRUE;
}
#endif
#endif
