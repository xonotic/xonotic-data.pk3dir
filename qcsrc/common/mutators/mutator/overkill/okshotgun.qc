#include "okshotgun.qh"

#ifdef SVQC
spawnfunc(weapon_okshotgun) { weapon_defaultspawnfunc(this, WEP_OVERKILL_SHOTGUN); }

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
		// Ugly hack to reuse the fire mode of the blaster.
		makevectors(actor.v_angle);
		Weapon oldwep = actor.(weaponentity).m_weapon; // we can't avoid this hack
		actor.(weaponentity).m_weapon = WEP_BLASTER;
		W_Blaster_Attack(
			actor,
			weaponentity,
			WEP_BLASTER.m_id | HITTYPE_SECONDARY,
			WEP_CVAR_SEC(okshotgun, shotangle),
			WEP_CVAR_SEC(okshotgun, damage),
			WEP_CVAR_SEC(okshotgun, edgedamage),
			WEP_CVAR_SEC(okshotgun, radius),
			WEP_CVAR_SEC(okshotgun, force),
			WEP_CVAR_SEC(okshotgun, speed),
			WEP_CVAR_SEC(okshotgun, spread),
			WEP_CVAR_SEC(okshotgun, delay),
			WEP_CVAR_SEC(okshotgun, lifetime)
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
	if (WEP_CVAR(okshotgun, reload_ammo) && actor.(weaponentity).clip_load < WEP_CVAR_PRI(okshotgun, ammo))
	{
		// Forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		return;
	}
	if (fire & 1) // Primary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(okshotgun, animtime)))
		{
			return;
		}
		W_Shotgun_Attack(thiswep, actor, weaponentity, true,
			WEP_CVAR_PRI(okshotgun, ammo),
			WEP_CVAR_PRI(okshotgun, damage),
			WEP_CVAR_PRI(okshotgun, bullets),
			WEP_CVAR_PRI(okshotgun, spread),
			WEP_CVAR_PRI(okshotgun, solidpenetration),
			WEP_CVAR_PRI(okshotgun, force));
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(okshotgun, animtime), w_ready);
		return;
	}
	if ((fire & 2) && (WEP_CVAR_SEC(okshotgun, refire_type) == 0)) // Secondary attack
	{
		if (!weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_SEC(okshotgun, refire)))
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
			WEP_CVAR_SEC(okshotgun, shotangle),
			WEP_CVAR_SEC(okshotgun, damage),
			WEP_CVAR_SEC(okshotgun, edgedamage),
			WEP_CVAR_SEC(okshotgun, radius),
			WEP_CVAR_SEC(okshotgun, force),
			WEP_CVAR_SEC(okshotgun, speed),
			WEP_CVAR_SEC(okshotgun, spread),
			WEP_CVAR_SEC(okshotgun, delay),
			WEP_CVAR_SEC(okshotgun, lifetime)
		);
		actor.(weaponentity).m_weapon = oldwep;
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(okshotgun, animtime), w_ready);
	}
}

METHOD(OverkillShotgun, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_PRI(okshotgun, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_SHOTGUN.m_id]) >= WEP_CVAR_PRI(okshotgun, ammo);
	return ammo_amount;
}

METHOD(OverkillShotgun, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	if (WEP_CVAR_SEC(okshotgun, ammo) == 0)
	{
		return true;
	}
	float ammo_amount = actor.(thiswep.ammo_field) >= WEP_CVAR_SEC(okshotgun, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[WEP_OVERKILL_SHOTGUN.m_id]) >= WEP_CVAR_SEC(okshotgun, ammo);
	return ammo_amount;
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
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_BLASTER_MURDER;
	else
		return WEAPON_SHOTGUN_MURDER;
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
