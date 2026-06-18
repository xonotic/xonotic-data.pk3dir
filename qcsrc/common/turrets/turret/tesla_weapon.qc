#include "tesla_weapon.qh"

#ifdef SVQC

entity turret_tesla_toast(entity actor, entity from, float range, float damage);
SOUND(TeslaCoilTurretAttack_FIRE, W_Sound("electro_fire"));
METHOD(TeslaCoilTurretAttack, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	bool isPlayer = IS_PLAYER(actor);
	if (fire & 1)
	if (!isPlayer || weapon_prepareattack(thiswep, actor, weaponentity, false, 1))
	{
		if (isPlayer)
		{
			turret_initparams(actor);
			W_SetupShot_Dir(actor, weaponentity, v_forward, false, 0, SND_TeslaCoilTurretAttack_FIRE, CH_WEAPON_B, 0, DEATH_TURRET_TESLA.m_id);
			actor.tur_shotdir_updated = w_shotdir;
			actor.tur_shotorg = w_shotorg;
			actor.tur_head = actor;
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0.5, w_ready);
		}

		float d = actor.shot_dmg;
		float r = actor.target_range;
		entity e = spawn();
		setorigin(e, actor.tur_shotorg);

		actor.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_TEAMCHECK;

		entity t = turret_tesla_toast(actor, e, r, d);
		delete(e);

		if (t == NULL)
			return;

		actor.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_MISSILES | TFL_TARGETSELECT_TEAMCHECK;

		actor.attack_finished_single[0] = time + actor.shot_refire;
		for (int i = 0; i < 10; ++i) // chain the lightning between max 10 more targets
		{
			d *= 0.75;
			r *= 0.85;
			t = turret_tesla_toast(actor, t, r, d);
			if (t == NULL)
				break;
		}

		IL_EACH(g_railgunhit, it.railgunhit, it.railgunhit = false);
		IL_CLEAR(g_railgunhit);
	}
}

entity turret_tesla_toast_cond_from;
entity turret_tesla_toast_cond_actor;
bool turret_tesla_toast_cond(entity e)
{
	return (e != turret_tesla_toast_cond_from && !e.railgunhit
		&& turret_validate_target(turret_tesla_toast_cond_actor, e, turret_tesla_toast_cond_actor.target_validate_flags) > 0);
}
entity turret_tesla_toast(entity actor, entity from, float range, float damage)
{
	entity closest = NULL;
	float head_dist2, closest_dist2 = 0;
	turret_tesla_toast_cond_from = from;
	turret_tesla_toast_cond_actor = actor;
	for (entity head = WarpZone_SearchInRadius(from.origin, range, MOVE_NOMONSTERS, turret_tesla_toast_cond); head; head = head.chain)
	{
		head_dist2 = vlen2(head.WarpZone_findradius_dist);
		if (!closest || head_dist2 < closest_dist2) // new closest
		{
			closest_dist2 = head_dist2;
			closest = head;
		}
	}

	if (closest)
	{
		te_csqc_trace_callback_func = te_csqc_lightningarc;
		WarpZone_TraceLine_ThroughZone(from.origin, WarpZone_UnTransformOrigin(closest, closest.WarpZone_findradius_nearest),
			MOVE_NOTHING, NULL, NULL, te_csqc_trace_callback);
		if (closest != actor.realowner)
			Damage(closest, actor, actor,
				damage,
				DEATH_TURRET_TESLA.m_id,
				DMG_NOWEP,
				closest.WarpZone_findradius_nearest,
				'0 0 0'
			);
		closest.railgunhit = true;
		IL_PUSH(g_railgunhit, closest);
	}
	return closest;
}

#endif // SVQC
