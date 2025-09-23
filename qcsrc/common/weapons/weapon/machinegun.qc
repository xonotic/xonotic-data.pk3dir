#include "machinegun.qh"

#ifdef SVQC

.float machinegun_spread_accumulation;
.float spreadUpdateTime;

ERASEABLE
void MachineGun_Update_Spread(entity actor, .entity weaponentity)
{
	float spread_accum = actor.(weaponentity).machinegun_spread_accumulation;

	// time based spread decay
	if (WEP_CVAR(WEP_MACHINEGUN, spread_decay))
	{
		float spreadSpectrumDistance = fabs(WEP_CVAR(WEP_MACHINEGUN, spread_max) - WEP_CVAR(WEP_MACHINEGUN, spread_min));
		float timediff = time - actor.(weaponentity).spreadUpdateTime;
		spread_accum = bound(0,
			spread_accum - (timediff * WEP_CVAR(WEP_MACHINEGUN, spread_decay)),
			spreadSpectrumDistance);
	}
	else // legacy behavior for Nexuiz weapon balance
	{
		spread_accum = bound(WEP_CVAR(WEP_MACHINEGUN, spread_min),
			(WEP_CVAR(WEP_MACHINEGUN, spread_add) * actor.(weaponentity).misc_bulletcounter),
			WEP_CVAR(WEP_MACHINEGUN, spread_max));
	}

	actor.(weaponentity).machinegun_spread_accumulation = spread_accum;
	actor.(weaponentity).spreadUpdateTime = time;
}

ERASEABLE
float MachineGun_Heat(float spread_accum)
{
	// function for reducing mg's damage with no spread and adding damage with
	// heated up barrel or vice versa depending on the values of exposed cvars
	float heatMultiplierApplicationPercent = 0.5;
	float coldMultiplierApplicationPercent = 0.5;

	float spreadSpectrumDistance = fabs(WEP_CVAR(WEP_MACHINEGUN, spread_max) - WEP_CVAR(WEP_MACHINEGUN, spread_min));

	if (spreadSpectrumDistance > 0) // avoid division by 0, can never be < 0 either due to how it is set when defined
	{
		heatMultiplierApplicationPercent = spread_accum / spreadSpectrumDistance;
		coldMultiplierApplicationPercent = 1 - heatMultiplierApplicationPercent;
	}

	// example where low end has halved damage and high end has tripled damage:
	// with 50% spread accumulation: heat = (0.5 * 0.5) + (0.5 * 3) = 0.25 + 1.5 = 1.75 damage multiplier
	// with 90% spread accumulation: heat = (0.1 * 0.5) + (0.9 * 3) = 0.05 + 2.7 = 2.75 damage multiplier
	// NOTE: multipliers do not apply when unset for compatibility
	float cold_multiplier = WEP_CVAR(WEP_MACHINEGUN, spread_cold_damagemultiplier);
	float heat_multiplier = WEP_CVAR(WEP_MACHINEGUN, spread_heat_damagemultiplier);
	return (cold_multiplier ? coldMultiplierApplicationPercent * cold_multiplier : coldMultiplierApplicationPercent)
	     + (heat_multiplier ? heatMultiplierApplicationPercent * heat_multiplier : heatMultiplierApplicationPercent);
}

void W_MachineGun_Attack(Weapon thiswep, int deathtype, entity actor, .entity weaponentity)
{
	W_SetupShot(actor, weaponentity, true, 0, SND_MACHINEGUN_FIRE, CH_WEAPON_A, ((actor.(weaponentity).misc_bulletcounter == 1) ? WEP_CVAR(WEP_MACHINEGUN, first_damage) : WEP_CVAR(WEP_MACHINEGUN, sustained_damage)), deathtype);

	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	// this attack_finished just enforces a cooldown at the end of a burst
	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(WEP_MACHINEGUN, first_refire) * W_WeaponRateFactor(actor);

	float spread_accuracy = (IS_DUCKED(actor) && IS_ONGROUND(actor))
		? WEP_CVAR(WEP_MACHINEGUN, spread_crouchmod)
		: 1;

	if(actor.(weaponentity).misc_bulletcounter == 1)
		fireBullet_falloff(actor, weaponentity, w_shotorg, w_shotdir,
		                   WEP_CVAR(WEP_MACHINEGUN, first_spread) * spread_accuracy,
		                   WEP_CVAR(WEP_MACHINEGUN, solidpenetration),
		                   WEP_CVAR(WEP_MACHINEGUN, first_damage),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_halflife),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_mindist),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_maxdist),
		                   0,
		                   WEP_CVAR(WEP_MACHINEGUN, first_force),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_forcehalflife),
		                   deathtype, EFFECT_BULLET, true);
	else
		fireBullet_falloff(actor, weaponentity, w_shotorg, w_shotdir,
		                   WEP_CVAR(WEP_MACHINEGUN, sustained_spread) * spread_accuracy,
		                   WEP_CVAR(WEP_MACHINEGUN, solidpenetration),
		                   WEP_CVAR(WEP_MACHINEGUN, sustained_damage),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_halflife),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_mindist),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_maxdist),
		                   0,
		                   WEP_CVAR(WEP_MACHINEGUN, sustained_force),
		                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_forcehalflife),
		                   deathtype, EFFECT_BULLET, true);

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	// casing code
	if(autocvar_g_casings >= 2)
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), vectoangles(v_forward), 3, actor, weaponentity);
	}

	if(actor.(weaponentity).misc_bulletcounter == 1)
		W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_MACHINEGUN, first_ammo), weaponentity);
	else
		W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_MACHINEGUN, sustained_ammo), weaponentity);
}

// weapon frames
void W_MachineGun_Attack_Frame(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(actor.(weaponentity).m_weapon != actor.(weaponentity).m_switchweapon || !weapon_prepareattack_check(thiswep, actor, weaponentity, (fire & 2), -1)) // abort immediately if switching
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}
	if(PHYS_INPUT_BUTTON_ATCK(actor))
	{
		if(!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
		if(!(actor.items & IT_UNLIMITED_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
			w_ready(thiswep, actor, weaponentity, fire);
			return;
		}
		++actor.(weaponentity).misc_bulletcounter;
		W_MachineGun_Attack(thiswep, thiswep.m_id, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(WEP_MACHINEGUN, sustained_refire), W_MachineGun_Attack_Frame);
	}
	else
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(WEP_MACHINEGUN, sustained_refire), w_ready);
}


void W_MachineGun_Attack_Auto(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(!(fire & 1) || !weapon_prepareattack_check(thiswep, actor, weaponentity, false, -1))
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

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_MACHINEGUN, sustained_ammo), weaponentity);

	W_SetupShot(actor, weaponentity, true, 0, SND_MACHINEGUN_FIRE, CH_WEAPON_A, WEP_CVAR(WEP_MACHINEGUN, sustained_damage), thiswep.m_id);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	MachineGun_Update_Spread(actor, weaponentity);

	float spread_accum = actor.(weaponentity).machinegun_spread_accumulation;

	float heat = MachineGun_Heat(spread_accum);

	float spread_accuracy;
	if (WEP_CVAR(WEP_MACHINEGUN, spread_min) < WEP_CVAR(WEP_MACHINEGUN, spread_max))
		spread_accuracy = WEP_CVAR(WEP_MACHINEGUN, spread_min) + spread_accum;
	else // inverted
		spread_accuracy = WEP_CVAR(WEP_MACHINEGUN, spread_min) - spread_accum;

	if (IS_DUCKED(actor) && IS_ONGROUND(actor))
		spread_accuracy *= WEP_CVAR(WEP_MACHINEGUN, spread_crouchmod);

	fireBullet_falloff(actor, weaponentity, w_shotorg, w_shotdir,
	                   spread_accuracy,
	                   WEP_CVAR(WEP_MACHINEGUN, solidpenetration),
	                   WEP_CVAR(WEP_MACHINEGUN, sustained_damage) * heat,
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_halflife),
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_mindist),
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_maxdist),
	                   0,
	                   WEP_CVAR(WEP_MACHINEGUN, sustained_force),
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_forcehalflife),
	                   thiswep.m_id, EFFECT_BULLET, true);

	++actor.(weaponentity).misc_bulletcounter;

	spread_accum += WEP_CVAR(WEP_MACHINEGUN, spread_add);

	actor.(weaponentity).machinegun_spread_accumulation = spread_accum;

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	if(autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), vectoangles(v_forward), 3, actor, weaponentity);
	}

	ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(WEP_MACHINEGUN, first_refire) * W_WeaponRateFactor(actor);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(WEP_MACHINEGUN, sustained_refire), W_MachineGun_Attack_Auto);
}

void W_MachineGun_Attack_Burst(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_SetupShot(actor, weaponentity, true, 0, SND_MACHINEGUN_FIRE, CH_WEAPON_A, WEP_CVAR(WEP_MACHINEGUN, sustained_damage), thiswep.m_id);
	if(!autocvar_g_norecoil)
	{
		actor.punchangle_x = random() - 0.5;
		actor.punchangle_y = random() - 0.5;
	}

	MachineGun_Update_Spread(actor, weaponentity);

	float spread_accum = actor.(weaponentity).machinegun_spread_accumulation;

	float heat = MachineGun_Heat(spread_accum);

	float spread_accuracy = WEP_CVAR(WEP_MACHINEGUN, burst_spread);
	if (IS_DUCKED(actor) && IS_ONGROUND(actor))
		spread_accuracy *= WEP_CVAR(WEP_MACHINEGUN, spread_crouchmod);

	fireBullet_falloff(actor, weaponentity, w_shotorg, w_shotdir,
	                   spread_accuracy,
	                   WEP_CVAR(WEP_MACHINEGUN, solidpenetration),
	                   WEP_CVAR(WEP_MACHINEGUN, sustained_damage) * heat,
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_halflife),
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_mindist),
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_maxdist),
	                   0,
	                   WEP_CVAR(WEP_MACHINEGUN, sustained_force),
	                   WEP_CVAR(WEP_MACHINEGUN, damagefalloff_forcehalflife),
	                   thiswep.m_id, EFFECT_BULLET, true);

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	if(autocvar_g_casings >= 2) // casing code
	{
		makevectors(actor.v_angle); // for some reason, this is lost
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), vectoangles(v_forward), 3, actor, weaponentity);
	}

	spread_accum += WEP_CVAR(WEP_MACHINEGUN, spread_add);

	actor.(weaponentity).machinegun_spread_accumulation = spread_accum;

	++actor.(weaponentity).misc_bulletcounter;
	if(actor.(weaponentity).misc_bulletcounter == 0)
	{
		ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(WEP_MACHINEGUN, burst_refire2) * W_WeaponRateFactor(actor);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(WEP_MACHINEGUN, burst_animtime), w_ready);
	}
	else
	{
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(WEP_MACHINEGUN, burst_refire), W_MachineGun_Attack_Burst);
	}

}

METHOD(MachineGun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(vdist(actor.origin - actor.enemy.origin, <, 3000 - bound(0, skill, 10) * 200))
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, true);
	else
		PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false, true);
}

METHOD(MachineGun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	// forced reload - wait until the bulletcounter is 0 so a burst loop can finish
	if (WEP_CVAR(WEP_MACHINEGUN, reload_ammo)
	&& actor.(weaponentity).clip_load < min(max(WEP_CVAR(WEP_MACHINEGUN, sustained_ammo), WEP_CVAR(WEP_MACHINEGUN, first_ammo)), WEP_CVAR(WEP_MACHINEGUN, burst_ammo))
	&& actor.(weaponentity).misc_bulletcounter >= 0)
	{
		thiswep.wr_reload(thiswep, actor, weaponentity);
	}
	else if(WEP_CVAR(WEP_MACHINEGUN, mode) == 1)
	{
		if(fire & 1)
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
		{
			actor.(weaponentity).misc_bulletcounter = 0;
			W_MachineGun_Attack_Auto(thiswep, actor, weaponentity, fire);
		}

		// You can "shoot" more rounds than what's "used", and vice versa.
		if(fire & 2)
		if(weapon_prepareattack(thiswep, actor, weaponentity, true, 0))
		{
			if(!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
			if(!(actor.items & IT_UNLIMITED_AMMO))
			{
				W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
				w_ready(thiswep, actor, weaponentity, fire);
				return;
			}

			float ammo_available;
			if (WEP_CVAR(WEP_MACHINEGUN, reload_ammo) > 0)
			{
				ammo_available = actor.(weaponentity).clip_load;
			}
			else
			{
				ammo_available = GetResource(actor, thiswep.ammo_type);
			}

			int to_shoot = WEP_CVAR(WEP_MACHINEGUN, burst);
			if(!(actor.items & IT_UNLIMITED_AMMO))
			{
				// We don't want to shoot 3 rounds if there's 2 left in the mag, so we'll use a fraction.
				// Also keep the fraction <= 1 otherwise we'd mag dump in one burst.
				float burst_fraction = min(1, ammo_available / WEP_CVAR(WEP_MACHINEGUN, burst_ammo));
				to_shoot = floor(to_shoot * burst_fraction);

				// We also don't want to use 3 rounds if there's only 2 left.
				int to_use = min(WEP_CVAR(WEP_MACHINEGUN, burst_ammo), ammo_available);
				W_DecreaseAmmo(thiswep, actor, to_use, weaponentity);
			}

			// Bursting counts up to 0 from a negative.
			actor.(weaponentity).misc_bulletcounter = -to_shoot;
			W_MachineGun_Attack_Burst(thiswep, actor, weaponentity, fire);
		}
	}
	else
	{

		if(fire & 1)
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, 0))
		{
			actor.(weaponentity).misc_bulletcounter = 1;
			W_MachineGun_Attack(thiswep, thiswep.m_id, actor, weaponentity); // sets attack_finished
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(WEP_MACHINEGUN, sustained_refire), W_MachineGun_Attack_Frame);
		}

		if((fire & 2) && WEP_CVAR(WEP_MACHINEGUN, first))
		if(weapon_prepareattack(thiswep, actor, weaponentity, true, 0))
		{
			actor.(weaponentity).misc_bulletcounter = 1;
			W_MachineGun_Attack(thiswep, thiswep.m_id | HITTYPE_SECONDARY, actor, weaponentity); // sets attack_finished
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(WEP_MACHINEGUN, first_refire), w_ready);
		}
	}
}

METHOD(MachineGun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	if(WEP_CVAR(WEP_MACHINEGUN, mode) == 1)
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_MACHINEGUN, sustained_ammo);
	else
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_MACHINEGUN, first_ammo);

	if(WEP_CVAR(WEP_MACHINEGUN, reload_ammo))
	{
		if(WEP_CVAR(WEP_MACHINEGUN, mode) == 1)
			ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_MACHINEGUN, sustained_ammo);
		else
			ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_MACHINEGUN, first_ammo);
	}

	return ammo_amount;
}

METHOD(MachineGun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount;
	float burst_ammo_per_shot = WEP_CVAR(WEP_MACHINEGUN, burst_ammo) / WEP_CVAR(WEP_MACHINEGUN, burst);

	if(WEP_CVAR(WEP_MACHINEGUN, mode) == 1)
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= burst_ammo_per_shot;
	else
		ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_MACHINEGUN, first_ammo);

	if(WEP_CVAR(WEP_MACHINEGUN, reload_ammo))
	{
		if(WEP_CVAR(WEP_MACHINEGUN, mode) == 1)
			ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= burst_ammo_per_shot;
		else
			ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_MACHINEGUN, first_ammo);
	}

	return ammo_amount;
}

METHOD(MachineGun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	if(actor.(weaponentity).misc_bulletcounter < 0)
		return;
	W_Reload(actor, weaponentity, min(max(WEP_CVAR(WEP_MACHINEGUN, sustained_ammo), WEP_CVAR(WEP_MACHINEGUN, first_ammo)), WEP_CVAR(WEP_MACHINEGUN, burst_ammo)), SND_RELOAD);
}

METHOD(MachineGun, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(MachineGun, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_MACHINEGUN_MURDER_SNIPE;
	else
		return WEAPON_MACHINEGUN_MURDER_SPRAY;
}

#endif
#ifdef CSQC

METHOD(MachineGun, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_MACHINEGUN_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTN_NORM);
}

#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>

METHOD(MachineGun, describe, string(MachineGun this))
{
	TC(MachineGun, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s quickly fires bullets with a small degree of spread."), COLORED_NAME(this));
	PAR(_("The secondary fire fires a quick burst of bullets faster than the primary fire and with no spread, but there's a short delay until it can be used again."));
	PAR(_("It consumes %s ammo for each bullet shot, until the whole magazine is emptied."), COLORED_NAME(ITEM_Bullets));
	PAR(_("The %s can be used in a lot of situations, and it works particularly well at long ranges since the bullets pierce the sky instantaneously. "
	      "Since the secondary fire has no spread, it's the better option when firing over a long range."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_secondaryMultishot(this.netname, "sustained", "burst", "burst", "burst_refire2", false));
	return PAGE_TEXT;
}

#endif
