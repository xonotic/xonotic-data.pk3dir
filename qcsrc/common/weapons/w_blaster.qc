#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ BLASTER,
/* function */ W_Blaster,
/* ammotype */ 0,
/* impulse  */ 1,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH,
/* rating   */ 0,
/* model    */ "laser",
/* netname  */ "laser",
/* fullname */ _("Blaster")
);

#define BLASTER_SETTINGS(w_cvar,w_prop) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, ammo) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, animtime) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, damage) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, delay) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, edgedamage) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, force) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, lifetime) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, radius) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, refire) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, shotangle) \
	w_cvar(WEP_BLASTER, blaster, MO_BOTH, speed) \
	w_cvar(WEP_BLASTER, blaster, MO_NONE, secondary) \
	w_prop(WEP_BLASTER, blaster, reloading_ammo, reload_ammo) \
	w_prop(WEP_BLASTER, blaster, reloading_time, reload_time) \
	w_prop(WEP_BLASTER, blaster, switchdelay_raise, switchdelay_raise) \
	w_prop(WEP_BLASTER, blaster, switchdelay_drop, switchdelay_drop)

#ifdef SVQC
BLASTER_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#define PROJISPRIMARY(ent) ent.dmg
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_blaster() { weapon_defaultspawnfunc(WEP_BLASTER); }
void spawnfunc_weapon_laser() { spawnfunc_weapon_blaster(); }

void W_Blaster_Touch()
{
	PROJECTILE_TOUCH;

	self.event_damage = func_null;

	if(PROJISPRIMARY(self))
	{
		RadiusDamage(
			self,
			self.realowner,
			WEP_CVAR_PRI(blaster, damage),
			WEP_CVAR_PRI(blaster, edgedamage),
			WEP_CVAR_PRI(blaster, radius),
			world,
			world,
			WEP_CVAR_PRI(blaster, force),
			self.projectiledeathtype,
			other
		);
	}
	else
	{
		RadiusDamage(
			self,
			self.realowner,
			WEP_CVAR_SEC(blaster, damage),
			WEP_CVAR_SEC(blaster, edgedamage),
			WEP_CVAR_SEC(blaster, radius),
			world,
			world,
			WEP_CVAR_SEC(blaster, force),
			self.projectiledeathtype,
			other
		);
	}
	
	remove(self);
}

void W_Blaster_Think()
{
	self.movetype = MOVETYPE_FLY;
	self.think = SUB_Remove;
	self.nextthink = time + WEP_CVAR_BOTH(blaster, PROJISPRIMARY(self), lifetime);
	CSQCProjectile(self, TRUE, PROJECTILE_BLASTER, TRUE);
}

void W_Blaster_Attack(float isprimary)
{
	float a = WEP_CVAR_BOTH(blaster, isprimary, shotangle);
	vector s_forward = v_forward * cos(a * DEG2RAD) + v_up * sin(a * DEG2RAD);

	W_SetupShot_Dir(self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, WEP_CVAR_BOTH(blaster, isprimary, damage));
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	entity missile = spawn();
	missile.owner = missile.realowner = self;
	missile.classname = "laserbolt"; // WEAPONTODO
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = WEP_CVAR_BOTH(blaster, isprimary, damage);
	PROJISPRIMARY(missile) = isprimary;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');
	WEP_SETUPPROJVELOCITY(missile, blaster, MO_BOTH, isprimary);
	missile.angles = vectoangles(missile.velocity);
	
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;

	missile.touch = W_Blaster_Touch;
	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;
	missile.projectiledeathtype = WEP_BLASTER; 
	missile.think = W_Blaster_Think;
	missile.nextthink = time + WEP_CVAR_BOTH(blaster, isprimary, delay);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);

	if(time >= missile.nextthink)
	{
		entity oldself;
		oldself = self;
		self = missile;
		self.think();
		self = oldself;
	}
}
float W_Blaster(float request)
{
	switch(request)
	{
		case WR_AIM:
		{
			if(autocvar_g_balance_laser_secondary)
			{
				if((random() * (autocvar_g_balance_laser_primary_damage + autocvar_g_balance_laser_secondary_damage)) > autocvar_g_balance_laser_primary_damage)
					{ self.BUTTON_ATCK2 = bot_aim(autocvar_g_balance_laser_secondary_speed, 0, autocvar_g_balance_laser_secondary_lifetime, FALSE); }
				else
					{ self.BUTTON_ATCK = bot_aim(autocvar_g_balance_laser_primary_speed, 0, autocvar_g_balance_laser_primary_lifetime, FALSE); }
			}
			else
				{ self.BUTTON_ATCK = bot_aim(autocvar_g_balance_laser_primary_speed, 0, autocvar_g_balance_laser_primary_lifetime, FALSE); }

			return TRUE;
		}
		
		case WR_THINK:
		{
			if(autocvar_g_balance_laser_reload_ammo && self.clip_load < 1) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if(self.BUTTON_ATCK)
			{
				if(weapon_prepareattack(0, autocvar_g_balance_laser_primary_refire))
				{
					W_DecreaseAmmo(ammo_none, 1, TRUE); // WEAPONTODO is this necessary?
					W_Blaster_Attack(FALSE);
					weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_laser_primary_animtime, w_ready);
				}
			}
			else if(self.BUTTON_ATCK2)
			{
				switch(autocvar_g_balance_laser_secondary)
				{
					case 0: // switch to last used weapon
					{
						if(self.switchweapon == WEP_LASER) // don't do this if already switching
							W_LastWeapon();
						break;
					}

					case 1: // normal projectile secondary
					{
						if(weapon_prepareattack(1, autocvar_g_balance_laser_secondary_refire))
						{
							W_DecreaseAmmo(ammo_none, 1, TRUE);
							W_Blaster_Attack(TRUE);
							weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_laser_secondary_animtime, w_ready);
						}

						break;
					}
				}
			}
			return TRUE;
		}
		
		case WR_INIT: 
		{
			precache_model("models/weapons/g_laser.md3");
			precache_model("models/weapons/v_laser.md3");
			precache_model("models/weapons/h_laser.iqm");
			precache_sound("weapons/lasergun_fire.wav");
			return TRUE;
		}
		
		case WR_SETUP:
		{
			self.current_ammo = ammo_none;
			return TRUE;
		}
		
		case WR_CHECKAMMO1:
		case WR_CHECKAMMO2:
		{
			return TRUE; // laser has infinite ammo
		}
		
		case WR_RELOAD:
		{
			W_Reload(0, "weapons/reload.wav");
			return TRUE;
		}
		
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_LASER_SUICIDE;
		}
		
		case WR_KILLMESSAGE:
		{
			return WEAPON_LASER_MURDER;
		}
	}
	
	return TRUE;
}
#endif
#ifdef CSQC
float W_Blaster(float request)
{
	switch(request)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum("new_laser_impact"), org2, w_backoff * 1000, 1);
			if(!w_issilent) { sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM); }
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
