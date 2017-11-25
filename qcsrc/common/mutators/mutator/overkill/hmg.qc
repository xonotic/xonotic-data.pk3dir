#include "hmg.qh"

#ifdef SVQC

REGISTER_MUTATOR(hmg_nadesupport, true);
MUTATOR_HOOKFUNCTION(hmg_nadesupport, Nade_Damage)
{
	if (M_ARGV(1, entity) != WEP_HMG) return;
	return = true;
	M_ARGV(3, float) /* damage */ = (M_ARGV(0, entity)).max_health * 0.1;
}

void W_HeavyMachineGun_Attack_Auto(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if (!PHYS_INPUT_BUTTON_ATCK(actor))
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if((!thiswep.wr_checkammo1(thiswep, actor, weaponentity) && !(actor.items & IT_UNLIMITED_WEAPON_AMMO)) || (!(actor.items & IT_SUPERWEAPON) && !(actor.items & IT_UNLIMITED_SUPERWEAPONS)))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_DecreaseAmmo(WEP_HMG, actor, WEP_CVAR_PRI(hmg, ammo), weaponentity);

	W_SetupShot (actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(hmg, damage));

	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random () - 0.5;
		actor.punchangle_y = random () - 0.5;
	}

	float hmg_spread = bound(WEP_CVAR_PRI(hmg, spread_min), WEP_CVAR_PRI(hmg, spread_min) + (WEP_CVAR_PRI(hmg, spread_add) * actor.(weaponentity).misc_bulletcounter), WEP_CVAR_PRI(hmg, spread_max));
	fireBullet(actor, weaponentity, w_shotorg, w_shotdir, hmg_spread, WEP_CVAR_PRI(hmg, solidpenetration), WEP_CVAR_PRI(hmg, damage), WEP_CVAR_PRI(hmg, force), WEP_HMG.m_id, 0);

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash(actor, weaponentity);
	W_AttachToShotorg(actor, weaponentity, actor.(weaponentity).muzzle_flash, '5 0 0');

	if (autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	int slot = weaponslot(weaponentity);
	ATTACK_FINISHED(actor, slot) = time + WEP_CVAR_PRI(hmg, refire) * W_WeaponRateFactor(actor);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(hmg, refire), W_HeavyMachineGun_Attack_Auto);
}

METHOD(HeavyMachineGun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(vdist(actor.origin - actor.enemy.origin, <, 3000 - bound(0, skill, 10) * 200))
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
    else
        PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
}

METHOD(HeavyMachineGun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if ((WEP_CVAR_SEC(hmg, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
	{
		// Secondary uses it's own refire timer if refire_type is 1.
		actor.jump_interval = time + WEP_CVAR_SEC(hmg, refire) * W_WeaponRateFactor(actor);
		// Ugly hack to reuse the fire mode of the blaster.
		makevectors(actor.v_angle);
		Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
		actor.(weaponentity).m_weapon = WEP_BLASTER;
		W_Blaster_Attack(
			actor,
			weaponentity,
			WEP_BLASTER.m_id | HITTYPE_SECONDARY,
			WEP_CVAR_SEC(hmg, shotangle),
			WEP_CVAR_SEC(hmg, damage),
			WEP_CVAR_SEC(hmg, edgedamage),
			WEP_CVAR_SEC(hmg, radius),
			WEP_CVAR_SEC(hmg, force),
			WEP_CVAR_SEC(hmg, speed),
			WEP_CVAR_SEC(hmg, spread),
			WEP_CVAR_SEC(hmg, delay),
			WEP_CVAR_SEC(hmg, lifetime)
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
    if (WEP_CVAR(hmg, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(hmg, ammo))
	{
		// Forced reload.
        thiswep.wr_reload(thiswep, actor, weaponentity);
		return;
	}
	if (fire & 1) // Primary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
		{
			return;
		}
		actor.(weaponentity).misc_bulletcounter = 0;
		W_HeavyMachineGun_Attack_Auto(thiswep, actor, weaponentity, fire);
		return;
	}
	if ((fire & 2) && (WEP_CVAR_SEC(hmg, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(hmg, refire)))
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
			WEP_CVAR_SEC(hmg, shotangle),
			WEP_CVAR_SEC(hmg, damage),
			WEP_CVAR_SEC(hmg, edgedamage),
			WEP_CVAR_SEC(hmg, radius),
			WEP_CVAR_SEC(hmg, force),
			WEP_CVAR_SEC(hmg, speed),
			WEP_CVAR_SEC(hmg, spread),
			WEP_CVAR_SEC(hmg, delay),
			WEP_CVAR_SEC(hmg, lifetime)
		);
		actor.(weaponentity).m_weapon = oldwep;
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(hmg, animtime), w_ready);
	}
}

METHOD(HeavyMachineGun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResourceAmount(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(hmg, ammo);
	if (autocvar_g_balance_hmg_reload_ammo)
	{
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_HMG.m_id]) >= WEP_CVAR_PRI(hmg, ammo);
	}
	return ammo_amount;
}

METHOD(HeavyMachineGun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResourceAmount(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(hmg, ammo);
	if (autocvar_g_balance_hmg_reload_ammo)
	{
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_HMG.m_id]) >= WEP_CVAR_SEC(hmg, ammo);
	}
	return ammo_amount;
}

METHOD(HeavyMachineGun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, WEP_CVAR_PRI(hmg, ammo), SND_RELOAD);
}

METHOD(HeavyMachineGun, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(HeavyMachineGun, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_HMG_MURDER_SNIPE;
    else
        return WEAPON_HMG_MURDER_SPRAY;
}

#endif
#ifdef CSQC

METHOD(HeavyMachineGun, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 2;
    pointparticles(EFFECT_MACHINEGUN_IMPACT, org2, w_backoff * 1000, 1);
    if(!w_issilent)
        sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
}

#endif
