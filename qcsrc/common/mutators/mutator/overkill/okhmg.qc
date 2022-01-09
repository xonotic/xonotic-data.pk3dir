#include "okhmg.qh"

#ifdef SVQC

REGISTER_MUTATOR(okhmg_nadesupport, true);
MUTATOR_HOOKFUNCTION(okhmg_nadesupport, Nade_Damage)
{
	if (M_ARGV(1, entity) != WEP_OVERKILL_HMG) return;
	return = true;
	M_ARGV(3, float) /* damage */ = (M_ARGV(0, entity)).max_health * 0.1;
}

void W_OverkillHeavyMachineGun_Attack_Auto(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if (!PHYS_INPUT_BUTTON_ATCK(actor))
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if((!thiswep.wr_checkammo1(thiswep, actor, weaponentity) && !(actor.items & IT_UNLIMITED_AMMO)) || (!StatusEffects_active(STATUSEFFECT_Superweapons, actor) && !(actor.items & IT_UNLIMITED_SUPERWEAPONS)))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_DecreaseAmmo(WEP_OVERKILL_HMG, actor, WEP_CVAR_PRI(okhmg, ammo), weaponentity);

	W_SetupShot(actor, weaponentity, true, 0, SND_UZI_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(okhmg, damage), WEP_OVERKILL_HMG.m_id);

	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random () - 0.5;
		actor.punchangle_y = random () - 0.5;
	}

	float okhmg_spread = bound(WEP_CVAR_PRI(okhmg, spread_min), WEP_CVAR_PRI(okhmg, spread_min) + (WEP_CVAR_PRI(okhmg, spread_add) * actor.(weaponentity).misc_bulletcounter), WEP_CVAR_PRI(okhmg, spread_max));
	fireBullet(actor, weaponentity, w_shotorg, w_shotdir, okhmg_spread, WEP_CVAR_PRI(okhmg, solidpenetration), WEP_CVAR_PRI(okhmg, damage), 0, WEP_CVAR_PRI(okhmg, force), WEP_OVERKILL_HMG.m_id, EFFECT_RIFLE);

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	if (autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, actor, weaponentity);
	}

	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR_PRI(okhmg, refire) * W_WeaponRateFactor(actor);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(okhmg, refire), W_OverkillHeavyMachineGun_Attack_Auto);
}

METHOD(OverkillHeavyMachineGun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(vdist(actor.origin - actor.enemy.origin, <, 3000 - bound(0, skill, 10) * 200))
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
}

METHOD(OverkillHeavyMachineGun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if ((WEP_CVAR_SEC(okhmg, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
	{
		// Secondary uses it's own refire timer if refire_type is 1.
		actor.jump_interval = time + WEP_CVAR_SEC(okhmg, refire) * W_WeaponRateFactor(actor);
		BLASTER_SECONDARY_ATTACK(okhmg, actor, weaponentity);
		if ((actor.(weaponentity).wframe == WFRAME_IDLE) ||
			(actor.(weaponentity).wframe == WFRAME_FIRE2))
		{
			// Set secondary fire animation.
			actor.(weaponentity).wframe = WFRAME_FIRE2;
			FOREACH_CLIENT(true, LAMBDA(
				if (it == actor || (IS_SPEC(it) && it.enemy == actor))
				{
					wframe_send(it, actor.(weaponentity), WFRAME_FIRE2, autocvar_g_weaponratefactor, true);
				}
			));
			animdecide_setaction(actor, ANIMACTION_SHOOT, true);
		}
	}
    if (WEP_CVAR(okhmg, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(okhmg, ammo))
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
		W_OverkillHeavyMachineGun_Attack_Auto(thiswep, actor, weaponentity, fire);
		return;
	}
	if ((fire & 2) && (WEP_CVAR_SEC(okhmg, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(okhmg, refire)))
		{
			return;
		}
		BLASTER_SECONDARY_ATTACK(okhmg, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(okhmg, animtime), w_ready);
	}
}

METHOD(OverkillHeavyMachineGun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(okhmg, ammo);
	if (autocvar_g_balance_okhmg_reload_ammo)
	{
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_HMG.m_id]) >= WEP_CVAR_PRI(okhmg, ammo);
	}
	return ammo_amount;
}

METHOD(OverkillHeavyMachineGun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_SEC(okhmg, ammo);
	if (autocvar_g_balance_okhmg_reload_ammo)
	{
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_HMG.m_id]) >= WEP_CVAR_SEC(okhmg, ammo);
	}
	return ammo_amount;
}

METHOD(OverkillHeavyMachineGun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    W_Reload(actor, weaponentity, WEP_CVAR_PRI(okhmg, ammo), SND_RELOAD);
}

METHOD(OverkillHeavyMachineGun, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(OverkillHeavyMachineGun, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_OVERKILL_HMG_MURDER_SNIPE;
    else
        return WEAPON_OVERKILL_HMG_MURDER_SPRAY;
}

#endif
#ifdef CSQC

METHOD(OverkillHeavyMachineGun, wr_impacteffect, void(entity thiswep, entity actor))
{
    vector org2;
    org2 = w_org + w_backoff * 2;
    pointparticles(EFFECT_MACHINEGUN_IMPACT, org2, w_backoff * 1000, 1);
    if(!w_issilent)
        sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
}

#endif
