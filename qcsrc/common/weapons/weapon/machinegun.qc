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
/* wepname   */ ATTRIB(MachineGun, m_name, string, _("MachineGun"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, burst, float, NONE) \
		P(class, prefix, burst_ammo, float, NONE) \
		P(class, prefix, burst_animtime, float, NONE) \
		P(class, prefix, burst_refire2, float, NONE) \
		P(class, prefix, burst_refire, float, NONE) \
		P(class, prefix, burst_speed, float, NONE) \
		P(class, prefix, first, float, NONE) \
		P(class, prefix, first_ammo, float, NONE) \
		P(class, prefix, first_damage, float, NONE) \
		P(class, prefix, first_force, float, NONE) \
		P(class, prefix, first_refire, float, NONE) \
		P(class, prefix, first_spread, float, NONE) \
		P(class, prefix, mode, float, NONE) \
		P(class, prefix, reload_ammo, float, NONE) \
        P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, solidpenetration, float, NONE) \
		P(class, prefix, spread_add, float, NONE) \
		P(class, prefix, spread_max, float, NONE) \
		P(class, prefix, spread_min, float, NONE) \
		P(class, prefix, sustained_ammo, float, NONE) \
		P(class, prefix, sustained_damage, float, NONE) \
		P(class, prefix, sustained_force, float, NONE) \
		P(class, prefix, sustained_refire, float, NONE) \
		P(class, prefix, sustained_spread, float, NONE) \
        P(class, prefix, switchdelay_drop, float, NONE) \
        P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, weaponreplace, string,NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, MachineGun, machinegun)
#undef X

ENDCLASS(MachineGun)
REGISTER_WEAPON(MACHINEGUN, machinegun, NEW(MachineGun));


#endif
#ifdef IMPLEMENTATION
#ifdef SVQC

spawnfunc(weapon_machinegun)
{
	if(autocvar_sv_q3acompat_machineshotgunswap)
	if(self.classname != "droppedweapon")
	{
		weapon_defaultspawnfunc(this, WEP_SHOCKWAVE);
		return;
	}
	weapon_defaultspawnfunc(this, WEP_MACHINEGUN);
}
spawnfunc(weapon_uzi) { spawnfunc_weapon_machinegun(this); }

void W_MachineGun_MuzzleFlash_Think()
{SELFPARAM();
	this.frame += 2;
	this.scale *= 0.5;
	this.alpha -= 0.25;
	this.nextthink = time + 0.05;

	if(this.alpha <= 0)
	{
		this.think = SUB_Remove_self;
		this.nextthink = time;
		this.realowner.muzzle_flash = world;
		return;
	}

}

void W_MachineGun_MuzzleFlash()
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

void W_MachineGun_Attack(Weapon thiswep, int deathtype, .entity weaponentity)
{SELFPARAM();
	W_SetupShot(self, true, 0, SND(UZI_FIRE), CH_WEAPON_A, ((self.misc_bulletcounter == 1) ? WEP_CVAR(machinegun, first_damage) : WEP_CVAR(machinegun, sustained_damage)));
	if(!autocvar_g_norecoil)
	{
		self.punchangle_x = random() - 0.5;
		self.punchangle_y = random() - 0.5;
	}
	int slot = weaponslot(weaponentity);
	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(self, slot) = time + WEP_CVAR(machinegun, first_refire) * W_WeaponRateFactor();

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
void W_MachineGun_Attack_Frame(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(PS(actor).m_weapon != PS(actor).m_switchweapon) // abort immediately if switching
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}
	if(actor.BUTTON_ATCK)
	{
		if(!thiswep.wr_checkammo2(thiswep))
		if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
			w_ready(thiswep, actor, weaponentity, fire);
			return;
		}
		actor.misc_bulletcounter = actor.misc_bulletcounter + 1;
		W_MachineGun_Attack(WEP_MACHINEGUN, WEP_MACHINEGUN.m_id, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Frame);
	}
	else
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), w_ready);
}


void W_MachineGun_Attack_Auto(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	float machinegun_spread;

	if(!(fire & 1))
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if(!thiswep.wr_checkammo1(thiswep))
	if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
		w_ready(thiswep, actor, weaponentity, fire);
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

	int slot = weaponslot(weaponentity);
	ATTACK_FINISHED(actor, slot) = time + WEP_CVAR(machinegun, first_refire) * W_WeaponRateFactor();
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Auto);
}

void W_MachineGun_Attack_Burst(Weapon thiswep, entity actor, .entity weaponentity, int fire)
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
		int slot = weaponslot(weaponentity);
		ATTACK_FINISHED(actor, slot) = time + WEP_CVAR(machinegun, burst_refire2) * W_WeaponRateFactor();
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(machinegun, burst_animtime), w_ready);
	}
	else
	{
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(machinegun, burst_refire), W_MachineGun_Attack_Burst);
	}

}

		METHOD(MachineGun, wr_aim, void(entity thiswep))
		{
			if(vlen(self.origin-self.enemy.origin) < 3000 - bound(0, skill, 10) * 200)
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, false);
			else
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, false);
		}
		METHOD(MachineGun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(WEP_CVAR(machinegun, reload_ammo) && actor.clip_load < min(max(WEP_CVAR(machinegun, sustained_ammo), WEP_CVAR(machinegun, first_ammo)), WEP_CVAR(machinegun, burst_ammo))) { // forced reload
				thiswep.wr_reload(thiswep);
			} else
			if(WEP_CVAR(machinegun, mode) == 1)
			{
				if(fire & 1)
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
				{
					actor.misc_bulletcounter = 0;
					W_MachineGun_Attack_Auto(thiswep, actor, weaponentity, fire);
				}

				if(fire & 2)
				if(weapon_prepareattack(thiswep, actor, weaponentity, true, 0))
				{
					if(!thiswep.wr_checkammo2(thiswep))
					if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
					{
						W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
						w_ready(thiswep, actor, weaponentity, fire);
						return;
					}

					W_DecreaseAmmo(thiswep, actor, WEP_CVAR(machinegun, burst_ammo));

					actor.misc_bulletcounter = WEP_CVAR(machinegun, burst) * -1;
					W_MachineGun_Attack_Burst(thiswep, actor, weaponentity, fire);
				}
			}
			else
			{

				if(fire & 1)
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
				{
					actor.misc_bulletcounter = 1;
					W_MachineGun_Attack(WEP_MACHINEGUN, WEP_MACHINEGUN.m_id, weaponentity); // sets attack_finished
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(machinegun, sustained_refire), W_MachineGun_Attack_Frame);
				}

				if((fire & 2) && WEP_CVAR(machinegun, first))
				if(weapon_prepareattack(thiswep, actor, weaponentity, true, 0))
				{
					actor.misc_bulletcounter = 1;
					W_MachineGun_Attack(WEP_MACHINEGUN, WEP_MACHINEGUN.m_id | HITTYPE_SECONDARY, weaponentity); // sets attack_finished
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(machinegun, first_refire), w_ready);
				}
			}
		}
		METHOD(MachineGun, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount;
			if(WEP_CVAR(machinegun, mode) == 1)
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(machinegun, sustained_ammo);
			else
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(machinegun, first_ammo);

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
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(machinegun, burst_ammo);
			else
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(machinegun, first_ammo);

			if(WEP_CVAR(machinegun, reload_ammo))
			{
				if(WEP_CVAR(machinegun, mode) == 1)
					ammo_amount += self.(weapon_load[WEP_MACHINEGUN.m_id]) >= WEP_CVAR(machinegun, burst_ammo);
				else
					ammo_amount += self.(weapon_load[WEP_MACHINEGUN.m_id]) >= WEP_CVAR(machinegun, first_ammo);
			}
			return ammo_amount;
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
			pointparticles(EFFECT_MACHINEGUN_IMPACT, org2, w_backoff * 1000, 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
		}

#endif
#endif
