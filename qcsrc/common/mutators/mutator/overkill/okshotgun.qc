#include "okshotgun.qh"

#ifdef SVQC
METHOD(OverkillShotgun, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if (vdist(actor.origin - actor.enemy.origin, >, WEP_CVAR_PRI(okshotgun, bot_range)))
	{
		PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
	}
	else
	{
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false);
	}
}

METHOD(OverkillShotgun, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if ((WEP_CVAR_SEC(okshotgun, refire_type) == 1) && (fire & 2) && (time >= actor.jump_interval))
	{
		// Secondary uses it's own refire timer if refire_type is 1.
		actor.jump_interval = time + WEP_CVAR_SEC(okshotgun, refire) * W_WeaponRateFactor(actor);
		BLASTER_SECONDARY_ATTACK(okshotgun, actor, weaponentity);
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
	if (WEP_CVAR(okshotgun, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(okshotgun, ammo))
	{
		// Forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		return;
	}
	if (fire & 1) // Primary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(okshotgun, refire)))
		{
			return;
		}
		W_Shotgun_Attack(thiswep, actor, weaponentity, true,
			WEP_CVAR_PRI(okshotgun, ammo),
			WEP_CVAR_PRI(okshotgun, damage),
			WEP_CVAR_PRI(okshotgun, bullets),
			WEP_CVAR_PRI(okshotgun, spread),
			WEP_CVAR_PRI(okshotgun, solidpenetration),
			WEP_CVAR_PRI(okshotgun, force),
			EFFECT_RIFLE_WEAK);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(okshotgun, animtime), w_ready);
		return;
	}
	if ((fire & 2) && (WEP_CVAR_SEC(okshotgun, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(okshotgun, refire)))
		{
			return;
		}
		BLASTER_SECONDARY_ATTACK(okshotgun, actor, weaponentity);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(okshotgun, animtime), w_ready);
	}
}

METHOD(OverkillShotgun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(okshotgun, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_SHOTGUN.m_id]) >= WEP_CVAR_PRI(okshotgun, ammo);
	return ammo_amount;
}

METHOD(OverkillShotgun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // Blaster secondary is unlimited.
}

METHOD(OverkillShotgun, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, WEP_CVAR_PRI(okshotgun, ammo), SND_RELOAD); // WEAPONTODO
}

METHOD(OverkillShotgun, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(OverkillShotgun, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_OVERKILL_SHOTGUN_MURDER;
}

#endif
#ifdef CSQC
.float prevric;

METHOD(OverkillShotgun, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_SHOTGUN_IMPACT, org2, w_backoff * 1000, 1);
	if(!w_issilent && time - actor.prevric > 0.25)
	{
		if(w_random < 0.05)
			sound(actor, CH_SHOTS, SND_RIC_RANDOM(), VOL_BASE, ATTEN_NORM);
		actor.prevric = time;
	}
}

#endif
