#ifndef IMPLEMENTATION
REGISTER_WEAPON(
/* WEP_##id  */ HLAC,
/* function  */ W_HLAC,
/* ammotype  */ ammo_cells,
/* impulse   */ 6,
/* flags     */ WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH,
/* rating    */ BOT_PICKUP_RATING_MID,
/* color     */ '0 1 0',
/* modelname */ "hlac",
/* simplemdl */ "foobar",
/* crosshair */ "gfx/crosshairhlac 0.6",
/* wepimg    */ "weaponhlac",
/* refname   */ "hlac",
/* wepname   */ _("Heavy Laser Assault Cannon")
);

#define HLAC_SETTINGS(w_cvar,w_prop) HLAC_SETTINGS_LIST(w_cvar, w_prop, HLAC, hlac)
#define HLAC_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, edgedamage) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, BOTH, lifetime) \
	w_cvar(id, sn, BOTH, radius) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, BOTH, speed) \
	w_cvar(id, sn, BOTH, spread_crouchmod) \
	w_cvar(id, sn, PRI,  spread_add) \
	w_cvar(id, sn, PRI,  spread_max) \
	w_cvar(id, sn, PRI,  spread_min) \
	w_cvar(id, sn, NONE, secondary) \
	w_cvar(id, sn, SEC,  shots) \
	w_cvar(id, sn, SEC,  spread) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
HLAC_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_hlac) { weapon_defaultspawnfunc(WEP_HLAC.m_id); }

void W_HLAC_Touch(void)
{SELFPARAM();
	float isprimary;

	PROJECTILE_TOUCH;

	self.event_damage = func_null;

	isprimary = !(self.projectiledeathtype & HITTYPE_SECONDARY);

	RadiusDamage(self, self.realowner, WEP_CVAR_BOTH(hlac, isprimary, damage), WEP_CVAR_BOTH(hlac, isprimary, edgedamage), WEP_CVAR_BOTH(hlac, isprimary, radius), world, world, WEP_CVAR_BOTH(hlac, isprimary, force), self.projectiledeathtype, other);

	remove(self);
}

void W_HLAC_Attack(void)
{SELFPARAM();
	entity missile;
    float spread;

	W_DecreaseAmmo(WEP_CVAR_PRI(hlac, ammo));

    spread = WEP_CVAR_PRI(hlac, spread_min) + (WEP_CVAR_PRI(hlac, spread_add) * self.misc_bulletcounter);
    spread = min(spread,WEP_CVAR_PRI(hlac, spread_max));
    if(self.crouch)
        spread = spread * WEP_CVAR_PRI(hlac, spread_crouchmod);

	W_SetupShot(self, false, 3, SND(LASERGUN_FIRE), CH_WEAPON_A, WEP_CVAR_PRI(hlac, damage));
	Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);
	if(!autocvar_g_norecoil)
	{
		self.punchangle_x = random() - 0.5;
		self.punchangle_y = random() - 0.5;
	}

	missile = spawn();
	missile.owner = missile.realowner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = true;

    missile.bot_dodgerating = WEP_CVAR_PRI(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Basic(missile, WEP_CVAR_PRI(hlac, speed), spread);
	//missile.angles = vectoangles(missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + WEP_CVAR_PRI(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.projectiledeathtype = WEP_HLAC.m_id;

	CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

void W_HLAC_Attack2(void)
{SELFPARAM();
	entity missile;
    float spread;

    spread = WEP_CVAR_SEC(hlac, spread);


    if(self.crouch)
        spread = spread * WEP_CVAR_SEC(hlac, spread_crouchmod);

	W_SetupShot(self, false, 3, SND(LASERGUN_FIRE), CH_WEAPON_A, WEP_CVAR_SEC(hlac, damage));
	Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = spawn();
	missile.owner = missile.realowner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = true;

    missile.bot_dodgerating = WEP_CVAR_SEC(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Basic(missile, WEP_CVAR_SEC(hlac, speed), spread);
	//missile.angles = vectoangles(missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + WEP_CVAR_SEC(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;
	missile.projectiledeathtype = WEP_HLAC.m_id | HITTYPE_SECONDARY;

	CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

// weapon frames
void W_HLAC_Attack_Frame(void)
{SELFPARAM();
	if(self.weapon != self.switchweapon) // abort immediately if switching
	{
		w_ready();
		return;
	}

	if(self.BUTTON_ATCK)
	{
		if(!WEP_ACTION(self.weapon, WR_CHECKAMMO1))
		if(!(self.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			W_SwitchWeapon_Force(self, w_getbestweapon(self));
			w_ready();
			return;
		}

		ATTACK_FINISHED(self) = time + WEP_CVAR_PRI(hlac, refire) * W_WeaponRateFactor();
		W_HLAC_Attack();
		self.misc_bulletcounter = self.misc_bulletcounter + 1;
        weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), W_HLAC_Attack_Frame);
	}
	else
	{
		weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(hlac, animtime), w_ready);
	}
}

void W_HLAC_Attack2_Frame(void)
{SELFPARAM();
    float i;

	W_DecreaseAmmo(WEP_CVAR_SEC(hlac, ammo));

    for(i=WEP_CVAR_SEC(hlac, shots);i>0;--i)
        W_HLAC_Attack2();

	if(!autocvar_g_norecoil)
	{
		self.punchangle_x = random() - 0.5;
		self.punchangle_y = random() - 0.5;
	}
}

bool W_HLAC(int req)
{SELFPARAM();
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			self.BUTTON_ATCK = bot_aim(WEP_CVAR_PRI(hlac, speed), 0, WEP_CVAR_PRI(hlac, lifetime), false);
			return true;
		}
		case WR_THINK:
		{
			if(autocvar_g_balance_hlac_reload_ammo && self.clip_load < min(WEP_CVAR_PRI(hlac, ammo), WEP_CVAR_SEC(hlac, ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if(self.BUTTON_ATCK)
			{
				if(weapon_prepareattack(0, WEP_CVAR_PRI(hlac, refire)))
				{
					self.misc_bulletcounter = 0;
					W_HLAC_Attack();
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), W_HLAC_Attack_Frame);
				}
			}

			else if(self.BUTTON_ATCK2 && WEP_CVAR(hlac, secondary))
			{
				if(weapon_prepareattack(1, WEP_CVAR_SEC(hlac, refire)))
				{
					W_HLAC_Attack2_Frame();
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(hlac, animtime), w_ready);
				}
			}

			return true;
		}
		case WR_INIT:
		{
			HLAC_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
			return true;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.WEP_AMMO(HLAC) >= WEP_CVAR_PRI(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC.m_id]) >= WEP_CVAR_PRI(hlac, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			ammo_amount = self.WEP_AMMO(HLAC) >= WEP_CVAR_SEC(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC.m_id]) >= WEP_CVAR_SEC(hlac, ammo);
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			HLAC_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
			return true;
		}
		case WR_RELOAD:
		{
			W_Reload(min(WEP_CVAR_PRI(hlac, ammo), WEP_CVAR_SEC(hlac, ammo)), SND(RELOAD));
			return true;
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
	return false;
}
#endif
#ifdef CSQC
bool W_HLAC(int req)
{SELFPARAM();
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum(EFFECT_BLASTER_IMPACT), org2, w_backoff * 1000, 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM);

			return true;
		}
		case WR_INIT:
		{
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
