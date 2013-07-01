#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ HLAC,
/* function */ w_hlac,
/* ammotype */ IT_CELLS,
/* impulse  */ 6,
/* flags    */ WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH,
/* rating   */ BOT_PICKUP_RATING_MID,
/* model    */ "hlac",
/* netname  */ "hlac",
/* fullname */ _("Heavy Laser Assault Cannon")
);

#define HLAC_SETTINGS(weapon) \
	WEP_ADD_CVAR(weapon, MO_BOTH, ammo) \
	WEP_ADD_CVAR(weapon, MO_BOTH, animtime) \
	WEP_ADD_CVAR(weapon, MO_BOTH, damage) \
	WEP_ADD_CVAR(weapon, MO_BOTH, edgedamage) \
	WEP_ADD_CVAR(weapon, MO_BOTH, force) \
	WEP_ADD_CVAR(weapon, MO_BOTH, lifetime) \
	WEP_ADD_CVAR(weapon, MO_BOTH, radius) \
	WEP_ADD_CVAR(weapon, MO_BOTH, refire) \
	WEP_ADD_CVAR(weapon, MO_BOTH, speed) \
	WEP_ADD_CVAR(weapon, MO_BOTH, spread_crouchmod) \
	WEP_ADD_CVAR(weapon, MO_PRI,  spread_add) \
	WEP_ADD_CVAR(weapon, MO_PRI,  spread_max) \
	WEP_ADD_CVAR(weapon, MO_PRI,  spread_min) \
	WEP_ADD_CVAR(weapon, MO_NONE, secondary) \
	WEP_ADD_CVAR(weapon, MO_SEC,  shots) \
	WEP_ADD_CVAR(weapon, MO_SEC,  spread) \
	WEP_ADD_PROP(weapon, reloading_ammo, reload_ammo) \
	WEP_ADD_PROP(weapon, reloading_time, reload_time) \
	WEP_ADD_PROP(weapon, switchdelay_raise, switchdelay_raise) \
	WEP_ADD_PROP(weapon, switchdelay_drop, switchdelay_drop)

#ifdef SVQC
HLAC_SETTINGS(hlac)
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_hlac() { weapon_defaultspawnfunc(WEP_HLAC); }

void W_HLAC_Touch (void)
{
	float isprimary;

	PROJECTILE_TOUCH;

	self.event_damage = func_null;
	
	isprimary = !(self.projectiledeathtype & HITTYPE_SECONDARY);
	
	RadiusDamage(self, self.realowner, WEP_CVAR_BOTH(hlac, isprimary, damage), WEP_CVAR_BOTH(hlac, isprimary, edgedamage), WEP_CVAR_BOTH(hlac, isprimary, radius), world, world, WEP_CVAR_BOTH(hlac, isprimary, force), self.projectiledeathtype, other);

	remove (self);
}

void W_HLAC_Attack (void)
{
	entity missile;
    float spread;

	W_DecreaseAmmo(ammo_cells, WEP_CVAR_PRI(hlac, ammo), autocvar_g_balance_hlac_reload_ammo);

    spread = WEP_CVAR_PRI(hlac, spread_min) + (WEP_CVAR_PRI(hlac, spread_add) * self.misc_bulletcounter);
    spread = min(spread,WEP_CVAR_PRI(hlac, spread_max));
    if(self.crouch)
        spread = spread * WEP_CVAR_PRI(hlac, spread_crouchmod);

	W_SetupShot (self, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_A, WEP_CVAR_PRI(hlac, damage));
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);
	if (!g_norecoil)
	{
		self.punchangle_x = random () - 0.5;
		self.punchangle_y = random () - 0.5;
	}

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = TRUE;

    missile.bot_dodgerating = WEP_CVAR_PRI(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjectileVelocity(missile, WEP_CVAR_PRI(hlac, speed), spread);
	//missile.angles = vectoangles (missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + WEP_CVAR_PRI(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.projectiledeathtype = WEP_HLAC;

	CSQCProjectile(missile, TRUE, PROJECTILE_HLAC, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void W_HLAC_Attack2f (void)
{
	entity missile;
    float spread;

    spread = WEP_CVAR_SEC(hlac, spread);


    if(self.crouch)
        spread = spread * WEP_CVAR_SEC(hlac, spread_crouchmod);

	W_SetupShot (self, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_A, WEP_CVAR_SEC(hlac, damage));
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = TRUE;

    missile.bot_dodgerating = WEP_CVAR_SEC(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjectileVelocity(missile, WEP_CVAR_SEC(hlac, speed), spread);
	//missile.angles = vectoangles (missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + WEP_CVAR_SEC(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH; 
	missile.projectiledeathtype = WEP_HLAC | HITTYPE_SECONDARY;

	CSQCProjectile(missile, TRUE, PROJECTILE_HLAC, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void W_HLAC_Attack2 (void)
{
    float i;

	W_DecreaseAmmo(ammo_cells, WEP_CVAR_SEC(hlac, ammo), autocvar_g_balance_hlac_reload_ammo);

    for(i=WEP_CVAR_SEC(hlac, shots);i>0;--i)
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
		if (!WEP_ACTION(self.weapon, WR_CHECKAMMO1))
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		{
			W_SwitchWeapon_Force(self, w_getbestweapon(self));
			w_ready();
			return;
		}

		ATTACK_FINISHED(self) = time + WEP_CVAR_PRI(hlac, refire) * W_WeaponRateFactor();
		W_HLAC_Attack();
		self.misc_bulletcounter = self.misc_bulletcounter + 1;
        weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), HLAC_fire1_02);
	}
	else
	{
		weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(hlac, animtime), w_ready);
	}
}

float w_hlac(float req)
{
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			self.BUTTON_ATCK = bot_aim(WEP_CVAR_PRI(hlac, speed), 0, WEP_CVAR_PRI(hlac, lifetime), FALSE);
			return TRUE;
		}
		case WR_THINK:
		{
			if(autocvar_g_balance_hlac_reload_ammo && self.clip_load < min(WEP_CVAR_PRI(hlac, ammo), WEP_CVAR_SEC(hlac, ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if (self.BUTTON_ATCK)
			{
				if (weapon_prepareattack(0, WEP_CVAR_PRI(hlac, refire)))
				{
					self.misc_bulletcounter = 0;
					W_HLAC_Attack();
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), HLAC_fire1_02);
				}
			}

			else if (self.BUTTON_ATCK2 && WEP_CVAR(hlac, secondary))
			{
				if (weapon_prepareattack(1, WEP_CVAR_SEC(hlac, refire)))
				{
					W_HLAC_Attack2();
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(hlac, animtime), w_ready);
				}
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model ("models/weapons/g_hlac.md3");
			precache_model ("models/weapons/v_hlac.md3");
			precache_model ("models/weapons/h_hlac.iqm");
			precache_sound ("weapons/lasergun_fire.wav");
			WEP_SET_PROPS(HLAC_SETTINGS(hlac), WEP_HLAC)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_cells;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.ammo_cells >= WEP_CVAR_PRI(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC]) >= WEP_CVAR_PRI(hlac, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			ammo_amount = self.ammo_cells >= WEP_CVAR_SEC(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC]) >= WEP_CVAR_SEC(hlac, ammo);
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			WEP_CONFIG_SETTINGS(HLAC_SETTINGS(hlac))
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_Reload(min(WEP_CVAR_PRI(hlac, ammo), WEP_CVAR_SEC(hlac, ammo)), autocvar_g_balance_hlac_reload_ammo, autocvar_g_balance_hlac_reload_time, "weapons/reload.wav");
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_HLAC_SUICIDE;
		}
		case WR_KILLMESSAGE:
		{
			return WEAPON_HLAC_MURDER;
		}
	}
	return TRUE;
}
#endif
#ifdef CSQC
float w_hlac(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum("laser_impact"), org2, w_backoff * 1000, 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
				
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/laserimpact.wav");
			return TRUE;
		}
	}
	return TRUE;
}
#endif
#endif
