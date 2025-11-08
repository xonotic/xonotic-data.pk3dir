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
	if(!(actor.items & IT_UNLIMITED_AMMO))
	{
		W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	W_DecreaseAmmo(WEP_OVERKILL_MACHINEGUN, actor, WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, ammo), weaponentity);

	W_SetupShot(actor, weaponentity, true, 0, SND_OK_MG_FIRE, CH_WEAPON_A, WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, damage), WEP_OVERKILL_MACHINEGUN.m_id);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	okmachinegun_spread = bound(WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, spread_min), WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, spread_min) + (WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, spread_add) * actor.(weaponentity).misc_bulletcounter), WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, spread_max));

	fireBullet_falloff(actor, weaponentity, w_shotorg, w_shotdir, okmachinegun_spread,
	                   WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, solidpenetration),
	                   WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, damage),
	                   WEP_CVAR(WEP_OVERKILL_MACHINEGUN, damagefalloff_halflife),
	                   WEP_CVAR(WEP_OVERKILL_MACHINEGUN, damagefalloff_mindist),
	                   WEP_CVAR(WEP_OVERKILL_MACHINEGUN, damagefalloff_maxdist),
	                   0,
	                   WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, force),
	                   WEP_CVAR(WEP_OVERKILL_MACHINEGUN, damagefalloff_forcehalflife),
	                   WEP_OVERKILL_MACHINEGUN.m_id, EFFECT_RIFLE, true);

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	if(autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), vectoangles(v_forward), 3, actor, weaponentity);
	}

	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, refire) * W_WeaponRateFactor(actor);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, refire), W_OverkillMachineGun_Attack_Auto);
}

METHOD(OverkillMachineGun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(vdist(actor.origin - actor.enemy.origin, <, 3000 - bound(0, skill, 10) * 200))
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, true);
}

METHOD(OverkillMachineGun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if ((WEP_CVAR_SEC(WEP_OVERKILL_MACHINEGUN, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
	{
		// Secondary uses it's own refire timer if refire_type is 1.
		actor.jump_interval = time + WEP_CVAR_PRI(WEP_BLASTER, refire) * W_WeaponRateFactor(actor);
		makevectors(actor.v_angle);
		W_Blaster_Attack(actor, weaponentity);
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
	if (WEP_CVAR(WEP_OVERKILL_MACHINEGUN, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, ammo))
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
	if ((fire & 2) && (WEP_CVAR_SEC(WEP_OVERKILL_MACHINEGUN, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_PRI(WEP_BLASTER, refire)))
		{
			return;
		}
		makevectors(actor.v_angle);
		W_Blaster_Attack(actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_PRI(WEP_BLASTER, animtime), w_ready);
	}
}

METHOD(OverkillMachineGun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, ammo);
	if (WEP_CVAR(WEP_OVERKILL_MACHINEGUN, reload_ammo))
	{
		ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_MACHINEGUN.m_id]) >= WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, ammo);
	}
	return ammo_amount;
}

METHOD(OverkillMachineGun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // Blaster secondary is unlimited.
}

METHOD(OverkillMachineGun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, WEP_CVAR_PRI(WEP_OVERKILL_MACHINEGUN, ammo), SND_RELOAD);
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
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_MACHINEGUN_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include <common/mutators/mutator/overkill/overkill.qh>

METHOD(OverkillMachineGun, describe, string(OverkillMachineGun this))
{
	TC(OverkillMachineGun, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s quickly fires bullets with a small degree of spread."), COLORED_NAME(this));
	PAR(_("Like with all %s weapons, the secondary fire shoots a laser which doesn't damage or push enemies, but can be used to push yourself around."), COLORED_NAME(MUTATOR_ok));
	PAR(_("The primary fire consumes %s ammo, although you spawn with an infinite amount of it in %s. "
	      "It has a limited magazine size, so needs reloading after several shots."), COLORED_NAME(ITEM_Bullets), COLORED_NAME(MUTATOR_ok));
	PAR(_("The %s can be used in a lot of situations, and it works particularly well at long ranges since the bullets pierce the sky instantaneously."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne(this.netname, "primary"));
	return PAGE_TEXT;
}

#endif
