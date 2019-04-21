#include "okmachinegun.qh"

#ifdef SVQC

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

	W_DecreaseAmmo(WEP_OVERKILL_MACHINEGUN, actor, WEP_CVAR_PRI(okmachinegun, ammo), weaponentity);

	W_SetupShot(actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(okmachinegun, damage), WEP_OVERKILL_MACHINEGUN.m_id);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	okmachinegun_spread = bound(WEP_CVAR_PRI(okmachinegun, spread_min), WEP_CVAR_PRI(okmachinegun, spread_min) + (WEP_CVAR_PRI(okmachinegun, spread_add) * actor.(weaponentity).misc_bulletcounter), WEP_CVAR_PRI(okmachinegun, spread_max));
	fireBullet(actor, weaponentity, w_shotorg, w_shotdir, okmachinegun_spread, WEP_CVAR_PRI(okmachinegun, solidpenetration), WEP_CVAR_PRI(okmachinegun, damage), WEP_CVAR_PRI(okmachinegun, force), WEP_OVERKILL_MACHINEGUN.m_id, EFFECT_RIFLE);

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;

	Send_Effect(EFFECT_MACHINEGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	W_MachineGun_MuzzleFlash(actor, weaponentity);
	W_AttachToShotorg(actor, weaponentity, actor.(weaponentity).muzzle_flash, '5 0 0');

	if(autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR_PRI(okmachinegun, refire) * W_WeaponRateFactor(actor);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(okmachinegun, refire), W_OverkillMachineGun_Attack_Auto);
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
		BLASTER_SECONDARY_ATTACK(okmachinegun, actor, weaponentity);
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
	if (WEP_CVAR(okmachinegun, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(okmachinegun, ammo))
	{
		// Forced reload
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
		W_OverkillMachineGun_Attack_Auto(thiswep, actor, weaponentity, fire);
		return;
	}
	if ((fire & 2) && (WEP_CVAR_SEC(okmachinegun, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(okmachinegun, refire)))
		{
			return;
		}
		BLASTER_SECONDARY_ATTACK(okmachinegun, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(okmachinegun, animtime), w_ready);
	}
}

METHOD(OverkillMachineGun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(okmachinegun, ammo);
	if (WEP_CVAR(okmachinegun, reload_ammo))
	{
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_MACHINEGUN.m_id]) >= WEP_CVAR_PRI(okmachinegun, ammo);
	}
	return ammo_amount;
}

METHOD(OverkillMachineGun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // Blaster secondary is unlimited.
}

METHOD(OverkillMachineGun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, WEP_CVAR_PRI(okmachinegun, ammo), SND_RELOAD);
}

METHOD(OverkillMachineGun, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(OverkillMachineGun, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_OVERKILL_MACHINEGUN_MURDER;
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
