#ifndef IMPLEMENTATION
CLASS(HeavyMachineGun, Weapon)
/* ammotype  */ ATTRIB(HeavyMachineGun, ammo_field, .int, ammo_nails)
/* impulse   */ ATTRIB(HeavyMachineGun, impulse, int, 3)
/* flags     */ ATTRIB(HeavyMachineGun, spawnflags, int, WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_HIDDEN | WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN | WEP_FLAG_SUPERWEAPON);
/* rating    */ ATTRIB(HeavyMachineGun, bot_pickupbasevalue, float, BOT_PICKUP_RATING_HIGH);
/* color     */ ATTRIB(HeavyMachineGun, wpcolor, vector, '0.5 0.5 0');
/* modelname */ ATTRIB(HeavyMachineGun, mdl, string, "ok_hmg");
#ifndef MENUQC
/* model     */ ATTRIB(HeavyMachineGun, m_model, Model, MDL_HMG_ITEM);
#endif
/* crosshair */ ATTRIB(HeavyMachineGun, w_crosshair, string, "gfx/crosshairuzi");
/* crosshair */ ATTRIB(HeavyMachineGun, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(HeavyMachineGun, model2, string, "weaponhmg");
/* refname   */ ATTRIB(HeavyMachineGun, netname, string, "hmg");
/* wepname   */ ATTRIB(HeavyMachineGun, message, string, _("Heavy Machine Gun"));
ENDCLASS(HeavyMachineGun)
REGISTER_WEAPON(HMG, NEW(HeavyMachineGun));

#define HMG_SETTINGS(w_cvar,w_prop) HMG_SETTINGS_LIST(w_cvar, w_prop, HMG, hmg)
#define HMG_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, NONE, spread_min) \
	w_cvar(id, sn, NONE, spread_max) \
	w_cvar(id, sn, NONE, spread_add) \
	w_cvar(id, sn, NONE, solidpenetration) \
	w_cvar(id, sn, NONE, damage) \
	w_cvar(id, sn, NONE, force) \
	w_cvar(id, sn, NONE, refire) \
	w_cvar(id, sn, NONE, ammo) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
HMG_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC

spawnfunc(weapon_hmg) { weapon_defaultspawnfunc(WEP_HMG.m_id); }

void W_HeavyMachineGun_Attack_Auto(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	if (!actor.BUTTON_ATCK)
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

	W_DecreaseAmmo(WEP_HMG, self, WEP_CVAR(hmg, ammo));

	W_SetupShot (actor, true, 0, SND(UZI_FIRE), CH_WEAPON_A, WEP_CVAR(hmg, damage));

	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random () - 0.5;
		actor.punchangle_y = random () - 0.5;
	}

	float hmg_spread = bound(WEP_CVAR(hmg, spread_min), WEP_CVAR(hmg, spread_min) + (WEP_CVAR(hmg, spread_add) * actor.misc_bulletcounter), WEP_CVAR(hmg, spread_max));
	fireBullet(w_shotorg, w_shotdir, hmg_spread, WEP_CVAR(hmg, solidpenetration), WEP_CVAR(hmg, damage), WEP_CVAR(hmg, force), WEP_HMG.m_id, 0);

	actor.misc_bulletcounter = actor.misc_bulletcounter + 1;

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash();
	W_AttachToShotorg(actor, actor.muzzle_flash, '5 0 0');

	if (autocvar_g_casings >= 2) // casing code
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor);

	ATTACK_FINISHED(actor) = time + WEP_CVAR(hmg, refire) * W_WeaponRateFactor();
	weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR(hmg, refire), W_HeavyMachineGun_Attack_Auto);
}

		METHOD(HeavyMachineGun, wr_aim, void(entity thiswep))
		{
			if(vlen(self.origin-self.enemy.origin) < 3000 - bound(0, skill, 10) * 200)
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, false);
			else
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, false);
		}
		METHOD(HeavyMachineGun, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
		{
			if(WEP_CVAR(hmg, reload_ammo) && actor.clip_load < WEP_CVAR(hmg, ammo)) { // forced reload
				Weapon w = get_weaponinfo(actor.weapon);
				w.wr_reload(w);
			} else
			{
				if (fire1)
				if (weapon_prepareattack(thiswep, actor, false, 0))
				{
					actor.misc_bulletcounter = 0;
					W_HeavyMachineGun_Attack_Auto(thiswep, actor, fire1, fire2);
				}
			}
		}
		METHOD(HeavyMachineGun, wr_init, void(entity thiswep))
		{
			HMG_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
		}
		METHOD(HeavyMachineGun, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.ammo_nails >= WEP_CVAR(hmg, ammo);

			if(autocvar_g_balance_hmg_reload_ammo)
				ammo_amount += self.(weapon_load[WEP_HMG.m_id]) >= WEP_CVAR(hmg, ammo);

			return ammo_amount;
		}
		METHOD(HeavyMachineGun, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount = self.ammo_nails >= WEP_CVAR(hmg, ammo);

			if(autocvar_g_balance_hmg_reload_ammo)
				ammo_amount += self.(weapon_load[WEP_HMG.m_id]) >= WEP_CVAR(hmg, ammo);

			return ammo_amount;
		}
		METHOD(HeavyMachineGun, wr_config, void(entity thiswep))
		{
			HMG_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
		}
		METHOD(HeavyMachineGun, wr_reload, void(entity thiswep))
		{
			W_Reload(self, WEP_CVAR(hmg, ammo), SND(RELOAD));
		}
		METHOD(HeavyMachineGun, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		METHOD(HeavyMachineGun, wr_killmessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_HMG_MURDER_SNIPE;
			else
				return WEAPON_HMG_MURDER_SPRAY;
		}

#endif
#ifdef CSQC

		METHOD(HeavyMachineGun, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 2;
			pointparticles(particleeffectnum(EFFECT_MACHINEGUN_IMPACT), org2, w_backoff * 1000, 1);
			if(!w_issilent)
				if(w_random < 0.05)
					sound(self, CH_SHOTS, SND_RIC1, VOL_BASE, ATTEN_NORM);
				else if(w_random < 0.1)
					sound(self, CH_SHOTS, SND_RIC2, VOL_BASE, ATTEN_NORM);
				else if(w_random < 0.2)
					sound(self, CH_SHOTS, SND_RIC3, VOL_BASE, ATTEN_NORM);
		}

#endif
#endif
