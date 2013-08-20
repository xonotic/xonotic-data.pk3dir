#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ UZI,
/* function */ w_uzi,
/* ammotype */ IT_NAILS,
/* impulse  */ 3,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN,
/* rating   */ BOT_PICKUP_RATING_MID,
/* model    */ "uzi",
/* netname  */ "uzi",
/* fullname */ _("Machine Gun")
);

#define UZI_SETTINGS(weapon) \
	WEP_ADD_CVAR(weapon, MO_NONE, speed) \
	WEP_ADD_CVAR(weapon, MO_NONE, spread_min) \
	WEP_ADD_CVAR(weapon, MO_NONE, spread_max) \
	WEP_ADD_CVAR(weapon, MO_NONE, spread_add) \
	WEP_ADD_CVAR(weapon, MO_NONE, mode) \
	WEP_ADD_CVAR(weapon, MO_NONE, bulletconstant) \
	WEP_ADD_CVAR(weapon, MO_NONE, first) \
	WEP_ADD_CVAR(weapon, MO_NONE, first_damage) \
	WEP_ADD_CVAR(weapon, MO_NONE, first_force) \
	WEP_ADD_CVAR(weapon, MO_NONE, first_refire) \
	WEP_ADD_CVAR(weapon, MO_NONE, first_spread) \
	WEP_ADD_CVAR(weapon, MO_NONE, first_ammo) \
	WEP_ADD_CVAR(weapon, MO_NONE, sustained_damage) \
	WEP_ADD_CVAR(weapon, MO_NONE, sustained_force) \
	WEP_ADD_CVAR(weapon, MO_NONE, sustained_refire) \
	WEP_ADD_CVAR(weapon, MO_NONE, sustained_spread) \
	WEP_ADD_CVAR(weapon, MO_NONE, sustained_ammo) \
	WEP_ADD_CVAR(weapon, MO_NONE, burst) \
	WEP_ADD_CVAR(weapon, MO_NONE, burst_refire) \
	WEP_ADD_CVAR(weapon, MO_NONE, burst_refire2) \
	WEP_ADD_CVAR(weapon, MO_NONE, burst_animtime) \
	WEP_ADD_CVAR(weapon, MO_NONE, burst_speed) \
	WEP_ADD_CVAR(weapon, MO_NONE, burst_ammo) \
	WEP_ADD_PROP(weapon, reloading_ammo, reload_ammo) \
	WEP_ADD_PROP(weapon, reloading_time, reload_time) \
	WEP_ADD_PROP(weapon, switchdelay_raise, switchdelay_raise) \
	WEP_ADD_PROP(weapon, switchdelay_drop, switchdelay_drop)

#ifdef SVQC
UZI_SETTINGS(uzi)
#endif
#else
#ifdef SVQC

void spawnfunc_weapon_uzi()
{
	if(autocvar_sv_q3acompat_machineshotgunswap)
	if(self.classname != "droppedweapon")
	{
		weapon_defaultspawnfunc(WEP_SHOTGUN);
		return;
	}
	weapon_defaultspawnfunc(WEP_UZI);
}

// leilei's fancy muzzleflash stuff
void UZI_Flash_Go()
{
	self.frame = self.frame + 2;
	self.scale = self.scale * 0.5;
	self.alpha = self.alpha - 0.25;
	self.nextthink = time + 0.05;

	if (self.alpha <= 0)
	{
		self.think = SUB_Remove;
		self.nextthink = time;
		self.realowner.muzzle_flash = world;
		return;
	}

}

void UziFlash()
{
	if (self.muzzle_flash == world)
		self.muzzle_flash = spawn();

	// muzzle flash for 1st person view
	setmodel(self.muzzle_flash, "models/uziflash.md3"); // precision set below

	self.muzzle_flash.scale = 0.75;
	self.muzzle_flash.think = UZI_Flash_Go;
	self.muzzle_flash.nextthink = time + 0.02;
	self.muzzle_flash.frame = 2;
	self.muzzle_flash.alpha = 0.75;
	self.muzzle_flash.angles_z = random() * 180;
	self.muzzle_flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	self.muzzle_flash.owner = self.muzzle_flash.realowner = self;
}

void W_UZI_Attack (float deathtype)
{
	W_SetupShot (self, autocvar_g_antilag_bullets && WEP_CVAR(uzi, speed) >= autocvar_g_antilag_bullets, 0, "weapons/uzi_fire.wav", CH_WEAPON_A, ((self.misc_bulletcounter == 1) ? WEP_CVAR(uzi, first_damage) : WEP_CVAR(uzi, sustained_damage)));
	if (!autocvar_g_norecoil)
	{
		self.punchangle_x = random () - 0.5;
		self.punchangle_y = random () - 0.5;
	}

	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(self) = time + WEP_CVAR(uzi, first_refire) * W_WeaponRateFactor();

	if (self.misc_bulletcounter == 1)
		fireBallisticBullet(w_shotorg, w_shotdir, WEP_CVAR(uzi, first_spread), WEP_CVAR(uzi, speed), 5, WEP_CVAR(uzi, first_damage), WEP_CVAR(uzi, first_force), deathtype, 0, 1, WEP_CVAR(uzi, bulletconstant));
	else
		fireBallisticBullet(w_shotorg, w_shotdir, WEP_CVAR(uzi, sustained_spread), WEP_CVAR(uzi, speed), 5, WEP_CVAR(uzi, sustained_damage), WEP_CVAR(uzi, sustained_force), deathtype, 0, 1, WEP_CVAR(uzi, bulletconstant));
	endFireBallisticBullet();

	pointparticles(particleeffectnum("uzi_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	UziFlash();
	W_AttachToShotorg(self.muzzle_flash, '5 0 0');

	// casing code
	if (autocvar_g_casings >= 2)
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);

	if (self.misc_bulletcounter == 1)
		W_DecreaseAmmo(ammo_nails, WEP_CVAR(uzi, first_ammo), autocvar_g_balance_uzi_reload_ammo);
	else
		W_DecreaseAmmo(ammo_nails, WEP_CVAR(uzi, sustained_ammo), autocvar_g_balance_uzi_reload_ammo);
}

// weapon frames
void uzi_fire1_02()
{
	if(self.weapon != self.switchweapon) // abort immediately if switching
	{
		w_ready();
		return;
	}
	if (self.BUTTON_ATCK)
	{
		if (!WEP_ACTION(self.weapon, WR_CHECKAMMO2))
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		{
			W_SwitchWeapon_Force(self, w_getbestweapon(self));
			w_ready();
			return;
		}
		self.misc_bulletcounter = self.misc_bulletcounter + 1;
		W_UZI_Attack(WEP_UZI);
		weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(uzi, sustained_refire), uzi_fire1_02);
	}
	else
		weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(uzi, sustained_refire), w_ready);
}


void uzi_mode1_fire_auto()
{
	float uzi_spread;

	if (!self.BUTTON_ATCK)
	{
		w_ready();
		return;
	}

	if (!WEP_ACTION(self.weapon, WR_CHECKAMMO1))
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		W_SwitchWeapon_Force(self, w_getbestweapon(self));
		w_ready();
		return;
	}

	W_DecreaseAmmo(ammo_nails, WEP_CVAR(uzi, sustained_ammo), autocvar_g_balance_uzi_reload_ammo);

	W_SetupShot (self, autocvar_g_antilag_bullets && WEP_CVAR(uzi, speed) >= autocvar_g_antilag_bullets, 0, "weapons/uzi_fire.wav", CH_WEAPON_A, WEP_CVAR(uzi, sustained_damage));
	if (!autocvar_g_norecoil)
	{
		self.punchangle_x = random () - 0.5;
		self.punchangle_y = random () - 0.5;
	}

	uzi_spread = bound(WEP_CVAR(uzi, spread_min), WEP_CVAR(uzi, spread_min) + (WEP_CVAR(uzi, spread_add) * self.misc_bulletcounter), WEP_CVAR(uzi, spread_max));
	fireBallisticBullet(w_shotorg, w_shotdir, uzi_spread, WEP_CVAR(uzi, speed), 5, WEP_CVAR(uzi, sustained_damage), WEP_CVAR(uzi, sustained_force), WEP_UZI, 0, 1, WEP_CVAR(uzi, bulletconstant));
	endFireBallisticBullet();

	self.misc_bulletcounter = self.misc_bulletcounter + 1;

	pointparticles(particleeffectnum("uzi_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	UziFlash();
	W_AttachToShotorg(self.muzzle_flash, '5 0 0');

	if (autocvar_g_casings >= 2) // casing code
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);

	ATTACK_FINISHED(self) = time + WEP_CVAR(uzi, first_refire) * W_WeaponRateFactor();
	weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(uzi, sustained_refire), uzi_mode1_fire_auto);
}

void uzi_mode1_fire_burst()
{
	W_SetupShot (self, autocvar_g_antilag_bullets && WEP_CVAR(uzi, speed) >= autocvar_g_antilag_bullets, 0, "weapons/uzi_fire.wav", CH_WEAPON_A, WEP_CVAR(uzi, sustained_damage));
	if (!autocvar_g_norecoil)
	{
		self.punchangle_x = random () - 0.5;
		self.punchangle_y = random () - 0.5;
	}

	fireBallisticBullet(w_shotorg, w_shotdir, WEP_CVAR(uzi, burst_speed), WEP_CVAR(uzi, speed), 5, WEP_CVAR(uzi, sustained_damage), WEP_CVAR(uzi, sustained_force), WEP_UZI, 0, 1, WEP_CVAR(uzi, bulletconstant));
	endFireBallisticBullet();


	pointparticles(particleeffectnum("uzi_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	UziFlash();
	W_AttachToShotorg(self.muzzle_flash, '5 0 0');

	if (autocvar_g_casings >= 2) // casing code
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);

	self.misc_bulletcounter = self.misc_bulletcounter + 1;
	if (self.misc_bulletcounter == 0)
	{
		ATTACK_FINISHED(self) = time + WEP_CVAR(uzi, burst_refire2) * W_WeaponRateFactor();
		weapon_thinkf(WFRAME_FIRE2, WEP_CVAR(uzi, burst_animtime), w_ready);
	}
	else
	{
		weapon_thinkf(WFRAME_FIRE2, WEP_CVAR(uzi, burst_refire), uzi_mode1_fire_burst);
	}

}

float w_uzi(float req)
{
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			if(vlen(self.origin-self.enemy.origin) < 3000 - bound(0, skill, 10) * 200)
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
			else
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
			
			return TRUE;
		}
		case WR_THINK:
		{
			if(autocvar_g_balance_uzi_reload_ammo && self.clip_load < min(max(WEP_CVAR(uzi, sustained_ammo), WEP_CVAR(uzi, first_ammo)), WEP_CVAR(uzi, burst_ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if(WEP_CVAR(uzi, mode) == 1)
			{
				if (self.BUTTON_ATCK)
				if (weapon_prepareattack(0, 0))
				{
					self.misc_bulletcounter = 0;
					uzi_mode1_fire_auto();
				}

				if(self.BUTTON_ATCK2)
				if(weapon_prepareattack(1, 0))
				{
					if (!WEP_ACTION(self.weapon, WR_CHECKAMMO2))
					if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
					{
						W_SwitchWeapon_Force(self, w_getbestweapon(self));
						w_ready();
						return FALSE;
					}

					W_DecreaseAmmo(ammo_nails, WEP_CVAR(uzi, burst_ammo), autocvar_g_balance_uzi_reload_ammo);

					self.misc_bulletcounter = WEP_CVAR(uzi, burst) * -1;
					uzi_mode1_fire_burst();
				}
			}
			else
			{

				if (self.BUTTON_ATCK)
				if (weapon_prepareattack(0, 0))
				{
					self.misc_bulletcounter = 1;
					W_UZI_Attack(WEP_UZI); // sets attack_finished
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(uzi, sustained_refire), uzi_fire1_02);
				}

				if (self.BUTTON_ATCK2 && WEP_CVAR(uzi, first))
				if (weapon_prepareattack(1, 0))
				{
					self.misc_bulletcounter = 1;
					W_UZI_Attack(WEP_UZI | HITTYPE_SECONDARY); // sets attack_finished
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR(uzi, first_refire), w_ready);
				}
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model ("models/uziflash.md3");
			precache_model ("models/weapons/g_uzi.md3");
			precache_model ("models/weapons/v_uzi.md3");
			precache_model ("models/weapons/h_uzi.iqm");
			precache_sound ("weapons/uzi_fire.wav");
			WEP_SET_PROPS(UZI_SETTINGS(uzi), WEP_UZI)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_nails;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			if(WEP_CVAR(uzi, mode) == 1)
				ammo_amount = self.ammo_nails >= WEP_CVAR(uzi, sustained_ammo);
			else
				ammo_amount = self.ammo_nails >= WEP_CVAR(uzi, first_ammo);

			if(autocvar_g_balance_uzi_reload_ammo)
			{
				if(WEP_CVAR(uzi, mode) == 1)
					ammo_amount += self.(weapon_load[WEP_UZI]) >= WEP_CVAR(uzi, sustained_ammo);
				else
					ammo_amount += self.(weapon_load[WEP_UZI]) >= WEP_CVAR(uzi, first_ammo);
			}
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			if(WEP_CVAR(uzi, mode) == 1)
				ammo_amount = self.ammo_nails >= WEP_CVAR(uzi, burst_ammo);
			else
				ammo_amount = self.ammo_nails >= WEP_CVAR(uzi, first_ammo);

			if(autocvar_g_balance_uzi_reload_ammo)
			{
				if(WEP_CVAR(uzi, mode) == 1)
					ammo_amount += self.(weapon_load[WEP_UZI]) >= WEP_CVAR(uzi, burst_ammo);
				else
					ammo_amount += self.(weapon_load[WEP_UZI]) >= WEP_CVAR(uzi, first_ammo);
			}
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			WEP_CONFIG_SETTINGS(UZI_SETTINGS(uzi))
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_Reload(min(max(WEP_CVAR(uzi, sustained_ammo), WEP_CVAR(uzi, first_ammo)), WEP_CVAR(uzi, burst_ammo)), autocvar_g_balance_uzi_reload_ammo, autocvar_g_balance_uzi_reload_time, "weapons/reload.wav");
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		case WR_KILLMESSAGE:
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_UZI_MURDER_SNIPE;
			else
				return WEAPON_UZI_MURDER_SPRAY;
		}
	}
	return TRUE;
}
#endif
#ifdef CSQC
float w_uzi(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 2;
			pointparticles(particleeffectnum("machinegun_impact"), org2, w_backoff * 1000, 1);
			if(!w_issilent)
				if(w_random < 0.05)
					sound(self, CH_SHOTS, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
				else if(w_random < 0.1)
					sound(self, CH_SHOTS, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
				else if(w_random < 0.2)
					sound(self, CH_SHOTS, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
					
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/ric1.wav");
			precache_sound("weapons/ric2.wav");
			precache_sound("weapons/ric3.wav");
			return TRUE;
		}
	}
	return TRUE;
}
#endif
#endif
