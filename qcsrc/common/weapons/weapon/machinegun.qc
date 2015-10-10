#ifndef IMPLEMENTATION
CLASS(MachineGun, Weapon)
/* ammotype  */ ATTRIB(MachineGun, ammo_field, .int, ammo_nails)
/* impulse   */ ATTRIB(MachineGun, impulse, int, 3)
/* flags     */ ATTRIB(MachineGun, spawnflags, int, WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN);
/* rating    */ ATTRIB(MachineGun, bot_pickupbasevalue, float, BOT_PICKUP_RATING_MID);
/* color     */ ATTRIB(MachineGun, wpcolor, vector, '1 1 0');
/* modelname */ ATTRIB(MachineGun, mdl, string, "uzi");
#ifndef MENUQC
/* model     */ ATTRIB(MachineGun, m_model, Model, MDL_MACHINEGUN_ITEM);
#endif
/* crosshair */ ATTRIB(MachineGun, w_crosshair, string, "gfx/crosshairuzi");
/* crosshair */ ATTRIB(MachineGun, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(MachineGun, model2, string, "weaponuzi");
/* refname   */ ATTRIB(MachineGun, netname, string, "machinegun");
/* wepname   */ ATTRIB(MachineGun, message, string, _("MachineGun"));
ENDCLASS(MachineGun)
REGISTER_WEAPON(MACHINEGUN, NEW(MachineGun));

#define MACHINEGUN_SETTINGS(w_cvar,w_prop) MACHINEGUN_SETTINGS_LIST(w_cvar, w_prop, MACHINEGUN, machinegun)
#define MACHINEGUN_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, NONE, spread_min) \
	w_cvar(id, sn, NONE, spread_max) \
	w_cvar(id, sn, NONE, spread_add) \
	w_cvar(id, sn, NONE, mode) \
	w_cvar(id, sn, NONE, first) \
	w_cvar(id, sn, NONE, first_damage) \
	w_cvar(id, sn, NONE, first_force) \
	w_cvar(id, sn, NONE, first_refire) \
	w_cvar(id, sn, NONE, first_spread) \
	w_cvar(id, sn, NONE, first_ammo) \
	w_cvar(id, sn, NONE, solidpenetration) \
	w_cvar(id, sn, NONE, sustained_damage) \
	w_cvar(id, sn, NONE, sustained_force) \
	w_cvar(id, sn, NONE, sustained_refire) \
	w_cvar(id, sn, NONE, sustained_spread) \
	w_cvar(id, sn, NONE, sustained_ammo) \
	w_cvar(id, sn, NONE, burst) \
	w_cvar(id, sn, NONE, burst_refire) \
	w_cvar(id, sn, NONE, burst_refire2) \
	w_cvar(id, sn, NONE, burst_animtime) \
	w_cvar(id, sn, NONE, burst_speed) \
	w_cvar(id, sn, NONE, burst_ammo) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
MACHINEGUN_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC

spawnfunc(weapon_machinegun)
{
	if(autocvar_sv_q3acompat_machineshotgunswap)
	if(self.classname != "droppedweapon")
	{
		weapon_defaultspawnfunc(WEP_SHOCKWAVE.m_id);
		return;
	}
	weapon_defaultspawnfunc(WEP_MACHINEGUN.m_id);
}
spawnfunc(weapon_uzi) { spawnfunc_weapon_machinegun(this); }

void W_MachineGun_MuzzleFlash_Think(void)
{SELFPARAM();
	self.frame = self.frame + 2;
	self.scale = self.scale * 0.5;
	self.alpha = self.alpha - 0.25;
	self.nextthink = time + 0.05;

	if(self.alpha <= 0)
	{
		self.think = SUB_Remove;
		self.nextthink = time;
		self.realowner.muzzle_flash = world;
		return;
	}

}

void W_MachineGun_MuzzleFlash(void)
{SELFPARAM();
	if(self.muzzle_flash == world)
		self.muzzle_flash = spawn();

	// muzzle flash for 1st person view
	setmodel(self.muzzle_flash, MDL_MACHINEGUN_MUZZLEFLASH); // precision set below

	self.muzzle_flash.scale = 0.75;
	self.muzzle_flash.think = W_MachineGun_MuzzleFlash_Think;
	self.muzzle_flash.nextthink = time + 0.02;
	self.muzzle_flash.frame = 2;
	self.muzzle_flash.alpha = 0.75;
	self.muzzle_flash.angles_z = random() * 180;
	self.muzzle_flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	self.muzzle_flash.owner = self.muzzle_flash.realowner = self;
}

void W_MachineGun_Attack(Weapon thiswep, int deathtype)
{SELFPARAM();
	W_SetupShot(self, true, 0, SND(UZI_FIRE), CH_WEAPON_A, ((self.misc_bulletcounter == 1) ? WEP_CVAR(machinegun, first_damage) : WEP_CVAR(machinegun, sustained_damage)));
	if(!autocvar_g_norecoil)
	{
		self.punchangle_x = random() - 0.5;
		self.punchangle_y = random() - 0.5;
	}

	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(self) = time + WEP_CVAR(machinegun, first_refire) * W_WeaponRateFactor();

	if(self.misc_bulletcounter == 1)
		fireBullet(w_shotorg, w_shotdir, WEP_CVAR(machinegun, first_spread), WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, first_damage), WEP_CVAR(machinegun, first_force), deathtype, 0);
	else
		fireBullet(w_shotorg, w_shotdir, WEP_CVAR(machinegun, sustained_spread), WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, sustained_damage), WEP_CVAR(machinegun, sustained_force), deathtype, 0);

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash();
	W_AttachToShotorg(self, self.muzzle_flash, '5 0 0');

	// casing code
	if(autocvar_g_casings >= 2)
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);

	if(self.misc_bulletcounter == 1)
		W_DecreaseAmmo(thiswep, self, WEP_CVAR(machinegun, first_ammo));
	else
		W_DecreaseAmmo(thiswep, self, WEP_CVAR(machinegun, sustained_ammo));
}

// weapon frames
void W_MachineGun_Attack_Frame(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	if(actor.weapon != actor.switchweapon) // abort immediately if switching
	{
		w_ready(thiswep, actor, fire1, fire2);
		return;
	}
	if(actor.BUTTON_ATCK)
	{
		Weapon w = get_weaponinfo(actor.weapon);
		if(!w.wr_checkammo2(w))
		if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
			w_ready(thiswep, actor, fire1, fire2);
			return;
		}
		actor.misc_bulletcounter = actor.misc_bulletcounter + 1;
		W_MachineGun_Attack(WEP_MACHINEGUN, WEP_MACHINEGUN.m_id);
		weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Frame);
	}
	else
		weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), w_ready);
}


void W_MachineGun_Attack_Auto(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	float machinegun_spread;

	if(!fire1)
	{
		w_ready(thiswep, actor, fire1, fire2);
		return;
	}

	Weapon w = get_weaponinfo(actor.weapon);
	if(!w.wr_checkammo1(w))
	if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
		w_ready(thiswep, actor, fire1, fire2);
		return;
	}

	W_DecreaseAmmo(WEP_MACHINEGUN, actor, WEP_CVAR(machinegun, sustained_ammo));

	W_SetupShot(actor, true, 0, SND(UZI_FIRE), CH_WEAPON_A, WEP_CVAR(machinegun, sustained_damage));
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	machinegun_spread = bound(WEP_CVAR(machinegun, spread_min), WEP_CVAR(machinegun, spread_min) + (WEP_CVAR(machinegun, spread_add) * actor.misc_bulletcounter), WEP_CVAR(machinegun, spread_max));
	fireBullet(w_shotorg, w_shotdir, machinegun_spread, WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, sustained_damage), WEP_CVAR(machinegun, sustained_force), WEP_MACHINEGUN.m_id, 0);

	actor.misc_bulletcounter = actor.misc_bulletcounter + 1;

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash();
	W_AttachToShotorg(actor, actor.muzzle_flash, '5 0 0');

	if(autocvar_g_casings >= 2) // casing code
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor);

	ATTACK_FINISHED(actor) = time + WEP_CVAR(machinegun, first_refire) * W_WeaponRateFactor();
	weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Auto);
}

void W_MachineGun_Attack_Burst(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	W_SetupShot(actor, true, 0, SND(UZI_FIRE), CH_WEAPON_A, WEP_CVAR(machinegun, sustained_damage));
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	fireBullet(w_shotorg, w_shotdir, WEP_CVAR(machinegun, burst_speed), WEP_CVAR(machinegun, solidpenetration), WEP_CVAR(machinegun, sustained_damage), WEP_CVAR(machinegun, sustained_force), WEP_MACHINEGUN.m_id, 0);

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash();
	W_AttachToShotorg(actor, actor.muzzle_flash, '5 0 0');

	if(autocvar_g_casings >= 2) // casing code
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor);

	actor.misc_bulletcounter = actor.misc_bulletcounter + 1;
	if(actor.misc_bulletcounter == 0)
	{
		ATTACK_FINISHED(actor) = time + WEP_CVAR(machinegun, burst_refire2) * W_WeaponRateFactor();
		weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR(machinegun, burst_animtime), w_ready);
	}
	else
	{
		weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR(machinegun, burst_refire), W_MachineGun_Attack_Burst);
	}

}

		METHOD(MachineGun, wr_aim, void(entity thiswep))
		{
			if(vlen(self.origin-self.enemy.origin) < 3000 - bound(0, skill, 10) * 200)
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, false);
			else
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, false);
		}
		METHOD(MachineGun, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
		{
			if(WEP_CVAR(machinegun, reload_ammo) && actor.clip_load < min(max(WEP_CVAR(machinegun, sustained_ammo), WEP_CVAR(machinegun, first_ammo)), WEP_CVAR(machinegun, burst_ammo))) { // forced reload
				Weapon w = get_weaponinfo(actor.weapon);
				w.wr_reload(w);
			} else
			if(WEP_CVAR(machinegun, mode) == 1)
			{
				if(fire1)
				if(weapon_prepareattack(thiswep, actor, false, 0))
				{
					actor.misc_bulletcounter = 0;
					W_MachineGun_Attack_Auto(thiswep, actor, fire1, fire2);
				}

				if(fire2)
				if(weapon_prepareattack(thiswep, actor, true, 0))
				{
					Weapon w = get_weaponinfo(actor.weapon);
					if(!w.wr_checkammo2(w))
					if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
					{
						W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
						w_ready(thiswep, actor, fire1, fire2);
						return;
					}

					W_DecreaseAmmo(thiswep, actor, WEP_CVAR(machinegun, burst_ammo));

					actor.misc_bulletcounter = WEP_CVAR(machinegun, burst) * -1;
					W_MachineGun_Attack_Burst(thiswep, actor, fire1, fire2);
				}
			}
			else
			{

				if(fire1)
				if(weapon_prepareattack(thiswep, actor, false, 0))
				{
					actor.misc_bulletcounter = 1;
					W_MachineGun_Attack(WEP_MACHINEGUN, WEP_MACHINEGUN.m_id); // sets attack_finished
					weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Frame);
				}

				if(fire2 && WEP_CVAR(machinegun, first))
				if(weapon_prepareattack(thiswep, actor, true, 0))
				{
					actor.misc_bulletcounter = 1;
					W_MachineGun_Attack(WEP_MACHINEGUN, WEP_MACHINEGUN.m_id | HITTYPE_SECONDARY); // sets attack_finished
					weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR(machinegun, first_refire), w_ready);
				}
			}
		}
		METHOD(MachineGun, wr_init, void(entity thiswep))
		{
			MACHINEGUN_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
		}
		METHOD(MachineGun, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount;
			if(WEP_CVAR(machinegun, mode) == 1)
				ammo_amount = self.WEP_AMMO(MACHINEGUN) >= WEP_CVAR(machinegun, sustained_ammo);
			else
				ammo_amount = self.WEP_AMMO(MACHINEGUN) >= WEP_CVAR(machinegun, first_ammo);

			if(WEP_CVAR(machinegun, reload_ammo))
			{
				if(WEP_CVAR(machinegun, mode) == 1)
					ammo_amount += self.(weapon_load[WEP_MACHINEGUN.m_id]) >= WEP_CVAR(machinegun, sustained_ammo);
				else
					ammo_amount += self.(weapon_load[WEP_MACHINEGUN.m_id]) >= WEP_CVAR(machinegun, first_ammo);
			}
			return ammo_amount;
		}
		METHOD(MachineGun, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount;
			if(WEP_CVAR(machinegun, mode) == 1)
				ammo_amount = self.WEP_AMMO(MACHINEGUN) >= WEP_CVAR(machinegun, burst_ammo);
			else
				ammo_amount = self.WEP_AMMO(MACHINEGUN) >= WEP_CVAR(machinegun, first_ammo);

			if(WEP_CVAR(machinegun, reload_ammo))
			{
				if(WEP_CVAR(machinegun, mode) == 1)
					ammo_amount += self.(weapon_load[WEP_MACHINEGUN.m_id]) >= WEP_CVAR(machinegun, burst_ammo);
				else
					ammo_amount += self.(weapon_load[WEP_MACHINEGUN.m_id]) >= WEP_CVAR(machinegun, first_ammo);
			}
			return ammo_amount;
		}
		METHOD(MachineGun, wr_config, void(entity thiswep))
		{
			MACHINEGUN_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
		}
		METHOD(MachineGun, wr_reload, void(entity thiswep))
		{
			W_Reload(self, min(max(WEP_CVAR(machinegun, sustained_ammo), WEP_CVAR(machinegun, first_ammo)), WEP_CVAR(machinegun, burst_ammo)), SND(RELOAD));
		}
		METHOD(MachineGun, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		METHOD(MachineGun, wr_killmessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_MACHINEGUN_MURDER_SNIPE;
			else
				return WEAPON_MACHINEGUN_MURDER_SPRAY;
		}

#endif
#ifdef CSQC

		METHOD(MachineGun, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 2;
			pointparticles(particleeffectnum(EFFECT_MACHINEGUN_IMPACT), org2, w_backoff * 1000, 1);
			if(!w_issilent)
				if(w_random < 0.05)
					sound(self, CH_SHOTS, SND_RIC1, VOL_BASE, ATTN_NORM);
				else if(w_random < 0.1)
					sound(self, CH_SHOTS, SND_RIC2, VOL_BASE, ATTN_NORM);
				else if(w_random < 0.2)
					sound(self, CH_SHOTS, SND_RIC3, VOL_BASE, ATTN_NORM);
		}

#endif
#endif
