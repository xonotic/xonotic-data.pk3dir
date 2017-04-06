#include "okmachinegun.qh"

#ifdef SVQC

spawnfunc(weapon_okmachinegun)
{
	if(autocvar_sv_q3acompat_machineshotgunswap)
	if(this.classname != "droppedweapon")
	{
		weapon_defaultspawnfunc(this, WEP_SHOCKWAVE);
		return;
	}
	weapon_defaultspawnfunc(this, WEP_OVERKILL_MACHINEGUN);
}

void W_OverkillMachineGun_Attack(Weapon thiswep, int deathtype, entity actor, .entity weaponentity)
{
	W_SetupShot(actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, ((actor.(weaponentity).misc_bulletcounter == 1) ? WEP_CVAR(okmachinegun, first_damage) : WEP_CVAR(okmachinegun, sustained_damage)));
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}
	int slot = weaponslot(weaponentity);
	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(actor, slot) = time + WEP_CVAR(okmachinegun, first_refire) * W_WeaponRateFactor(actor);

	if(actor.(weaponentity).misc_bulletcounter == 1)
		fireBullet(actor, weaponentity, w_shotorg, w_shotdir, WEP_CVAR(okmachinegun, first_spread), WEP_CVAR(okmachinegun, solidpenetration), WEP_CVAR(okmachinegun, first_damage), WEP_CVAR(okmachinegun, first_force), deathtype, 0);
	else
		fireBullet(actor, weaponentity, w_shotorg, w_shotdir, WEP_CVAR(okmachinegun, sustained_spread), WEP_CVAR(okmachinegun, solidpenetration), WEP_CVAR(okmachinegun, sustained_damage), WEP_CVAR(okmachinegun, sustained_force), deathtype, 0);

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash(actor, weaponentity);
	W_AttachToShotorg(actor, weaponentity, actor.(weaponentity).muzzle_flash, '5 0 0');

	// casing code
	if(autocvar_g_casings >= 2)
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	if(actor.(weaponentity).misc_bulletcounter == 1)
		W_DecreaseAmmo(thiswep, actor, WEP_CVAR(okmachinegun, first_ammo), weaponentity);
	else
		W_DecreaseAmmo(thiswep, actor, WEP_CVAR(okmachinegun, sustained_ammo), weaponentity);
}

// weapon frames
void W_OverkillMachineGun_Attack_Frame(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(actor.(weaponentity).m_weapon != actor.(weaponentity).m_switchweapon) // abort immediately if switching
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}
	if(PHYS_INPUT_BUTTON_ATCK(actor))
	{
		if(!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
		if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
			w_ready(thiswep, actor, weaponentity, fire);
			return;
		}
		actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;
		W_OverkillMachineGun_Attack(WEP_OVERKILL_MACHINEGUN, WEP_OVERKILL_MACHINEGUN.m_id, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(okmachinegun, sustained_refire), W_OverkillMachineGun_Attack_Frame);
	}
	else
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(okmachinegun, sustained_refire), w_ready);
}

void W_OverkillMachineGun_Attack_Auto(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	float okmachinegun_spread;

	if(!(fire & 1))
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if(!thiswep.wr_checkammo1(thiswep, actor, weaponentity))
	if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_DecreaseAmmo(WEP_OVERKILL_MACHINEGUN, actor, WEP_CVAR(okmachinegun, sustained_ammo), weaponentity);

	W_SetupShot(actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, WEP_CVAR(okmachinegun, sustained_damage));
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	okmachinegun_spread = bound(WEP_CVAR(okmachinegun, spread_min), WEP_CVAR(okmachinegun, spread_min) + (WEP_CVAR(okmachinegun, spread_add) * actor.(weaponentity).misc_bulletcounter), WEP_CVAR(okmachinegun, spread_max));
	fireBullet(actor, weaponentity, w_shotorg, w_shotdir, okmachinegun_spread, WEP_CVAR(okmachinegun, solidpenetration), WEP_CVAR(okmachinegun, sustained_damage), WEP_CVAR(okmachinegun, sustained_force), WEP_OVERKILL_MACHINEGUN.m_id, 0);

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash(actor, weaponentity);
	W_AttachToShotorg(actor, weaponentity, actor.(weaponentity).muzzle_flash, '5 0 0');

	if(autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	int slot = weaponslot(weaponentity);
	ATTACK_FINISHED(actor, slot) = time + WEP_CVAR(okmachinegun, first_refire) * W_WeaponRateFactor(actor);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(okmachinegun, sustained_refire), W_OverkillMachineGun_Attack_Auto);
}

METHOD(OverkillMachineGun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(vdist(actor.origin - actor.enemy.origin, <, 3000 - bound(0, skill, 10) * 200))
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
	else
		PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
}

METHOD(OverkillMachineGun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if ((WEP_CVAR_SEC(okmachinegun, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
	{
		// Secondary uses it's own refire timer if refire_type is 1.
		actor.jump_interval = time + WEP_CVAR_SEC(okmachinegun, refire) * W_WeaponRateFactor(actor);
		// Ugly hack to reuse the fire mode of the blaster.
		makevectors(actor.v_angle);
		Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
		actor.(weaponentity).m_weapon = WEP_BLASTER;
		W_Blaster_Attack(
			actor,
			weaponentity,
			WEP_BLASTER.m_id | HITTYPE_SECONDARY,
			WEP_CVAR_SEC(okmachinegun, shotangle),
			WEP_CVAR_SEC(okmachinegun, damage),
			WEP_CVAR_SEC(okmachinegun, edgedamage),
			WEP_CVAR_SEC(okmachinegun, radius),
			WEP_CVAR_SEC(okmachinegun, force),
			WEP_CVAR_SEC(okmachinegun, speed),
			WEP_CVAR_SEC(okmachinegun, spread),
			WEP_CVAR_SEC(okmachinegun, delay),
			WEP_CVAR_SEC(okmachinegun, lifetime)
		);
		actor.(weaponentity).m_weapon = oldwep;
		if ((actor.(weaponentity).wframe == WFRAME_IDLE) ||
			(actor.(weaponentity).wframe == WFRAME_FIRE2))
		{
			// Set secondary fire animation.
			vector a = '0 0 0';
			actor.(weaponentity).wframe = WFRAME_FIRE2;
			a = actor.(weaponentity).anim_fire2;
			a.z *= g_weaponratefactor;
			FOREACH_CLIENT(true, LAMBDA(
				if (it == actor || (IS_SPEC(it) && it.enemy == actor))
				{
					wframe_send(it, actor.(weaponentity), a, true);
				}
			));
			animdecide_setaction(actor, ANIMACTION_SHOOT, true);
		}
	}
	if (WEP_CVAR(okmachinegun, reload_ammo) && actor.(weaponentity).clip_load < min(max(WEP_CVAR(okmachinegun, sustained_ammo), WEP_CVAR(okmachinegun, first_ammo)), WEP_CVAR(okmachinegun, burst_ammo)))
	{
		// Forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		return;
	}
	if (WEP_CVAR(okmachinegun, mode) == 1)
	{
		if(fire & 1) // Primary attack
		{
			if (!weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
			{
				return;
			}
			actor.(weaponentity).misc_bulletcounter = 0;
			W_OverkillMachineGun_Attack_Auto(thiswep, actor, weaponentity, fire);
			return;
		}
		if ((fire & 2) && (WEP_CVAR_SEC(okmachinegun, refire_type) == 0)) // Secondary attack
		{
			if (!weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(okmachinegun, refire)))
			{
				return;
			}
			// ugly instagib hack to reuse the fire mode of the laser
			makevectors(actor.v_angle);
			Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
			actor.(weaponentity).m_weapon = WEP_BLASTER;
			W_Blaster_Attack(
				actor,
				weaponentity,
				WEP_BLASTER.m_id | HITTYPE_SECONDARY,
				WEP_CVAR_SEC(okmachinegun, shotangle),
				WEP_CVAR_SEC(okmachinegun, damage),
				WEP_CVAR_SEC(okmachinegun, edgedamage),
				WEP_CVAR_SEC(okmachinegun, radius),
				WEP_CVAR_SEC(okmachinegun, force),
				WEP_CVAR_SEC(okmachinegun, speed),
				WEP_CVAR_SEC(okmachinegun, spread),
				WEP_CVAR_SEC(okmachinegun, delay),
				WEP_CVAR_SEC(okmachinegun, lifetime)
			);
			actor.(weaponentity).m_weapon = oldwep;
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(okmachinegun, animtime), w_ready);
		}
	}
	else
	{
		if (fire & 1) // Primary attack
		{
			if (!weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
			{
				return;
			}
			actor.(weaponentity).misc_bulletcounter = 1;
			W_OverkillMachineGun_Attack(WEP_OVERKILL_MACHINEGUN, WEP_OVERKILL_MACHINEGUN.m_id, actor, weaponentity); // sets attack_finished
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(okmachinegun, sustained_refire), W_OverkillMachineGun_Attack_Frame);
			return;
		}
		if ((fire & 2) && (WEP_CVAR_SEC(okmachinegun, refire_type) == 0)) // Secondary attack
		{
			if (!weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(okmachinegun, refire)))
			{
				return;
			}
			// ugly instagib hack to reuse the fire mode of the laser
			makevectors(actor.v_angle);
			Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
			actor.(weaponentity).m_weapon = WEP_BLASTER;
			W_Blaster_Attack(
				actor,
				weaponentity,
				WEP_BLASTER.m_id | HITTYPE_SECONDARY,
				WEP_CVAR_SEC(okmachinegun, shotangle),
				WEP_CVAR_SEC(okmachinegun, damage),
				WEP_CVAR_SEC(okmachinegun, edgedamage),
				WEP_CVAR_SEC(okmachinegun, radius),
				WEP_CVAR_SEC(okmachinegun, force),
				WEP_CVAR_SEC(okmachinegun, speed),
				WEP_CVAR_SEC(okmachinegun, spread),
				WEP_CVAR_SEC(okmachinegun, delay),
				WEP_CVAR_SEC(okmachinegun, lifetime)
			);
			actor.(weaponentity).m_weapon = oldwep;
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(okmachinegun, animtime), w_ready);
		}
	}
}

METHOD(OverkillMachineGun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	if(WEP_CVAR(okmachinegun, mode) == 1)
		ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR(okmachinegun, sustained_ammo);
	else
		ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR(okmachinegun, first_ammo);

	if(WEP_CVAR(okmachinegun, reload_ammo))
	{
		if(WEP_CVAR(okmachinegun, mode) == 1)
			ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_MACHINEGUN.m_id]) >= WEP_CVAR(okmachinegun, sustained_ammo);
		else
			ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_MACHINEGUN.m_id]) >= WEP_CVAR(okmachinegun, first_ammo);
	}
	return ammo_amount;
}

METHOD(OverkillMachineGun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	if(WEP_CVAR(okmachinegun, mode) == 1)
		ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR(okmachinegun, burst_ammo);
	else
		ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR(okmachinegun, first_ammo);

	if(WEP_CVAR(okmachinegun, reload_ammo))
	{
		if(WEP_CVAR(okmachinegun, mode) == 1)
			ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_MACHINEGUN.m_id]) >= WEP_CVAR(okmachinegun, burst_ammo);
		else
			ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_MACHINEGUN.m_id]) >= WEP_CVAR(okmachinegun, first_ammo);
	}
	return ammo_amount;
}

METHOD(OverkillMachineGun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, min(max(WEP_CVAR(okmachinegun, sustained_ammo), WEP_CVAR(okmachinegun, first_ammo)), WEP_CVAR(okmachinegun, burst_ammo)), SND_RELOAD);
}

METHOD(OverkillMachineGun, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(OverkillMachineGun, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_MACHINEGUN_MURDER_SNIPE;
	else
		return WEAPON_MACHINEGUN_MURDER_SPRAY;
}

#endif
#ifdef CSQC

METHOD(OverkillMachineGun, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2;
	org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_MACHINEGUN_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
}

#endif

